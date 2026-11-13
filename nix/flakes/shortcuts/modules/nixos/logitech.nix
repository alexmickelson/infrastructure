{ config, lib, ... }:
let
  mice = [
    {
      name = "Wireless Mouse MX Master 3";
      cid = 195;
    }
    {
      name = "MX Master 4";
      cid = 416;
    }
  ];
in
{
  config = lib.mkIf config.shortcuts.logitech {
    services.logiops = {
      enable = true;
      config = {
        io_timeout = 3000.0;
        devices = map (mouse: {
          inherit (mouse) name;
          buttons = [
            {
              inherit (mouse) cid;
              action = {
                type = "Keypress";
                keys = [ "KEY_LEFTMETA" ];
              };
            }
          ];
        }) mice;
      };
    };

    services.udev.extraRules = lib.concatMapStringsSep "\n" (
      mouse:
      ''ACTION=="add", SUBSYSTEM=="hidraw", ATTRS{name}=="${mouse.name}", RUN+="${config.systemd.package}/bin/systemctl --no-block try-restart logid.service"''
    ) mice;
  };
}
