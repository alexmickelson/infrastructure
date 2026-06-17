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
      # No serverAddr — this node IS the server
      extraFlags = toString [
        "--disable=traefik"
        "--disable=servicelb"
        "--disable-cloud-controller"
        "--node-ip=${ip}"
        "--bind-address=${ip}"
        "--node-external-ip=${ip}"
        "--tls-san=${ip}"
        "--kubelet-arg=eviction-hard="
        "--kubelet-arg=eviction-soft="
        "--kubelet-arg=eviction-soft-grace-period="
        "--kubelet-arg=eviction-pressure-transition-period=0s"
      ];
    };
  };
}
# curl -sfL https://get.k3s.io | \
#   K3S_URL=https://100.112.73.80:6443 \
#   K3S_TOKEN="<your-node-token>" \
#   sh -s - agent \
#     --node-ip=<worker-tailscale-ip> \
#     --node-external-ip=<worker-tailscale-ip>


# kubectl taint node gpu-worker dedicated=department-server:NoSchedule