-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

-- 1. Jump between matching tags / pairs (HTML, JSX, {}, (), etc.)
map("n", "<leader>dx", "%", { desc = "Jump to matching tag / pair" })

-- 2. Make `d` delete WITHOUT touching clipboard
map({ "n", "x" }, "d", '"_d', { desc = "Delete without yanking" })
map({ "n", "x" }, "D", '"_D', { desc = "Delete line without yanking" })

-- (optional) If you also want `c` to not clobber clipboard, uncomment:
map({ "n", "x" }, "c", '"_c', { desc = "Change without yanking" })
map("n", "C", '"_C', { desc = "Change to end without yanking" })
