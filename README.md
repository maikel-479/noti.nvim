# noti

A volt-powered notification manager for Neovim - a complete reimagining of nvim-notify built on the powerful [volt](https://github.com/NvChad/volt) UI framework.

## ✨ Features

### From nvim-notify
- 🔔 Beautiful floating notifications
- ⏱️ Configurable timeouts and persistence
- 📊 Multiple log levels (ERROR, WARN, INFO, DEBUG, TRACE)
- 📝 Notification history
- 🔄 Replace and update notifications
- 🔀 Automatic duplicate merging
- 🎨 Multiple built-in renderers
- ⚡ Async notification support
- 🎯 Custom callbacks (on_open, on_close)

### Enhanced with volt
- 🎮 **Interactive Notifications** - Clickable buttons and actions
- 📈 **Rich Components** - Progress bars, graphs, tables in notifications
- 🎨 **Advanced Layouts** - Grid-based layouts with hover effects
- 🖱️ **Mouse Support** - Full mouse interaction with notification elements
- 🎯 **Smart Positioning** - Intelligent window placement and stacking
- 🔧 **Component Library** - Checkboxes, sliders, tabs, and more
- 📊 **Data Visualization** - Built-in graphs for progress tracking
- 🎭 **Custom Renderers** - Easy to create with volt's component system

## 📦 Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "maikel-479/noti",
  dependencies = {
    "maikel-479/volt", -- Required: volt UI framework
    "nvim-lua/plenary.nvim", -- Optional: for async support
  },
  config = function()
    require("noti").setup({
      -- your configuration
    })
  end
}
```

## 🚀 Quick Start

### Basic Usage

```lua
-- Simple notification
require("noti")("Hello, world!")

-- With log level
require("noti")("Error occurred!", vim.log.levels.ERROR)

-- With options
require("noti")("Task completed", vim.log.levels.INFO, {
  title = "Success",
  icon = "",
  timeout = 3000,
})
```

### Replace vim.notify

```lua
-- Make all vim.notify calls use noti
vim.notify = require("noti")
```

### Interactive Notifications

```lua
require("noti")("Save changes?", vim.log.levels.WARN, {
  title = "Unsaved Changes",
  timeout = false,
  render = "interactive",
  actions = {
    {
      text = "Save",
      callback = function()
        vim.cmd("write")
        require("noti").info("File saved!")
      end,
      hl = "ExGreen",
    },
    {
      text = "Discard",
      callback = function()
        require("noti").warn("Changes discarded")
      end,
      hl = "ExRed",
    },
    {
      text = "Cancel",
      callback = function()
        require("noti").info("Cancelled")
      end,
    },
  },
})
```

### Progress Notifications

```lua
local id = require("noti")("Starting task...", vim.log.levels.INFO, {
  title = "Progress",
  timeout = false,
}).id

for i = 1, 10 do
  vim.defer_fn(function()
    require("noti")(string.format("Progress: %d%%", i * 10), vim.log.levels.INFO, {
      replace = id,
      timeout = i == 10 and 2000 or false,
    })
  end, i * 500)
end
```

## ⚙️ Configuration

```lua
require("noti").setup({
  -- Notification positioning
  top_down = true,              -- Stack from top to bottom
  offset = { x = 1, y = 1 },    -- Screen offset
  
  -- Appearance
  render = "default",            -- default|minimal|compact|interactive
  minimum_width = 50,
  max_width = nil,              -- nil = 80% of screen width
  max_height = nil,             -- nil = 80% of screen height
  
  -- Behavior
  level = vim.log.levels.INFO,  -- Minimum level to display
  timeout = 5000,               -- Default timeout in ms
  merge_duplicates = true,      -- Merge duplicate notifications
  fps = 30,                     -- Animation frame rate
  
  -- Icons per level
  icons = {
    ERROR = "",
    WARN = "",
    INFO = "",
    DEBUG = "",
    TRACE = "✎",
  },
  
  -- Colors (volt highlight groups)
  colors = {
    ERROR = "ExRed",
    WARN = "ExYellow",
    INFO = "ExBlue",
    DEBUG = "CommentFg",
    TRACE = "ExLightGrey",
  },
  
  -- Callbacks
  on_open = function(win, record)
    -- Called when notification opens
  end,
  on_close = function(win, record)
    -- Called when notification closes
  end,
  
  -- Time formats
  time_formats = {
    notification = "%H:%M:%S",
    history = "%Y-%m-%d %H:%M:%S",
  },
})
```

## 🎨 Renderers

### Built-in Renderers

#### Default
Full-featured renderer with title, separator, message, and actions.
```lua
require("noti")("Message", vim.log.levels.INFO, { render = "default" })
```

#### Minimal
Simple renderer showing just icon and message.
```lua
require("noti")("Message", vim.log.levels.INFO, { render = "minimal" })
```

#### Compact
Single-line format with icon, level badge, and message.
```lua
require("noti")("Message", vim.log.levels.INFO, { render = "compact" })
```

#### Interactive
Enhanced renderer with borders, actions, and volt components.
```lua
require("noti")("Message", vim.log.levels.INFO, { render = "interactive" })
```

### Custom Renderers

Create your own using volt's component system:

```lua
local function my_renderer(notif, config)
  local ui = require("volt.ui")
  local color = require("noti.config").get_color(config, notif.level)
  
  return {
    {
      { "┌─", color },
      { " " .. notif.icon .. " ", color },
      { notif.message[1], "Normal" },
      { " ─┐", color },
    },
    {
      { "└", color },
      { string.rep("─", 40), color },
      { "┘", color },
    },
  }
