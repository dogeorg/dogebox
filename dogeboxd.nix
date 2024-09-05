{ config, lib, pkgs, ... }:

let dogebox = import <dogebox> { inherit pkgs; }; in
{
  environment.systemPackages = [
    dogebox.dogeboxd
  ];

  users.users.dogeboxd = {
    isNormalUser = true;
    group =  "dogebox";
    extraGroups = [];
  };

  systemd.services.dogeboxd = {
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      # TODO: This needs a storage path
      ExecStart = "${dogebox.dogeboxd}/build/dogeboxd";
      Restart = "always";
      User = "dogeboxd";
      Group = "dogebox";
    };
  };
}
