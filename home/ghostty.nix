# Ghostty terminal configuration

{ ... }:

{
  programs.ghostty = {
    enable = true;
    settings = {
      # Keep one GTK process alive so Super+Return can use `ghostty +new-window`
      # without paying full cold-start cost (~1–2 s) every time.
      gtk-single-instance = true;

      # Transparency + blur
      background-opacity = 0.8;  # 0.0 = transparent, 1.0 = opaque
      background-blur = true;

      # Use the Noctalia-generated runtime theme file.
      theme = "noctalia";
    };

  };
}
