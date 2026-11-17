#!/usr/bin/env bash
set -euo pipefail

image=docker.io/library/debian:12@sha256:268fb24c39bca92d326dd83ea3abebe4a3f7751c804ffef23bb6d857dd343ff8

ci=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
state=${RUNNER_TEMP:?}/ci
mkdir -p "$state/nix" "$state/home"

userns_restriction=/proc/sys/kernel/apparmor_restrict_unprivileged_userns
if [ "${CI:-}" = true ] && [ "$(cat "$userns_restriction" 2>/dev/null || echo 0)" = 1 ]; then
	sudo sysctl -qw kernel.apparmor_restrict_unprivileged_userns=0
fi

pass=(
	--env COMMAND --env APT_PACKAGES --env RELEASE --env RELEASE_DIR --env TAG
	--env CI --env GITHUB_ACTIONS --env GITHUB_REPOSITORY --env GITHUB_SHA --env GITHUB_REF_NAME
)
for name in ${PASS_ENV:-}; do
	pass+=(--env "$name")
done

exec podman run --rm \
	--security-opt seccomp=unconfined --security-opt systempaths=unconfined \
	--volume "$GITHUB_WORKSPACE:$GITHUB_WORKSPACE" --workdir "$GITHUB_WORKSPACE/${WORKING_DIRECTORY:-.}" \
	--volume "$state/nix:/nix" --volume "$state/home:/root" --volume "$ci:/ci:ro" \
	"${pass[@]}" "$image" /ci/entry.sh
