{
  pkgs,
  specialArgs,
  arch,
  dbxRelease,
  ...
}:

let
  flakeSource = specialArgs.flakeSource;
in
{
  virtualisation.diskSize = 8192;
  system.build.qcow2 = {
    imageName = "dogebox-${dbxRelease}-${arch}.qcow2";
  };

  system.activationScripts.copyflake = {
    deps = [ "users" ];
    text = ''
      mkdir -p /etc/nixos
      ${pkgs.rsync}/bin/rsync -a --delete --exclude='.git' "${flakeSource}/" "/etc/nixos/"
    '';
  };
}
