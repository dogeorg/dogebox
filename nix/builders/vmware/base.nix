{
  imports = [ ../../dbx/base.nix ];

  /* Below copied from ${nixpkgs}/nixos/modules/virtualization/vmware-image.nix */

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    autoResize = true;
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/ESP";
    fsType = "vfat";
  };

  boot.growPartition = true;

  boot.loader.grub = {
    device = "nodev";
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  virtualisation.vmware.guest.enable = true;

  system.activationScripts.buildType = {
    text = ''
      mkdir -p /opt
      echo "vmware" > /opt/build-type
    '';
  };
}
