{ lib, pkgs, config, specialArgs, ... }:

let
  builderType = specialArgs.builderType or "unknown";
in
{
  options.dogebox.builderType = lib.mkOption {
    type = lib.types.str;
    internal = true;
    description = "The type of builder used (e.g., iso, qemu).";
  };

  config = {
    dogebox.builderType = builderType;
    nix.registry.nixpkgs.flake = specialArgs.inputs.nixpkgs;
    environment.systemPackages = [ pkgs.rsync ];
    system.configurationRevision = lib.mkIf (specialArgs.inputs.self ? rev) specialArgs.inputs.self.rev;
  };
}
