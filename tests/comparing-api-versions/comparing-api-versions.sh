#!/usr/bin/env bash
set -euo pipefail

v1_urls=(
  "http://localhost:8080/exist/apps/Edirom-Online-Backend/data/xql/getText.xql?uri=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Ftexts%2Ftext-1.xml"
)

v2_urls=(
  "http://localhost:8080/exist/apps/Edirom-Online-Backend/api/document?resource=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Ftexts%2Ftext-1.xml&tree=musicStructure&mediaType=text%2Fhtml"
)

if [[ ${#v1_urls[@]} -ne ${#v2_urls[@]} ]]; then
  echo "Error: the number of v1 URLs (${#v1_urls[@]}) does not match the number of v2 URLs (${#v2_urls[@]})."
  exit 1
fi

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

strip_namespaces() {
  local file="$1"
  local tmp_file="${file}.tmp"
  sed -E 's/[[:space:]]+xmlns(:(exist|functx|xd))?="(http:\/\/www\.w3\.org\/1999\/xhtml|http:\/\/exist\.sourceforge\.net\/NS\/exist|http:\/\/www\.functx\.com|http:\/\/www\.oxygenxml\.com\/ns\/doc\/xsl)"//g' "$file" > "$tmp_file"
  mv "$tmp_file" "$file"
}

for i in "${!v1_urls[@]}"; do
  index=$((i + 1))
  v1_file="$tmpdir/v1_${index}.out"
  v2_file="$tmpdir/v2_${index}.out"

  echo "\nComparing pair $index"
  echo "v1: ${v1_urls[$i]}"
  echo "v2: ${v2_urls[$i]}"

  curl -sS --fail "${v1_urls[$i]}" -o "$v1_file"
  curl -sS --fail "${v2_urls[$i]}" -o "$v2_file"

  strip_namespaces "$v1_file"
  strip_namespaces "$v2_file"

  diff_output=$(diff -u "$v1_file" "$v2_file" || true)
  if [[ -z "$diff_output" ]]; then
    echo "Result: no differences"
  else
    echo "Result: differences found"
    printf '%s\n' "$diff_output"
  fi
done
