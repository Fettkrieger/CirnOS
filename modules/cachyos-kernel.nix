# CachyOS kernel flake overlay and binary cache (see AGENTS.md for two-phase deploy).
{ inputs, ... }:

{
  nixpkgs.overlays = [
    inputs.nix-cachyos-kernel.overlays.default
  ];

  nix.settings = {
    substituters = [ "https://attic.xuyh0120.win/lantian" ];
    trusted-public-keys = [
      "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
    ];
  };
}
