{ pkgs, ... }:

let
  vboxFile = pkgs.writeTextFile {
    name = "vbox.nix";
    text = builtins.readFile ./vbox.nix;
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
  imports = [ ./vbox.nix ];

  system.activationScripts.copyFiles = ''
    mkdir -p /opt/nixos
    echo "vbox" >> /opt/build-type
    cp ${vboxFile} /etc/nixos/configuration.nix
    cp ${baseFile} /etc/nixos/base.nix
    cp ${dogeboxFile} /etc/nixos/dogebox.nix
    cp ${dogeboxdFile} /etc/nixos/dogeboxd.nix
    cp ${dkmFile} /etc/nixos/dkm.nix
  '';
}
