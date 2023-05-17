" function to trim trailing spaces on multiple lines
" can alternatlive use <leader>s as detailed below for single lines
fun! StripTrailingWhitespaces()
  let l = line(".")
  let c = col(".")
  %s/\s\+$//e
  call cursor(l, c)
endfun

if ! has('gui_running')
    set ttimeoutlen=10
    augroup FastEscape
        autocmd!
        au InsertEnter * set timeoutlen=0
        au InsertLeave * set timeoutlen=1000
    augroup END
endif

" work-around for errors while using fish shell
set shell=bash

"""""""""""
" plugins "
"""""""""""
call plug#begin('~/.vim/plugged')

" Displays code tags in a sidebar
Plug 'majutsushi/tagbar'
" Provides automatic closing quotes/brackets/...
Plug 'Raimondi/delimitMate'
" Tree file explorer
Plug 'scrooloose/nerdtree'
" Changes surrounding tags
Plug 'tpope/vim-surround'
" Git in vim
Plug 'tpope/vim-fugitive'
" Add/remove comments
Plug 'tpope/vim-commentary'
" Date manipulation
Plug 'tpope/vim-speeddating'
" Adds an indent line visual aid
Plug 'Yggdroot/indentLine'
" Multiple colored parents visual aid
Plug 'kien/rainbow_parentheses.vim'
" Syntax checking
Plug 'scrooloose/syntastic'
" Autocomplete in vim
Plug 'Valloric/YouCompleteMe'
" Tabs/spacing
Plug 'godlygeek/tabular'
" Scratch notes
Plug 'mtth/scratch.vim'
" Execute commands in vim
Plug 'Shougo/vimproc.vim'
" Fish syntax highlighting
Plug 'Soares/fish.vim'
" Unique character highlighter (line)
Plug 'unblevable/quick-scope'
"  Plug 'decaycs/decay.nvim', { 'as': 'decay' }
" Plug 'jacoborus/tender.vim'
Plug 'bluz71/vim-nightfly-colors', { 'as': 'nightfly' }

call plug#end()

"""""""""""""""""""""
" general vim stuff "
"""""""""""""""""""""
" toggle cursorline when entering/leaving insert mode
" autocmd InsertEnter,InsertLeave * set cul!
" always highlight current line
set cursorline

"folding settings
set foldmethod=indent   " fold based on indent
set foldnestmax=10      " deepest fold is 10 levels
set nofoldenable        " dont fold by default
set foldlevel=1         " this is just what i use

" enable y/yy yanking to utilize system clipboard
set clipboard=unnamed

""""""""""""""""""""""""""""""""""""
" syntax and colorscheme specifics "
""""""""""""""""""""""""""""""""""""
syntax enable
colorscheme nightfly
set fileencodings=utf-8

"""""""""""""""""""""
" filetype settings "
"""""""""""""""""""""
" required for vundle
filetype off
filetype plugin on
filetype indent off
set smartindent
syntax on

" detect filetype fix
au BufRead,BufNewFile *.exp set filetype=tcl

" python stuff
au FileType python set omnifunc=pythoncomplete#Complete
let g:SuperTabDefaultCompletionType = "context"
set completeopt=menuone,longest,preview

" golang stuff
au FileType go nmap <leader>i <Plug>(go-info)
au FileType go nmap <leader>gd <Plug>(go-doc)
au FileType go nmap <leader>gv <Plug>(go-doc-vertical)
au FileType go nmap <leader>r <Plug>(go-run)
au FileType go nmap <leader>b <Plug>(go-build)
au FileType go nmap <leader>t <Plug>(go-test)
au FileType go nmap <leader>c <Plug>(go-coverage)
au FileType go nmap <leader>ds <Plug>(go-def-split)
au FileType go nmap <leader>dv <Plug>(go-def-vertical)
au FileType go nmap <leader>dt <Plug>(go-def-tab)

""""""""
" sets "
""""""""
set hidden
set modelines=0
" required for vundle
set nocompatible
set nobackup
set noswapfile
set number
set wildmenu " visual autocomplete for command menu
set lazyredraw " don't always redraw if not needed
set showmatch " highlight matching brackets/parens

" enable hybrid line numbers
set nu
set rnu

" general settings
let mapleader=","

" tab settings
"" use spaces instead of tabs
set expandtab
set smarttab
"" set tab to four spaces
set tabstop=2 " number of visual spaces per TAB
set softtabstop=2 " number of spaces in tab when editing
set shiftwidth=2

" show the last command entered
set showcmd

" indent settings
set autoindent

" backspace settings
set backspace=indent,eol,start

" search settings
set ignorecase
set incsearch
set hlsearch

" status line stuff
"set statusline=%F%m%r%h%w\ [FORMAT=%{&ff}]\ [TYPE=%Y]\ [ASCII=\%03.3b]\ [HEX=\%02.2B]\ [POS=%04l,%04v][%p%%]\ [LEN=%L]
set laststatus=2

" disable the read-only warning
set autoread
command W :execute ':silent w !sudo tee % > /dev/null' | :edit!

" better handling of large files (still testing)
" set synmaxcol=120

" disable obnoxious bell in vim
set visualbell

""""""""
" maps "
""""""""
" paste
nnoremap <silent> <leader>pp :set paste!<CR>
" copy line to system clipboard (middle click)
nnoremap <leader>y "*y
" copy entire file to system clipboard (middle click)
nnoremap <leader>Y ggVG"*y

" Home key
imap <esc>OH <esc>0i
cmap <esc>OH <home>
nmap <esc>OH 0

