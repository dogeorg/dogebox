{ config, lib, pkgs, ... }:

let dogebox = import <dogebox> { inherit pkgs; }; in
{

  boot.loader.grub.enable = false;

  fileSystems."/" = { device = "/dev/null"; };

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

  system.stateVersion = "24.05";

}
