
local function sett(settingName, settingValue)
  return "\n"..settingName.." = "..tostring(settingValue)
end

local lines = {
"Current Server Settings for Logistica:\n",
}

for k, v in pairs(logistica.settings) do
  table.insert(lines, sett(k, v))
end

logistica.Guide.Desc.server_settings = table.concat(lines, "\n")
