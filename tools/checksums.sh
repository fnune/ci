dir=${1:?usage: checksums DIR}

cd "$dir" || exit 1
sums=$(find . -maxdepth 1 -type f ! -name SHA256SUMS -printf '%f\n' | sort | xargs -r sha256sum)
printf '%s\n' "$sums" >SHA256SUMS
cat SHA256SUMS
