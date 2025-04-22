{ lib, pkgs, ... }:

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
    extraGroups = [ "wheel" "dogebox" "networkmanager" ];

    # Very temporary, until we have SSH key management in dpanel.
    password = "suchpass";
  };

  security.sudo.wheelNeedsPassword = false;

  # These will be overridden by the included dogebox.nix file above, but set defaults.
  networking.wireless.iwd.enable = lib.mkDefault true;
  networking.networkmanager.enable = lib.mkDefault true;
  networking.networkmanager.wifi.backend = lib.mkDefault "iwd";

  networking.firewall.enable = true;

#   environment.etc."first-boot-script.sh" = {
#     text = ''
#       #${pkgs.bash}/bin/bash

#       # Remove <dogebox> flake import
#       ${pkgs.gnused}/bin/sed -i 's|/\*rm\*/.*/\*rm\*/||g' /etc/nixos/*.nix

#       # Add <dogebox> channel import
#       ${pkgs.gnused}/bin/sed -i '/\/\*inject\*\//a\
# let\
#   dbxRelease = "${dbxRelease}";\
#   nurPackagesHash = "${nurPackagesHash}";\
#   dogebox = import <dogebox> { inherit pkgs dbxRelease nurPackagesHash; };\
# in\
# ' /etc/nixos/*.nix

#       # Remove inject line.
#       ${pkgs.gnused}/bin/sed -i 's|/\*inject\*/||g' /etc/nixos/*.nix

#       # Replace any ../../dbx/ references with ./ to make everything flat.
#       ${pkgs.gnused}/bin/sed -i 's|\.\.\/\.\.\/dbx\/|\.\/|g' /etc/nixos/*.nix

#       if [ ! -f /opt/first-boot-done ]; then
#         echo "Sleeping for 10 seconds to ensure network is actually up..."
#         sleep 10

#         echo "Checking internet connectivity..."
#         if ! ${pkgs.iputils}/bin/ping -c 1 dogecoin.org > /dev/null 2>&1; then
#           echo "No internet connectivity detected. Internet is required at boot (ethernet) right now. WiFi support coming soon."
#           sleep 1d
#         else
#           echo "Internet check successful"
#         fi

#         export NIX_PATH=nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos:nixos-config=/etc/nixos/configuration.nix:/nix/var/nix/profiles/per-user/root/channels
#         export PATH=$PATH:${pkgs.git}/bin
#         echo "Adding nixpkgs channel..."
#         ${pkgs.nix}/bin/nix-channel --add https://nixos.org/channels/nixos-24.11 nixpkgs
#         echo "Adding dogebox nix channel..."
#         ${pkgs.nix}/bin/nix-channel --add https://github.com/dogeorg/dogebox-nur-packages/archive/${dbxRelease}.tar.gz dogebox
#         echo "Sleeping for 5 seconds..."
#         sleep 5
#         echo "Updating nix channels..."
#         ${pkgs.nix}/bin/nix-channel --update

#         # If we're booting from a RO media, don't bother rebuilding the system here.
#         if [ -f /opt/ro-media ]; then
#           echo "Detected read-only root filesystem. Skipping system rebuild."
#           echo "Sleeping for 5 seconds..."
#           sleep 5
#           exit 0
#         fi

#         echo "Rebuilding system..."
#         # This MUST use boot and not switch, or you will get errors
#         # about nix trying to replace in-process unit files (the one executing this script)
#         ${pkgs.nixos-rebuild}/bin/nixos-rebuild boot
#         echo "First boot commands completed."
#         touch /opt/first-boot-done
#         echo "Rebooting into new configuration..."
#         sleep 3
#         # Reboot to apply the new configuration we built above.
#         reboot
#       else
#         echo "Not first boot, skipping."
#       fi
#     '';
#     mode = "0755";
#   };

  # systemd.services.runOnceOnFirstBoot = {
  #   description = "[DOGEBOX] Initial Dogebox setup.. this could take a while on first boot :)";
  #   wants = [ "network-online.target" ];
  #   after = [ "network-online.target" ];
  #   wantedBy = [ "multi-user.target" ];
  #   before = [ "getty@tty1.service" ];
  #   serviceConfig = {
  #     Type = "oneshot";
  #     RemainAfterExit = true;
  #     ExecStart = "${pkgs.bash}/bin/bash /etc/first-boot-script.sh";
  #     # Print to the TTY so people can actually see the system is doing things the first time they boot.
  #     StandardOutput = "tty";
  #     StandardError = "tty";
  #     TTYPath = "/dev/tty1";
  #     TTYReset = true;
  #     TTYVHangup = true;
  #   };
  # };

  # These are all needed for the oneshot boot process above.
  environment.systemPackages = [
    pkgs.bash
    pkgs.nix
    pkgs.nixos-rebuild
    pkgs.git
    pkgs.wirelesstools
  ];
}
