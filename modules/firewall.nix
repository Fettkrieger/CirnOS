# Firewall configuration
{ ... }:

{
  networking.firewall = {
    enable = true;
    
    # TCP ports
    allowedTCPPorts = [ 
      22     # SSH
      7777   # Fragments torrent client
    ];
    
    # UDP ports
    allowedUDPPorts = [ 
      7777   # Fragments torrent client
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
