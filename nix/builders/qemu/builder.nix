{
  pkgs,
  lib,
  specialArgs,
  arch,
  dbxRelease, # Example of using passed args
  ...
}:

let
  qemuFile = pkgs.writeTextFile {
    name = "qemu.nix";
    text = builtins.readFile ./base.nix;
  };

  baseFile = pkgs.writeTextFile {
    name = "base.nix";
    text = builtins.readFile ../../dbx/base.nix;
  };

  dogeboxFile = pkgs.writeTextFile {
    name = "dogebox.nix";
    text = builtins.readFile ../../dbx/dogebox.nix;
  };

  dogeboxdFile = pkgs.writeTextFile {
    name = "dogeboxd.nix";
    text = builtins.readFile ../../dbx/dogeboxd.nix;
  };

  dkmFile = pkgs.writeTextFile {
    name = "dkm.nix";
    text = builtins.readFile ../../dbx/dkm.nix;
  };

  flakeSource = specialArgs.flakeSource;
in
{
  imports = [ ./base.nix ];

  # QEMU specific settings
  # Example: Adjust disk size or format if needed for QEMU
  virtualisation.diskSize = 8192; # Example: 8GB disk
  format.qcow.imageName = "dogebox-${dbxRelease}-${arch}.qcow2";

  # Activation script to run during image build to copy flake source
  system.activationScripts.copyFlakeAndMark = {
    deps = [ "users" ];
    text = ''
      echo "[ActivScript] Copying flake source from ${flakeSource} to image /etc/nixos..."
      mkdir -p /etc/nixos
      ${pkgs.rsync}/bin/rsync -a --delete --exclude='.git' "${flakeSource}/" "/etc/nixos/"

      echo "[ActivScript] Marking build type as qemu..."
      mkdir -p /opt
      echo "qemu" > /opt/build-type

      echo "[ActivScript] Flake source copy and marking complete."
    '';
  };

  # Ensure no activation scripts from this module are included
  system.activationScripts = lib.mkForce {};

  system.activationScripts.copyFiles = ''
    mkdir /opt
    echo "qemu" > /opt/build-type
    cp ${qemuFile} /etc/nixos/configuration.nix
    cp ${baseFile} /etc/nixos/base.nix
    cp ${dogeboxFile} /etc/nixos/dogebox.nix
    cp ${dogeboxdFile} /etc/nixos/dogeboxd.nix
    cp ${dkmFile} /etc/nixos/dkm.nix
  '';
}
