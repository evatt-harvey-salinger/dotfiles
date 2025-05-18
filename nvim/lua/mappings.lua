require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>", {desc = "Exit insert mode with jk"})

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")
