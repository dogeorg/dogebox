# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ lib, pkgs, ... }:

{
  imports = [
    ./dogebox.nix
  ]
  ++ lib.optionals (builtins.pathExists "/etc/nixos/hardware-configuration.nix") [
    /etc/nixos/hardware-configuration.nix
  ];

  nix.settings = {
    auto-optimise-store = false;
    experimental-features = [ "nix-command" "flakes" ];
    require-sigs = true;
    sandbox = true;
    sandbox-fallback = false;
    substituters = [
      "https://cache.nixos.org/"
      "https://dbx.nix.dogecoin.org"
    ];
    system-features = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "dbx.nix.dogecoin.org:ODXaHC+9DNqXQ8ZTijaCT4JpieqmOatZeZBbdN51Obc="
    ];
    trusted-users = [ "root" "nixos" ];
  };

  # Set your time zone.
  time.timeZone = "Australia/Brisbane";

  environment.systemPackages = with pkgs; [
    # Install a few utility packages
    git
    vim
    wget
    wirelesstools
    networkmanager
  ];

  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.backend = "iwd";

  # DO NOT CHANGE THIS. EVER. EVEN WHEN UPDATING YOUR SYSTEM PAST 24.11.
  system.stateVersion = "24.11";
}
