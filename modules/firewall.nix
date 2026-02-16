# Firewall configuration
{ ... }:

{
  networking.firewall = {
    enable = true;
    
    # TCP ports
    allowedTCPPorts = [ 
      22     # SSH
      7777   # Fragments torrent client
      22000  # Syncthing sync traffic (TCP)
    ];
    
    # UDP ports
    allowedUDPPorts = [ 
      7777   # Fragments torrent client
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
