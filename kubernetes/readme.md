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


<!-- I had to modify the base ingress to allow for use on 80 and 443. There should be a way to do this with helm, but I can never quite get it to work

this is the original: https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.12.0/deploy/static/provider/baremetal/deploy.yaml

the `ingress-nginx-controller` was changed to a daemonset rather than an deployment
 -->

ingress

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.kind=DaemonSet \
  --set controller.hostPort.enabled=true \
  --set controller.hostPort.ports.http=80 \
  --set controller.hostPort.ports.https=443 \
  --set controller.service.type=NodePort \
  --set controller.allowSnippetAnnotations=true \
  --set controller.config.annotations-risk-level=Critical \
  --set controller.metrics.enabled=false \
  --set controller.ingressClassResource.default=true
```
<!-- https://github.com/kubernetes/ingress-nginx/issues/12618 for why anotation risk needs to be critical-->



