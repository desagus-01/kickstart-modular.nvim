return {

  { -- requires plugins in lua/plugins/treesitter.lua and lua/plugins/lsp.lua
    -- for complete functionality (language features)
    'quarto-dev/quarto-nvim',
    dev = false,
    opts = {
      lspFeatures = {
        enabled = true,
        chunks = 'curly',
      },
      codeRunner = {
        enabled = true,
        default_method = 'slime',
      },
    },
    dependencies = {
      -- for language features in code cells
      -- configured in lua/plugins/lsp.lua
      'jmbuhr/otter.nvim',
    },
  },

  { -- directly open ipynb files as quarto docuements
    -- and convert back behind the scenes
    'GCBallesteros/jupytext.nvim',
    opts = {
      custom_language_formatting = {
        python = {
          extension = 'qmd',
          style = 'quarto',
          force_ft = 'quarto',
        },
        r = {
          extension = 'qmd',
          style = 'quarto',
          force_ft = 'quarto',
        },
      },
    },
  },

  { -- send code from python/r/qmd documets to a terminal or REPL
    -- like ipython, R, bash
    'jpalardy/vim-slime',
    dev = false,
    init = function()
      vim.b['quarto_is_python_chunk'] = false
      Quarto_is_in_python_chunk = function()
        require('otter.tools.functions').is_otter_language_context 'python'
      end

      vim.cmd [[
      let g:slime_dispatch_ipython_pause = 100
      function SlimeOverride_EscapeText_quarto(text)
      call v:lua.Quarto_is_in_python_chunk()
      if exists('g:slime_python_ipython') && len(split(a:text,"\n")) > 1 && b:quarto_is_python_chunk && !(exists('b:quarto_is_r_mode') && b:quarto_is_r_mode)
      return ["%cpaste -q\n", g:slime_dispatch_ipython_pause, a:text, "--", "\n"]
      else
      if exists('b:quarto_is_r_mode') && b:quarto_is_r_mode && b:quarto_is_python_chunk
      return [a:text, "\n"]
      else
      return [a:text]
      end
      end
      endfunction
      ]]

      vim.g.slime_target = 'neovim'
      vim.g.slime_no_mappings = true
      vim.g.slime_python_ipython = 1
    end,
    config = function()
      vim.g.slime_input_pid = false
      vim.g.slime_suggest_default = true
      vim.g.slime_menu_config = false
      vim.g.slime_neovim_ignore_unlisted = true

      local function mark_terminal()
        local job_id = vim.b.terminal_job_id
        vim.print('job_id: ' .. job_id)
      end

      local function set_terminal()
        vim.fn.call('slime#config', {})
      end
      vim.keymap.set('n', '<leader>cm', mark_terminal, { desc = '[m]ark terminal' })
      vim.keymap.set('n', '<leader>cs', set_terminal, { desc = '[s]et terminal' })
      vim.keymap.set('n', '<leader>Qtm', mark_terminal, { desc = 'Quarto: [m]ark terminal' })
      vim.keymap.set('n', '<leader>Qts', set_terminal, { desc = 'Quarto: [s]et terminal' })
    end,
  },

  { -- paste an image from the clipboard or drag-and-drop
    'HakonHarnes/img-clip.nvim',
    event = 'BufEnter',
    ft = { 'markdown', 'quarto', 'latex' },
    opts = {
      default = {
        dir_path = 'img',
        drag_and_drop = {
          enabled = false,
          insert_mode = false,
        },
      },
      filetypes = {
        markdown = {
          url_encode_path = true,
          template = '![$CURSOR]($FILE_PATH)',
          drag_and_drop = {
            download_images = false,
          },
        },
        quarto = {
          url_encode_path = true,
          template = '![$CURSOR]($FILE_PATH)',
          drag_and_drop = {
            download_images = false,
          },
        },
      },
    },
    config = function(_, opts)
      require('img-clip').setup(opts)
      vim.keymap.set('n', '<leader>ii', ':PasteImage<cr>', { desc = 'insert [i]mage from clipboard' })
    end,
  },

  { -- preview equations
    'jbyuki/nabla.nvim',
    keys = {
      { '<leader>qm', ':lua require"nabla".toggle_virt()<cr>', desc = 'toggle [m]ath equations' },
    },
  },

  {
    'benlubas/molten-nvim',
    dev = false,
    enabled = false,
    version = '^1.0.0', -- use version <2.0.0 to avoid breaking changes
    build = ':UpdateRemotePlugins',
    init = function()
      vim.g.molten_image_provider = 'image.nvim'
      -- vim.g.molten_output_win_max_height = 20
      vim.g.molten_auto_open_output = true
      vim.g.molten_auto_open_html_in_browser = true
      vim.g.molten_tick_rate = 200
    end,
    config = function()
      local init = function()
        local quarto_cfg = require('quarto.config').config
        quarto_cfg.codeRunner.default_method = 'molten'
        vim.cmd [[MoltenInit]]
      end
      local deinit = function()
        local quarto_cfg = require('quarto.config').config
        quarto_cfg.codeRunner.default_method = 'slime'
        vim.cmd [[MoltenDeinit]]
      end
      vim.keymap.set('n', '<localleader>mi', init, { silent = true, desc = 'Initialize molten' })
      vim.keymap.set('n', '<localleader>md', deinit, { silent = true, desc = 'Stop molten' })
      vim.keymap.set('n', '<localleader>mp', ':MoltenImagePopup<CR>', { silent = true, desc = 'molten image popup' })
      vim.keymap.set('n', '<localleader>mb', ':MoltenOpenInBrowser<CR>', { silent = true, desc = 'molten open in browser' })
      vim.keymap.set('n', '<localleader>mh', ':MoltenHideOutput<CR>', { silent = true, desc = 'hide output' })
      vim.keymap.set('n', '<localleader>ms', ':noautocmd MoltenEnterOutput<CR>', { silent = true, desc = 'show/enter output' })
    end,
  },

  {
    'quarto-keymaps',
    dir = vim.fn.stdpath 'config',
    lazy = false,
    config = function()
      vim.g['quarto_is_r_mode'] = nil
      vim.g['reticulate_running'] = false

      local function map(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { silent = true, noremap = true, desc = desc })
      end

      local function send_cell()
        local has_molten, molten_status = pcall(require, 'molten.status')
        local molten_works = false
        local molten_active = ''
        if has_molten then
          molten_works, molten_active = pcall(molten_status.kernels)
        end
        if molten_works and molten_active ~= vim.NIL and molten_active ~= '' then
          molten_active = molten_status.initialized()
        end
        if molten_active ~= vim.NIL and molten_active ~= '' and molten_status.kernels() ~= 'Molten' then
          vim.cmd.QuartoSend()
          return
        end

        if vim.b['quarto_is_r_mode'] == nil then
          vim.fn['slime#send_cell']()
          return
        end
        if vim.b['quarto_is_r_mode'] == true then
          vim.g.slime_python_ipython = 0
          local is_python = require('otter.tools.functions').is_otter_language_context 'python'
          if is_python and not vim.b['reticulate_running'] then
            vim.fn['slime#send']('reticulate::repl_python()' .. '\r')
            vim.b['reticulate_running'] = true
          end
          if not is_python and vim.b['reticulate_running'] then
            vim.fn['slime#send']('exit' .. '\r')
            vim.b['reticulate_running'] = false
          end
          vim.fn['slime#send_cell']()
        end
      end

      local slime_send_region_cmd = ':<C-u>call slime#send_op(visualmode(), 1)<CR>'
      slime_send_region_cmd = vim.api.nvim_replace_termcodes(slime_send_region_cmd, true, false, true)

      local function send_region()
        if vim.bo.filetype ~= 'quarto' or vim.b['quarto_is_r_mode'] == nil then
          vim.cmd('normal' .. slime_send_region_cmd)
          return
        end
        if vim.b['quarto_is_r_mode'] == true then
          vim.g.slime_python_ipython = 0
          local is_python = require('otter.tools.functions').is_otter_language_context 'python'
          if is_python and not vim.b['reticulate_running'] then
            vim.fn['slime#send']('reticulate::repl_python()' .. '\r')
            vim.b['reticulate_running'] = true
          end
          if not is_python and vim.b['reticulate_running'] then
            vim.fn['slime#send']('exit' .. '\r')
            vim.b['reticulate_running'] = false
          end
          vim.cmd('normal' .. slime_send_region_cmd)
        end
      end

      local function is_code_chunk(lang)
        return require('otter.keeper').get_current_language_context() == lang
      end

      local function insert_a_code_chunk(lang, curly)
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<esc>', true, false, true), 'n', true)
        local keys
        if curly == nil then
          curly = true
        end
        if is_code_chunk(lang) then
          if curly then
            keys = [[o```<cr><cr>```{]] .. lang .. [[}<esc>o]]
          else
            keys = [[o```<cr><cr>```]] .. lang .. [[<esc>o]]
          end
        else
          if curly then
            keys = [[o```{]] .. lang .. [[}<cr>```<esc>O]]
          else
            keys = [[o```]] .. lang .. [[<cr>```<esc>O]]
          end
        end
        keys = vim.api.nvim_replace_termcodes(keys, true, false, true)
        vim.api.nvim_feedkeys(keys, 'n', false)
      end

      local function insert_code_chunk(lang)
        insert_a_code_chunk(lang, true)
      end

      local function insert_plain_code_chunk(lang)
        insert_a_code_chunk(lang, false)
      end

      local function new_terminal(lang)
        vim.cmd('vsplit term://' .. lang)
      end

      local function get_otter_symbols_lang()
        local otterkeeper = require 'otter.keeper'
        local main_nr = vim.api.nvim_get_current_buf()
        local langs = {}
        for i, l in ipairs(otterkeeper.rafts[main_nr].languages) do
          langs[i] = i .. ': ' .. l
        end
        local i = vim.fn.inputlist(langs)
        local lang = otterkeeper.rafts[main_nr].languages[i]
        local params = {
          textDocument = vim.lsp.util.make_text_document_params(),
          otter = { lang = lang },
        }
        vim.lsp.buf_request(main_nr, vim.lsp.protocol.Methods.textDocument_documentSymbol, params, nil)
      end

      local function show_r_table()
        local node = vim.treesitter.get_node { ignore_injections = false }
        assert(node, 'no symbol found under cursor')
        local text = vim.treesitter.get_node_text(node, 0)
        vim.cmd([[call slime#send("DT::datatable(]] .. text .. [[)" . "\r")]])
      end

      map('n', '<leader>Q<CR>', send_cell, 'Quarto: run code cell')
      map({ 'n', 'i' }, '<C-CR>', send_cell, 'Quarto: run code cell')
      map('v', '<CR>', send_region, 'Quarto: run code region')

      map('n', '<leader>Qa', ':QuartoActivate<CR>', 'Quarto: activate')
      map('n', '<leader>Qe', require('otter').export, 'Quarto: export')
      map('n', '<leader>QE', function()
        require('otter').export(true)
      end, 'Quarto: export with overwrite')
      map('n', '<leader>Qh', ':QuartoHelp ', 'Quarto: help')
      map('n', '<leader>Qp', function()
        require('quarto').quartoPreview()
      end, 'Quarto: preview')
      map('n', '<leader>Qu', function()
        require('quarto').quartoUpdatePreview()
      end, 'Quarto: update preview')
      map('n', '<leader>Qq', function()
        require('quarto').quartoClosePreview()
      end, 'Quarto: close preview')

      map('n', '<leader>Qra', ':QuartoSendAll<CR>', 'Quarto: run all')
      map('n', '<leader>Qrb', ':QuartoSendBelow<CR>', 'Quarto: run below')
      map('n', '<leader>Qrr', ':QuartoSendAbove<CR>', 'Quarto: run to cursor')

      map('n', '<leader>Qoa', require('otter').activate, 'Quarto: otter activate')
      map('n', '<leader>Qod', require('otter').deactivate, 'Quarto: otter deactivate')
      map('n', '<leader>Qos', get_otter_symbols_lang, 'Quarto: otter symbols')

      map('n', '<leader>Qcr', function()
        insert_code_chunk 'r'
      end, 'Quarto: R code chunk')
      map('n', '<leader>Qcp', function()
        insert_code_chunk 'python'
      end, 'Quarto: Python code chunk')
      map('n', '<leader>Qcl', function()
        insert_code_chunk 'lua'
      end, 'Quarto: Lua code chunk')
      map('n', '<leader>Qcj', function()
        insert_code_chunk 'julia'
      end, 'Quarto: Julia code chunk')
      map('n', '<leader>Qcb', function()
        insert_code_chunk 'bash'
      end, 'Quarto: Bash code chunk')
      map('n', '<leader>Qco', function()
        insert_code_chunk 'ojs'
      end, 'Quarto: OJS code chunk')

      map('n', '<leader>QCr', function()
        insert_plain_code_chunk 'r'
      end, 'Quarto: plain R code chunk')
      map('n', '<leader>QCp', function()
        insert_plain_code_chunk 'python'
      end, 'Quarto: plain Python code chunk')
      map('n', '<leader>QCl', function()
        insert_plain_code_chunk 'lua'
      end, 'Quarto: plain Lua code chunk')
      map('n', '<leader>QCj', function()
        insert_plain_code_chunk 'julia'
      end, 'Quarto: plain Julia code chunk')
      map('n', '<leader>QCb', function()
        insert_plain_code_chunk 'bash'
      end, 'Quarto: plain Bash code chunk')
      map('n', '<leader>QCo', function()
        insert_plain_code_chunk 'ojs'
      end, 'Quarto: plain OJS code chunk')

      map('n', '<leader>Qti', function()
        new_terminal 'ipython --no-confirm-exit --no-autoindent'
      end, 'Quarto: new IPython terminal')
      map('n', '<leader>Qtp', function()
        new_terminal 'python'
      end, 'Quarto: new Python terminal')
      map('n', '<leader>Qtr', function()
        new_terminal 'R --no-save'
      end, 'Quarto: new R terminal')
      map('n', '<leader>Qtj', function()
        new_terminal 'julia'
      end, 'Quarto: new Julia terminal')
      map('n', '<leader>Qtn', function()
        new_terminal '$SHELL'
      end, 'Quarto: new shell terminal')

      map('n', '<leader>Qrt', show_r_table, 'Quarto: show R table')
    end,
  },
}
