{ pkgs ? import <nixpkgs> {}, lib, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ../../dbx/base.nix
  ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    autoResize = true;
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/ESP";
    fsType = "vfat";
  };

  boot.growPartition = true;

  boot.loader.grub.device = "/dev/sda";

  services.qemuGuest.enable = true;

  # Support for usb wifi dongle for wifi bring-up testing
  boot.kernelModules = [ "rtw88_8822ce" "rtw_8822bu" "rtw88_pci" "rtw88_core" ];
  hardware.enableRedistributableFirmware = true;

  system.activationScripts.buildType = {
    text = ''
      mkdir -p /opt
      echo "qemu" > /opt/build-type
    '';
  };
}
