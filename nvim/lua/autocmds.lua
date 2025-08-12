vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'markdown', 'toml', 'lua' },
  callback = function()
    vim.o.tabstop = 2
    vim.o.shiftwidth = 2
    vim.o.expandtab = true
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'python' },
  callback = function()
    vim.o.tabstop = 4
    vim.o.shiftwidth = 4
    vim.o.expandtab = true
  end,
})

-- SPLIT SEPARATOR COLOR
-- Create a group to ensure this command isn't duplicated on reload
local override_group = vim.api.nvim_create_augroup('HighlightOverrides', { clear = true })

-- Create an auto-command that runs whenever a colorscheme is loaded
vim.api.nvim_create_autocmd('ColorScheme', {
  group = override_group,
  pattern = '*', -- This applies to any colorscheme
  desc = 'Apply custom separator colors',
  callback = function()
    -- Your working command, executed via Lua:
    vim.cmd 'highlight! WinSeparator guifg=#3B4261'

    -- You should probably set the vertical one to match:
    vim.cmd 'highlight! VertSplit guifg=#3B4261'
  end,
})
