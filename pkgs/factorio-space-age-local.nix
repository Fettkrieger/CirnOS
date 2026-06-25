{ pkgs }:

let
  cfg = import ../home/factorio-space-age-local.nix;

  release = {
    candidateHashFilenames = [ "factorio-space-age_linux_${cfg.version}.tar.xz" ];
    name = cfg.storeName;
    needsAuth = false;
    sha256 = cfg.sha256;
    tarDirectory = "x64";
    url = "file://${cfg.srcStorePath}";
    version = cfg.version;
  };

  versionsJson = pkgs.writeText "factorio-space-age-${cfg.version}-versions.json" (
    builtins.toJSON {
      x86_64-linux.expansion = {
        stable = release;
        experimental = release;
      };
    }
  );
in
{
  inherit (cfg) enable version installPath srcStorePath sha256 sriHash storeName;

  package =
    if cfg.enable then
      pkgs.factorio-space-age.override {
        inherit versionsJson;
      }
    else
      null;
}
