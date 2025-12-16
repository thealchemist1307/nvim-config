local join = (vim.fs and vim.fs.joinpath) or function(...)
  local sep = package.config:sub(1, 1)
  return table.concat({ ... }, sep)
end

local home = vim.env.USERPROFILE or vim.env.HOME
if not home then
  vim.notify("Unable to resolve a home directory for loading the Omarchy theme.", vim.log.levels.WARN, { title = "Omarchy Theme" })
  return {}
end

local theme_file = join(home, ".config", "omarchy", "current", "theme", "neovim.lua")

if vim.fn.filereadable(theme_file) == 0 then
  vim.notify(("Omarchy theme file not found at %s"):format(theme_file), vim.log.levels.WARN, { title = "Omarchy Theme" })
  return {}
end

local ok, theme_spec = pcall(dofile, theme_file)
if not ok then
  vim.notify(("Failed to load Omarchy theme file %s:\n%s"):format(theme_file, theme_spec), vim.log.levels.ERROR, { title = "Omarchy Theme" })
  return {}
end

return theme_spec
