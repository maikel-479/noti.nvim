-- showcase.lua
-- Advanced showcase demonstrating noti's volt-powered features

local noti = require("noti")
local ui = require("volt.ui")

-- Setup noti with custom config
noti.setup({
  render = "interactive",
  timeout = 5000,
  top_down = true,
})

-- Demo 1: File Operation Confirmation
local function file_operation_demo()
  noti("Unsaved changes detected!", vim.log.levels.WARN, {
    title = "File Modified",
    icon = "󰈸",
    timeout = false,
    actions = {
      {
        text = "Save & Exit",
        callback = function()
          vim.cmd("write")
          noti.info("File saved successfully!")
          vim.defer_fn(function()
            vim.cmd("quit")
          end, 1000)
        end,
        hl = "ExGreen",
      },
      {
        text = "Discard & Exit",
        callback = function()
          noti.warn("Changes discarded")
          vim.cmd("quit!")
        end,
        hl = "ExRed",
      },
      {
        text = "Cancel",
        callback = function()
          noti.info("Operation cancelled")
        end,
        hl = "ExYellow",
      },
    },
  })
end

-- Demo 2: Download Progress with Bar
local function download_progress_demo()
  local id
  
  local function progress_renderer(notif, config)
    local progress = tonumber(notif.message[1]) or 0
    local color = require("noti.config").get_color(config, notif.level)
    
    return {
      {
        { "📥 ", color },
        { "Downloading file.zip", "Normal" },
        { "_pad_" },
        { string.format("%d%%", progress), "ExBlue" },
      },
      ui.progressbar({
        w = 40,
        val = progress,
        icon = { on = "█", off = "░" },
        hl = { on = "ExGreen", off = "CommentFg" },
      }),
      {
        { string.format("%.1f MB / 10.0 MB", progress / 10), "CommentFg" },
      },
    }
  end
  
  -- Simulate download
  for i = 0, 100, 5 do
    vim.defer_fn(function()
      if i == 0 then
        local record = noti(tostring(i), vim.log.levels.INFO, {
          title = "Download",
          render = progress_renderer,
          timeout = false,
        })
        id = record.id
      else
        noti(tostring(i), vim.log.levels.INFO, {
          render = progress_renderer,
          replace = id,
          timeout = i == 100 and 3000 or false,
        })
        
        if i == 100 then
          vim.defer_fn(function()
            noti("Download complete! ✓", vim.log.levels.INFO, {
              title = "Success",
              icon = "",
            })
          end, 3000)
        end
      end
    end, i * 50)
  end
end

-- Demo 3: Git Status Display
local function git_status_demo()
  local function git_renderer(notif, config)
    return {
      {
        { "┌─ ", "ExGreen" },
        { " Git Status", "Normal" },
        { " ", "Normal" },
        { "_pad_" },
        { "master ─┐", "ExGreen" },
      },
      {
        { "│ ", "ExGreen" },
        { "● ", "ExGreen" },
        { "3 files modified", "Normal" },
        { "_pad_" },
        { "│", "ExGreen" },
      },
      {
        { "│ ", "ExGreen" },
        { "✚ ", "ExBlue" },
        { "2 files staged", "Normal" },
        { "_pad_" },
        { "│", "ExGreen" },
      },
      {
        { "│ ", "ExGreen" },
        { "✖ ", "ExRed" },
        { "1 file deleted", "Normal" },
        { "_pad_" },
        { "│", "ExGreen" },
      },
      {
        { "├", "ExGreen" },
        { "─", "ExGreen" },
        { "_pad_" },
        { "─┤", "ExGreen" },
      },
      {
        { "│ ", "ExGreen" },
        { "[C]ommit", "ExBlue" },
        function()
          noti.info("Opening commit dialog...")
        end,
        { " ", "Normal" },
        { "[P]ush", "ExBlue" },
        function()
          noti.info("Pushing changes...")
        end,
        { "_pad_" },
        { "│", "ExGreen" },
      },
      {
        { "└", "ExGreen" },
        { "─", "ExGreen" },
        { "_pad_" },
        { "─┘", "ExGreen" },
      },
    }
  end
  
  -- Make lines proper width
  local lines = git_renderer()
  for i, line in ipairs(lines) do
    lines[i] = ui.hpad(line, 50)
  end
  
  noti("", vim.log.levels.INFO, {
    render = function() return lines end,
    timeout = false,
  })
end

-- Demo 4: Code Metrics Graph
local function code_metrics_demo()
  local data = { 3, 5, 7, 4, 8, 6, 9, 7, 8 }
  
  local function metrics_renderer(notif, config)
    local graph = ui.graphs.bar({
      val = data,
      baropts = {
        w = 3,
        gap = 1,
        format_hl = function(val)
          if val < 40 then
            return "ExRed"
          elseif val < 70 then
            return "ExYellow"
          else
            return "ExGreen"
          end
        end,
      },
      format_labels = function(val)
        return tostring(val) .. "%"
      end,
      footer_label = { "Code Coverage (Last 9 Days)", "ExBlue" },
    })
    
    return graph
  end
  
  noti("", vim.log.levels.INFO, {
    title = "Metrics",
    render = metrics_renderer,
    timeout = 10000,
  })
