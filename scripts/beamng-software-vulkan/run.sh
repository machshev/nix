#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
launcher="$(nix build --impure --file "$script_dir" --no-link --print-out-paths)"
exec "$launcher/bin/beamng-software-vulkan" "$@"
