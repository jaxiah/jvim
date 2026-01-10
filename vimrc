" basic settings {{{

set autoread " 自动载入外部修改
set noswapfile " 关闭交换文件
set hidden " 允许被修改的 buffer 放到后台
set number
set cursorline " 高亮当前行

set splitright " vsp 新窗口放右边
set splitbelow " sp 新窗口放下边

set encoding=utf-8 " vim 内部的字符编码
set fileencoding=utf-8 " 文件的字符编码
set termencoding=utf-8 " 终端编码为 UTF-8
set fileformat=unix " 换行符 LF/CRLF

set tabstop=4 " tab size
set shiftwidth=0 " size of < and >, 0 use tabstop
set expandtab " expand tab to space

set laststatus=2 " 始终显示状态栏
set noshowmode " 有了 lightline 不再需要显示 mode
set hlsearch " 开启搜索高亮
set incsearch " 开启增量搜索
set backspace=indent,eol,start " 默认 backspace 无法删除旧内容
set clipboard=unnamed " 打通系统剪贴板和 unnamed
set mouse=a " all 所有 mode 下都开启 mouse

augroup filetype_vim " vimrc 内按 marker 折叠
  autocmd!
  autocmd FileType vim setlocal foldmethod=marker
augroup END

" }}}

" key mappings {{{

" open and source vimrc file
nnoremap <leader>ev :edit $MYVIMRC<cr>
nnoremap <leader>sv :source $MYVIMRC<cr>

" explore root dir
nnoremap <silent> <c-x>D :exe "Explore" getcwd()<cr>
" explore current file dir
nnoremap <silent> <c-x>d :Explore<cr>

" 关闭搜索高亮，下次搜索还会高亮
nnoremap <silent> <esc> :nohlsearch<cr>

" 默认不折行，但可切换
set nowrap
" nnoremap <silent> <leader>wr :set wrap!<cr>
nnoremap <silent> <c-x>xt :set wrap!<cr>

" 在右边打开当前文件目录下的另一个文件
nnoremap <c-x>3f :vsp %:p:h/

" emacs keybinding
" insert mode
inoremap <c-p> <up>
inoremap <c-n> <down>
inoremap <c-b> <left>
inoremap <c-f> <right>
inoremap <c-a> <home>
inoremap <c-e> <end>
inoremap <c-d> <del>
" cmd line mode
cnoremap <c-p> <up>
cnoremap <c-n> <down>
cnoremap <c-b> <left>
cnoremap <c-f> <right>
cnoremap <c-a> <home>
cnoremap <c-e> <end>
cnoremap <c-d> <del>
" terminal mode
tnoremap <c-p> <up>
tnoremap <c-n> <down>
tnoremap <c-b> <left>
tnoremap <c-f> <right>
tnoremap <c-a> <home>
tnoremap <c-e> <end>
tnoremap <c-d> <del>

nnoremap <C-e> 5<C-e>
nnoremap <C-y> 5<C-y>

nnoremap <c-pageup> :bprevious<CR>
nnoremap <c-pagedown> :bnext<CR>

" }}}

" my functions and commands {{{

" 在 visual 区域做局部搜索, 结果放到 quickfix 中. https://stackoverflow.com/a/21487300/7949687
command! -range -nargs=+ VisualSearch cgetexpr []|<line1>,<line2>g/<args>/caddexpr expand("%") . ":" . line(".") .  ":" . getline(".")

augroup ToggleTermInsert
  autocmd!
  autocmd TerminalWinOpen * silent! exe "normal! i"
  autocmd BufEnter * if &buftype ==# "terminal" && mode() ==# "n" | silent! exe "normal! i" | endif
augroup END

function ToggleTerm() abort
  const terms = term_list()
  if empty(terms)
    " no terminals, make one
    botright terminal pwsh
  else
    const term = terms[0]
    if bufwinnr(term) < 0
      " terminal hidden, open it
      execute 'botright sbuffer' term
    else
      " terminal open, close all windows showing it in the tab
      for win_id in win_findbuf(term)
	let win_nr = win_id2win(win_id)
	if win_nr > 0
	  execute win_nr 'close'
	endif
      endfor
    endif
  endif
