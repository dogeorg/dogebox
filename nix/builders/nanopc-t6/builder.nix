{ pkgs ? import <nixpkgs> {}, modulesPath, lib, config, dbxRelease, ... }:

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

  imageName = "dogebox-${dbxRelease}-t6";

  # Override make-disk-image to pass in values that aren't properly exposed via nixos-generators
  # https://github.com/nix-community/nixos-generators/blob/master/formats/raw.nix#L23-L27
  baseRawImage = import "${toString modulesPath}/../lib/make-disk-image.nix" {
    inherit lib config pkgs;
    diskSize = "auto";
    format = "raw";
    name = imageName;
  };
in
{
  imports = [
    ./base.nix
  ];

  # These aren't used directly, but are consumed by ubootNanoPCT6 so need to be explicitly whitelisted.
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "arm-trusted-firmware-rk3588"
    "rkbin"
  ];

  system.build.raw = lib.mkForce (pkgs.stdenv.mkDerivation {
    name = "dogebox-t6.img";
    src = ./.;
    buildInputs = [
      baseRawImage
      pkgs.bash
      pkgs.parted
      pkgs.simg2img
    ];
    buildCommand = ''
      mkdir -p $out

      ln -s ${pkgs.ubootNanoPCT6}/idbloader.img $out/idbloader.img
      ln -s ${pkgs.ubootNanoPCT6}/u-boot.itb $out/uboot.img
      ${pkgs.bash}/bin/bash $src/scripts/extract-fs-from-disk-image.sh ${baseRawImage}/nixos.img $out/
      cp $src/templates/parameter.txt $out/
      ${pkgs.bash}/bin/bash $src/scripts/make-sd-image.sh $out/ ${imageName}.img

      # Only copy the resulting image, we don't care about other intermediaries.
      mv $out/dogebox-*.img /tmp
      rm -Rf $out/*
      mv /tmp/dogebox-*.img $out/
    '';
  });

  system.activationScripts.copyFiles = ''
    mkdir -p /opt
    echo "nanopc-T6" > /opt/build-type

    # Even though the T6 image can technically run off the microsd card
    # the EMMC is going to be a much better experience, so force installation.
    touch /opt/ro-media

    cp ${nanopc-T6File} /etc/nixos/configuration.nix
    cp ${kernelConfigFile} /etc/nixos/nanopc-T6_linux_defconfig
    cp ${baseFile} /etc/nixos/base.nix
    cp ${dogeboxFile} /etc/nixos/dogebox.nix
    cp ${dogeboxdFile} /etc/nixos/dogeboxd.nix
    cp ${dkmFile} /etc/nixos/dkm.nix
    cp ${firmwareFile} /etc/nixos/firmware.nix
  '';
}
