{ lib, ... }:

{
  fileSystems = lib.mkDefault {
    "/" = {
      device = "/dev/disk/by-label/nixos";
      autoResize = true;
      fsType = "ext4";
    };
  };
  boot.growPartition = true;
  boot.loader.grub.device = lib.mkDefault "/dev/sda";
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;
  boot.loader.systemd-boot.enable = lib.mkDefault true;
}
