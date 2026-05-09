
{ config, lib, ... }:

{
  options.services.k3s.nodeIp = lib.mkOption {
    type = lib.types.str;
    description = "The IP address to bind k3s to (e.g. Tailscale IP).";
  };

  config = let
    ip = config.services.k3s.nodeIp;
  in {
    services.k3s = {
      enable = true;
      role = "server";
      extraFlags = toString [
        "--disable=traefik"
        "--node-ip=${ip}"
        "--bind-address ${ip}"
        "--node-external-ip ${ip}"
        "--tls-san ${ip}"

        # Disable disk-based evictions
        "--kubelet-arg=eviction-hard="
        "--kubelet-arg=eviction-soft="
        "--kubelet-arg=eviction-soft-grace-period="
        "--kubelet-arg=eviction-pressure-transition-period=0s"
      ];
      serverAddr = "https://${ip}:6443";
    };
    # networking.firewall.allowedTCPPorts = [
    #   443
    #   80
    #   10250
    # ];
    # networking.firewall.allowedUDPPorts = [
    #   443
    #   80
    # ];
  };
}
