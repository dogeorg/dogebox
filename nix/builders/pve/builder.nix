{ pkgs, specialArgs, dbxRelease, arch, ... }:

let
  flakeSource = specialArgs.flakeSource;
in
{
  system.activationScripts.copyflake = {
    deps = [ "users" ];
    text = ''
      mkdir -p /etc/nixos
      ${pkgs.rsync}/bin/rsync -a --delete --exclude='.git' "${flakeSource}/" "/etc/nixos/"
    '';
  };
}
