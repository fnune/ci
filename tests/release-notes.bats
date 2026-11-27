setup() {
	load helpers
	make_repo
	add_fragment Added "Pair devices with a short code"
	release v1.0.0
}

@test "the notes hold the version's changes" {
	run release-notes v1.0.0
	assert_success
	assert_output --partial "Pair devices with a short code"
}

@test "the notes leave out the version header that the release title already shows" {
	run release-notes v1.0.0
	refute_line --regexp '^## v1\.0\.0'
	refute_line --index 0 ''
}

@test "a tag without a version file fails" {
	run release-notes v2.0.0
	assert_failure
	assert_output --partial "changie batch"
}

@test "with cliff.toml, the notes hold the tag's conventional commits since the previous tag" {
	make_cliff_repo
	commit "feat: pair devices with a short code"
	git tag v1.0.0
	commit "feat: forget a paired device"
	commit "docs: explain pairing"
	git tag v1.1.0
	run release-notes v1.1.0
	assert_success
	assert_output --partial "Forget a paired device"
	refute_output --partial "Pair devices with a short code"
	refute_output --partial "Explain pairing"
	refute_line --regexp '^## '
}

@test "with cliff.toml, the first tag's notes start at the first commit" {
	make_cliff_repo
	commit "feat: pair devices with a short code"
	git tag v1.0.0
	run release-notes v1.0.0
	assert_success
	assert_output --partial "Pair devices with a short code"
}

@test "without a version file or cliff.toml the notes fail and say what to add" {
	cd "$BATS_TEST_TMPDIR"
	run release-notes v2.0.0
	assert_failure
	assert_output --partial cliff.toml
}
