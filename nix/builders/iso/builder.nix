{
  inputs,
  arch,
  pkgs,
  lib,
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

  system.activationScripts.copyFlakeAndMark = {
    deps = [ "users" ];
    text = ''
      echo "[ActivScript] Copying flake source from ${flakeSource} to image /etc/nixos..."
      mkdir -p /etc/nixos  # Target path within the image build environment
      ${pkgs.rsync}/bin/rsync -a --delete --exclude='.git' "${flakeSource}/" "/etc/nixos/"

      echo "[ActivScript] Marking build type as iso..."
      mkdir -p /opt
      echo "iso" > /opt/build-type
      echo "[ActivScript] Marking as RO media..."
      touch /opt/ro-media

      echo "[ActivScript] Flake source copy and marking complete."
    '';
  };
}
