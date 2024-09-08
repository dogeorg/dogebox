{ config, lib, pkgs, modulesPath, ... }:

let
  configDir = ./.;
in
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

  # Copy self into build image.
  environment.etc = {
    "nixos/hardware-configuration.nix" = {
      source = "${configDir}/hardware-configuration.nix";
    };
  };
}
