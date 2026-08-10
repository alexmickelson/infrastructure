#!/usr/bin/env bash
# Report namespace-level Istio adoption and health signals.  Read-only.
# Requires: kubectl, jq
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: istio-namespace-report.sh [--namespace NAME] [--all-namespaces]

Audits Istio implementation by namespace.  The default excludes Kubernetes and
Istio system namespaces; --all-namespaces includes them.  It is safe to run
against a production cluster: it only issues kubectl get commands.
EOF
}

namespace=""
include_system=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--namespace) namespace="${2:?missing namespace name}"; shift 2 ;;
    -A|--all-namespaces) include_system=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

for command in kubectl jq; do
  command -v "$command" >/dev/null || { echo "Missing required command: $command" >&2; exit 127; }
done

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

fetch() {
  local resource="$1" output="$2" required="${3:-false}"
  if ! kubectl get "$resource" -A -o json >"$output" 2>"$output.err"; then
    if [[ "$required" == "true" ]]; then
      echo "Cannot query $resource; check the selected kubectl context and access:" >&2
      tail -n 1 "$output.err" >&2
      exit 1
    fi
    # Optional APIs may not be installed or permitted.  Treat them as absent and
    # make the resulting gap explicit without dumping kubectl discovery noise.
    printf '{"items":[]}' >"$output"
    printf '%s' "$resource" >"$output.warning"
  fi
}

fetch namespaces "$tmpdir/namespaces.json" true
fetch pods "$tmpdir/pods.json"
fetch deployments "$tmpdir/deployments.json"
fetch statefulsets "$tmpdir/statefulsets.json"
fetch daemonsets "$tmpdir/daemonsets.json"
fetch services "$tmpdir/services.json"
fetch endpointslices.discovery.k8s.io "$tmpdir/endpointslices.json"
fetch networkpolicies.networking.k8s.io "$tmpdir/networkpolicies.json"
fetch authorizationpolicies.security.istio.io "$tmpdir/authz.json"
fetch peerauthentications.security.istio.io "$tmpdir/peerauth.json"
fetch requestauthentications.security.istio.io "$tmpdir/requestauth.json"
fetch destinationrules.networking.istio.io "$tmpdir/destinationrules.json"
fetch virtualservices.networking.istio.io "$tmpdir/virtualservices.json"
fetch gateways.gateway.networking.k8s.io "$tmpdir/gateways.json"
fetch httproutes.gateway.networking.k8s.io "$tmpdir/httproutes.json"

context="$(kubectl config current-context 2>/dev/null || echo unknown)"
echo "Istio namespace implementation report"
echo "Context: $context    Generated: $(date -Iseconds)"
echo ""

