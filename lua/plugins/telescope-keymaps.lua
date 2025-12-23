return {
  {
    "nvim-telescope/telescope.nvim",
    keys = {
      {
        "<leader>df",
        function()
          require("telescope.builtin").find_files()
        end,
        desc = "Telescope: Find files",
      },
      {
        "<leader>dg",
        function()
          require("telescope.builtin").live_grep()
        end,
        desc = "Telescope: Live grep",
      },
      {
        "<leader>db",
        function()
          require("telescope.builtin").buffers()
        end,
        desc = "Telescope: Buffers",
      },

      {
        "<leader>dd",
        function()
          local builtin = require("telescope.builtin")

          -- If we're in visual mode, grab the selected text
          local mode = vim.fn.mode()
          if mode == "v" or mode == "V" or mode == "\22" then
            local _, ls, cs = unpack(vim.fn.getpos("v"))
            local _, le, ce = unpack(vim.fn.getpos("."))
            if ls > le or (ls == le and cs > ce) then
              ls, le = le, ls
              cs, ce = ce, cs
            end

            local lines = vim.fn.getline(ls, le)
            if #lines > 0 then
              lines[1] = string.sub(lines[1], cs)
              lines[#lines] = string.sub(lines[#lines], 1, ce)
              local text = table.concat(lines, "\n"):gsub("\n", " "):gsub("^%s+", ""):gsub("%s+$", "")

              if text ~= "" then
                return builtin.grep_string({ search = text })
              end
            end
          end

          -- Normal mode fallback: word under cursor
          builtin.grep_string({ search = vim.fn.expand("<cword>") })
        end,
        mode = { "n", "v" },
        desc = "Telescope: Find usages (selection/cword)",
      },
    },
  },
}
