## Cloudflare cert manager

<https://cert-manager.io/docs/installation/helm/>
```bash
helm repo add jetstack https://charts.jetstack.io --force-update
helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.16.2 \
  --set crds.enabled=true
```


<https://medium.com/@kevinlutzer9/managed-ssl-certs-for-a-private-kubernetes-cluster-with-cloudflare-cert-manager-and-lets-encrypt-7987ba19044f>

```bash
kubectl create -n cert-manager secret generic cloudflare-api-key-secret --from-literal=api-key=<TOKEN>
```


then apply `issuer.yml`1