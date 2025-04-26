{ lib, pkgs, ... }:

{
  imports =
    [
      ./dkm.nix
      ./dogeboxd.nix
    ]
    ++ lib.optionals (builtins.pathExists "/opt/dogebox/nix/dogebox.nix") [
      /opt/dogebox/nix/dogebox.nix
    ];

  users.groups.dogebox = { };

  users.users.shibe = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "dogebox"
      "networkmanager"
    ];

    # Very temporary, until we have SSH key management in dpanel.
    password = "suchpass";
  };

  security.sudo.wheelNeedsPassword = false;

  # These will be overridden by the included dogebox.nix file above, but set defaults.
  networking.wireless.iwd.enable = lib.mkDefault true;
  networking.networkmanager.enable = lib.mkDefault true;
  networking.networkmanager.wifi.backend = lib.mkDefault "iwd";

  networking.firewall.enable = true;

  # These are all needed for the oneshot boot process above.
  environment.systemPackages = [
    pkgs.bash
    pkgs.nix
    pkgs.nixos-rebuild
    pkgs.git
    pkgs.wirelesstools
  ];
}
