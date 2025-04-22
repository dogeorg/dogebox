{ pkgs, specialArgs, dbxRelease, arch, ... }:

let
  flakeSource = specialArgs.flakeSource;
in
{
  vm.imageName = "dogebox-${dbxRelease}-${arch}.vmdk";

  system.activationScripts.copyflake = {
    deps = [ "users" ];
    text = ''
      mkdir -p /etc/nixos
      ${pkgs.rsync}/bin/rsync -a --delete --exclude='.git' "${flakeSource}/" "/etc/nixos/"
    '';
  };
}
