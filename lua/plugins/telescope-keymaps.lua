return {
  {
    "nvim-telescope/telescope.nvim",
    keys = {
      {
        "<leader>df",
        function() require("telescope.builtin").find_files() end,
        desc = "Telescope: Find files",
      },
      {
        "<leader>dg",
        function() require("telescope.builtin").live_grep() end,
        desc = "Telescope: Live grep",
      },
      {
        "<leader>db",
        function() require("telescope.builtin").buffers() end,
        desc = "Telescope: Buffers",
      },
      {
        "<leader>dd",
        function() require("telescope.builtin").diagnostics() end,
        desc = "Telescope: Diagnostics",
      },
    },
  },
}
