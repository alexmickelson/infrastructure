#!/usr/bin/env bash
#
# Lists the pods that should be in the ambient mesh and have no ztunnel listener, without changing
# anything. Same scenario as istio-mesh-orphan-repair.sh: pods kubelet started while istio-cni was not
# in the node's CNI chain, which look healthy from every other angle - Ready, Service endpoints, ArgoCD
# Healthy - and are only visible to a meshed peer or an istio gateway as a refused HBONE dial that the
# gateway answers with 503.
#
# Run it on a schedule to notice the state without waiting for a 503, or before the repair script.
# Pods whose namespace network policy refuses the prober are listed as undecided: a refusal there is
# indistinguishable from a missing listener, so they are neither reported as orphans nor repaired.
#
# Exits 0 with no orphans, 1 with orphans listed, 2 when the probe did not return a result per target.
# PROBE_NAMESPACE picks a namespace the caller may create Jobs in; the prober has to run inside the
# cluster, off the mesh, since the pod CIDR is not routable from a peer host. The one Job it creates
# is deleted as soon as it reports.
set -euo pipefail
source "$(dirname "$0")/istio-mesh-orphan-lib.sh"

survey
report_blocked
if [ -z "$SURVEY_ORPHANS" ]; then
  echo "no ambient pods missing an hbone listener on $HBONE_PORT"
  exit 0
fi

echo "ambient pods missing an hbone listener on $HBONE_PORT while the application port answers:"
printf '%s\n' "$SURVEY_ORPHANS"
exit 1
