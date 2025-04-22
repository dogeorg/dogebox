{ inputs, ... }: # arch is implicitly x86_64 for default

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
in
{
  # Import the list of modules from the inner flake
  # Default builder might not have its own base.nix, adjust if it does
  imports = baseOsModules;

  # Add any builder-specific overrides here, e.g.:
  # boot.loader.grub.enable = true;
  # boot.loader.grub.device = "/dev/sda"; # or "nodev" for VMs

  # Activation script (kept from original)
  system.activationScripts.buildType = ''
    mkdir -p /opt
    echo "default" > /opt/build-type
  '';
}
