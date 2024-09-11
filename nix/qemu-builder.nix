{ pkgs, ... }:

let
  qemuFile = pkgs.writeTextFile {
    name = "qemu.nix";
    text = builtins.readFile ./qemu.nix;
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
  imports = [ ./qemu.nix ];

  system.activationScripts.copyFiles = ''
    mkdir -p /opt/nixos
    echo "qemu" >> /opt/build-type
    cp ${qemuFile} /etc/nixos/configuration.nix
    cp ${baseFile} /etc/nixos/base.nix
    cp ${dogeboxFile} /etc/nixos/dogebox.nix
    cp ${dogeboxdFile} /etc/nixos/dogeboxd.nix
    cp ${dkmFile} /etc/nixos/dkm.nix
  '';
}
