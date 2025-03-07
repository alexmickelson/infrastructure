# sources

> note: k0s never works as well as you think

<https://k3s.io/>


nix instructions: <https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/networking/cluster/k3s/README.md>



## tailscale operator

```
helm repo add tailscale https://pkgs.tailscale.com/helmcharts
helm repo update
helm upgrade \
  --install \
  tailscale-operator \
  tailscale/tailscale-operator \
  --namespace=tailscale \
  --create-namespace \
  --set-string oauth.clientId="<OAauth client ID>" \
  --set-string oauth.clientSecret="<OAuth client secret>" \
  --wait
```


Currently clouflare domains cannot be CNAME'd to tailscale domains:
- <https://github.com/tailscale/tailscale/issues/7650>
- related, different IP addresses: <https://tailscale.com/blog/choose-your-ip#natural-solutions>


## Kubernetes ingress controller

```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.12.0/deploy/static/provider/baremetal/deploy.yaml
``

I'll need to create a custom service to bring in port 80 and 443 later

```
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  -f values.yml
```
