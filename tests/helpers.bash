bats_load_library bats-support
bats_load_library bats-assert

make_repo() {
	cd "$BATS_TEST_TMPDIR" || return 1
	git init -q -b main repo
	cd repo || return 1
	git config user.email ci@example.org
	git config user.name ci
	changie init >/dev/null
	git add -A
	git commit -qm init
}

add_fragment() {
	changie new --kind "$1" --body "$2" >/dev/null
	git add -A
	git commit -qm "$2"
}

release() {
	changie batch "$1" >/dev/null
	changie merge >/dev/null
	git add -A
	git commit -qm "$1"
}
