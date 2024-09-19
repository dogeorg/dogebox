{ pkgs, ... }:

{
  imports = [ 
    ./base.nix
  ];

  # Use the extlinux boot loader. (NixOS wants to enable GRUB by default)
  boot.loader.grub.enable = false;
  # Enables the generation of /boot/extlinux/extlinux.conf
  boot.loader.generic-extlinux-compatible.enable = true;

  boot.kernelPackages = let
    linux_rk3588_pkg = {
                        fetchFromGitHub,
                        linuxManualConfig,
                        ubootTools,
                         ...
                      } :
    (linuxManualConfig rec {
      modDirVersion = "6.1.43";
      version = "${modDirVersion}-xunlong-rk3588";
      extraMeta.branch = "6.1";

      # https://github.com/orangepi-xunlong/linux-orangepi/tree/orange-pi-6.1-rk35xx
      src = fetchFromGitHub {
        owner = "orangepi-xunlong";
        repo = "linux-orangepi";
        rev = "752c0d0a12fdce201da45852287b48382caa8c0f";
        hash = "sha256-tVu/3SF/+s+Z6ytKvuY+ZwqsXUlm40yOZ/O5kfNfUYc=";
      };

      configfile = ./nanopc-T6_linux_defconfig;

      allowImportFromDerivation = true;

#  modulesClosure = pkgs.makeModulesClosure {
#    rootModules = config.boot.initrd.availableKernelModules ++ config.boot.initrd.kernelModules;
#    kernel = modulesTree;
#    firmware = firmware;
#    allowMissing = false;
#  };

    })
    .overrideAttrs (old: {
      name = "k"; # dodge uboot length limits
      nativeBuildInputs = old.nativeBuildInputs ++ [ubootTools];
    });
      linux_rk3588 = pkgs.callPackage linux_rk3588_pkg{};
    in
      pkgs.recurseIntoAttrs (pkgs.linuxPackagesFor linux_rk3588);

  #boot.initrd.availableKernelModules = [ "nvme" "usbhid" ];
  boot.initrd.availableKernelModules = [];
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
    screen
  ];

  services.openssh = {
    enable = true;
    passwordAuthentication = true;
  };

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