# Return workload desired/ready replicas without requiring metrics-server.
workload_counts() {
  local ns="$1"
  jq -s --arg ns "$ns" '
    [.[0].items[]?, .[1].items[]?, .[2].items[]? | select(.metadata.namespace == $ns)] as $w |
    {objects: ($w|length), desired: ($w|map(.spec.replicas // 1)|add // 0),
     ready: ($w|map(.status.readyReplicas // .status.numberReady // 0)|add // 0)}
  ' "$tmpdir/deployments.json" "$tmpdir/statefulsets.json" "$tmpdir/daemonsets.json"
}

print_namespace() {
  local ns="$1" nsdata mode pods running ready sidecars ambient_disabled workload services endpoints
  nsdata="$(jq -c --arg ns "$ns" '.items[] | select(.metadata.name == $ns)' "$tmpdir/namespaces.json")"
  mode="$(jq -r '.metadata.labels["istio.io/dataplane-mode"] // empty' <<<"$nsdata")"
  [[ "$mode" == "ambient" ]] || mode="$(jq -r '.metadata.labels["istio-injection"] // empty' <<<"$nsdata")"
  [[ -n "$mode" ]] || mode="not enrolled"

  pods="$(jq --arg ns "$ns" '[.items[] | select(.metadata.namespace == $ns) | select(.status.phase != "Succeeded" and .status.phase != "Failed")] | length' "$tmpdir/pods.json")"
  running="$(jq --arg ns "$ns" '[.items[] | select(.metadata.namespace == $ns and .status.phase == "Running")] | length' "$tmpdir/pods.json")"
  ready="$(jq --arg ns "$ns" '[.items[] | select(.metadata.namespace == $ns and .status.phase == "Running") | select((.status.containerStatuses // []) | length > 0 and all(.[]; .ready == true))] | length' "$tmpdir/pods.json")"
  sidecars="$(jq --arg ns "$ns" '[.items[] | select(.metadata.namespace == $ns) | select(any(.spec.containers[]?; .name == "istio-proxy"))] | length' "$tmpdir/pods.json")"
  ambient_disabled="$(jq --arg ns "$ns" '[.items[] | select(.metadata.namespace == $ns) | select(.metadata.annotations["ambient.istio.io/redirection"] == "disabled")] | length' "$tmpdir/pods.json")"
  workload="$(workload_counts "$ns")"
  services="$(jq --arg ns "$ns" '[.items[] | select(.metadata.namespace == $ns and .spec.type != "ExternalName")] | length' "$tmpdir/services.json")"
  endpoints="$(jq --arg ns "$ns" '[.items[] | select(.metadata.namespace == $ns) | .endpoints[]? | select(.conditions.ready == true)] | length' "$tmpdir/endpointslices.json")"

  local authz peer strict permissive jwt dr vs gw routes np mtls_status authz_status netpol_status notes
  authz="$(jq --arg ns "$ns" '[.items[] | select(.metadata.namespace == $ns)] | length' "$tmpdir/authz.json")"
  peer="$(jq --arg ns "$ns" '[.items[] | select(.metadata.namespace == $ns)] | length' "$tmpdir/peerauth.json")"
  strict="$(jq --arg ns "$ns" '[.items[] | select(.metadata.namespace == $ns and (.spec.mtls.mode // "") == "STRICT")] | length' "$tmpdir/peerauth.json")"
  permissive="$(jq --arg ns "$ns" '[.items[] | select(.metadata.namespace == $ns and (.spec.mtls.mode // "") == "PERMISSIVE")] | length' "$tmpdir/peerauth.json")"
  jwt="$(jq --arg ns "$ns" '[.items[] | select(.metadata.namespace == $ns)] | length' "$tmpdir/requestauth.json")"
  dr="$(jq --arg ns "$ns" '[.items[] | select(.metadata.namespace == $ns)] | length' "$tmpdir/destinationrules.json")"
  vs="$(jq --arg ns "$ns" '[.items[] | select(.metadata.namespace == $ns)] | length' "$tmpdir/virtualservices.json")"
  gw="$(jq --arg ns "$ns" '[.items[] | select(.metadata.namespace == $ns)] | length' "$tmpdir/gateways.json")"
  routes="$(jq --arg ns "$ns" '[.items[] | select(.metadata.namespace == $ns)] | length' "$tmpdir/httproutes.json")"
  np="$(jq --arg ns "$ns" '[.items[] | select(.metadata.namespace == $ns)] | length' "$tmpdir/networkpolicies.json")"

  if (( peer == 0 )); then
    mtls_status="NOT CONFIGURED (verify mesh-wide policy)"
  elif (( strict > 0 )); then
    mtls_status="STRICT ($strict policy/policies)"
  elif (( permissive > 0 )); then
    mtls_status="PERMISSIVE ($permissive policy/policies)"
  else
    mtls_status="CUSTOM / WORKLOAD-SCOPED ($peer policy/policies)"
  fi

  if (( authz == 0 )); then
    authz_status="NOT CONFIGURED (verify mesh-wide/default-deny policy)"
  else
    authz_status="$authz policy/policies configured"
  fi

  if (( np == 0 )); then
    netpol_status="NOT CONFIGURED"
  else
    netpol_status="$np policy/policies configured"
  fi

  notes=()
  [[ "$mode" == "not enrolled" && "$pods" -gt 0 ]] && notes+=("workloads are outside the mesh")
  [[ "$mode" == "ambient" && "$ambient_disabled" -gt 0 ]] && notes+=("$ambient_disabled pod(s) explicitly bypass ambient redirection")
  [[ "$mode" != "ambient" && "$mode" != "not enrolled" && "$pods" -gt "$sidecars" ]] && notes+=("$((pods-sidecars)) pod(s) lack an istio-proxy (injection may be incomplete)")
  (( running > ready )) && notes+=("$((running-ready)) running pod(s) are not Ready")
  (( services > 0 && endpoints == 0 )) && notes+=("services have no ready EndpointSlice endpoints")
  (( strict == 0 && peer > 0 )) && notes+=("PeerAuthentication exists but none is namespace STRICT")
  (( peer == 0 )) && notes+=("no namespace PeerAuthentication (check mesh-wide mTLS policy)")
  (( authz == 0 )) && notes+=("no AuthorizationPolicy (check mesh-wide/default-deny policy)")

  printf 'Namespace: %s\n' "$ns"
  echo '  Mesh adoption'
  printf '    Mode:                 %s\n' "$mode"
  printf '    Active pods:          %s (sidecars: %s; ambient opt-outs: %s)\n' "$pods" "$sidecars" "$ambient_disabled"
  printf '    Traffic resources:    DestinationRules=%s, VirtualServices=%s, Gateways=%s, HTTPRoutes=%s\n' "$dr" "$vs" "$gw" "$routes"
  echo '  Operational health'
  printf '    Running pods:         %s/%s Ready\n' "$ready" "$running"
  printf '    Workload replicas:    %s/%s Ready (%s workload objects)\n' "$(jq -r '.ready' <<<"$workload")" "$(jq -r '.desired' <<<"$workload")" "$(jq -r '.objects' <<<"$workload")"
  printf '    Service endpoints:    %s ready endpoints across %s service(s)\n' "$endpoints" "$services"
  echo '  Security policy'
  printf '    mTLS:                 %s\n' "$mtls_status"
  printf '    AuthorizationPolicy:  %s\n' "$authz_status"
  printf '    RequestAuthentication:%s\n' " $jwt policy/policies configured"
  printf '    NetworkPolicy:        %s\n' "$netpol_status"

  if (( authz > 0 )); then
    echo '    AuthorizationPolicy details:'
    jq -r --arg ns "$ns" '
      .items[] | select(.metadata.namespace == $ns) |
      (.spec.selector // {}) as $selector |
      (if (($selector.matchLabels // {}) | length) == 0 and (($selector.matchExpressions // []) | length) == 0 then "all workloads" else "selected workloads" end) as $scope |
      (.spec.action // "ALLOW") as $action |
      (.spec.rules // []) as $rules |
      "      - \(.metadata.name): \($action); \($scope); \($rules | length) rule(s)"
    ' "$tmpdir/authz.json"
  fi
  if (( np > 0 )); then
    echo '    NetworkPolicy details:'
    jq -r --arg ns "$ns" '
      .items[] | select(.metadata.namespace == $ns) |
      (.spec.podSelector // {}) as $selector |
      (if (($selector.matchLabels // {}) | length) == 0 and (($selector.matchExpressions // []) | length) == 0 then "all pods" else "selected pods" end) as $scope |
      (.spec.policyTypes // []) as $declaredTypes |
      (if ($declaredTypes | length) > 0 then $declaredTypes else [if .spec | has("ingress") then "Ingress" else empty end, if .spec | has("egress") then "Egress" else empty end] end) as $types |
      ([if (($types | index("Ingress")) != null and (.spec.ingress? == [])) then "default-deny ingress" else empty end,
        if (($types | index("Egress")) != null and (.spec.egress? == [])) then "default-deny egress" else empty end] | join(", ")) as $defaultDeny |
      "      - \(.metadata.name): \($scope); \($types | join("+")); \(if $defaultDeny == "" then "rules configured" else $defaultDeny end)"
    ' "$tmpdir/networkpolicies.json"
  fi
  if ((${#notes[@]})); then
    echo '  Findings'
    for note in "${notes[@]}"; do printf '    - %s\n' "$note"; done
  fi
  echo
}

control_ready="$(jq '[.items[] | select(.metadata.namespace == "istio-system" and (.metadata.labels.app == "istiod" or .metadata.name == "istiod")) | .status.readyReplicas // 0] | add // 0' "$tmpdir/deployments.json")"
ztunnel="$(jq '[.items[] | select(.metadata.namespace == "istio-system" and (.metadata.labels.app == "ztunnel" or .metadata.name == "ztunnel")) | {desired: (.status.desiredNumberScheduled // 0), ready: (.status.numberReady // 0)}] | .[0] // {desired:0,ready:0}' "$tmpdir/daemonsets.json")"
echo "Mesh prerequisites: istiod ready replicas=$control_ready; ztunnel ready=$(jq -r '.ready' <<<"$ztunnel")/$(jq -r '.desired' <<<"$ztunnel")"
echo "Reports mesh adoption and operational health separately. Namespace policy status does not account for mesh-wide policies."
echo

while IFS= read -r ns; do
  [[ -n "$namespace" && "$ns" != "$namespace" ]] && continue
  if ! $include_system && [[ "$ns" =~ ^(kube-|istio-system$|istio-ingress$) ]]; then continue; fi
  print_namespace "$ns"
done < <(jq -r '.items[] | select(.status.phase == "Active") | .metadata.name' "$tmpdir/namespaces.json" | sort)

for warning in "$tmpdir"/*.warning; do
  [[ -e "$warning" ]] || continue
  [[ -s "$warning" ]] && echo "Warning: unable to query optional resource $(<"$warning"); its checks are omitted." >&2
done
