-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set
local ts = vim.treesitter
local LazyVim = require("lazyvim.util")

local get_node_text = ts.get_node_text
if not get_node_text and vim.treesitter.query and vim.treesitter.query.get_node_text then
  get_node_text = vim.treesitter.query.get_node_text
end

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

local function resolve_lang(ft)
  if not ft then
    return nil
  end

  if ts.language and ts.language.get_lang then
    local ok, resolved = pcall(ts.language.get_lang, ft)
    if ok and resolved then
      return resolved
    end
  end

  return parser_overrides[ft] or ft
end

local function get_tag_tree_context()
  local ft = vim.bo.filetype
  local config = tag_configs[ft]
  if not config then
    return nil, nil, "unsupported"
  end

  local lang = resolve_lang(ft)
  local parser_ok, parser = pcall(ts.get_parser, 0, lang)
  if not parser_ok then
    return nil, nil, "no_parser"
  end

  local first_tree = parser:parse()[1]
  if not first_tree then
    return nil, nil, "parse_failed"
  end

  return config, first_tree:root()
end

local error_messages = {
  unsupported = "HTML tag helpers only work inside HTML / JSX buffers",
  no_parser = "Install a tree-sitter parser for this filetype to use the HTML tag helpers",
  parse_failed = "Tree-sitter could not parse this buffer",
  not_on_tag = "Place the cursor inside an opening/closing tag before using this mapping",
  no_parent = "Unable to locate the wrapping element for this tag",
  no_match = "No matching HTML tag found (is it self-closing?)",
}

local div_error_messages = vim.tbl_extend("force", {}, error_messages, {
  no_div = "Place the cursor inside a <div> before pressing `at`",
  no_next = "No more <div> tags were found after the current selection",
})

local function notify_tag_error(err, messages)
  if not err then
    return
  end
  local lookup = messages or error_messages
  if lookup and lookup[err] then
    vim.notify(lookup[err], vim.log.levels.WARN)
  end
end

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

local function find_matching_tag_for_node(config, node)
  if not (config and node) then
    return nil, "no_match"
  end

  local parent = node:parent()
  if not parent then
    return nil, "no_parent"
  end

  local target_field, target_type = get_match_targets(config, node:type())

  local match
  if target_field then
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

local function find_matching_tag()
  local config, root, err = get_tag_tree_context()
  if not config then
    return nil, err
  end

  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1] - 1, cursor[2]
  local node = root:named_descendant_for_range(row, col, row, col)

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

  local match
  match, err = find_matching_tag_for_node(config, node)
  if not match then
    return nil, err
  end

  return match
end

local function normalize_range(range)
  if not range then
    return nil
  end
  local sr, sc, er, ec = range[1], range[2], range[3], range[4]
  if sr > er or (sr == er and sc > ec) then
    sr, sc, er, ec = er, ec, sr, sc
  end
  return { sr, sc, er, ec }
end

local function ranges_equal(a, b)
  if not (a and b) then
    return false
  end
  for i = 1, 4 do
    if a[i] ~= b[i] then
      return false
    end
  end
  return true
end

local function get_visual_range()
  local mode = vim.fn.mode()
  if mode ~= "v" and mode ~= "V" and mode ~= "\22" then
    return nil
  end
  local start_pos = vim.fn.getpos("v")
  local end_pos = vim.fn.getpos(".")
  if not (start_pos and end_pos) then
    return nil
  end
  local sr, sc = start_pos[2] - 1, start_pos[3] - 1
  local er, ec = end_pos[2] - 1, end_pos[3] - 1
  return normalize_range({ sr, sc, er, ec })
end

local function apply_visual_range(range)
  local normalized = normalize_range(range)
  if not normalized then
    return
  end
  local sr, sc, er, ec = normalized[1], normalized[2], normalized[3], normalized[4]
  vim.cmd("normal! \\<Esc>")
  vim.api.nvim_win_set_cursor(0, { sr + 1, sc })
  vim.cmd("normal! v")
  vim.api.nvim_win_set_cursor(0, { er + 1, ec })
end

local function compare_pos(row1, col1, row2, col2)
  if row1 ~= row2 then
    return row1 < row2 and -1 or 1
  end
  if col1 ~= col2 then
    return col1 < col2 and -1 or 1
  end
  return 0
end

local tag_name_fallbacks =
  { "tag_name", "identifier", "property_identifier", "nested_identifier", "jsx_namespace_name" }

