-- lua/noti/service/notification.lua
-- Notification data structure

local config_util = require("noti.config")

---@class Noti.Notification
---@field id number
---@field message string[]
---@field level string
---@field title string[]
---@field icon string
---@field time number
---@field timeout number|false
---@field keep? function
---@field on_open? function
---@field on_close? function
---@field render function
---@field hide_from_history? boolean
---@field animate boolean
---@field actions? Noti.Action[]
---@field duplicates? number[]
local Notification = {}
Notification.__index = Notification

local level_map = {
  [vim.log.levels.ERROR] = "ERROR",
  [vim.log.levels.WARN] = "WARN",
  [vim.log.levels.INFO] = "INFO",
  [vim.log.levels.DEBUG] = "DEBUG",
  [vim.log.levels.TRACE] = "TRACE",
}

--- Create a new notification
---@param id number Notification ID
---@param message string|string[] Message content
---@param level string|number Log level
---@param opts table Options
---@param config table Configuration
---@return Noti.Notification
function Notification.new(id, message, level, opts, config)
  -- Normalize level
  if type(level) == "number" then
    level = level_map[level] or "INFO"
  else
    level = (level or "INFO"):upper()
  end
  
  -- Normalize message
  if type(message) == "string" then
    message = vim.split(message, "\n")
  end
  
  -- Create title
  local title = opts.title or ""
  if type(title) == "string" then
    local time_str = config_util.format_time(config, vim.fn.localtime())
    title = { title, time_str }
  end
  
  -- Get icon
  local icon = opts.icon or config_util.get_icon(config, level)
  
  -- Get renderer
  local render = opts.render or config.render
  if type(render) == "string" then
    render = require("noti.render")[render]
  end
  
  local self = setmetatable({
    id = id,
    message = message,
    level = level,
    title = title,
    icon = icon,
    time = vim.fn.localtime(),
    timeout = opts.timeout ~= nil and opts.timeout or config.timeout,
    keep = opts.keep,
    on_open = opts.on_open,
    on_close = opts.on_close,
    render = render,
    hide_from_history = opts.hide_from_history or false,
    animate = opts.animate ~= false,
    actions = opts.actions,
    duplicates = nil,
  }, Notification)
  
  return self
end

--- Create a record for history
---@return Noti.Record
function Notification:to_record()
  return {
    id = self.id,
    message = vim.deepcopy(self.message),
    level = self.level,
    title = vim.deepcopy(self.title),
    icon = self.icon,
    time = self.time,
    render = self.render,
  }
end

--- Check if two notifications are equal (for duplicate detection)
---@param other Noti.Notification
---@return boolean
function Notification:equals(other)
  if self.level ~= other.level then
    return false
  end
  
  if not vim.deep_equal(self.message, other.message) then
    return false
  end
  
  -- Compare only the left title (not timestamp)
  if self.title[1] ~= other.title[1] then
    return false
  end
  
  if self.icon ~= other.icon then
    return false
  end
  
  return true
end

--- Get display width of notification
---@return number Width in columns
function Notification:get_width()
  local max_width = 0
  
  -- Check message width
  for _, line in ipairs(self.message) do
    max_width = math.max(max_width, vim.fn.strwidth(line))
  end
  
  -- Check title width
  local title_width = vim.fn.strwidth(self.icon .. " " .. self.title[1] .. " " .. self.title[2])
  max_width = math.max(max_width, title_width)
  
  -- Account for actions if present
  if self.actions then
    for _, action in ipairs(self.actions) do
      max_width = math.max(max_width, vim.fn.strwidth(action.text) + 4)
    end
  end
  
  return max_width
end

--- Get display height of notification
---@return number Height in lines
function Notification:get_height()
  local height = #self.message
  
  -- Add 2 for title and separator
  height = height + 2
  
  -- Add lines for actions
  if self.actions and #self.actions > 0 then
    height = height + 2 + #self.actions
  end
  
  return height
end

return Notification
