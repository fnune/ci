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
