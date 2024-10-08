{ pkgs ? import <nixpkgs> {}, ... }:

let
  dogebox = import <dogebox> { inherit pkgs; };

  nanopc-T6File = pkgs.writeTextFile {
    name = "nanopc-T6.nix";
    text = builtins.readFile ./base.nix;
  };

  kernelConfigFile = pkgs.writeTextFile {
    name = "nanopc-T6_linux_defconfig";
    text = builtins.readFile ./nanopc-T6_linux_defconfig;
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

 firmwareFile = pkgs.writeTextFile {
   name = "firmware.nix";
   text = builtins.readFile ./firmware.nix;
 };
in
{
  imports = [
    ./base.nix
  ];

  system.activationScripts.copyFiles = ''
    mkdir -p /opt
    echo "nanopc-T6" >> /opt/build-type
    cp ${nanopc-T6File} /etc/nixos/configuration.nix
    cp ${kernelConfigFile} /etc/nixos/nanopc-T6_linux_defconfig
    cp ${baseFile} /etc/nixos/base.nix
    cp ${dogeboxFile} /etc/nixos/dogebox.nix
    cp ${dogeboxdFile} /etc/nixos/dogeboxd.nix
    cp ${dkmFile} /etc/nixos/dkm.nix
    cp ${firmwareFile} /etc/nixos/firmware.nix
  '';
}
