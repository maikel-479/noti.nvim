-- lua/noti/service/init.lua (FIXED)
-- Notification service management without Volt dependency

local Notification = require("noti.service.notification")
local Queue = require("noti.service.queue")
local Animator = require("noti.animator")
local history = require("noti.history")

---@class Noti.Service
---@field config table Configuration
---@field notifications table<number, Noti.Notification> All notifications
---@field queue Noti.Queue Pending notifications
---@field animator Noti.Animator Window animator
---@field running boolean Service running state
---@field fps number Frames per second
local Service = {}
Service.__index = Service

--- Create a new notification service
---@param config table Configuration
---@return Noti.Service
function Service.new(config)
  local self = setmetatable({
    config = config,
    notifications = {},
    queue = Queue.new(),
    animator = Animator.new(config),
    running = false,
    fps = config.fps or 30,
  }, Service)
  
  return self
end

--- Start the service loop
function Service:start()
  if self.running then
    return
  end
  
  self.running = true
  self:tick()
end

--- Service tick (called at FPS rate)
function Service:tick()
  if not self.running then
    return
  end
  
  -- Process pending notifications
  while not self.queue:is_empty() do
    local notif = self.queue:peek()
    
    -- Try to create window for notification
    local success = pcall(function()
      return self.animator:show(notif)
    end)
    
    if success then
      self.queue:dequeue()
    else
      -- No more space or error, wait for next tick
      break
    end
  end
  
  -- Update animator
  local has_active = self.animator:update()
  
  -- Schedule next tick if there's work to do
  if has_active or not self.queue:is_empty() then
    vim.defer_fn(function()
      self:tick()
    end, math.floor(1000 / self.fps))
  else
    self.running = false
  end
end

--- Add a notification
---@param message string|string[] Message
---@param level string|number Log level
---@param opts table Options
---@return Noti.Record
function Service:notify(message, level, opts)
  -- Create notification
  local id = #self.notifications + 1
  local notif = Notification.new(id, message, level, opts, self.config)
  
  -- Store notification
  self.notifications[id] = notif
  
  -- Add to history if not hidden
  if not notif.hide_from_history then
    history.add(notif:to_record())
  end
  
  -- Check for replacement
  if opts.replace then
    local replace_id = type(opts.replace) == "table" and opts.replace.id or opts.replace
    local existing = self.notifications[replace_id]
    
    if existing then
      -- Inherit options from existing if not specified
      if not opts.title then notif.title = existing.title end
      if not opts.icon then notif.icon = existing.icon end
      if opts.timeout == nil then notif.timeout = existing.timeout end
      
      -- Replace in animator
      pcall(self.animator.replace, self.animator, replace_id, notif)
      return notif:to_record()
    end
  end
  
  -- Check for duplicates
  if self.config.merge_duplicates and not opts.replace then
    local duplicate = self:find_duplicate(notif)
    
    if duplicate then
      -- Track duplicates
      duplicate.duplicates = duplicate.duplicates or { duplicate.id }
      table.insert(duplicate.duplicates, notif.id)
      notif.duplicates = duplicate.duplicates
      
      -- Check if we should merge
      local min_dups = type(self.config.merge_duplicates) == "number" 
        and self.config.merge_duplicates or 2
      
      if #notif.duplicates >= min_dups then
        pcall(self.animator.replace, self.animator, duplicate.id, notif)
        return notif:to_record()
      end
    end
  end
  
  -- Check level threshold
  local level_num = vim.log.levels[notif.level] or vim.log.levels.INFO
  if level_num < self.config.level then
    return notif:to_record()
  end
  
  -- Queue notification
  self.queue:enqueue(notif)
  self:start()
  
  return notif:to_record()
end

--- Find a duplicate notification
---@param notif Noti.Notification
---@return Noti.Notification?
function Service:find_duplicate(notif)
  for _, existing in pairs(self.animator.active) do
    if existing and existing:equals(notif) then
      return existing
    end
  end
  return nil
end

--- Dismiss all visible notifications
---@param opts table Options
function Service:dismiss(opts)
  opts = opts or {}
  
  -- Close all active windows
  pcall(self.animator.dismiss_all, self.animator)
  
  -- Clear queue if requested
  if opts.pending then
    local count = 0
    while not self.queue:is_empty() do
      self.queue:dequeue()
      count = count + 1
    end
    
    if not opts.silent and count > 0 then
      vim.notify(string.format("Dismissed %d pending notifications", count))
    end
  end
end

return Service
