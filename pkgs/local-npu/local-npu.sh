#!/usr/bin/env bash
set -euo pipefail

assets=${LOCAL_NPU_ASSETS:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)}
state=${LOCAL_NPU_STATE_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/local-npu}
model=$state/model-group128
container=local-npu-qwen3
image=docker.io/openvino/model_server@sha256:a928903fe429f1e3e27107cc45932d30d95febfd2d1159dc50869c3eac76fc58
repo=anubhav200/Qwen3-4B-Instruct-2507-openvino-int4
revision=ea34b26c6e5f3babeb3eef61e5abb3da50f0f075

wait_ready() {
  echo "Waiting for the NPU model (first compilation can take several minutes)..." >&2
  for ((attempt = 0; attempt < 240; attempt++)); do
    if ! podman container exists "$container" \
      || [ "$(podman inspect --format '{{.State.Running}}' "$container")" != true ]; then
      echo "NPU server is not running. Use 'local-npu logs' or 'local-npu start'." >&2
      return 1
    fi
    if curl --fail --silent --max-time 5 http://127.0.0.1:8011/v1/config \
      | jq --exit-status 'any(.["qwen3-4b-npu"].model_version_status[]?; .state == "AVAILABLE")' >/dev/null; then
      echo "NPU model is ready." >&2
      return 0
    fi
    sleep 5
  done
  echo "Model did not become ready within 20 minutes; inspect 'local-npu logs'." >&2
  return 1
}

fetch_model() {
  mkdir -p "$model"
  while read -r digest file; do
    if [ -f "$model/$file" ] && printf '%s  %s\n' "$digest" "$model/$file" | sha256sum --check --status; then
      continue
    fi
    echo "Downloading $file"
    curl --fail --location --retry 3 --show-error --continue-at - \
      "https://huggingface.co/$repo/resolve/$revision/$file" \
      --output "$model/$file.part"
    printf '%s  %s\n' "$digest" "$model/$file.part" | sha256sum --check
    mv -- "$model/$file.part" "$model/$file"
  done < "$assets/model.sha256"
}

start_server() {
    if podman container exists "$container" \
      && [ "$(podman inspect --format '{{index .Config.Labels "io.local-npu.model-revision"}}' "$container")" != "$revision" ]; then
      echo "Replacing the NPU server for the updated model export..."
      podman rm --force "$container"
    fi
    if podman container exists "$container"; then
      if [ "$(podman inspect --format '{{.State.Running}}' "$container")" = true ]; then
        echo "NPU server is already running."
        return 0
      fi
      echo "Restarting NPU server..."
      podman start "$container"
      return 0
    fi
    if [ ! -c /dev/accel/accel0 ]; then
      echo "Intel NPU device /dev/accel/accel0 is unavailable." >&2
      exit 1
    fi
    fetch_model
    mkdir -p "$state/compiled-cache-group128"
    podman run --rm --userns=keep-id --user "$(id -u):$(id -g)" \
      --volume "$state:/models:rw" "$image" \
      --configure --model_path /models/model-group128 --task text_generation \
      --target_device NPU --tool_parser hermes3 --max_num_seqs 1 \
      --max_prompt_len 7168 \
      --plugin_config '{"MIN_RESPONSE_LEN":1024,"GENERATE_HINT":"BEST_PERF","CACHE_DIR":"/models/compiled-cache-group128"}'
    printf '%s\n' '{"model_config_list":[{"config":{"name":"qwen3-4b-npu","base_path":"/models/model-group128"}}]}' > "$state/config.json"
    podman run --detach --name "$container" \
      --label "io.local-npu.model-revision=$revision" \
      --userns=keep-id --user "$(id -u):$(id -g)" --group-add keep-groups \
      --device /dev/accel/accel0 \
      --cpus 6 --memory 12g --memory-swap 14g \
      --publish 127.0.0.1:8011:8000 \
      --volume "$state:/models:rw" \
      --env HOME=/models --env XDG_CACHE_HOME=/models/cache \
      "$image" --rest_port 8000 --config_path /models/config.json --log_level INFO
    echo "NPU server is compiling/loading. Follow 'local-npu logs'; check 'local-npu status'."
}

case "${1:-help}" in
  fetch)
    fetch_model
    podman pull "$image"
    ;;
  start)
    start_server
    ;;
  status)
    podman ps --all --filter "name=^$container$" --format '{{.Names}}: {{.Status}}'
    curl --fail --silent --show-error --max-time 5 http://127.0.0.1:8011/v1/config | jq .
    ;;
  wait)
    wait_ready
    ;;
  logs)
    shift
    exec podman logs "$@" "$container"
    ;;
  stop)
    if podman container exists "$container"; then
      podman rm --force "$container"
    fi
    ;;
  opencode)
    shift
    # Start before changing XDG paths: Podman needs the host's normal profile.
    # Keep lifecycle messages off stdout for `opencode run --format json`.
    start_server >&2
    wait_ready
    # A separate client profile keeps the experiment out of the normal client.
    export XDG_CONFIG_HOME=$state/client-config
    export XDG_DATA_HOME=$state/client-data
    export XDG_STATE_HOME=$state/client-state
    export XDG_CACHE_HOME=$state/client-cache
    export LOCAL_NPU_REPO_PLUGIN=$assets/repo-plugin
    mkdir -p "$XDG_CONFIG_HOME/opencode"
    cp -- "$assets/opencode.json" "$XDG_CONFIG_HOME/opencode/opencode.json"
    exec opencode --standalone "$@"
    ;;
  help|--help|-h)
    echo 'Usage: local-npu {fetch|start|wait|status|logs [-f]|stop|opencode [ARGS...]}'
    echo 'Model: Qwen3-4B-Instruct-2507, symmetric group-size-128 INT4, Intel NPU only.'
    echo "State: $state"
    ;;
  *)
    echo "Unknown command: $1" >&2
    exit 2
    ;;
esac
