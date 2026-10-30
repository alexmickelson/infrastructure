#!/usr/bin/env bash
#
# Intended scenario: pods in an ambient namespace that kubelet started while istio-cni was not yet in
# the node's CNI chain - a node reboot on k3s, where the primary CNI config istio-cni is chained into
# gets regenerated while kubelet is building sandboxes. Those pods never receive a CNI ADD, so no
# ztunnel listener exists in them, and they are invisible from every other angle: the pod is Ready,
# its Service has endpoints, probes pass and ArgoCD reports the app Healthy. Only a meshed peer or an
# istio gateway sees it, as a refused HBONE dial to <pod-ip>:15008 that the gateway answers with 503.
# A public resource behind pangolin shows the same 503 once its SSO check has been satisfied.
#
# Run it after a reboot, or whenever a service behind an istio gateway answers 503 while its pod is
# Running and Ready. It reports the orphans, re-runs the istio-cni agent's startup reconcile, and
# recreates only the pods still missing a listener. Re-runnable: a converged cluster is reported clean
# and nothing is touched. Pods whose namespace network policy refuses the prober are reported as
# undecided rather than repaired, because a refusal there is indistinguishable from a missing listener.
#
# DRY_RUN=1 reports only. PROBE_NAMESPACE picks a namespace the caller may create Jobs in; the prober
# has to run inside the cluster, off the mesh, since the pod CIDR is not routable from a peer host.
set -euo pipefail

HBONE_PORT=15008
PROBE_IMAGE="docker.io/library/busybox:1.38.0"
EXCLUDED_NAMESPACES=" kube-system istio-system "
PROBE_NAMESPACE="${PROBE_NAMESPACE:-hermes}"
PROBE_SETTLE_SECONDS="${PROBE_SETTLE_SECONDS:-120}"
CNI_SETTLE_SECONDS="${CNI_SETTLE_SECONDS:-45}"
POD_SETTLE_SECONDS="${POD_SETTLE_SECONDS:-20}"
DRY_RUN="${DRY_RUN:-0}"
RUN_ID="$(date +%s)"
PROBE_SEQ=0

for command in kubectl awk; do
  command -v "$command" >/dev/null || { echo "missing required command: $command" >&2; exit 127; }
done

ambient_namespaces() {
  kubectl get ns -l istio.io/dataplane-mode=ambient -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'
}

ambient_candidate_pods() {
  local ambient
  ambient=" $(ambient_namespaces | tr '\n' ' ') "
  kubectl get pods -A -o jsonpath='{range .items[*]}{.metadata.namespace}{"|"}{.metadata.name}{"|"}{.status.podIP}{"|"}{.spec.hostNetwork}{"|"}{.status.phase}{"|"}{.metadata.deletionTimestamp}{"|"}{.metadata.labels.istio\.io/dataplane-mode}{"|"}{range .status.conditions[?(@.type=="Ready")]}{.status}{end}{"\n"}{end}' |
    awk -F'|' -v ambient="$ambient" -v excluded="$EXCLUDED_NAMESPACES" '
      index(ambient, " " $1 " ") == 0 || index(excluded, " " $1 " ") != 0 { next }
      $4 == "true" || $5 != "Running" || $6 != "" || $7 == "none" || $3 == "" || $8 != "True" { next }
      { print $1, $2, $3 }'
}

probe_hbone() {
  local job result expected actual ips
  PROBE_SEQ=$((PROBE_SEQ + 1))
  job="istio-mesh-probe-${RUN_ID}-${PROBE_SEQ}"
  ips="$(printf '%s\n' "$@" | awk 'NF' | tr '\n' ' ')"
  kubectl -n "$PROBE_NAMESPACE" create -f - >/dev/null <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: $job
spec:
  backoffLimit: 0
  ttlSecondsAfterFinished: 600
  template:
    metadata:
      labels:
        istio.io/dataplane-mode: none
    spec:
      restartPolicy: Never
      containers:
        - name: probe
          image: $PROBE_IMAGE
          env:
            - name: HBONE_PORT
              value: "$HBONE_PORT"
            - name: PROBE_IPS
              value: "$ips"
          command: ["/bin/sh", "-c", "for ip in \$PROBE_IPS; do if nc -w 1 \"\$ip\" \"\$HBONE_PORT\" </dev/null >/dev/null 2>&1; then echo reachable \"\$ip\"; else echo orphan \"\$ip\"; fi; done"]
EOF
  kubectl -n "$PROBE_NAMESPACE" wait --for=condition=complete "job/$job" --timeout="${PROBE_SETTLE_SECONDS}s" >/dev/null
  result="$(kubectl -n "$PROBE_NAMESPACE" logs "job/$job")"
  kubectl -n "$PROBE_NAMESPACE" delete job "$job" --wait=false >/dev/null
  expected="$(printf '%s\n' $ips | awk 'NF' | wc -l)"
  actual="$(printf '%s\n' "$result" | awk 'NF' | wc -l)"
  if [ "$expected" != "$actual" ]; then
    echo "probe returned $actual of $expected results" >&2
    exit 1
  fi
  printf '%s\n' "$result"
}

