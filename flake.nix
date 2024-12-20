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
    dbxRelease = "v0.3.2-beta.3";
    nurPackagesHash = "4e3a0c35aef994e3ec5516ccbb7c202a0cb8fb27";

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
    t6 = base "aarch64" ./nix/builders/nanopc-t6/builder.nix "raw";

    vbox-x86_64 = base "x86_64" ./nix/builders/virtualbox/builder.nix "virtualbox";
    vm-x86_64 = base "x86_64" ./nix/builders/default/builder.nix "vm";

    iso-x86_64 = base "x86_64" ./nix/builders/iso/builder.nix "iso";
    iso-aarch64 = base "aarch64" ./nix/builders/iso/builder.nix "iso";

    qemu-x86_64 = base "x86_64" ./nix/builders/qemu/builder.nix "qcow";
    qemu-aarch64 = base "aarch64" ./nix/builders/qemu/builder.nix "qcow";
  };
}
