{ ... }:

{
  # hp-nix: define named laptop workspaces only (no startup windows).
  programs.niri.settings.workspaces = {
    A = { };
    B = { };
    C = { };
  };
}
