{ modulesPath, ... }:

{
  imports = [ 
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
    ../dbx/base.nix
  ];

}
