{ inputs, lib, config, pkgs, dbxRelease, specialArgs, modulesPath, ... }:

let
  flakeSource = specialArgs.flakeSource;
  imageName = "dogebox-${dbxRelease}-t6";

  baseRawImage = import "${toString modulesPath}/../lib/make-disk-image.nix" {
    inherit lib config pkgs;
    diskSize = "auto";
    format = "raw";
    name = imageName;
  };
in
{
  system.build.raw = lib.mkForce (pkgs.stdenv.mkDerivation {
    name = "dogebox-${dbxRelease}-t6.img";
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

  system.activationScripts.copyFlakeAndMark = {
    deps = [ "users" ];
    text = ''
      echo "[dbx setup] Copying flake source from ${flakeSource} to image /etc/nixos..."
      mkdir -p /etc/nixos
      ${pkgs.rsync}/bin/rsync -a --delete --exclude='.git' "${flakeSource}/" "/etc/nixos/"

      echo "[dbx setup] Marking build type as nanopc-t6..."
      mkdir -p /opt
      echo "nanopc-t6" > /opt/build-type

      echo "[dbx setup] Flake source copy and marking complete."
    '';
  };
}
