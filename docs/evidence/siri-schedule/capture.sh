#!/bin/bash
set -euo pipefail
simulator_id="${1:?Usage: capture.sh EXACT_UDID EVIDENCE_APP_PATH scenario [light|dark]}"
app_path="${2:?Evidence .app path is required}"
scenario="${3:?Scenario: before-settings|after-settings|race|session|category|pending|cancelled|empty|offline|mock|mock-session}"
appearance="${4:-light}"
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
repo_dir="$(git rev-parse --show-toplevel)"
evidence_dir="$repo_dir/docs/evidence/siri-schedule"
bundle_id="$(plutil -extract CFBundleIdentifier raw -o - "$app_path/Info.plist")"
api_url="http://127.0.0.1:18088"
mode="$scenario"
case "$scenario" in
  before-settings|after-settings) mode=settings ;;
  race|session|category) ;;
  mock|mock-session) api_url="http://127.0.0.1:1" ;;
  pending|cancelled|empty|offline) api_url="$api_url/$scenario"; mode=race ;;
  *) echo "Unknown scenario: $scenario" >&2; exit 2 ;;
esac

# Requires the sole build/simulator lease and an already booted task-owned device.
# This script never boots a simulator, changes agent access, or fabricates UI taps.
xcrun simctl install "$simulator_id" "$app_path"
xcrun simctl ui "$simulator_id" appearance "$appearance"
container="$(xcrun simctl get_app_container "$simulator_id" "$bundle_id" data)"
rm -f "$container/Documents/SiriEvidence.json"
SIMCTL_CHILD_LANDINHO_SIRI_EVIDENCE="$mode" SIMCTL_CHILD_LANDINHO_API_URL="$api_url" \
  xcrun simctl launch --terminate-running-process \
  --stdout="/tmp/landinho-siri-$scenario.stdout" --stderr="/tmp/landinho-siri-$scenario.stderr" \
  "$simulator_id" "$bundle_id" -AppleLocale pt_BR -AppleLanguages '(pt-BR)'

if [[ "$mode" != settings ]]; then
  for attempt in {1..50}; do
    [[ -f "$container/Documents/SiriEvidence.json" ]] && break
    sleep 0.4
  done
  [[ -f "$container/Documents/SiriEvidence.json" ]] || { echo "AppIntent did not finish" >&2; exit 1; }
  cp "$container/Documents/SiriEvidence.json" "$evidence_dir/$scenario-result.json"
  python3 "$evidence_dir/verify-result.py" "$scenario" "$evidence_dir/$scenario-result.json"
fi
sleep 2
xcrun simctl io "$simulator_id" screenshot "$evidence_dir/harness-$scenario-$appearance.png"
sips -s format jpeg -s formatOptions 85 "$evidence_dir/harness-$scenario-$appearance.png" \
  --out "$evidence_dir/harness-$scenario-$appearance.jpg" >/dev/null
rm "$evidence_dir/harness-$scenario-$appearance.png"
