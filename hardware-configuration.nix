{ config, lib, pkgs, modulesPath, ... }:

{

  fileSystems."/" =
    { device = "/dev/disk/by-label/DOGEBOX";
      fsType = "ext4";
    };

  fileSystems."/boot" = if pkgs.system == "x86_64-linux" then {
    device = "/dev/sda1";
    fsType = "vfat";
  } else { };

  networking.useDHCP = lib.mkDefault true;

}
