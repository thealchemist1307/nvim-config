return {
  { "mason-org/mason.nvim", opts = {} },
  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = {
      "mason-org/mason.nvim",
      "neovim/nvim-lspconfig",
    },
    opts = function()
      return {
        ensure_installed = {
          "ts_ls",
          "eslint",
          "jsonls",
          "pyright",
          "clangd",
          "lua_ls",
        },
        automatic_installation = true,
        handlers = {
          function(server_name)
            if server_name == "tsgo" then
              return
            end
            require("lspconfig")[server_name].setup({})
          end,
        },
      }
    end,
  },
}