local function get_tag_name(node)
  if not (node and get_node_text) then
    return nil
  end

  local name_node
  if node.child_by_field_name then
    name_node = node:child_by_field_name("name")
  elseif node.field then
    local nodes = node:field("name")
    name_node = nodes and nodes[1]
  end

  if not name_node then
    for _, type_name in ipairs(tag_name_fallbacks) do
      name_node = find_child_by_type(node, type_name)
      if name_node then
        break
      end
    end
  end

  if not name_node then
    return nil
  end

  local ok, text = pcall(get_node_text, name_node, 0)
  if not ok then
    return nil
  end

  return text
end

local function is_div_tag(node)
  local name = get_tag_name(node)
  if not name then
    return false
  end
  return name:lower() == "div"
end

local start_tag_types = {
  start_tag = true,
  jsx_opening_element = true,
}

local end_tag_types = {
  end_tag = true,
  jsx_closing_element = true,
}

local self_closing_tag_types = {
  self_closing_tag = true,
  jsx_self_closing_element = true,
}

local element_types = {
  element = true,
  jsx_element = true,
}

local function compute_tag_range(start_node, end_node)
  if not start_node then
    return nil
  end
  end_node = end_node or start_node
  local sr, sc = start_node:start()
  local er, ec_exclusive = end_node:end_()
  return { sr, sc, er, math.max(ec_exclusive - 1, 0) }
end

local function get_tag_selection_range(config, root, row, col)
  if not (config and root) then
    return nil, "unsupported"
  end

  local node = root:named_descendant_for_range(row, col, row, col)
  while node do
    local node_type = node:type()
    if self_closing_tag_types[node_type] then
      return compute_tag_range(node, node)
    end

    if start_tag_types[node_type] or end_tag_types[node_type] then
      local match, match_err = find_matching_tag_for_node(config, node)
      if not match then
        return nil, match_err
      end
      local start_node = start_tag_types[node_type] and node or match
      local end_node = start_tag_types[node_type] and match or node
      return compute_tag_range(start_node, end_node)
    end

    if element_types[node_type] then
      local start_child
      local child_count = node.named_child_count and node:named_child_count() or 0
      for i = 0, child_count - 1 do
        local child = node:named_child(i)
        if child then
          local child_type = child:type()
          if self_closing_tag_types[child_type] or start_tag_types[child_type] then
            start_child = child
            break
          end
        end
      end

      if start_child then
        if self_closing_tag_types[start_child:type()] then
          return compute_tag_range(start_child, start_child)
        end
        local closing, match_err = find_matching_tag_for_node(config, start_child)
        if not closing then
          return nil, match_err
        end
        return compute_tag_range(start_child, closing)
      end
    end

    node = node:parent()
  end

  return nil, "not_on_tag"
end

local function compute_div_selection(start_tag, closing_tag)
  if not (start_tag and closing_tag) then
    return nil
  end
  local sr, sc = start_tag:start()
  local er, ec_exclusive = closing_tag:end_()
  local range = { sr, sc, er, math.max(ec_exclusive - 1, 0) }
  return {
    range = range,
    next_search = { er, ec_exclusive },
    start = { sr, sc },
  }
end

local function find_div_element_at_position(config, root, row, col)
  if not (config and root) then
    return nil, "unsupported"
  end

  local node = root:named_descendant_for_range(row, col, row, col)
  while node do
    local node_type = node:type()
    if start_tag_types[node_type] and is_div_tag(node) then
      local closing, match_err = find_matching_tag_for_node(config, node)
      if closing then
        return compute_div_selection(node, closing)
      end
      return nil, match_err
    elseif element_types[node_type] then
      local count = node:named_child_count()
      for i = 0, count - 1 do
        local child = node:named_child(i)
        if child and start_tag_types[child:type()] then
          if is_div_tag(child) then
            local closing, match_err = find_matching_tag_for_node(config, child)
            if closing then
              return compute_div_selection(child, closing)
            end
            return nil, match_err
          end
          break
        end
      end
    end
    node = node:parent()
  end

  return nil, "no_div"
end

local function find_next_div_element(config, root, row, col)
  if not (config and root and row and col) then
    return nil, "no_next"
  end

  local best

  local function traverse(node)
    if not node then
      return
    end
    local node_type = node:type()
    if start_tag_types[node_type] and is_div_tag(node) then
      local sr, sc = node:start()
      if compare_pos(sr, sc, row, col) > 0 then
        local closing = select(1, find_matching_tag_for_node(config, node))
        if closing then
          local selection = compute_div_selection(node, closing)
          if selection then
            if not best or compare_pos(selection.start[1], selection.start[2], best.start[1], best.start[2]) < 0 then
              best = selection
            end
          end
        end
      end
    end

    local count = node:named_child_count()
    for i = 0, count - 1 do
      traverse(node:named_child(i))
    end
  end

  traverse(root)

  if not best then
    return nil, "no_next"
  end

  return best
