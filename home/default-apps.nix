# Default applications configuration using XDG MIME types
{ ... }:

{
  xdg.mimeApps = {
    enable = true;
    
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
      
      # Images - gthumb
      "image/jpeg" = "gthumb.desktop";
      "image/png" = "gthumb.desktop";
      "image/gif" = "gthumb.desktop";
      "image/bmp" = "gthumb.desktop";
      "image/webp" = "gthumb.desktop";
      "image/svg+xml" = "gthumb.desktop";
      
      # Videos - mpv
      "video/mp4" = "mpv.desktop";
      "video/x-matroska" = "mpv.desktop";
      "video/webm" = "mpv.desktop";
      "video/mpeg" = "mpv.desktop";
      "video/x-msvideo" = "mpv.desktop";
      "video/quicktime" = "mpv.desktop";
      "video/x-flv" = "mpv.desktop";
      
      # Audio - mpv
      "audio/mpeg" = "mpv.desktop";
      "audio/mp4" = "mpv.desktop";
      "audio/x-wav" = "mpv.desktop";
      "audio/flac" = "mpv.desktop";
      "audio/ogg" = "mpv.desktop";
      
      # Archives - Nautilus
      "application/zip" = "org.gnome.Nautilus.desktop";
      "application/x-tar" = "org.gnome.Nautilus.desktop";
      "application/x-7z-compressed" = "org.gnome.Nautilus.desktop";
      "application/x-rar" = "org.gnome.Nautilus.desktop";
      
      # Directories
      "inode/directory" = "org.gnome.Nautilus.desktop";
    };
  };
}
