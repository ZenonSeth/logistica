local ProQ = {}
ProQ.__index = ProQ

function ProQ.new()
  local self = setmetatable({}, ProQ)
  self.queue = {}
  return self
end

function ProQ:add_pos(newval)
  self.value = newval
end

function ProQ:get_value()
  return self.value
end
