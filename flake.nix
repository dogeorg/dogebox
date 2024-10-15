{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-24.05";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    upstreamDogeboxChannel = {
      url = "github:dogeorg/dogebox-nur-packages";
      flake = false;
    };
  };
  outputs = { self, nixpkgs, nixos-generators, upstreamDogeboxChannel,... } @ inputs: let
    developmentMode = builtins.getEnv "dev" == "1";

    devConfig = if developmentMode then
      builtins.fromJSON (builtins.readFile ./dev.json)
    else
      {};

    localDogeboxdPath = if (builtins.hasAttr "dogeboxd" devConfig) then devConfig.dogeboxd else null;
    localDpanelPath = if (builtins.hasAttr "dpanel" devConfig) then devConfig.dpanel else null;
    dogeboxNurPackagesPath = if (builtins.hasAttr "nur" devConfig) then devConfig.nur else upstreamDogeboxChannel;

    dbx = system: import (dogeboxNurPackagesPath + "/default.nix") {
      pkgs = import nixpkgs {
        system = system + "-linux";
      };
      localDogeboxdPath = localDogeboxdPath;
      localDpanelPath = localDpanelPath;
    };

    base = arch: builder: format: nixos-generators.nixosGenerate {
      system = arch + "-linux";
      modules = [ builder ];
      format = format;
      specialArgs = {
        inherit arch;
        dogebox = dbx arch;
      };
    };
  in {
    t6 = base "aarch64" ./nix/builders/nanopc-t6/builder.nix "raw";

    vbox-x86_64 = base "x86_64" ./nix/builders/virtualbox/builder.nix "virtualbox";
    vm-x86_64 = base "x86_64" ./nix/builders/default/builder.nix "vm";

    iso-x86_64 = base "x86_64" ./nix/builders/iso/builder.nix "iso";
    iso-aarch64 = base "aarch64" ./nix/builders/iso/builder.nix "iso";

    qemu-x86_64 = base "x86_64" ./nix/builders/qemu/builder.nix "qcow";
    qemu-aarch64 = base "aarch64" ./nix/builders/qemu/builder.nix "qcow";
  };
}
