{ ... }:

{
  # GNOME keyboard shortcuts configuration
  dconf.settings = {
    # Window management keybindings
    "org/gnome/desktop/wm/keybindings" = {
      # Close window
      close = ["<Super>q"];
      
      # Switch to workspaces
      switch-to-workspace-1 = ["<Super>1"];
      switch-to-workspace-2 = ["<Super>2"];
      switch-to-workspace-3 = ["<Super>3"];
      switch-to-workspace-4 = ["<Super>4"];
      
      # Move window to workspaces
      move-to-workspace-1 = ["<Super><Shift>1"];
      move-to-workspace-2 = ["<Super><Shift>2"];
      move-to-workspace-3 = ["<Super><Shift>3"];
      move-to-workspace-4 = ["<Super><Shift>4"];
      
      # Add more keybindings here as needed
      # Examples:
      # maximize = ["<Super>Up"];
      # unmaximize = ["<Super>Down"];
      # toggle-fullscreen = ["<Super>f"];
      # minimize = ["<Super>h"];
    };

    # Custom keybindings
    "org/gnome/settings-daemon/plugins/media-keys" = {
      # Define custom keybindings list
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
      ];
    };
    
    # Custom keybinding: Open Ghostty with Ctrl+Space
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      binding = "<Ctrl>space";
      command = "ghostty";
      name = "Open Ghostty Terminal";
    };
  };
}
