return {
	-- add gruvbox
	{ "ellisonleao/gruvbox.nvim" },
	{ "judaew/ronny.nvim" },

	-- Configure LazyVim to load gruvbox
	{
		"LazyVim/LazyVim",
		opts = {
			-- colorscheme = "gruvbox",
			colorscheme = "ronny",
			-- colorscheme = "ron",
		},
	},
}
