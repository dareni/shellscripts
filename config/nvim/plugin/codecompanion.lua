return {
  "olimorris/codecompanion.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  opts = {
    strategies = {
      chat = { adapter = "ollama" },
      inline = { adapter = "ollama" },
    },
    log_level = "DEBUG",
    adapters = {
      ollama = function()
        return require("codecompanion.adapters").extend("ollama", {
          env = {
            url = "http://127.0.0.1:1434"
          },
          schema = {
            model = { default = "qwen2.5-coder:3b" },
          },
        })
      end,
    },
  },
}
