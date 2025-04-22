{ pkgs, dbxRelease, specialArgs, arch, ... }:

let
  flakeSource = specialArgs.flakeSource;
in
{
  vmware.memorySize = 4096;
  vmware.vmDerivationName = "dogebox";
  vmware.vmName = "Dogebox";
  vmware.vmFileName = "dogebox-${dbxRelease}-${arch}.vmdk";

  system.activationScripts.copyflake = {
    deps = [ "users" ];
    text = ''
      mkdir -p /etc/nixos
      ${pkgs.rsync}/bin/rsync -a --delete --exclude='.git' "${flakeSource}/" "/etc/nixos/"
    '';
  };
}
