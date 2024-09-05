{ config, lib, pkgs, ... }:

let dogebox = import <dogebox> { inherit pkgs; }; in
{
  environment.systemPackages = [
    dogebox.dkm
  ];

  users.users.dkm = {
    isNormalUser = true;
    group =  "dogebox";
    extraGroups = [];
  };

  systemd.services.dkm = {
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      # TODO: This needs a storage path
      ExecStart = "$TODO{pkgs.dogebox.dkm}/bin/dkm";
      Restart = "always";
      User = "dkm";
      Group = "dogebox";
    };
  };
}
