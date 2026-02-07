{ pkgs, lib, ... }:
{
  services.gitea-actions-runner = {
    instances.infrastructure = {
      enable = true;
      name = "infrastructure-runner";
      url = "https://git.alexmickelson.guru";
      tokenFile = "/data/runner/gitea-infrastructure-token.txt";
      labels = [
        "home-server:host"  # Changed from just "home-server"
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
        container = { 
          enabled = false;
        };
        # Add explicit host settings
        host = {
          workdir_parent = "/var/lib/gitea-runner/infrastructure";
        };
      };
    };
  };

  environment.pathsToLink = [
    "/bin"
  ];

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

  systemd.tmpfiles.rules = [
    "d /data/runner 0755 gitea-runner gitea-runner -"
    "f /data/runner/gitea-infrastructure-token.txt 0600 gitea-runner gitea-runner -"
  ];

  systemd.services.gitea-runner-infrastructure.serviceConfig = {
    WorkingDirectory = lib.mkForce "/var/lib/gitea-runner/infrastructure";
    
    ReadWritePaths = lib.mkForce [ 
      "/var/lib/gitea-runner"
      "/data/cloudflare/"
      "/data/runner/infrastructure"
      "/data/runner"
      "/home/github/infrastructure"
    ];
    
    # CRITICAL: Allow the runner to create child processes without namespace restrictions
    BindReadOnlyPaths = lib.mkForce [
      "/nix/store"
      "/nix/var"
      "/run/current-system"
    ];
    
    # Completely disable mount namespace isolation
    PrivateMounts = lib.mkForce false;
    MountFlags = lib.mkForce "shared";  # Share mounts with child processes
    
    # Allow the runner process to use unshare/clone without restrictions
    SystemCallFilter = lib.mkForce [ ];
    RestrictNamespaces = lib.mkForce false;
    
    # Give the runner CAP_SYS_ADMIN to create namespaces if needed, but inherit parent's
    AmbientCapabilities = lib.mkForce [ "CAP_SYS_ADMIN" ];
    CapabilityBoundingSet = lib.mkForce [ "CAP_SYS_ADMIN" ];
    
    # Disable all other sandboxing features
    DynamicUser = lib.mkForce false;
    PrivateDevices = lib.mkForce false;
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
    RestrictRealtime = lib.mkForce false;
    RestrictSUIDSGID = lib.mkForce false;
    RemoveIPC = lib.mkForce false;
    LockPersonality = lib.mkForce false;
    RestrictAddressFamilies = lib.mkForce [ ];
    
    User = lib.mkForce "gitea-runner";
    Group = lib.mkForce "gitea-runner";
    
    DeviceAllow = lib.mkForce [ "/dev/zfs rw" ];
    DevicePolicy = lib.mkForce "auto";
    
    Restart = lib.mkForce "always";
  };
}