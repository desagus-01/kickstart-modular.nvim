return {
  'yousefhadder/markdown-plus.nvim',
  ft = 'markdown',
  opts = {
    list = {
      checkbox_completion = {
        enabled = true,
      },
    },
  },
  config = function(_, opts)
    require('markdown-plus').setup(opts)

    -- Move markdown-plus table keymaps from <leader>t{...} -> <leader>mt{...}
    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'markdown',
      callback = function(ev)
        local bufnr = ev.buf

        -- All table-related <leader>t mappings from the wiki
        -- https://github.com/YousefHadder/markdown-plus.nvim/wiki/5.Keymaps#tables-normal--insert-mode
        local suffixes = {
          'c', -- create
          'f', -- format
          'n', -- normalize
          'ir', -- insert row below
          'iR', -- insert row above
          'dr', -- delete row
          'yr', -- duplicate row
          'ic', -- insert col right
          'iC', -- insert col left
          'dc', -- delete col
          'yc', -- duplicate col
          'a', -- toggle alignment
          'x', -- clear cell
          'mh', -- move col left
          'ml', -- move col right
          'mk', -- move row up
          'mj', -- move row down
          't', -- transpose (this is the one that often collides: <leader>tt)
          'sa', -- sort asc
          'sd', -- sort desc
          'vx', -- table -> csv
          'vi', -- csv -> table
        }

        local function boolish(v)
          return v == 1 or v == true
        end

        for _, suf in ipairs(suffixes) do
          local old_lhs = '<leader>t' .. suf
          local new_lhs = '<leader>mt' .. suf

          -- Fetch the existing mapping (buffer-local preferred; falls back if needed)
          local m = vim.fn.maparg(old_lhs, 'n', false, true)

          -- If it's not mapped, skip quietly
          if m and (m.rhs ~= '' or m.callback ~= nil) then
            local rhs = m.callback or m.rhs

            -- Recreate mapping under <leader>mt...
            vim.keymap.set('n', new_lhs, rhs, {
              buffer = bufnr,
              silent = true,
              expr = boolish(m.expr),
              nowait = boolish(m.nowait),
              -- If original was noremap=1, keep it non-remapped.
              -- If original was remappable, keep it remappable.
              remap = not boolish(m.noremap),
              desc = (m.desc and ('md+ table: ' .. m.desc)) or nil,
            })

            -- Remove the old <leader>t... mapping so it stops conflicting
            pcall(vim.keymap.del, 'n', old_lhs, { buffer = bufnr })
          end
        end
      end,
    })
  end,
}
