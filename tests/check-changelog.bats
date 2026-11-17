setup() {
	load helpers
	make_repo
}

@test "a branch without a new fragment fails" {
	git checkout -qb feature
	run check-changelog fragment main
	assert_failure
	assert_output --partial "changie new"
}

@test "a branch with a new fragment passes" {
	git checkout -qb feature
	add_fragment Added "Pair devices with a short code"
	run check-changelog fragment main
	assert_success
}

@test "a fragment that only changes counts as none" {
	add_fragment Added "Pair devices"
	git checkout -qb feature
	echo "body: Pair devices with a code" >>.changes/unreleased/*.yaml
	git commit -qam reword
	run check-changelog fragment main
	assert_failure
}

@test "a released tag passes" {
	add_fragment Added "Pair devices"
	release v1.0.0
	run check-changelog release v1.0.0
	assert_success
}

@test "a tag without a version file fails" {
	add_fragment Added "Pair devices"
	release v1.0.0
	run check-changelog release v2.0.0
	assert_failure
	assert_output --partial "changie batch"
}

@test "a release that leaves fragments unreleased fails" {
	add_fragment Added "Pair devices"
	release v1.0.0
	add_fragment Fixed "A late fix"
	run check-changelog release v1.0.0
	assert_failure
	assert_output --partial "unreleased"
}

@test "a release without changie merge fails" {
	add_fragment Added "Pair devices"
	changie batch v1.0.0 >/dev/null
	run check-changelog release v1.0.0
	assert_failure
	assert_output --partial "changie merge"
}

@test "an unknown mode prints the usage" {
	run check-changelog publish v1.0.0
	assert_failure 2
	assert_output --partial "usage"
}
