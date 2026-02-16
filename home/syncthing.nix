{ ... }:

{
  services.syncthing = {
    enable = true;

    # Keep GUI-added devices/folders instead of forcing only declarative state.
    # This lets you pair hosts from the Syncthing UI without committing IDs.
    overrideDevices = false;
    overrideFolders = false;

    settings = {
      options = {
        # Disable telemetry prompt.
        urAccepted = -1;
      };

      folders = {
        "sync" = {
          path = "/home/krieger/Sync";
          id = "krieger-sync";
          label = "Sync";
          devices = [ ];
        };
      };
    };
  };
}
