return {
  {
    "RRethy/vim-illuminate",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      delay = 120, -- how fast highlights appear
      under_cursor = true,
      large_file_cutoff = 2000,
      min_count_to_highlight = 2,
    },
    config = function(_, opts)
      require("illuminate").configure(opts)

      -- Optional: jump between highlighted references like VSCode (F7/Shift+F7 vibe)
      vim.keymap.set("n", "]]", function()
        require("illuminate").goto_next_reference(false)
      end, { desc = "Next reference" })
      vim.keymap.set("n", "[[", function()
        require("illuminate").goto_prev_reference(false)
      end, { desc = "Prev reference" })
    end,
  },
}
