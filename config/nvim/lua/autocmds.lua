-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "gitcommit" },
	callback = function()
		vim.opt_local.colorcolumn = "50,72"
	end,
})

-- colorscheme ron ------------------------------------------------------------
local function apply_ron_tweaks()
	-- Remove the heavy background block and use a clean underline instead.
	-- vim.api.nvim_set_hl(0, "CursorLine", { bg = "#262626", underline = true })
	-- vim.api.nvim_set_hl(0, "Normal", { fg = "#e2e2e2", bg = "#1c1c1c" })
	vim.api.nvim_set_hl(0, "CursorLine", { bg = "NONE", underline = true })

	-- Use a very subtle dark grey instead of ron's default (underline alternative).
	-- vim.api.nvim_set_hl(0, "CursorLine", { bg = "#252525", ctermbg = 235 })

	-- Darken completion/popup menus
	vim.api.nvim_set_hl(0, "Pmenu", { bg = "#1e1e1e", fg = "#d0d0d0" })
	vim.api.nvim_set_hl(0, "PmenuSel", { bg = "#333333", fg = "#ffffff", bold = true })

	-- Darken floating windows (LSP docs, hover windows, etc.)
	vim.api.nvim_set_hl(0, "NormalFloat", { bg = "#181818", fg = "#d0d0d0" })
	vim.api.nvim_set_hl(0, "FloatBorder", { bg = "#181818", fg = "#505050" })

	-- Fix folded lines and fold column backgrounds
	vim.api.nvim_set_hl(0, "Folded", { bg = "#1c1c1c", fg = "#777777", ctermbg = 234, ctermfg = 243 })
	vim.api.nvim_set_hl(0, "FoldColumn", { bg = "NONE", fg = "#555555" })
end

vim.api.nvim_create_autocmd("ColorScheme", {
	pattern = "ron",
	callback = function()
		apply_ron_tweaks()
	end,
})
-- Parenthesis highlight-------------------------------------------------------
local function fix_paren_match()
	-- The default bracket '[({' highlight colouring has the dull colour under
	-- the cursor position and the bright colour for the matching bracket. This
	-- logic changes the background block to an underline instead.
	local current_match = vim.api.nvim_get_hl(0, { name = "MatchParen" })

	-- Extract its foreground color (falling back to standard text if empty)
	local theme_fg = current_match.fg or "NONE"
	local theme_bg = current_match.bg or "NONE"

	vim.api.nvim_set_hl(0, "MatchParen", {
		reverse = false,
		bg = theme_fg,
		fg = theme_bg,
		underline = true,
		bold = false,
	})
end

-- fix the cursor highlight for ron and ronny ---------------------------------
vim.api.nvim_create_autocmd("ColorScheme", {
	pattern = "ronny",
	callback = fix_paren_match,
})

-- Run immediately for the active colorscheme on startup
local colorscheme = vim.g.colors_name
if colorscheme == "ron" then
	apply_ron_tweaks()
	fix_paren_match()
elseif colorscheme == "ronny" then
	fix_paren_match()
end
