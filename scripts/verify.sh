#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
npm --prefix functions run build
npm --prefix functions test
(cd app && flutter analyze && flutter test --reporter expanded && flutter build web --no-web-resources-cdn)
