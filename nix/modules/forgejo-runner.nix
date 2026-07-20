{ pkgs, lib, ... }:
{
  services.gitea-actions-runner = {
    package = pkgs.forgejo-runner;
    instances.infrastructure = {
      enable = true;
      name = "infrastructure-runner";
      url = "https://forgejo.alexmickelson.guru";
      tokenFile = "/data/runner/forgejo-infrastructure-token.txt";
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
        nodejs_24
        openssl
        gettext
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
          options = [ "NOPASSWD" "SETENV" ];
        }
      ];
    }
  ];

  system.activationScripts.zfs-delegate-forgejo-runner = {
    text = 
      let
        poolNames = [ "data-ssd" "backup" ];
        permissions = "compression,create,destroy,mount,mountpoint,receive,rollback,send,snapshot,hold";
      in
      ''
        ${lib.concatMapStringsSep "\n" (pool: 
          "${pkgs.zfs}/bin/zfs allow -u forgejo-runner ${permissions} ${pool} || true"
        ) poolNames}
      '';
    deps = [ ];
  };

  systemd.services.gitea-runner-infrastructure.serviceConfig = {
    WorkingDirectory = lib.mkForce "/var/lib/gitea-runner/infrastructure";
    
    User = lib.mkForce "forgejo-runner";
    Group = lib.mkForce "forgejo-runner";
    
    Environment = lib.mkForce [
      "PATH=/run/wrappers/bin:/etc/profiles/per-user/forgejo-runner/bin:/run/current-system/sw/bin"
      "NIX_PATH=nixpkgs=${pkgs.path}"
    ];
    
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
    
    DeviceAllow = lib.mkForce [ "/dev/zfs rw" ];
    DevicePolicy = lib.mkForce "auto";
    
    Restart = lib.mkForce "always";
  };

  systemd.services.gitea-runner-infrastructure.path = [ pkgs.sudo ];
}
