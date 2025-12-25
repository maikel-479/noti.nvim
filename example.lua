-- examples.lua
-- Usage examples for noti plugin

-- Basic setup
require("noti").setup({
  -- Position notifications at the top
  top_down = true,
  
  -- Use interactive renderer by default
  render = "default",
  
  -- Timeout in milliseconds
  timeout = 5000,
  
  -- Merge duplicate notifications
  merge_duplicates = true,
  
  -- Custom icons
  icons = {
    ERROR = "",
    WARN = "",
    INFO = "",
    DEBUG = "",
    TRACE = "✎",
  },
})

-- 1. Simple notification
require("noti")("Hello, world!")

-- 2. Notification with level
require("noti")("This is an error", vim.log.levels.ERROR)

-- 3. Notification with options
require("noti")("Task completed", vim.log.levels.INFO, {
  title = "Success",
  icon = "",
  timeout = 3000,
})

-- 4. Convenience functions
require("noti").error("Something went wrong!")
require("noti").warn("Warning message")
require("noti").info("Information")
require("noti").debug("Debug info")

-- 5. Interactive notification with actions
require("noti")("Do you want to continue?", vim.log.levels.WARN, {
  title = "Confirmation",
  timeout = false, -- No timeout
  render = "interactive",
  actions = {
    {
      text = "Yes",
      callback = function()
        print("User clicked Yes")
        require("noti").info("Continuing...")
      end,
      hl = "ExGreen",
    },
    {
      text = "No",
      callback = function()
        print("User clicked No")
        require("noti").info("Cancelled")
      end,
      hl = "ExRed",
    },
  },
})

-- 6. Notification with custom renderer
require("noti")("Custom styled message", vim.log.levels.INFO, {
  render = function(notif, config)
    -- Return volt-style lines
    return {
      {
        { "★ ", "ExYellow" },
        { notif.message[1], "Normal" },
        { " ★", "ExYellow" },
      }
    }
  end,
})

-- 7. Progress notification (update it over time)
local progress_id = require("noti")("Loading: 0%", vim.log.levels.INFO, {
  title = "Progress",
  timeout = false,
}).id

-- Update progress
for i = 1, 10 do
  vim.defer_fn(function()
    require("noti")(string.format("Loading: %d%%", i * 10), vim.log.levels.INFO, {
      title = "Progress",
      replace = progress_id,
      timeout = i == 10 and 2000 or false,
    })
  end, i * 500)
end

-- 8. Multi-line notification
require("noti")({
  "This is a multi-line notification",
  "It can contain multiple lines",
  "And will be properly formatted",
}, vim.log.levels.INFO, {
  title = "Multi-line Example",
})

-- 9. Notification that stays open
require("noti")("This message stays visible", vim.log.levels.WARN, {
  timeout = 10000,
  keep = function()
    -- Keep visible if user is in insert mode
    return vim.api.nvim_get_mode().mode == "i"
  end,
})

-- 10. Async notification (requires plenary)
local async = require("plenary.async")
async.run(function()
  local notif = require("noti").async("Waiting for input...", vim.log.levels.INFO, {
    timeout = false,
  })
  
  -- Wait for notification to open
  notif.events.open()
  print("Notification opened!")
  
  -- Do some work...
  async.util.sleep(2000)
  
  -- Update notification
  require("noti")("Work completed!", vim.log.levels.INFO, {
    replace = notif.id,
    timeout = 2000,
  })
end)

-- 11. History commands
-- Show history in a buffer
vim.cmd("Noti")

-- Clear history
vim.cmd("NotiClear")

-- Dismiss all visible notifications
vim.cmd("NotiDismiss")

-- 12. Programmatic history access
local history = require("noti").get_history()
for _, record in ipairs(history) do
  print(string.format("[%s] %s: %s", 
    vim.fn.strftime("%H:%M:%S", record.time),
    record.level,
    table.concat(record.message, " ")))
end

-- 13. Replace vim.notify
vim.notify = require("noti")

-- Now all plugins using vim.notify will use noti
vim.cmd("echo 'test'") -- Will use noti

-- 14. Create custom instance with different config
local custom_noti = require("noti").instance({
  render = "minimal",
  top_down = false,
  timeout = 2000,
})

-- Use custom instance
custom_noti("This uses custom config", vim.log.levels.INFO)

-- 15. Notification with callbacks
require("noti")("Opening...", vim.log.levels.INFO, {
  on_open = function(win)
    print("Notification window opened:", win)
  end,
  on_close = function(win)
    print("Notification window closed:", win)
  end,
})

-- 16. Using different renderers
require("noti")("Default style", vim.log.levels.INFO, { render = "default" })
require("noti")("Minimal style", vim.log.levels.INFO, { render = "minimal" })
require("noti")("Compact style", vim.log.levels.INFO, { render = "compact" })
require("noti")("Interactive style", vim.log.levels.INFO, { render = "interactive" })
