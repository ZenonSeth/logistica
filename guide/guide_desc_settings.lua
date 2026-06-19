local S = logistica.TRANSLATOR

local function sett(settingName, settingValue)
  return "\n"..settingName.." = "..tostring(settingValue)
end

local lines = {
S("Logistica v")..logistica.VERSION_STRING.."\n",
S("Current Server Settings for Logistica:\n"),
}

local keys = {}
for k, _ in pairs(logistica.settings) do keys[#keys + 1] = k end
table.sort(keys)
for _, k in ipairs(keys) do
  table.insert(lines, sett(k, logistica.settings[k]))
end

logistica.Guide.Desc.server_settings = table.concat(lines, "\n")
