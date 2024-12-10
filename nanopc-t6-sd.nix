{
  pkgs ? import <nixpkgs> {},
  stdenv ? pkgs.stdenv,
  fetchurl ? pkgs.fetchurl,
  ...
}:

stdenv.mkDerivation rec {
  name = "dogebox-t6-sd.img";
  src  = ./.;
  buildInputs = [
    pkgs.bash 
    pkgs.parted
    pkgs.simg2img
  ];
  buildCommand = ''
    mkdir -p $out
    T6_WORK_DIR="nixos-arm64"
    mkdir -p ''${T6_WORK_DIR}
    ln -s ${pkgs.pkgsCross.aarch64-multiplatform.ubootNanoPCT6}/idbloader.img ''${T6_WORK_DIR}/idbloader.img
    ln -s ${pkgs.pkgsCross.aarch64-multiplatform.ubootNanoPCT6}/u-boot.itb    ''${T6_WORK_DIR}/uboot.img
    ${pkgs.bash}/bin/bash ${src}/bin/extract-fs-from-disk-image.sh ${pkgs.dogebox-t6.img}/dogebox-*-t6.img ''${T6_WORK_DIR}
    if [[ ! -f ''${T6_WORK_DIR}/parameter.txt ]]; then
      cp ${src}/templates/parameter.txt ''${T6_WORK_DIR}/parameter.txt;
    fi
    ${pkgs.bash}/bin/bash ${src}/bin/make-sd-image.sh
  '';
}
