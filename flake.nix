{
  description = "nikolaiser's k3s flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";

      pkgs = nixpkgs.legacyPackages.${system};
      inherit (pkgs) lib;


      baseSystem = nixpkgs.lib.nixosSystem {
        modules = [ ./base.nix ./cloud-init.nix "${nixpkgs}/nixos/modules/profiles/qemu-guest.nix" ];
      };

      conf = lib.trivial.importJson ./config.json;

      makeDiskImage = import "${nixpkgs}/nixos/lib/make-disk-image.nix";

    in
    {
      baseImage = makeDiskImage {
        inherit pkgs lib;
        config = baseSystem.config;
        name = "nixos-cloudinit";
        format = "raw";
        copyChannel = false;
      };

      nixosConfigurations = {
        k3s = lib.nixosSystem {
          inherit lib pkgs system;
          specialArgs = {
            inherit conf;
          };
          modules = [ ./k3s.nix ./hardware-configuration.nix ./base.nix ];
        };

        haproxyBgp = lib.nixosSystem
          {
            inherit lib pkgs system;
            specialArgs = {
              inherit conf;
            };
            modules = [ ./ha-proxy-bgp.nix ./hardware-configuration.nix ./base.nix ];
          };
      };
    };
}
    
