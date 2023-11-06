
local META_ON_OFF_KEY = "logonoff"

local charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
local function rand_str(length, seed)
  math.randomseed(seed)
  local ret = {}
  local r
  for i = 1, length do
    r = math.random(1, #charset)
    table.insert(ret, charset:sub(r, r))
  end
  return table.concat(ret)
end

----------------------------------------------------------------
-- global namespaced functions
----------------------------------------------------------------

function logistica.load_position(pos)
  if pos.x < -30912 or pos.y < -30912 or pos.z < -30912 or
     pos.x >  30927 or pos.y >  30927 or pos.z >  30927 then return end
  if minetest.get_node_or_nil(pos) then
    return
  end
  local vm = minetest.get_voxel_manip()
  vm:read_from_map(pos, pos)
end

function logistica.swap_node(pos, newName)
  local node = minetest.get_node(pos)
  if node.name ~= newName then
    node.name = newName
    minetest.swap_node(pos, node)
  end
end

function logistica.get_network_name_for(pos)
  local p1 = rand_str(3, pos.x)
  local p2 = rand_str(3, pos.y)
  local p3 = rand_str(3, pos.z)
  return p1.."-"..p2.."-"..p3
end

function logistica.set_infotext(pos, txt)
  local meta = minetest.get_meta(pos)
  meta:set_string("infotext", txt)
end

function logistica.ttos(val, name, skipnewlines, depth)
    skipnewlines = skipnewlines or true
    depth = depth or 0

    local tmp = string.rep(" ", depth)

    if name then tmp = tmp .. name .. " = " end

    if type(val) == "table" then
        tmp = tmp .. "{" .. (not skipnewlines and "\n" or "")

        for k, v in pairs(val) do
            tmp =  tmp .. logistica.ttos(v, k, skipnewlines, depth + 1) .. "," .. (not skipnewlines and "\n" or "")
        end

        tmp = tmp .. string.rep(" ", depth) .. "}"
    elseif type(val) == "number" then
        tmp = tmp .. tostring(val)
    elseif type(val) == "string" then
        tmp = tmp .. string.format("%q", val)
    elseif type(val) == "boolean" then
        tmp = tmp .. (val and "true" or "false")
    else
        tmp = tmp .. "\"[inserializeable datatype:" .. type(val) .. "]\""
    end

    return tmp
end

function logistica.clamp(v, min, max)
    if v < min then return min end
    if v > max then return max end
    return v
end

function logistica.start_node_timer(pos, time)
	local timer = minetest.get_node_timer(pos)
	if not timer:is_started() then
		timer:start(time)
	end
	return timer
end

function logistica.is_machine_on(pos)
  local meta = minetest.get_meta(pos)
  return meta:get_int(META_ON_OFF_KEY) > 0
end

-- toggles the state and returns the new state (true for on, false for off)
function logistica.toggle_machine_on_off(pos)
  local meta = minetest.get_meta(pos)
  local newState = (meta:get_int(META_ON_OFF_KEY) + 1) % 2
  meta:set_int(META_ON_OFF_KEY, newState)
  return newState > 0
end

-- isOn is optional
function logistica.set_logistica_node_infotext(pos, isOn)
	if isOn == nil then isOn = logistica.is_machine_on(pos) end
	logistica.load_position(pos)
  local meta = minetest.get_meta(pos)
  local node = minetest.get_node(pos)
	local text = minetest.registered_nodes[node.name].description..
							"\n"..(isOn and "Running" or "Stopped")
	meta:set_string("infotext", text)
end
