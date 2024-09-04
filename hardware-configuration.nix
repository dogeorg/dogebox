{ config, lib, pkgs, modulesPath, ... }:

{

  fileSystems."/" = lib.mkDefault
    { 
      device = "/dev/disk/by-label/DOGEBOX";
      fsType = "ext4";
    };

  fileSystems."/boot" = lib.mkDefault 
    {
      device = "/dev/sda1";
      fsType = "vfat";
    };

  networking.useDHCP = lib.mkDefault true;

}
