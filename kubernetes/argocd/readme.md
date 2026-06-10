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