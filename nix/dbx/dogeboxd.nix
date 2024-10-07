{ config, lib, pkgs, /*rm*/dogebox ? import <dogebox>,/*rm*/... }:

/*inject*/
{
  environment.systemPackages = [
    pkgs.systemd
    pkgs.nixos-rebuild
    dogebox.dogeboxd
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

  users.users.dogeboxd = {
    isSystemUser = true;
    group =  "dogebox";
    extraGroups = [];
  };

  systemd.tmpfiles.rules = [
    "d /opt/dogebox 0700 dogeboxd dogebox -"
  ];

  systemd.services.dogeboxd = {
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      ExecStart = "/run/wrappers/bin/dogeboxd --addr 0.0.0.0 --data /opt/dogebox --nix /opt/dogebox/nix --containerlogdir /opt/dogebox/logs --port 3000 --uiport 8080 --uidir ${dogebox.dogeboxd}/dpanel/src";
      Restart = "always";
      User = "dogeboxd";
      Group = "dogebox";
      Environment = "PATH=/run/wrappers/bin:${pkgs.systemd}/bin:${pkgs.nixos-rebuild}/bin:${pkgs.coreutils}/bin:${pkgs.bash}/bin:$PATH";
    };
  };

  networking.firewall.allowedTCPPorts = [ 3000 8080 ];

  security.wrappers._dbxroot = {
    source = "${dogebox.dogeboxd}/dogeboxd/bin/_dbxroot";
    owner = "root";
    group = "root";
    setuid = true;
  };

  # This wrapper is to ensure dogeboxd can listen on port :80
  # for it's internal router. This is never exposed outside the host.
  security.wrappers.dogeboxd = {
    source = "${dogebox.dogeboxd}/dogeboxd/bin/dogeboxd";
    owner = "dogeboxd";
    group = "dogebox";
    capabilities = "cap_net_bind_service=+ep";
  };

  # This wrapper grants no special powers, but makes the binary
  # available system-wide, so that it can be used by systemd init
  # for checking if containers should start at boot (when not in recovery mode)
  security.wrappers.dbx = {
    source = "${dogebox.dogeboxd}/dogeboxd/bin/dbx";
    owner = "dogeboxd";
    group = "dogebox";
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
