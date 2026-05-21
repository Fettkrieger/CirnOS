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
      
      # Images - gThumb
      "image/jpeg" = "org.gnome.gThumb.desktop";
      "image/png" = "org.gnome.gThumb.desktop";
      "image/gif" = "org.gnome.gThumb.desktop";
      "image/bmp" = "org.gnome.gThumb.desktop";
      "image/webp" = "org.gnome.gThumb.desktop";
      "image/svg+xml" = "org.gnome.gThumb.desktop";
      "image/tiff" = "org.gnome.gThumb.desktop";
      "image/avif" = "org.gnome.gThumb.desktop";
      "image/heic" = "org.gnome.gThumb.desktop";
      "image/jxl" = "org.gnome.gThumb.desktop";

      # Disk images - GNOME Disks
      "application/x-cd-image" = "gnome-disk-image-mounter.desktop";
      "application/x-raw-disk-image" = "gnome-disk-image-mounter.desktop";
      "application/x-raw-disk-image-xz-compressed" = "gnome-disk-image-writer.desktop";
      
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
      
      # Archives - File Roller (GNOME archive manager)
      "application/zip" = "org.gnome.FileRoller.desktop";
      "application/x-tar" = "org.gnome.FileRoller.desktop";
      "application/x-7z-compressed" = "org.gnome.FileRoller.desktop";
      "application/x-rar" = "org.gnome.FileRoller.desktop";
      "application/gzip" = "org.gnome.FileRoller.desktop";
      "application/x-bzip2" = "org.gnome.FileRoller.desktop";
      "application/x-xz" = "org.gnome.FileRoller.desktop";

      # PDF / documents - Evince (GNOME document viewer)
      "application/pdf" = "org.gnome.Evince.desktop";
      "application/x-pdf" = "org.gnome.Evince.desktop";
      "image/vnd.djvu" = "org.gnome.Evince.desktop";

      # Directories - Nautilus (GNOME file manager)
      "inode/directory" = "org.gnome.Nautilus.desktop";
    };
  };
}
