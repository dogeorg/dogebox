{ inputs, arch, pkgs, lib, dbxRelease, ... }:

let
  # Evaluate the inner flake configuration with overrides
  innerFlakeOutputsFunc = (import "${inputs.self}/nix/flake.nix").outputs;
  innerFlakeArgs = {
      self = { inputs = { inherit (inputs) nixpkgs dogeboxd dkm; }; }; # Simplified self
      inherit (inputs) nixpkgs dogeboxd dkm;
      lib = inputs.nixpkgs.lib;
  };
  evaluatedInnerOutputs = innerFlakeOutputsFunc innerFlakeArgs;

  # Select the LIST OF MODULES based on arch
  osConfigName = "dogeboxos-${arch}"; # e.g., dogeboxos-x86_64 or dogeboxos-aarch64
  baseOsModules = evaluatedInnerOutputs.dogeboxosModules.${osConfigName} or (throw "Unsupported architecture for ISO: ${arch}");

  # Define cleaned source for copying
  cleanedFlakeSource = lib.cleanSource inputs.self;
  baseNix = lib.cleanSource ./base.nix;
in
{
  # Import the list of modules from the inner flake
  imports = baseOsModules;

  # ISO specific settings (kept from original)
  isoImage.isoName = "dogebox-${dbxRelease}-${arch}.iso";
  isoImage.prependToMenuLabel = "DogeboxOS (";
  isoImage.appendToMenuLabel = ")";

  # Set system configuration revision based on outer flake's git rev (if available)
  system.configurationRevision = lib.mkIf (inputs.self ? rev) inputs.self.rev;

  # Activation script to copy flake source and mark build type
  system.activationScripts.copyFlake =
    # Ensure this runs late, after potential mounting/setup
    lib.mkOrder 1000 ''
      echo "Copying source to /etc/nixos..."
      mkdir -p /etc/nixos
      # Copy the contents using the cleaned source path
      cp -rL ${cleanedFlakeSource}/nix/* /etc/nixos/

      # Mark build type and read-only media (as before)
      mkdir -p /opt
      touch /opt/ro-media # ISOs are read-only
      echo "iso" > /opt/build-type
    '';
}
