# ThinkPad E16 Gen 2 AMD power and laptop reliability defaults.
{ lib, ... }:

{
  services.power-profiles-daemon.enable = lib.mkForce false;

  services.tlp = {
    enable = true;
    pd.enable = true;

    settings = {
      TLP_AUTO_SWITCH = 2;

      START_CHARGE_THRESH_BAT0 = 75;
      STOP_CHARGE_THRESH_BAT0 = 80;
      RESTORE_THRESHOLDS_ON_BAT = 1;

      PLATFORM_PROFILE_ON_AC = "performance";
      PLATFORM_PROFILE_ON_BAT = "balanced";
      PLATFORM_PROFILE_ON_SAV = "low-power";

      CPU_DRIVER_OPMODE_ON_AC = "active";
      CPU_DRIVER_OPMODE_ON_BAT = "active";
      CPU_DRIVER_OPMODE_ON_SAV = "active";
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_SCALING_GOVERNOR_ON_SAV = "powersave";
      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 1;
      CPU_BOOST_ON_SAV = 0;

      WIFI_PWR_ON_AC = "off";
      WIFI_PWR_ON_BAT = "off";

      RUNTIME_PM_DRIVER_DENYLIST = "amdgpu rtw89_8852ce rtw89_pci btusb xhci_hcd";
    };
  };

  zramSwap = {
    enable = true;
    memoryPercent = 25;
    algorithm = "zstd";
  };

  services.fstrim.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
}
