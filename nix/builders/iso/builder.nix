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

  system.activationScripts.copyFlakeAndMark = {
    deps = [ "users" ];
    text = ''
      echo "[dbx setup] Copying flake source from ${flakeSource} to image /etc/nixos..."
      mkdir -p /etc/nixos
      ${pkgs.rsync}/bin/rsync -a --delete --exclude='.git' "${flakeSource}/" "/etc/nixos/"

      echo "[dbx setup] Marking build type as iso..."
      mkdir -p /opt
      echo "iso" > /opt/build-type
      echo "[dbx setup] Marking as RO media..."
      touch /opt/ro-media

      echo "[dbx setup] Flake source copy and marking complete."
    '';
  };
}
