-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- shellscripts/config/nvim/lua/keymaps.lua

-------------------------------------------------------------------------------
local function sum_visual_column()
  -- Ensure we exit visual mode first so '< and '> marks are properly updated
  vim.cmd([[noautocmd silent normal! gv]])

  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")

  local start_line = start_pos[2]
  local end_line = end_pos[2]

  -- Visual block columns are 1-indexed byte offsets
  local start_col = math.min(start_pos[3], end_pos[3])
  local end_col = math.max(start_pos[3], end_pos[3])

  local total = 0
  local count = 0

  -- Loop through each line in the visual block range
  for line_num = start_line, end_line do
    local line_text = vim.fn.getline(line_num)

    -- Extract the substring corresponding to the selected column block
    -- Note: We use vim.fn.strdisplaywidth or simple safe substring handling
    local sub_text = line_text:sub(start_col, end_col)

    -- Find any number (including decimals and negative signs) in that column slice
    local num_str = sub_text:match("([%-%d%.]+)")
    if num_str then
      local val = tonumber(num_str)
      if val then
        total = total + val
        count = count + 1
      end
    end
  end

  -- Print the result and copy it to the unnamed register so you can paste it with 'p'
  local result_str = tostring(total)
  -- In Lua, string conversion:
  result_str = tostring(total)
  vim.fn.setreg('"', result_str)
  vim.notify(string.format("Sum: %s (from %d numbers)", result_str, count), vim.log.levels.INFO)
end

-------------------------------------------------------------------------------
local function resolve_stack_path(path)
  print("resolve_stack_path:" .. path)
  -- 1. Handle Rust standard library paths (/rustc/<hash>/...)
  if path:match("^/rustc/") then
    local sysroot = vim.fn.trim(vim.fn.system("rustc --print sysroot"))
    if vim.v.shell_error == 0 and sysroot ~= "" then
      local local_path = path:gsub("^/rustc/[a-f0-9]+", sysroot .. "/lib/rustlib/src/rust")
      print("rustcPath:" .. local_path)
      if vim.fn.filereadable(local_path) == 1 then
        return local_path
      end
    end
  end

  -- 2. Handle Cargo registry dependency paths (.cargo/registry/src/...)
  if path:match("%.cargo/registry/src/") then
    -- Extract everything after .cargo/registry/src/
    local relative_part = path:match(".+%.cargo/registry/src/(.+)")
    print("relative_part:" .. relative_part)
    if relative_part then
      -- Determine local cargo home (respects CARGO_HOME env var or defaults to ~/.cargo)
      local cargo_home = os.getenv("CARGO_HOME") or (vim.fn.expand("$HOME") .. "/.cargo")
      local local_path = cargo_home .. "/registry/src/" .. relative_part
      print("cargo dep:" .. local_path)
      if vim.fn.filereadable(local_path) == 1 then
        return local_path
      end
    end
  end

  -- 3. Fallback to original path (for your own project files)
  return path
end

-------------------------------------------------------------------------------
-- Use the rust stack dump from a failed test for a jump to the source file.
-- Note: position the cursor on the line:column line in the dump.
local function jump_from_rust_stack_trace(event)
  -- 1. Get the current line (the path) and the line above it (the crate info)
  local line_num = vim.api.nvim_win_get_cursor(0)[1]
  local current_line = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)[1] or ""
  local above_line = ""
  if line_num > 1 then
    above_line = vim.api.nvim_buf_get_lines(0, line_num - 2, line_num - 1, false)[1] or ""
  end

  -- 2. Extract the file path, line, and column using regex
  -- Matches things like "./src/markup/discovery.rs:372:46"
  -- local path, line, col = current_line:match("(src/.-%.rs):(%d+):(%d+)")
  local path, line, col = current_line:match("at (.-%.rs):(%d+):(%d+)")

  if not path then
    -- Fallback if the cursor is actually on the top line instead of the path line
    path, line, col = above_line:match("at (.-%.rs):(%d+):(%d+)")
  end
  if path and line then
    local resolved_path = resolve_stack_path(path)
    if resolved_path == path then
      -- not std or external crate
      if vim.fn.filereadable(resolved_path) ~= 1 then
        -- 3. Determine  the crate name from the preceeding line (e.g., "wicket_macro::...")
        local crate = above_line:match("%d+:%s+([^:]+)")
        if crate then
          -- Normalize crate names (Rust uses underscores, but folders sometimes use dashes)
          crate = crate:gsub("_", "-")
          resolved_path = "crates/" .. crate .. "/" .. path
        end
      end
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
    vim.cmd("edit " .. resolved_path)
    pcall(vim.api.nvim_win_set_cursor, 0, { tonumber(line), tonumber(col) - 1 })
    print("Jumped to workspace file: " .. resolved_path)
  else
    print("No Rust workspace path detected under cursor.")
  end
end

