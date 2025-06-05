#!/bin/bash
set -euo pipefail

REPO="derailed/k9s"
EBUILD_DIR="../../../sys-cluster/k9s-bin"
TEMPLATE="k9s-bin.ebuild.template"

latest_version=$(curl -s "https://api.github.com/repos/${REPO}/releases/latest" | jq -r .tag_name)

if [[ -z "${latest_version}" || "${latest_version}" == "null" ]]; then
  echo "Error: Could not determine latest version"
  exit 1
fi

# Normalize version string (strip leading 'v')
version="${latest_version#v}"
filename="${EBUILD_DIR}/k9s-bin-${version}.ebuild"

mkdir -p "${EBUILD_DIR}"

if [[ -e "${filename}" ]]; then
  echo "Ebuild already exists: ${filename}"
  exit 0
fi

# Render from template
sed \
  -e "s/@VERSION@/${version}/g" \
  "${TEMPLATE}" > "${filename}"


sudo ebuild ${filename} digest

sudo chown -R brad:brad ${EBUILD_DIR}/Manifest

echo "Generated ebuild: ${filename}"
