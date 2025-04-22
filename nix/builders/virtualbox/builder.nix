{
  pkgs,
  lib,
  specialArgs,
  arch,
  dbxRelease, 
  ...
}:

let
  vboxFile = pkgs.writeTextFile {
    name = "vbox.nix";
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

  virtualbox.memorySize = 4096;
  virtualbox.vmDerivationName = "dogebox";
  virtualbox.vmName = "Dogebox";
  virtualbox.vmFileName = "dogebox-${dbxRelease}-${arch}.ova";

  virtualisation.virtualbox.guest.enable = true;
  format.virtualbox.imageName = "dogebox-${dbxRelease}-${arch}.ova";

  system.activationScripts.copyFiles = ''
    mkdir /opt
    echo "vbox" > /opt/build-type
    cp ${vboxFile} /etc/nixos/configuration.nix
    cp ${baseFile} /etc/nixos/base.nix
    cp ${dogeboxFile} /etc/nixos/dogebox.nix
    cp ${dogeboxdFile} /etc/nixos/dogeboxd.nix
    cp ${dkmFile} /etc/nixos/dkm.nix
  '';

  # Activation script to run during image build to copy flake source
  system.activationScripts.copyFlakeAndMark = {
    deps = [ "users" ];
    text = ''
      echo "[ActivScript] Copying flake source from ${flakeSource} to image /etc/nixos..."
      mkdir -p /etc/nixos
      ${pkgs.rsync}/bin/rsync -a --delete --exclude='.git' "${flakeSource}/" "/etc/nixos/"

      echo "[ActivScript] Marking build type as virtualbox..."
      mkdir -p /opt
      echo "virtualbox" > /opt/build-type

      echo "[ActivScript] Flake source copy and marking complete."
    '';
  };

  system.activationScripts = lib.mkForce {};
}
