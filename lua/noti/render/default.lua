-- lua/noti/render/default.lua
-- Default notification renderer with title, separator, message, and actions

local render_util = require("noti.render")
local config_util = require("noti.config")
local ui = require("volt.ui")

--- Render a notification with default style
---@param notif Noti.Notification
---@param config table Configuration
---@return table[] Lines for volt rendering
return function(notif, config)
  local lines = {}
  local color = config_util.get_color(config, notif.level)
  
  -- Title line
  local title = notif.title[1] or notif.level
  local time = notif.title[2] or ""
  
  local title_parts = {}
  if notif.icon ~= "" then
    table.insert(title_parts, { notif.icon .. " ", color })
  end
  if title ~= "" then
    table.insert(title_parts, { title, "Normal" })
  end
  
  -- Add duplicate counter if applicable
  if notif.duplicates and #notif.duplicates > 1 then
    table.insert(title_parts, { string.format(" (x%d)", #notif.duplicates), "CommentFg" })
  end
  
  -- Padding between title and time
  table.insert(title_parts, { "_pad_" })
  
  if time ~= "" then
    table.insert(title_parts, { time, "CommentFg" })
  end
  
  table.insert(lines, title_parts)
  
  -- Separator
  table.insert(lines, render_util.separator(40, "─", color))
  
  -- Message lines
  for _, line in ipairs(notif.message) do
    table.insert(lines, {
      { line, "Normal" }
    })
  end
  
  -- Actions if present
  if notif.actions and #notif.actions > 0 then
    -- Action separator
    table.insert(lines, {})
    table.insert(lines, render_util.separator(40, "─", "CommentFg"))
    
    -- Action buttons
    for _, action in ipairs(notif.actions) do
      local button = {
        { "  ", "Normal" },
        { "▶ ", color },
        { action.text, action.hl or "ExBlue" },
        action.callback
      }
      table.insert(lines, button)
    end
  end
  
  -- Pad lines with proper width handling
  for i, line in ipairs(lines) do
    if type(line) == "table" and line[1] then
      -- Check if line has _pad_ marker
      local has_pad = false
      for _, part in ipairs(line) do
        if part[1] == "_pad_" then
          has_pad = true
          break
        end
      end
      
      if has_pad then
        lines[i] = ui.hpad(line, 40)
      end
    end
  end
  
  return lines
end
