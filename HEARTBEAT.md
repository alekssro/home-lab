# Heartbeat & Scheduled Tasks

- **Schedule:** Every 4 hours.
- **Routine:**
  1. Scan all namespace pod states (`kubectl get pods -A`). Identify any pods in `CrashLoopBackOff` or with high restart counts.
  2. Check PVC usage and host disk capacity to prevent storage exhaustion.
  3. Send a brief status summary of any anomalies to the user's Slack alert channel.
