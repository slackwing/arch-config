require 'core.options'
require 'core.keymaps'

local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then
    error('Error cloning lazy.nvim:\n' .. out)
  end
end

local rtp = vim.opt.rtp
rtp:prepend(lazypath)

require('lazy').setup {
  require 'plugins.neotree',
  -- require 'plugins.colortheme',
  require 'plugins.lualine',
  require 'plugins.treesitter',
  require 'plugins.telescope',
  require 'plugins.lsp',
  require 'plugins.autocompletion',
  require 'plugins.autoformatting',
  require 'plugins.gitsigns',
  require 'plugins.indent-blankline',
  require 'plugins.misc',
  require 'plugins.diffview',
  require 'plugins.mini',
}

vim.api.nvim_set_hl(0, 'Normal', { bg = 'none' })
vim.api.nvim_set_hl(0, 'NormalFloat', { bg = 'none' })
vim.api.nvim_set_hl(0, 'SignColumn', { bg = 'none' })
vim.api.nvim_set_hl(0, 'EndOfBuffer', { bg = 'none' })

-- mini.diff mappings
vim.keymap.set('n', ';a', function()
  vim.cmd 'normal ghgh'
end, { desc = 'MiniDiff: apply hunk under cursor' })
vim.keymap.set('n', ';r', function()
  vim.cmd 'normal gHgh'
end, { desc = 'MiniDiff: reset hunk under cursor' })
vim.keymap.set('n', ';d', function()
  MiniDiff.toggle_overlay()
end)