" End key
nmap <esc>OF $
imap <esc>OF <esc>$a
cmap <esc>OF <end>

" training to not use arrow keys wooooo
nnoremap <up> <nop>
nnoremap <down> <nop>
nnoremap <left> <nop>
nnoremap <right> <nop>
nnoremap j gj
nnoremap k gk

" remap hjkl to be less annoying (to fit better with default homerow/index key)
noremap ; l
noremap l k
noremap k j
noremap j h

" remap doubles to <ESC> for easy switching from insert mode
inoremap jj <ESC>
inoremap kk <ESC>
inoremap lll <ESC>
inoremap ;; <ESC>

" select all
nnoremap aa ggVG

" easy window split
"nnoremap <leader>w <C-w>v<C-w>l
nnoremap <leader>v :vsplit<CR>
nnoremap <leader>h :split<CR>

" easy window switching
nnoremap <silent> <leader>; :wincmd l<CR>
nnoremap <silent> <leader>l :wincmd k<CR>
nnoremap <silent> <leader>k :wincmd j<CR>
nnoremap <silent> <leader>j :wincmd h<CR>

" easy window moving
nnoremap <silent> <leader>: :wincmd L<CR>
nnoremap <silent> <leader>L :wincmd K<CR>
nnoremap <silent> <leader>K :wincmd J<CR>
nnoremap <silent> <leader>J :wincmd H<CR>

" easy tabs
"nnoremap <leader>tn :tabnew<cr>
"nnoremap <leader>to :tabonly<cr>
"nnoremap <leader>tc :tabclose<cr>
"nnoremap <leader>tj :tabp<cr>
"nnoremap <leader>t; :tabn<cr>
"map <leader>tm :tabmove

" key remaps
nmap <F4> :NERDTreeToggle<CR>
nmap <F8> :TagbarToggle<CR>
" F1 is bad
inoremap <F1> <ESC>
nnoremap <F1> <ESC>
vnoremap <F1> <ESC>

" trim trailing spaces
"nnoremap <leader>s :s/\s\+$//e<CR>
nnoremap <leader>S :call StripTrailingWhitespaces()<CR>
" automatically delete trailing whitespace on save
au BufWritePre * :%s/\s\+$//e

" get rid of hightlighting after a search
" same as :nohlsearch
nnoremap <leader><space> :noh<cr>

" stop that stupid window from popping up
map q: :q

"""""""""""""""""""
" plugin specific "
"""""""""""""""""""
""" IndentLines
let g:indentLine_color_term = 239
let g:indentLine_char = '|'

""" RainbowParentheses
au VimEnter * RainbowParenthesesToggle
au Syntax * RainbowParenthesesLoadRound
au Syntax * RainbowParenthesesLoadSquare
au Syntax * RainbowParenthesesLoadBraces
" specify colors! (added to remove black!)
let g:rbpt_colorpairs = [
  \ ['brown',       'RoyalBlue3'],
  \ ['Darkblue',    'SeaGreen3'],
  \ ['darkgray',    'DarkOrchid3'],
  \ ['darkgreen',   'firebrick3'],
  \ ['darkcyan',    'RoyalBlue3'],
  \ ['darkred',     'SeaGreen3'],
  \ ['darkmagenta', 'DarkOrchid3'],
  \ ['brown',       'firebrick3'],
  \ ['gray',        'RoyalBlue3'],
  \ ['darkmagenta', 'DarkOrchid3'],
  \ ['Darkblue',    'firebrick3'],
  \ ['darkgreen',   'RoyalBlue3'],
  \ ['darkcyan',    'SeaGreen3'],
  \ ['darkred',     'DarkOrchid3'],
  \ ['red',         'firebrick3'],
\ ]

""" unite
let g:unite_source_history_yank_enable = 1
nnoremap <C-p> :Unite file_rec/async<cr>
nnoremap <space>/ :Unite grep:.<cr>
nnoremap <space>y :Unite history/yank<cr>
nnoremap <space>s :Unite -quick-match buffer<cr>

""" multicursor
let g:multi_cursor_use_default_mapping=0
let g:multi_cursor_next_key='<C-n>'
let g:multi_cursor_prev_key='<C-p>'
let g:multi_cursor_skip_key='<C-x>'
let g:multi_cursor_quit_key='<Esc>'

""" gotags
let g:tagbar_type_go = {
    \ 'ctagstype' : 'go',
    \ 'kinds'     : [
        \ 'p:package',
        \ 'i:imports:1',
        \ 'c:constants',
        \ 'v:variables',
        \ 't:types',
        \ 'n:interfaces',
        \ 'w:fields',
        \ 'e:embedded',
        \ 'm:methods',
        \ 'r:constructor',
        \ 'f:functions'
    \ ],
    \ 'sro' : '.',
    \ 'kind2scope' : {
        \ 't' : 'ctype',
        \ 'n' : 'ntype'
    \ },
    \ 'scope2kind' : {
        \ 'ctype' : 't',
        \ 'ntype' : 'n'
    \ },
    \ 'ctagsbin'  : 'gotags',
    \ 'ctagsargs' : '-sort -silent'
\ }

let g:ctrlp_cache_dir = $HOME . '/.cache/ctrlp'
if executable('ag')
  let g:ctrlp_user_command = 'ag %s -l --nocolor -g ""'
endif

" commentary
autocmd FileType fish setlocal commentstring=#\ %s

""" autosave
let g:auto_save = 1 " enable autosave on vim start
let g:auto_save_no_updatetime = 1 " do not change the 'updatetime' option
let g:auto_save_in_insert_mode = 0  " do not save while in insert mode
