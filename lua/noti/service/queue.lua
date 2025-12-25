-- lua/noti/service/queue.lua
-- Simple FIFO queue implementation

---@class Noti.Queue
---@field items table Items storage
---@field head number Head index
---@field tail number Tail index
local Queue = {}
Queue.__index = Queue

--- Create a new queue
---@return Noti.Queue
function Queue.new()
  return setmetatable({
    items = {},
    head = 0,
    tail = -1,
  }, Queue)
end

--- Add item to queue
---@param item any Item to add
function Queue:enqueue(item)
  self.tail = self.tail + 1
  self.items[self.tail] = item
end

--- Remove and return first item
---@return any|nil
function Queue:dequeue()
  if self:is_empty() then
    return nil
  end
  
  local item = self.items[self.head]
  self.items[self.head] = nil
  self.head = self.head + 1
  
  return item
end

--- Get first item without removing
---@return any|nil
function Queue:peek()
  if self:is_empty() then
    return nil
  end
  return self.items[self.head]
end

--- Check if queue is empty
---@return boolean
function Queue:is_empty()
  return self.head > self.tail
end

--- Get queue size
---@return number
function Queue:size()
  return self.tail - self.head + 1
end

--- Clear the queue
function Queue:clear()
  self.items = {}
  self.head = 0
  self.tail = -1
end

return Queue
