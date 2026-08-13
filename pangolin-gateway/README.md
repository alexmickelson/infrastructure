# Pangolin VPS gateway

This Compose stack is the public Pangolin control plane and tunnel relay. It is
intended for a VPS, not the Kubernetes cluster. The cluster will run a Newt
connector separately, which creates an outbound encrypted tunnel to this VPS.

## Before first start

1. Copy `.env.example` to `.env`, then set `SERVER_SECRET` to a unique random
   secret (at least 32 characters). Do not change it after startup without
   Pangolin's secret-rotation procedure.
2. Create public DNS records for `pangolin.alexmickelson.guru` and the resource
   hostnames you plan to expose, all pointing to this VPS.
3. Open TCP 80/443 and UDP 51820/21820 in the VPS firewall and provider
   firewall.
4. Confirm no other VPS service listens on ports 80 or 443.

Start and inspect the stack:

```sh
docker compose up -d
docker compose ps
docker compose logs -f
```

To install the daily 03:17 local-time update job, run:

```sh
./install.sh
```

The cron job runs `git pull --ff-only` and `docker compose up -d` from this
checkout. It refuses to overwrite local Git changes and writes output to
`/tmp/pangolin-gateway-update.log`.

Complete initial setup at `https://pangolin.alexmickelson.guru/auth/initial-setup`.
Then create a Newt site in Pangolin. Deploy its generated Newt credentials only
in Kubernetes, where the connector will target the dedicated `pangolin-gateway`
Istio Service. Keep the existing Tailscale gateway separate for unauthenticated
tailnet access.

Do not expose Traefik's insecure API/dashboard separately; it is reachable only
inside the Gerbil network namespace.
