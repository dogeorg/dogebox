{ config, lib, pkgs, ... }:

let
  dogebox = import <dogebox> { inherit pkgs; };
in
{
  environment.systemPackages = [
    pkgs.systemd
    pkgs.nixos-rebuild
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
      Environment = "PATH=/run/wrappers/bin:${pkgs.systemd}/bin:${pkgs.nixos-rebuild}/bin:${pkgs.coreutils}/bin:${pkgs.bash}/bin:$PATH";
    };
  };

  networking.firewall.allowedTCPPorts = [ 3000 8080 ];

  security.wrappers.nixosrebuildboot = {
    source = "${dogebox.dogeboxd}/dogeboxd/bin/nixosrebuildboot";
    owner = "root";
    group = "root";
    setuid = true;
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

  security.wrappers.reboot = {
    source = "${pkgs.systemd}/bin/reboot";
    owner = "root";
    group = "root";
    setuid = true;
  };

  # TEMPORARY. Remove this when we can figure out how to point it to _just_ the wrappers?
  security.sudo.extraRules = [
    {
      users = [ "dogeboxd" ];
      commands = [ {
        command = "ALL";
        options = [ "NOPASSWD" ];
      } ];
    }
  ];
}
