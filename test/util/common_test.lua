-- run with: lua test/util/common_test.lua

-- Minimal stand-ins for the Minetest API so util/common.lua can be loaded
-- and its pure functions tested outside the game engine.
logistica = { MODNAME = "logistica" }
minetest = {
  get_translator = function() return function(s) return s end end,
  get_position_from_hash = function(hash)
    -- stub: only needs to be a deterministic, known mapping for the tests below,
    -- not a faithful copy of the real engine encoding
    if hash == 424242 then return {x = 1, y = 2, z = 3} end
    return nil
  end,
}
vector = {
  new = function(x, y, z) return {x = x, y = y, z = z} end,
}

local MOD_ROOT = arg[0]:match("^(.*)test/util/common_test%.lua$") or "./"
dofile(MOD_ROOT.."util/common.lua")

local passed, failed = 0, 0

local function check(name, condition)
  if condition then
    passed = passed + 1
  else
    failed = failed + 1
    print("FAIL: "..name)
  end
end

local function positions_equal(a, b)
  return a and b and a.x == b.x and a.y == b.y and a.z == b.z
end

-- encode_position

check("encode_position formats x,y,z with prefix",
  logistica.encode_position({x = 1, y = -2, z = 3}) == "l_1,-2,3")

check("encode_position handles zero and negative coords",
  logistica.encode_position({x = 0, y = -30912, z = 30927}) == "l_0,-30912,30927")

-- decode_position

check("decode_position reverses encode_position",
  positions_equal(logistica.decode_position(logistica.encode_position({x = 5, y = -6, z = 7})), {x = 5, y = -6, z = 7}))

check("decode_position rejects a string without the prefix",
  logistica.decode_position("5,-6,7") == nil)

check("decode_position rejects a malformed body",
  logistica.decode_position("l_5,-6") == nil)

check("decode_position rejects a non-string",
  logistica.decode_position(nil) == nil and logistica.decode_position(12345) == nil)

check("decode_position handles large coordinates beyond s16 range",
  positions_equal(logistica.decode_position("l_1000000,-2000000,3000000"), {x = 1000000, y = -2000000, z = 3000000}))

-- compat_decode_position

check("compat_decode_position decodes the new prefixed format",
  positions_equal(logistica.compat_decode_position(logistica.encode_position({x = 8, y = 9, z = 10})), {x = 8, y = 9, z = 10}))

check("compat_decode_position falls back to legacy hash decoding",
  positions_equal(logistica.compat_decode_position("424242"), {x = 1, y = 2, z = 3}))

check("compat_decode_position returns nil for an empty string",
  logistica.compat_decode_position("") == nil)

check("compat_decode_position returns nil for a non-string",
  logistica.compat_decode_position(nil) == nil)

check("compat_decode_position returns nil for an unparseable legacy value",
  logistica.compat_decode_position("not_a_number") == nil)

print(string.format("%d passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
