# Steam + Millennium for Noctalia-driven Material-Theme colors.
#
# Noctalia's Steam template only writes steamui/skins/Material-Theme/css/main/colors/matugen.css.
# Millennium loads Material-Theme from ~/.steam/steam/millennium/themes/Material-Theme/; the theme's
# Matugen mode pulls matugen.css via steamloopback.host. See home/steam-material-theme.nix and
# https://docs.noctalia.dev/v4/theming/program-specific/steam/
{ config, lib, pkgs, ... }:

let
  i686 = pkgs.pkgsi686Linux;

  millenniumDist = pkgs.stdenv.mkDerivation {
    pname = "millennium-dist";
    version = "2.36.1";
    src = pkgs.fetchurl {
      url = "https://github.com/SteamClientHomebrew/Millennium/releases/download/v2.36.1/millennium-v2.36.1-linux-x86_64.tar.gz";
      hash = "sha256-bYZ728qVKZCbA1vTRkytZCnjvKcB3cSrqQOV7pA0+2k=";
    };
    nativeBuildInputs = [ pkgs.patchelf ];
    dontBuild = true;
    unpackPhase = "true";
    installPhase = ''
      runHook preInstall
      mkdir -p "$out"
      ${pkgs.gnutar}/bin/tar -xzf "$src" -C "$out"
      chmod +x $out/usr/lib/millennium/*.so
      # Embed bundled Python + i686 nixpkgs libs so dlopen() works on NixOS (no /opt/python by default).
      patchelf --set-rpath "$out/opt/python-i686-3.11.8/lib:${i686.openssl.out}/lib:${i686.zlib.out}/lib:${i686.stdenv.cc.cc.lib}/lib" \
        "$out/usr/lib/millennium/libmillennium_x86.so"
      runHook postInstall
    '';
  };

  millenniumLib = "${millenniumDist}/usr/lib/millennium";
  millenniumPython = "${millenniumDist}/opt/python-i686-3.11.8";
in
{
  # Millennium expects the official tarball layout under /usr and /opt (see install.sh).
  system.activationScripts.millennium = ''
    mkdir -p /usr/lib /usr/share /opt
    ln -sfn ${millenniumLib} /usr/lib/millennium
    ln -sfn ${millenniumDist}/usr/share/millennium /usr/share/millennium
    ln -sfn ${millenniumPython} /opt/python-i686-3.11.8
  '';

  environment.systemPackages = [
    (pkgs.writeShellScriptBin "cirnos-install-millennium-assets" ''
      set -eu
      if [ "$(id -u)" -ne 0 ]; then
        echo "Run: sudo cirnos-install-millennium-assets" >&2
        exit 1
      fi
      mkdir -p /usr/lib /usr/share /opt
      ln -sfn ${millenniumLib} /usr/lib/millennium
      ln -sfn ${millenniumDist}/usr/share/millennium /usr/share/millennium
      ln -sfn ${millenniumPython} /opt/python-i686-3.11.8
      echo "Millennium /usr/lib, /usr/share, and /opt/python symlinks installed."
    '')
  ];

  # Copy Millennium libs into the Steam dir with execute bits. Nix store paths are not
  # executable, so dlopen(MILLENNIUM_RUNTIME_PATH) fails if we symlink the store directly.
  programs.steam.package = pkgs.steam.override {
    extraProfile = ''
      mill_lib="$HOME/.local/share/Steam/millennium/lib"
      mill_py="$HOME/.local/share/Steam/millennium/python"
      mkdir -p "$mill_lib" "$mill_py" "$HOME/.steam/steam/ubuntu12_32" "$HOME/.steam/steam/ubuntu12_64"
      ${pkgs.coreutils}/bin/cp -f ${millenniumLib}/*.so "$mill_lib/"
      chmod +x "$mill_lib"/*.so
      if [ ! -e "$mill_py/lib/libpython-3.11.8.so" ]; then
        ${pkgs.rsync}/bin/rsync -a --delete ${millenniumPython}/ "$mill_py/"
      fi
      ln -sfn "$mill_lib/libmillennium_bootstrap_86x.so" "$HOME/.steam/steam/ubuntu12_32/libXtst.so.6"
      ln -sfn "$mill_lib/libmillennium_hhx64.so" "$HOME/.steam/steam/ubuntu12_64/libmillennium_hhx64.so"
      export MILLENNIUM_RUNTIME_PATH="$mill_lib/libmillennium_x86.so"
      export LD_LIBRARY_PATH="$mill_py/lib''${LD_LIBRARY_PATH:+:}$LD_LIBRARY_PATH"
    '';
  };
}
