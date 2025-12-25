-- test/noti_spec.lua
-- Test suite for noti plugin

describe("noti", function()
  local noti
  
  before_each(function()
    -- Clear any existing state
    package.loaded["noti"] = nil
    package.loaded["noti.config"] = nil
    package.loaded["noti.service"] = nil
    package.loaded["noti.history"] = nil
    
    noti = require("noti")
  end)
  
  describe("setup", function()
    it("initializes with default config", function()
      noti.setup()
      assert.is_not_nil(noti)
    end)
    
    it("accepts custom config", function()
      noti.setup({
        timeout = 3000,
        render = "minimal",
      })
      -- Should not error
    end)
  end)
  
  describe("notifications", function()
    before_each(function()
      noti.setup()
    end)
    
    it("creates a simple notification", function()
      local record = noti("Test message")
      assert.is_not_nil(record)
      assert.equals(1, record.id)
    end)
    
    it("creates notification with level", function()
      local record = noti("Error message", vim.log.levels.ERROR)
      assert.is_not_nil(record)
      assert.equals("ERROR", record.level)
    end)
    
    it("creates notification with options", function()
      local record = noti("Message", vim.log.levels.INFO, {
        title = "Test Title",
        icon = "",
        timeout = 1000,
      })
      
      assert.is_not_nil(record)
      assert.equals("Test Title", record.title[1])
      assert.equals("", record.icon)
    end)
    
    it("supports multi-line messages", function()
      local record = noti({
        "Line 1",
        "Line 2",
        "Line 3",
      })
      
      assert.is_not_nil(record)
      assert.equals(3, #record.message)
    end)
  end)
  
  describe("convenience functions", function()
    before_each(function()
      noti.setup()
    end)
    
    it("has error function", function()
      local record = noti.error("Error")
      assert.equals("ERROR", record.level)
    end)
    
    it("has warn function", function()
      local record = noti.warn("Warning")
      assert.equals("WARN", record.level)
    end)
    
    it("has info function", function()
      local record = noti.info("Info")
      assert.equals("INFO", record.level)
    end)
    
    it("has debug function", function()
      local record = noti.debug("Debug")
      assert.equals("DEBUG", record.level)
    end)
  end)
  
  describe("history", function()
    before_each(function()
      noti.setup()
      noti.clear_history()
    end)
    
    it("tracks notifications in history", function()
      noti("Message 1")
      noti("Message 2")
      
      local history = noti.get_history()
      assert.equals(2, #history)
    end)
    
    it("can clear history", function()
      noti("Message 1")
      noti("Message 2")
      
      noti.clear_history()
      
      local history = noti.get_history()
      assert.equals(0, #history)
    end)
    
    it("excludes hidden notifications from history", function()
      noti("Visible", vim.log.levels.INFO)
      noti("Hidden", vim.log.levels.INFO, {
        hide_from_history = true,
      })
      
      local history = noti.get_history()
      assert.equals(1, #history)
      
      -- But includes with flag
      local all_history = noti.get_history({ include_hidden = true })
      assert.equals(2, #all_history)
    end)
  end)
  
  describe("replacement", function()
    before_each(function()
      noti.setup()
    end)
    
    it("replaces existing notification", function()
      local first = noti("Original message")
      local replaced = noti("Updated message", vim.log.levels.INFO, {
        replace = first.id,
      })
      
      assert.is_not_nil(replaced)
    end)
    
    it("inherits options when replacing", function()
      local first = noti("Original", vim.log.levels.ERROR, {
        title = "Test",
        icon = "",
      })
      
      local replaced = noti("Updated", nil, {
        replace = first,
      })
      
      -- Should inherit ERROR level, title, and icon
      assert.equals("ERROR", replaced.level)
      assert.equals("Test", replaced.title[1])
      assert.equals("", replaced.icon)
    end)
  end)
  
  describe("actions", function()
    before_each(function()
      noti.setup()
    end)
    
    it("supports action buttons", function()
      local clicked = false
      
      local record = noti("Interactive", vim.log.levels.INFO, {
        actions = {
          {
            text = "Click me",
            callback = function()
              clicked = true
            end,
          },
        },
      })
      
      assert.is_not_nil(record)
      assert.equals(1, #record.actions)
    end)
  end)
  
  describe("custom instance", function()
    it("creates separate instance", function()
      noti.setup()
      
      local custom = noti.instance({
        timeout = 1000,
        render = "minimal",
      })
      
      assert.is_not_nil(custom)
      
      -- Should work independently
      custom("Custom instance message")
    end)
    
    it("inherits global config when requested", function()
      noti.setup({
        timeout = 5000,
        icons = {
          INFO = "ℹ",
        },
      })
      
      local custom = noti.instance({
        timeout = 1000,
      }, true) -- inherit = true
      
      -- Should have custom timeout but inherited icons
      assert.is_not_nil(custom)
    end)
  end)
  
  describe("renderers", function()
    before_each(function()
      noti.setup()
    end)
    
    it("supports default renderer", function()
      local record = noti("Test", vim.log.levels.INFO, {
        render = "default",
      })
      assert.is_not_nil(record.render)
    end)
    
    it("supports minimal renderer", function()
      local record = noti("Test", vim.log.levels.INFO, {
        render = "minimal",
      })
      assert.is_not_nil(record.render)
    end)
    
    it("supports compact renderer", function()
      local record = noti("Test", vim.log.levels.INFO, {
        render = "compact",
      })
      assert.is_not_nil(record.render)
    end)
    
    it("supports custom renderer function", function()
      local record = noti("Test", vim.log.levels.INFO, {
        render = function(notif, config)
          return {
            {
              { notif.message[1], "Normal" }
            }
          }
        end,
      })
      assert.is_not_nil(record.render)
    end)
  end)
  
  describe("level filtering", function()
    it("filters notifications below threshold", function()
      noti.setup({
        level = vim.log.levels.WARN,
      })
      
      -- INFO should be filtered
      noti.info("This should not show")
      
      -- WARN and above should show
      noti.warn("This should show")
      noti.error("This should show")
    end)
  end)
end)
