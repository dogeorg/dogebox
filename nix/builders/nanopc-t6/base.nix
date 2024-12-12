{ pkgs ? import <nixpkgs> {}, lib, ... }:

{
  imports =
    # If we have an overlay for /opt specified, load that first.
    lib.optional (builtins.pathExists /etc/nixos/opt-overlay.nix) /etc/nixos/opt-overlay.nix

    ++
    [
      ./firmware.nix
      ../../dbx/base.nix
    ];

  nixpkgs.overlays = [
    (final: super: {
      makeModulesClosure = x:
        super.makeModulesClosure (x // { allowMissing = true; });
    })
  ];

  # Show everything in the tty console instead of serial.
  boot.kernelParams = [ "console=ttyFIQ0" ];

  # Use the extlinux boot loader. (NixOS wants to enable GRUB by default)
  boot.loader.grub.enable = false;
  # Enables the generation of /boot/extlinux/extlinux.conf
  boot.loader.generic-extlinux-compatible.enable = true;
  boot.loader.timeout = 1;

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
    cloud-utils
    parted
    wpa_supplicant
    screen
  ];

  #systemd.services.formatLargestDisk = {
  #  description = "Formats the largest disk to ext4";
  #  unitConfig = {
  #    type = "oneshot";
  #    after = [ "sysinit.target" ];
  #  };##

  #  script = ''
  #    if [ ! -e /etc/largest-disk-formatted ]; then
  #      largest_disk=$(lsblk -dno NAME,SIZE,MOUNTPOINT | awk '$3 == "" {print $1, $2}' | sort -rh -k2 | head -n1 | awk '{print $1}')

  #      if [ -z "$largest_disk" ]; then
  #        echo "No suitable data disk found."
  #        exit 1
  #      fi

  #      echo "Largest unmounted disk found: $largest_disk"
  #      echo "Formatting as ext4..."
  #      mkfs.ext4 /dev/$largest_disk

   #     cat <<EOF > /etc/nixos/opt-overlay.nix
#{ ... }:

#{
#  fileSystems."/opt" = {
#    device = "/dev/''${largest_disk}";
#    fsType = "ext4";
#  };
#}
#        EOF

 #       echo "/dev/$largest_disk" > /etc/largest-disk
 #       touch /etc/largest-disk-formatted
  #    fi
  #  '';

   # wantedBy = [ "basic.target" "runOnceOnFirstBoot.service" ];
 # };

  systemd.services.resizerootfs = {
    description = "Expands root filesystem of boot deviceon first boot";
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
}
