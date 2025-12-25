-- lua/noti/config.lua
-- Configuration management for noti

local M = {}

local default_config = {
  -- Notification settings
  level = vim.log.levels.INFO,
  timeout = 5000,
  max_width = nil,
  max_height = nil,
  minimum_width = 50,
  
  -- Positioning
  top_down = true,
  offset = { x = 1, y = 1 },
  
  -- Rendering
  render = "default",
  stages = "fade_slide",
  fps = 30,
  
  -- Behavior
  merge_duplicates = true,
  keep_duplicates_visible = true,
  
  -- Icons per level
  icons = {
    ERROR = "",
    WARN = "",
    INFO = "",
    DEBUG = "",
    TRACE = "✎",
  },
  
  -- Colors per level (volt highlight groups)
  colors = {
    ERROR = "ExRed",
    WARN = "ExYellow",
    INFO = "ExBlue",
    DEBUG = "CommentFg",
    TRACE = "ExLightGrey",
  },
  
  -- Callbacks
  on_open = nil,
  on_close = nil,
  
  -- Time formats
  time_formats = {
    notification = "%H:%M:%S",
    history = "%Y-%m-%d %H:%M:%S",
  },
}

--- Validate and setup configuration
---@param user_config table User configuration
---@param base_config? table Base config to extend
---@return table Validated configuration
function M.setup(user_config, base_config)
  base_config = base_config or default_config
  local config = vim.tbl_deep_extend("force", base_config, user_config)
  
  -- Validate level
  if type(config.level) == "string" then
    config.level = vim.log.levels[config.level:upper()] or vim.log.levels.INFO
  end
  
  -- Validate timeout
  if type(config.timeout) ~= "number" and config.timeout ~= false then
    config.timeout = default_config.timeout
  end
  
  -- Validate dimensions
  if config.max_width and type(config.max_width) == "number" then
    local max_w = config.max_width
    config.max_width = function() return max_w end
  elseif not config.max_width then
    config.max_width = function()
      return math.floor(vim.o.columns * 0.8)
    end
  end
  
  if config.max_height and type(config.max_height) == "number" then
    local max_h = config.max_height
    config.max_height = function() return max_h end
  elseif not config.max_height then
    config.max_height = function()
      return math.floor(vim.o.lines * 0.8)
    end
  end
  
  return config
end

--- Get icon for a level
---@param config table Configuration
---@param level string Level name
---@return string Icon
function M.get_icon(config, level)
  return config.icons[level] or config.icons.INFO
end

--- Get color for a level
---@param config table Configuration
---@param level string Level name
---@return string Highlight group
function M.get_color(config, level)
  return config.colors[level] or config.colors.INFO
end

--- Get formatted time
---@param config table Configuration
---@param timestamp number Unix timestamp
---@param format_type? string "notification" or "history"
---@return string Formatted time
function M.format_time(config, timestamp, format_type)
  format_type = format_type or "notification"
  local format = config.time_formats[format_type] or "%H:%M:%S"
  return vim.fn.strftime(format, timestamp)
end

return M
