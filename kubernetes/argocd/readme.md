https://argo-cd.readthedocs.io/en/latest/getting_started/


```bash
kubectl create namespace argocd
kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

get the initial admin password

```bash
argocd admin initial-password -n argocd
```

let gateway handle tls

```bash
kubectl patch configmap argocd-cmd-params-cm \
    -n argocd \
    --type merge \
    -p '{"data":{"server.insecure":"true"}}'
```


## tailscale operator setup

```bash
kubectl create secret generic operator-oauth \
  --namespace tailscale \
  --from-literal=client_id="<OAuth client ID>" \
  --from-literal=client_secret="<OAuth client secret>"
```

## external-dns cloudflare secret

```bash
kubectl create secret generic external-dns-cloudflare \
  --namespace external-dns \
  --from-literal=cloudflare-api-token="<YOUR_API_TOKEN>"
```

You can generate a Cloudflare API token from the [Cloudflare Dashboard](https://dash.cloudflare.com/profile/api-tokens). The token needs at least:
- **Zone → DNS → Edit** (to create/update/delete DNS records)
- **Zone → Zone → Read** (to access zone information)
