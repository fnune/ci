actionlint_config=.github/actionlint.yaml
[ -f "$actionlint_config" ] || actionlint_config=$DEFAULT_ACTIONLINT_CONFIG
mapfile -t workflows < <(find .github/workflows -maxdepth 1 -type f \( -name '*.yml' -o -name '*.yaml' \) 2>/dev/null | sort)
if [ ${#workflows[@]} -gt 0 ]; then
	actionlint -config-file "$actionlint_config" "${workflows[@]}"
fi

zizmor_config=
for candidate in zizmor.yml .github/zizmor.yml; do
	[ -f "$candidate" ] && zizmor_config=$candidate
done
zizmor --offline --no-progress --config "${zizmor_config:-$DEFAULT_ZIZMOR_CONFIG}" .
