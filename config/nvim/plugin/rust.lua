return {
  {
    "mrcjkb/rustaceanvim",
    opts = {
      server = {
        default_settings = {
          ["rust-analyzer"] = {
            cargo = {
              -- Configure rust-analyzer to use a separate background target folder,
              -- keeping target/ clean for cargo test caches.
              targetDir = true,
            },
          },
        },
      },
      dap = {
        load_rust_types = true,
      },
    },
  },
}
