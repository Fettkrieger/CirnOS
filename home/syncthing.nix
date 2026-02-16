{ ... }:

{
  services.syncthing = {
    enable = true;

    # Keep GUI-added devices/folders from the web UI across restarts.
    overrideDevices = false;
    overrideFolders = false;

    settings = {
      options = {
        # Disable telemetry prompt.
        urAccepted = -1;
      };
    };
  };
}
