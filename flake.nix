{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-24.11";
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dogeboxd = {
      url = "github:dogebox-wg/dogeboxd/dev-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dkm = {
      url = "github:dogebox-wg/dkm/dev-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dogebox-nur-packages = {
      url = "github:dogebox-wg/dogebox-nur-packages";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nixpkgs, nixos-generators, flake-utils, ... } @ inputs: let
    dbxRelease = "v0.3.2-beta.3";

    builderBases = {
      iso = ./nix/builders/iso/base.nix;
      qemu = ./nix/builders/qemu/base.nix;
      virtualbox = ./nix/builders/virtualbox/base.nix;
      nanopc-t6 = ./nix/builders/nanopc-t6/base.nix;
      default = ./nix/builders/default/base.nix;
    };

    dbxEntryModule = ./nix/dbx/base.nix;
    commonModule = ./nix/os/common.nix;

    mkConfigModules = { builderType }: [
      (builderBases.${builderType} or (throw "Unsupported builderType: ${builderType}"))
      commonModule
      dbxEntryModule
    ];

    mkNixosSystem = { system, builderType }: nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit inputs dbxRelease builderType;
        flakeSource = self;
        arch = nixpkgs.lib.strings.removeSuffix "-linux" system;

        # These are the built packages, rather than the raw sources.
        dkm = inputs.dkm.packages.${system}.default;
        dogeboxd = inputs.dogeboxd.packages.${system}.default;
      };
      modules = mkConfigModules { inherit builderType; };
    };

    base = arch: builderType: builderSpecificModule: format:
      let
        system = arch + "-linux";
      in nixos-generators.nixosGenerate {
        inherit system format;
        modules = [ builderSpecificModule ] ++ (mkConfigModules { inherit builderType; });
        specialArgs = {
          inherit inputs dbxRelease builderType arch;
          flakeSource = self;
          dkm = inputs.dkm.packages.${system}.default;
          dogeboxd = inputs.dogeboxd.packages.${system}.default;

          # Explicitly only pass the rk3588 firmware for the nanopc-t6 builder.
          nanopc-t6-rk3588-firmware = inputs.dogebox-nur-packages.legacyPackages.${system}.rk3588-firmware;
        };
    };

    mkDevShell = system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in pkgs.mkShell {
      buildInputs = [
        pkgs.gnumake
        pkgs.nixos-generators
        pkgs.swig
        pkgs.git
        pkgs.parted
        pkgs.btrfs-progs
        pkgs.e2fsprogs
        pkgs.rsync
        pkgs.wget
        pkgs.simg2img
        pkgs.exfat
        pkgs.exfatprogs
      ];
    };
  in {
    t6 = base "aarch64" "nanopc-t6" ./nix/builders/nanopc-t6/builder.nix "raw";
    vbox-x86_64 = base "x86_64" "virtualbox" ./nix/builders/virtualbox/builder.nix "virtualbox";
    vm-x86_64 = base "x86_64" "default" ./nix/builders/default/builder.nix "vm"; # Assuming builderType 'default'
    iso-x86_64 = base "x86_64" "iso" ./nix/builders/iso/builder.nix "iso";
    iso-aarch64 = base "aarch64" "iso" ./nix/builders/iso/builder.nix "iso";
    qemu-x86_64 = base "x86_64" "qemu" ./nix/builders/qemu/builder.nix "qcow";
    qemu-aarch64 = base "aarch64" "qemu" ./nix/builders/qemu/builder.nix "qcow";

    nixosConfigurations = {
      dogeboxos-iso-x86_64 = mkNixosSystem { system = "x86_64-linux"; builderType = "iso"; };
      dogeboxos-iso-aarch64 = mkNixosSystem { system = "aarch64-linux"; builderType = "iso"; };
      dogeboxos-qemu-x86_64 = mkNixosSystem { system = "x86_64-linux"; builderType = "qemu"; };
      dogeboxos-qemu-aarch64 = mkNixosSystem { system = "aarch64-linux"; builderType = "qemu"; };
      dogeboxos-vbox-x86_64 = mkNixosSystem { system = "x86_64-linux"; builderType = "virtualbox"; };
      dogeboxos-t6-aarch64 = mkNixosSystem { system = "aarch64-linux"; builderType = "nanopc-t6"; };
      dogeboxos-vm-x86_64 = mkNixosSystem { system = "x86_64-linux"; builderType = "default"; };
    };

    devShells = flake-utils.lib.eachDefaultSystem mkDevShell;
  };
}
