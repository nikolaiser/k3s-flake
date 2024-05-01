{

  system.stateVersion = "23.11";

  nixpkgs.hostPlatform = "x86_64-linux";

  nix.settings.trusted-users = [ "ops" ];

  services.openssh.enable = true;

  services.qemuGuest.enable = true;

  security.sudo.wheelNeedsPassword = false;

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
