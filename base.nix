{
  imports = [ ./cloud-init.nix ];

  system.stateVersion = "23.11";

  nixpkgs.hostPlatform = "x86_64-linux";

  services.openssh.enable = true;

  services.qemuGuest.enable = true;

  security.sudo.wheelNeedsPassword = false;

  fileSystems."/" = {
    label = "nixos";
    fsType = "ext4";
    autoResize = true;
  };
  boot.loader.grub.device = "/dev/sda";

  users.users.ops = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

  networking = {
    useNetworkd = true;
    dhcpcd.enable = false;
    interfaces.net0.useDHCP = true;
  };

  systemd.network.enable = true;

}
