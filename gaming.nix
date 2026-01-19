{ config, pkgs, ... }:

{
  # Gaming optimizations for NVIDIA RTX 5070 Ti + AMD Ryzen 7800X3D
  
  # Kernel parameters for gaming performance
  boot.kernelParams = [
    # CPU scheduling optimizations for gaming
    "preempt=full"  # Full preemption for low latency
    "mitigations=off"  # Disable CPU mitigations for performance (security trade-off)
    
    # NVIDIA-specific gaming parameters
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1"  # Better suspend/resume and VRAM management
    "nvidia_drm.modeset=1"  # Required for Wayland and better performance
    
    # CPU frequency scaling for consistent performance
    "amd_pstate=passive"  # Use passive mode for better control
  ];
  
  # Enable required kernel modules for gaming
  boot.kernelModules = [
    "kvm-amd"  # Virtualization support (useful for some games)
    "cpufreq-dt"  # CPU frequency scaling
  ];
  
  # CPU frequency scaling governor for gaming (performance over power)
  powerManagement.cpuFreqGovernor = "performance";
  
  # NVIDIA gaming optimizations
  hardware.nvidia = {
    # Enable persistent kernel module (reduces driver loading overhead)
    persistenced = true;
    
    # Enable power management for better VRAM management
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    
    # Ensure modesetting is enabled for better performance
    modesetting.enable = true;
    
    # Use beta driver for newest GPU support
    package = config.boot.kernelPackages.nvidiaPackages.beta;
  };
  
  # Enable swap for edge cases (important for gaming with large VRAM allocations)
  zramSwap = {
    enable = true;
    memoryPercent = 50;  # Use 50% of RAM as swap
    priority = 32767;  # High priority swap
  };
  
  # Gaming packages
  environment.systemPackages = with pkgs; [
    # Gaming platforms and tools
    steam
    steam-run  # Run unpatched binaries for games
    proton-ge  # Proton with gaming enhancements
    
    # Game launchers
    lutris  # For running various games
    heroic  # Epic Games and GOG launcher
    
    # Performance monitoring
    mangohud  # In-game performance overlay
    goverlay  # GUI for MangoHUD
    
    # Gaming utilities
    gamemode  # Game mode daemon for auto-optimization
    lib32  # 32-bit support libraries (essential for many games)
    
    # Vulkan support (modern gaming API)
    vulkan-tools
    vulkan-validation-layers
    
    # OpenGL support
    glxinfo
  ];
  
  # Enable gamemode service
  services.gamemode.enable = true;
  
  # Security/sandboxing adjustments for gaming (some games need this)
  security.protectedKernelLogs = false;
  
  # Network optimizations for online gaming
  boot.kernel.sysctl = {
    # Network buffer optimization
    "net.core.rmem_max" = 134217728;  # 128 MB
    "net.core.wmem_max" = 134217728;  # 128 MB
    
    # TCP window scaling for better throughput
    "net.ipv4.tcp_window_scaling" = 1;
    
    # Reduce latency in network
    "net.ipv4.tcp_tw_reuse" = 1;
    
    # Increase connection backlog
    "net.core.netdev_max_backlog" = 4096;
  };
  
  # User groups for gaming
  users.users.krieger.extraGroups = [ "gamemode" ];
  
  # Disable power saving modes during gaming (managed by gamemode)
  services.tlp.enable = false;  # Disable TLP if using gamemode
}
