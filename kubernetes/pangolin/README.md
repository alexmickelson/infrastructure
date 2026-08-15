# Pangolin Newt site

This workload connects the Kubernetes cluster to the Pangolin control plane on
the VPS. It does not create a Pangolin public resource; create that resource in
the Pangolin dashboard after Newt is connected.

## Vault data

The `vault-backend` ClusterSecretStore already selects Vault's KV v2 `secret`
mount. Store these values at the logical Vault path `secret/newt`:

```sh
vault kv put secret/newt \
  PANGOLIN_ENDPOINT=https://pangolin.alexmickelson.guru \
  NEWT_ID='<site ID from Pangolin>' \
  NEWT_SECRET='<site secret from Pangolin>'
```

`newt.yml` reads that path with `remoteRef.key: newt` and creates the
`pangolin/newt-auth` Kubernetes Secret. Never commit any of these values.
After changing the Vault credentials, force an ExternalSecret refresh and
restart Newt so its environment is rebuilt from the updated Secret:

```sh
kubectl annotate externalsecret/newt-auth -n pangolin \
  force-sync="$(date +%s)" --overwrite
kubectl rollout restart deployment/newt -n pangolin
```

## Pangolin public resource

Create an HTTP public resource for the Kubernetes site with this target:

| Setting | Value |
| --- | --- |
| Target site | The Kubernetes Newt site |
| Method | `http` |
| Hostname | `pangolin-gateway-istio.istio-ingress.svc.cluster.local` |
| Port | `80` |
| Path | `/` (prefix match) |

The `pangolin-gateway` Gateway is intentionally HTTP-only and ClusterIP-only:
Pangolin terminates public TLS on the VPS and forwards the original `Host`
header across the Newt tunnel. Existing HTTPRoutes are attached to it in
addition to their Tailscale Gateway parents.

Newt persists its resolved configuration at `/data/pangolin/newt` on the
Kubernetes node hosting its Pod. The initial permission-fixing init container
sets that directory to Newt's unprivileged UID before the connector starts.

Pangolin Community Edition requires one public resource per hostname. A single
`*.alexmickelson.guru` resource requires Pangolin Cloud or Enterprise plus a
DNS-01 wildcard certificate on the VPS.
