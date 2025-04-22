{ pkgs, specialArgs, dbxRelease, arch, ... }:

let
  flakeSource = specialArgs.flakeSource;
in
{
  system.activationScripts.copyFlakeAndMark = {
    deps = [ "users" ];
    text = ''
      echo "[dbx setup] Copying flake source from ${flakeSource} to image /etc/nixos..."
      mkdir -p /etc/nixos
      ${pkgs.rsync}/bin/rsync -a --delete --exclude='.git' "${flakeSource}/" "/etc/nixos/"

      echo "[dbx setup] Marking build type as pve..."
      mkdir -p /opt
      echo "pve" > /opt/build-type

      echo "[dbx setup] Flake source copy and marking complete."
    '';
  };
}
