
opencost

https://opencost.io/docs/installation/helm

## Prometheus

https://opencost.io/docs/installation/prometheus

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm upgrade --install prometheus prometheus-community/prometheus \
    --namespace prometheus-system --create-namespace \
    --set prometheus-pushgateway.enabled=false \
    --set alertmanager.enabled=false \
    -f https://raw.githubusercontent.com/opencost/opencost/develop/kubernetes/prometheus/extraScrapeConfigs.yaml
```

## OpenCost

```bash
helm repo add opencost-charts https://opencost.github.io/opencost-helm-chart
helm repo update

helm upgrade --install opencost opencost-charts/opencost \
    --namespace opencost \
    --create-namespace \
    -f values.yaml
```