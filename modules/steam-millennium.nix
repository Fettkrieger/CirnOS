# Steam + Millennium for Noctalia-driven Material-Theme colors.
#
# Noctalia's Steam template only writes steamui/skins/Material-Theme/css/main/colors/matugen.css.
# Millennium loads Material-Theme from ~/.local/share/Steam/millennium/themes/Material-Theme/; the theme's
# Matugen mode pulls matugen.css via steamloopback.host. See home/steam-material-theme.nix and
# https://docs.noctalia.dev/v4/theming/program-specific/steam/
#
# v2.36.1 stable Linux tarballs ship only 32-bit libs (hhx64 is i386) and omit bootstrap_hhx64 —
# the 32-bit backend loads but steamwebhelper never gets Millennium, so settings URLs do nothing.
# v3.0.0-beta.24 has proper elf64 bootstrap/hhx64/pvs64 (matches steambrew install.sh).
{ config, lib, pkgs, ... }:

let
  i686 = pkgs.pkgsi686Linux;
  millenniumVersion = "3.0.0-beta.24";

  i686Rpath = lib.makeLibraryPath [
    i686.openssl
    i686.zlib
    i686.stdenv.cc.cc
  ];

  millenniumDist = pkgs.stdenv.mkDerivation {
    pname = "millennium-dist";
    version = millenniumVersion;
    src = pkgs.fetchurl {
      url = "https://github.com/SteamClientHomebrew/Millennium/releases/download/v${millenniumVersion}/millennium-v${millenniumVersion}-linux-x86_64.tar.gz";
      hash = "sha256-wRsiiv+xXyCLJ+1d5SkSaB/cKqbF0Ummc+N+iCyvgrk=";
    };
    nativeBuildInputs = [ pkgs.patchelf ];
    dontBuild = true;
    unpackPhase = "true";
    installPhase = ''
      runHook preInstall
      mkdir -p "$out"
      ${pkgs.gnutar}/bin/tar -xzf "$src" -C "$out"
      chmod +x $out/usr/lib/millennium/*
      # Only the 32-bit core links OpenSSL; patch so dlopen works on NixOS.
      patchelf --set-rpath "${i686Rpath}" "$out/usr/lib/millennium/libmillennium_x86.so"
      runHook postInstall
    '';
  };

  millenniumLib = "${millenniumDist}/usr/lib/millennium";

  # steam.sh uses ~/.steam/steam.pid + steam.pipe — pgrep -x steam misses steam.bin and races on restart.
  steamClientHelpers = ''
    steam_client_running() {
      local steam_pid_path="$HOME/.steam/steam.pid"
      [ -e "$steam_pid_path" ] || return 1
      local steam_pid
      steam_pid=$(<"$steam_pid_path") || return 1
      [ -d "/proc/$steam_pid" ] || return 1
      find "/proc/$steam_pid/fd" -lname "$HOME/.steam/steam.pipe" -print -quit 2>/dev/null \
        | ${pkgs.gnugrep}/bin/grep -q .
    }
  '';

  steamUbuntu32Guard = pkgs.writeShellScript "steam-ubuntu32-guard" ''
    ${steamClientHelpers}
    dir="$(dirname "$0")"
    real_xtst="$dir/steam-runtime/usr/lib/i386-linux-gnu/libXtst.so.6"
    run_without_millennium() {
      unset MILLENNIUM_RUNTIME_PATH
      unset LD_PRELOAD
      if [ -f "$real_xtst" ]; then
        ln -sfn "$real_xtst" "$dir/libXtst.so.6"
      fi
      exec "$dir/steam.bin" "$@"
    }
    if steam_client_running; then
      run_without_millennium "$@"
    fi
    mill_bootstrap="$HOME/.local/share/Steam/millennium/lib/libmillennium_bootstrap_x86.so"
    if [ -f "$mill_bootstrap" ]; then
      ln -sfn "$mill_bootstrap" "$dir/libXtst.so.6"
    fi
    exec "$dir/steam.bin" "$@"
  '';

  # steam.sh does not restore ubuntu12_32/steam when it was deleted; bootstrap.tar.xz does.
  ensureSteamClientBinary = pkgs.writeShellScript "ensure-steam-client-binary" ''
    set -eu
    steam_root="$HOME/.local/share/Steam"
    steam32="$steam_root/ubuntu12_32"
    real="$steam32/steam.bin"
    wrapper="$steam32/steam"
    bootstrap="$steam_root/bootstrap.tar.xz"
    is_elf() {
      [ -f "$1" ] && ${pkgs.file}/bin/file -b "$1" | ${pkgs.gnugrep}/bin/grep -q '^ELF'
    }
    ensure_client() {
      if is_elf "$real"; then
        return 0
      fi
      if is_elf "$wrapper"; then
        ${pkgs.coreutils}/bin/mv -f "$wrapper" "$real"
        return 0
      fi
      if [ ! -f "$bootstrap" ]; then
        echo "cirnos-steam: missing $bootstrap — reinstall Steam from store.steampowered.com" >&2
        return 1
      fi
      echo "cirnos-steam: restoring ubuntu12_32/steam from bootstrap.tar.xz..." >&2
      ${pkgs.gnutar}/bin/tar -xf "$bootstrap" -C "$steam_root" ubuntu12_32/steam
      if is_elf "$steam32/steam"; then
        ${pkgs.coreutils}/bin/mv -f "$steam32/steam" "$real"
      fi
      is_elf "$real"
    }
    ensure_client
  '';

  # Relaunch must not exec steam/steam.bin (Millennium double-attach segfaults). The tray menu talks
  # to the running client via ~/.steam/steam.pipe (see steam-for-linux #10107 / steam-runtime-urlopen).
  cirnosSteam = pkgs.writeShellScriptBin "cirnos-steam" ''
    set -eu
    ${steamClientHelpers}
    nix_steam="/run/current-system/sw/bin/steam"
    steam_pipe="$HOME/.steam/steam.pipe"
    # Tray "Library" (override: STEAM_REOPEN_URL=steam://open/store).
    reopen_url="''${STEAM_REOPEN_URL:-steam://open/library}"

    steam_pipe_send() {
      local url="$1"
      if [ ! -p "$steam_pipe" ]; then
        echo "cirnos-steam: $steam_pipe missing (is Steam running?)" >&2
        return 1
      fi
      # Same wire format as steam-runtime-urlopen: "steam <url>"
      printf 'steam %s\n' "$url" >"$steam_pipe"
    }

    focus_steam_window() {
      command -v niri >/dev/null 2>&1 || return 0
      local id
      id=$(${pkgs.jq}/bin/jq -r '
        .[] | select(
          (.app_id | ascii_downcase | test("^steam$"))
          or (.title | test("Steam"; "i"))
        ) | .id' < <(niri msg windows -j 2>/dev/null) 2>/dev/null | head -n1)
      if [ -n "$id" ] && [ "$id" != "null" ]; then
        niri msg action focus-window --id="$id" >/dev/null 2>&1 || true
      fi
    }

    if steam_client_running; then
      case "''${1-}" in
        -shutdown)
          exec "$nix_steam" -shutdown
          ;;
        steam://*|steam:*)
          steam_pipe_send "$1"
          focus_steam_window
          exit 0
          ;;
        ""|-foreground)
          steam_pipe_send "$reopen_url"
          focus_steam_window
          exit 0
          ;;
        *)
          steam_pipe_send "$reopen_url"
          focus_steam_window
          exit 0
          ;;
      esac
    fi
    exec "$nix_steam" "$@"
  '';

  # Mirrors steambrew.app/install.sh post_install (ubuntu12_* libXtst preload hooks).
  millenniumSteamBootstrap = pkgs.writeShellScript "millennium-steam-bootstrap" ''
    set -eu
    ${steamClientHelpers}
    "${ensureSteamClientBinary}"
    mill_lib="$HOME/.local/share/Steam/millennium/lib"
    steam32="$HOME/.local/share/Steam/ubuntu12_32"
    steam64="$HOME/.local/share/Steam/ubuntu12_64"
    real_xtst="$steam32/steam-runtime/usr/lib/i386-linux-gnu/libXtst.so.6"
    mkdir -p "$mill_lib" "$steam32" "$steam64"
    ${pkgs.coreutils}/bin/cp -f ${millenniumLib}/* "$mill_lib/"
    chmod +x "$mill_lib"/*

    install_steam_foreground_guard() {
      local dir="$HOME/.local/share/Steam/ubuntu12_32"
      local real="$dir/steam.bin"
      local wrapper="$dir/steam"
      is_elf() {
        [ -f "$1" ] && ${pkgs.file}/bin/file -b "$1" | ${pkgs.gnugrep}/bin/grep -q '^ELF'
      }
      if [ ! -d "$dir" ]; then
        return 0
      fi
      if is_elf "$wrapper"; then
        ${pkgs.coreutils}/bin/mv -f "$wrapper" "$real"
      fi
      if ! is_elf "$real"; then
        return 0
      fi
      chmod u+w "$wrapper" 2>/dev/null || true
      ${pkgs.coreutils}/bin/cp -f ${steamUbuntu32Guard} "$wrapper"
      chmod +x "$wrapper"
    }

    use_real_xtst() {
      if [ -f "$real_xtst" ]; then
        ln -sfn "$real_xtst" "$steam32/libXtst.so.6"
      fi
    }

    install_millennium_hooks() {
      ln -sfn "$mill_lib/libmillennium_bootstrap_x86.so" "$steam32/libXtst.so.6"
      ln -sfn "$mill_lib/libmillennium_bootstrap_hhx64.so" "$steam64/libXtst.so.6"
      ln -sfn "$mill_lib/libmillennium_hhx64.so" "$steam64/libmillennium_hhx64.so"
      export MILLENNIUM_RUNTIME_PATH="$mill_lib/libmillennium_x86.so"
    }

    install_steam_foreground_guard

    # Relaunch (Noctalia, tray -foreground, second nix steam): never attach Millennium again.
    if steam_client_running; then
      use_real_xtst
    else
      install_millennium_hooks
    fi
  '';

  millenniumBootstrapBin = pkgs.writeShellScriptBin "millennium-steam-bootstrap" (
    builtins.readFile millenniumSteamBootstrap
  );
in
{
  system.activationScripts.millennium = ''
    mkdir -p /usr/lib
    ln -sfn ${millenniumLib} /usr/lib/millennium
  '';

  environment.systemPackages = [
    cirnosSteam
    (pkgs.writeShellScriptBin "cirnos-repair-steam-client" ''
      exec ${millenniumBootstrapBin}/bin/millennium-steam-bootstrap
    '')
    (pkgs.writeShellScriptBin "cirnos-install-millennium-assets" ''
      set -eu
      if [ "$(id -u)" -ne 0 ]; then
        echo "Run: sudo cirnos-install-millennium-assets" >&2
        exit 1
      fi
      mkdir -p /usr/lib
      ln -sfn ${millenniumLib} /usr/lib/millennium
      echo "Millennium /usr/lib/millennium symlink installed."
    '')
    millenniumBootstrapBin
  ];

  programs.steam.package = pkgs.steam.override {
    extraProfile = builtins.readFile millenniumSteamBootstrap;
  };
}
