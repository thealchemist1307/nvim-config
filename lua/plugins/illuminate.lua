return {
  {
    "RRethy/vim-illuminate",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      delay = 120,
      under_cursor = true,
      large_file_cutoff = 2000,
      min_count_to_highlight = 2,
      filetype_overrides = {
        javascriptreact = { providers = { "lsp", "treesitter", "regex" } },
        typescriptreact = { providers = { "lsp", "treesitter", "regex" } },
      },
    },
    config = function(_, opts)
      local illuminate = require("illuminate")
      illuminate.configure(opts)

      -- make it unmissable (themes sometimes make defaults invisible)
      vim.api.nvim_set_hl(0, "IlluminatedWordText", { underline = true })
      vim.api.nvim_set_hl(0, "IlluminatedWordRead", { underline = true })
      vim.api.nvim_set_hl(0, "IlluminatedWordWrite", { underline = true })
      vim.api.nvim_set_hl(0, "IlluminatedCurWord", { underline = true, bold = true })
    end,
  },

  -- ensure parsers exist
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "javascript", "typescript", "tsx", "html", "css", "json" })
    end,
  },
}
