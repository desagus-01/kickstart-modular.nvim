return {
  'olimorris/codecompanion.nvim',
  dependencies = {
    {
      'ravitemer/mcphub.nvim',
      dependencies = {
        { 'nvim-lua/plenary.nvim', version = false },
        'franco-ruggeri/codecompanion-spinner.nvim',
      },
      lazy = false,

      build = 'npm install -g mcp-hub@latest',
      opts = {
        config = vim.fn.expand '~/.config/nvim/mcphub/servers.json',
      },
      config = function(_, opts)
        require('mcphub').setup(opts)
      end,
    },
  },

  opts = function()
    local model_name = 'gpt-5-mini'

    if not vim.env.CODECOMPANION_TOKEN_PATH then
      vim.env.CODECOMPANION_TOKEN_PATH = vim.fn.expand '~/.config'
    end

    local function map(modes, lhs, rhs, desc)
      vim.keymap.set(modes, lhs, rhs, {
        noremap = true,
        silent = true,
        desc = desc,
      })
    end

    map('n', '<leader>cc', '<cmd>CodeCompanionChat Toggle<CR>', 'CodeCompanion chat')
    map('n', '<leader>ca', '<cmd>CodeCompanion<CR>', 'CodeCompanion inline')
    map('v', '<leader>ci', ":'<,'>CodeCompanion<CR>", 'CodeCompanion inline selection')
    map('v', '<leader>cs', ":'<,'>CodeCompanionChat<CR>", 'CodeCompanion chat selection')
    map('n', '<leader>cm', '<cmd>CodeCompanionCmd<CR>', 'CodeCompanion cmd')
    map('n', '<leader>cp', '<cmd>CodeCompanionActions<CR>', 'CodeCompanion actions')
    map('n', '<leader>cs', '<cmd>MCPHub<CR>', 'MCPHub')

    return {
      opts = {
        log_level = 'DEBUG',
        send_code = true,
        use_default_actions = true,
        use_default_prompts = true,
      },

      display = {
        action_palette = {
          provider = 'telescope',
        },
        chat = {
          show_context = true,
          show_tools_processing = true,
          show_token_count = true,
        },
      },

      interactions = {
        chat = {
          adapter = 'copilot',
          roles = {
            user = 'Gus',
            llm = '🤖 Copilot (' .. model_name .. ')',
          },
          tools = {
            opts = {
              auto_submit_errors = true,
              auto_submit_success = true,
              default_tools = {
                'agent',
                'read_file',
                'file_search',
                'grep_search',
                'run_command',
                'get_diagnostics',
                'get_changed_files',
              },
            },
            groups = {
              ['repo_analyst'] = {
                description = 'Analyse and summarise the codebase before editing',
                system_prompt = [[
You are a repository analyst working inside Neovim.
Your first job is to understand the codebase before proposing changes.

Rules:
- Prefer searching and reading before editing.
- Identify the most relevant files first.
- Summaries must mention file paths and responsibilities.
- For architecture questions, explain entrypoints, data flow, abstractions, and risks.
- Do not edit files unless explicitly asked.
                ]],
                tools = {
                  'read_file',
                  'file_search',
                  'grep_search',
                  'run_command',
                  'get_diagnostics',
                },
                opts = {
                  collapse_tools = true,
                  ignore_system_prompt = true,
                  ignore_tool_system_prompt = true,
                },
              },
            },
          },
        },

        inline = {
          adapter = 'copilot',
        },

        cmd = {
          adapter = 'copilot',
        },
      },

      adapters = {
        http = {
          opts = {
            show_model_choices = true,
          },

          copilot = function()
            return require('codecompanion.adapters').extend('copilot', {
              schema = {
                model = {
                  default = model_name,
                },
              },
            })
          end,
        },
      },

      extensions = {
        spinner = {},
        mcphub = {
          callback = 'mcphub.extensions.codecompanion',
          opts = {
            make_tools = true,
            show_server_tools_in_chat = true,
            add_mcp_prefix_to_tool_names = false,
            show_result_in_chat = true,
            make_vars = false,
            make_slash_commands = true,
          },
        },
      },
    }
  end,
}
