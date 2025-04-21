{
  description = "NixOS configuration flake for Dogebox OS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11"; # Placeholder
    dogeboxd.url = "github:dogebox-wg/dogeboxd/dev-flake"; # Placeholder
    dkm.url = "github:dogebox-wg/dkm/dev-flake"; # Placeholder
    # Removed hardware input as it wasn't used after merge
  };

  outputs = { self, nixpkgs, dogeboxd, dkm, ... }@inputs: # Removed flakeSourcePath, hardware
  let
    # Define the common core modules used by all configurations
    coreModules = [
      # Common base configuration
      # Path relative to flake.nix (assuming dbx is at flake root ../dbx)
      ./dbx/base.nix # Ensure this path is correct relative to flake.nix

      # Basic flake settings needed for the OS itself
      ({ pkgs, ... }: {
        nix.package = pkgs.nixVersions.stable;
        nix.extraOptions = ''
          experimental-features = nix-command flakes
        '';
        # Removed environment.etc and system.configurationRevision
      })
    ] ++ nixpkgs.lib.optionals (builtins.pathExists "/etc/nixos/builder-base.nix") [
      /etc/nixos/builder-base.nix
    ];

    # Helper function to create a NixOS configuration AND expose its modules
    mkDogeboxOS = { system, extraModules ? [] }:
      let
        allModules = coreModules ++ extraModules;
      in
      {
        config = nixpkgs.lib.nixosSystem {
           inherit system;
           specialArgs = { inherit inputs; }; # Pass outer flake inputs
           modules = allModules;
         };
         modules = allModules;
      };

    # Store the results of mkDogeboxOS
    systemConfigs = {
      "dogeboxos-x86_64" = mkDogeboxOS { system = "x86_64-linux"; };
      "dogeboxos-aarch64" = mkDogeboxOS { system = "aarch64-linux"; };
    };

  in
  {
    nixosConfigurations = nixpkgs.lib.mapAttrs (name: value: value.config) systemConfigs;
    dogeboxosModules = nixpkgs.lib.mapAttrs (name: value: value.modules) systemConfigs;
  };
} 