
{ ... }:

{
  services.k3s.enable = true;
  services.k3s.role = "server";
  services.k3s.extraFlags = toString [
    # "--debug" # Optionally add additional args to k3s
    "--disable=traefik"
    "--tls-san 100.96.241.36"
  ];
}
