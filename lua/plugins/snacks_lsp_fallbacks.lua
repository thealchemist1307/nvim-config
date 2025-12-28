local function declaration_or_definition()
  local Snacks = require("snacks")
  local buf = vim.api.nvim_get_current_buf()
  local clients = vim.lsp.get_clients({ bufnr = buf })
  for _, client in ipairs(clients) do
    if client.supports_method and client:supports_method("textDocument/declaration") then
      return Snacks.picker.lsp_declarations()
    end
  end
  return Snacks.picker.lsp_definitions()
end

return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      opts.servers["*"] = opts.servers["*"] or {}
      opts.servers["*"].keys = opts.servers["*"].keys or {}
      for idx = #opts.servers["*"].keys, 1, -1 do
        if opts.servers["*"].keys[idx][1] == "gD" then
          table.remove(opts.servers["*"].keys, idx)
        end
      end
      table.insert(opts.servers["*"].keys, {
        "gD",
        declaration_or_definition,
        desc = "Goto Declaration",
        has = { "declaration", "definition" },
      })
    end,
  },
}