end

require("noti")("Message", vim.log.levels.INFO, {
  render = my_renderer
})
```

## 📜 Commands

| Command | Description |
|---------|-------------|
| `:Noti` | Show notification history |
| `:NotiClear` | Clear notification history |
| `:NotiDismiss` | Dismiss all visible notifications |

## 🔌 API

### Core Functions

#### `require("noti")(message, level, opts)`
Display a notification.

#### `require("noti").setup(config)`
Configure noti.

#### `require("noti").error(message, opts)`
Show error notification.

#### `require("noti").warn(message, opts)`
Show warning notification.

#### `require("noti").info(message, opts)`
Show info notification.

#### `require("noti").debug(message, opts)`
Show debug notification.

### History Management

#### `require("noti").get_history(opts)`
Get notification history.

#### `require("noti").clear_history()`
Clear all history.

#### `require("noti").show_history()`
Display history in a buffer.

### Dismissal

#### `require("noti").dismiss(opts)`
Dismiss visible notifications.

Options:
- `pending`: Also clear queued notifications
- `silent`: Don't show dismissal message

### Advanced

#### `require("noti").instance(config, inherit)`
Create a separate noti instance with custom config.

#### `require("noti").async(message, level, opts)`
Create an async notification (requires plenary).

## 🎯 Why noti over nvim-notify?

### 1. **Interactive Capabilities**
nvim-notify shows static notifications. noti allows clickable buttons, interactive elements, and user input directly in notifications.

### 2. **Rich Components**
Built on volt, noti can display progress bars, graphs, tables, tabs, and other complex UI elements in notifications.

### 3. **Better Layouts**
Volt's grid system enables sophisticated multi-column layouts and precise control over notification appearance.

### 4. **Mouse Support**
Full mouse interaction with notification elements - click buttons, hover for details, drag sliders.

### 5. **Modern Architecture**
Clean separation of concerns with volt handling UI while noti focuses on notification logic.

### 6. **Extensibility**
Easy to create custom renderers and components using volt's extensive component library.

### 7. **Performance**
Volt's efficient rendering system ensures smooth animations even with many notifications.

## 🔧 Advanced Examples

### Progress Bar Notification
```lua
local ui = require("volt.ui")

local function progress_renderer(notif, config)
  local progress = tonumber(notif.message[1]:match("%d+")) or 0
  
  return {
    {
      { notif.title[1] .. ": ", "Normal" },
      { tostring(progress) .. "%", "ExBlue" },
    },
    ui.progressbar({
      w = 40,
      val = progress,
      icon = { on = "█", off = "░" },
      hl = { on = "ExGreen", off = "CommentFg" },
    }),
  }
end

for i = 0, 100, 10 do
  vim.defer_fn(function()
    require("noti")(tostring(i), vim.log.levels.INFO, {
      title = "Downloading",
      render = progress_renderer,
      replace = 1,
      timeout = i == 100 and 2000 or false,
    })
  end, i * 100)
end
```

### Graph Notification
```lua
local ui = require("volt.ui")

local data = { 5, 7, 3, 8, 6, 9, 4 }

local function graph_renderer(notif, config)
  return ui.graphs.bar({
    val = data,
    baropts = {
      w = 3,
      gap = 1,
      hl = "ExBlue",
    },
    format_labels = function(val)
      return tostring(val)
    end,
    footer_label = { "Weekly Activity", "ExGreen" },
  })
end

require("noti")("", vim.log.levels.INFO, {
  title = "Statistics",
  render = graph_renderer,
  timeout = 10000,
})
```

### Tabbed Notification
```lua
local ui = require("volt.ui")

local function tabbed_renderer(notif, config)
  local active_tab = notif.message[1] or "Info"
  
  local tabs = ui.tabs({ "Info", "Details", "_pad_", "Logs" }, 40, {
    active = active_tab,
    hlon = "ExBlue",
    hloff = "CommentFg",
  })
  
  return vim.list_extend(tabs, {
    {},
    { { "Content for " .. active_tab, "Normal" } },
  })
end
```

## 📝 License

MIT

## 🙏 Acknowledgments

- [nvim-notify](https://github.com/rcarriga/nvim-notify) - Original inspiration and architecture
- [volt](https://github.com/maikel-479/volt) - Powerful UI framework that makes this possible
- [NvChad](https://github.com/NvChad) - For creating volt and the beautiful UI components

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
