# Theme configuration (Noctalia-driven GTK, Qt, and cursors)
#
# This file sets the *baseline* widget styles. Noctalia's color templates
# (Settings -> Color Scheme -> Templates) overlay accent colors on top:
#   * GTK template -> writes ~/.config/gtk-{3,4}.0/noctalia.css and appends
#     `@import url("noctalia.css");` to gtk.css. The base theme MUST be
#     `adw-gtk3` / `adw-gtk3-dark` for the import to layer correctly; the
#     stock Adwaita theme has different selectors and the override fails.
#   * Qt template -> writes ~/.config/qt{5,6}ct/colors/noctalia.conf. For
#     Qt apps to actually consult that file the platform theme must be
#     `qtct` (sets QT_QPA_PLATFORMTHEME=qt6ct), so that's set below.
#   * KColorScheme template -> intentionally disabled in noctalia-settings.json
#     (no KDE/Qt6 apps use ~/.local/share/color-schemes/noctalia.colors here).
#     If you reintroduce Dolphin/Ark/Konsole, re-enable that template AND
#     add a reload watcher that fires `org.kde.KGlobalSettings.notifyChange`
#     on D-Bus, otherwise running KDE apps cache the old palette forever.
{ config, pkgs, ... }:

let
  # Ship all mocha cursor variants so runtime switching can pick the closest color.
  catppuccinMochaCursorThemes = pkgs.symlinkJoin {
    name = "catppuccin-mocha-cursors";
    paths = [
      pkgs.catppuccin-cursors.mochaRosewater
      pkgs.catppuccin-cursors.mochaFlamingo
      pkgs.catppuccin-cursors.mochaPink
      pkgs.catppuccin-cursors.mochaMauve
      pkgs.catppuccin-cursors.mochaRed
      pkgs.catppuccin-cursors.mochaMaroon
      pkgs.catppuccin-cursors.mochaPeach
      pkgs.catppuccin-cursors.mochaYellow
      pkgs.catppuccin-cursors.mochaGreen
      pkgs.catppuccin-cursors.mochaTeal
      pkgs.catppuccin-cursors.mochaSky
      pkgs.catppuccin-cursors.mochaSapphire
      pkgs.catppuccin-cursors.mochaBlue
      pkgs.catppuccin-cursors.mochaLavender
    ];
  };
in
{
  # GTK: adw-gtk3 base, dark variant, with Noctalia color overlay applied
  # at runtime via the GTK template's gtk-refresh.py post-hook.
  gtk = {
    enable = true;

    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };

    # Preserve the pre-26.05 GTK 4 theme behavior explicitly.
    gtk4.theme = config.gtk.theme;

    # Papirus-Dark is the primary icon theme: ~5000 third-party app icons
    # (Discord, Spotify, Signal, WhatsApp, Chromium, VS Code,
    # org.gnome.Nautilus, ...) reachable directly, with `breeze-dark`
    # and `hicolor` chained after it via the theme's
    # `Inherits=breeze-dark,hicolor` line. Hicolor catches per-app
    # icons that ship in the package itself (cursor, teamspeak6, ...).
    # Adwaita is still installed system-wide as a sibling for any GTK
    # widget that hardcodes Adwaita symbolic names.
    # Base Papirus-Dark is deployed from the package; folder tint is overridden at
    # runtime by ~/.icons/Papirus-Dark-Noctalia (see papirus-folders-live.nix).
    iconTheme = {
      name = "Papirus-Dark-Noctalia";
      package = pkgs.papirus-icon-theme;
    };

    cursorTheme = {
      name = "catppuccin-mocha-blue-cursors";
      package = catppuccinMochaCursorThemes;
      size = 24;
    };

    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };

    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
  };

  # Noctalia mutates ~/.config/gtk-4.0/gtk.css after activation: the GTK
  # color template's gtk-refresh.py post-hook appends an
  # `@import url("noctalia.css");` line so the per-host accent colors
  # overlay the adw-gtk3-dark base. That mutation turns HM's symlink into
  # a regular file, so on the next rebuild HM detects an unmanaged file
  # and tries to back it up to `gtk.css.backup`. After the first cycle
  # `.backup` already exists and HM refuses to clobber it, failing
  # home-manager-krieger.service with:
  #   "Existing file '.../gtk.css.backup' would be clobbered by backing up..."
  # The Noctalia import is regenerated on every theme refresh, so the
  # original HM-generated gtk.css has no value to preserve. Force HM to
  # overwrite the file in place without backups; the next color refresh
  # re-appends the noctalia.css import.
  #
  # gtk-3.0/gtk.css is *not* managed by HM (we don't set gtk3.extraCss),
  # so there's no backup conflict to fix there — Noctalia just creates
  # the file from scratch on each refresh.
  xdg.configFile."gtk-4.0/gtk.css".force = true;

  # Qt: route through qt6ct so Noctalia's Qt color template lands. After
  # the first rebuild, run `qt6ct` once and pick the "noctalia" color
  # scheme from the dropdown — qt6ct persists the choice in qt6ct.conf.
  qt = {
    enable = true;
    platformTheme.name = "qtct";
  };
}
