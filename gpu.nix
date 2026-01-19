{ config, pkgs, ... }:

{
  # NVIDIA kernel parameters for suspend/resume and Wayland support
  boot.kernelParams = [ 
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1" # For suspend/resume support
    "nvidia_drm.modeset=1" # Enable modesetting for Wayland
  ];

  # NVIDIA GPU configuration
  services.xserver.videoDrivers = [ "nvidia" ];

  # Enable OpenGL and graphics support
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # Enable 32-bit support for gaming and compatibility
  };

  hardware.nvidia = {
    # Modesetting is required for Wayland compositors
    modesetting.enable = true;

    # Enable power management (set to false for desktops usually)
    powerManagement.enable = false;
    powerManagement.finegrained = false;

    # Use the open-source NVIDIA driver (beta for latest GPU support)
    open = true;

    # Enable the NVIDIA settings menu (accessible via `nvidia-settings` command)
    nvidiaSettings = true;

    # Select the appropriate driver version
    # Using beta for newest GPU support (RTX 5070 Ti)
    package = config.boot.kernelPackages.nvidiaPackages.beta;
  };

  # CPU microcode updates for AMD Ryzen 7800X3D
  hardware.cpu.amd.updateMicrocode = true;

  # GDM Wayland support with NVIDIA
  services.displayManager.gdm.wayland = true;
}
