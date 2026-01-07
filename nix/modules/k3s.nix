
{ ... }:

{
  services.k3s = {
    enable = true;
    role = "server";
    extraFlags = toString [
      "--disable=traefik"
      "--bind-address 100.122.128.107"
      "--node-external-ip 100.122.128.107"
      "--tls-san 100.122.128.107"


      # Disable disk-based evictions
      "--kubelet-arg=eviction-hard="
      "--kubelet-arg=eviction-soft="
      "--kubelet-arg=eviction-soft-grace-period="
      "--kubelet-arg=eviction-pressure-transition-period=0s"
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
