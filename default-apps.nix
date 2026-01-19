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
      
      # Images - Default GNOME image viewer (gthumb)
      "image/jpeg" = "gthumb.desktop";
      "image/png" = "gthumb.desktop";
      "image/gif" = "gthumb.desktop";
      "image/bmp" = "gthumb.desktop";
      "image/webp" = "gthumb.desktop";
      "image/svg+xml" = "gthumb.desktop";
      
      # Videos - VLC
      "video/mp4" = "mpv.desktop";
      "video/x-matroska" = "mpv.desktop";
      "video/webm" = "mpv.desktop";
      "video/mpeg" = "mpv.desktop";
      "video/x-msvideo" = "mpv.desktop";
      "video/quicktime" = "mpv.desktop";
      "video/x-flv" = "mpv.desktop";
      
      # Audio - VLC
      "audio/mpeg" = "mpv.desktop";
      "audio/mp4" = "mpv.desktop";
      "audio/x-wav" = "mpv.desktop";
      "audio/flac" = "mpv.desktop";
      "audio/ogg" = "mpv.desktop";
      "audio/x-vorbis+ogg" = "mpv.desktop";
      "audio/x-opus+ogg" = "mpv.desktop";
      
      # PDFs - Default GNOME document viewer (Evince)
      "application/pdf" = "org.gnome.Evince.desktop";
      
      # Archives - Default GNOME archive manager
      "application/zip" = "org.gnome.FileRoller.desktop";
      "application/x-7z-compressed" = "org.gnome.FileRoller.desktop";
      "application/x-tar" = "org.gnome.FileRoller.desktop";
      "application/x-rar" = "org.gnome.FileRoller.desktop";
      
      # File manager - Nautilus (GNOME Files)
      "inode/directory" = "org.gnome.Nautilus.desktop";
    };
    
    # Associations for applications that can open these file types
    associations.added = {
      "text/plain" = [ "code.desktop" "org.gnome.gedit.desktop" ];
      "image/jpeg" = [ "gthumb.desktop" ];
      "image/png" = [ "gthumb.desktop" ];
      "video/mp4" = [ "mpv.desktop" ];
      "audio/mpeg" = [ "mpv.desktop" ];
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