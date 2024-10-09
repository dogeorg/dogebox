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

    localDogeboxdPath = if devConfig.dogeboxd != null then devConfig.dogeboxd else null;
    dogeboxNurPackagesPath = if devConfig.nur != null then devConfig.nur else upstreamDogeboxChannel;

    dbx = system: import (dogeboxNurPackagesPath + "/default.nix") {
      pkgs = import nixpkgs {
        system = system;
      };
      localDogeboxdPath = localDogeboxdPath;
    };

    dbxArm64 = dbx "aarch64-linux";
    dbxX64 = dbx "x86_64-linux";

    base = system: builder: format: dbx: nixos-generators.nixosGenerate {
      system = system;
      modules = [ builder ];
      format = format;
      specialArgs = {
        dogebox = dbx;
      };
    };
  in {
    t6 = base "aarch64-linux" ./nix/builders/nanopc-t6/builder.nix "raw" dbxArm64;
    vbox-x86_64 = base "x86_64-linux" ./nix/builders/virtualbox/builder.nix "virtualbox" dbxX64;
    vm-x86_64 = base "x86_64-linux" ./nix/builders/default/builder.nix "vm" dbxX64;

    iso-x86_64 = base "x86_64-linux" ./nix/builders/iso/builder.nix "install-iso" dbxX64;
    iso-aarch64 = base "aarch64-linux" ./nix/builders/iso/builder.nix "install-iso" dbxArm64;
  };
}
