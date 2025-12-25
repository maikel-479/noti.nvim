-- lua/noti/render/compact.lua
-- Compact notification renderer - single line format

local config_util = require("noti.config")

--- Render a notification in compact single-line style
---@param notif Noti.Notification
---@param config table Configuration
---@return table[] Lines for volt rendering
return function(notif, config)
  local color = config_util.get_color(config, notif.level)
  
  local parts = {}
  
  -- Icon
  if notif.icon ~= "" then
    table.insert(parts, { notif.icon .. " ", color })
  end
  
  -- Level badge
  table.insert(parts, { "[" .. notif.level .. "]", color })
  table.insert(parts, { " ", "Normal" })
  
  -- Title if present
  if notif.title[1] ~= "" then
    table.insert(parts, { notif.title[1] .. ": ", "Normal" })
  end
  
  -- Duplicate counter
  if notif.duplicates and #notif.duplicates > 1 then
    table.insert(parts, { string.format("(x%d) ", #notif.duplicates), "CommentFg" })
  end
  
  -- First line of message
  table.insert(parts, { notif.message[1] or "", "Normal" })
  
  return { parts }
end
