#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ -z "${JAVA_HOME:-}" && -x /Users/macbook/.jdks/jdk-17.0.12+7/Contents/Home/bin/java ]]; then
  export JAVA_HOME=/Users/macbook/.jdks/jdk-17.0.12+7/Contents/Home
fi
export PATH="${JAVA_HOME:+$JAVA_HOME/bin:}$PATH"
npm --prefix functions run build
exec npm run emulators
