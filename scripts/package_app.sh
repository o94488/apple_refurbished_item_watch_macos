#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h:h}"
OUTPUT_DIR="${ROOT}/outputs"
APP="${OUTPUT_DIR}/Refurb Watch.app"
SDK="/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk"
SWIFTC="/Library/Developer/CommandLineTools/usr/bin/swiftc"
MODULE_CACHE="${ROOT}/.build/module-cache"
BINARY="${ROOT}/.build/RefurbWatch"

cd "${ROOT}"
mkdir -p "${MODULE_CACHE}"
mkdir -p "${OUTPUT_DIR}"

CLANG_MODULE_CACHE_PATH="${MODULE_CACHE}" "${SWIFTC}" \
    -sdk "${SDK}" \
    -target arm64-apple-macosx15.0 \
    -swift-version 5 \
    -O \
    -whole-module-optimization \
    -o "${BINARY}" \
    "${ROOT}"/Sources/RefurbWatch/*.swift

mkdir -p "${APP}/Contents/MacOS"
mkdir -p "${APP}/Contents/Resources"
install -m 755 "${BINARY}" "${APP}/Contents/MacOS/RefurbWatch"
install -m 644 "${ROOT}/Resources/Info.plist" "${APP}/Contents/Info.plist"

codesign --force --sign - "${APP}"
echo "Created ${APP}"
