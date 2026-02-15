# Ghostty terminal configuration

{ ... }:

{
  programs.ghostty = {
    enable = true;
    settings = {
      # Transparency + blur
      background-opacity = 0.8;  # 0.0 = transparent, 1.0 = opaque
      background-blur = true;

      # Use the Noctalia-generated runtime theme file.
      theme = "noctalia";
    };

  };
}
