-- lua/noti/render/minimal.lua
-- Minimal notification renderer - just icon and message

local config_util = require("noti.config")

--- Render a notification with minimal style
---@param notif Noti.Notification
---@param config table Configuration
---@return table[] Lines for volt rendering
return function(notif, config)
  local lines = {}
  local color = config_util.get_color(config, notif.level)
  
  -- First line: icon + first message line
  local first_line = {}
  if notif.icon ~= "" then
    table.insert(first_line, { notif.icon .. " ", color })
  end
  
  -- Add duplicate counter if applicable
  if notif.duplicates and #notif.duplicates > 1 then
    table.insert(first_line, { string.format("(x%d) ", #notif.duplicates), "CommentFg" })
  end
  
  table.insert(first_line, { notif.message[1] or "", "Normal" })
  table.insert(lines, first_line)
  
  -- Remaining message lines
  for i = 2, #notif.message do
    table.insert(lines, {
      { notif.message[i], "Normal" }
    })
  end
  
  return lines
end
