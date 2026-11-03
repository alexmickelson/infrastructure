{
  pkgs,
  ...
}:
{
  home.packages = [ pkgs.quickshell ];

  xdg.configFile."quickshell/shell.qml".source = ./shell.qml;
}
