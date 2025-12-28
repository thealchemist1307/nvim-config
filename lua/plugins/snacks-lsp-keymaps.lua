local function lsp_supports(method, buf)
  if not method then
    return true
  end
  buf = buf or vim.api.nvim_get_current_buf()
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = buf })) do
    if client.supports_method and client:supports_method(method, buf) then
      return true
    end
  end
  return false
end

local function try_target(target, buf)
  if not target or type(target.fn) ~= "function" then
    return false
  end
  if target.method and not lsp_supports(target.method, buf) then
    return false
  end
  target.fn()
  return true
end

local function picker_with_fallback(opts)
  local label = opts.label or opts.method or "requested LSP method"
  return function()
    local buf = vim.api.nvim_get_current_buf()
    if try_target(opts.primary, buf) then
      return
    end
    if try_target(opts.fallback, buf) then
      return
    end
    vim.notify(("No attached LSP clients support %s."):format(label), vim.log.levels.WARN)
  end
end

local function picker_fn(name)
  return function()
    return require("snacks").picker[name]()
  end
end

return {
  {
    "folke/snacks.nvim",
    optional = true,
    keys = function()
      return {
        {
          "gd",
          picker_with_fallback({
            label = "definitions",
            primary = {
              method = "textDocument/definition",
              fn = picker_fn("lsp_definitions"),
            },
          }),
          desc = "Snacks: Goto Definition",
        },
        {
          "gD",
          picker_with_fallback({
            label = "declarations",
            primary = {
              method = "textDocument/declaration",
              fn = picker_fn("lsp_declarations"),
            },
            fallback = {
              method = "textDocument/definition",
              fn = picker_fn("lsp_definitions"),
            },
          }),
          desc = "Snacks: Goto Declaration",
        },
        {
          "gI",
          picker_with_fallback({
            label = "implementations",
            primary = {
              method = "textDocument/implementation",
              fn = picker_fn("lsp_implementations"),
            },
            fallback = {
              method = "textDocument/definition",
              fn = picker_fn("lsp_definitions"),
            },
          }),
          desc = "Snacks: Goto Implementation",
        },
      }
    end,
  },
}
