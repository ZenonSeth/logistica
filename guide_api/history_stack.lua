
-- the stack is a volatile, in-memory concept
local stackInfos = {}

-- a history stack implementation, much like browser history works like
local HistoryStack = {}

-- gets (or creates an empty one) the current history stack for the given player/stack names
-- `optStackSizeLimit` enforces how far back to keep history, if nil, it defaults to 100
function HistoryStack.get(playerName, stackName, optStackSizeLimit)
  local self = {}
  local stackSizeLimit = optStackSizeLimit or 100
  if not stackInfos[playerName] then stackInfos[playerName] = {} end
  if not stackInfos[playerName][stackName] then stackInfos[playerName][stackName] = {currentPage = 0, stack = {}} end

  local mStackInfo = stackInfos[playerName][stackName]

  -- returns a string representation of the current stack item, or empty string if there isn't one
  self.get_current = function()
    return mStackInfo.stack[mStackInfo.currentPage] or ""
  end

  -- goes back to the prevous page of the stack, if possible, and returns its name (a string or empty string if stack is empty)
  self.go_back = function()
    if mStackInfo.currentPage > 1 then mStackInfo.currentPage = mStackInfo.currentPage - 1 end
    return mStackInfo.stack[mStackInfo.currentPage] or ""
  end

  -- goes forward to the next page of the stack, if possible, and returns its name (a string, or empty string if empty)
  self.go_forward = function()
    if mStackInfo.currentPage < #mStackInfo.stack then mStackInfo.currentPage = mStackInfo.currentPage + 1 end
    return mStackInfo.stack[mStackInfo.currentPage] or ""
  end

  -- adds a new page to the stack, after the current one, erasing any following stack.
  -- Returns `newPagName`, or `nil` if newPageName wasn't pushed for any reason
  self.push_new = function(newPageName)
    if type(newPageName) ~= "string" or newPageName == "" then return nil end
    local currPageName = mStackInfo.stack[mStackInfo.currentPage]
    if newPageName == currPageName then return nil end
    local newPageIndex = mStackInfo.currentPage + 1
    mStackInfo.currentPage = newPageIndex
    mStackInfo.stack[newPageIndex] = newPageName
    -- erase anything after it
    for i = newPageIndex + 1, #mStackInfo.stack do
      mStackInfo.stack[i] = nil
    end
    -- now check if we have exceeded limit
    if #mStackInfo.stack > stackSizeLimit then
      table.remove(mStackInfo.stack, 1)
      mStackInfo.currentPage = mStackInfo.currentPage - 1
    end
    return newPageName
  end

  -- returns true if there's a previous page to go to, false if there isn't
  self.has_prev = function()
    return mStackInfo.currentPage > 1
  end

  -- returns true if there's a next page to go to, false if there isn't
  self.has_next = function()
    return mStackInfo.currentPage > 0 and mStackInfo.currentPage < #mStackInfo.stack
  end

  return self
end

-- clears all stacks for given player from memory
function HistoryStack.on_player_leave(playerName)
  stackInfos[playerName] = nil
end

-- export it
logistica.HistoryStack = HistoryStack
