{
  pkgs,
  lib,
  specialArgs,
  arch,
  dbxRelease, 
  ...
}:

let
  flakeSource = specialArgs.flakeSource;
in
{
  virtualbox.memorySize = 4096;
  virtualbox.vmDerivationName = "dogebox";
  virtualbox.vmName = "Dogebox";
  virtualbox.vmFileName = "dogebox-${dbxRelease}-${arch}.ova";
  virtualisation.virtualbox.guest.enable = true;

  system.activationScripts.copyflake = {
    deps = [ "users" ];
    text = ''
      mkdir -p /etc/nixos
      ${pkgs.rsync}/bin/rsync -a --delete --exclude='.git' "${flakeSource}/" "/etc/nixos/"
    '';
  };
}