orphan_pods() {
  local candidates
  candidates="$(ambient_candidate_pods)"
  [ -n "$candidates" ] || return 0
  probe_hbone $(printf '%s\n' "$candidates" | awk '{print $3}') |
    awk -v candidates="$candidates" '
      $1 == "orphan" { print $2 }' |
    while read -r ip; do
      printf '%s\n' "$candidates" | awk -v ip="$ip" '$3 == ip { print $1, $2, $3 }'
    done
}

restart_cni_agent() {
  kubectl -n istio-system delete pod -l k8s-app=istio-cni-node --wait=false >/dev/null
  sleep "$CNI_SETTLE_SECONDS"
}

workload_of_pod() {
  local ns="$1" name="$2" kind owner
  kind="$(kubectl -n "$ns" get pod "$name" -o jsonpath='{.metadata.ownerReferences[0].kind}')"
  owner="$(kubectl -n "$ns" get pod "$name" -o jsonpath='{.metadata.ownerReferences[0].name}')"
  if [ "$kind" = "ReplicaSet" ]; then
    kind="$(kubectl -n "$ns" get "replicaset/$owner" -o jsonpath='{.metadata.ownerReferences[0].kind}')"
    owner="$(kubectl -n "$ns" get "replicaset/$owner" -o jsonpath='{.metadata.ownerReferences[0].name}')"
  fi
  printf '%s/%s' "$kind" "$owner"
}

recreate_pod() {
  local ns="$1" name="$2" workload kind host_paths
  if [ "$DRY_RUN" = "1" ]; then
    echo "dry run: would recreate $ns/$name"
    return 0
  fi
  host_paths="$(kubectl -n "$ns" get pod "$name" -o jsonpath='{range .spec.volumes[*]}{.hostPath.path}{"\n"}{end}')"
  workload="$(workload_of_pod "$ns" "$name")"
  kind="${workload%%/*}"
  if [ -z "$host_paths" ]; then
    kubectl -n "$ns" delete pod "$name" --wait=false >/dev/null
    return 0
  fi
  if [ "$kind" = "DaemonSet" ]; then
    echo "$ns/$name is a $kind pod writing $host_paths, deleting it without draining the node"
    kubectl -n "$ns" delete pod "$name" --wait=false >/dev/null
    return 0
  fi
  if [ "$kind" != "Deployment" ] && [ "$kind" != "StatefulSet" ]; then
    echo "not recreating $ns/$name: owner $workload holds $host_paths and cannot be scaled" >&2
    return 0
  fi
  kubectl -n "$ns" scale "$workload" --replicas=0 >/dev/null
  kubectl -n "$ns" wait --for=delete "pod/$name" --timeout=300s >/dev/null
  kubectl -n "$ns" scale "$workload" --replicas=1 >/dev/null
}

orphans="$(orphan_pods)"
if [ -z "$orphans" ]; then
  echo "no ambient pods missing an hbone listener on $HBONE_PORT"
  exit 0
fi

echo "ambient pods missing an hbone listener on $HBONE_PORT:"
printf '%s\n' "$orphans"

if [ "$DRY_RUN" = "1" ]; then
  echo "dry run: not restarting istio-cni-node and not recreating pods"
  exit 0
fi

restart_cni_agent
survivors="$(orphan_pods)"
if [ -z "$survivors" ]; then
  echo "istio-cni-node reconcile re-enrolled every orphan"
  exit 0
fi

echo "still orphaned after the istio-cni-node reconcile:"
printf '%s\n' "$survivors"

printf '%s\n' "$survivors" | while read -r ns name ip; do
  echo "recreating $ns/$name ($ip)"
  recreate_pod "$ns" "$name"
done

sleep "$POD_SETTLE_SECONDS"
remaining="$(orphan_pods)"
if [ -n "$remaining" ]; then
  echo "still orphaned after recreation:"
  printf '%s\n' "$remaining"
  exit 1
fi
echo "every ambient pod answers on $HBONE_PORT"
