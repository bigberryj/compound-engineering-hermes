#!/usr/bin/env bash
# Install the compound-engineering Hermes bundle.
#
# Creates a symlink at ~/.hermes/skills/compound-engineering pointing
# to this checkout, so future updates are just `git pull`.

set -euo pipefail

BUNDLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="${HOME}/.hermes/skills"
LINK_PATH="${SKILLS_DIR}/compound-engineering"

mkdir -p "${SKILLS_DIR}"

if [[ -L "${LINK_PATH}" || -e "${LINK_PATH}" ]]; then
    echo "Found existing ${LINK_PATH}"
    if [[ -L "${LINK_PATH}" ]]; then
        EXISTING_TARGET="$(readlink "${LINK_PATH}")"
        if [[ "${EXISTING_TARGET}" == "${BUNDLE_DIR}" ]]; then
            echo "✓ Already linked to this checkout — nothing to do."
            exit 0
        fi
        echo "  Currently points to: ${EXISTING_TARGET}"
        echo "  Refusing to clobber. Remove the existing link manually and re-run."
        exit 1
    fi
    echo "  Refusing to clobber a real directory. Remove it manually and re-run."
    exit 1
fi

ln -s "${BUNDLE_DIR}" "${LINK_PATH}"
echo "✓ Linked ${LINK_PATH} -> ${BUNDLE_DIR}"
echo ""
echo "Verify with:"
echo "  bash ${BUNDLE_DIR}/ce-setup/scripts/check-health.sh"
