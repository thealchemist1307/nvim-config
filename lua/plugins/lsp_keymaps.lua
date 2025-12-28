return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      local default_server = opts.servers["*"]
      if type(default_server) ~= "table" then
        default_server = {}
        opts.servers["*"] = default_server
      end

      default_server.keys = default_server.keys or {}
      vim.list_extend(default_server.keys, {
        {
          "gD",
          vim.lsp.buf.declaration,
          desc = "Goto Declaration",
          has = "declaration",
        },
        {
          "gI",
          vim.lsp.buf.implementation,
          desc = "Goto Implementation",
          has = "implementation",
        },
      })
    end,
  },
}
