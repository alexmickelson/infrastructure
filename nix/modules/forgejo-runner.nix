{ pkgs, lib, ... }:
{
  users.users.forgejo-runner = {
    isNormalUser = true;
    description = "Forgejo Actions Runner";
    home = "/home/forgejo-runner";
    createHome = true;
    group = "forgejo-runner";
    extraGroups = [ "docker" ];
    packages = with pkgs; [
      kubernetes-helm
      nodejs_24
      openssl
      gettext
    ];
    shell = pkgs.bash;
  };
  users.groups.forgejo-runner = { };

  security.sudo.extraRules = [
    {
      users = [ "forgejo-runner" ];
      commands = [
        {
          command = "/run/current-system/sw/bin/nix-collect-garbage";
          options = [
            "NOPASSWD"
            "SETENV"
          ];
        }
      ];
    }
  ];

  system.activationScripts.zfs-delegate-forgejo-runner = {
    text =
      let
        poolNames = [
          "data-ssd"
          "backup"
        ];
        permissions = "compression,create,destroy,mount,mountpoint,receive,rollback,send,snapshot,hold";
      in
      ''
        ${lib.concatMapStringsSep "\n" (
          pool: "${pkgs.zfs}/bin/zfs allow -u forgejo-runner ${permissions} ${pool} || true"
        ) poolNames}
      '';
    deps = [ ];
  };

  systemd.services.forgejo-runner-infrastructure = {
    description = "Forgejo Actions Runner";
    after = [
      "network-online.target"
      "docker.service"
    ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.sudo ];

    environment = {
      PATH = lib.mkForce "/run/wrappers/bin:/etc/profiles/per-user/forgejo-runner/bin:/run/current-system/sw/bin";
      NIX_PATH = "nixpkgs=${pkgs.path}";
    };

    serviceConfig = {
      ExecStart = "${pkgs.forgejo-runner}/bin/forgejo-runner daemon --config /data/runner/forgejo-runner.yml";
      WorkingDirectory = "/var/lib/forgejo-runner/infrastructure";
      User = "forgejo-runner";
      Group = "forgejo-runner";
      Restart = "always";
      RestartSec = 5;

      # matches the hardening posture you already forced off on the module version —
      # host-native execution needs broad access (docker socket, zfs, sudo, etc.)
      DynamicUser = false;
      PrivateDevices = false;
      PrivateMounts = false;
      PrivateTmp = false;
      PrivateUsers = false;
      ProtectClock = false;
      ProtectControlGroups = false;
      ProtectHome = false;
      ProtectHostname = false;
      ProtectKernelLogs = false;
      ProtectKernelModules = false;
      ProtectKernelTunables = false;
      ProtectProc = "default";
      ProtectSystem = false;
      NoNewPrivileges = false;
      RestrictNamespaces = false;
      RestrictRealtime = false;
      RestrictSUIDSGID = false;
      RemoveIPC = false;
      LockPersonality = false;

      DeviceAllow = [ "/dev/zfs rw" ];
      DevicePolicy = "auto";
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/forgejo-runner/infrastructure 0750 forgejo-runner forgejo-runner -"
  ];
}
