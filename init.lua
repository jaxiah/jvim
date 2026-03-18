vim.g.mapleader = '\\'
vim.g.maplocalleader = '\\\\'
vim.g.have_nerd_font = true -- Using Maple Mono NF

-- [[ Options ]]
vim.o.number = true
vim.o.cursorline = true
vim.o.mouse = 'a'
vim.o.showmode = false
vim.o.autoread = true
vim.o.swapfile = false
vim.o.backup = false
vim.o.writebackup = false

vim.o.tabstop = 4
vim.o.shiftwidth = 0 -- use tabstop value
vim.o.expandtab = true

vim.o.wrap = false
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.termguicolors = true
vim.o.background = 'dark'

vim.schedule(function() vim.o.clipboard = 'unnamedplus' end)
vim.o.undofile = false
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.signcolumn = 'yes'
vim.o.updatetime = 250
vim.o.timeoutlen = 300
vim.o.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
vim.o.inccommand = 'split'
vim.o.scrolloff = 5
vim.o.confirm = true

-- GUI (neovide or gvim)
if vim.fn.has 'gui_running' == 1 or vim.g.neovide then vim.o.guifont = 'Maple Mono NL NF CN:h11' end

-- [[ Keymaps ]]

-- Clear search highlight
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Edit / source config
vim.keymap.set('n', '<leader>ev', '<cmd>edit $MYVIMRC<CR>', { desc = 'Edit config' })
vim.keymap.set('n', '<leader>sv', '<cmd>source $MYVIMRC<CR>', { desc = 'Source config' })

-- File explorer (netrw)
vim.keymap.set('n', '<C-x>D', function() vim.cmd('Explore ' .. vim.fn.getcwd()) end, { silent = true, desc = 'Explore root dir' })
vim.keymap.set('n', '<C-x>d', '<cmd>Explore<CR>', { silent = true, desc = 'Explore file dir' })

-- Open vsp in current file's directory
vim.keymap.set('n', '<C-x>3f', ':vsp %:p:h/', { desc = 'Vsp in file dir' })

-- Toggle wrap
vim.keymap.set('n', '<C-x>xt', '<cmd>set wrap!<CR>', { silent = true, desc = 'Toggle wrap' })

-- Emacs-style bindings in insert / cmdline / terminal modes
-- Note: <c-n>/<c-p>/<c-e> coexist with blink.cmp via its `fallback` mechanism
local emacs_maps = {
  { '<C-p>', '<Up>' },
  { '<C-n>', '<Down>' },
  { '<C-b>', '<Left>' },
  { '<C-f>', '<Right>' },
  { '<C-a>', '<Home>' },
  { '<C-e>', '<End>' },
  { '<C-d>', '<Del>' },
}
for _, km in ipairs(emacs_maps) do
  vim.keymap.set('i', km[1], km[2])
  vim.keymap.set('c', km[1], km[2])
  vim.keymap.set('t', km[1], km[2])
end

-- Scroll faster in normal mode
vim.keymap.set('n', '<C-e>', '5<C-e>')
vim.keymap.set('n', '<C-y>', '5<C-y>')

-- Buffer navigation
vim.keymap.set('n', '<C-PageUp>', '<cmd>bprevious<CR>')
vim.keymap.set('n', '<C-PageDown>', '<cmd>bnext<CR>')

-- Window navigation
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move to left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move to right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move to lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move to upper window' })

-- Diagnostics
vim.diagnostic.config {
  update_in_insert = false,
  severity_sort = true,
  float = { border = 'rounded', source = 'if_many' },
  underline = { severity = { min = vim.diagnostic.severity.WARN } },
  virtual_text = true,
  virtual_lines = false,
  jump = { float = true },
}
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic quickfix list' })

-- Exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- [[ Autocommands ]]
-- switch to english im (1033) when leaving insert mode
vim.api.nvim_create_autocmd('InsertLeave', {
  pattern = '*',
  callback = function() vim.fn.jobstart { 'im-select.exe', '1033' } end,
})

-- Highlight on yank
vim.api.nvim_create_autocmd('TextYankPost', {
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function() vim.hl.on_yank() end,
})

-- vim files: fold by marker
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'vim',
  group = vim.api.nvim_create_augroup('vim-fold', { clear = true }),
  callback = function() vim.wo.foldmethod = 'marker' end,
})

-- Reload file if changed externally (autoread needs checktime to actually fire)
vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter' }, {
  group = vim.api.nvim_create_augroup('autoread', { clear = true }),
  command = 'checktime',
})

