local function supports_method(client, method)
  return client.supports_method and client:supports_method(method)
end

local function method_flag(client, method)
  return supports_method(client, method) and "yes" or "no"
end

local function format_location(loc)
  if not loc then
    return ""
  end
  local uri = loc.uri or loc.targetUri
  local range = loc.range or loc.targetRange or loc.targetSelectionRange
  if not uri or not range then
    return ""
  end
  local filename = vim.uri_to_fname(uri)
  local start_line = (range.start and range.start.line or 0) + 1
  local start_char = (range.start and range.start.character or 0) + 1
  return string.format("%s:%d:%d", filename, start_line, start_char)
end

local function list_count(result)
  if not result then
    return 0
  end
  if vim.tbl_islist(result) then
    return #result
  end
  return 1
end

local function first_location(result)
  if not result then
    return nil
  end
  if vim.tbl_islist(result) then
    return result[1]
  end
  return result
end

local function debug_caps()
  local buf = vim.api.nvim_get_current_buf()
  local clients = vim.lsp.get_clients({ bufnr = buf })
  if vim.tbl_isempty(clients) then
    vim.notify("No LSP clients attached to current buffer", vim.log.levels.INFO, { title = "LSP Debug" })
    return
  end
  local lines = {}
  for _, client in ipairs(clients) do
    local root = client.config and client.config.root_dir or ""
    table.insert(lines, string.format("[%s]\n  root: %s\n  definition: %s  declaration: %s  implementation: %s  typeDefinition: %s", client.name, root, method_flag(client, "textDocument/definition"), method_flag(client, "textDocument/declaration"), method_flag(client, "textDocument/implementation"), method_flag(client, "textDocument/typeDefinition")))
  end
  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "LSP Debug Caps" })
end

local function debug_definition()
  local buf = vim.api.nvim_get_current_buf()
  local params = vim.lsp.util.make_position_params(0)
  local responses = vim.lsp.buf_request_sync(buf, "textDocument/definition", params, 1000)
  if not responses or vim.tbl_isempty(responses) then
    vim.notify("No responses for textDocument/definition", vim.log.levels.WARN, { title = "LSP Debug" })
    return
  end
  local lines = {}
  for client_id, resp in pairs(responses) do
    local client = vim.lsp.get_client_by_id(client_id)
    local name = client and client.name or ("client %d"):format(client_id)
    local count = list_count(resp.result)
    local loc = format_location(first_location(resp.result))
    if loc ~= "" then
      table.insert(lines, string.format("[%s] %d location(s) — %s", name, count, loc))
    else
      table.insert(lines, string.format("[%s] %d location(s)", name, count))
    end
  end
  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "LSP Debug Definition" })
end

return {
  {
    "neovim/nvim-lspconfig",
    init = function()
      vim.api.nvim_create_user_command("LspDebugCaps", debug_caps, { desc = "Inspect attached LSP clients and capabilities" })
      vim.api.nvim_create_user_command("LspDebugDef", debug_definition, { desc = "Inspect definition results at cursor" })
    end,
  },
}
