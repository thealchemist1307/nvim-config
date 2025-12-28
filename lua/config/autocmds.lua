-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Ensure matchit is available for HTML (so % jumps between tags)
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "html" },
  callback = function()
    vim.cmd("silent! packadd matchit")
  end,
})

-- tsgo attaches automatically somewhere upstream; immediately stop it so only ts_ls remains
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("disable_tsgo_lsp", { clear = true }),
  callback = function(event)
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client and client.name == "tsgo" then
      vim.schedule(function()
        client.stop()
      end)
    end
  end,
})
