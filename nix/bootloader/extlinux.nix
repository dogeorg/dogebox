{ config, libs, pkgs, ... }:

let
  configDir = ./.;
in
{
  # Use the extlinux boot loader. (NixOS wants to enable GRUB by default)
  boot.loader.grub.enable = false;
  # Enables the generation of /boot/extlinux/extlinux.conf
  boot.loader.generic-extlinux-compatible.enable = true;

  # Copy self into build image.
  environment.etc = {
    "nixos/bootloader/extlinux.nix" = {
      source = "${configDir}/extlinux.nix";
    };
  };
}
