return {
  -- Formatting (on save)
  {
    "stevearc/conform.nvim",
    opts = {
      format_on_save = { timeout_ms = 2000, lsp_fallback = true },
      formatters_by_ft = {
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
      },
    },
    config = function(_, opts)
      require("conform").setup(opts)
      vim.keymap.set({ "n", "v" }, "<leader>cf", function()
        require("conform").format({ lsp_fallback = true })
      end, { desc = "Format file/range" })
    end,
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