end

-- Demo 5: Build Status with Steps
local function build_status_demo()
  local steps = {
    { name = "Compile", status = "done" },
    { name = "Test", status = "running" },
    { name = "Package", status = "pending" },
    { name = "Deploy", status = "pending" },
  }
  
  local id
  
  local function build_renderer()
    local lines = {
      {
        { "🔨 ", "ExBlue" },
        { "Build Pipeline", "Normal" },
      },
      {
        { string.rep("─", 40), "CommentFg" },
      },
    }
    
    for _, step in ipairs(steps) do
      local icon, hl
      if step.status == "done" then
        icon, hl = "✓", "ExGreen"
      elseif step.status == "running" then
        icon, hl = "⟳", "ExYellow"
      elseif step.status == "failed" then
        icon, hl = "✗", "ExRed"
      else
        icon, hl = "○", "CommentFg"
      end
      
      table.insert(lines, {
        { " " .. icon .. " ", hl },
        { step.name, "Normal" },
      })
    end
    
    return lines
  end
  
  -- Initial render
  local record = noti("", vim.log.levels.INFO, {
    title = "Building",
    render = build_renderer,
    timeout = false,
  })
  id = record.id
  
  -- Simulate build progress
  vim.defer_fn(function()
    steps[2].status = "done"
    steps[3].status = "running"
    noti("", vim.log.levels.INFO, {
      render = build_renderer,
      replace = id,
      timeout = false,
    })
  end, 2000)
  
  vim.defer_fn(function()
    steps[3].status = "done"
    steps[4].status = "running"
    noti("", vim.log.levels.INFO, {
      render = build_renderer,
      replace = id,
      timeout = false,
    })
  end, 4000)
  
  vim.defer_fn(function()
    steps[4].status = "done"
    noti("", vim.log.levels.INFO, {
      render = build_renderer,
      replace = id,
      timeout = 3000,
    })
    
    vim.defer_fn(function()
      noti("Build completed successfully! 🎉", vim.log.levels.INFO, {
        title = "Success",
        icon = "",
      })
    end, 3000)
  end, 6000)
end

-- Demo 6: LSP Diagnostics Summary
local function lsp_diagnostics_demo()
  local function diagnostics_renderer(notif, config)
    return {
      {
        { "󰙨 ", "ExBlue" },
        { "LSP Diagnostics", "Normal" },
      },
      {
        { string.rep("─", 40), "CommentFg" },
      },
      {
        { "  ", "Normal" },
        { "3", "ExRed" },
        { " Errors  ", "Normal" },
        { "█████░░░░░", "ExRed" },
      },
      {
        { "  ", "Normal" },
        { "7", "ExYellow" },
        { " Warnings", "Normal" },
        { "███████░░░", "ExYellow" },
      },
      {
        { "  ", "Normal" },
        { "2", "ExBlue" },
        { " Info    ", "Normal" },
        { "██░░░░░░░░", "ExBlue" },
      },
      {},
      {
        { "[V]iew Details", "ExBlue" },
        function()
          vim.cmd("TroubleToggle")
        end,
        { " ", "Normal" },
        { "[F]ix All", "ExGreen" },
        function()
          vim.lsp.buf.code_action()
        end,
      },
    }
  end
  
  noti("", vim.log.levels.WARN, {
    render = diagnostics_renderer,
    timeout = 8000,
  })
end

-- Demo Menu
local function show_menu()
  noti("Choose a demo:", vim.log.levels.INFO, {
    title = "Noti Showcase",
    icon = "🎭",
    timeout = false,
    render = "interactive",
    actions = {
      {
        text = "File Operation",
        callback = file_operation_demo,
      },
      {
        text = "Download Progress",
        callback = download_progress_demo,
      },
      {
        text = "Git Status",
        callback = git_status_demo,
      },
      {
        text = "Code Metrics",
        callback = code_metrics_demo,
      },
      {
        text = "Build Pipeline",
        callback = build_status_demo,
      },
      {
        text = "LSP Diagnostics",
        callback = lsp_diagnostics_demo,
      },
    },
  })
end

-- Command to run showcase
vim.api.nvim_create_user_command("NotiShowcase", show_menu, {
  desc = "Show noti feature showcase"
})

-- Auto-run on load (optional)
-- show_menu()

return {
  show_menu = show_menu,
  file_operation = file_operation_demo,
  download_progress = download_progress_demo,
  git_status = git_status_demo,
  code_metrics = code_metrics_demo,
  build_status = build_status_demo,
  lsp_diagnostics = lsp_diagnostics_demo,
}
