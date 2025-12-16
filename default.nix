# This file describes your repository contents.
# It should return a set of nix derivations
# and optionally the special attributes `lib`, `modules` and `overlays`.
# It should NOT import <nixpkgs>. Instead, you should take pkgs as an argument.
# Having pkgs default to <nixpkgs> is fine though, and it lets you use short
# commands such as:
#     nix-build -A mypackage

{ pkgs ? import <nixpkgs> { } }:

{
  # The `lib`, `modules`, and `overlays` names are special
  lib = import ./lib { inherit pkgs; }; # functions
  modules = import ./modules; # NixOS modules
  overlays = import ./overlays; # nixpkgs overlays

  fishPlugins.replay-fish = pkgs.fishPlugins.callPackage ./pkgs/fish-replay { };
  vscode-oss = pkgs.callPackage ./pkgs/vscode-oss { };
  wallpaperengine-gui = pkgs.callPackage ./pkgs/wallpaperengine-gui.nix { };
  linux-wallpaperengine = pkgs.linux-wallpaperengine.overrideAttrs {
    version = "0-unstable-2025-12-09";
    src = pkgs.fetchFromGitHub {
      owner = "Almamu";
      repo = "linux-wallpaperengine";
      rev = "68d0bd9c157f7b16bc4f66348d69421b38831ffb";
      fetchSubmodules = true;
      hash = "sha256-M2ayJjHgMJ3kLEgD06dlbGEMPdR+yT2xwjxjUXdgrXw=";
    };
  };
}
