#!/bin/sh
set -eu

nix_version=2.34.9
case $(uname -m) in
x86_64) nix_sha256=e8912e087582b3799e0e5a6b06f9d63386c54821f77ad4de3b9b748736ad364e ;;
aarch64) nix_sha256=f0bb2518db6c9db3f925be3edb76f6e0da17cb72fba329493f510ca08e5111a7 ;;
*)
	echo "entry.sh: no Nix hash for $(uname -m)" >&2
	exit 1
	;;
esac
nix_bin=/nix/var/ci/bin
user=ci
home=/home/$user

prepare_as_root() {
	export DEBIAN_FRONTEND=noninteractive
	apt-get update -qq
	# shellcheck disable=SC2086 # APT_PACKAGES is a list of package names
	apt-get install -qq --no-install-recommends bash ca-certificates curl git xz-utils ${APT_PACKAGES:-} >/dev/null

	mkdir -p /etc/nix
	cat >/etc/nix/nix.conf <<CONF
build-users-group =
experimental-features = nix-command flakes
max-jobs = auto
sandbox = true
sandbox-fallback = false
CONF

	groupadd --non-unique --gid "${HOST_GID:?}" "$user"
	useradd --non-unique --uid "${HOST_UID:?}" --gid "$HOST_GID" --home-dir "$home" --shell /bin/bash "$user"
	chown "$HOST_UID:$HOST_GID" /nix "$home"
}

install_nix() {
	tarball=nix-$nix_version-$(uname -m)-linux
	work=$(mktemp -d)
	curl -fsSL "https://releases.nixos.org/nix/nix-$nix_version/$tarball.tar.xz" -o "$work/nix.tar.xz"
	echo "$nix_sha256  $work/nix.tar.xz" | sha256sum -c --quiet
	tar -xJf "$work/nix.tar.xz" -C "$work"
	"$work/$tarball/install" --no-daemon --no-channel-add --no-modify-profile >/dev/null
	mkdir -p /nix/var/ci
	ln -sfn "$(dirname "$(readlink -f "$HOME/.nix-profile/bin/nix")")" "$nix_bin"
	rm -rf "$work"
}

nearest_flake() {
	dir=$PWD
	while [ "$dir" != / ]; do
		[ -f "$dir/flake.nix" ] && echo "$dir" && return
		dir=$(dirname "$dir")
	done
}

run() {
	flake=$(nearest_flake)
	shell=${DEV_SHELL-default}
	if [ -n "$flake" ] && [ "$shell" = default ]; then
		nix develop "$flake" --command bash -euo pipefail -c "$1"
	elif [ -n "$flake" ] && [ -n "$shell" ]; then
		nix develop "$flake#$shell" --command bash -euo pipefail -c "$1"
	else
		bash -euo pipefail -c "$1"
	fi
}

if [ "$(id -u)" = 0 ]; then
	prepare_as_root
	exec setpriv --reuid="$HOST_UID" --regid="$HOST_GID" --init-groups \
		env HOME="$home" USER="$user" LOGNAME="$user" "$0"
fi

[ -x "$nix_bin/nix" ] || install_nix

tools=$("$nix_bin/nix" build --no-link --print-out-paths path:/ci#default)
PATH=$tools/bin:$nix_bin:$PATH
export PATH
git config --global --add safe.directory '*'

if [ "${RELEASE:-false}" = true ]; then
	check-changelog release "${TAG:?}"
	run "$COMMAND"
	checksums "${RELEASE_DIR:?}"
else
	run "$COMMAND"
fi
