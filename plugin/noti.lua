-- Plugin file structure:
--
-- noti/
-- ├── lua/
-- │   └── noti/
-- │       ├── init.lua              [Main entry point]
-- │       ├── config.lua            [Configuration management]
-- │       ├── animator.lua          [Window animation & positioning]
-- │       ├── history.lua           [History management]
-- │       ├── service/
-- │       │   ├── init.lua          [Notification service]
-- │       │   ├── notification.lua  [Notification class]
-- │       │   └── queue.lua         [FIFO queue]
-- │       └── render/
-- │           ├── init.lua          [Render dispatcher]
-- │           ├── default.lua       [Default renderer]
-- │           ├── minimal.lua       [Minimal renderer]
-- │           ├── compact.lua       [Compact renderer]
-- │           └── interactive.lua   [Interactive renderer]
-- ├── examples.lua                   [Usage examples]
-- ├── test/
-- │   └── noti_spec.lua             [Test suite]
-- ├── README.md                      [Documentation]
-- └── plugin/
--     └── noti.lua                   [Auto-setup file]

-- plugin/noti.lua
-- Auto-setup file for easy loading

if vim.g.loaded_noti then
  return
end
vim.g.loaded_noti = 1

-- Auto-setup with defaults if not already configured
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    -- Check if user has already set up noti
    if not package.loaded["noti"] then
      require("noti").setup()
    end
  end,
  once = true,
})

-- Create highlight groups
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    -- Ensure volt highlights are available
    pcall(require, "volt.highlights")
  end,
})
