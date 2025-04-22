{
  description = "NixOS configuration flake for Dogebox OS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    dogeboxd.url = "github:dogebox-wg/dogeboxd/dev-flake";
    dkm.url = "github:dogebox-wg/dkm/dev-flake";
  };

  outputs = { self, nixpkgs, dogeboxd, dkm, ... }@inputs:
  let
    coreModules = [
      ./dbx/base.nix
      ({ pkgs, ... }: {
        nix.package = pkgs.nixVersions.stable;
        nix.extraOptions = ''
          experimental-features = nix-command flakes
        '';
      })
    ] ++ nixpkgs.lib.optionals (builtins.pathExists "./builder-base.nix") [
      ./builder-base.nix
    ] ++ nixpkgs.lib.optionals (builtins.pathExists "/etc/nixos/nix/builder-base.nix") [
      /etc/nixos/nix/builder-base.nix
    ];

    mkDogeboxOS = { system, extraModules ? [] }:
      let
        allModules = coreModules ++ extraModules;
      in
      {
        config = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = allModules;
        };
        modules = allModules;
      };

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