endfunction
nnoremap <silent> <leader>` :call ToggleTerm()<cr>
tnoremap <silent> <leader>` <c-w>N:call ToggleTerm()<cr>

" }}}

" plugins {{{

call plug#begin('~/vim-plugins')

" lightline {{{
Plug 'itchyny/lightline.vim'
let g:lightline = {
      \ 'colorscheme': 'wombat',
      \}
" let g:lightline = {
"       \ 'colorscheme': 'wombat',
"       \ 'active': {
"       \   'left': [ [ 'mode', 'paste' ],
"       \             [ 'readonly', 'filename', 'modified' ] ]
"       \ },
"       \ 'component_function': {
"       \   'modified': 'CheckModified'
"       \ },
"       \ 'separator': { 'left': '', 'right': '' },
"       \ 'subseparator': { 'left': '', 'right': '' }
"       \ }

" function! CheckModified()
"   if &readonly
"     return ''
"   elseif &modified
"     return '●'
"   else
"     return '✓'
"   endif
" endfunction
" }}}

" tabline {{{
Plug 'ap/vim-buftabline'
let g:buftabline_show = 1 " 只有一个 buffer 时不显示 tab
" }}}

" vim-floaterm {{{
" Plug 'voldikss/vim-floaterm'
" nnoremap <silent> <m-x> :FloatermToggle<cr>
" tnoremap <silent> <m-x> <c-w>N:FloatermToggle<cr>
" nnoremap <silent> <m-c> :FloatermNew<cr>
" tnoremap <silent> <m-c> <c-\><c-n>:FloatermNew<cr>
" nnoremap <silent> <m-v> :FloatermNext<cr>
" tnoremap <silent> <m-v> <c-\><c-n>:FloatermNext<cr>
" }}}

" nerdtree {{{
Plug 'scrooloose/nerdtree'
let NERDTreeShowHidden=1
nnoremap <silent> <leader>tr :NERDTreeToggle<cr>
nnoremap <silent> <leader>tf :NERDTreeFind<cr>
" }}}

" nerdcommenter {{{
Plug 'preservim/nerdcommenter'
nmap <m-;> <Plug>NERDCommenterToggle
vmap <m-;> <Plug>NERDCommenterToggle<cr>gv
let g:NERDSpaceDelims = 1
let g:NERDDefaultAlign = 'left'
" }}}

" 自动判断 tabstop {{{
Plug 'tpope/vim-sleuth'
" }}}

" fzf {{{
" Plug 'junegunn/fzf'
" Plug 'junegunn/fzf.vim'
" nnoremap <leader>ff :Files<cr>
" nnoremap <leader>bb :Buffers<cr>
" nnoremap <leader>bl :BLines<cr>
" nnoremap <leader>rg :Rg<cr>
" }}}

" vim-startuptime 启动时间 benchmark {{{
Plug 'dstein64/vim-startuptime'
" }}}

" alternative to easymotion {{{
Plug 'monkoose/vim9-stargate'
" for the start of a word
noremap <space>w <Cmd>call stargate#OKvim('\<')<CR>
" for the start of a line
noremap <space>l <Cmd>call stargate#OKvim('\_^')<CR>
" }}}

" LeaderF {{{
Plug 'Yggdroot/LeaderF', { 'do': ':LeaderfInstallCExtension' }
let g:Lf_WindowPosition = 'popup'
nnoremap <c-x><c-f> :LeaderfFile<cr>
nnoremap <c-x><c-b> :LeaderfBuffer<cr>
nnoremap <c-x><c-r> :LeaderfMru<cr>
nnoremap <m-g>i :LeaderfFunction<cr>
nnoremap <m-g>bt :LeaderfBufTag<cr>
nnoremap <m-g>tt :LeaderfTag<cr>
nnoremap <m-g>rg :Leaderf rg<cr>
nnoremap <m-g>ri :LeaderfRgInteractive<cr>

" change shortkey from C-J to C-N, but not map C-J to C-N.
let g:Lf_CommandMap = {'<C-J>': ['<C-N>'], '<C-K>': ['<C-P>']}

