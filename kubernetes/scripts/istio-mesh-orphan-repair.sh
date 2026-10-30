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
# Listing without repairing is istio-mesh-orphan-report.sh. PROBE_NAMESPACE picks a namespace the
# caller may create Jobs in; the prober has to run inside the cluster, off the mesh, since the pod
# CIDR is not routable from a peer host.
set -euo pipefail
source "$(dirname "$0")/istio-mesh-orphan-lib.sh"

CNI_SETTLE_SECONDS="${CNI_SETTLE_SECONDS:-45}"
POD_SETTLE_SECONDS="${POD_SETTLE_SECONDS:-20}"

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

survey
report_blocked
if [ -z "$SURVEY_ORPHANS" ]; then
  echo "no ambient pods missing an hbone listener on $HBONE_PORT"
  exit 0
fi

echo "ambient pods missing an hbone listener on $HBONE_PORT while the application port answers:"
printf '%s\n' "$SURVEY_ORPHANS"

restart_cni_agent
survey
if [ -z "$SURVEY_ORPHANS" ]; then
  echo "istio-cni-node reconcile re-enrolled every orphan"
  exit 0
fi

echo "still orphaned after the istio-cni-node reconcile:"
printf '%s\n' "$SURVEY_ORPHANS"

printf '%s\n' "$SURVEY_ORPHANS" | while read -r ns name ip; do
  echo "recreating $ns/$name ($ip)"
  recreate_pod "$ns" "$name"
done

sleep "$POD_SETTLE_SECONDS"
survey
report_blocked
if [ -n "$SURVEY_ORPHANS" ]; then
  echo "still orphaned after recreation:"
  printf '%s\n' "$SURVEY_ORPHANS"
  exit 1
fi
echo "every ambient pod answers on $HBONE_PORT"
