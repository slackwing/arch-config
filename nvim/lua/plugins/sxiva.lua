return {
  'tree-sitter-sxiva',
  dir = '/home/slackwing/src/feathers/11.sxiv/editor/nvim',
  config = function()
    require('sxiva').setup()

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
