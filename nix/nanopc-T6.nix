{ pkgs, ... }:

{
  imports = [ 
    ./base.nix
  ];

  # Use the extlinux boot loader. (NixOS wants to enable GRUB by default)
  boot.loader.grub.enable = false;
  # Enables the generation of /boot/extlinux/extlinux.conf
  boot.loader.generic-extlinux-compatible.enable = true;

#  boot.kernelPackages = let
#    linux_rk3588_pkg = { fetchFromGitHub, buildLinux, ... } @ args:
#
#      buildLinux(args // rec {
#        modDirVersion = "6.1.57";
#        version = modDirVersion;
#
#        src = fetchFromGitHub {
#          owner = "friendlyarm";
#          repo = "kernel-rockchip";
#          rev = "85d0764ec61ebfab6b0d9f6c65f2290068a46fa1";
#          hash = "sha256-oGMx0EYfPQb8XxzObs8CXgXS/Q9pE1O5/fP7/ehRUDA=";
#        };
#        kernelPatches = [];
#
#        extraConfig = "";
#
#        extraMeta.branch = "6.1";
#
#        configFile = ./nanopc-T6_linux_defconfig;
#
#      } // (args.Override or {}));
#    linux_rk3588 = pkgs.callPackage linux_rk3588_pkg{};
#  in
#    pkgs.recurseIntoAttrs (pkgs.linuxPackagesFor linux_rk3588);

  boot.initrd.availableKernelModules = [ "nvme" "usbhid" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-label/DOGEBOX_EMMC";
      fsType = "ext4";
    };

  environment.systemPackages = with pkgs; [
    cloud-utils
    parted
    wpa_supplicant
  ];

  systemd.services.resizerootfs = {
    description = "Expands root filesystem on first boot";
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
    wantedBy = [ "basic.target" ];
  };

}
