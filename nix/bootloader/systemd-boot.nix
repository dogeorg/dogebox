{ config, libs, pkgs, ... }:

let
  configDir = ./.;
in
{
  # Use the GRUB 2 boot loader.
  # boot.loader.grub.enable = true;
  # boot.loader.grub.efiSupport = true;
  # boot.loader.grub.efiInstallAsRemovable = true;
  # boot.loader.efi.efiSysMountPoint = "/boot/efi";
  # Define on which hard drive you want to install Grub.
  # boot.loader.grub.device = "/dev/sda"; # or "nodev" for efi only
  boot.loader.systemd-boot.enable = true;

  # Copy self into build image.
  environment.etc = {
    "nixos/bootloader/systemd-boot.nix" = {
      source = "${configDir}/systemd-boot.nix";
    };
  };
}
