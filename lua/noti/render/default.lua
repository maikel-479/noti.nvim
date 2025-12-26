-- lua/noti/render/default.lua (FIXED)
-- Simple, working default renderer

local config_util = require("noti.config")

--- Render a notification with default style
---@param notif Noti.Notification
---@param config table Configuration
---@return string[] Lines with embedded highlight markers
return function(notif, config)
  local lines = {}
  local color = config_util.get_color(config, notif.level)
  
  -- Title line
  local title = notif.title[1] or notif.level
  local time = notif.title[2] or ""
  
  -- Build title line
  local title_line = ""
  if notif.icon ~= "" then
    title_line = notif.icon .. " "
  end
  title_line = title_line .. title
  
  -- Add duplicate counter if applicable
  if notif.duplicates and #notif.duplicates > 1 then
    title_line = title_line .. string.format(" (x%d)", #notif.duplicates)
  end
  
  -- Add time to right
  if time ~= "" then
    local space_count = 40 - vim.fn.strwidth(title_line) - vim.fn.strwidth(time)
    if space_count > 0 then
      title_line = title_line .. string.rep(" ", space_count) .. time
    end
  end
  
  table.insert(lines, title_line)
  
  -- Separator
  table.insert(lines, string.rep("─", 40))
  
  -- Message lines
  for _, line in ipairs(notif.message) do
    table.insert(lines, line)
  end
  
  -- Actions if present
  if notif.actions and #notif.actions > 0 then
    table.insert(lines, "")
    table.insert(lines, string.rep("─", 40))
    
    for i, action in ipairs(notif.actions) do
      table.insert(lines, string.format("  [%d] %s", i, action.text))
    end
  end
  
  return lines
end
