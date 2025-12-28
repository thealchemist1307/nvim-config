local function detect_system_luals()
  local exepath = vim.fn.exepath("lua-language-server")
  if exepath ~= "" and not exepath:find("mason", 1, true) then
    return exepath
  end
  local candidates = {
    "/usr/bin/lua-language-server",
    "/usr/local/bin/lua-language-server",
    vim.fn.expand("~/bin/lua-language-server"),
  }
  for _, candidate in ipairs(candidates) do
    if candidate ~= "" and vim.loop.fs_stat(candidate) then
      return candidate
    end
  end
end

local function ensure_local_libbfd()
  local libdir = vim.fn.expand("~/.local/lib/lua-ls")
  local target = libdir .. "/libbfd-2.38-system.so"
  if vim.loop.fs_stat(target) then
    return libdir
  end
  local candidates = {
    "/usr/lib/libbfd-2.45.1.so",
    "/usr/lib/libbfd.so",
  }
  for _, source in ipairs(candidates) do
    if vim.loop.fs_stat(source) then
      vim.fn.mkdir(libdir, "p")
      local ok, err = vim.loop.fs_copyfile(source, target)
      if not ok then
        vim.notify(
          ("Failed to copy %s → %s (%s)"):format(source, target, err or "unknown error"),
          vim.log.levels.ERROR,
          { title = "lua_ls" }
        )
        return
      end
      return libdir
    end
  end
end

return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      opts.servers.lua_ls = opts.servers.lua_ls or {}
      local cmd = detect_system_luals()
      if cmd then
        opts.servers.lua_ls.mason = false
        opts.servers.lua_ls.cmd = { cmd }
      else
        local libdir = ensure_local_libbfd()
        if libdir then
          opts.servers.lua_ls.cmd_env = opts.servers.lua_ls.cmd_env or {}
          local current = opts.servers.lua_ls.cmd_env.LD_LIBRARY_PATH
            or vim.env.LD_LIBRARY_PATH
            or ""
          local path = libdir
          if current ~= "" then
            path = libdir .. ":" .. current
          end
          opts.servers.lua_ls.cmd_env.LD_LIBRARY_PATH = path
        else
          vim.schedule(function()
            vim.notify(
              table.concat({
                "System lua-language-server not found.",
                "Install it via `sudo pacman -S lua-language-server`",
                "or copy libbfd-2.38-system.so into ~/.local/lib/lua-ls to avoid Mason runtime errors.",
              }, " "),
              vim.log.levels.WARN,
              { title = "lua_ls" }
            )
          end)
        end
      end
    end,
  },
}
