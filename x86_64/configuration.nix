# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

let dogebox = import <dogebox> { inherit pkgs; }; in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./setup
    ];

  # Use the GRUB 2 boot loader.
  # boot.loader.grub.enable = true;
  # boot.loader.grub.efiSupport = true;
  # boot.loader.grub.efiInstallAsRemovable = true;
  # boot.loader.efi.efiSysMountPoint = "/boot/efi";
  # Define on which hard drive you want to install Grub.
  # boot.loader.grub.device = "/dev/sda"; # or "nodev" for efi only
  boot.loader.systemd-boot.enable = true;

  networking.hostName = "dogebox";
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  # networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  # Set your time zone.
  time.timeZone = "Australia/Brisbane";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  # Enable sound.
  # sound.enable = true;
  # hardware.pulseaudio.enable = true;

  users.groups.dogeboxd = {};

  users.users.dogeboxd = {
    isSystemUser = true;
    group =  "dogeboxd";
    # extraGroups = [ "wheel" ];
    # packages = with pkgs; [
    # ];
  };

  environment.systemPackages = with pkgs; [
    dnsmasq
    git
    vim
    wget
    dogebox.dogeboxd
    dogebox.dogecoin-core
    dogebox.dogemap
    dogebox.dogenet
    dogebox.jampuppy
    dogebox.libdogecoin
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # TODO : look in to system.activationScripts

  # /media does not exist by default, and devmon's default config
  # will mount devices at '/media/<username>/<devname>' rather
  # than '/media/<devname>' for some reason, so this should
  # ensure it exists.
  systemd.tmpfiles.rules = [
    "d /media 0755 root root -"
  ];

  services.devmon.enable = true;
#  services.gvfs.enable = true;
#  services.udisks2.enable = true;

  services.nix-serve = {
    enable = true;
  };

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
  };

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 22 80 443 ];
  networking.firewall.allowedUDPPorts = [ ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "23.11"; # Did you read the comment?

}

