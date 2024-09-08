# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

let configDir = ./.;
in
{
  imports =
      [
        ./base.nix
      ]
    ;

  # Copy self into build image.
  environment.etc = {
    "nixos/configuration.nix" = {
      source = "${configDir}/vbox.nix";
    };
  };

  /* Below copied from ${nixpkgs}/nixos/modules/virtualisation/virtualbox-image.nix */

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/nixos";
      autoResize = true;
      fsType = "ext4";
    };
  };

  boot.growPartition = true;
  boot.loader.grub.device = "/dev/sda";

  swapDevices = [{
    device = "/var/swap";
    size = 2048;
  }];

  virtualisation.virtualbox.guest.enable = true;
}
