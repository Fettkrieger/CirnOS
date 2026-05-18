# System-wide packages (available to all users)
{ pkgs, lib, ... }:

let
  cursorWithLibsecret = pkgs.symlinkJoin {
    name = "code-cursor-libsecret";
    paths = [ pkgs.code-cursor ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      rm $out/bin/cursor
      makeWrapper ${pkgs.code-cursor}/bin/cursor $out/bin/cursor \
        --add-flags "--password-store=gnome-libsecret"
    '';
  };
in
{
  # Fonts (needed for Noctalia and other UI elements)
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    noto-fonts
    noto-fonts-color-emoji
    corefonts  # Windows fonts (Arial, Times, etc.) - needed for Steam/Proton games
  ];

  # Chromium browser
  programs.chromium.enable = true;

  # Keychron keyboard WebHID access (for launcher.keychron.com)
  services.udev.extraRules = ''
    # Keychron keyboards - allow WebHID access
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="3434", MODE="0660", TAG+="uaccess"
  '';

  environment.systemPackages = with pkgs; [
    evtest                            #Input event inspection tool used by Noctalia Slow Bongo
    wev                               #Wayland event viewer (used to verify logiops keypresses)
    wget                              #CLI downloader for files over HTTP/HTTPS
    curl                              #CLI tool for transferring data with URLs  
    git                               #Version control system
    jdk17                             #Java runtime/toolchain for Android builds
    android-studio-full               #Android Studio with bundled Android SDK/emulator components
    android-tools                     #ADB and fastboot tools for Android devices
    python3                           #Python programming language interpreter  
    pywalfox-native                   #Native app/CLI used by the Pywalfox Firefox addon
    chromium                          #Web browser
    qbittorrent                       #Torrent client
    popsicle                          #USB image writer
    kicad                             #PCB design software
    dconf-editor                      #GNOME configuration editor
    spotify                           #Music streaming client (icon resolved via papirus-icon-theme: spotify-client)
    vscode                            #Source-code editor
    (lib.hiPrio cursorWithLibsecret)  #Cursor AI code editor, forced to use GNOME Keyring/libsecret
    nixd                              #Nix language server (Nix IDE / vscode-nix-ide in Cursor and VS Code)
    fastfetch                         #System information tool
    tree                              #Directory listing tool
    ripgrep                           #Search tool
    fd                                #Find alternative
    jq                                #JSON processor used by Noctalia music search
    yt-dlp                            #YouTube downloader
    libreoffice-fresh                 #Office suite
    ffmpeg                            #Multimedia framework
    qt6Packages.qt6gtk2               #Qt6 gtk3 platform theme (qBittorrent)

    # === GNOME / Nautilus file manager stack ===
    # Nautilus is the user's file manager. The trash backend
    # (`trash:///` URL, restore + empty-trash context entries) is
    # provided by `gvfs` which is enabled at the system level in
    # modules/common.nix; gvfs also implements the network protocols
    # (sftp, smb, mtp, ftp, ...) Nautilus exposes under "Other
    # Locations". Modern Nautilus has built-in archive extract
    # (right-click -> Extract Here) via gnome-autoar, so file-roller
    # is only needed for *opening* / browsing archives -- it owns
    # `org.gnome.FileRoller.desktop` which the archive MIME types in
    # home/default-apps.nix are routed to.
    nautilus                          #GNOME file manager (trash + remote shares via gvfs)
    evince                            #GNOME document viewer (PDF, DjVu, …)
    file-roller                       #GNOME archive manager (registers org.gnome.FileRoller.desktop)
    gnome-calculator                  #GNOME Calculator
    loupe                             #GNOME image viewer (org.gnome.Loupe.desktop)
    snapshot                          #GNOME Camera / webcam (org.gnome.Snapshot.desktop)
    gnome-disk-utility                #GNOME Disks (mount, format, SMART; org.gnome.DiskUtility.desktop)
    dosfstools                        #FAT formatting for Disks (replaces gparted-full exfat/fat tooling)
    exfatprogs                        #exFAT formatting for Disks
    gnome-system-monitor              #GNOME System Monitor (org.gnome.SystemMonitor.desktop)
    gnome-boxes                       #GNOME Boxes VMs (org.gnome.Boxes.desktop; needs libvirtd in common.nix)

    # === Qt + GTK base libraries needed by Noctalia color templates ===
    # adw-gtk3 is required as the base GTK theme so the GTK template's
    # `@import url("noctalia.css")` overlay layers correctly. qt6ct is
    # required for the Qt template (~/.config/qt6ct/colors/noctalia.conf
    # is only consulted when QT_QPA_PLATFORMTHEME=qt6ct, which is set by
    # home/themes.nix via `qt.platformTheme.name = "qtct"`).
    adw-gtk3                          #GTK3/4 Adwaita-style theme that Noctalia's GTK template overlays
    libsForQt5.qt5ct                  #Qt5 control panel (qt5ct), reads ~/.config/qt5ct/colors/noctalia.conf
    qt6Packages.qt6ct                 #Qt6 control panel, reads ~/.config/qt6ct/colors/noctalia.conf

    # === Icon themes (resolution chain for app icons in dock/launcher/notifications) ===
    # The active GTK icon theme is set in home/themes.nix to `Papirus-Dark`,
    # which inherits `breeze-dark, hicolor`. With Papirus active, Noctalia's
    # dock/launcher (which uses Quickshell -> QIcon::fromTheme) resolves icons
    # in this order:
    #   1. Papirus-Dark        ~5000+ third-party app icons (Discord, Spotify,
    #                          Steam, Signal, WhatsApp, Chromium, VS Code,
    #                          org.gnome.Nautilus, ...)
    #   2. breeze-dark         Free byproduct of the Inherits chain; covers any
    #                          stray KDE-named icons (e.g. qt apps).
    #   3. hicolor             per-app icons that ship in the package itself
    #                          (cursor, teamspeak6-client, footage, ...)
    #   4. Adwaita             still installed by home-manager as a sibling
    # so virtually every desktop app gets a real icon in the dock without
    # having to symlink anything per-app the way spotify used to need.
    papirus-icon-theme                #Primary icon theme; pulls in breeze-icons via inherits chain
    adwaita-icon-theme                #Generic GNOME/Adwaita symbolic icons (final fallback for GTK apps)
    hicolor-icon-theme                #Freedesktop fallback theme (always required)

    unzip                             #Archive extractor
    zip                               #Archive creator
    p7zip                             #7z archive support
    ffmpegthumbnailer                 #Thumbnail generator for video files (GTK file managers / Loupe)
    inkscape                          #Vector graphics editor
    networkmanagerapplet              #NetworkManager connection editor for VPN imports
    pavucontrol                       #PulseAudio volume control
    tailscale                         #Tailscale CLI used by the Noctalia plugin
    wdisplays                         #Wayland display configuration tool
    wl-clipboard                      #Wayland clipboard utilities
    teamspeak6-client                 #Voice communication software
    obsidian                          #Note-taking and knowledge management application
    nodejs_20
    signal-desktop
    whatsapp-electron
    #GStreamer plugins (needed for Footage and video apps)
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-libav
   
    # Footage wrapped to use X11 (crashes on Wayland with NVIDIA due to Vulkan bug)
    (pkgs.symlinkJoin {
      name = "footage-x11";
      paths = [ pkgs.footage ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/footage --set GDK_BACKEND x11
      '';
    })
  ];
}
