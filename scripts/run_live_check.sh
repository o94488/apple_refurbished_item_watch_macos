#!/bin/zsh
set -euo pipefail

ROOT="${0:A:h:h}"
SDK="/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk"
SWIFTC="/Library/Developer/CommandLineTools/usr/bin/swiftc"
MODULE_CACHE="${ROOT}/.build/module-cache"
TEST_BINARY="${ROOT}/.build/RefurbWatchLiveCheck"

mkdir -p "${MODULE_CACHE}"

CLANG_MODULE_CACHE_PATH="${MODULE_CACHE}" "${SWIFTC}" \
    -sdk "${SDK}" \
    -target arm64-apple-macosx15.0 \
    -swift-version 5 \
    -o "${TEST_BINARY}" \
    "${ROOT}/Sources/RefurbWatch/Models.swift" \
    "${ROOT}/Sources/RefurbWatch/ProductDescriptionParser.swift" \
    "${ROOT}/Sources/RefurbWatch/AppleStoreClient.swift" \
    "${ROOT}/Tests/Manual/LiveInventoryHarness.swift"

"${TEST_BINARY}"
