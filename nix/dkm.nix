{ config, lib, pkgs, ... }:

let
  dogebox = import <dogebox> { inherit pkgs; };
  configDir = ./.;
in
{
  environment.systemPackages = [
    dogebox.dkm
  ];

  users.users.dkm = {
    isSystemUser = true;
    group =  "dogebox";
    extraGroups = [];
  };
  
  systemd.tmpfiles.rules = [
    "d /opt/dkm 0700 dkm dogebox -"
  ];

  systemd.services.dkm = {
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      ExecStart = "${dogebox.dkm}/bin/dkm --dir /opt/dkm";
      Restart = "always";
      User = "dkm";
      Group = "dogebox";
    };
  };

  # Copy self into build image.
  environment.etc = {
    "nixos/dkm.nix" = {
      source = "${configDir}/dkm.nix";
    };
  };
}
