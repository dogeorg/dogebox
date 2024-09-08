{ config, lib, pkgs, ... }:

let
  dogebox = import <dogebox> { inherit pkgs; };
  configDir = ./.;  
in
{
  imports = [
    ./dkm.nix
    ./dogeboxd.nix
  ] ++ lib.optionals (builtins.pathExists "/opt/dogebox/nix/dogebox.nix") [
    /opt/dogebox/nix/dogebox.nix
  ];

  users.motd = ''
+===================================================+
|                                                   |
|      ____   ___   ____ _____ ____   _____  __     |
|     |  _ \ / _ \ / ___| ____| __ ) / _ \ \/ /     |
|     | | | | | | | |  _|  _| |  _ \| | | \  /      |
|     | |_| | |_| | |_| | |___| |_) | |_| /  \      |
|     |____/ \___/ \____|_____|____/ \___/_/\_\     |
|                                                   |
+===================================================+
'';

  users.groups.dogebox = {};

  users.users.shibe = {
    isNormalUser = true;
    extraGroups = [ "wheel" "dogebox" ];

    # Very temporary, until we have SSH key management in dpanel.
    password = "suchpass";
  };

  # These will be overridden by the included dogebox.nix file above, but set defaults.
  networking.wireless.enable = lib.mkDefault false;
  networking.networkmanager.enable = lib.mkForce false;

  networking.firewall.enable = true;

  # Copy self into build image.
  environment.etc = {
    "nixos/dogebox.nix" = {
      source = "${configDir}/dogebox.nix";
    };
  };
}
