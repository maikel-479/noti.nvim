-- lua/noti/history.lua
-- Notification history management

local M = {}

-- History storage
local history = {}

--- Add a notification to history
---@param record Noti.Record
function M.add(record)
  table.insert(history, vim.deepcopy(record))
end

--- Get notification history
---@param opts? table Options (include_hidden: boolean)
---@return Noti.Record[]
function M.get(opts)
  opts = opts or {}
  
  if opts.include_hidden then
    return vim.deepcopy(history)
  end
  
  local visible = {}
  for _, record in ipairs(history) do
    if not record.hide_from_history then
      table.insert(visible, record)
    end
  end
  
  return visible
end

--- Clear all history
function M.clear()
  history = {}
end

--- Get history count
---@return number
function M.count()
  return #history
end

--- Get recent notifications
---@param count number Number of recent notifications to get
---@return Noti.Record[]
function M.recent(count)
  local start = math.max(1, #history - count + 1)
  local recent = {}
  
  for i = start, #history do
    table.insert(recent, vim.deepcopy(history[i]))
  end
  
  return recent
end

--- Search history by level
---@param level string Level to search for
---@return Noti.Record[]
function M.by_level(level)
  local results = {}
  
  for _, record in ipairs(history) do
    if record.level == level then
      table.insert(results, vim.deepcopy(record))
    end
  end
  
  return results
end

--- Search history by text
---@param text string Text to search for
---@return Noti.Record[]
function M.search(text)
  local results = {}
  local pattern = text:lower()
  
  for _, record in ipairs(history) do
    -- Search in message
    for _, line in ipairs(record.message) do
      if line:lower():find(pattern, 1, true) then
        table.insert(results, vim.deepcopy(record))
        break
      end
    end
    
    -- Search in title
    if record.title[1]:lower():find(pattern, 1, true) then
      table.insert(results, vim.deepcopy(record))
    end
  end
  
  return results
end

return M
