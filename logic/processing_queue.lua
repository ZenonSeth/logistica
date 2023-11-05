
logistica.proq = {}

local function get_meta(pos)
  logistica.load_position(pos)
  return minetest.get_meta(pos)
end

local QUEUE_KEY = "log_proq"
local DELIM = "|"

-- listOfPositions must be a list (naturally numbered table) of position vectors
local function save_queue(meta, listOfPositions)
  local tableOfStrings = {}
  for _,v in ipairs(listOfPositions) do
    table.insert(tableOfStrings, vector.to_string(v))
  end
  local singleString = table.concat(tableOfStrings, DELIM)
  meta:set_string(singleString)
end

-- listOfPositions must be a list (naturally numbered table) of position vectors
function logistica.proq.add(pos, listOfPositions)
  local meta = get_meta(pos)
  local positions = logistica.proq.get_all(pos)
  for _, v in ipairs(listOfPositions) do
    table.insert(positions, v)
  end
  save_queue(meta, positions)
end

-- returns a table of up to the next N positions
function logistica.proq.pop_next(pos, count)
  local meta = get_meta(pos)
  local positions = logistica.proq.get_all(pos)
  local ret = {}
  local rem = {}
  for i, v in ipairs(positions) do
    if (i <= count) then
      table.insert(ret, v)
    else
      table.insert(rem, v)
    end
  end
  save_queue(meta, rem)
  return ret
end

function logistica.proq.get_all(pos)
  local meta = get_meta(pos)
  if not meta:contains(QUEUE_KEY) then return {} end
  local compressedString = meta:get_string(QUEUE_KEY)
  local positionStrings = string.split(compressedString, DELIM, false)
  local positions = {}
    for _, v in ipairs(positionStrings) do
      local vector = vector.from_string(v)
      if vector then
        table.insert(positions, vector)
      end
    end
  return positions
end
