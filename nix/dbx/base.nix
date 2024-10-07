# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ lib, pkgs, ... }:

{
  imports = [ ./dogebox.nix ];

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

  environment.systemPackages = with pkgs; [
    # Install a few utility packages
    git
    vim
    wget
  ];

  # DO NOT CHANGE THIS. EVER. EVEN WHEN UPDATING YOUR SYSTEM PAST 24.05.
  system.stateVersion = "24.05";
}
