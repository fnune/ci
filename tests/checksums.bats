setup() {
	load helpers
	mkdir "$BATS_TEST_TMPDIR/dist"
	echo app >"$BATS_TEST_TMPDIR/dist/app"
	echo notes >"$BATS_TEST_TMPDIR/dist/app.sig"
}

@test "the sums verify the files" {
	run checksums "$BATS_TEST_TMPDIR/dist"
	assert_success
	cd "$BATS_TEST_TMPDIR/dist" || return 1
	run sha256sum -c SHA256SUMS
	assert_success
}

@test "the sums use file names, not paths" {
	checksums "$BATS_TEST_TMPDIR/dist" >/dev/null
	run cat "$BATS_TEST_TMPDIR/dist/SHA256SUMS"
	assert_line --regexp '  app$'
	refute_output --partial /
}

@test "a second run does not list the sums file itself" {
	checksums "$BATS_TEST_TMPDIR/dist" >/dev/null
	checksums "$BATS_TEST_TMPDIR/dist" >/dev/null
	run cat "$BATS_TEST_TMPDIR/dist/SHA256SUMS"
	refute_output --partial SHA256SUMS
	assert_equal "${#lines[@]}" 2
}
