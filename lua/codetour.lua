-- lua/codetour.lua
-- Code Tour: navigate a codebase step-by-step via .tour.json files.
--
-- Workflow:
--   :TourLoad                  — auto-detect <stem>.tour.json next to current .md buffer
--   :TourLoad path/to/t.json   — load explicitly
--   ]q / [q (existing)         — quickfix next/prev; auto-updates description panel
--   Enter on qf line           — also updates description panel
--   :cc N                      — jump to step N directly
--
-- Layout when a tour is active:
--   ┌──────────────────────────┐
--   │    code window (main)    │
--   ├──────────────────────────┤
--   │    description (B)       │  ← full step description, markdown ft
--   ├──────────────────────────┤
--   │    quickfix (A)          │  ← all steps overview, Enter to jump
--   └──────────────────────────┘

local M = {}

-- ── state ────────────────────────────────────────────────────────────────────
M._steps    = {}
M._title    = ''
M._summary  = ''
M._idx      = 0     -- 1-based; 0 = no tour loaded
M._code_win = nil   -- window where code files are opened
M._desc_buf = nil
M._desc_win = nil
M._ns       = vim.api.nvim_create_namespace('codetour')  -- for virtual text signs

local DESC_HEIGHT = 12
local QF_HEIGHT = 8

-- ── description window ───────────────────────────────────────────────────────
local function desc_buf_valid() return M._desc_buf ~= nil and vim.api.nvim_buf_is_valid(M._desc_buf) end

local function desc_win_valid() return M._desc_win ~= nil and vim.api.nvim_win_is_valid(M._desc_win) end

local function ensure_desc_buf()
  if not desc_buf_valid() then
    M._desc_buf = vim.api.nvim_create_buf(false, true)
    vim.bo[M._desc_buf].buftype = 'nofile'
    vim.bo[M._desc_buf].bufhidden = 'hide'
    vim.bo[M._desc_buf].swapfile = false
    vim.bo[M._desc_buf].filetype = 'markdown'
    vim.api.nvim_buf_set_name(M._desc_buf, 'CodeTour:Description')
  end
end

local function open_desc_win()
  -- Open below the code window
  local code_win = (M._code_win and vim.api.nvim_win_is_valid(M._code_win)) and M._code_win or vim.api.nvim_get_current_win()

  vim.api.nvim_set_current_win(code_win)
  vim.cmd('belowright ' .. DESC_HEIGHT .. 'split')
  M._desc_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(M._desc_win, M._desc_buf)

  local wo = vim.wo[M._desc_win]
  wo.wrap = true
  wo.linebreak = true
  wo.number = false
  wo.relativenumber = false
  wo.signcolumn = 'no'
  wo.statusline = '  CodeTour ─ description '
  wo.winfixheight = true

  -- Return focus to code window
  vim.api.nvim_set_current_win(code_win)
end

local function ensure_desc_win()
  ensure_desc_buf()
  if not desc_win_valid() then open_desc_win() end
end

local function update_desc(step, idx, total)
  if not desc_buf_valid() then return end

  local lines = {}
  -- Header line
  table.insert(lines, string.format('  ▶  Step %d / %d   %s : %d', idx, total, step.file or '?', step.line or 0))
  table.insert(lines, '  ' .. string.rep('─', 68))
  table.insert(lines, '')

  -- Description body — split on literal \n
  local desc = step.description or '(no description)'
  for _, l in ipairs(vim.split(desc, '\n', { plain = true })) do
    table.insert(lines, '  ' .. l)
  end

  vim.bo[M._desc_buf].modifiable = true
  vim.api.nvim_buf_set_lines(M._desc_buf, 0, -1, false, lines)
  vim.bo[M._desc_buf].modifiable = false

  if desc_win_valid() then vim.api.nvim_win_set_cursor(M._desc_win, { 1, 0 }) end
end

-- ── virtual text signs ────────────────────────────────────────────────────────
-- Each tour stop gets an eol virtual text annotation on its source line so the
-- reader can see "oh, there's a tour point here" while browsing code freely.

vim.api.nvim_set_hl(0, 'CodeTourSign', { link = 'Comment', default = true })

-- Normalize a path to forward slashes for cross-platform comparison.
local function norm(p) return p:gsub('\\', '/') end

-- Place signs for all steps whose file matches `fpath` (relative to cwd) on `bufnr`.
local function place_signs(bufnr, fpath)
  fpath = norm(fpath)
  vim.api.nvim_buf_clear_namespace(bufnr, M._ns, 0, -1)
  for i, s in ipairs(M._steps) do
    if norm(s.file) == fpath then
      local lnum  = (s.line or 1) - 1   -- 0-based for extmarks
      local label = (s.description or ''):match('^([^\n]+)') or ''
      label = label:gsub('%*%*(.-)%*%*', '%1'):sub(1, 56)  -- strip **bold**, trim
      pcall(vim.api.nvim_buf_set_extmark, bufnr, M._ns, lnum, 0, {
        virt_text     = { { '  ◆ [' .. i .. '/' .. #M._steps .. '] ' .. label, 'CodeTourSign' } },
        virt_text_pos = 'eol',
        hl_mode       = 'combine',
      })
    end
  end
end

-- Clear signs from every loaded buffer.
local function clear_all_signs()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.api.nvim_buf_clear_namespace(bufnr, M._ns, 0, -1)
    end
  end
end

-- Place signs on all currently loaded buffers whose name matches a step file.
local function refresh_all_signs()
  clear_all_signs()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_is_loaded(bufnr) then
      local rel = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ':.')
      place_signs(bufnr, rel)
    end
  end
end

-- Auto-place signs whenever a file buffer is entered (catches buffers opened
-- after TourLoad, including each step file opened during navigation).
vim.api.nvim_create_autocmd({ 'BufEnter', 'BufReadPost' }, {
  group = vim.api.nvim_create_augroup('CodeTourSigns', { clear = true }),
  callback = function(ev)
    if #M._steps == 0 then return end
    local rel = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(ev.buf), ':.')
    place_signs(ev.buf, rel)
  end,
})

-- ── quickfix overview ─────────────────────────────────────────────────────────
local function populate_qf()
  local items = {}
  for i, s in ipairs(M._steps) do
    -- First line of description, strip **bold** markers for readability
    local first = (s.description or ''):match '^([^\n]+)' or ''
    first = first:gsub('%*%*(.-)%*%*', '%1')
    items[i] = {
      filename = s.file or '',
      lnum = s.line or 1,
      col = 1,
      text = string.format('[%d/%d] %s', i, #M._steps, first),
    }
  end
  local title = M._title
  if M._summary ~= '' then title = title .. ' — ' .. M._summary:sub(1, 60) end
  vim.fn.setqflist({}, 'r', { title = title, items = items })
end

local function sync_qf_cursor(idx)
  local info = vim.fn.getqflist { winid = 0 }
  local qf_winid = info.winid
  if qf_winid and qf_winid > 0 then pcall(vim.api.nvim_win_set_cursor, qf_winid, { idx, 0 }) end
end

-- ── navigation ───────────────────────────────────────────────────────────────
function M.goto_step(idx)
  if #M._steps == 0 then
    vim.notify('CodeTour: no tour loaded — use :TourLoad', vim.log.levels.WARN)
    return
  end

  if idx < 1 then
    vim.notify('CodeTour: already at first step', vim.log.levels.INFO)
    idx = 1
  elseif idx > #M._steps then
    vim.notify('CodeTour: already at last step', vim.log.levels.INFO)
    idx = #M._steps
  end
  M._idx = idx
  local s = M._steps[idx]

  -- ① Open file at line in the code window
  local code_win = (M._code_win and vim.api.nvim_win_is_valid(M._code_win)) and M._code_win or vim.api.nvim_get_current_win()

  -- Avoid jumping into desc or qf windows
  if code_win == M._desc_win then
    -- find another suitable window
    for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if w ~= M._desc_win then
        local bt = vim.bo[vim.api.nvim_win_get_buf(w)].buftype
        if bt == '' or bt == 'acwrite' then
          code_win = w
          M._code_win = w
          break
        end
      end
    end
  end

  local fpath = s.file or ''
  if fpath ~= '' then
    vim.api.nvim_set_current_win(code_win)
    vim.cmd('edit ' .. vim.fn.fnameescape(fpath))
    vim.api.nvim_win_set_cursor(0, { s.line or 1, 0 })
    vim.cmd 'normal! zz' -- center the line vertically
  end

  -- ② Update description window
  ensure_desc_win()
  update_desc(s, idx, #M._steps)

  -- ③ Sync quickfix cursor (visual highlight in overview)
  sync_qf_cursor(idx)
end

function M.next() M.goto_step(M._idx + 1) end
function M.prev() M.goto_step(M._idx - 1) end

-- ── load ─────────────────────────────────────────────────────────────────────
function M.load(path)
  path = vim.fn.expand(path)
  if vim.fn.filereadable(path) == 0 then
    vim.notify('CodeTour: file not found: ' .. path, vim.log.levels.ERROR)
    return
  end
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok then
    vim.notify('CodeTour: cannot read: ' .. path, vim.log.levels.ERROR)
    return
  end
  local ok2, data = pcall(vim.json.decode, table.concat(lines, '\n'))
  if not ok2 or type(data) ~= 'table' then
    vim.notify('CodeTour: invalid JSON: ' .. path, vim.log.levels.ERROR)
    return
  end
  if not data.steps or #data.steps == 0 then
    vim.notify('CodeTour: no steps in: ' .. path, vim.log.levels.WARN)
    return
  end

  M._steps   = data.steps
  M._title   = data.title       or vim.fn.fnamemodify(path, ':t:r')
  M._summary = data.description or ''
  M._idx     = 0
  M._code_win = vim.api.nvim_get_current_win()

  -- Place virtual text signs on already-open buffers; BufEnter handles the rest
  refresh_all_signs()

  -- Build quickfix and open the overview window
  populate_qf()
  vim.cmd('copen ' .. QF_HEIGHT)
  vim.cmd 'wincmd p' -- return to code window

  vim.notify(string.format('CodeTour: "%s" — %d steps', M._title, #M._steps), vim.log.levels.INFO)
  M.goto_step(1)
end

-- Auto-detect <stem>.tour next to current buffer
function M.load_auto()
  local cur = vim.fn.expand '%:p'
  if cur == '' then
    vim.notify('CodeTour: no file in current buffer', vim.log.levels.WARN)
    return
  end
  local stem = vim.fn.fnamemodify(cur, ':t:r')
  local dir = norm(vim.fn.fnamemodify(cur, ':p:h'))
  local candidate = dir .. '/' .. stem .. '.tour'
  if vim.fn.filereadable(candidate) == 1 then
    M.load(candidate)
  else
    vim.notify('CodeTour: not found: ' .. candidate .. '\n(use :TourLoad <path> to load explicitly)', vim.log.levels.WARN)
  end
end

-- ── ]q / [q keymaps: wrap cnext/cprev and sync description ──────────────────
-- More reliable than QuickFixCmdPost (which may not fire for all qf navigation).
-- When no tour is loaded, behaves exactly like stock cnext/cprev.
local function qf_step(cmd)
  local ok, err = pcall(vim.cmd, cmd)
  if not ok then
    -- surface the normal "no more items" message
    vim.notify((err:match(': (.+)$') or err), vim.log.levels.WARN)
    return
  end
  if #M._steps == 0 or not desc_win_valid() then return end
  vim.schedule(function()
    local idx = vim.fn.getqflist({ idx = 0 }).idx
    if idx >= 1 and idx <= #M._steps then
      M._idx = idx
      update_desc(M._steps[idx], idx, #M._steps)
    end
  end)
end

vim.keymap.set('n', ']q', function() qf_step('cnext') end, { desc = 'cnext (+ CodeTour desc sync)' })
vim.keymap.set('n', '[q', function() qf_step('cprev') end, { desc = 'cprev (+ CodeTour desc sync)' })

-- Enter in the quickfix window: jump to that step directly
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'qf',
  group   = vim.api.nvim_create_augroup('CodeTourQfEnter', { clear = true }),
  callback = function()
    vim.keymap.set('n', '<CR>', function()
      if #M._steps == 0 then return end
      local row = vim.api.nvim_win_get_cursor(0)[1]
      M.goto_step(row)
    end, { buffer = true, desc = 'CodeTour: jump to step' })
  end,
})

-- ── commands ─────────────────────────────────────────────────────────────────
vim.api.nvim_create_user_command('TourLoad', function(opts)
  if opts.args == '' then
    M.load_auto()
  else
    M.load(opts.args)
  end
end, {
  nargs = '?',
  complete = 'file',
  desc = 'Load .tour.json (no arg = auto-detect from current .md buffer)',
})

return M
