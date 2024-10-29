{ lib, ... }:

{
  imports = [ ../../dbx/base.nix ];

  fileSystems = lib.mkDefault {
    "/" = {
      device = "/dev/disk/by-label/nixos";
      autoResize = true;
      fsType = "ext4";
    };
  };

  boot.growPartition = true;

  boot.loader.grub.device = "/dev/sda";
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.enable = true;
}
