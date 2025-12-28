return {
  "rhart92/codex.nvim",
  lazy = false,
  config = function()
    local codex = require("codex")

    codex.setup({
      split = "vertical",
      size = 0.40,
      focus_after_send = true,
    })

    local function apply_toggle_keymap(buf)
      local opts = { desc = "Codex: Toggle", silent = true, nowait = true }
      if buf and vim.api.nvim_buf_is_valid(buf) then
        opts.buffer = buf
      end
      vim.keymap.set({ "n", "t" }, "<leader>cc", codex.toggle, opts)
    end

    apply_toggle_keymap()

    local group = vim.api.nvim_create_augroup("codex_toggle_keymap", { clear = true })
    vim.api.nvim_create_autocmd({ "FileType", "LspAttach" }, {
      group = group,
      callback = function(event)
        local buf = event.buf
        vim.defer_fn(function()
          apply_toggle_keymap(buf)
        end, 0)
      end,
    })

    vim.keymap.set("v", "<leader>cs", codex.actions.send_selection, { desc = "Codex: Send selection" })
  end,
}
