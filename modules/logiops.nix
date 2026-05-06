# Logitech MX Master 3S configuration via logiops + Solaar.
#
# This is the system-wide replacement for Logitech Options/Options+ on Linux.
# It owns every remappable feature on the mouse (thumb buttons, gesture button,
# thumb wheel, vertical wheel behavior, DPI, smart-shift) and runs alongside
# Solaar for a GUI front-end (battery, scroll resolution, host switching, DPI
# slider, pairing).
#
# Architecture:
#   * `pkgs.logiops` ships /bin/logid + /lib/systemd/system/logid.service
#     (built with the Nix store paths baked into ExecStart). We register the
#     unit with `systemd.packages` and pin it to graphical.target.
#   * The daemon reads /etc/logid.cfg (libconfig format). We materialise that
#     file from the heredoc below, so editing this Nix file is the only way to
#     change behavior. Run `rebuild` then `sudo systemctl restart logid`.
#   * Solaar is enabled through the official `hardware.logitech.wireless`
#     NixOS module, which also installs `pkgs.logitech-udev-rules` so non-root
#     users can talk HID++ to the receiver.
#
# Why no `services.logiops`? There's no merged NixOS module yet (PRs #167388,
# #287399 are still open as of nixos-unstable 25.11), so we wire it ourselves.
{ config, lib, pkgs, ... }:

