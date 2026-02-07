{ pkgs, lib, ... }:
{
  services.gitea-actions-runner = {
    instances.infrastructure = {
      enable = true;
      name = "infrastructure-runner";
      url = "https://git.alexmickelson.guru";
      tokenFile = "/data/runner/gitea-infrastructure-token.txt";
      labels = [
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
      ];
      settings = {
        container = { 
          enabled = false;
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
    "d /var/lib/gitea-runner 0755 gitea-runner gitea-runner -"
    "d /var/lib/gitea-runner/infrastructure 0755 gitea-runner gitea-runner -"
  ];

  # Completely override the service to run as a simple user process
  systemd.services.gitea-runner-infrastructure.serviceConfig = lib.mkForce {
    Type = "simple";
    User = "gitea-runner";
    Group = "gitea-runner";
    WorkingDirectory = "/var/lib/gitea-runner/infrastructure";
    Restart = "always";
    RestartSec = "5s";
    
    # No sandboxing - inherit everything from the system
    PrivateTmp = false;
    ProtectSystem = false;
    ProtectHome = false;
    NoNewPrivileges = false;
  };
}