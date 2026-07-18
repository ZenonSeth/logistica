-- Quantum Cycles: an abstract, network-wide resource banked on the network controller.
-- Generation happens only on the controller itself, gated on at least one
-- Quantum Cycle Generator node being present anywhere on the network - extra
-- generators don't add generation speed, they're just a presence requirement.

local META_QC_BANK     = "qc_bank"
local META_QC_VLAVA     = "qc_vlava"
local META_QC_PROGRESS  = "qc_progress"

local VLAVA_MAX          = 1000 -- one bucket, in virtual-lava units
local VLAVA_DRAIN_PER_SEC = 100 -- virtual-lava units drained per second while generating
local VLAVA_PER_CYCLE     = 100 -- virtual-lava units drained per banked Quantum Cycle

local EMPTY_BUCKET     = logistica.itemstrings.empty_bucket
local LAVA_LIQUID_NAME = logistica.liquids.lava

local h2p = minetest.get_position_from_hash

-- Whether a network has a Quantum Cycle Generator only changes when the network is
-- rescanned - and a rescan always produces a brand new `network` table (see
-- create_network in network_logic.lua). So this is memoized by network table identity:
-- a weak-keyed cache means it's recomputed once per rescan instead of every controller tick,
-- and old entries are garbage-collected automatically once their network table is replaced.
local has_generator_cache = setmetatable({}, { __mode = "k" })

local function network_has_quantum_generator(network)
  local cached = has_generator_cache[network]
  if cached ~= nil then return cached end

  local found = false
  for hash, _ in pairs(network[logistica.NETWORK_GROUPS.misc] or {}) do
    local pos = h2p(hash)
    logistica.load_position(pos)
    local node = minetest.get_node_or_nil(pos)
    if node and logistica.GROUPS.quantum_generators.is(node.name) then
      found = true
      break
    end
  end
  has_generator_cache[network] = found
  return found
end

-- called from the network controller's own timer; pos is the controller's position
function logistica.run_quantum_cycle_generation(pos, network, elapsed)
  if not network or not elapsed or elapsed <= 0 then return end
  if not network_has_quantum_generator(network) then return end

  local meta = minetest.get_meta(pos)
  local vlava = meta:get_int(META_QC_VLAVA)
  local progress = meta:get_int(META_QC_PROGRESS)
  local bank = meta:get_int(META_QC_BANK)
  local bankMax = logistica.settings.quantum_cycle_bank_max

  local toDrain = math.floor(elapsed * VLAVA_DRAIN_PER_SEC)
  while toDrain > 0 and bank < bankMax do
    if vlava <= 0 then
      local filled = logistica.use_bucket_for_liquid_in_network(pos, ItemStack(EMPTY_BUCKET), LAVA_LIQUID_NAME, false)
      if not filled then break end -- no lava available in network, generation stalls
      vlava = vlava + VLAVA_MAX
    end
    local drained = math.min(toDrain, vlava)
    vlava = vlava - drained
    toDrain = toDrain - drained
    progress = progress + drained
    if progress >= VLAVA_PER_CYCLE then
      local gained = math.floor(progress / VLAVA_PER_CYCLE)
      bank = math.min(bankMax, bank + gained)
      progress = progress - gained * VLAVA_PER_CYCLE
    end
  end

  meta:set_int(META_QC_VLAVA, vlava)
  meta:set_int(META_QC_PROGRESS, progress)
  meta:set_int(META_QC_BANK, bank)
end

-- returns the max Quantum Cycles a network can ever bank
function logistica.network_get_quantum_cycles_max()
  return logistica.settings.quantum_cycle_bank_max
end

-- returns how many Quantum Cycles are currently banked on the given network
function logistica.network_get_quantum_cycles(network)
  if not network then return 0 end
  return minetest.get_meta(h2p(network.controller)):get_int(META_QC_BANK)
end

-- attempts to remove `amount` Quantum Cycles from the network's bank<br>
-- returns true if successful, false if not enough was banked (nothing is removed in that case)<br>
-- does not mutate anything if dryRun
function logistica.network_take_quantum_cycles(network, amount, dryRun)
  if not network or amount <= 0 then return true end
  local meta = minetest.get_meta(h2p(network.controller))
  local bank = meta:get_int(META_QC_BANK)
  if bank < amount then return false end
  if not dryRun then meta:set_int(META_QC_BANK, bank - amount) end
  return true
end
