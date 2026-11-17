usage() {
	echo "usage: check-changelog fragment BASE_REF | check-changelog release TAG" >&2
	exit 2
}

fail() {
	echo "check-changelog: $*" >&2
	exit 1
}

[ $# -eq 2 ] || usage
case $1 in
fragment)
	if [ -z "$(git diff --name-only --diff-filter=A "$2...HEAD" -- .changes/unreleased)" ]; then
		fail "no new file in .changes/unreleased since $2. Run changie new."
	fi
	;;
release)
	tag=$2
	[ -f ".changes/$tag.md" ] || fail ".changes/$tag.md does not exist. Run changie batch for $tag."
	if find .changes/unreleased -type f ! -name .gitkeep 2>/dev/null | grep -q .; then
		fail ".changes/unreleased still has fragments that $tag does not include."
	fi
	changie merge --dry-run | diff -u CHANGELOG.md - >&2 || fail "CHANGELOG.md is out of date. Run changie merge."
	;;
*)
	usage
	;;
esac
