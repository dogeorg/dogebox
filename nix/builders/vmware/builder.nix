{ pkgs, dbxRelease, specialArgs, arch, ... }:

let
  flakeSource = specialArgs.flakeSource;
in
{
  vmware.memorySize = 4096;
  vmware.vmDerivationName = "dogebox";
  vmware.vmName = "Dogebox";
  vmware.vmFileName = "dogebox-${dbxRelease}-${arch}.vmdk";

  system.activationScripts.copyFlakeAndMark = {
    deps = [ "users" ];
    text = ''
      echo "[dbx setup] Copying flake source from ${flakeSource} to image /etc/nixos..."
      mkdir -p /etc/nixos
      ${pkgs.rsync}/bin/rsync -a --delete --exclude='.git' "${flakeSource}/" "/etc/nixos/"

      echo "[dbx setup] Marking build type as vmware..."
      mkdir -p /opt
      echo "vmware" > /opt/build-type

      echo "[dbx setup] Flake source copy and marking complete."
    '';
  };
}
