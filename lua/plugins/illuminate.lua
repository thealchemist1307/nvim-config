return {
  {
    "RRethy/vim-illuminate",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      delay = 120,
      under_cursor = true,
      large_file_cutoff = 2000,
      min_count_to_highlight = 2,
      providers = { "lsp", "treesitter", "regex" },
    },
    config = function(_, opts)
      require("illuminate").configure(opts)

      -- Make highlights visible in most themes
      vim.api.nvim_set_hl(0, "IlluminatedWordText", { link = "LspReferenceText" })
      vim.api.nvim_set_hl(0, "IlluminatedWordRead", { link = "LspReferenceRead" })
      vim.api.nvim_set_hl(0, "IlluminatedWordWrite", { link = "LspReferenceWrite" })
    end,
  },
}
