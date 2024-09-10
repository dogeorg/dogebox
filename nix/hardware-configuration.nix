{ config, lib, pkgs, modulesPath, ... }:

{

  fileSystems."/" = lib.mkDefault
    { 
      device = "/dev/disk/by-label/dogebox";
      fsType = "ext4";
    };

  fileSystems."/boot" = lib.mkDefault 
    {
      device = "/dev/sda";
      fsType = "vfat";
    };

  networking.useDHCP = lib.mkDefault true;
}
