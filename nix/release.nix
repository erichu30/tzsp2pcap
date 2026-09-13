{ system ? builtins.currentSystem }:
let
  nixpkgs = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/b6018f87da91d19d0ab4cf979885689b469cdd41.tar.gz";
  };
  pkgs = import nixpkgs { inherit system; };
in
pkgs.pkgsStatic.callPackage ./package.nix { }
