logistica.ALLOWED_PULL_LISTS = {}
local allowedPull = logistica.ALLOWED_PULL_LISTS
allowedPull["main"] = true
allowedPull["src"] = true
allowedPull["dst"] = true
allowedPull["output"] = true
allowedPull["fuel"] = true

logistica.ALLOWED_PUSH_LISTS = {}
local allowedPush = logistica.ALLOWED_PUSH_LISTS
allowedPush["main"] = true
allowedPush["src"] = true
allowedPush["fuel"] = true
allowedPush["input"] = true
allowedPush["shift"] = true

function logistica.is_allowed_pull_list(listName)
  return allowedPull[listName] == true
end

function logistica.is_allowed_push_list(listName)
  return allowedPush[listName] == true
end