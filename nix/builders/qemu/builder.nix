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

  system.activationScripts.copyFlakeAndMark = {
    deps = [ "users" ];
    text = ''
      echo "[dbx setup] Copying flake source from ${flakeSource} to image /etc/nixos..."
      mkdir -p /etc/nixos
      ${pkgs.rsync}/bin/rsync -a --delete --exclude='.git' "${flakeSource}/" "/etc/nixos/"

      echo "[dbx setup] Marking build type as qemu..."
      mkdir -p /opt
      echo "qemu" > /opt/build-type

      echo "[dbx setup] Flake source copy and marking complete."
    '';
  };
}
