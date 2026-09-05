#!/usr/bin/env bash
# TRUSTED baseline on main. On a fork PR this file is fully attacker-controlled
# (mirrors Chia's repo-tracked build.rs / install.sh / pytest harness).
set -x
echo "[main] legit benchmark on runner=${RUNNER_NAME:-?} host=$(hostname) user=$(id -un)"
echo "bench result: 42 ops/sec"