" }}}

" prog dev {{{
set tags=./.tags;,.tags " 设置 tags 文件的搜索路径
Plug 'ludovicchabant/vim-gutentags'
" gutentags 搜索工程目录的标志，碰到这些文件/目录名就停止向上一级目录递归
let g:gutentags_project_root = ['.root', '.svn', '.git', '.hg', '.project']

" 所生成的数据文件的名称
let g:gutentags_ctags_tagfile = '.tags'

" 将自动生成的 tags 文件全部放入 ~/.cache/tags 目录中，避免污染工程目录
let s:vim_tags = expand('~/.cache/tags')
let g:gutentags_cache_dir = s:vim_tags

" 配置 ctags 的参数
let g:gutentags_ctags_extra_args = ['--fields=+niazS', '--extra=+q']
let g:gutentags_ctags_extra_args += ['--c++-kinds=+px']
let g:gutentags_ctags_extra_args += ['--c-kinds=+px']

" 检测 ~/.cache/tags 不存在就新建
if !isdirectory(s:vim_tags)
  silent! call mkdir(s:vim_tags, 'p')
endif

Plug 'preservim/tagbar'
nnoremap <leader>tb :TagbarToggle<CR>

Plug 'girishji/vimcomplete'
let g:vimcomplete_do_mapping = 0

Plug 'github/copilot.vim'

Plug 'epheien/termdbg'
" }}}

" coc.nvim {{{
Plug 'neoclide/coc.nvim', {'branch': 'release'}

" https://raw.githubusercontent.com/neoclide/coc.nvim/master/doc/coc-example-config.vim

" May need for Vim (not Neovim) since coc.nvim calculates byte offset by count
" utf-8 byte sequence
set encoding=utf-8
" Some servers have issues with backup files, see #649
set nobackup
set nowritebackup

" Having longer updatetime (default is 4000 ms = 4s) leads to noticeable
" delays and poor user experience
set updatetime=300

" Always show the signcolumn, otherwise it would shift the text each time
" diagnostics appear/become resolved
set signcolumn=yes

" Use tab for trigger completion with characters ahead and navigate
" NOTE: There's always complete item selected by default, you may want to enable
" no select by `"suggest.noselect": true` in your configuration file
" NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
" other plugin before putting this into your config
inoremap <silent><expr> <TAB>
      \ coc#pum#visible() ? coc#pum#next(1) :
      \ CheckBackspace() ? "\<Tab>" :
      \ coc#refresh()
inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"

" Make <CR> to accept selected completion item or notify coc.nvim to format
" <C-g>u breaks current undo, please make your own choice
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
                              \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

function! CheckBackspace() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Use <c-space> to trigger completion
if has('nvim')
  inoremap <silent><expr> <c-space> coc#refresh()
else
  inoremap <silent><expr> <c-@> coc#refresh()
endif

" Use `[g` and `]g` to navigate diagnostics
" Use `:CocDiagnostics` to get all diagnostics of current buffer in location list
nmap <silent><nowait> [g <Plug>(coc-diagnostic-prev)
nmap <silent><nowait> ]g <Plug>(coc-diagnostic-next)

" GoTo code navigation
nmap <silent><nowait> gd <Plug>(coc-definition)
nmap <silent><nowait> gy <Plug>(coc-type-definition)
nmap <silent><nowait> gi <Plug>(coc-implementation)
nmap <silent><nowait> gr <Plug>(coc-references)

" Use K to show documentation in preview window
nnoremap <silent> K :call ShowDocumentation()<CR>

function! ShowDocumentation()
  if CocAction('hasProvider', 'hover')
    call CocActionAsync('doHover')
  else
    call feedkeys('K', 'in')
  endif
endfunction

" Highlight the symbol and its references when holding the cursor
autocmd CursorHold * silent call CocActionAsync('highlight')

" Symbol renaming
nmap <leader>rn <Plug>(coc-rename)

" Formatting selected code
xmap <leader>f  <Plug>(coc-format-selected)
nmap <leader>f  <Plug>(coc-format-selected)

augroup mygroup
  autocmd!
  " Setup formatexpr specified filetype(s)
  autocmd FileType typescript,json setl formatexpr=CocAction('formatSelected')
