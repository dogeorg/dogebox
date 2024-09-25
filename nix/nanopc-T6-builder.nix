{ pkgs, ... }:

let
  nanopc-T6File = pkgs.writeTextFile {
    name = "nanopc-T6.nix";
    text = builtins.readFile ./nanopc-T6.nix;
  };

  baseFile = pkgs.writeTextFile {
    name = "base.nix";
    text = builtins.readFile ./base.nix;
  };

  dogeboxFile = pkgs.writeTextFile {
    name = "dogebox.nix";
    text = builtins.readFile ./dogebox.nix;
  };

  dogeboxdFile = pkgs.writeTextFile {
    name = "dogeboxd.nix";
    text = builtins.readFile ./dogeboxd.nix;
  };

  dkmFile = pkgs.writeTextFile {
    name = "dkm.nix";
    text = builtins.readFile ./dkm.nix;
  };
in
{
  imports = [ ./nanopc-T6.nix ];

  system.activationScripts.copyFiles = ''
    mkdir -p /opt/nixos
    echo "nanopc-T6" >> /opt/build-type
    cp ${nanopc-T6File} /etc/nixos/configuration.nix
    cp ${baseFile} /etc/nixos/base.nix
    cp ${dogeboxFile} /etc/nixos/dogebox.nix
    cp ${dogeboxdFile} /etc/nixos/dogeboxd.nix
    cp ${dkmFile} /etc/nixos/dkm.nix
  '';
}
