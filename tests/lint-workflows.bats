setup() {
	load helpers
	cd "$BATS_TEST_TMPDIR" || return 1
	mkdir -p repo/.github/workflows
	cd repo || return 1
	cat >.github/workflows/ci.yml <<'YAML'
name: ci
on: push
permissions: {}
jobs:
  check:
    runs-on: ubuntu-26.04
    steps:
      - run: echo checked
YAML
}

@test "the default config knows the ubuntu-26.04 runner" {
	run lint-workflows
	assert_success
}

@test "a repository's own actionlint config replaces the default" {
	printf 'self-hosted-runner:\n  labels: []\n' >.github/actionlint.yaml
	run lint-workflows
	assert_failure
	assert_output --partial ubuntu-26.04
}

@test "an unsafe workflow fails" {
	cat >>.github/workflows/ci.yml <<'YAML'
      - run: echo "${{ github.event.head_commit.message }}"
YAML
	run lint-workflows
	assert_failure
}
