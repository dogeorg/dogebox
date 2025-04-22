{ inputs, lib, config, pkgs, dbxRelease, modulesPath, specialArgs, ... }:

let
  # flakeSource defined using specialArgs consistent with other builders
  flakeSource = specialArgs.flakeSource;

  # Image naming (kept from original)
  imageName = "dogebox-${dbxRelease}-t6";

  # Reference the base NixOS configuration modules from flake.nix
  # This assumes mkConfigModules is accessible or we pass modules directly
  # We will rely on the modules passed by the `base` function in flake.nix
  # No need to re-evaluate inner flake here

in
{
  # imports = [ ./firmware.nix ]; # Base modules are already included by flake.nix's `base` function
  imports = [ ./firmware.nix ]; # Keep firmware import if specific to T6

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

  # KERNEL PKG LOGIC REMAINS UNCHANGED...
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

  systemd.services.resizerootfs = { # kept from original
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

  # Unfree packages needed for T6 build (kept from original)
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "arm-trusted-firmware-rk3588"
    "rkbin"
  ];

  # Custom image building logic (kept from original, ensure config is passed correctly)
  # Note: make-disk-image might run activation scripts itself. Check its behavior.
  # We might need to inject the flake copy *before* make-disk-image runs if it doesn't include activation.
  # For now, assume activation script runs within the environment make-disk-image prepares.
  
  # Raw image specific settings
  format.raw.imageName = "dogebox-${dbxRelease}-t6.img";

  # Activation script to run during image build to copy flake source
  system.activationScripts.copyFlakeAndMark = {
    deps = [ "users" ];
    text = ''
      echo "[ActivScript] Copying flake source from ${flakeSource} to image /etc/nixos..."
      mkdir -p /etc/nixos
      ${pkgs.rsync}/bin/rsync -a --delete --exclude='.git' "${flakeSource}/" "/etc/nixos/"

      echo "[ActivScript] Marking build type as nanopc-t6..."
      mkdir -p /opt
      echo "nanopc-t6" > /opt/build-type

      echo "[ActivScript] Flake source copy and marking complete."
    '';
  };

  # Remove the old, problematic activation script
  # system.activationScripts.copyFiles = lib.mkForce {}; 
  # Ensure *all* other activation scripts defined *only* in this file are removed if not needed.
  # The resizerootfs service handles the first boot resize, not copyFiles logic.
  # We keep systemd.services.resizerootfs
}
