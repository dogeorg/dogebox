{
  imports = [ ../../dbx/base.nix ];

  /* Below copied from ${nixpkgs}/nixos/modules/virtualisation/virtualbox-image.nix */
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/nixos";
      autoResize = true;
      fsType = "ext4";
    };
  };

  boot.growPartition = true;
  boot.loader.grub.device = "/dev/sda";

  swapDevices = [{
    device = "/var/swap";
    size = 2048;
  }];

  virtualisation.virtualbox.guest.enable = true;

  system.activationScripts.buildType = {
    text = ''
      mkdir -p /opt
      echo "virtualbox" > /opt/build-type
    '';
  };
}
