
{ ... }:

{
  services.k3s = {
    enable = true;
    role = "server";
    extraFlags = toString [
      # "--debug" # Optionally add additional args to k3s
      "--disable=traefik"
      "--bind-address 100.122.128.107"
      "--node-external-ip 100.122.128.107"
      "--tls-san 100.122.128.107"
    ];
    serverAddr = "https://100.122.128.107:6443";
  };
  networking.firewall.allowedTCPPorts = [
    443
    80
  ];
  networking.firewall.allowedUDPPorts = [
    443
    80
  ];
}
