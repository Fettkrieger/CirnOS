# Firewall configuration
{ lib, hostname, ... }:

let
  isRoamingLaptop = hostname == "lenuwu-nix";
in

{
  networking.firewall = {
    enable = true;
    
    # TCP ports
    allowedTCPPorts = [
      22000  # Syncthing sync traffic (TCP)
    ] ++ lib.optionals (!isRoamingLaptop) [
      22     # SSH
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
