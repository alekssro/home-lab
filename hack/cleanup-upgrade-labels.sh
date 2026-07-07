#!/usr/bin/env bash
#
# cleanup-upgrade-labels.sh
#
# Removes stale plan.upgrade.cattle.io/* labels from all nodes.
# Run this BEFORE pushing new upgrade plan channel changes to avoid
# the "jobs.batch not found, requeuing" error loop in the
# system-upgrade-controller.
#
# The root cause: when an upgrade completes, the controller's
# ttlSecondsAfterFinished (900s) deletes the finished jobs, but the
# node labels referencing those jobs are never cleaned up. On the
# next plan update, the controller sees these stale labels, tries
# to look up the deleted jobs, and enters a "not found" retry loop.
#
# Usage:
#   ./hack/cleanup-upgrade-labels.sh
#   # Then commit/push your plan changes and reconcile Flux.

set -euo pipefail

echo "==> Checking for stale plan.upgrade.cattle.io labels on nodes..."

NODES=$(kubectl get nodes -o jsonpath='{.items[*].metadata.name}')

found=0
for node in $NODES; do
  labels=$(kubectl get node "$node" -o json | jq -r '[.metadata.labels | to_entries[] | select(.key | startswith("plan.upgrade.cattle.io"))] | map(.key) | .[]')
  if [ -n "$labels" ]; then
    for label in $labels; do
      echo "    Removing label '$label' from node '$node'"
      kubectl label node "$node" "${label}-"
      found=1
    done
  fi
done

if [ "$found" -eq 0 ]; then
  echo "==> No stale upgrade labels found. Nothing to clean up."
else
  echo ""
  echo "==> Labels removed. Restarting system-upgrade-controller to clear work queue..."
  kubectl rollout restart deployment/system-upgrade-controller -n system-upgrade
  kubectl rollout status deployment/system-upgrade-controller -n system-upgrade --timeout=60s
  echo "==> Done. You can now safely push your new plan channel changes."
fi
