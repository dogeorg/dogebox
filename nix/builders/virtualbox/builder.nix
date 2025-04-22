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

  system.activationScripts.copyFlakeAndMark = {
    deps = [ "users" ];
    text = ''
      echo "[dbx setup] Copying flake source from ${flakeSource} to image /etc/nixos..."
      mkdir -p /etc/nixos
      ${pkgs.rsync}/bin/rsync -a --delete --exclude='.git' "${flakeSource}/" "/etc/nixos/"

      echo "[dbx setup] Marking build type as virtualbox..."
      mkdir -p /opt
      echo "virtualbox" > /opt/build-type

      echo "[dbx setup] Flake source copy and marking complete."
    '';
  };
}
