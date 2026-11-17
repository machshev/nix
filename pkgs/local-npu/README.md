# Local NPU coding experiment

Qwen3-4B-Instruct-2507 on the Intel NPU, served through OpenVINO Model
Server 2026.4.1 and used from OpenCode 2.2.5. The model and container are
pinned by revision/digest; every downloaded model file is SHA-256 checked.

From this repository:

```sh
# From the project you want to work on:
nix run path:/home/jamesm/base/nix#local-npu -- opencode
```

The client starts the NPU server automatically when needed, waits until the
model is ready, then opens OpenCode in the current project. After `stop`, the
same command starts it again. Quitting OpenCode leaves the model server running;
use `stop` to release its memory.

The first start downloads about 2.2 GB of model files plus the container image.
Model compilation can take several minutes. `local-npu start` can be used to
preload the model, and `local-npu wait` waits for readiness independently.

The default **Repo** agent answers read-only repository questions. Use a fresh
session when switching from the earlier experiment, or select **Repo** in the
agent picker. Existing sessions can retain their previous agent.

For a single question:

```sh
nix run path:/home/jamesm/base/nix#local-npu -- opencode run \
  'What mods are installed on the luanti server?'
```

For edits, explicitly select the experimental **Npu** coding agent:

```sh
nix run path:/home/jamesm/base/nix#local-npu -- opencode run --agent npu \
  'Read the parser and add a test for empty input. Run the focused test.'
```

Start the client from the project's usual development shell so its test tools
(Python, Node, Cargo, etc.) are on PATH. The NPU launcher provides the inference
client and server controls, not each project's development dependencies.

Other commands:

```sh
nix run path:.#local-npu -- status
nix run path:.#local-npu -- logs -f
nix run path:.#local-npu -- stop
```

The script can also be run directly with `bash pkgs/local-npu/local-npu.sh`.
It needs Podman, curl, jq, git, coreutils and OpenCode on PATH.

## Configuration

- Rootless Podman, with `/dev/accel/accel0` passed through to the container.
  The launcher uses the host Podman to retain its NixOS storage/helper setup.
- Inference explicitly targets `NPU`; there is no automatic CPU fallback.
- API published only at `127.0.0.1:8011`. OVMS chat completions use `/v3`,
  while its status API uses `/v1/config`.
- 7,168 input tokens plus 1,024 reserved response tokens; OpenCode advertises
  an 8,192-token total context. Each response is capped at 512 output tokens.
- Sampling uses Qwen's recommended temperature 0.7, top-p 0.8, top-k 20 and
  min-p 0, with presence penalty 1.2 to discourage repetition.
- `hermes3` parses Qwen's tool calls into OpenAI-compatible responses.
- `GENERATE_HINT=BEST_PERF` trades a longer initial compilation for inference
  performance. Compiled artifacts are cached under the experiment state.
- The container has a six-CPU quota, a 12 GiB memory limit and a 14 GiB
  combined memory/swap limit. These limits protect the interactive workstation
  during compilation; they are not benchmark settings for maximum CPU speed.

State lives in `~/.local/share/local-npu` by default. Set
`LOCAL_NPU_STATE_DIR` to use another absolute path. Stopping removes the
container but retains weights, compiled caches and client history.

The `opencode` subcommand uses an isolated XDG profile, leaving the normal
OpenCode configuration unchanged. Project instructions/configuration still
apply. It starts a private OpenCode server (`--standalone`).

The default `repo` agent can only read and search. Its bundled plugin lists
tracked and non-ignored untracked filenames with `git ls-files`, ranks them
against words in the question and supplies up to eight possible source paths.
This is a lightweight filename hint, not semantic search. Non-Git checkouts or
questions without filename matches fall back to glob and grep.

For each new question the plugin limits the offered tools and uses
`tool_choice: required` until a source file has been read. It then allows a
normal answer or further reading/searching. This prevents the immediate
"I cannot access the repository" replies seen with the original setup. It does
not guarantee that the selected file answers the question, or that the model's
interpretation is correct. If the eight-step budget is exhausted, OpenCode's
final tool-free response is left alone.

