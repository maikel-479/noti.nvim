-- lua/noti/render/minimal.lua (FIXED)
-- Minimal notification renderer - just icon and message

local config_util = require("noti.config")

--- Render a notification with minimal style
---@param notif Noti.Notification
---@param config table Configuration
---@return string[] Simple text lines
return function(notif, config)
  local lines = {}
  
  -- First line: icon + counter + first message line
  local first_line = ""
  
  if notif.icon ~= "" then
    first_line = notif.icon .. " "
  end
  
  -- Add duplicate counter if applicable
  if notif.duplicates and #notif.duplicates > 1 then
    first_line = first_line .. string.format("(x%d) ", #notif.duplicates)
  end
  
  first_line = first_line .. (notif.message[1] or "")
  table.insert(lines, first_line)
  
  -- Remaining message lines
  for i = 2, #notif.message do
    table.insert(lines, notif.message[i])
  end
  
  return lines
end