-- Auto-enter insert mode when switching to a terminal buffer
vim.api.nvim_create_autocmd('TermOpen', {
  group = vim.api.nvim_create_augroup('term-open', { clear = true }),
  callback = function() vim.cmd 'startinsert' end,
})
vim.api.nvim_create_autocmd('BufEnter', {
  group = vim.api.nvim_create_augroup('term-enter', { clear = true }),
  callback = function()
    if vim.bo.buftype == 'terminal' then vim.cmd 'startinsert' end
  end,
})

-- [[ ToggleTerm ]]
local function toggle_term()
  local term_buf = nil
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].buftype == 'terminal' then
      term_buf = buf
      break
    end
  end

  if term_buf == nil then
    vim.cmd 'botright split | terminal'
  else
    local term_wins = vim.fn.win_findbuf(term_buf)
    if #term_wins == 0 then
      vim.cmd('botright sbuffer ' .. term_buf)
      vim.cmd 'startinsert'
    else
      for _, win_id in ipairs(term_wins) do
        vim.api.nvim_win_close(win_id, false)
      end
    end
  end
end

vim.keymap.set('n', '<leader>`', toggle_term, { silent = true, desc = 'Toggle terminal' })
vim.keymap.set('t', '<leader>`', function()
  vim.cmd 'stopinsert'
  vim.schedule(toggle_term)
end, { silent = true, desc = 'Toggle terminal' })

-- [[ VisualSearch command ]]
-- Search within visual selection, results go to quickfix.
-- Usage (visual mode): :VisualSearch <pattern>
vim.api.nvim_create_user_command('VisualSearch', function(opts)
  vim.fn.setqflist {}
  vim.cmd(opts.line1 .. ',' .. opts.line2 .. 'g/' .. opts.args .. '/caddexpr expand("%") . ":" . line(".") . ":" . getline(".")')
end, { range = true, nargs = '+', desc = 'Search in visual range → quickfix' })

-- [[ Plugin manager: lazy.nvim ]]
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then error('Error cloning lazy.nvim:\n' .. out) end
end
vim.opt.rtp:prepend(lazypath)

