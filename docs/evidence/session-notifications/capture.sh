#!/bin/bash
set -euo pipefail

# The evidence app must already be built. This script never boots a device.
# Use only the exact task-owned simulator approved by the sole build lease.
device="${1:?exact simulator UDID required}"
derived="${2:?approved DerivedData path required}"
bundle="me.mauriciocardozo.racing.vroomvroom"
app="$derived/Build/Products/Debug-iphonesimulator/VroomVroom.app"
output="docs/evidence/session-notifications"
capture_temp="$(mktemp -d /tmp/landinho-session-notifications-captures.XXXXXX)"
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
trap 'rm -rf "$capture_temp"' EXIT

xcrun simctl bootstatus "$device"
test -d "$app"
xcrun simctl terminate "$device" "$bundle" >/dev/null 2>&1 || true
xcrun simctl uninstall "$device" "$bundle" >/dev/null 2>&1 || true
xcrun simctl install "$device" "$app"
xcrun simctl status_bar "$device" override --time '09:41' --dataNetwork wifi --wifiMode active --wifiBars 3 --batteryState charged --batteryLevel 100
start="$(python3 - <<'PY'
from datetime import datetime, timedelta, timezone
print((datetime.now(timezone.utc) + timedelta(hours=1)).replace(microsecond=0).isoformat().replace('+00:00', 'Z'))
PY
)"

launch_mode() {
  SIMCTL_CHILD_LANDINHO_REMINDER_EVIDENCE="$1" SIMCTL_CHILD_LANDINHO_REMINDER_START="$2" \
    xcrun simctl launch --terminate-running-process "$device" "$bundle" -AppleLanguages '(pt-BR)' -AppleLocale pt_BR
}

capture_image() {
  xcrun simctl io "$device" screenshot "$capture_temp/$1.png"
  sips -s format jpeg -s formatOptions 88 "$capture_temp/$1.png" --out "$output/$1.jpg" >/dev/null
}

for mode in before off on cancel denied; do
  launch_mode "$mode" "$start"
  sleep 5
  if [ "$mode" = before ]; then name=before-detail; else name="after-$mode"; fi
  capture_image "$name"
  container="$(xcrun simctl get_app_container "$device" "$bundle" data)"
  cp "$container/Documents/session-reminder-evidence.json" "$output/injected-$mode.json"
  python3 - "$output/injected-$mode.json" "$mode" <<'PY'
import json, sys
record = json.load(open(sys.argv[1]))
mode = sys.argv[2]
assert record['backend'] == 'injected evidence backend'
assert record['permissionRequests'] == 0
assert len(record['scheduledSessionIDs']) == (1 if mode == 'on' else 0)
assert record['additions'] == (1 if mode == 'on' else 0)
assert record['removals'] == (1 if mode == 'cancel' else 0)
PY
  printf 'Captured %s with verified injected state\n' "$mode"
done

# Reinstall via normal public simulator lifecycle before provisional setup.
# No permission database is edited and no OS button is automated.
xcrun simctl uninstall "$device" "$bundle"
xcrun simctl install "$device" "$app"
native_start="$(python3 - <<'PY'
from datetime import datetime, timedelta, timezone
print((datetime.now(timezone.utc) + timedelta(seconds=45)).replace(microsecond=0).isoformat().replace('+00:00', 'Z'))
PY
)"
launch_mode native-provisional "$native_start"
container="$(xcrun simctl get_app_container "$device" "$bundle" data)"
for attempt in {1..90}; do
  if [ -f "$container/Documents/session-reminder-native-scheduled.json" ] || [ -f "$container/Documents/session-reminder-native-failed.json" ]; then break; fi
  sleep 1
done
if [ ! -f "$container/Documents/session-reminder-native-scheduled.json" ]; then
  cp "$container/Documents/session-reminder-native-phases.json" "$output/native-provisional-waiting-phases.json"
  capture_image native-provisional-awaiting
  printf '%s\n' 'Native scheduling did not complete within the capture deadline; inspect phase diagnostics.' >&2
  exit 1
fi
python3 - "$container/Documents/session-reminder-native-scheduled.json" <<'PY_CHECK'
import json, sys
record = json.load(open(sys.argv[1]))
assert not record['failures'], record
assert record['systemAuthorizationRawValue'] == 3
assert len(record['nativeRequests']) == 1
PY_CHECK
capture_image native-provisional-enabled
for attempt in {1..90}; do
  if [ -f "$container/Documents/session-reminder-native-delivery.json" ]; then break; fi
  sleep 1
done
cp "$container/Documents/session-reminder-native-phases.json" "$output/native-provisional-phases.json"
for phase in scheduled rescheduled cancelled source-cancelled delivery; do
  cp "$container/Documents/session-reminder-native-$phase.json" "$output/native-$phase.json"
  python3 - "$output/native-$phase.json" <<'PY'
import json, sys
record = json.load(open(sys.argv[1]))
assert not record['failures'], record['failures']
assert record['systemAuthorizationRawValue'] == 3, 'Evidence must use actual provisional authorization'
if record['phase'] == 'delivery':
    assert len(record['deliveredNotifications']) == 1
else:
    assert len(record['nativeRequests']) == 1
    assert record['nativeRequests'][0]['nextTriggerEpoch'] == record['expectedStartEpoch']
PY
done
capture_image native-after-delivery
printf '%s\n' 'Verified native pending, reschedule, manual/source cancellation, and provisional delivery'

# Capture the unanswered permission sheet LAST: iOS may keep it above later apps.

xcrun simctl terminate "$device" "$bundle" >/dev/null 2>&1 || true
xcrun simctl uninstall "$device" "$bundle"
xcrun simctl install "$device" "$app"
# Actual shipping permission request, deliberately left unanswered.
launch_mode permission "$start"
container="$(xcrun simctl get_app_container "$device" "$bundle" data)"
for attempt in {1..90}; do
  if [ -f "$container/Documents/session-reminder-native-phases.json" ] && python3 - "$container/Documents/session-reminder-native-phases.json" <<'PY'
import json, sys
record = json.load(open(sys.argv[1]))
sys.exit(0 if any(e['phase'] == 'shippingRequestAuthorization.begin' for e in record['events']) else 1)
PY
  then break; fi
  sleep 1
done
python3 - "$container/Documents/session-reminder-native-phases.json" <<'PY'
import json, sys
record = json.load(open(sys.argv[1]))
assert any(e['phase'] == 'shippingRequestAuthorization.begin' for e in record['events']), record
PY
sleep 2
capture_image native-permission-prompt
cp "$container/Documents/session-reminder-native-phases.json" "$output/native-permission-phases.json"
xcrun simctl terminate "$device" "$bundle" >/dev/null 2>&1 || true

