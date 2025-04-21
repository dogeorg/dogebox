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
  };
  outputs = { self, nixpkgs, nixos-generators, flake-utils, ... } @ inputs: let
    dbxRelease = "v0.3.2-beta.3";

    base = arch: builder: format: nixos-generators.nixosGenerate {
      system = arch + "-linux";
      modules = [
        builder
        {
          nix.registry.nixpkgs.flake = nixpkgs;
        }
      ];
      format = format;
      specialArgs = {
        inherit arch dbxRelease;
        inherit inputs;
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
    t6 = base "aarch64" ./nix/builders/nanopc-t6/builder.nix "raw";

    vbox-x86_64 = base "x86_64" ./nix/builders/virtualbox/builder.nix "virtualbox";
    vm-x86_64 = base "x86_64" ./nix/builders/default/builder.nix "vm";

    iso-x86_64 = base "x86_64" ./nix/builders/iso/builder.nix "iso";
    iso-aarch64 = base "aarch64" ./nix/builders/iso/builder.nix "iso";

    qemu-x86_64 = base "x86_64" ./nix/builders/qemu/builder.nix "qcow";
    qemu-aarch64 = base "aarch64" ./nix/builders/qemu/builder.nix "qcow";

    devShell = {
      "x86_64-linux" = mkDevShell "x86_64-linux";
      "aarch64-linux" = mkDevShell "aarch64-linux";
    };
  };
}
