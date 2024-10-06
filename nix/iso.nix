{
  imports = [ ./base.nix ];

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/nixos";
      autoResize = true;
      fsType = "ext4";
    };
  };

  boot.growPartition = true;
  boot.loader.grub.device = "/dev/sda";
}
