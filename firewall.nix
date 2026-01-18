{ ... }:

{
  # Firewall configuration
  networking.firewall = {
    # Enable the firewall
    enable = true;
    
    # Allow specific TCP ports
    allowedTCPPorts = [ 
      # Add TCP ports here
      # Example: 80 443 for web servers
      # Example: 22 for SSH
      
      # Fragments - Port for local file sharing app
      # Uncomment the line below to enable Fragments support
      # 7777  # Default Fragments port (change if different)
    ];
    
    # Allow specific UDP ports
    allowedUDPPorts = [ 
      # Add UDP ports here
      # Example: 53 for DNS
    ];
    
    # Allow specific TCP port ranges
    allowedTCPPortRanges = [
      # Example: { from = 8000; to = 8100; }
    ];
    
    # Allow specific UDP port ranges
    allowedUDPPortRanges = [
      # Example: { from = 4000; to = 4010; }
    ];
    
    # Allow ping (ICMP)
    allowPing = true;
    
    # Log refused connections (useful for debugging)
    logReversePathDrops = false;
    
    # Log refused packets
    logRefusedConnections = false;
    
    # Extra commands to run when setting up the firewall
    extraCommands = ''
      # Add custom iptables rules here if needed
      # Example: iptables -A INPUT -p tcp --dport 8080 -j ACCEPT
    '';
    
    # Extra commands to run when stopping the firewall
    extraStopCommands = ''
      # Add cleanup commands here if needed
    '';
  };
}
