return {
  -- Formatting (on save)
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters_by_ft = vim.tbl_extend("force", opts.formatters_by_ft or {}, {
        -- Web
        javascript = { "prettier" },
        javascriptreact = { "prettier" },
        typescript = { "prettier" },
        typescriptreact = { "prettier" },
        json = { "prettier" },
        jsonc = { "prettier" },
        html = { "prettier" },
        css = { "prettier" },
        scss = { "prettier" },
        markdown = { "prettier" },
        yaml = { "prettier" },

        -- Lua
        lua = { "stylua" },

        -- Python
        python = { "isort", "black" },

        -- C / C++
        c = { "clang_format" },
        cpp = { "clang_format" },
      })
    end,
    keys = {
      {
        "<leader>cf",
        function()
          require("conform").format({ lsp_fallback = true })
        end,
        mode = { "n", "v" },
        desc = "Format file/range",
      },
    },
  },

  -- Linting (diagnostics)
  {
    "mfussenegger/nvim-lint",
    config = function()
      local lint = require("lint")

      lint.linters_by_ft = {
        -- Web
        javascript = { "eslint_d" },
        javascriptreact = { "eslint_d" },
        typescript = { "eslint_d" },
        typescriptreact = { "eslint_d" },

        -- Python
        python = { "ruff" },

        -- C/C++
        c = { "cppcheck" },
        cpp = { "cppcheck" },
      }

      local group = vim.api.nvim_create_augroup("NvimLint", { clear = true })

      vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
        group = group,
        callback = function()
          lint.try_lint()
        end,
      })

      vim.keymap.set("n", "<leader>cl", function()
        lint.try_lint()
      end, { desc = "Lint now" })
    end,
  },
}
