-- lua/noti/render/init.lua
-- Renderer dispatcher and base rendering utilities

local M = {}

-- Available renderers
M.default = require("noti.render.default")
M.minimal = require("noti.render.minimal")
M.compact = require("noti.render.compact")
M.interactive = require("noti.render.interactive")

--- Format notification lines for volt rendering
---@param lines string[] Text lines
---@param hl string Highlight group
---@return table[] Volt virt_text lines
function M.format_lines(lines, hl)
  local result = {}
  for _, line in ipairs(lines) do
    table.insert(result, {
      { line, hl }
    })
  end
  return result
end

--- Create a separator line
---@param width number Line width
---@param char? string Character to use
---@param hl? string Highlight group
---@return table Volt virt_text line
function M.separator(width, char, hl)
  return {
    { string.rep(char or "─", width), hl or "CommentFg" }
  }
end

--- Create a title line
---@param icon string Icon
---@param title string Title text
---@param time string Time string
---@param icon_hl string Icon highlight
---@param title_hl string Title highlight
---@return table Volt virt_text line
function M.title_line(icon, title, time, icon_hl, title_hl)
  local parts = {}
  
  if icon and icon ~= "" then
    table.insert(parts, { icon .. " ", icon_hl })
  end
  
  if title and title ~= "" then
    table.insert(parts, { title .. " ", title_hl })
  end
  
  if time and time ~= "" then
    table.insert(parts, { time, "CommentFg" })
  end
  
  return parts
end

--- Create an action button
---@param text string Button text
---@param callback function Click callback
---@param hl? string Highlight group
---@return table Volt virt_text with action
function M.action_button(text, callback, hl)
  return {
    { "[ " .. text .. " ]", hl or "ExBlue" },
    callback
  }
end

--- Calculate max width of lines
---@param lines table[] Lines
---@return number Max width
function M.max_width(lines)
  local max_w = 0
  for _, line in ipairs(lines) do
    local w = 0
    if type(line) == "table" then
      for _, part in ipairs(line) do
        if type(part) == "table" and part[1] then
          w = w + vim.fn.strwidth(part[1])
        end
      end
    else
      w = vim.fn.strwidth(tostring(line))
    end
    max_w = math.max(max_w, w)
  end
  return max_w
end

return M
