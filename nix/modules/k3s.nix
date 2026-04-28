
{ ... }:

{
  services.k3s = {
    enable = true;
    role = "server";
    extraFlags = toString [
      "--disable=traefik"
      "--node-ip=100.110.207.108"
      "--bind-address 100.110.207.108"
      "--node-external-ip 100.110.207.108"
      "--tls-san 100.110.207.108"


      # Disable disk-based evictions
      "--kubelet-arg=eviction-hard="
      "--kubelet-arg=eviction-soft="
      "--kubelet-arg=eviction-soft-grace-period="
      "--kubelet-arg=eviction-pressure-transition-period=0s"
    ];
    serverAddr = "https://100.110.207.108:6443";
  };
  networking.firewall.allowedTCPPorts = [
    443
    80
    10250
  ];
  networking.firewall.allowedUDPPorts = [
    443
    80
  ];
}
