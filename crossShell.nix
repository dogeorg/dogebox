with import <nixpkgs> {
  crossSystem = {
    config = "aarch64-unknown-linux-gnu";
  };
};

mkShell {
  buildInputs = [
    swig
    git
    parted
    btrfs-progs
    e2fsprogs
    rsync
    wget
    simg2img
    exfat
    exfatprogs
    gnumake
    flex
    bison
    bc
    pkg-config
    ncurses
    elfutils
    openssl
    openssl.dev
    nixos-generators
  ];
}
