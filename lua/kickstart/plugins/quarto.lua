-- ============================================================================
-- KERNEL CONFIGURATION
-- ============================================================================
local R_KERNEL = 'ir'
local BASH_KERNEL = 'bash'
local PYTHON_FALLBACK_KERNEL = 'python3'

local kernel_ids_by_buf = {}

-- Kernel lifecycle state.
-- MoltenInit creates the kernel, but the Jupyter kernel may not yet be ready
-- to receive code. We keep callbacks queued until MoltenKernelReady fires.
local ready_kernels = {}
local starting_kernels = {}
local kernel_waiters = {}

-- ============================================================================
-- GENERAL HELPERS
-- ============================================================================

local function contains(tbl, value)
  for _, item in ipairs(tbl or {}) do
    if item == value then
      return true
    end
  end

  return false
end

local function available_kernels()
  local ok, kernels = pcall(vim.fn.MoltenAvailableKernels)

  if not ok then
    return {}
  end

  return kernels
end

local function local_running_kernels()
  local ok, kernels = pcall(vim.fn.MoltenRunningKernels, true)

  if not ok then
    return {}
  end

  return kernels
end

local function kernel_map()
  local buf = vim.api.nvim_get_current_buf()

  if kernel_ids_by_buf[buf] == nil then
    kernel_ids_by_buf[buf] = {}
  end

  return kernel_ids_by_buf[buf]
end

local molten_lifecycle_group = vim.api.nvim_create_augroup('QuartoMoltenKernelLifecycle', { clear = true })

vim.api.nvim_create_autocmd('User', {
  group = molten_lifecycle_group,
  pattern = 'MoltenKernelReady',

  callback = function(event)
    local kernel_id = event.data and event.data.kernel_id

    if not kernel_id then
      return
    end

    ready_kernels[kernel_id] = true
    starting_kernels[kernel_id] = nil

    local waiters = kernel_waiters[kernel_id]

    if not waiters then
      return
    end

    kernel_waiters[kernel_id] = nil

    -- Run all queued evaluations in the order they were requested.
    vim.schedule(function()
      for _, callback in ipairs(waiters) do
        local ok, err = pcall(callback, kernel_id)

        if not ok then
          vim.notify(("Error executing code with kernel '%s': %s"):format(kernel_id, err), vim.log.levels.ERROR)
        end
      end
    end)
  end,
})

-- Clean our per-buffer bookkeeping when a buffer disappears.
vim.api.nvim_create_autocmd('BufWipeout', {
  group = molten_lifecycle_group,

  callback = function(event)
    kernel_ids_by_buf[event.buf] = nil
  end,
})

local function when_kernel_ready(kernel_id, callback)
  -- Kernel is already confirmed ready.
  if ready_kernels[kernel_id] then
    callback(kernel_id)
    return
  end

  -- If we know that WE just started this kernel, wait for
  -- MoltenKernelReady.
  if starting_kernels[kernel_id] then
    kernel_waiters[kernel_id] = kernel_waiters[kernel_id] or {}

    table.insert(kernel_waiters[kernel_id], callback)

    return
  end

  -- If the kernel already existed before our helper saw it, for example
  -- because it was manually initialized, assume it is already usable.
  ready_kernels[kernel_id] = true

  callback(kernel_id)
end

