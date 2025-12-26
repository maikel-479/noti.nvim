-- lua/noti/render/compact.lua (FIXED)
-- Compact single-line renderer

local config_util = require("noti.config")

--- Render a notification in compact single-line style
---@param notif Noti.Notification
---@param config table Configuration
---@return string[] Single line in array
return function(notif, config)
  local parts = {}
  
  -- Icon
  if notif.icon ~= "" then
    table.insert(parts, notif.icon)
  end
  
  -- Level badge
  table.insert(parts, "[" .. notif.level .. "]")
  
  -- Title if present
  if notif.title[1] ~= "" then
    table.insert(parts, notif.title[1] .. ":")
  end
  
  -- Duplicate counter
  if notif.duplicates and #notif.duplicates > 1 then
    table.insert(parts, string.format("(x%d)", #notif.duplicates))
  end
  
  -- First line of message
  table.insert(parts, notif.message[1] or "")
  
  return { table.concat(parts, " ") }
end
