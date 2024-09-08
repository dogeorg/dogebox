{ config, lib, pkgs, modulesPath, ... }:

let
  configDir = ./.;
in
{

  fileSystems."/" = lib.mkDefault
    { 
      device = "/dev/disk/by-label/DOGEBOX";
      fsType = "ext4";
    };

  fileSystems."/boot" = lib.mkForce 
    {
      device = "/dev/sda1";
      fsType = "ext4";
    };

  networking.useDHCP = lib.mkDefault true;

  # Copy self into build image.
  environment.etc = {
    "nixos/hardware-configuration.nix" = {
      source = "${configDir}/hardware-configuration.nix";
    };
  };
}