-- ============================================================================
-- KERNEL IDS
-- ============================================================================
local function kernel_id_matches_spec(kernel_id, kernel_spec)
  if kernel_id == kernel_spec then
    return true
  end

  local prefix = kernel_spec .. '_'

  if kernel_id:sub(1, #prefix) ~= prefix then
    return false
  end

  return tonumber(kernel_id:sub(#prefix + 1)) ~= nil
end

local function find_local_kernel_id(kernel_spec)
  local running = local_running_kernels()
  local map = kernel_map()

  -- Prefer the ID we already remembered.
  if map[kernel_spec] and contains(running, map[kernel_spec]) then
    return map[kernel_spec]
  end

  map[kernel_spec] = nil

  -- Recover kernels that were initialized manually.
  for _, kernel_id in ipairs(running) do
    if kernel_id_matches_spec(kernel_id, kernel_spec) then
      map[kernel_spec] = kernel_id

      return kernel_id
    end
  end

  return nil
end

-- ============================================================================
-- PYTHON ENVIRONMENT DETECTION
-- ============================================================================
local function python_kernel()
  local kernels = available_kernels()

  local env = vim.env.VIRTUAL_ENV or vim.env.CONDA_PREFIX

  if env and env ~= '' then
    local env_name = vim.fn.fnamemodify(env, ':t')

    if contains(kernels, env_name) then
      return env_name
    end
  end

  return PYTHON_FALLBACK_KERNEL
end

-- ============================================================================
-- LANGUAGE -> KERNEL ROUTING
-- ============================================================================

local function kernel_for_language(lang)
  if lang == 'r' then
    return R_KERNEL
  end

  if lang == 'python' then
    return python_kernel()
  end

  if lang == 'bash' or lang == 'sh' then
    return BASH_KERNEL
  end

  return nil
end

-- ============================================================================
-- INITIALIZE ONE KERNEL
-- ============================================================================

local function init_kernel(kernel_spec)
  if not contains(available_kernels(), kernel_spec) then
    vim.notify(("Jupyter kernel '%s' is not installed."):format(kernel_spec), vim.log.levels.WARN)

    return nil
  end

  -- Already attached to this buffer.
  local existing = find_local_kernel_id(kernel_spec)

  if existing then
    return existing
  end

  local before = local_running_kernels()

  -- Clear stale readiness information for old kernels with the same
  -- kernelspec that are no longer running.
  for kernel_id, _ in pairs(ready_kernels) do
    if kernel_id_matches_spec(kernel_id, kernel_spec) and not contains(before, kernel_id) then
      ready_kernels[kernel_id] = nil
      starting_kernels[kernel_id] = nil
      kernel_waiters[kernel_id] = nil
    end
  end

  -- Start the Jupyter kernel.
  vim.cmd('MoltenInit ' .. kernel_spec)

  local after = local_running_kernels()

  local map = kernel_map()

  -- Find the newly-created Molten kernel ID.
  for _, kernel_id in ipairs(after) do
    if not contains(before, kernel_id) then
      map[kernel_spec] = kernel_id

      -- If MoltenKernelReady somehow already fired during MoltenInit,
      -- do not overwrite that ready state.
      if not ready_kernels[kernel_id] then
        starting_kernels[kernel_id] = true
      end

      return kernel_id
    end
  end

  -- Fallback in case Molten reused something unexpectedly.
  local recovered = find_local_kernel_id(kernel_spec)

  if recovered then
    return recovered
  end

  vim.notify(("Molten could not initialize kernel '%s'."):format(kernel_spec), vim.log.levels.ERROR)

  return nil
end

local function init_quarto_kernels() -- not really needed, but can be useful
  local specs = {
    R_KERNEL,
    python_kernel(),
    BASH_KERNEL,
  }

  local seen = {}

  for _, kernel_spec in ipairs(specs) do
    if kernel_spec and not seen[kernel_spec] then
      init_kernel(kernel_spec)
      seen[kernel_spec] = true
    end
  end

  vim.notify('Quarto kernels starting/attached.', vim.log.levels.INFO)
end

-- ============================================================================
-- GET / START THE CORRECT KERNEL
-- ============================================================================
-- callback(kernel_id) is called:
--
--   immediately  -> if kernel is ready
--   later        -> if kernel must first finish starting
-- ============================================================================

local function with_kernel_for_language(lang, callback)
  local kernel_spec = kernel_for_language(lang)

  if not kernel_spec then
    vim.notify(("No Molten kernel configured for '%s'."):format(lang or 'unknown'), vim.log.levels.ERROR)

    return
  end

  local kernel_id = find_local_kernel_id(kernel_spec)

  -- Auto-initialize on first use.
  if not kernel_id then
    kernel_id = init_kernel(kernel_spec)
  end

  if not kernel_id then
    return
  end

  -- Execute immediately if ready, otherwise queue until
  -- MoltenKernelReady.
  when_kernel_ready(kernel_id, callback)
end

local function molten_quarto_runner(cell, _ignore_cols)
  -- Capture the cell location BEFORE waiting for the kernel.
  -- This means you can move your cursor while the kernel is starting
  -- and Molten still executes the originally-requested chunk.
  local first_line = cell.range.from[1] + 1

  local last_line = cell.range.to[1]

  if last_line < first_line then
    last_line = first_line
  end

  with_kernel_for_language(cell.lang, function(kernel_id)
    vim.fn.MoltenEvaluateRange(kernel_id, first_line, last_line)
  end)
end

-- ============================================================================
-- PLUGINS
-- ============================================================================

return {

  {
    'benlubas/molten-nvim',

    lazy = false,

    version = '^1.0.0',

    build = ':UpdateRemotePlugins',

    dependencies = {
      {
        '3rd/image.nvim',

        build = false,

        opts = {
          processor = 'magick_cli',
        },
      },
    },
    config = function()
      vim.api.nvim_set_hl(0, 'MoltenVirtualText', { link = 'NormalFloat' })

      vim.api.nvim_set_hl(0, 'MoltenOutputWin', { link = 'NormalFloat' })

      vim.api.nvim_set_hl(0, 'MoltenOutputFooter', { link = 'Comment' })
    end,

    init = function()
      vim.g.molten_image_provider = 'image.nvim'

      -- Inline output
      vim.g.molten_auto_open_output = false
      vim.g.molten_virt_text_output = true
      vim.g.molten_virt_lines_off_by_1 = true
      vim.g.molten_wrap_output = true
      vim.g.molten_virt_text_max_lines = 8
      vim.g.molten_virt_text_truncate = 'bottom'

      -- Expanded output
      vim.g.molten_enter_output_behavior = 'open_and_enter'

      vim.g.molten_output_win_max_height = 30
      vim.g.molten_output_win_max_width = 120

      vim.g.molten_output_win_border = {
        '╭',
        '─',
        '╮',
        '│',
        '╯',
        '─',
        '╰',
        '│',
      }

      vim.g.molten_use_border_highlights = true
      vim.g.molten_output_show_more = true

      -- Once we leave/close the popup, don't redraw it.
      vim.g.molten_output_win_hide_on_leave = true

      vim.g.molten_auto_init_behavior = 'raise'
      vim.g.molten_auto_open_html_in_browser = true
      vim.g.molten_tick_rate = 200
    end,
  },

  {
    'quarto-dev/quarto-nvim',

    dependencies = {
      'jmbuhr/otter.nvim',
      'benlubas/molten-nvim',
    },

    opts = {
      lspFeatures = {
        enabled = true,

        chunks = 'all',

        languages = {
          'r',
          'python',
          'bash',
        },
      },

      codeRunner = {
        enabled = true,

        -- Everything runs through our language-aware Molten runner.
        default_method = molten_quarto_runner,

        never_run = {
          'yaml',
        },
      },
    },

    config = function(_, opts)
      require('quarto').setup(opts)
      local function open_molten_output_centered()
        -- Open AND enter Molten's output window.
        vim.cmd 'noautocmd MoltenEnterOutput'

        -- Let Molten finish constructing the float first.
        vim.schedule(function()
          local win = vim.api.nvim_get_current_win()

          if not vim.api.nvim_win_is_valid(win) then
            return
          end

          local cfg = vim.api.nvim_win_get_config(win)

          -- If this isn't a floating window, something went wrong.
          if not cfg.relative or cfg.relative == '' then
            vim.notify('No Molten output window available for the current cell.', vim.log.levels.WARN)
            return
          end

          -- Maximum desired popup size relative to the editor.
          local max_width = math.floor(vim.o.columns * 0.80)
          local max_height = math.floor(vim.o.lines * 0.70)

          local width = math.min(cfg.width, max_width)
          local height = math.min(cfg.height, max_height)

          -- Center the window.
          local row = math.floor((vim.o.lines - height) / 2) - 1
          local col = math.floor((vim.o.columns - width) / 2)

          row = math.max(row, 0)
          col = math.max(col, 0)

          vim.api.nvim_win_set_config(win, {
            relative = 'editor',
            anchor = 'NW',

            row = row,
            col = col,

            width = width,
            height = height,

            zindex = 100,
          })

          local buf = vim.api.nvim_win_get_buf(win)

          -- q = close popup and return to document
          vim.keymap.set('n', 'q', '<cmd>q<CR>', {
            buffer = buf,
            silent = true,
            nowait = true,
            desc = 'Close Molten output',
          })

          -- Esc can close it too.
          vim.keymap.set('n', '<Esc>', '<cmd>q<CR>', {
            buffer = buf,
            silent = true,
            nowait = true,
            desc = 'Close Molten output',
          })
        end)
      end
      local runner = require 'quarto.runner'

      local function map(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, {
          silent = true,
          noremap = true,
          desc = desc,
        })
      end

      -- ======================================================================
      -- KEYMAPS: RUN CODE
      -- ======================================================================
      map('n', '<leader>Qrr', runner.run_cell, 'Quarto: run current cell')

      map('n', '<leader>Qra', function()
        runner.run_all(true)
      end, 'Quarto: run all cells')

      map('n', '<leader>Qrb', function()
        runner.run_below(true)
      end, 'Quarto: run current cell and below')

      map('n', '<leader>Qru', function()
        runner.run_above(true)
      end, 'Quarto: run through current cell')

      map('n', '<leader>Qrl', runner.run_line, 'Quarto: run current line')
      map('v', '<leader>Qrv', runner.run_range, 'Quarto: run visual selection')

      -- ======================================================================
      -- KEYMAPS: MOLTEN / KERNEL MANAGEMENT
      -- ======================================================================
      map('n', '<leader>Qmi', init_quarto_kernels, 'Molten: preload R/Python/Bash')

      map('n', '<leader>QmI', ':MoltenInit<CR>', 'Molten: initialize kernel manually')

      map('n', '<leader>Qmd', ':MoltenDeinit<CR>', 'Molten: deinitialize')

      map('n', '<leader>Qmf', ':MoltenInfo<CR>', 'Molten: info')

      map('n', '<leader>Qmh', ':MoltenHideOutput<CR>', 'Molten: hide output')

      map('n', '<leader>Qmo', open_molten_output_centered, 'Molten: open output')

      map('n', '<leader>Qo', open_molten_output_centered, 'Molten: open output')

      map('n', '<leader>Qmp', ':MoltenImagePopup<CR>', 'Molten: image popup')

      map('n', '<leader>Qmx', ':MoltenDelete<CR>', 'Molten: delete cell/output')

      -- ======================================================================
      -- KEYMAPS: QUARTO
      -- ======================================================================
      map('n', '<leader>Qa', ':QuartoActivate<CR>', 'Quarto: activate')

      map('n', '<leader>Qp', require('quarto').quartoPreview, 'Quarto: preview')

      map('n', '<leader>Qu', require('quarto').quartoUpdatePreview, 'Quarto: update preview')

      map('n', '<leader>Qq', require('quarto').quartoClosePreview, 'Quarto: close preview')

      map('n', '<leader>Qh', ':QuartoHelp ', 'Quarto: help')

      map('n', '<leader>Qe', require('otter').export, 'Quarto: export')

      map('n', '<leader>QE', function()
        require('otter').export(true)
      end, 'Quarto: export with overwrite')

      -- ======================================================================
      -- CODE CHUNK INSERTION
      -- ======================================================================

      local function is_code_chunk(lang)
        return require('otter.keeper').get_current_language_context() == lang
      end

      local function insert_code_chunk(lang)
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<esc>', true, false, true), 'n', true)

        local keys

        if is_code_chunk(lang) then
          keys = [[o```<cr><cr>```{]] .. lang .. [[}<esc>o]]
        else
          keys = [[o```{]] .. lang .. [[}<cr>```<esc>O]]
        end

        keys = vim.api.nvim_replace_termcodes(keys, true, false, true)

        vim.api.nvim_feedkeys(keys, 'n', false)
      end

      -- ======================================================================
      -- KEYMAPS: INSERT CODE CHUNKS
      -- ======================================================================
      map('n', '<leader>Qcr', function()
        insert_code_chunk 'r'
      end, 'Quarto: insert R chunk')

      map('n', '<leader>Qcp', function()
        insert_code_chunk 'python'
      end, 'Quarto: insert Python chunk')

      map('n', '<leader>Qcb', function()
        insert_code_chunk 'bash'
      end, 'Quarto: insert Bash chunk')
    end,
  },
  -- ==========================================================================
  -- IMAGE PASTE
  -- ==========================================================================

  {
    'HakonHarnes/img-clip.nvim',

    event = 'BufEnter',

    ft = {
      'markdown',
      'quarto',
      'latex',
    },

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

      vim.keymap.set('n', '<leader>ii', ':PasteImage<CR>', {
        desc = 'Insert image from clipboard',
      })
    end,
  },

  -- ==========================================================================
  -- EQUATION PREVIEW
  -- ==========================================================================

  {
    'jbyuki/nabla.nvim',

    keys = {
      {
        '<leader>qm',

        ':lua require("nabla").toggle_virt()<CR>',

        desc = 'Toggle math equations',
      },
    },
  },
}
