tag=${1:?usage: publish-github TAG DIR}
dir=${2:?usage: publish-github TAG DIR}
: "${GITHUB_REPOSITORY:?publish-github needs GITHUB_REPOSITORY, such as fnune/kyaraben}"
: "${GH_TOKEN:?publish-github needs GH_TOKEN}"

notes=$(mktemp)
release-notes "$tag" >"$notes"
find "$dir" -maxdepth 1 -type f -print0 | xargs -0 "${GH_COMMAND:-gh}" release create "$tag" \
	--repo "$GITHUB_REPOSITORY" --verify-tag --title "$tag" --notes-file "$notes"
