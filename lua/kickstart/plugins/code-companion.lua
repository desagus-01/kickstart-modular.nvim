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
    map('n', '<leader>cp', '<cmd>CodeCompanionActions<CR>', 'CodeCompanion actions')
    map('n', '<leader>cm', '<cmd>MCPHub<CR>', 'MCPHub')
    -- NOTE: YOLO mode toggle is built-in: `gty` inside any chat buffer.

    -- =========================================================================
    -- HELPERS
    -- =========================================================================
    local function load_system_prompt(filename)
      local path = vim.fn.stdpath 'config' .. '/prompts/' .. filename
      local lines = vim.fn.readfile(path)
      local in_system = false
      local result = {}
      for _, line in ipairs(lines) do
        if line:match '^## system' then
          in_system = true
        elseif line:match '^## ' and in_system then
          break
        elseif in_system then
          table.insert(result, line)
        end
      end
      return vim.trim(table.concat(result, '\n'))
    end

    -- =========================================================================
    -- AGENTIC WORKFLOWS
    -- Launched from Action Palette (<leader>cp).
    --   auto_submit=true  → fires without user input
    --   repeat_until      → re-attaches prompt until condition met
    --   condition         → only fires if predicate true
    --
    -- YOLO mode (gty in chat): bypasses insert_edit_into_file approvals.
    -- run_command still prompts once per unique cmd (security by default).
    -- To allow run_command in YOLO mode, uncomment the override in tools below.
    -- =========================================================================
    local workflows = {

      -- -----------------------------------------------------------------------
      -- P1: Edit → Test Loop
      -- LLM edits code, runs tests, loops until all tests pass.
      -- -----------------------------------------------------------------------
      ['⚡ Edit → Test Loop'] = {
        interaction = 'workflow',
        description = 'Edit code and run tests, looping until all tests pass',
        tools = {
          'read_file',
          'file_search',
          'grep_search',
          'insert_edit_into_file',
          'run_command',
          'get_diagnostics',
        },
        prompts = {
          -- Turn 1: setup — user reviews then submits
          {
            {
              name = 'Setup',
              role = 'user',
              opts = { auto_submit = false },
              content = function()
                local approvals = require 'codecompanion.interactions.chat.tools.approvals'
                approvals:toggle_yolo_mode()

                local test_cmd = vim.fn.input 'Test command (e.g. cargo test / pytest / npm test): '
                if test_cmd == '' then
                  test_cmd = '<your test command>'
                end

                return string.format(
                  [[### Task
Fix or implement the code so the test suite passes.

### Working File
#{buffer}{watch}

### Steps — follow exactly, no deviations
1. Read any relevant files first
2. Edit code using the insert_edit_into_file tool
3. Run tests using the run_command tool with: `%s`
4. Trigger BOTH tools in the **same response**

We will loop until tests pass.]],
                  test_cmd
                )
              end,
            },
          },
          -- Turn 2: reflect on failure, repeat until tests pass
          {
            {
              name = 'Reflect on Failure',
              role = 'user',
              opts = { auto_submit = true },
              condition = function(chat)
                return chat.tools.tool and chat.tools.tool.name == 'run_command'
              end,
              repeat_until = function(chat)
                return chat.tool_registry.flags.testing == true
              end,
              content = 'Tests are still failing. Analyse the output above, fix the code, and run the tests again.',
            },
          },
        },
      },

      -- -----------------------------------------------------------------------
      -- P4: Plan → Implement → Review
      -- Three-phase pipeline: architect plans, agent implements, reviewer checks.
      -- -----------------------------------------------------------------------
      ['\240\159\167\160 Plan \226\134\146 Implement \226\134\146 Review'] = {
        interaction = 'workflow',
        description = 'Architect plans, agent implements, reviewer checks for issues',
        tools = {
          'ask_questions',
          'read_file',
          'file_search',
          'grep_search',
          'insert_edit_into_file',
          'get_diagnostics',
          'get_changed_files',
          'sequential_thinking__sequentialthinking',
          'memory_mcp__create_entities',
          'memory_mcp__search_nodes',
        },
        prompts = {
          -- Turn 1: architecture phase
          {
            {
              name = 'Plan',
              role = 'user',
              opts = { auto_submit = false },
              content = function()
                local approvals = require 'codecompanion.interactions.chat.tools.approvals'
                approvals:toggle_yolo_mode()

                local task = vim.fn.input 'Describe the task: '
                if task == '' then
                  task = '[describe your task here]'
                end

                return string.format(
                  [[### Phase 1 — Architecture

You are acting as a senior architect. Before writing any code:

1. Use sequential_thinking to decompose the problem
2. Read relevant files to understand current structure
3. Produce:
   - **Analysis**: what the task requires
   - **Affected files**: which files need changing
   - **Plan**: numbered steps with rationale
   - **Risks**: edge cases or open questions
4. Store the plan in memory_mcp for reference

Do NOT write any code yet.

### Task
%s

### Codebase context
#{buffer}]],
                  task
                )
              end,
            },
          },
          -- Turn 2: implementation phase (auto-fires after plan)
          {
            {
              name = 'Implement',
              role = 'user',
              opts = { auto_submit = true },
              content = [[### Phase 2 — Implementation

The architecture plan above is approved. Now implement it:

1. Read each file before editing it
2. Use insert_edit_into_file to make changes
3. Run get_diagnostics after editing each file — fix any errors before moving on
4. Follow the plan step by step — no scope creep
5. When done, summarise what was changed and why]],
            },
          },
          -- Turn 3: review phase (auto-fires after implementation)
          {
            {
              name = 'Review',
              role = 'user',
              opts = { auto_submit = true },
              content = [[### Phase 3 — Review

Implementation complete. Now review it:

1. Use get_changed_files to see all changes
2. Use get_diagnostics on each changed file
3. Check for: bugs, missing error handling, security issues, logic errors
4. Rate each finding:
   - \240\159\148\180 Critical — will cause bugs or security issues
   - \240\159\237\161 Warning  — should fix, quality concern
   - \240\159\237\162 Suggest  — nice to have

If there are \240\159\148\180 Critical findings, list them clearly.
If all clear, say so explicitly.]],
            },
          },
        },
      },

      -- -----------------------------------------------------------------------
      -- P5: Research → Implement
      -- Research a topic with brave search, then implement a solution.
      -- -----------------------------------------------------------------------
      ['\240\159\148\172 Research \226\134\146 Implement'] = {
        interaction = 'workflow',
        description = 'Research a topic with brave search, then implement a solution',
        tools = {
          'read_file',
          'file_search',
          'fetch_webpage',
          'insert_edit_into_file',
          'get_diagnostics',
          'brave__brave_web_search',
          'sequential_thinking__sequentialthinking',
          'memory_mcp__create_entities',
          'memory_mcp__search_nodes',
        },
        prompts = {
          -- Turn 1: research phase
          {
            {
              name = 'Research',
              role = 'user',
              opts = { auto_submit = false },
              content = function()
                local approvals = require 'codecompanion.interactions.chat.tools.approvals'
                approvals:toggle_yolo_mode()

                local query = vim.fn.input 'Research query: '
                if query == '' then
                  query = '[describe what to research]'
                end

                return string.format(
                  [[### Phase 1 — Research

Research the following using brave_web_search and fetch_webpage.

Summarise your findings covering:
- Key APIs, patterns, and idioms
- Gotchas and version-specific notes
- Best practices and common pitfalls
- Any relevant examples

Store key findings in memory_mcp under a searchable key.

### Query
%s

### Codebase context
#{buffer}]],
                  query
                )
              end,
            },
          },
          -- Turn 2: implementation phase (auto-fires after research)
          {
            {
              name = 'Implement',
              role = 'user',
              opts = { auto_submit = true },
              content = [[### Phase 2 — Implementation

Research complete. Now implement a solution based on your findings:

1. Read relevant existing files first
2. Use insert_edit_into_file to write the code
3. Apply the best practices and patterns from your research
4. Run get_diagnostics after writing — fix any errors
5. Summarise what was implemented and any deviations from research

Working context: #{buffer}{watch}]],
            },
          },
        },
      },
    }

    -- =========================================================================
    -- MAIN CONFIG
    -- =========================================================================
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
          show_header_separator = true,
          show_token_count = true,
          window = {
            layout = 'vertical',
            width = 0.35,
          },
        },
      },

      interactions = {
        chat = {
          adapter = 'copilot',
          roles = {
            user = 'Gus',
            llm = '\240\159\164\150 Copilot (' .. model_name .. ')',
          },
          tools = {
            opts = {
              auto_submit_errors = true,
              auto_submit_success = true,
            },

            -- Uncomment to allow run_command to fire in YOLO mode (gty).
            -- By default run_command prompts once per unique command.
            -- Only enable if you trust the LLM not to run destructive commands.
            -- ['run_command'] = {
            --   opts = { allowed_in_yolo_mode = true },
            -- },

            groups = {
              ['planner'] = {
                description = 'Architecture planner — sequential thinking + memory, no code edits',
                system_prompt = function(_, ctx)
                  local base = load_system_prompt 'architect.md'
                  return base
                    .. string.format(
                      '\n\nContext: Neovim %s, %s, date %s.\nUse sequential_thinking tools to decompose problems. Store decisions with memory_mcp tools.',
                      ctx.nvim_version,
                      ctx.os,
                      ctx.date
                    )
                end,
                tools = {
                  'ask_questions',
                  'read_file',
                  'file_search',
                  'grep_search',
                  'fetch_webpage',
                  'sequential_thinking__sequentialthinking',
                  'memory_mcp__create_entities',
                  'memory_mcp__search_nodes',
                  'memory_mcp__open_nodes',
                  'memory_mcp__add_relations',
                },
                opts = {
                  collapse_tools = true,
                  ignore_system_prompt = true,
                  ignore_tool_system_prompt = true,
                },
              },

              ['reviewer'] = {
                description = 'Code reviewer — diagnostics, git diffs, GitHub context',
                system_prompt = function(_, ctx)
                  local base = load_system_prompt 'code-review.md'
                  return base
                    .. string.format(
                      '\n\nContext: Neovim %s, %s, date %s.\nUse GitHub MCP tools to check PR/issue context. Never modify code — only report findings.',
                      ctx.nvim_version,
                      ctx.os,
                      ctx.date
                    )
                end,
                tools = {
                  'ask_questions',
                  'read_file',
                  'file_search',
                  'grep_search',
                  'get_changed_files',
                  'get_diagnostics',
                  'run_command', -- P3: run linters/type-checkers during review
                  'github__get_pull_request',
                  'github__list_pull_requests',
                  'github__get_issue',
                  'github__list_issues',
                  'github__search_code',
                  'github__list_commits',
                },
                opts = {
                  collapse_tools = true,
                  ignore_system_prompt = true,
                  ignore_tool_system_prompt = true,
                },
              },

              ['refactorer'] = {
                description = 'Refactoring agent — think, search usages, edit, verify',
                system_prompt = function(_, ctx)
                  local base = load_system_prompt 'refactor.md'
                  return base
                    .. string.format(
                      '\n\nContext: Neovim %s, %s, date %s.\nUse sequential_thinking to plan refactoring steps. Search all usages before renaming/moving.',
                      ctx.nvim_version,
                      ctx.os,
                      ctx.date
                    )
                end,
                tools = {
                  'ask_questions',
                  'read_file',
                  'file_search',
                  'grep_search',
                  'insert_edit_into_file',
                  'get_diagnostics',
                  'get_changed_files',
                  'run_command', -- P3: verify no regressions after refactor
                  'sequential_thinking__sequentialthinking',
                },
                opts = {
                  collapse_tools = true,
                  ignore_system_prompt = true,
                  ignore_tool_system_prompt = true,
                },
              },

              ['researcher'] = {
                description = 'Research agent — brave search, web fetch, deep analysis',
                system_prompt = function(_, ctx)
                  local base = load_system_prompt 'deep-think.md'
                  return base
                    .. string.format(
                      '\n\nContext: Neovim %s, %s, date %s.\nUse brave search for web queries. Use sequential_thinking for analysis. Store reusable conclusions in memory_mcp.',
                      ctx.nvim_version,
                      ctx.os,
                      ctx.date
                    )
                end,
                tools = {
                  'ask_questions',
                  'read_file',
                  'file_search',
                  'fetch_webpage',
                  'brave__brave_web_search',
                  'sequential_thinking__sequentialthinking',
                  'memory_mcp__create_entities',
                  'memory_mcp__search_nodes',
                },
                opts = {
                  collapse_tools = true,
                  ignore_system_prompt = true,
                  ignore_tool_system_prompt = true,
                },
              },

              ['recall'] = {
                description = 'Memory agent — store/recall project context across sessions',
                system_prompt = function(_, ctx)
                  local base = load_system_prompt 'remember.md'
                  return base
                    .. string.format(
                      '\n\nContext: Neovim %s, %s, date %s.\nUse memory_mcp tools for persistent knowledge graph storage.',
                      ctx.nvim_version,
                      ctx.os,
                      ctx.date
                    )
                end,
                tools = {
                  'ask_questions',
                  'read_file',
                  'file_search',
                  'grep_search',
                  'memory_mcp__create_entities',
                  'memory_mcp__search_nodes',
                  'memory_mcp__open_nodes',
                  'memory_mcp__add_relations',
                  'memory_mcp__delete_entities',
                  'memory_mcp__delete_relations',
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

      -- Merge markdown prompt dirs with Lua workflow entries
      prompt_library = vim.tbl_extend('force', {
        markdown = {
          dirs = {
            vim.fn.stdpath 'config' .. '/prompts',
          },
        },
      }, workflows),

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
