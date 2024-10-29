{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = [
    pkgs.gnumake
    pkgs.nixos-generators
    pkgs.swig
    pkgs.git
    pkgs.parted
    pkgs.btrfs-progs
    pkgs.e2fsprogs
    pkgs.rsync
    pkgs.wget
    pkgs.simg2img
    pkgs.exfat
    pkgs.exfatprogs
  ];
}
