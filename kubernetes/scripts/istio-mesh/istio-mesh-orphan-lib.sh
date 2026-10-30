#!/usr/bin/env bash
#
# The ambient-mesh orphan probe, shared by istio-mesh-orphan-report.sh and istio-mesh-orphan-repair.sh.
# A pod counts as an orphan when a connection to its <pod-ip>:15008, ztunnel's HBONE listener, is
# refused while a port the pod declares still answers. When every port is refused the pod is undecided
# and left alone: an ingress NetworkPolicy that does not admit the prober is indistinguishable from a
# missing listener, and acting on it recreates the pod on every run without ever converging.

HBONE_PORT=15008
PROBE_IMAGE="docker.io/library/busybox:1.38.0"
EXCLUDED_NAMESPACES=" kube-system istio-system "
PROBE_NAMESPACE="${PROBE_NAMESPACE:-hermes}"
PROBE_SETTLE_SECONDS="${PROBE_SETTLE_SECONDS:-120}"
RUN_ID="$(date +%s)"
PROBE_SEQ=0
SURVEY_ORPHANS=""
SURVEY_BLOCKED=""

for command in kubectl awk; do
  command -v "$command" >/dev/null || { echo "missing required command: $command" >&2; exit 127; }
done

ambient_namespaces() {
  kubectl get ns -l istio.io/dataplane-mode=ambient -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'
}

ambient_candidate_pods() {
  local ambient
  ambient=" $(ambient_namespaces | tr '\n' ' ') "
  kubectl get pods -A -o jsonpath='{range .items[*]}{.metadata.namespace}{"|"}{.metadata.name}{"|"}{.status.podIP}{"|"}{.spec.hostNetwork}{"|"}{.status.phase}{"|"}{.metadata.deletionTimestamp}{"|"}{.metadata.labels.istio\.io/dataplane-mode}{"|"}{range .status.conditions[?(@.type=="Ready")]}{.status}{end}{"|"}{range .spec.containers[*]}{range .ports[*]}{.containerPort}{" "}{end}{end}{"\n"}{end}' |
    awk -F'|' -v ambient="$ambient" -v excluded="$EXCLUDED_NAMESPACES" '
      index(ambient, " " $1 " ") == 0 || index(excluded, " " $1 " ") != 0 { next }
      $4 == "true" || $5 != "Running" || $6 != "" || $7 == "none" || $3 == "" || $8 != "True" { next }
      { sub(/ +$/, "", $9); gsub(/ /, ",", $9); print $1, $2, $3, $9 }'
}

probe_hbone() {
  local job result expected actual targets
  PROBE_SEQ=$((PROBE_SEQ + 1))
  job="istio-mesh-probe-${RUN_ID}-${PROBE_SEQ}"
  targets="$(printf '%s\n' "$@" | awk 'NF' | tr '\n' ' ')"
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
            - name: PROBE_TARGETS
              value: "$targets"
          command: ["/bin/sh", "-c", "for t in \$PROBE_TARGETS; do ip=\$(echo \$t | cut -d: -f1); ports=\$(echo \$t | cut -d: -f2); if nc -w 1 \"\$ip\" \"\$HBONE_PORT\" </dev/null >/dev/null 2>&1; then echo reachable \"\$ip\"; continue; fi; app=; for p in \$(echo \$ports | tr ',' ' '); do nc -w 1 \"\$ip\" \"\$p\" </dev/null >/dev/null 2>&1 && app=yes; done; if [ -n \"\$app\" ]; then echo orphan \"\$ip\"; else echo blocked \"\$ip\"; fi; done"]
EOF
  kubectl -n "$PROBE_NAMESPACE" wait --for=condition=complete "job/$job" --timeout="${PROBE_SETTLE_SECONDS}s" >/dev/null
  result="$(kubectl -n "$PROBE_NAMESPACE" logs "job/$job")"
  kubectl -n "$PROBE_NAMESPACE" delete job "$job" --wait=false >/dev/null
  expected="$(printf '%s\n' $targets | awk 'NF' | wc -l)"
  actual="$(printf '%s\n' "$result" | awk 'NF' | wc -l)"
  if [ "$expected" != "$actual" ]; then
    echo "probe returned $actual of $expected results" >&2
    exit 2
  fi
  printf '%s\n' "$result"
}

pods_in_state() {
  local results="$1" state="$2" candidates="$3"
  printf '%s\n' "$results" | awk -v state="$state" '$1 == state { print $2 }' |
    while read -r ip; do
      printf '%s\n' "$candidates" | awk -v ip="$ip" '$3 == ip { print $1, $2, $3 }'
    done
}

survey() {
  local candidates results
  candidates="$(ambient_candidate_pods)"
  SURVEY_ORPHANS=""
  SURVEY_BLOCKED=""
  [ -n "$candidates" ] || return 0
  results="$(probe_hbone $(printf '%s\n' "$candidates" | awk '{print $3 ":" $4}'))"
  SURVEY_ORPHANS="$(pods_in_state "$results" orphan "$candidates")"
  SURVEY_BLOCKED="$(pods_in_state "$results" blocked "$candidates")"
}

report_blocked() {
  [ -n "$SURVEY_BLOCKED" ] || return 0
  echo "undecided, no port on the pod answers the prober, an ingress NetworkPolicy is the likely cause:"
  printf '%s\n' "$SURVEY_BLOCKED"
}
