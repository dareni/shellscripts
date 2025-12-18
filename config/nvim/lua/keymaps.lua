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
map("n", "<F5>", function() require("dap").continue() end, { desc = "DAP: Run/Continue" })

-- F9: Toggle Breakpoint
map("n", "<F9>", function() require("dap").toggle_breakpoint() end, { desc = "DAP: Toggle Breakpoint" })

-- F10: Step Over
map("n", "<F10>", function() require("dap").step_over() end, { desc = "DAP: Step Over" })

-- F11: Step Into
map("n", "<F11>", function() require("dap").step_into() end, { desc = "DAP: Step Into" })

-- F12: Step Out
map("n", "<F12>", function() require("dap").step_out() end, { desc = "DAP: Step Out" })

-- Optional: Shift+F5 for Terminate
map("n", "<S-F5>", function() require("dap").terminate() end, { desc = "DAP: Terminate" })

-- Optional: F8 for Toggling DAP UI
map("n", "<F8>", function() require("dapui").toggle({}) end, { desc = "DAP: Toggle UI" })
