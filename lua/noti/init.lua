-- lua/noti/init.lua
-- Noti: A volt-powered notification manager for Neovim

local M = {}

local config = require("noti.config")
local service = require("noti.service")
local history = require("noti.history")

-- Global state
local _instance = nil
local _config = nil

---@class Noti.Options
---@field title? string Notification title
---@field icon? string Custom icon
---@field timeout? number|boolean Timeout in ms (false = no timeout)
---@field level? string|number Log level
---@field on_open? function Callback when notification opens
---@field on_close? function Callback when notification closes
---@field keep? function Function to keep notification open
---@field render? string|function Renderer to use
---@field replace? number|table Notification to replace
---@field hide_from_history? boolean Hide from history
---@field animate? boolean Enable animations
---@field actions? table[] Interactive actions/buttons

---@class Noti.Action
---@field text string Button text
---@field callback function Action callback
---@field hl? string Highlight group

---@class Noti.Record
---@field id number Notification ID
---@field message string[] Message lines
---@field level string Log level
---@field title string[] Title parts
---@field icon string Icon
---@field time number Timestamp
---@field render function Render function

--- Setup noti with configuration
---@param user_config? table Configuration options
function M.setup(user_config)
  _config = config.setup(user_config or {})
  _instance = service.new(_config)
  
  -- Create commands
  vim.api.nvim_create_user_command("Noti", function()
    M.show_history()
  end, { desc = "Show notification history" })
  
  vim.api.nvim_create_user_command("NotiClear", function()
    M.clear_history()
  end, { desc = "Clear notification history" })
  
  vim.api.nvim_create_user_command("NotiDismiss", function()
    M.dismiss()
  end, { desc = "Dismiss all notifications" })
end

--- Display a notification
---@param message string|string[] Message content
---@param level? string|number Log level
---@param opts? Noti.Options Options
---@return Noti.Record
function M.notify(message, level, opts)
  if not _instance then
    M.setup()
  end
  
  level = level or vim.log.levels.INFO
  opts = opts or {}
  
  return _instance:notify(message, level, opts)
end

--- Display an async notification
---@param message string|string[] Message content
---@param level? string|number Log level
---@param opts? Noti.Options Options
---@return table Async record with events
function M.async(message, level, opts)
  if not _instance then
    M.setup()
  end
  
  local async = require("plenary.async")
  local send_close, wait_close = async.control.channel.oneshot()
  local send_open, wait_open = async.control.channel.oneshot()
  
  opts = opts or {}
  opts.on_close = send_close
  opts.on_open = send_open
  
  async.util.scheduler()
  local record = M.notify(message, level, opts)
  
  return vim.tbl_extend("error", record, {
    events = {
      open = wait_open,
      close = wait_close,
    }
  })
end

--- Get notification history
---@param opts? table Options (include_hidden: boolean)
---@return Noti.Record[]
function M.get_history(opts)
  if not _instance then
    M.setup()
  end
  return history.get(opts)
end

--- Clear notification history
function M.clear_history()
  if not _instance then
    M.setup()
  end
  history.clear()
end

--- Show history in a buffer
function M.show_history()
  if not _instance then
    M.setup()
  end
  
  local records = history.get()
  if #records == 0 then
    vim.notify("No notification history", vim.log.levels.INFO)
    return
  end
  
  -- Create a buffer to display history
  local buf = vim.api.nvim_create_buf(false, true)
  local lines = {}
  
  for _, record in ipairs(records) do
    local time = vim.fn.strftime("%Y-%m-%d %H:%M:%S", record.time)
    table.insert(lines, string.format("[%s] %s %s: %s", 
      time, record.icon, record.level, table.concat(record.message, " ")))
  end
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].filetype = "noti-history"
  
  -- Open in a split
  vim.cmd("split")
  vim.api.nvim_win_set_buf(0, buf)
end

--- Dismiss all visible notifications
---@param opts? table Options (pending: boolean, silent: boolean)
function M.dismiss(opts)
  if not _instance then
    return
  end
  _instance:dismiss(opts or {})
end

--- Create a notification instance with custom config
---@param user_config table Configuration
---@param inherit? boolean Inherit global config
---@return table Instance
function M.instance(user_config, inherit)
  local inst_config = config.setup(user_config, inherit and _config)
  return service.new(inst_config)
end

-- Convenience functions for different log levels
function M.error(message, opts)
  return M.notify(message, vim.log.levels.ERROR, opts)
end

function M.warn(message, opts)
  return M.notify(message, vim.log.levels.WARN, opts)
end

function M.info(message, opts)
  return M.notify(message, vim.log.levels.INFO, opts)
end

function M.debug(message, opts)
  return M.notify(message, vim.log.levels.DEBUG, opts)
end

function M.trace(message, opts)
  return M.notify(message, vim.log.levels.TRACE, opts)
end

-- Allow calling module directly
setmetatable(M, {
  __call = function(_, message, level, opts)
    return M.notify(message, level, opts)
  end
})

return M
