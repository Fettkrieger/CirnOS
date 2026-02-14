# Noctalia shell - desktop bar, notifications, and control center
{ inputs, hostname, ... }:

{
  imports = [ inputs.noctalia.homeModules.default ];

  programs.noctalia-shell = {
    enable = true;
    systemd.enable = true;

    settings = {
      bar = {
        position = "top";
        density = "default";
        widgets = {
          left = [
            { id = "Workspace"; }
            { id = "ActiveWindow"; }
          ];
          center = [
            { id = "Clock"; }
          ];
          right = [
            { id = "Tray"; }
            { id = "MediaMini"; }
            { id = "AudioVisualizer"; }
            { id = "Network"; }
            { id = "SystemMonitor"; }
            { id = "Volume"; }
            { id = "Microphone"; }
            { id = "Brightness"; }
            { id = "Bluetooth"; }
            { id = "NightLight"; }
            { id = "PowerProfile"; }
            { id = "LockKeys"; }
            { id = "NotificationHistory"; }
            { id = "SessionMenu"; }
            { id = "ControlCenter"; }
          ] ++ (if hostname == "hp-nix" then [{ id = "Battery"; }] else []);
        };
      };
    };
  };
}
