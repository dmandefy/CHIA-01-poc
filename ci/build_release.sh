#!/usr/bin/env bash
# TRUSTED release build. Restores a "dependency" from a shared on-host cache
# (mirrors cargo registry / pip cache reused across jobs on a persistent runner).
set -x
echo "[release] trusted build on runner=${RUNNER_NAME:-?} host=$(hostname) user=$(id -un)"

echo "[release] === persistence check: markers left by earlier (untrusted) jobs on this non-ephemeral runner ==="
ls -la "$HOME/.poc_backdoor/" 2>/dev/null || echo "(no persistence markers)"

CACHE="$HOME/.poc_cache"
mkdir -p "$CACHE"
if [ ! -f "$CACHE/libdep.sh" ]; then
  echo 'dep_build(){ echo "// clean legitimate dependency"; }' > "$CACHE/libdep.sh"
fi
echo "[release] restoring cached dependency from $CACHE/libdep.sh"
# shellcheck disable=SC1090
source "$CACHE/libdep.sh"

mkdir -p dist
{ echo "#!/bin/sh"; echo "# chia01-poc release binary v1"; dep_build; } > dist/app
echo "[release] built dist/app (sha256 below):"
sha256sum dist/app
echo "[release] ---- dist/app contents ----"; cat dist/app; echo "[release] ---------------------------"

echo "[release] === loot check: did a poisoned cached dep exfiltrate the FAKE release secret? ==="
cat "$HOME/.poc_loot/stolen.txt" 2>/dev/null || echo "(no loot captured)"
