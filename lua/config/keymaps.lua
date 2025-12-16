-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set
local ts = vim.treesitter

local html_tag_config = {
  match_field_by_type = {
    start_tag = "end_tag",
    end_tag = "start_tag",
  },
  match_type_by_type = {
    start_tag = "end_tag",
    end_tag = "start_tag",
  },
}

local jsx_tag_config = {
  match_field_by_type = {
    jsx_opening_element = "closing_element",
    jsx_closing_element = "opening_element",
  },
  match_type_by_type = {
    jsx_opening_element = "jsx_closing_element",
    jsx_closing_element = "jsx_opening_element",
  },
}

local tag_configs = {
  html = html_tag_config,
  xhtml = html_tag_config,
  htmldjango = html_tag_config,
  xml = html_tag_config,
  javascriptreact = jsx_tag_config,
  typescriptreact = jsx_tag_config,
  tsx = jsx_tag_config,
  jsx = jsx_tag_config,
}

local parser_overrides = {
  javascriptreact = "javascript",
  jsx = "javascript",
  typescriptreact = "tsx",
  tsx = "tsx",
}

local error_messages = {
  unsupported = "`<leader>dx` only works inside HTML / JSX buffers",
  no_parser = "Install a tree-sitter parser for this filetype to use `<leader>dx`",
  parse_failed = "Tree-sitter could not parse this buffer",
  not_on_tag = "Place the cursor inside an opening/closing tag before pressing `<leader>dx`",
  no_parent = "Unable to locate the wrapping element for this tag",
  no_match = "No matching HTML tag found (is it self-closing?)",
}

local function get_match_targets(config, node_type)
  if not (config and node_type) then
    return nil, nil
  end
  local target_field = config.match_field_by_type and config.match_field_by_type[node_type]
  local target_type = config.match_type_by_type and config.match_type_by_type[node_type]
  return target_field, target_type
end

local function find_child_by_type(node, target_type)
  if not (node and target_type) then
    return nil
  end

  if node.named_child_count and node.named_child then
    local count = node:named_child_count()
    for i = 0, count - 1 do
      local child = node:named_child(i)
      if child and child:type() == target_type then
        return child
      end
    end
  end

  if node.child_count and node.child then
    local count = node:child_count()
    for i = 0, count - 1 do
      local child = node:child(i)
      if child and child:type() == target_type then
        return child
      end
    end
  end

  return nil
end

local function find_matching_tag()
  local ft = vim.bo.filetype
  local config = tag_configs[ft]
  if not config then
    return nil, "unsupported"
  end

  local lang = nil
  if ts.language and ts.language.get_lang then
    local ok, resolved = pcall(ts.language.get_lang, ft)
    if ok then
      lang = resolved
    end
  end
  lang = lang or parser_overrides[ft] or ft

  local parser_ok, parser = pcall(ts.get_parser, 0, lang)
  if not parser_ok then
    return nil, "no_parser"
  end

  local first_tree = parser:parse()[1]
  if not first_tree then
    return nil, "parse_failed"
  end

  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1] - 1, cursor[2]
  local node = first_tree:root():named_descendant_for_range(row, col, row, col)

  while node do
    local field_target, type_target = get_match_targets(config, node:type())
    if field_target or type_target then
      break
    end
    node = node:parent()
  end

  if not node then
    return nil, "not_on_tag"
  end

  local parent = node:parent()
  if not parent then
    return nil, "no_parent"
  end

  local target_field, target_type = get_match_targets(config, node:type())

  local match
  if target_field then
    -- Prefer child_by_field_name when available (Neovim 0.10+),
    -- but fall back to :field for older releases.
    if parent.child_by_field_name then
      match = parent:child_by_field_name(target_field)
    elseif parent.field then
      local nodes = parent:field(target_field)
      match = nodes and nodes[1]
    end
  end

  if not match and target_type then
    match = find_child_by_type(parent, target_type)
  end

  if not match then
    return nil, "no_match"
  end

  return match
end

local function jump_between_html_tags()
  local match, err = find_matching_tag()
  if not match then
    if error_messages[err] then
      vim.notify(error_messages[err], vim.log.levels.WARN)
    end
    return
  end

  local target_row, target_col = match:start()
  vim.api.nvim_win_set_cursor(0, { target_row + 1, target_col })
end

-- 1. Jump between matching HTML/JSX tags only
map("n", "<leader>dx", jump_between_html_tags, { desc = "Jump between HTML tags" })

-- 1b. Close the current tab quickly
map("n", "<leader>cq", "<cmd>tabclose<cr>", { desc = "Close current tab" })

-- 2. Make `d` delete WITHOUT touching clipboard
map({ "n", "x" }, "d", '"_d', { desc = "Delete without yanking" })
map({ "n", "x" }, "D", '"_D', { desc = "Delete line without yanking" })

-- (optional) If you also want `c` to not clobber clipboard, uncomment:
map({ "n", "x" }, "c", '"_c', { desc = "Change without yanking" })
map("n", "C", '"_C', { desc = "Change to end without yanking" })
