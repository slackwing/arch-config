return {
  'nvim-mini/mini.diff',
  version = '*',
  config = function()
    require('mini.diff').setup {
      mappings = {
        goto_first = ';h',
        goto_prev = ';k',
        goto_next = ';j',
        goto_last = ';l',
      },
      options = {
        wrap_goto = true,
      },
    }
    vim.keymap.set('n', ';a', function()
      vim.cmd 'normal ghgh;j'
    end, { desc = 'MiniDiff: apply hunk under cursor' })
    vim.keymap.set('n', ';r', function()
      vim.cmd 'normal gHgh;j'
    end, { desc = 'MiniDiff: reset hunk under cursor' })
    vim.keymap.set('n', ';d', function()
      MiniDiff.toggle_overlay()
    end)
    vim.api.nvim_set_hl(0, 'MiniDiffOverAdd', {
      fg = '#000000',
      bg = '#98c379',
    })
    vim.api.nvim_set_hl(0, 'MiniDiffOverChange', {
      fg = '#000000',
      bg = '#d1aa66',
    })
    vim.api.nvim_set_hl(0, 'MiniDiffOverDelete', {
      fg = '#000000',
      bg = '#e06c75',
    })
    local function MiniDiffBatch(action_key)
      local feed = function(keys)
        local tc = vim.api.nvim_replace_termcodes(keys, true, false, true)
        vim.api.nvim_feedkeys(tc, 'x', false)
      end
      feed ';h'
      vim.wait(50)
      local seen = {}
      local function key(pos)
        return pos[2] .. ':' .. pos[3]
      end
      while true do
        local pos = vim.fn.getpos '.'
        local k = key(pos)
        if seen[k] then
          break
        end
        seen[k] = true
        feed(action_key)
        vim.wait(50)
        local before = vim.fn.getpos '.'
        feed ';j'
        vim.wait(50)
        local after = vim.fn.getpos '.'
        if before[2] == after[2] and before[3] == after[3] then
          break
        end
      end
    end

    vim.keymap.set('n', ';A', function()
      MiniDiffBatch ';a'
    end)
    vim.keymap.set('n', ';R', function()
      MiniDiffBatch ';r'
    end)
  end,
}
