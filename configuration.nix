# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
      [ #./bootloader
        ./hardware-configuration.nix 
        ./dogebox.nix
      ]
    ;

  nix.settings = {
    #allowed-users = [ "*" ];
    auto-optimise-store = false;
    # builders =
    #cores = 0;
    experimental-features = [ "nix-command" "flakes" ];
    #extra-sandbox-paths =
    ##max-jobs = auto;
    require-sigs = true;
    sandbox = true;
    sandbox-fallback = false;
    substituters = [ "https://cache.nixos.org/" ];
    system-features = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
    trusted-public-keys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" ];
    #trusted-substituters =
    trusted-users = [ "root" "nixos" ];
  };

  # Set your time zone.
  time.timeZone = "Australia/Brisbane";

  # Install a few utility packages
  environment.systemPackages = with pkgs; [
    git
    vim
    wget
  ];

  # /media does not exist by default, and devmon's default config
  # will mount devices at '/media/<username>/<devname>' rather
  # than '/media/<devname>' for some reason, so this should
  # ensure it exists.
  systemd.tmpfiles.rules = [
    "d /media 0755 root root -"
  ];

  services.devmon.enable = true;

  system.stateVersion = "23.11"; # Did you read the comment?
}
