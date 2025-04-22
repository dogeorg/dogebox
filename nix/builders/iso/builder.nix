{
  arch,
  pkgs,
  dbxRelease,
  specialArgs,
  ...
}:

let
  flakeSource = specialArgs.flakeSource;
in
{
  isoImage.isoName = "dogebox-${dbxRelease}-${arch}.iso";
  isoImage.prependToMenuLabel = "DogeboxOS (";
  isoImage.appendToMenuLabel = ")";

  system.activationScripts.copyflake = {
    deps = [ "users" ];
    text = ''
      mkdir -p /etc/nixos
      ${pkgs.rsync}/bin/rsync -a --delete --exclude='.git' "${flakeSource}/" "/etc/nixos/"
      mkdir -p /opt
      echo "iso" > /opt/build-type
      touch /opt/ro-media
    '';
  };
}
