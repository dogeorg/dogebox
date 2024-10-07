{ lib, pkgs, ... }:

let
  dogebox = import <dogebox> { inherit pkgs; };
in
{
  imports = [
    ./dkm.nix
    ./dogeboxd.nix
  ] ++ lib.optionals (builtins.pathExists "/opt/dogebox/nix/dogebox.nix") [
    /opt/dogebox/nix/dogebox.nix
  ];

  users.groups.dogebox = {};

  users.users.shibe = {
    isNormalUser = true;
    extraGroups = [ "wheel" "dogebox" ];

    # Very temporary, until we have SSH key management in dpanel.
    password = "suchpass";
  };

  security.sudo.wheelNeedsPassword = false;

  # These will be overridden by the included dogebox.nix file above, but set defaults.
  networking.wireless.enable = lib.mkDefault false;
  networking.networkmanager.enable = lib.mkForce false;

  networking.firewall.enable = true;

  environment.etc."first-boot-script.sh" = {
    text = ''
      #${pkgs.bash}/bin/bash
      if [ ! -f /opt/first-boot-done ]; then
        echo "Sleeping for 10 seconds to ensure network is actually up..."
        sleep 10
        export NIX_PATH=nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos:nixos-config=/etc/nixos/configuration.nix:/nix/var/nix/profiles/per-user/root/channels
        export PATH=$PATH:${pkgs.git}/bin
        echo "Adding nixpkgs channel..."
        ${pkgs.nix}/bin/nix-channel --add https://nixos.org/channels/nixos-24.05 nixpkgs
        echo "Adding dogebox nix channel..."
        ${pkgs.nix}/bin/nix-channel --add https://github.com/dogeorg/dogebox-nur-packages/archive/v0.1.1-beta.tar.gz dogebox
        echo "Updating nix channel..."
        ${pkgs.nix}/bin/nix-channel --update
        echo "Rebuilding system..."
        # This MUST use boot and not switch, or you will get errors
        # about nix trying to replace in-process unit files (the one executing this script)
        ${pkgs.nixos-rebuild}/bin/nixos-rebuild boot
        echo "First boot commands completed."
        touch /opt/first-boot-done
        echo "Rebooting into new configuration..."
        sleep 3
        # Reboot to apply the new configuration we built above.
        reboot
      else
        echo "Not first boot, skipping."
      fi
    '';
    mode = "0755";
  };

  systemd.services.runOnceOnFirstBoot = {
    description = "[DOGEBOX] Initial Dogebox setup.. this could take a while on first boot :)";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    before = [ "getty@tty1.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.bash}/bin/bash /etc/first-boot-script.sh";
      # Print to the TTY so people can actually see the system is doing things the first time they boot.
      StandardOutput = "tty";
      StandardError = "tty";
      TTYPath = "/dev/tty1";
      TTYReset = true;
      TTYVHangup = true;
    };
  };

  # These are all needed for the oneshot boot process above.
  environment.systemPackages = [
    pkgs.nixos-rebuild
    pkgs.bash
    pkgs.nix
    pkgs.nixos-rebuild
    pkgs.git
  ];
}
