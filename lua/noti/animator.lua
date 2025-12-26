-- lua/noti/animator.lua (FIXED)
-- Window management without Volt dependency

local api = vim.api

---@class Noti.Window
---@field win number Window ID
---@field buf number Buffer ID
---@field notif Noti.Notification Notification data
---@field timer? table Timer for timeout
---@field row number Window row position
---@field col number Window col position
---@field stage number Current animation stage

---@class Noti.Animator
---@field config table Configuration
---@field windows table<number, Noti.Window> Active windows by notif ID
---@field active table<number, Noti.Notification> Active notifications
---@field win_stages table<number, number> Stage tracking
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
    win_stages = {},
  }, Animator)
  
  return self
end

--- Calculate available position for new notification
---@param width number Notification width
---@param height number Notification height
---@return number? row Row position or nil if no space
---@return number? col Column position or nil if no space
function Animator:find_position(width, height)
  local offset = self.config.offset
  local screen_cols = vim.o.columns
  local screen_lines = vim.o.lines - vim.o.cmdheight - (vim.o.laststatus > 0 and 1 or 0)
  
  -- Account for border (2 lines/cols)
  local border_padding = 2
  local total_height = height + border_padding
  
  -- Calculate column position (right-aligned with offset)
  local col = screen_cols - width - offset.x - border_padding
  
  -- Collect existing window positions
  local occupied = {}
  for _, win_info in pairs(self.windows) do
    if api.nvim_win_is_valid(win_info.win) then
      local win_conf = api.nvim_win_get_config(win_info.win)
      table.insert(occupied, {
        row = win_conf.row,
        height = win_conf.height + border_padding
      })
    end
  end
  
  -- Sort positions by row
  table.sort(occupied, function(a, b)
    return self.config.top_down and a.row < b.row or a.row > b.row
  end)
  
  -- Find first available slot
  local current_row = self.config.top_down and offset.y or (screen_lines - total_height - offset.y)
  
  for _, pos in ipairs(occupied) do
    local gap = self.config.top_down 
      and (pos.row - current_row) 
      or (current_row - (pos.row + pos.height))
    
    if gap >= total_height then
      return current_row, col
    end
    
    current_row = self.config.top_down 
      and (pos.row + pos.height) 
      or (pos.row - total_height)
  end
  
  -- Check if there's space after all windows
  if self.config.top_down then
    if current_row + total_height <= screen_lines then
      return current_row, col
    end
  else
    if current_row >= offset.y then
      return current_row, col
    end
  end
  
  return nil, nil
end

--- Render notification content to buffer
---@param buf number Buffer ID
---@param notif Noti.Notification
---@return number width, number height
function Animator:render_to_buffer(buf, notif)
  local render_lines = notif.render(notif, self.config)
  
  -- Convert Volt-style virt_text to actual buffer content
  local lines = {}
  local highlights = {}
  local namespace = api.nvim_create_namespace("noti_render")
  
  for line_idx, line_data in ipairs(render_lines) do
    local line_text = ""
    local col_offset = 0
    
    -- Handle both string lines and virt_text tables
    if type(line_data) == "string" then
      line_text = line_data
    elseif type(line_data) == "table" then
      -- Extract text from virt_text structure
      for _, segment in ipairs(line_data) do
        if type(segment) == "table" and segment[1] then
          local text = segment[1]
          local hl = segment[2]
          
          -- Skip padding markers
          if text ~= "_pad_" then
            line_text = line_text .. text
            
            -- Store highlight info
            if hl then
              table.insert(highlights, {
                line = line_idx - 1,
                col_start = col_offset,
                col_end = col_offset + #text,
                hl_group = hl
              })
            end
            
            col_offset = col_offset + #text
          end
        end
      end
    end
    
    table.insert(lines, line_text)
  end
  
  -- Set buffer content
  api.nvim_buf_set_option(buf, "modifiable", true)
  api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  api.nvim_buf_set_option(buf, "modifiable", false)
  
  -- Apply highlights
  for _, hl_info in ipairs(highlights) do
    pcall(api.nvim_buf_set_extmark, buf, namespace, hl_info.line, hl_info.col_start, {
      end_col = hl_info.col_end,
      hl_group = hl_info.hl_group,
      priority = 50,
    })
  end
  
  -- Calculate dimensions
  local width = self.config.minimum_width
  for _, line in ipairs(lines) do
    width = math.max(width, api.nvim_strwidth(line))
  end
  
  return width, #lines
end

--- Show a notification
---@param notif Noti.Notification
---@return boolean success True if notification was shown
function Animator:show(notif)
  -- Create buffer
  local buf = api.nvim_create_buf(false, true)
  api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  api.nvim_buf_set_option(buf, "filetype", "noti")
  
  -- Render content to buffer
  local width, height = self:render_to_buffer(buf, notif)
  
  -- Respect max dimensions
  width = math.min(width, self.config.max_width())
  height = math.min(height, self.config.max_height())
  
  -- Find position
  local row, col = self:find_position(width, height)
  if not row then
    api.nvim_buf_delete(buf, { force = true })
    return false
  end
  
  -- Create window
  local win = api.nvim_open_win(buf, false, {
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
  
  -- Store window info
  self.windows[notif.id] = {
    win = win,
    buf = buf,
    notif = notif,
    row = row,
    col = col,
    stage = 1,
  }
  
  self.active[notif.id] = notif
  self.win_stages[win] = 1
  
  -- Call on_open callback
  if notif.on_open then
    pcall(notif.on_open, win)
  end
  if self.config.on_open then
    pcall(self.config.on_open, win, notif:to_record())
  end
  
  -- Start timeout timer
  if notif.timeout and notif.timeout > 0 then
    local timer = vim.loop.new_timer()
    timer:start(notif.timeout, 0, vim.schedule_wrap(function()
      timer:stop()
      timer:close()
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
    pcall(notif.on_close, win_info.win)
  end
  if self.config.on_close then
    pcall(self.config.on_close, win_info.win, notif:to_record())
  end
  
  -- Close window and delete buffer
  pcall(api.nvim_win_close, win_info.win, true)
  pcall(api.nvim_buf_delete, win_info.buf, { force = true })
  
  -- Clean up
  self.win_stages[win_info.win] = nil
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
  
  -- Re-render to same buffer
  local width, height = self:render_to_buffer(win_info.buf, new_notif)
  
  -- Update window size if needed
  width = math.min(width, self.config.max_width())
  height = math.min(height, self.config.max_height())
  
  if api.nvim_win_is_valid(win_info.win) then
    api.nvim_win_set_config(win_info.win, {
      relative = "editor",
      width = width,
      height = height,
      row = win_info.row,
      col = win_info.col,
    })
  end
  
  -- Update notification reference
  win_info.notif = new_notif
  self.active[old_id] = nil
  self.active[new_notif.id] = new_notif
  self.windows[new_notif.id] = win_info
  self.windows[old_id] = nil
  
  -- Reset timer if needed
  if win_info.timer then
    win_info.timer:stop()
    if new_notif.timeout and new_notif.timeout > 0 then
      win_info.timer:start(new_notif.timeout, 0, vim.schedule_wrap(function()
        win_info.timer:stop()
        win_info.timer:close()
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
  -- Clean up invalid windows
  for notif_id, win_info in pairs(self.windows) do
    if not api.nvim_win_is_valid(win_info.win) then
      self:close(notif_id)
    end
  end
  
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
