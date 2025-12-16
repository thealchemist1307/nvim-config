return {
  "rhart92/codex.nvim",
  lazy = false,
  config = function()
    require("codex").setup({
      split = "vertical",
      size = 0.40,
      focus_after_send = true,
    })
  end,
  keys = {
    { "<leader>cc", function() require("codex").toggle() end, desc = "Codex: Toggle", mode = { "n", "t" } },
    { "<leader>cs", function() require("codex").actions.send_selection() end, desc = "Codex: Send selection", mode = "v" },
  },
}
