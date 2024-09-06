{ config, lib, pkgs, ... }:

let dogebox = import <dogebox> { inherit pkgs; }; in
{
  environment.systemPackages = [
    dogebox.dogeboxd
  ];

  users.users.dogeboxd = {
    isSystemUser = true;
    group =  "dogebox";
    extraGroups = [];
  };

  systemd.tmpfiles.rules = [
    "d /opt/dogebox 0700 dogeboxd dogebox -"
  ];

  # TODO: Add /bin to $PATH

  systemd.services.dogeboxd = {
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      ExecStart = "${dogebox.dogeboxd}/dogeboxd/bin/dogeboxd --addr 0.0.0.0 --data /opt/dogebox --nix /opt/dogebox/nix --port 3000 --uiport 8080 --uidir ${dogebox.dogeboxd}/dpanel/src";
      Restart = "always";
      User = "dogeboxd";
      Group = "dogebox";
    };
  };

  security.wrappers.nixosrebuildswitch = {
    source = "${dogebox.dogeboxd}/dogeboxd/bin/nixosrebuildswitch";
    owner = "root";
    group = "root";
    setuid = true;
  };

  security.wrappers.machinectlstop = {
    source = "${dogebox.dogeboxd}/dogeboxd/bin/machinectlstop";
    owner = "root";
    group = "root";
    setuid = true;
  };
}