let
  # ----------------------------------------------------------------------
  # /etc/logid.cfg
  # ----------------------------------------------------------------------
  # libconfig syntax: `:` and `=` are interchangeable; statements end with `;`;
  # arrays use `( ... )` and structs use `{ ... }`. Keys are listed in:
  #   https://github.com/PixlOne/logiops/wiki/Configuration
  # Linux key/button names live in:
  #   https://github.com/torvalds/linux/blob/master/include/uapi/linux/input-event-codes.h
  # NOTE: KEY_* names assume a US/QWERTY layout — pick the *physical* key, not
  # the labelled glyph (e.g. on QWERTZ your 'Y' key is KEY_Z).
  logidConfig = ''
    # /etc/logid.cfg — managed by modules/logiops.nix. Do not edit by hand.
    # Re-generate with `sudo nixos-rebuild switch` (alias: `rebuild`).
    # Watch the daemon parse this file with `journalctl -u logid -f`.
    # Discover button CIDs live with `sudo systemctl stop logid && sudo logid -v`.

    # ------------------------------------------------------------------
    # Global daemon options (apply to all devices)
    # ------------------------------------------------------------------
    # workers:    number of worker threads in the dispatch queue. Default 4.
    #             Don't lower this; the queue spawns extra threads if it
    #             stalls so smaller numbers actually create more threads.
    # io_timeout: HID++ I/O timeout in milliseconds. Default 2000. Bump it
    #             if you see "device timed out" warnings in the journal.
    workers: 4;
    io_timeout: 2000;

    # ------------------------------------------------------------------
    # Per-device configuration
    # ------------------------------------------------------------------
    # logiops matches devices by `name`. Get the exact string from
    # `journalctl -u logid -b | grep -i 'detected device'`. The MX Master 3
    # and 3S both report as "MX Master 3S" when paired via the Logi Bolt /
    # Unifying receiver in HID++ mode.
    devices: (
    {
      name: "MX Master 3S";

      # ----------------------------------------------------------------
      # DPI / sensitivity
      # ----------------------------------------------------------------
      # Integer between 200 and 4000 (MX Master 3S sensor range), in steps
      # of 50. Logitech Options defaults to 1000; 1500 feels right on a
      # 2560×1440 display. To bind a button to cycling DPIs instead, see
      # the CycleDPI action in the buttons block below.
      dpi: 1500;

      # ----------------------------------------------------------------
      # Smart-shift (ratchet vs free-spin) on the vertical wheel
      # ----------------------------------------------------------------
      # on:        true  = ratcheted clicks (precise scrolling)
      #            false = free-spin / "infinite" wheel
      # threshold: 1..255. The angular speed at which the wheel auto-
      #            switches into free-spin. Lower = easier to enter spin.
      #            Logitech Options ships ~30; 15 makes free-spin trigger
      #            with a soft flick.
      # default_threshold: optional, sets the device's persistent default
      #            (what the firmware boots into when logid isn't running
      #            yet). Solaar exposes the same setting in its UI.
      # The wheel-mode button under the wheel (CID 0xc4) is bound below
      # to ToggleSmartShift, which flips `on` at runtime.
      smartshift:
      {
        on: true;
        threshold: 15;
        # default_threshold: 30;
      };

      # ----------------------------------------------------------------
      # Vertical scroll wheel — high-resolution mode
      # ----------------------------------------------------------------
      # hires:  true  = report ~120 ticks per detent (smooth scrolling in
      #                 GTK 4, Firefox, Electron, etc.)
      #         false = classic 1 tick per detent
      # invert: true  = "natural scrolling" *on the device only* (does not
      #                 affect touchpad). Most users keep this false and
      #                 let the compositor decide.
      # target: false = wheel events go straight to the OS (default).
      #         true  = wheel events become HID++ notifications that
      #                 logiops can remap below via `up`/`down` gestures.
      # Templates for `target = true`:
      #   up:   { mode: "OnInterval"; interval: 1000;
      #           action: { type: "Keypress"; keys: ["KEY_VOLUMEUP"]; }; };
      #   down: { mode: "OnInterval"; interval: 1000;
      #           action: { type: "Keypress"; keys: ["KEY_VOLUMEDOWN"]; }; };
      hiresscroll:
      {
        hires: true;
        invert: false;
        target: false;
      };

      # ----------------------------------------------------------------
      # Thumb wheel (the small horizontal wheel by your thumb)
      # ----------------------------------------------------------------
      # divert: false = native horizontal scrolling (REL_HWHEEL). Works in
      #                 every GTK/Qt app out of the box, scrolls Firefox
      #                 with Shift held, etc. Recommended default.
      #         true  = logiops captures the wheel and you must define
      #                 `left`/`right` (and optionally `proxy`/`touch`/
      #                 `tap`) to give it any behavior.
      # invert: flips the left/right direction reported to userspace.
      #
      # When `divert = true`, common bindings:
      #   * Tab cycling (Ctrl+Tab / Ctrl+Shift+Tab):
      #       left:  { mode: "OnInterval"; interval: 100;
      #                action: { type: "Keypress";
      #                          keys: ["KEY_LEFTCTRL","KEY_LEFTSHIFT","KEY_TAB"]; }; };
      #       right: { mode: "OnInterval"; interval: 100;
      #                action: { type: "Keypress";
      #                          keys: ["KEY_LEFTCTRL","KEY_TAB"]; }; };
      #   * Niri column focus (Super+Left/Right):
      #       left:  { mode: "OnInterval"; interval: 80;
      #                action: { type: "Keypress";
      #                          keys: ["KEY_LEFTMETA","KEY_LEFT"]; }; };
      #       right: { mode: "OnInterval"; interval: 80;
      #                action: { type: "Keypress";
      #                          keys: ["KEY_LEFTMETA","KEY_RIGHT"]; }; };
      #   * Analog horizontal scroll via Axis (kept here as documentation):
      #       left:  { mode: "Axis"; axis: "REL_HWHEEL"; axis_multiplier: -1; };
      #       right: { mode: "Axis"; axis: "REL_HWHEEL"; axis_multiplier:  1; };
      thumbwheel:
      {
        divert: false;
        invert: false;
      };

      # ----------------------------------------------------------------
      # Buttons — per-CID action mappings
      # ----------------------------------------------------------------
      # MX Master 3S Control IDs (CIDs):
      #   0x50  Left click          (left undiverted; you don't want logiops in this path)
      #   0x51  Right click         (left undiverted)
      #   0x52  Middle click        (wheel button; left undiverted)
      #   0x53  Back thumb button
      #   0x56  Forward thumb button
      #   0xc3  Gesture button      (the flat one under your thumb)
      #   0xc4  Wheel-mode button   (under the scroll wheel)
      #   0xd7  Top "Easy-Switch"   (reports through HID, not as a CID)
      #
      # Action types you can use:
      #   None / Keypress / Gestures / ToggleSmartShift / ToggleHiresScroll /
      #   CycleDPI / ChangeDPI / ChangeHost
      # See the wiki for the full action grammar.
      buttons: (
        # ---- Back thumb button ----------------------------------------
        # Default: regular browser/file-manager Back. Replace `BTN_BACK`
        # with e.g. `KEY_LEFTALT, KEY_LEFT` for an explicit Alt+Left, or
        # bind a `CycleDPI` action to repurpose it as a precision toggle.
        {
          cid: 0x53;
          action:
          {
            type: "Keypress";
            keys: ["BTN_BACK"];
          };
        },

        # ---- Forward thumb button -------------------------------------
        {
          cid: 0x56;
          action:
          {
            type: "Keypress";
            keys: ["BTN_FORWARD"];
          };
        },

        # ---- Gesture button (under the thumb) -------------------------
        # Tap (no drag)   -> Super+X (Niri overview, replaces the old
        #                    keyd `mouseback+mouseforward` chord).
        # Drag Up/Down    -> Super+Up/Down  (Niri focus window/workspace)
        # Drag Left/Right -> Super+Left/Right (Niri focus column)
        #
        # `mode: "OnRelease"` fires the action exactly once when you let
        # go. Swap to `mode: "OnInterval"; interval: 200;` to repeat the
        # keypress while you keep dragging (useful for workspace surfing).
        {
          cid: 0xc3;
          action:
          {
            type: "Gestures";
            gestures: (
              {
                direction: "None";
                mode: "OnRelease";
                action:
                {
                  type: "Keypress";
                  keys: ["KEY_LEFTMETA", "KEY_X"];
                };
              },
              {
                direction: "Up";
                mode: "OnRelease";
                action:
                {
                  type: "Keypress";
                  keys: ["KEY_LEFTMETA", "KEY_UP"];
                };
              },
              {
                direction: "Down";
                mode: "OnRelease";
                action:
                {
                  type: "Keypress";
                  keys: ["KEY_LEFTMETA", "KEY_DOWN"];
                };
              },
              {
                direction: "Left";
                mode: "OnRelease";
                action:
                {
                  type: "Keypress";
                  keys: ["KEY_LEFTMETA", "KEY_LEFT"];
                };
              },
              {
                direction: "Right";
                mode: "OnRelease";
                action:
                {
                  type: "Keypress";
                  keys: ["KEY_LEFTMETA", "KEY_RIGHT"];
                };
              }
            );
          };
        },

        # ---- Wheel-mode button (under the scroll wheel) ---------------
        # Toggles smart-shift on/off live (ratchet <-> free-spin).
        # Other useful actions:
        #   { type: "ToggleHiresScroll"; }                    # toggle hi-res
        #   { type: "CycleDPI"; dpis: [800, 1500, 2400]; }   # DPI rotation
        #   { type: "ChangeHost"; host: "next"; }            # multi-host
        {
          cid: 0xc4;
          action:
          {
            type: "ToggleSmartShift";
          };
        }

        # ---- Templates for buttons we deliberately leave alone --------
        # Uncomment any of these to divert the standard mouse buttons.
        # Be careful: diverting 0x50/0x51 means the OS no longer sees a
        # plain left/right click on the MX Master, only what you map.
        # ,
        # { cid: 0x50; action: { type: "Keypress"; keys: ["BTN_LEFT"];   }; }
        # ,
        # { cid: 0x51; action: { type: "Keypress"; keys: ["BTN_RIGHT"];  }; }
        # ,
        # { cid: 0x52; action: { type: "Keypress"; keys: ["BTN_MIDDLE"]; }; }
      );
    }
    );
  '';
in
{
  # logiops daemon: package + unit + config file -------------------------
  environment.systemPackages = [ pkgs.logiops ];

  # `pkgs.logiops` installs logid.service into $out/lib/systemd/system.
  # systemd.packages copies it into /etc/systemd/system; wantedBy creates
  # the graphical.target.wants/ symlink so it actually starts on boot.
  systemd.packages = [ pkgs.logiops ];
  systemd.services.logid = {
    wantedBy = [ "graphical.target" ];
    # Pick up /etc/logid.cfg edits without a stale state from a previous run.
    restartTriggers = [ logidConfig ];
  };

  environment.etc."logid.cfg".text = logidConfig;

  # Solaar GUI + canonical udev rules ------------------------------------
  # `hardware.logitech.wireless.enable` installs `pkgs.ltunify` and the
  # `pkgs.logitech-udev-rules` package (so any seated user can talk to
  # 046d:* receivers via hidraw). `enableGraphical = true` adds Solaar.
  hardware.logitech.wireless = {
    enable = true;
    enableGraphical = true;
  };
}
