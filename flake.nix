{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-24.05";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nixpkgs, nixos-generators,... } @ inputs: let
    # Both of these MUST be updated to successfully build a new
    # release, otherwise nix will silently cache things.
    dbxRelease = "v0.3.1-beta";
    nurPackagesHash = "d532765fa6057f2fa146b34f0fcd648737b87bed";

    developmentMode = builtins.getEnv "dev" == "1";

    devConfig = if developmentMode then
      builtins.fromJSON (builtins.readFile ./dev.json)
    else
      {};

    localDogeboxdPath = if (builtins.hasAttr "dogeboxd" devConfig) then devConfig.dogeboxd else null;
    localDpanelPath = if (builtins.hasAttr "dpanel" devConfig) then devConfig.dpanel else null;
    dogeboxNurPackagesPath = if (builtins.hasAttr "nur" devConfig) then devConfig.nur else builtins.fetchGit {
      url = "https://github.com/dogeorg/dogebox-nur-packages.git";
      ref = "refs/tags/${dbxRelease}";
      rev = nurPackagesHash;
    };

    dbx = system: import (dogeboxNurPackagesPath + "/default.nix") {
      pkgs = import nixpkgs {
        system = system + "-linux";
      };
      inherit localDogeboxdPath localDpanelPath dbxRelease nurPackagesHash;
    };

    base = arch: builder: format: nixos-generators.nixosGenerate {
      system = arch + "-linux";
      modules = [ builder ];
      format = format;
      specialArgs = {
        inherit arch dbxRelease;
        dogebox = dbx arch;
      };
    };
  in {
    iso-aarch64    = base "aarch64" ./nix/builders/iso/builder.nix "iso";
    iso-x86_64     = base "x86_64" ./nix/builders/iso/builder.nix "iso";

    pve-aarch64    = base "aarch64" ./nix/builders/pve/builder.nix "proxmox-lxc";
    pve-x86_64     = base "x86_64" ./nix/builders/pve/builder.nix "proxmox-lxc";

    qemu-aarch64   = base "aarch64" ./nix/builders/qemu/builder.nix "qcow";
    qemu-x86_64    = base "x86_64" ./nix/builders/qemu/builder.nix "qcow";

    raw-aarch64    = base "aarch64" ./nix/builders/default/builder.nix "raw";
    raw-x86_64     = base "x86_64" ./nix/builders/default/builder.nix "raw";

    t6             = base "aarch64" ./nix/builders/nanopc-t6/builder.nix "raw";

    vbox-aarch64   = base "aarch64" ./nix/builders/virtualbox/builder.nix "virtualbox";
    vbox-x86_64    = base "x86_64" ./nix/builders/virtualbox/builder.nix "virtualbox";

    vm-aarch64     = base "aarch64" ./nix/builders/default/builder.nix "vm";
    vm-x86_64      = base "x86_64" ./nix/builders/default/builder.nix "vm";

    vmware-aarch64 = base "aarch64" ./nix/builders/vmware/builder.nix "vmware";
    vmware-x86_64  = base "x86_64" ./nix/builders/vmware/builder.nix "vmware";
  };
}
