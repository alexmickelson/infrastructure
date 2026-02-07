{ pkgs, lib, ... }:
{
  services.gitea-actions-runner = {
    instances.infrastructure = {
      enable = true;
      name = "infrastructure-runner";
      url = "https://git.alexmickelson.guru";
      tokenFile = "/data/runner/gitea-infrastructure-token.txt";
      labels = [
        "home-server"
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
      ];
      settings = {
        container = { enabled = false; };
      };
    };
  };

  environment.pathsToLink = [
    "/bin"
  ];

  # Make sure the user exists FIRST
  users.users.gitea-runner = {
    isNormalUser = true;
    description = "Gitea Actions Runner";
    home = "/home/gitea-runner";
    createHome = true;
    extraGroups = [ "docker" ];
    packages = with pkgs; [
      kubernetes-helm
    ];
    shell = pkgs.bash;
  };
  users.groups.gitea-runner = { };

  # Ensure proper permissions on the token file
  systemd.tmpfiles.rules = [
    "d /data/runner 0755 gitea-runner gitea-runner -"
    "f /data/runner/gitea-infrastructure-token.txt 0600 gitea-runner gitea-runner -"
  ];

  # Completely disable all sandboxing
  systemd.services.gitea-runner-infrastructure.serviceConfig = {
    # Your existing paths - but also add state directory
    ReadWritePaths = lib.mkForce [ ];  # Empty - no restrictions
    StateDirectory = lib.mkForce "gitea-runner-infrastructure";
    StateDirectoryMode = lib.mkForce "0755";
    
    # Disable all sandboxing features
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
    
    # Ensure it runs as your existing user
    User = lib.mkForce "gitea-runner";
    Group = lib.mkForce "gitea-runner";
    
    # Allow access to devices
    DeviceAllow = lib.mkForce [ ];
    DevicePolicy = lib.mkForce "auto";
    
    Restart = lib.mkForce "always";
  };
}