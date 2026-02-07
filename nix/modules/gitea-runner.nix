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

# Override only the sandboxing settings, keep ExecStart from the module
systemd.services.gitea-runner-infrastructure.serviceConfig = {
  # Keep the working directory
  WorkingDirectory = lib.mkForce "/var/lib/gitea-runner/infrastructure";
  
  # Override user/group
  User = lib.mkForce "gitea-runner";
  Group = lib.mkForce "gitea-runner";
  
  # Remove ALL sandboxing - run as a normal user process
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
  
  # Allow access to devices
  DeviceAllow = lib.mkForce [ "/dev/zfs rw" ];
  DevicePolicy = lib.mkForce "auto";
  
  Restart = lib.mkForce "always";
};
}