{ inputs, pkgs, lib, specialArgs, ... }:

let
  # Evaluate the inner flake configuration with overrides
  innerFlakeOutputsFunc = (import "${inputs.self}/nix/flake.nix").outputs;
  innerFlakeArgs = {
      self = { # Provide self for inner flake evaluation context
          inputs = {
              inherit (inputs) nixpkgs dogeboxd dkm;
          };
      };
      inherit (inputs) nixpkgs dogeboxd dkm;
      lib = inputs.nixpkgs.lib;
      flakeSourcePath = inputs.self;
  };
  evaluatedInnerOutputs = innerFlakeOutputsFunc innerFlakeArgs;

  # Select the x86_64 module list
  baseOsModules = evaluatedInnerOutputs.dogeboxosModules."dogeboxos-x86_64";

  flakeSource = specialArgs.flakeSource;
  # Define arch based on specialArgs or default to x86_64 if necessary
  arch = specialArgs.arch or "x86_64"; 
  dbxRelease = specialArgs.dbxRelease or "unknown"; # Get release info
in
{
  # Import the list of modules from the inner flake
  # Default builder might not have its own base.nix, adjust if it does
  imports = baseOsModules;

  # Default/VM specific settings
  format.vm.imageName = "dogebox-${dbxRelease}-${arch}.vmdk"; # Or other common VM format

  # Activation script to run during image build to copy flake source
  system.activationScripts.copyFlakeAndMark = {
    deps = [ "users" ];
    text = ''
      echo "[ActivScript] Copying flake source from ${flakeSource} to image /etc/nixos..."
      mkdir -p /etc/nixos
      ${pkgs.rsync}/bin/rsync -a --delete --exclude='.git' "${flakeSource}/" "/etc/nixos/"

      echo "[ActivScript] Marking build type as default..."
      mkdir -p /opt
      echo "default" > /opt/build-type

      echo "[ActivScript] Flake source copy and marking complete."
    '';
  };

  # Ensure no *other* activation scripts are defined here unless intended for build time
  # Add any builder-specific overrides here, e.g.:
  # boot.loader.grub.enable = true;
  # boot.loader.grub.device = "/dev/sda"; # or "nodev" for VMs
}
