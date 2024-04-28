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
        modules = [ ./base.nix "${nixpkgs}/nixos/modules/profiles/qemu-guest.nix" ];
      };

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
    };
}
