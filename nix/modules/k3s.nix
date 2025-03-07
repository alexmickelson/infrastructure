
{ ... }:

{
  services.k3s.enable = true;
  services.k3s.role = "server";
  services.k3s.extraFlags = toString [
    # "--debug" # Optionally add additional args to k3s
    "--disable=traefik"
    "--tls-san 100.122.128.107"
  ];
  networking.firewall.allowedTCPPorts = [
    443
    80
  ];
  networking.firewall.allowedUDPPorts = [
    443
    80
  ];
}
