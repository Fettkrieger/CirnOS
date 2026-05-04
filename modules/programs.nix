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
    wget                              #CLI downloader for files over HTTP/HTTPS
    curl                              #CLI tool for transferring data with URLs  
    git                               #Version control system
    jdk17                             #Java runtime/toolchain for Android builds
    android-studio-full               #Android Studio with bundled Android SDK/emulator components
    android-tools                     #ADB and fastboot tools for Android devices
    python3                           #Python programming language interpreter  
    chromium                          #Web browser
    qbittorrent                       #Torrent client
    popsicle                          #USB image writer
    kicad                             #PCB design software
    dconf-editor                      #GNOME configuration editor
    discord                           #Chat and communication platform  
    vscode                            #Source-code editor
    (lib.hiPrio cursorWithLibsecret)  #Cursor AI code editor, forced to use GNOME Keyring/libsecret
    fastfetch                         #System information tool
    tree                              #Directory listing tool
    ripgrep                           #Search tool
    fd                                #Find alternative
    jq                                #JSON processor used by Noctalia music search
    yt-dlp                            #YouTube downloader
    libreoffice-fresh                 #Office suite
    claude-code                       #AI assistant
    ffmpeg                            #Multimedia framework  
    nautilus                          #File manager
    unzip                             #Archive extractor
    zip                               #Archive creator
    p7zip                             #7z archive support
    ffmpegthumbnailer                 #Thumbnail generator for video files
    gthumb                            #Image viewer and organizer  
    inkscape                          #Vector graphics editor
    networkmanagerapplet              #NetworkManager connection editor for VPN imports
    pavucontrol                       #PulseAudio volume control
    tailscale                         #Tailscale CLI used by the Noctalia plugin
    wdisplays                         #Wayland display configuration tool
    wl-clipboard                      #Wayland clipboard utilities
    teamspeak6-client                 #Voice communication software
    obsidian                          #Note-taking and knowledge management application
    gparted-full                      #Graphical partition editor with extra filesystem tools (including exFAT)
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
