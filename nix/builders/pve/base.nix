{ modulesPath, ... }:

{
  imports = [ 
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
    ../../dbx/base.nix
  ];

  system.activationScripts.buildType = {
    text = ''
      mkdir -p /opt
      echo "pve" > /opt/build-type
    '';
  };
}
