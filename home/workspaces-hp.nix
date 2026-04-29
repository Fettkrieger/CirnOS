{ ... }:

{
  # Laptop hosts: define named workspaces only (no startup windows).
  programs.niri.settings.workspaces = {
    A = { };
    B = { };
    C = { };
  };
}
