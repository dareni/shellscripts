-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Define a local function for setting keymaps for convenience
local function map(mode, lhs, rhs, opts)
  local options = { noremap = true, silent = true }
  if opts then
    options = vim.tbl_extend("force", options, opts)
  end
  vim.keymap.set(mode, lhs, rhs, options)
end

-- Function Key Mappings for Debugging (DAP)
-- Use 'n' mode for these, as they are typically used in Normal mode.

-- F5: Run/Continue (Start Debugging / Continue)
map("n", "<F5>", function()
  require("dap").continue()
end, { desc = "DAP: Run/Continue" })

-- F9: Toggle Breakpoint
map("n", "<F9>", function()
  require("dap").toggle_breakpoint()
end, { desc = "DAP: Toggle Breakpoint" })

-- F10: Step Over
map("n", "<F10>", function()
  require("dap").step_over()
end, { desc = "DAP: Step Over" })

-- F11: Step Into
map("n", "<F11>", function()
  require("dap").step_into()
end, { desc = "DAP: Step Into" })

-- F12: Step Out
map("n", "<F12>", function()
  require("dap").step_out()
end, { desc = "DAP: Step Out" })

-- Optional: Shift+F5 for Terminate
map("n", "<S-F5>", function()
  require("dap").terminate()
end, { desc = "DAP: Terminate" })

-- Optional: F8 for Toggling DAP UI
map("n", "<F8>", function()
  require("dapui").toggle({})
end, { desc = "DAP: Toggle UI" })

vim.api.nvim_create_autocmd("FileType", {
  pattern = "rust",
  callback = function(event)
    local wk = require("which-key")

    wk.add({
      -- Define the parent group prefix and its name
      { "<leader>cM", group = "Macro", mode = "n", buffer = event.buf },
      { "<leader>cL", group = "Rust LSP", mode = "n", buffer = event.buf },
      -- Define the macro mappings
      { "<leader>cMx", "<cmd>RustLsp expandMacro<CR>", desc = "Expand Macro", mode = "n", buffer = event.buf },
      { "<leader>cMr", "<cmd>RustLsp rebuildProcMacros<CR>", desc = "Rebuild Macro", mode = "n", buffer = event.buf },
      -- Define the lsp mappings
      { "<leader>cLr", "<cmd>LspInfo<CR>", desc = "Lsp Info", mode = "n", buffer = event.buf },
      { "<leader>cLl", "<cmd>RustLsp logFile<CR>", desc = "Lsp Log File", mode = "n", buffer = event.buf },
    })
  end,
})


-- Use the rust stack dump from a failed test for a jump to the source file.
-- Note: position the cursor on the line:column line in the dump.
vim.keymap.set("n", "gJ", function()
  -- 1. Get the current line (the path) and the line above it (the crate info)
  local line_num = vim.api.nvim_win_get_cursor(0)[1]
  local current_line = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)[1] or ""
  local above_line = ""
  if line_num > 1 then
    above_line = vim.api.nvim_buf_get_lines(0, line_num - 2, line_num - 1, false)[1] or ""
  end

  -- 2. Extract the file path, line, and column using regex
  -- Matches things like "./src/markup/discovery.rs:372:46"
  local path, line, col = current_line:match("(src/.-%.rs):(%d+):(%d+)")

  if not path then
    -- Fallback if the cursor is actually on the top line instead of the path line
    path, line, col = above_line:match("(src/.-%.rs):(%d+):(%d+)")
  end

  if path and line then
    -- 3. Determine  the crate name from the preceeding line (e.g., "wicket_macro::...")
    local crate = above_line:match("%d+:%s+([^:]+)")
    if crate then
      -- Normalize crate names (Rust uses underscores, but folders sometimes use dashes)
      crate = crate:gsub("_", "-")
      path = "crates/" .. crate .. "/" .. path
    end

    -- 4. Open the file and jump to the line/column
    local target_win = nil
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local buf = vim.api.nvim_win_get_buf(win)
      -- A regular file buffer has an empty buftype
      if vim.bo[buf].buftype == "" then
        target_win = win
        break
      end
    end

    -- Switch to the normal window (or split if none exists)
    if target_win then
      vim.api.nvim_set_current_win(target_win)
    else
      vim.cmd("vsplit")
    end

    -- 5. Open the file safely
    vim.cmd("edit " .. path)
    pcall(vim.api.nvim_win_set_cursor, 0, { tonumber(line), tonumber(col) - 1 })
    print("Jumped to workspace file: " .. path)
  else
    print("No Rust workspace path detected under cursor.")
  end
end, { desc = "Jump to Workspace from test Stack Trace" })
