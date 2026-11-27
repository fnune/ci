tag=${1:?usage: publish-github TAG DIR}
dir=${2:?usage: publish-github TAG DIR}
: "${GITHUB_REPOSITORY:?publish-github needs GITHUB_REPOSITORY, such as fnune/kyaraben}"
: "${GH_TOKEN:?publish-github needs GH_TOKEN}"
gh=${GH_COMMAND:-gh}

notes=$(mktemp)
release-notes "$tag" >"$notes"
mapfile -d '' files < <(find "$dir" -maxdepth 1 -type f -print0)
if ! "$gh" release create "$tag" --repo "$GITHUB_REPOSITORY" --verify-tag --title "$tag" --notes-file "$notes" "${files[@]}"; then
	"$gh" release view "$tag" --repo "$GITHUB_REPOSITORY" >/dev/null || exit 1
	echo "publish-github: $tag already exists, so its files are replaced." >&2
	"$gh" release upload "$tag" --repo "$GITHUB_REPOSITORY" --clobber "${files[@]}"
fi
