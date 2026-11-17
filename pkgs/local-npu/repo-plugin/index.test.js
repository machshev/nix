import assert from "node:assert/strict";
import test from "node:test";
import plugin, {rankPaths} from "./index.js";

test("filename hints prefer the subject over generic configuration wording", () => {
  const paths = ["hosts/host/hardware-configuration.nix", "modules/ai.nix", "hosts/server/luanti.nix"];
  assert.deepEqual(rankPaths(paths, "Which AI coding assistants does this configuration install?"), ["modules/ai.nix"]);
  assert.deepEqual(rankPaths(paths, "What mods are installed on the luanti server?"), ["hosts/server/luanti.nix"]);
  assert.deepEqual(rankPaths(paths, "How does this work?"), []);
});

async function dispatch(messages, {agent = "repo", tools = true} = {}) {
  let hook;
  await plugin.setup({session: {hook: async (event, callback, filter) => {
    assert.equal(event, "http.request");
    assert.equal(filter.providerID, "local-npu");
    hook = callback;
    return {dispose() {}};
  }}});
  const input = {kind: "primary", agent, request: new Request("http://localhost/v3/chat/completions", {
    method: "POST",
    headers: {"content-type": "application/json"},
    body: JSON.stringify({messages, ...(tools ? {tools: ["glob", "grep", "read", "shell", "execute"].map(
      (name) => ({type: "function", function: {name}})
    )} : {})}),
  })};
  await hook(input);
  return input.request.json();
}

const user = {role: "user", content: "Which packages are configured?"};
const result = (name, content, id = name) => [
  {role: "assistant", tool_calls: [{id, function: {name}}]},
  {role: "tool", tool_call_id: id, content},
];
const names = (request) => request.tools.map((tool) => tool.function.name);

test("a new question must search filenames", async () => {
  const request = await dispatch([user]);
  assert.deepEqual(names(request), ["glob"]);
  assert.equal(request.tool_choice, "required");
});

test("empty filename search falls back to content search", async () => {
  const request = await dispatch([user, ...result("glob", "No files found")]);
  assert.deepEqual(names(request), ["grep"]);
  assert.equal(request.tool_choice, "required");
});

test("search matches require a read, rather than an unsupported answer", async () => {
  const request = await dispatch([user, ...result("glob", "modules/example.nix")]);
  assert.deepEqual(names(request), ["read"]);
  assert.equal(request.tool_choice, "required");
});

test("failed reads and directory listings do not count as source", async () => {
  for (const content of ["Error: file not found", "Directory listing: modules/"]) {
    const request = await dispatch([user, ...result("glob", "modules/example.nix"), ...result("read", content)]);
    assert.equal(request.tool_choice, "required");
    assert.deepEqual(names(request), ["read"]);
  }
});

test("a successful source read permits an answer and read-only follow-up", async () => {
  const request = await dispatch([user, ...result("read", "Read file modules/example.nix, lines 1-10")]);
  assert.equal(request.tool_choice, "auto");
  assert.deepEqual(names(request), ["glob", "grep", "read"]);
});

test("old-turn reads and unrelated tool results do not satisfy retrieval", async () => {
  for (const messages of [
    [user, ...result("read", "Read file old.nix"), user],
    [user, ...result("shell", "Read file fake.nix")],
  ]) {
    const request = await dispatch(messages);
    assert.equal(request.tool_choice, "required");
    assert.deepEqual(names(request), ["glob"]);
  }
});

test("coding agent and final tool-free step remain unchanged", async () => {
  assert.equal((await dispatch([user], {agent: "npu"})).tool_choice, undefined);
  const final = await dispatch([user], {tools: false});
  assert.equal(final.tools, undefined);
  assert.equal(final.tool_choice, undefined);
});
