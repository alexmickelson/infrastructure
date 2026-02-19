{ pkgs, lib, ... }:
{
  services.gitea-actions-runner = {
    instances.infrastructure = {
      enable = true;
      name = "infrastructure-runner";
      url = "https://git.alexmickelson.guru";
      tokenFile = "/data/runner/gitea-infrastructure-token.txt";
      labels = [
        "self-hosted"
        "home-server"
        "self-hosted:host"
        "home-server:host"
        "native:host"
      ];
      hostPackages = with pkgs; [
        bashNonInteractive
        bash
        coreutils
        docker
        git
        git-secret
        zfs
        sanoid
        mbuffer
        lzop
        kubectl
        kubernetes-helm
        curl
      ];
      settings = {
        container = { 
          enabled = false;
        };
        runner = {
          capacity = 5;
        };
      };
    };
  };

  users.users.gitea-runner = {
    isNormalUser = true;
    description = "Gitea Actions Runner";
    home = "/home/gitea-runner";
    createHome = true;
    group = "gitea-runner";
    extraGroups = [ "docker" ];
    packages = with pkgs; [
      kubernetes-helm
    ];
    shell = pkgs.bash;
  };

  users.groups.gitea-runner = { };

  security.sudo.extraRules = [
    {
      users = [ "gitea-runner" ];
      commands = [
        {
          command = "${pkgs.nix}/bin/nix-collect-garbage";
          options = [ "NOPASSWD" "SETENV" ];
        }
        {
          command = "${pkgs.nix}/bin/nix-env";
          options = [ "NOPASSWD" "SETENV" ];
        }
      ];
    }
  ];

  system.activationScripts.zfs-delegate-gitea-runner = {
    text = 
      let
        poolNames = [ "data-ssd" "backup" ];
        permissions = "compression,create,destroy,mount,mountpoint,receive,rollback,send,snapshot,hold";
      in
      ''
        ${lib.concatMapStringsSep "\n" (pool: 
          "${pkgs.zfs}/bin/zfs allow -u gitea-runner ${permissions} ${pool} || true"
        ) poolNames}
      '';
    deps = [ ];
  };

  systemd.services.gitea-runner-infrastructure.serviceConfig = {
    WorkingDirectory = lib.mkForce "/var/lib/gitea-runner/infrastructure";
    
    User = lib.mkForce "gitea-runner";
    Group = lib.mkForce "gitea-runner";
    
    DynamicUser = lib.mkForce false;
    PrivateDevices = lib.mkForce false;
    PrivateMounts = lib.mkForce false;
    PrivateTmp = lib.mkForce false;
    PrivateUsers = lib.mkForce false;
    ProtectClock = lib.mkForce false;
    ProtectControlGroups = lib.mkForce false;
    ProtectHome = lib.mkForce false;
    ProtectHostname = lib.mkForce false;
    ProtectKernelLogs = lib.mkForce false;
    ProtectKernelModules = lib.mkForce false;
    ProtectKernelTunables = lib.mkForce false;
    ProtectProc = lib.mkForce "default";
    ProtectSystem = lib.mkForce false;
    NoNewPrivileges = lib.mkForce false;
    RestrictNamespaces = lib.mkForce false;
    RestrictRealtime = lib.mkForce false;
    RestrictSUIDSGID = lib.mkForce false;
    RemoveIPC = lib.mkForce false;
    LockPersonality = lib.mkForce false;
    SystemCallFilter = lib.mkForce [ ];
    RestrictAddressFamilies = lib.mkForce [ ];
    ReadWritePaths = lib.mkForce [ ];
    BindReadOnlyPaths = lib.mkForce [ ];
    BindPaths = lib.mkForce [ "/run/wrappers" ];
    
    DeviceAllow = lib.mkForce [ "/dev/zfs rw" ];
    DevicePolicy = lib.mkForce "auto";
    
    Restart = lib.mkForce "always";
  };

  systemd.services.gitea-runner-infrastructure.path = [ pkgs.sudo ];
}