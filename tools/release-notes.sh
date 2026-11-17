tag=${1:?usage: release-notes TAG}
file=.changes/$tag.md

if [ ! -f "$file" ]; then
	echo "release-notes: $file does not exist. Run changie batch for $tag first." >&2
	exit 1
fi

without_version_header() {
	tail -n +2 "$1" | sed '/./,$!d'
}

without_version_header "$file"
