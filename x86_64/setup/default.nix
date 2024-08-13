{ config, libs, pkgs, ... }:

{
  systemd.services.initial-setup-check = {
    description = "";
    after = [ "network.target" ]; # We want the network config completed, as we'll override it if we go into setup mode
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = "yes";
      ExecStart = "/etc/nixos/setup/initial-setup-check.sh";
    };
  };
}
