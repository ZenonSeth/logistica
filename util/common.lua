

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