{
  pkgs,
  ...
}:
let
  touchpadController = "0000:00:19.1";
in
{
  services.udev.extraRules = ''
  ACTION=="add|bind", SUBSYSTEM=="pci", DRIVER=="intel-lpss", KERNELS=="${touchpadController}", ATTR{power/control}="on"
'';
}
