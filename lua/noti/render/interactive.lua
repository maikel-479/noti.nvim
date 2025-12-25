-- lua/noti/render/interactive.lua
-- Interactive notification renderer with volt components

local config_util = require("noti.config")
local ui = require("volt.ui")

--- Render an interactive notification with buttons and components
---@param notif Noti.Notification
---@param config table Configuration
---@return table[] Lines for volt rendering
return function(notif, config)
  local lines = {}
  local color = config_util.get_color(config, notif.level)
  
  -- Header with icon and title
  local header = {}
  table.insert(header, { "┌─ ", color })
  
  if notif.icon ~= "" then
    table.insert(header, { notif.icon .. " ", color })
  end
  
  local title = notif.title[1] or notif.level
  table.insert(header, { title, "Normal" })
  
  if notif.duplicates and #notif.duplicates > 1 then
    table.insert(header, { string.format(" (x%d)", #notif.duplicates), "CommentFg" })
  end
  
  table.insert(header, { " ", "Normal" })
  table.insert(header, { "_pad_" })
  
  if notif.title[2] ~= "" then
    table.insert(header, { notif.title[2] .. " ", "CommentFg" })
  end
  table.insert(header, { "─┐", color })
  
  table.insert(lines, ui.hpad(header, 50))
  
  -- Message area
  for _, line in ipairs(notif.message) do
    table.insert(lines, {
      { "│ ", color },
      { line, "Normal" },
      { "_pad_" },
      { "│", color }
    })
  end
  
  -- Make message lines proper width
  for i = 2, #lines do
    lines[i] = ui.hpad(lines[i], 50)
  end
  
  -- Actions section if present
  if notif.actions and #notif.actions > 0 then
    -- Separator
    table.insert(lines, ui.hpad({
      { "├", color },
      { "─", color },
      { "_pad_" },
      { "─┤", color }
    }, 50))
    
    -- Action buttons
    for i, action in ipairs(notif.actions) do
      local action_line = {
        { "│ ", color },
        { string.format("[%d]", i), "ExYellow" },
        { " ", "Normal" },
        { action.text, action.hl or "ExBlue" },
        action.callback,
        { "_pad_" },
        { "│", color }
      }
      table.insert(lines, ui.hpad(action_line, 50))
    end
  end
  
  -- Footer
  local footer = ui.hpad({
    { "└", color },
    { "─", color },
    { "_pad_" },
    { "─┘", color }
  }, 50)
  table.insert(lines, footer)
  
  return lines
end
