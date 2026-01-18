{ ... }:

{
  # Default applications configuration using XDG MIME types
  xdg.mimeApps = {
    enable = true;
    
    # Set default applications for file types
    defaultApplications = {
      # Text files - Visual Studio Code
      "text/plain" = "code.desktop";
      "text/x-c" = "code.desktop";
      "text/x-c++" = "code.desktop";
      "text/x-python" = "code.desktop";
      "text/x-java" = "code.desktop";
      "text/x-javascript" = "code.desktop";
      "text/x-shellscript" = "code.desktop";
      "text/html" = "code.desktop";
      "text/css" = "code.desktop";
      "application/json" = "code.desktop";
      "application/xml" = "code.desktop";
      "application/x-yaml" = "code.desktop";
      
      # Web browser - Firefox
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "x-scheme-handler/about" = "firefox.desktop";
      "x-scheme-handler/unknown" = "firefox.desktop";
      
      # Images - Default GNOME image viewer (Eye of GNOME)
      "image/jpeg" = "org.gnome.eog.desktop";
      "image/png" = "org.gnome.eog.desktop";
      "image/gif" = "org.gnome.eog.desktop";
      "image/bmp" = "org.gnome.eog.desktop";
      "image/webp" = "org.gnome.eog.desktop";
      "image/svg+xml" = "org.gnome.eog.desktop";
      
      # Videos - VLC
      "video/mp4" = "vlc.desktop";
      "video/x-matroska" = "vlc.desktop";
      "video/webm" = "vlc.desktop";
      "video/mpeg" = "vlc.desktop";
      "video/x-msvideo" = "vlc.desktop";
      
      # Audio - VLC
      "audio/mpeg" = "vlc.desktop";
      "audio/mp4" = "vlc.desktop";
      "audio/x-wav" = "vlc.desktop";
      "audio/flac" = "vlc.desktop";
      "audio/ogg" = "vlc.desktop";
      
      # PDFs - Default GNOME document viewer (Evince)
      "application/pdf" = "org.gnome.Evince.desktop";
      
      # Archives - Default GNOME archive manager
      "application/zip" = "org.gnome.FileRoller.desktop";
      "application/x-7z-compressed" = "org.gnome.FileRoller.desktop";
      "application/x-tar" = "org.gnome.FileRoller.desktop";
      "application/x-rar" = "org.gnome.FileRoller.desktop";
      
      # File manager - Nautilus
      "inode/directory" = "org.gnome.Nautilus.desktop";
    };
    
    # Associations for applications that can open these file types
    associations.added = {
      "text/plain" = [ "code.desktop" "org.gnome.gedit.desktop" ];
      "image/jpeg" = [ "org.gnome.eog.desktop" "gimp.desktop" ];
      "image/png" = [ "org.gnome.eog.desktop" "gimp.desktop" ];
      "video/mp4" = [ "vlc.desktop" "mpv.desktop" ];
      "audio/mpeg" = [ "vlc.desktop" "mpv.desktop" ];
    };
  };
  
  # Environment variables for default applications
  home.sessionVariables = {
    # Default editor for terminal
    EDITOR = "code --wait";
    VISUAL = "code --wait";
    
    # Default browser
    BROWSER = "firefox";
  };
}
