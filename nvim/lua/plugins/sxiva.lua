return {
  'tree-sitter-sxiva',
  dir = '/home/slackwing/src/feathers/11.sxiv/editor/nvim',
  config = function()
    local sxiva = require 'sxiva'
    sxiva.setup()

    -- Create user commands
    vim.api.nvim_create_user_command('Sxiv', function()
      sxiva.recalculate()
    end, { desc = 'Recalculate points for current .sxiva file' })

    vim.api.nvim_create_user_command('SxivaLogNow', function()
      sxiva.log_now()
    end, { desc = 'Set last entry end time to current time' })

    vim.api.nvim_create_user_command('SxivaLogEnd', function()
      sxiva.log_end()
    end, { desc = 'Clean up last incomplete entry (remove notes after ---)' })

    vim.api.nvim_create_user_command('SxivaRepeatEntry', function()
      sxiva.repeat_entry()
    end, { desc = 'Duplicate last entry with +12 min start time' })

    -- Keybindings for .sxiva files only
    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'sxiva',
      callback = function(args)
        vim.keymap.set('n', ';s', ':Sxiv<CR>', { buffer = args.buf, desc = 'Recalculate SXIVA points', silent = true })
        vim.keymap.set('n', ';l', ':SxivaLogNow<CR>', { buffer = args.buf, desc = 'Log current time', silent = true })
        vim.keymap.set('n', ';e', ':SxivaLogEnd<CR>', { buffer = args.buf, desc = 'Clean incomplete entry', silent = true })
        vim.keymap.set('n', ';r', ':SxivaRepeatEntry<CR>', { buffer = args.buf, desc = 'Repeat last entry', silent = true })
      end,
    })

    -- Set custom highlight colors for SXIVA
    -- Times in red/orange
    vim.api.nvim_set_hl(0, '@type.sxiva', { fg = '#E06C75' }) -- Red for times

    -- Categories in green
    vim.api.nvim_set_hl(0, '@string.sxiva', { fg = '#98C379' }) -- Green for categories

    -- Points in cyan
    vim.api.nvim_set_hl(0, '@function.sxiva', { fg = '#56B6C2' }) -- Cyan for points

    -- Gray for separators and minutes
    vim.api.nvim_set_hl(0, '@comment.sxiva', { fg = '#5C6370' }) -- Gray

    -- Bold for focus
    vim.api.nvim_set_hl(0, '@keyword.sxiva', { bold = true })

    -- Bold bright red for [ERROR] messages
    vim.api.nvim_set_hl(0, 'SxivaError', { fg = '#FF0000', bold = true })

    -- Don't highlight tree-sitter ERROR nodes (syntax errors) - they're noisy
    vim.api.nvim_set_hl(0, '@error.sxiva', { link = 'Normal' })
  end,
  ft = 'sxiva', -- Load only for .sxiva files
}
