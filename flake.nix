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

    dpanel = {
      url = "github:dogebox-wg/dpanel";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };

    dogeboxd = {
      url = "github:dogebox-wg/dogeboxd/dev-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
      inputs.dpanel-src.follows = "dpanel";
    };

    dkm = {
      url = "github:dogebox-wg/dkm/dev-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };

    dogebox-nur-packages = {
      url = "github:dogebox-wg/dogebox-nur-packages";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    {
      self,
      nixpkgs,
      nixos-generators,
      flake-utils,
      ...
    }@inputs:
    let
      dbxRelease = "v0.3.2-beta.3";

      builderBases = {
        iso = ./nix/builders/iso/base.nix;
        qemu = ./nix/builders/qemu/base.nix;
        nanopc-t6 = ./nix/builders/nanopc-t6/base.nix;
      };

      getCopyFlakeScript =
        system: self:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        ''
          mkdir -p /etc/nixos
          ${pkgs.rsync}/bin/rsync -a --delete --exclude='.git' "${self}/" "/etc/nixos/"
        '';

      getSetOptScript =
        builderType: isBaseBuilder:
        let
          isReadOnly = (builderType == "iso" || builderType == "nanopc-t6");
          mediaFile = if isReadOnly then "ro-media" else "rw-media";
        in
        ''
          mkdir -p /opt
          echo '${builderType}' > /opt/build-type
          touch /opt/${mediaFile}
        '';

      versionScript =
        let
          flakeLock = ./flake.lock;
          flakeLockContent = builtins.readFile flakeLock;
          flakeLockJson = builtins.fromJSON flakeLockContent;

          # We read these from the lock so that we only need to specify the flake
          # name, rather than the full flake URL, which has to contain versioning info.
          dbxdFlake = builtins.getFlake (
            "github:dogebox-wg/dogeboxd/" + flakeLockJson.nodes.dogeboxd.locked.rev
          );
          dpanelFlake = builtins.getFlake (
            "github:dogebox-wg/dpanel/" + flakeLockJson.nodes.dpanel.locked.rev
          );
          dkmFlake = builtins.getFlake ("github:dogebox-wg/dkm/" + flakeLockJson.nodes.dkm.locked.rev);
        in
        ''
          mkdir -p /opt/versioning

          # Write out our pretty release version.
          echo '${dbxRelease}' > /opt/versioning/dbx

          # Dump the entire flake.lock file into the versioning directory.
          echo '${flakeLockContent}' > /opt/versioning/flake.lock

          # Write out info about our flake inputs for easy access.
          mkdir -p /opt/versioning/dogeboxd
          echo '${dbxdFlake.rev}' > /opt/versioning/dogeboxd/rev
          echo '${dbxdFlake.narHash}' > /opt/versioning/dogeboxd/hash

          mkdir -p /opt/versioning/dkm
          echo '${dkmFlake.rev}' > /opt/versioning/dkm/rev
          echo '${dkmFlake.narHash}' > /opt/versioning/dkm/hash

          mkdir -p /opt/versioning/dpanel
          echo '${dpanelFlake.rev}' > /opt/versioning/dpanel/rev
          echo '${dpanelFlake.narHash}' > /opt/versioning/dpanel/hash
        '';

      dbxEntryModule = ./nix/dbx/base.nix;
      commonModule = ./nix/os/common.nix;

      mkConfigModules =
        {
          system,
          builderType,
          isBaseBuilder,
        }:
        [
          (builderBases.${builderType} or (throw "Unsupported builderType: ${builderType}"))
          commonModule
          dbxEntryModule
          (
            { ... }:
            {
              system.activationScripts.copyFlake = getCopyFlakeScript system self;
              system.activationScripts.setOpt = getSetOptScript builderType isBaseBuilder;
              system.activationScripts.versioning = versionScript;
            }
          )
        ];

      getSpecialArgs = arch: system: builderType: {
        inherit
          inputs
          dbxRelease
          builderType
          arch
          ;

        # These are the built packages, rather than the raw sources.
        dkm = inputs.dkm.packages.${system}.default;
        dogeboxd = inputs.dogeboxd.packages.${system}.default;

        # Explicitly only pass the rk3588 firmware for the nanopc-t6 builder.
        nanopc-t6-rk3588-firmware = inputs.dogebox-nur-packages.legacyPackages.${system}.rk3588-firmware;
      };

      mkNixosSystem =
        { system, builderType }:
        let
          arch = nixpkgs.lib.strings.removeSuffix "-linux" system;
          isBaseBuilder = false;
        in
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = mkConfigModules { inherit system builderType isBaseBuilder; };
          specialArgs = getSpecialArgs arch system builderType;
        };

      base =
        arch: builderType: builderSpecificModule: format:
        let
          system = arch + "-linux";
          isBaseBuilder = false;
        in
        nixos-generators.nixosGenerate {
          inherit system format;
          modules = [
            builderSpecificModule
          ] ++ (mkConfigModules { inherit system builderType isBaseBuilder; });
          specialArgs = getSpecialArgs arch system builderType;
        };

      ## Development Scripts & tools below this point.

      mkDevShell =
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        pkgs.mkShell {
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

      qemu-aarch64 = base "aarch64" "qemu" ./nix/builders/qemu/builder.nix "qcow";

      getLaunchAArch64Script =
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        pkgs.writeShellApplication {
          name = "launch";
          text = ''
            temp_qcow2=$(mktemp -d)/nixos.qcow2

            cp ${qemu-aarch64}/nixos.qcow2 "''${temp_qcow2}"
            chmod 777 "''${temp_qcow2}"

            ${pkgs.qemu}/bin/qemu-system-aarch64 \
              -machine virt,highmem=off \
              -cpu cortex-a72 \
              -m 2048 \
              -bios /opt/homebrew/share/qemu/edk2-aarch64-code.fd \
              -drive if=none,file="''${temp_qcow2}",format=qcow2,id=hd \
              -device virtio-blk-device,drive=hd \
              -netdev user,id=net0,hostfwd=tcp::2222-:22,hostfwd=tcp::3000-:3000,hostfwd=tcp::8080-:8080 \
              -device virtio-net-device,netdev=net0 \
              -device virtio-serial-device \
              -chardev vc,id=virtcon \
              -device virtconsole,chardev=virtcon

            rm "''${temp_qcow2}"
          '';
        };

    in
    {
      inherit qemu-aarch64;

      t6 = base "aarch64" "nanopc-t6" ./nix/builders/nanopc-t6/builder.nix "raw";
      iso-x86_64 = base "x86_64" "iso" ./nix/builders/iso/builder.nix "iso";
      iso-aarch64 = base "aarch64" "iso" ./nix/builders/iso/builder.nix "iso";
      qemu-x86_64 = base "x86_64" "qemu" ./nix/builders/qemu/builder.nix "qcow";

      nixosConfigurations = {
        dogeboxos-iso-x86_64 = mkNixosSystem {
          system = "x86_64-linux";
          builderType = "iso";
        };
        dogeboxos-iso-aarch64 = mkNixosSystem {
          system = "aarch64-linux";
          builderType = "iso";
        };
        dogeboxos-qemu-x86_64 = mkNixosSystem {
          system = "x86_64-linux";
          builderType = "qemu";
        };
        dogeboxos-qemu-aarch64 = mkNixosSystem {
          system = "aarch64-linux";
          builderType = "qemu";
        };
        dogeboxos-t6-aarch64 = mkNixosSystem {
          system = "aarch64-linux";
          builderType = "nanopc-t6";
        };
      };

      devShells = flake-utils.lib.eachDefaultSystem mkDevShell;

      apps = flake-utils.lib.eachDefaultSystemMap (system: {
        launch-aarch64 = {
          type = "app";
          program = "${getLaunchAArch64Script system}/bin/launch";
        };
      });

      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-rfc-style;
      formatter.aarch64-linux = nixpkgs.legacyPackages.aarch64-linux.nixfmt-rfc-style;
    };
}
