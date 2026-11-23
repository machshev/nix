-- core.set_node() runs the new/old node's on_construct, on_destruct and
-- after_destruct callbacks. If one of those sets a node whose callback sets
-- it back, the server recurses until the Lua error tracebacks it builds at
-- each level exhaust memory (seen as ~10G in seconds, then an OOM kill).
--
-- Wrap every node's callbacks with a shared nesting counter: past
-- max_depth, log what is looping and where (once per node and callback),
-- and skip the callback so the loop ends.

local max_depth = 32
local depth = 0
local reported = {}

local callbacks = {"on_construct", "on_destruct", "after_destruct"}

local function wrap(name, field, fn)
	return function(pos, ...)
		if depth >= max_depth then
			local key = name .. " " .. field
			if not reported[key] then
				reported[key] = true
				core.log("error", ("[recursion_guard] %s %s at %s nested %d deep; skipping it.\n%s")
					:format(name, field, core.pos_to_string(pos), depth, debug.traceback()))
			end
			return
		end
		depth = depth + 1
		local res = {pcall(fn, pos, ...)}
		depth = depth - 1
		if not res[1] then
			error(res[2], 0)
		end
		return unpack(res, 2, table.maxn(res))
	end
end

core.register_on_mods_loaded(function()
	for name, def in pairs(core.registered_nodes) do
		local overrides
		for _, field in ipairs(callbacks) do
			if type(def[field]) == "function" then
				overrides = overrides or {}
				overrides[field] = wrap(name, field, def[field])
			end
		end
		if overrides then
			core.override_item(name, overrides)
		end
	end
end)
