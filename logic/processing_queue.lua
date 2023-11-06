local ProQ = {}
ProQ.__index = ProQ

function ProQ.new()
  local self = setmetatable({}, ProQ)
  self.queue = {}
  return self
end

-- the : syntax here causes a "self" arg to be implicitly added before any other args
function ProQ:add_pos(newval)
  self.value = newval
end

function ProQ:get_value()
  return self.value
end

local instance = ProQ.new()
-- do stuff with instance...