-------------------------------------------------------------------------------
-- Generic key bindings -------------------------------------------------------
local wk = require("which-key")
wk.add({
  { "<leader>m", group = "Misc Custom Binds", mode = { "n", "v" } },
  { "<leader>mc", group = "code" },
  { "<leader>md", group = "debug" },
  { "<leader>mn", "<cmd>NoiceAll<cr>", desc = "Noice" },
  { "<leader>mt", "<cmd>terminal<cr>", desc = "Terminal (mode: ctrl-\\ n)" },
  { "<leader>ms", sum_visual_column, desc = "sum column to register", mode = "v" },
  {
    "<leader>mk",
    function()
      local key = vim.fn.getcharstr()
      print("keytrans:", vim.fn.keytrans(key), " inspect:", vim.inspect(key))
    end,
    desc = "Print next entered key",
    mode = "n",
  },
})

-------------------------------------------------------------------------------
--- Source file jump, from rust-trouble-test stacktrace buffer.
vim.api.nvim_create_autocmd("FileType", {
  pattern = "trouble",
  callback = function(event)
    wk.add({
      {
        "<leader>mJ",
        function()
          jump_from_rust_stack_trace(event)
        end,
        desc = "Jump to Workspace from test Stack Trace",
        mode = "n",
        buffer = event.buf,
      },
    })
  end,
})

-------------------------------------------------------------------------------
-- Rust lang specific bindings ------------------------------------------------
vim.api.nvim_create_autocmd("FileType", {
  pattern = "rust",
  callback = function(event)
    wk.add({
      -- Define the parent group prefix and its name
      { "<leader>mcM", group = "Rust Macro", mode = "n", buffer = event.buf },
      { "<leader>mcL", group = "Rust LSP", mode = "n", buffer = event.buf },
      -- Define the macro mappings
      { "<leader>mcMx", "<cmd>RustLsp expandMacro<CR>", desc = "Expand Macro", mode = "n", buffer = event.buf },
      {
        "<leader>mcMr",
        "<cmd>RustLsp rebuildProcMacros<CR>",
        desc = "Rebuild Macro",
        mode = "n",
        buffer = event.buf,
      },
      -- Define the lsp mappings
      { "<leader>mcLr", "<cmd>LspInfo<CR>", desc = "Lsp Info", mode = "n", buffer = event.buf },
      { "<leader>mcLl", "<cmd>RustLsp logFile<CR>", desc = "Lsp Log File", mode = "n", buffer = event.buf },
    })
  end,
})

-------------------------------------------------------------------------------
-- Function Key Mappings for Debugging (DAP)
-- Use 'n' mode for these, as they are typically used in Normal mode.
-- The function key bounds are also duplicated by which-key binds below.

-- F5: Run/Continue (Start Debugging / Continue)
vim.keymap.set("n", "<F5>", function()
  require("dap").continue()
end, { desc = "DAP: Run/Continue" })

-- F9: Toggle Breakpoint
vim.keymap.set("n", "<F9>", function()
  require("dap").toggle_breakpoint()
end, { desc = "DAP: Toggle Breakpoint" })

-- F10: Step Over
vim.keymap.set("n", "<F10>", function()
  require("dap").step_over()
end, { desc = "DAP: Step Over" })

-- F11: Step Into
vim.keymap.set("n", "<F11>", function()
  require("dap").step_into()
end, { desc = "DAP: Step Into" })

-- F12: Step Out
vim.keymap.set("n", "<F12>", function()
  require("dap").step_out()
end, { desc = "DAP: Step Out" })

-- S-F5: terminate
vim.keymap.set("n", "<F17>", function()
  require("dap").terminate()
  require("dapui").close()
end, { desc = "Terminate Debugger (Shift-F5)" })

-- F8 for Toggling DAP UI
vim.keymap.set("n", "<F8>", function()
  require("dapui").toggle({})
end, { desc = "DAP: Toggle UI" })

-- Debug binds repeated here and bound by which-key
wk.add({
  {
    "<leader>mdc",
    function()
      require("dap").continue()
    end,
    desc = "<F5> DAP: Run/Continue",
    mode = "n",
  },
  {
    "<leader>mdb",
    function()
      require("dap").toggle_breakpoint()
    end,
    desc = "<F9> DAP: Toggle Breakpoint",
    mode = "n",
  },
  {
    "<leader>mdo",
    function()
      require("dap").step_over()
    end,
    desc = "<F10> DAP: Step Over",
    mode = "n",
  },
  {
    "<leader>mdi",
    function()
      require("dap").step_into()
    end,
    desc = "<F11> DAP: Step Into",
    mode = "n",
  },
  {
    "<leader>mdu",
    function()
      require("dap").step_out()
    end,
    desc = "<F12> DAP: Step Out",
    mode = "n",
  },
  {
    "<leader>mdt",
    function()
      require("dap").terminate()
    end,
    desc = "<S-F5> DAP: Terminate",
    mode = "n",
  },
  {
    "<leader>mdu",
    function()
      require("dap").toggle({})
    end,
    desc = "<F8> DAP: Toggle UI",
    mode = "n",
  },
  {
    "<leader>mdt",
    function()
      -- Allow the output of dbg! to appear in the dap console.
      vim.cmd("RustLsp debug --nocapture")
    end,
    desc = "Debug the nearest test --nocapture",
    mode = "n",
  },
})