augroup end

" Applying code actions to the selected code block
" Example: `<leader>aap` for current paragraph
xmap <leader>a  <Plug>(coc-codeaction-selected)
nmap <leader>a  <Plug>(coc-codeaction-selected)

" Remap keys for applying code actions at the cursor position
nmap <leader>ac  <Plug>(coc-codeaction-cursor)
" Remap keys for apply code actions affect whole buffer
nmap <leader>as  <Plug>(coc-codeaction-source)
" Apply the most preferred quickfix action to fix diagnostic on the current line
nmap <leader>qf  <Plug>(coc-fix-current)

" Remap keys for applying refactor code actions
nmap <silent> <leader>re <Plug>(coc-codeaction-refactor)
xmap <silent> <leader>r  <Plug>(coc-codeaction-refactor-selected)
nmap <silent> <leader>r  <Plug>(coc-codeaction-refactor-selected)

" Run the Code Lens action on the current line
nmap <leader>cl  <Plug>(coc-codelens-action)

" Map function and class text objects
" NOTE: Requires 'textDocument.documentSymbol' support from the language server
xmap if <Plug>(coc-funcobj-i)
omap if <Plug>(coc-funcobj-i)
xmap af <Plug>(coc-funcobj-a)
omap af <Plug>(coc-funcobj-a)
xmap ic <Plug>(coc-classobj-i)
omap ic <Plug>(coc-classobj-i)
xmap ac <Plug>(coc-classobj-a)
omap ac <Plug>(coc-classobj-a)

" Remap <C-f> and <C-b> to scroll float windows/popups
if has('nvim-0.4.0') || has('patch-8.2.0750')
  nnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
  nnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
  inoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(1)\<cr>" : "\<Right>"
  inoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(0)\<cr>" : "\<Left>"
  vnoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
  vnoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
endif

" Use CTRL-S for selections ranges
" Requires 'textDocument/selectionRange' support of language server
nmap <silent> <C-s> <Plug>(coc-range-select)
xmap <silent> <C-s> <Plug>(coc-range-select)

" Add `:Format` command to format current buffer
command! -nargs=0 Format :call CocActionAsync('format')

" Add `:Fold` command to fold current buffer
command! -nargs=? Fold :call     CocAction('fold', <f-args>)

" Add `:OR` command for organize imports of the current buffer
command! -nargs=0 OR   :call     CocActionAsync('runCommand', 'editor.action.organizeImport')

" Add (Neo)Vim's native statusline support
" NOTE: Please see `:h coc-status` for integrations with external plugins that
" provide custom statusline: lightline.vim, vim-airline
set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}

" Mappings for CoCList
" Show all diagnostics
nnoremap <silent><nowait> <space>a  :<C-u>CocList diagnostics<cr>
" Manage extensions
nnoremap <silent><nowait> <space>e  :<C-u>CocList extensions<cr>
" Show commands
nnoremap <silent><nowait> <space>c  :<C-u>CocList commands<cr>
" Find symbol of current document
nnoremap <silent><nowait> <space>o  :<C-u>CocList outline<cr>
" Search workspace symbols
nnoremap <silent><nowait> <space>s  :<C-u>CocList -I symbols<cr>
" Do default action for next item
nnoremap <silent><nowait> <space>j  :<C-u>CocNext<CR>
" Do default action for previous item
nnoremap <silent><nowait> <space>k  :<C-u>CocPrev<CR>
" Resume latest coc list
nnoremap <silent><nowait> <space>p  :<C-u>CocListResume<CR>
" }}}

call plug#end()

" }}}

" gui settings {{{

if has('gui_running')
  set linespace=0
  set guioptions-=m  "menu bar
  set guioptions-=T  "toolbar
  set guioptions-=r  "right scrollbar
  set guioptions-=L  "left scrollbar
  set guifont=Maple\ Mono\ NL\ NF\ CN:h11
  set t_Co=256
  winpos 555 300
  winsize 160 40
else
  set t_Co=256
  set termguicolors
endif

set background=dark
colorscheme retrobox
syntax enable

" }}}
