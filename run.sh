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

kvm=()
if [ "${KVM:-false}" = true ]; then
	if [ "${CI:-}" = true ]; then
		echo 'KERNEL=="kvm", GROUP="kvm", MODE="0666", OPTIONS+="static_node=kvm"' | sudo tee /etc/udev/rules.d/99-ci-kvm.rules >/dev/null
		sudo udevadm control --reload-rules
		sudo udevadm trigger --name-match=kvm
	fi
	kvm=(--device /dev/kvm)
fi

pass=(
	--env HOST_UID="$(id -u)" --env HOST_GID="$(id -g)"
	--env COMMAND --env DEV_SHELL --env APT_PACKAGES --env KVM --env RELEASE --env RELEASE_DIR --env TAG
	--env CI --env GITHUB_ACTIONS --env GITHUB_REPOSITORY --env GITHUB_SHA --env GITHUB_REF_NAME
)
for name in ${PASS_ENV:-}; do
	pass+=(--env "$name")
done

exec podman run --rm --userns=keep-id --user 0:0 \
	--cap-add SYS_ADMIN --security-opt seccomp=unconfined --security-opt systempaths=unconfined \
	--volume "$GITHUB_WORKSPACE:$GITHUB_WORKSPACE" --workdir "$GITHUB_WORKSPACE/${WORKING_DIRECTORY:-.}" \
	--volume "$state/nix:/nix" --volume "$state/home:/home/ci" --volume "$ci:/ci:ro" \
	"${kvm[@]}" "${pass[@]}" "$image" /ci/entry.sh
