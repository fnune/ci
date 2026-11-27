tag=${1:?usage: release-notes TAG}
file=.changes/$tag.md

without_version_header() {
	tail -n +2 | sed '/./,$!d'
}

if [ -f "$file" ]; then
	without_version_header <"$file"
elif [ -f cliff.toml ]; then
	start=$(git describe --tags --abbrev=0 "$tag^" 2>/dev/null || git rev-list --max-parents=0 "$tag")
	git-cliff --strip header "$start..$tag" 2>/dev/null | without_version_header
else
	echo "release-notes: neither $file nor cliff.toml exists. Run changie batch for $tag first, or add a cliff.toml." >&2
	exit 1
fi
