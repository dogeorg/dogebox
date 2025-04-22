{ inputs, lib, config, pkgs, dbxRelease, modulesPath, ... }:

let
  # Evaluate the inner flake configuration with overrides
  innerFlakeOutputsFunc = (import "${inputs.self}/nix/flake.nix").outputs;
  innerFlakeArgs = {
      self = { # Provide self for inner flake evaluation context
          inputs = {
              inherit (inputs) nixpkgs dogeboxd dkm;
          };
      };
      inherit (inputs) nixpkgs dogeboxd dkm;
      lib = inputs.nixpkgs.lib;
      flakeSourcePath = inputs.self;
  };
  evaluatedInnerOutputs = innerFlakeOutputsFunc innerFlakeArgs;

  # Select the aarch64 module list
  baseOsModules = evaluatedInnerOutputs.dogeboxosModules."dogeboxos-aarch64";

  # Get the evaluated config for use in make-disk-image
  osConfig = evaluatedInnerOutputs.nixosConfigurations."dogeboxos-aarch64".config;

  # Image naming (kept from original)
  imageName = "dogebox-${dbxRelease}-t6";

  # Modified make-disk-image logic
  baseRawImage = import "${toString modulesPath}/../lib/make-disk-image.nix" {
    inherit lib pkgs;
    config = osConfig;
    diskSize = "auto";
    format = "raw";
    name = imageName;
  };
in
{
  imports = baseOsModules ++ [ ./firmware.nix ]; # No longer need ./base.nix here

  nixpkgs.overlays = [
    (final: super: {
      makeModulesClosure = x:
        super.makeModulesClosure (x // { allowMissing = true; });
    })
  ];

  # Show everything in the tty console instead of serial.
  boot.kernelParams = [ "console=ttyFIQ0" ];

  # Use the extlinux boot loader. (NixOS wants to enable GRUB by default)
  boot.loader.grub.enable = lib.mkForce false;
  # Enables the generation of /boot/extlinux/extlinux.conf
  boot.loader.generic-extlinux-compatible.enable = lib.mkDefault true;
  boot.loader.timeout = lib.mkDefault 1;

  boot.kernelPackages = let
    linux_rk3588_pkg = {
      fetchFromGitHub,
      linuxManualConfig,
      ubootTools,
      ...
    } :
    (linuxManualConfig rec {
      modDirVersion = "6.1.57";
      version = modDirVersion;

      src = fetchFromGitHub {
        owner = "friendlyarm";
        repo = "kernel-rockchip";
        rev = "85d0764ec61ebfab6b0d9f6c65f2290068a46fa1";
        hash = "sha256-oGMx0EYfPQb8XxzObs8CXgXS/Q9pE1O5/fP7/ehRUDA=";
      };

      configfile = ./nanopc-T6_linux_defconfig;
      allowImportFromDerivation = true;
    })
    .overrideAttrs (old: {
      nativeBuildInputs = old.nativeBuildInputs ++ [ubootTools];
      prePatch = ''
        cp arch/arm64/boot/dts/rockchip/rk3588-nanopi6-rev01.dts arch/arm64/boot/dts/rockchip/rk3588-nanopc-t6.dts
        sed -i "s/rk3588-nanopi6-rev0a.dtb/rk3588-nanopi6-rev0a.dtb\ rk3588-nanopc-t6.dtb/" arch/arm64/boot/dts/rockchip/Makefile
      '';
    });
      linux_rk3588 = pkgs.callPackage linux_rk3588_pkg{};
    in
      pkgs.recurseIntoAttrs (pkgs.linuxPackagesFor linux_rk3588);

  boot.initrd.availableKernelModules = [ "nvme" "usbhid" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "rtw88_8822ce" "rtw88_pci" "rtw88_core" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
    };

  environment.systemPackages = with pkgs; [
    avahi
    cloud-utils
    parted
    screen
  ];

  # Initial hostName for the box to respond to dogebox.local for first boot and installation steps.
  # Will be replaced ny dogeboxd configuration
  networking.hostName = lib.mkDefault ("dogebox");
  services.avahi = {
      nssmdns4 = true;
      nssmdns6 = true;

      enable = true;
      reflector = true;
      publish = {
        enable = true;
        addresses = true;
        workstation = true;
        userServices = true;
      };
  };

  systemd.services.resizerootfs = {
    description = "Expands root filesystem of boot device on first boot";
    unitConfig = {
      type = "oneshot";
      after = [ "sysinit.target" ];
    };
    script = ''
      if [ ! -e /etc/fs.resized ];
        then
          echo "Expanding root filesystem . . ."
          PATH=$PATH:/run/current-system/sw/bin/
          ROOT_PART=$(basename "$(findmnt -c -n -o SOURCE /)")
          ROOT_PART_NUMBER=$(cat /sys/class/block/$ROOT_PART/partition)
          ROOT_DISK=$(basename "$(readlink -f "/sys/class/block/$ROOT_PART/..")")
          growpart /dev/"$ROOT_DISK" "$ROOT_PART_NUMBER" || if [ $? == 2 ]; then echo "Error with growpart"; exit 2; fi
          partprobe
          resize2fs /dev/"$ROOT_PART"
          touch /etc/fs.resized
        fi
    '';
    wantedBy = [ "basic.target" "runOnceOnFirstBoot.service" ];
  };
  # ------------------------------------------- 

  # Unfree packages needed for T6 build (kept from original)
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "arm-trusted-firmware-rk3588"
    "rkbin"
  ];

  # Custom image building logic (kept from original)
  system.build.raw = lib.mkForce (pkgs.stdenv.mkDerivation {
    name = "dogebox-t6.img";
    src = ./.;
    buildInputs = [
      baseRawImage # This now contains the flake-based NixOS config
      pkgs.bash
      pkgs.parted
      pkgs.simg2img
    ];
    buildCommand = ''
      mkdir -p $out

      ln -s ${pkgs.ubootNanoPCT6}/idbloader.img $out/idbloader.img
      ln -s ${pkgs.ubootNanoPCT6}/u-boot.itb $out/uboot.img
      ${pkgs.bash}/bin/bash $src/scripts/extract-fs-from-disk-image.sh ${baseRawImage}/nixos.img $out/
      cp $src/templates/parameter.txt $out/
      ${pkgs.bash}/bin/bash $src/scripts/make-sd-image.sh $out/ ${imageName}.img

      # Only copy the resulting image, we don't care about other intermediaries.
      mv $out/dogebox-*.img /tmp
      rm -Rf $out/*
      mv /tmp/dogebox-*.img $out/
    '';
  });

  # Activation script modifications (kept from original)
  system.activationScripts.copyFiles = ''
    mkdir -p /opt
    echo "nanopc-T6" > /opt/build-type # Updated build type

    if [ ! -f /opt/dbx-installed ]; then
      touch /opt/ro-media
    fi
  '';
}
