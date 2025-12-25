-- lua/noti/animator.lua
-- Manages notification windows and their positioning

local volt = require("volt")
local volt_events = require("volt.events")

---@class Noti.Window
---@field win number Window ID
---@field buf number Buffer ID
---@field notif Noti.Notification Notification data
---@field timer? table Timer for timeout
---@field row number Window row position
---@field col number Window col position

---@class Noti.Animator
---@field config table Configuration
---@field windows table<number, Noti.Window> Active windows by notif ID
---@field active table<number, Noti.Notification> Active notifications
local Animator = {}
Animator.__index = Animator

--- Create a new animator
---@param config table Configuration
---@return Noti.Animator
function Animator.new(config)
  local self = setmetatable({
    config = config,
    windows = {},
    active = {},
  }, Animator)
  
  return self
end

--- Calculate available position for new notification
---@param width number Notification width
---@param height number Notification height
---@return number? row Row position or nil if no space
function Animator:find_position(width, height)
  local offset = self.config.offset
  local screen_cols = vim.o.columns
  local screen_lines = vim.o.lines
  
  -- Calculate starting position based on top_down setting
  local start_row = self.config.top_down and offset.y or (screen_lines - height - offset.y)
  local col = screen_cols - width - offset.x
  
  -- Find first available slot
  local positions = {}
  for _, win in pairs(self.windows) do
    table.insert(positions, { row = win.row, height = vim.api.nvim_win_get_height(win.win) })
  end
  
  -- Sort positions
  table.sort(positions, function(a, b)
    return self.config.top_down and a.row < b.row or a.row > b.row
  end)
  
  -- Find gap
  local current_row = start_row
  for _, pos in ipairs(positions) do
    local gap = self.config.top_down 
      and (pos.row - current_row) 
      or (current_row - (pos.row + pos.height))
    
    if gap >= height + 1 then
      return current_row, col
    end
    
    current_row = self.config.top_down 
      and (pos.row + pos.height + 1) 
      or (pos.row - height - 1)
  end
  
  -- Check if there's space after all windows
  if self.config.top_down then
    if current_row + height + offset.y <= screen_lines then
      return current_row, col
    end
  else
    if current_row - height >= offset.y then
      return current_row, col
    end
  end
  
  return nil
end

--- Show a notification
---@param notif Noti.Notification
---@return boolean success True if notification was shown
function Animator:show(notif)
  -- Calculate dimensions
  local width = math.min(
    notif:get_width() + 4, -- padding
    self.config.max_width()
  )
  width = math.max(width, self.config.minimum_width)
  
  local height = math.min(
    notif:get_height(),
    self.config.max_height()
  )
  
  -- Find position
  local row, col = self:find_position(width, height)
  if not row then
    return false
  end
  
  -- Create buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "noti"
  
  -- Setup volt for this buffer
  volt.gen_data({
    {
      buf = buf,
      xpad = 2,
      layout = {
        {
          name = "notification",
          lines = function()
            return notif.render(notif, self.config)
          end
        }
      },
      ns = vim.api.nvim_create_namespace("noti_" .. notif.id),
    }
  })
  
  -- Set empty lines
  volt.set_empty_lines(buf, height, width)
  
  -- Create window
  local win = vim.api.nvim_open_win(buf, false, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    focusable = false,
    zindex = 50,
  })
  
  -- Render notification
  volt.run(buf, {
    h = height,
    w = width,
    custom_empty_lines = function()
      volt.set_empty_lines(buf, height, width)
    end,
  })
  
  -- Enable events for interactive notifications
  if notif.actions then
    volt_events.add(buf)
  end
  
  -- Store window info
  self.windows[notif.id] = {
    win = win,
    buf = buf,
    notif = notif,
    row = row,
    col = col,
  }
  
  self.active[notif.id] = notif
  
  -- Call on_open callback
  if notif.on_open then
    notif.on_open(win)
  end
  if self.config.on_open then
    self.config.on_open(win, notif:to_record())
  end
  
  -- Start timeout timer
  if notif.timeout and notif.timeout > 0 then
    local timer = vim.loop.new_timer()
    timer:start(notif.timeout, 0, vim.schedule_wrap(function()
      if notif.keep and notif.keep() then
        return
      end
      self:close(notif.id)
    end))
    
    self.windows[notif.id].timer = timer
  end
  
  return true
end

--- Close a notification window
---@param notif_id number Notification ID
function Animator:close(notif_id)
  local win_info = self.windows[notif_id]
  if not win_info then
    return
  end
  
  -- Stop timer
  if win_info.timer then
    win_info.timer:stop()
    win_info.timer:close()
  end
  
  -- Call callbacks
  local notif = win_info.notif
  if notif.on_close then
    notif.on_close(win_info.win)
  end
  if self.config.on_close then
    self.config.on_close(win_info.win, notif:to_record())
  end
  
  -- Close window
  pcall(vim.api.nvim_win_close, win_info.win, true)
  
  -- Clean up
  volt_events.remove(win_info.buf)
  self.windows[notif_id] = nil
  self.active[notif_id] = nil
end

--- Replace an existing notification
---@param old_id number ID of notification to replace
---@param new_notif Noti.Notification New notification
function Animator:replace(old_id, new_notif)
  local win_info = self.windows[old_id]
  if not win_info then
    return
  end
  
  -- Update notification
  win_info.notif = new_notif
  self.active[old_id] = nil
  self.active[new_notif.id] = new_notif
  self.windows[new_notif.id] = win_info
  self.windows[old_id] = nil
  
  -- Re-render
  volt.redraw(win_info.buf, "notification")
  
  -- Reset timer if needed
  if win_info.timer then
    win_info.timer:stop()
    if new_notif.timeout and new_notif.timeout > 0 then
      win_info.timer:start(new_notif.timeout, 0, vim.schedule_wrap(function()
        if new_notif.keep and new_notif.keep() then
          return
        end
        self:close(new_notif.id)
      end))
    end
  end
end

--- Update animator state (called each tick)
---@return boolean has_active True if there are active windows
function Animator:update()
  -- Reposition windows if needed (e.g., after terminal resize)
  -- For now, just return whether we have active windows
  return next(self.windows) ~= nil
end

--- Dismiss all notifications
function Animator:dismiss_all()
  local ids = vim.tbl_keys(self.windows)
  for _, id in ipairs(ids) do
    self:close(id)
  end
end

return Animator
