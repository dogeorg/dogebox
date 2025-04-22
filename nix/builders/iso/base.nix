{ lib, ... }:

{
  fileSystems = lib.mkDefault {
    "/" = {
      device = "/dev/disk/by-label/nixos"; # ISOs use this label
      autoResize = true;
      fsType = "ext4";
    };
  };
  boot.growPartition = true;
  boot.loader.grub.device = lib.mkDefault "/dev/sda"; # Needed for ISO generation
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;
  boot.loader.systemd-boot.enable = lib.mkDefault true;

  system.activationScripts.buildType = {
    text = ''
      mkdir -p /opt
      echo "iso" > /opt/build-type
    '';
  };
}
