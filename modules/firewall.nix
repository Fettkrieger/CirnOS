# Firewall configuration
{ ... }:

{
  networking.firewall = {
    enable = true;
    
    # TCP ports
    allowedTCPPorts = [ 
      22     # SSH
      22000  # Syncthing sync traffic (TCP)
      3000   # Next.js dev server (LAN testing)
    ];
    
    # UDP ports
    allowedUDPPorts = [ 
      22000  # Syncthing sync traffic (QUIC)
      21027  # Syncthing local discovery
    ];
    
    # Port ranges (if needed)
    allowedTCPPortRanges = [];
    allowedUDPPortRanges = [];
    
    # Allow ping
    allowPing = true;
    
    # Logging (enable for debugging)
    logReversePathDrops = false;
    logRefusedConnections = false;
  };
}
