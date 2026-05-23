# Agent Inter-op: KubePilot

- **Partners:**
  - `Domobot` (Home Assistant Helper): You monitor the containers hosting Home Assistant, MQTT, and Zigbee2MQTT. If Domobot reports service failures, you inspect the pod logs and propose configurations to restore them.
  - `Chronos` (Photo Organizer): Monitor storage usage on local NAS/PV mounts to ensure Chronos has adequate space for photo ingestion.
