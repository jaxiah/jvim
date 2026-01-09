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
    botright terminal powershell
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

" c/c++ dev {{{
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
