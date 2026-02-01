# NVIDIA GPU configuration for RTX 5070 Ti
{ config, pkgs, ... }:

{
  # NVIDIA gaming environment variables
  environment.sessionVariables = {
    __GL_GSYNC_ALLOWED = "1";
    __GL_VRR_ALLOWED = "1";
  };
  # NVIDIA kernel parameters
  boot.kernelParams = [ 
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
    "nvidia_drm.modeset=1"
  ];

  # NVIDIA drivers
  services.xserver.videoDrivers = [ "nvidia" ];

  # Graphics support
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.beta;
  };

  # AMD CPU microcode
  hardware.cpu.amd.updateMicrocode = true;

  # GDM Wayland with NVIDIA
  services.displayManager.gdm.wayland = true;
}
