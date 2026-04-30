#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="${WORKSPACE:-ColombaCustomer.xcworkspace}"
SCHEME="${SCHEME:-ColombaCustomer}"
BUNDLE_ID="${BUNDLE_ID:-ch.colomba.customer}"
DEVICE_NAME="${DEVICE_NAME:-Colomba Phase1 iPhone 12}"
DEVICE_TYPE="${DEVICE_TYPE:-com.apple.CoreSimulator.SimDeviceType.iPhone-12}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-.derived/phase01-cold-start}"
LOG_PATH="${LOG_PATH:-tmp/cold-start.log}"
THRESHOLD_MS="${THRESHOLD_MS:-1500}"

if ! xcodebuild -version >/dev/null 2>&1; then
  echo "PAPU_NEEDED_XCODE: xcodebuild requires a full Xcode install, not only Command Line Tools." >&2
  exit 2
fi

mkdir -p "$(dirname "$LOG_PATH")" "$DERIVED_DATA_PATH"

runtime_id="$({
  xcrun simctl list runtimes -j
} | IOS_RUNTIME_MAJOR="${IOS_RUNTIME_MAJOR:-}" python3 -c 'import json, os, re, sys
r=json.load(sys.stdin)["runtimes"]
major=os.environ.get("IOS_RUNTIME_MAJOR", "")
ios=[x for x in r if x.get("platform") == "iOS" and x.get("isAvailable")]
if major:
    ios=[x for x in ios if str(x.get("version", "")).split(".", 1)[0] == major]
if not ios:
    raise SystemExit("no matching available iOS simulator runtime")
def version_key(runtime):
    return tuple(int(part) for part in re.findall(r"\d+", str(runtime.get("version", ""))))
ios.sort(key=version_key, reverse=True)
print(ios[0]["identifier"])')"

udid="$(xcrun simctl list devices -j | DEVICE_NAME="$DEVICE_NAME" python3 -c 'import json,sys,os
name=os.environ["DEVICE_NAME"]
d=json.load(sys.stdin)["devices"]
for devices in d.values():
    for device in devices:
        if device.get("name") == name and device.get("isAvailable"):
            print(device["udid"])
            raise SystemExit(0)
' 2>/dev/null || true)"

if [ -z "$udid" ]; then
  udid="$(xcrun simctl create "$DEVICE_NAME" "$DEVICE_TYPE" "$runtime_id")"
fi

xcrun simctl boot "$udid" >/dev/null 2>&1 || true
xcrun simctl bootstatus "$udid" -b

xcodebuild \
  -workspace "$WORKSPACE" \
  -scheme "$SCHEME" \
  -configuration Debug \
  -destination "id=$udid" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  build

app_path="$DERIVED_DATA_PATH/Build/Products/Debug-iphonesimulator/$SCHEME.app"
if [ ! -d "$app_path" ]; then
  app_path="$(find "$DERIVED_DATA_PATH/Build/Products" -name "$SCHEME.app" -type d | head -1)"
fi
if [ -z "$app_path" ] || [ ! -d "$app_path" ]; then
  echo "Could not locate built app under $DERIVED_DATA_PATH" >&2
  exit 1
fi

xcrun simctl terminate "$udid" "$BUNDLE_ID" >/dev/null 2>&1 || true
xcrun simctl uninstall "$udid" "$BUNDLE_ID" >/dev/null 2>&1 || true
xcrun simctl install "$udid" "$app_path"
: > "$LOG_PATH"

xcrun simctl spawn "$udid" log stream \
  --style compact \
  --predicate 'subsystem == "ch.colomba.customer" AND category == "performance.cold-start"' \
  > "$LOG_PATH" 2>&1 &
log_pid=$!
trap 'kill "$log_pid" >/dev/null 2>&1 || true' EXIT

xcrun simctl launch "$udid" "$BUNDLE_ID" >/dev/null

for _ in $(seq 1 150); do
  if grep -Eo 'COLOMBA_COLD_START_MS=[0-9]+' "$LOG_PATH" >/dev/null 2>&1; then
    break
  fi
  sleep 0.1
done

kill "$log_pid" >/dev/null 2>&1 || true
trap - EXIT

measurement="$(grep -Eo 'COLOMBA_COLD_START_MS=[0-9]+' "$LOG_PATH" | tail -1 | cut -d= -f2)"
if [ -z "$measurement" ]; then
  echo "No COLOMBA_COLD_START_MS measurement found. Log tail:" >&2
  tail -80 "$LOG_PATH" >&2 || true
  exit 1
fi

printf 'COLOMBA_COLD_START_MS=%s\n' "$measurement"
python3 - "$measurement" "$THRESHOLD_MS" <<'PY'
import sys
measurement = int(sys.argv[1])
threshold = int(sys.argv[2])
if measurement >= threshold:
    raise SystemExit(f"cold-start gate failed: {measurement}ms >= {threshold}ms")
print(f"cold-start gate passed: {measurement}ms < {threshold}ms")
PY