end

local div_selection_state = {}

local function select_div_text_object()
  local config, root, err = get_tag_tree_context()
  if not config then
    notify_tag_error(err, div_error_messages)
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local current_range = get_visual_range()
  local state = div_selection_state[bufnr]

  local selection
  if state and state.range and current_range and ranges_equal(state.range, current_range) and state.next_search then
    selection, err = find_next_div_element(config, root, state.next_search[1], state.next_search[2])
  else
    local cursor = vim.api.nvim_win_get_cursor(0)
    selection, err = find_div_element_at_position(config, root, cursor[1] - 1, cursor[2])
  end

  if not selection then
    notify_tag_error(err or "no_div", div_error_messages)
    div_selection_state[bufnr] = nil
    return
  end

  apply_visual_range(selection.range)
  div_selection_state[bufnr] = {
    range = normalize_range(selection.range),
    next_search = selection.next_search,
  }
end

local function yank_current_html_tag()
  local config, root, err = get_tag_tree_context()
  if not config then
    notify_tag_error(err)
    return
  end

  local cursor = vim.api.nvim_win_get_cursor(0)
  local range, range_err = get_tag_selection_range(config, root, cursor[1] - 1, cursor[2])
  if not range then
    notify_tag_error(range_err)
    return
  end

  apply_visual_range(range)
  vim.cmd("normal! y")
end

local function jump_between_html_tags()
  local match, err = find_matching_tag()
  if not match then
    notify_tag_error(err)
    return
  end

  local target_row, target_col = match:start()
  vim.api.nvim_win_set_cursor(0, { target_row + 1, target_col })
end

-- 1. Jump between matching HTML/JSX tags only
map("n", "<leader>dx", jump_between_html_tags, { desc = "Jump between HTML tags" })

-- 1a. Select div tags and advance to the next on repeat
map("x", "at", select_div_text_object, { desc = "Select <div> (repeat for next)" })

-- 1b. Close the current tab quickly
map("n", "<leader>cq", "<cmd>tabclose<cr>", { desc = "Close current tab" })

map("n", "<leader>wf", "<cmd>w<cr>", { desc = "Save file" })

map("n", "<leader>yd", function()
  vim.cmd("normal! 0v$%$y")
end, { desc = "Run yank macro 0v$%$y" })
map("n", "<leader>yD", yank_current_html_tag, { desc = "Yank surrounding HTML/JSX tag" })

-- 2. Make `d` delete WITHOUT touching clipboard
map({ "n", "x" }, "d", '"_d', { desc = "Delete without yanking" })
map({ "n", "x" }, "D", '"_D', { desc = "Delete line without yanking" })

-- (optional) If you also want `c` to not clobber clipboard, uncomment:
map({ "n", "x" }, "c", '"_c', { desc = "Change without yanking" })
map("n", "C", '"_C', { desc = "Change to end without yanking" })

-- Terminal toggles: allow hiding/reopening the Snacks terminal with <leader>ft
map({ "n", "t" }, "<leader>ft", function()
  Snacks.terminal(nil, { cwd = LazyVim.root() })
end, { desc = "Terminal (Root Dir)" })

-- Terminal: escape to normal mode (for Codex/any TUI)
vim.keymap.set("t", "<F6>", [[<C-\><C-n>]], {
  silent = true,
  desc = "Terminal: navigate/copy (normal mode)",
})

local function set_ctrl_t_terminal_keymaps(buf, label)
  local prefix = label or "Terminal"
  vim.keymap.set("t", "<C-t>", [[<C-\><C-n>]], {
    buffer = buf,
    silent = true,
    nowait = true,
    desc = prefix .. ": terminal -> normal (navigate output)",
  })

  vim.keymap.set("n", "<C-t>", "i", {
    buffer = buf,
    silent = true,
    nowait = true,
    desc = prefix .. ": normal -> terminal (type)",
  })
end

vim.api.nvim_create_autocmd("TermOpen", {
  callback = function(ev)
    local name = vim.api.nvim_buf_get_name(ev.buf) -- e.g. term://.../codex...
    name = name and name:lower() or ""
    local is_codex = name:find("codex", 1, true) ~= nil
    local is_snacks_terminal = not is_codex and vim.bo[ev.buf].filetype == "snacks_terminal"
    if not (is_codex or is_snacks_terminal) then
      return
    end

    local label = is_codex and "Codex" or "Terminal"
    set_ctrl_t_terminal_keymaps(ev.buf, label)
  end,
})
-- Optional: make <C-w> work inside terminals again
-- vim.o.termwinkey = "<C-w>"
