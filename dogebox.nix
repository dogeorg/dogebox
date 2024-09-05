{ config, lib, pkgs, ... }:

let dogebox = import <dogebox> { inherit pkgs; }; in
{
  imports = [
    ./dkm.nix
    # ./dogeboxd.nix
  ] ++ lib.optionals (builtins.pathExists "/opt/dogebox/nix/dogebox.nix") [
    /opt/dogebox/nix/dogebox.nix
  ];

  users.groups.dogebox = {};

  # users.users.dogeboxd = {
  #   isSystemUser = true;
  #   group =  "dogeboxd";
  #   extraGroups = [ "wheel" ];
  # };

  # These will be overridden by the included dogebox.nix file above, but set defaults.
  networking.wireless.enable = lib.mkDefault false;
  networking.networkmanager.enable = lib.mkForce false;
}