-- [[ Plugins ]]
require('lazy').setup({
  -- Auto-detect indentation (replaces vim-sleuth)
  { 'NMAC427/guess-indent.nvim', opts = {} },

  -- Git signs in gutter
  {
    'lewis6991/gitsigns.nvim',
    event = 'BufReadPre',
    opts = {
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
    },
  },

  -- Keybinding hints popup
  {
    'folke/which-key.nvim',
    event = 'VimEnter',
    opts = {
      delay = 300,
      icons = { mappings = vim.g.have_nerd_font },
      spec = {
        { '<leader>s', group = '[S]earch', mode = { 'n', 'v' } },
        { '<leader>t', group = '[T]oggle' },
        { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },
        { 'gr', group = 'LSP Actions', mode = { 'n' } },
      },
    },
  },

  -- Fuzzy finder (replaces LeaderF / fzf)
  {
    'nvim-telescope/telescope.nvim',
    event = 'VimEnter',
    dependencies = {
      'nvim-lua/plenary.nvim',
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make',
        cond = function() return vim.fn.executable 'make' == 1 end,
      },
      { 'nvim-telescope/telescope-ui-select.nvim' },
      { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
    },
    config = function()
      require('telescope').setup {
        extensions = {
          ['ui-select'] = { require('telescope.themes').get_dropdown() },
        },
      }
      pcall(require('telescope').load_extension, 'fzf')
      pcall(require('telescope').load_extension, 'ui-select')

      local builtin = require 'telescope.builtin'
      -- Emacs-style file/buffer pickers (mirrors LeaderF bindings from vimrc)
      vim.keymap.set('n', '<C-x><C-f>', builtin.find_files, { desc = 'Find files' })
      vim.keymap.set('n', '<C-x><C-b>', builtin.buffers, { desc = 'Find buffers' })
      vim.keymap.set('n', '<C-x><C-r>', builtin.oldfiles, { desc = 'Recent files (MRU)' })
      vim.keymap.set('n', '<M-g>rg', builtin.live_grep, { desc = 'Live grep (ripgrep)' })
      vim.keymap.set('n', '<M-g>i', builtin.lsp_document_symbols, { desc = 'Document symbols (functions)' })
      vim.keymap.set('n', '<M-g>bt', builtin.treesitter, { desc = 'Treesitter symbols (buf tags)' })
      vim.keymap.set('n', '<M-g>tt', builtin.lsp_workspace_symbols, { desc = 'Workspace symbols (tags)' })
      -- Other pickers
      vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
      vim.keymap.set({ 'n', 'v' }, '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
      vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
      vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
      vim.keymap.set('n', '<leader>sc', builtin.commands, { desc = '[S]earch [C]ommands' })
      vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
      vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
      vim.keymap.set(
        'n',
        '<leader>/',
        function() builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown { winblend = 10, previewer = false }) end,
        { desc = 'Fuzzy search in current buffer' }
      )
      vim.keymap.set(
        'n',
        '<leader>s/',
        function() builtin.live_grep { grep_open_files = true, prompt_title = 'Live Grep in Open Files' } end,
        { desc = '[S]earch in Open Files' }
      )
      vim.keymap.set('n', '<leader>sn', function() builtin.find_files { cwd = vim.fn.stdpath 'config' } end, { desc = '[S]earch [N]eovim files' })

      -- LSP pickers (set per-buffer on LspAttach)
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('telescope-lsp-attach', { clear = true }),
        callback = function(event)
          local buf = event.buf
          vim.keymap.set('n', 'grr', builtin.lsp_references, { buffer = buf, desc = '[G]oto [R]eferences' })
          vim.keymap.set('n', 'gri', builtin.lsp_implementations, { buffer = buf, desc = '[G]oto [I]mplementation' })
          vim.keymap.set('n', 'grd', builtin.lsp_definitions, { buffer = buf, desc = '[G]oto [D]efinition' })
          vim.keymap.set('n', 'gO', builtin.lsp_document_symbols, { buffer = buf, desc = 'Document Symbols' })
          vim.keymap.set('n', 'gW', builtin.lsp_dynamic_workspace_symbols, { buffer = buf, desc = 'Workspace Symbols' })
          vim.keymap.set('n', 'grt', builtin.lsp_type_definitions, { buffer = buf, desc = '[G]oto [T]ype Definition' })
        end,
      })
    end,
  },

  -- LSP (replaces coc.nvim)
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      { 'mason-org/mason.nvim', opts = {} },
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      { 'j-hui/fidget.nvim', opts = {} }, -- LSP progress indicator
    },
    config = function()
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc, mode) vim.keymap.set(mode or 'n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc }) end
          map('grn', vim.lsp.buf.rename, '[R]e[n]ame')
          map('gra', vim.lsp.buf.code_action, 'Code [A]ction', { 'n', 'x' })
          map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
          map('<leader>th', function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }) end, '[T]oggle Inlay [H]ints')

          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client:supports_method('textDocument/documentHighlight', event.buf) then
            local au = vim.api.nvim_create_augroup('lsp-highlight', { clear = false })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, { buffer = event.buf, group = au, callback = vim.lsp.buf.document_highlight })
            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, { buffer = event.buf, group = au, callback = vim.lsp.buf.clear_references })
            vim.api.nvim_create_autocmd('LspDetach', {
              group = vim.api.nvim_create_augroup('lsp-detach', { clear = true }),
              callback = function(e)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds { group = 'lsp-highlight', buffer = e.buf }
              end,
            })
          end
        end,
      })

      -- Add LSP servers here. They will be auto-installed via Mason.
      ---@type table<string, vim.lsp.Config>
      local servers = {
        clangd = { cmd = { 'clangd', '-j=1' } },
        pyright = {},
        lua_ls = {
          on_init = function(client)
            if client.workspace_folders then
              local path = client.workspace_folders[1].name
              if path ~= vim.fn.stdpath 'config' and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc')) then return end
            end
            client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
              runtime = { version = 'LuaJIT', path = { 'lua/?.lua', 'lua/?/init.lua' } },
              workspace = {
                checkThirdParty = false,
                library = vim.tbl_extend('force', vim.api.nvim_get_runtime_file('', true), { '${3rd}/luv/library', '${3rd}/busted/library' }),
              },
            })
          end,
          settings = { Lua = {} },
        },
      }

      local ensure_installed = { 'lua-language-server', 'clangd', 'pyright', 'stylua', 'black' }
      require('mason-tool-installer').setup { ensure_installed = ensure_installed }

      for name, server in pairs(servers) do
        vim.lsp.config(name, server)
        vim.lsp.enable(name)
      end
    end,
  },

  -- Autoformat
  {
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      { '<leader>ft', function() require('conform').format { async = true, lsp_format = 'fallback' } end, mode = '', desc = '[F]or[m]at buffer' },
    },
    opts = {
      notify_on_error = false,
      formatters_by_ft = { lua = { 'stylua' }, python = { 'black' }, markdown = { 'prettier' } },
      formatters = { black = { prepend_args = { '-l', '160' } } },
    },
  },

  -- Completion (replaces coc / vimcomplete)
  {
    'saghen/blink.cmp',
    event = 'VimEnter',
    version = '1.*',
    dependencies = {
      {
        'L3MON4D3/LuaSnip',
        version = '2.*',
        build = (function()
          if vim.fn.has 'win32' == 1 or vim.fn.executable 'make' == 0 then return end
          return 'make install_jsregexp'
        end)(),
        opts = {},
      },
    },
    opts = {
      -- Emacs insert-mode bindings (<c-n>/<c-p>/<c-e> etc.) coexist with blink
      -- via the `fallback` mechanism: blink handles them when menu is open,
      -- falls through to vim keymap when menu is closed.
      keymap = { preset = 'default' },
      appearance = { nerd_font_variant = 'mono' },
      completion = { documentation = { auto_show = false, auto_show_delay_ms = 500 } },
      sources = { default = { 'lsp', 'path', 'snippets', 'buffer' } },
      snippets = { preset = 'luasnip' },
      signature = { enabled = true },
    },
  },

  -- mini plugins collection
  {
    'nvim-mini/mini.nvim',
    config = function()
      require('mini.ai').setup { n_lines = 500 } -- Better text objects: va), yinq, ci'
      require('mini.surround').setup() -- saiw), sd', sr)'
      require('mini.comment').setup() -- gc to toggle comments (replaces nerdcommenter)
      require('mini.tabline').setup() -- Buffer tabline (replaces vim-buftabline)
      local statusline = require 'mini.statusline'
      statusline.setup { use_icons = vim.g.have_nerd_font }
      statusline.section_location = function() return '%2l:%-2v' end
    end,
  },

  -- Syntax highlighting & indentation
  {
    'nvim-treesitter/nvim-treesitter',
    lazy = false,
    build = ':TSUpdate',
    branch = 'main',
    config = function()
      local parsers = { 'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc' }
      require('nvim-treesitter').install(parsers)
      vim.api.nvim_create_autocmd('FileType', {
        callback = function(args)
          local language = vim.treesitter.language.get_lang(args.match)
          if not language then return end
          if not vim.treesitter.language.add(language) then return end
          vim.treesitter.start(args.buf, language)
          vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })
    end,
  },

  -- File tree (replaces NERDTree; use alongside netrw+telescope for lightweight nav)
  {
    'nvim-neo-tree/neo-tree.nvim',
    version = '*',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-tree/nvim-web-devicons',
      'MunifTanjim/nui.nvim',
    },
    cmd = 'Neotree',
    keys = {
      { '<leader>tr', '<cmd>Neotree toggle<CR>', desc = 'Neo[T]ree toggle' },
      { '<leader>tf', '<cmd>Neotree reveal<CR>', desc = 'Neo[T]ree reveal current [F]ile' },
    },
    opts = {
      filesystem = {
        filtered_items = { hide_dotfiles = false },
        window = { mappings = { ['<leader>tr'] = 'close_window' } },
      },
    },
  },

  -- Quick jump / motion (replaces vim9-stargate / easymotion)
  {
    'folke/flash.nvim',
    event = 'VeryLazy',
    opts = {},
    keys = {
      { '<M-g>w', function() require('flash').jump() end, mode = { 'n', 'x', 'o' }, desc = 'Flash jump' },
      { '<M-g>l', function() require('flash').jump { pattern = '^' } end, mode = { 'n', 'x', 'o' }, desc = 'Flash jump to line' },
      { '<M-g>t', function() require('flash').treesitter() end, mode = { 'n', 'x', 'o' }, desc = 'Flash treesitter select' },
    },
  },

  -- Copilot
  { 'github/copilot.vim', event = 'InsertEnter' },

  -- Optional extras (uncomment to enable):
  -- require 'debug', -- DAP debugger (nvim-dap + nvim-dap-ui)
}, {
  ui = {
    icons = vim.g.have_nerd_font and {} or {
      cmd = '⌘',
      config = '🛠',
      event = '📅',
      ft = '📂',
      init = '⚙',
      keys = '🗝',
      plugin = '🔌',
      runtime = '💻',
      require = '🌙',
      source = '📄',
      start = '🚀',
      task = '📌',
      lazy = '💤 ',
    },
  },
})

-- Colorscheme: retrobox is built-in to neovim 0.10+, no plugin needed
vim.cmd.colorscheme 'retrobox'

-- vim: ts=2 sts=2 sw=2 et
