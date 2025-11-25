require 'core.options'
require 'core.keymaps'

_G.message = function(val)
  local msg = vim.inspect(val)
  msg = msg:gsub('"', '\\"')
  vim.cmd('echom "' .. msg .. '"')
end

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

-- Midpoint between #000000 and tmux ianctive (#0A0A00).
local inactive = '#050500'
-- Midpoint between tmux inactive and tmux active.
local active = '#1B1B00'

-- Set initial highlight groups
vim.api.nvim_set_hl(0, 'Normal', { bg = active })
vim.api.nvim_set_hl(0, 'NormalNC', { bg = inactive })

-- When a Neovim window becomes active
vim.api.nvim_create_autocmd({ 'WinEnter', 'FocusGained' }, {
  callback = function()
    vim.api.nvim_set_hl(0, 'Normal', { bg = active })
    vim.api.nvim_set_hl(0, 'NormalNC', { bg = inactive })
    vim.cmd 'redraw'
  end,
})

-- When Neovim loses focus (switch to another tmux pane)
vim.api.nvim_create_autocmd({ 'FocusLost' }, {
  callback = function()
    -- Force ALL windows into inactive color
    vim.api.nvim_set_hl(0, 'Normal', { bg = inactive })
    vim.api.nvim_set_hl(0, 'NormalNC', { bg = inactive })
    vim.cmd 'redraw'
  end,
})