The `npu` coding agent retains reading, searching, editing, writing and shell
commands. The retrieval gate applies only to `repo` on the local provider.
Unused built-in plugins (including skill discovery, web tools and subagents)
are disabled to reduce tool definitions and system instructions. Per-tool
output is capped at 120 lines / 8,000 bytes to limit context growth.
Automatic compaction is disabled: the initial full-tool
configuration compacted even the first request and lost the task in its
summary. Use fresh sessions for independent tasks rather than long chats.

## Model provenance

The current export is
[`anubhav200/Qwen3-4B-Instruct-2507-openvino-int4`](https://huggingface.co/anubhav200/Qwen3-4B-Instruct-2507-openvino-int4)
at revision `ea34b26c6e5f3babeb3eef61e5abb3da50f0f075`.
Its IR metadata records symmetric INT4, ratio 1.0, group size 128, without AWQ
or calibration. Weights and compiled artifacts use `model-group128` and
`compiled-cache-group128` under the state directory.

The earlier channel-wise export was
[`ervin0307/Qwen3-4B-Instruct-2507-int4-ov`](https://huggingface.co/ervin0307/Qwen3-4B-Instruct-2507-int4-ov)
at revision `56db90b12924ca095287201df2c62e7d46c20fcf`.
Its existing `model` and `compiled-cache` directories are retained. Switching
exports alone did **not** fix repository-question refusals; the successful
trial also required a more directed retrieval workflow.

The upstream model is
[`Qwen/Qwen3-4B-Instruct-2507`](https://huggingface.co/Qwen/Qwen3-4B-Instruct-2507),
an Apache-2.0 model that answers without a separate thinking phase.

The NPU is also available to the dictation service. Concurrent dictation can
affect latency; record whether it was active when comparing measurements.

## Initial validation (avodah, 2026-11-13)

- The server discovered `CPU, NPU`, and the graph explicitly selected `NPU`.
  Its accelerator file descriptor identified `intel_vpu` on PCI `0000:00:0b.0`.
- Initial compilation/loading took about 98 seconds. Cached restart worked.
- Direct chat returned the requested text. A structured tool-call request
  returned `add` with the correct integer arguments. Those small requests took
  about 4.3 and 6.0 seconds respectively, including prompt processing.
- OpenCode successfully read files and edited a Python function in a temporary
  fixture. The initial run skipped the requested test execution; another run
  repeated narration until the output limit. Sampling and worker instructions
  were subsequently tightened. These trials establish integration, not reliable
  autonomous coding performance.
- With the final sampling settings and explicit individual-tool instructions,
  the model read both fixture files, implemented `add(a,b)` with `edit`, and ran
  the tests with `shell`. It recovered from `python3` being absent on PATH by
  using the interpreter path supplied in the request. All three tests passed.
- The initial 10 GiB container limit caused an OOM kill during a longer session;
  the experiment now uses 12 GiB, with a 14 GiB combined memory/swap limit.
- The group-size-128 export compiled/loaded in about 194 seconds on its first
  start. With the original undirected workflow it still refused to search.
- Requiring a search and a source read made the plain Luanti question retrieve
  `hosts/qatan/luanti.nix` and identify its seven explicitly configured mods.
  An unrelated AI-assistants question exposed a bad broad search and context
  overflow; filename hints and smaller tool output were added afterward.
- With filename hints, the plain AI-assistants question read
  `modules/home-manager/ai.nix` and correctly listed all four configured tools.
  The packaged launcher also read `hosts/qatan/luanti.nix` and listed all seven
  mods. Some extra mod descriptions were imprecise, so list questions are now
  instructed to return names and source paths only. A final packaged retest
  again identified all seven mod names and cited the correct path, but still
  added descriptions despite that instruction. Treat elaboration cautiously.
  These are two smoke tests, not evidence of general coding reliability.

Plugin edge-case checks can be run with
`node pkgs/local-npu/repo-plugin/index.test.js`. They cover per-question gating,
empty searches, failed reads, unrelated results and the coding-agent bypass.
