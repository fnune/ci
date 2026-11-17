setup() {
	load helpers
	make_repo
	add_fragment Added "Pair devices with a short code"
	release v1.0.0
	mkdir dist
	echo app >dist/app
	echo sums >dist/SHA256SUMS

	mkdir "$BATS_TEST_TMPDIR/bin"
	echo "#!$(command -v bash)" >"$BATS_TEST_TMPDIR/bin/gh"
	cat >>"$BATS_TEST_TMPDIR/bin/gh" <<'GH'
printf '%s\n' "$@" >"$BATS_TEST_TMPDIR/gh-args"
while [ $# -gt 0 ]; do
	[ "$1" = --notes-file ] && cp "$2" "$BATS_TEST_TMPDIR/gh-notes"
	shift
done
GH
	chmod +x "$BATS_TEST_TMPDIR/bin/gh"
	export GH_COMMAND=$BATS_TEST_TMPDIR/bin/gh GITHUB_REPOSITORY=fnune/example GH_TOKEN=token
}

@test "the release is created for the tag, on the repository, with every file" {
	run publish-github v1.0.0 dist
	assert_success
	run cat "$BATS_TEST_TMPDIR/gh-args"
	assert_line --index 0 release
	assert_line --index 1 create
	assert_line --index 2 v1.0.0
	assert_line fnune/example
	assert_line --verify-tag
	assert_line dist/app
	assert_line dist/SHA256SUMS
}

@test "the release notes come from the changelog" {
	publish-github v1.0.0 dist
	run cat "$BATS_TEST_TMPDIR/gh-notes"
	assert_output --partial "Pair devices with a short code"
}

@test "publishing without a token fails before calling gh" {
	unset GH_TOKEN
	run publish-github v1.0.0 dist
	assert_failure
	assert_output --partial GH_TOKEN
	assert [ ! -e "$BATS_TEST_TMPDIR/gh-args" ]
}
