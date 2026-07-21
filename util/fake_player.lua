
-- Minimal fake player object, for calling item/node callbacks (on_use, can_dig,
-- after_place_node, etc.) that expect a player argument when acting on behalf of
-- an offline owner. Not a full ObjectRef replacement -- only the getters those
-- callbacks commonly read are implemented.
--
-- Cached per player name: repeated calls for the same name reuse and refresh
-- the same table instead of allocating a new one.
--
-- opts (all optional):
--   dir           : vector, facing direction used to derive look_dir/pitch/yaw
--   inventory     : InvRef, backs get/set_wielded_item and get_inventory
--   wield_list    : string, inventory list name used for the wielded item
--   wield_index   : number, index into wield_list (default 1)
--   wielded_item  : ItemStack, initial wielded item when no inventory/wield_list is given
local CLEANUP_INTERVAL = 60
local IDLE_TIMEOUT      = 600

local fake_player_cache = {}
local last_used_time    = {}

local fake_player_methods = {
  is_player = function() return true end,
  get_player_name = function(self) return self._name end,

  get_pos = function(self) return vector.copy(self._pos) end,
  set_pos = function(self, newPos) self._pos = vector.copy(newPos) end,

  get_look_dir = function(self) return vector.copy(self._dir) end,
  get_look_pitch = function(self) return self._pitch end,
  get_look_yaw = function(self) return self._yaw end,

  get_inventory = function(self) return self._inventory end,

  get_wielded_item = function(self)
    if self._inventory and self._wield_list then
      return self._inventory:get_stack(self._wield_list, self._wield_index)
    end
    return ItemStack(self._wielded_item)
  end,
  set_wielded_item = function(self, itemstack)
    if self._inventory and self._wield_list then
      return self._inventory:set_stack(self._wield_list, self._wield_index, itemstack)
    end
    self._wielded_item = ItemStack(itemstack)
  end,

  get_player_control = function()
    return { jump = false, right = false, left = false, LMB = false, RMB = false,
      sneak = false, aux1 = false, down = false, up = false }
  end,
}

function logistica.create_fake_player(playerName, pos, opts)
  opts = opts or {}
  local dir = opts.dir or vector.new(0, 0, 1)

  local player = fake_player_cache[playerName]
  if not player then
    player = { is_fake_player = true }
    setmetatable(player, { __index = fake_player_methods })
    fake_player_cache[playerName] = player
  end

  local yaw = math.atan(-dir.x, dir.z)
  if yaw < 0 then yaw = yaw + 2 * math.pi end

  player._name         = playerName
  player._pos          = vector.copy(pos)
  player._dir          = dir
  player._pitch        = -math.deg(math.asin(dir.y))
  player._yaw          = yaw
  player._inventory    = opts.inventory
  player._wield_list   = opts.wield_list
  player._wield_index  = opts.wield_index or 1
  player._wielded_item = opts.wielded_item and ItemStack(opts.wielded_item) or ItemStack("")

  last_used_time[playerName] = os.time()

  return player
end

-- drop the cached fake player once the real player is back online
minetest.register_on_joinplayer(function(player)
  local name = player:get_player_name()
  fake_player_cache[name] = nil
  last_used_time[name] = nil
end)

-- periodically evict fake players that haven't been used in a while
local cleanup_timer = 0
minetest.register_globalstep(function(dtime)
  cleanup_timer = cleanup_timer + dtime
  if cleanup_timer < CLEANUP_INTERVAL then return end
  cleanup_timer = 0

  local now = os.time()
  for name, lastUsed in pairs(last_used_time) do
    if now - lastUsed > IDLE_TIMEOUT then
      fake_player_cache[name] = nil
      last_used_time[name] = nil
    end
  end
end)
