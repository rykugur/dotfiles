" function to trim trailing spaces on multiple lines
" can alternatlive use <leader>s as detailed below for single lines
fun! StripTrailingWhitespaces()
    let l = line(".")
    let c = col(".")
    %s/\s\+$//e
    call cursor(l, c)
endfun

" enable vundle
set rtp+=~/.vim/bundle/vundle/
call vundle#rc()

" enable powerline
set rtp+=~/dotfiles/powerline/powerline/bindings/vim
"set rtp+=/usr/local/lib/python2.7/site-packages/Powerline-beta-py2.7.egg/powerline/bindings/vim
"call vam#ActivateAddons(['powerline'])

" let Vundle manage Vundle
"  " required! 
Bundle 'gmarik/vundle'

" Vundle Bundles
" To update/install: :BundleInstall in or vim +BundleInstall +qall on cli
Bundle 'ervandew/supertab'
Bundle 'majutsushi/tagbar'
Bundle 'Raimondi/delimitMate'
Bundle 'scrooloose/nerdtree'
Bundle 'tpope/vim-surround'
Bundle 'tpope/vim-fugitive'
Bundle 'vim-scripts/comments.vim'
Bundle 'Yggdroot/indentLine'
Bundle 'nathanaelkane/vim-indent-guides'
Bundle 'kien/rainbow_parentheses.vim'
Bundle 'scrooloose/syntastic'
Bundle 'vim-scripts/slimv.vim'
Bundle 'xolox/vim-misc'
Bundle 'xolox/vim-notes'

" syntax and colorscheme specifics
syntax enable
"colorscheme distinguished
colorscheme hybrid
"colorscheme 256-grayvim
"colorscheme mustang
"set t_Co=256
set fileencodings=utf-8
"let g:molokai_original = 1
"set background=dark
"
" IndentLines
let g:indentLine_color_term = 239

" filetype settings
filetype on
filetype plugin on
filetype indent on

" IndentGuides (default key: <leader>ig)
let g:indent_guides_auto_colors = 0
autocmd VimEnter,Colorscheme * :hi IndentGuidesOdd ctermbg=darkgray
autocmd VimEnter,Colorscheme * :hi IndentGuidesEven ctermbg=gray
set ts=2 sw=2 noet
let g:indent_guides_start_level=2
"let g:indent_guides_guide_size=1

" RainbowParentheses
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

" detect filetype fix
au BufRead,BufNewFile *.exp set filetype=tcl

" python stuff
au FileType python set omnifunc=pythoncomplete#Complete
let g:SuperTabDefaultCompletionType = "context"
set completeopt=menuone,longest,preview

" general settings
" set mapleader
let mapleader=","
" tab settings
set expandtab
set shiftwidth=4
set tabstop=4
" indent settings
set autoindent
" search settings
set ignorecase
set incsearch
set hlsearch
" status line stuff
"set statusline=%F%m%r%h%w\ [FORMAT=%{&ff}]\ [TYPE=%Y]\ [ASCII=\%03.3b]\ [HEX=\%02.2B]\ [POS=%04l,%04v][%p%%]\ [LEN=%L]
set laststatus=2
" other misc sets
set cursorline
set hidden
set modelines=0
set nocompatible
set nobackup
set noswapfile
set number
"set pastetoggle=<leader><F5>
nnoremap <silent> <leader>pp :set paste!<CR>

" key remaps
nmap <F4> :NERDTreeToggle<CR>
nmap <F8> :TagbarToggle<CR>
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
"inoremap <up> <nop>
"inoremap <down> <nop>
"inoremap <left> <nop>
"inoremap <right> <nop>
nnoremap j gj
nnoremap k gk
" F1 is bad
inoremap <F1> <ESC>
nnoremap <F1> <ESC>
vnoremap <F1> <ESC>
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
" easy tabs
"nnoremap <leader>tn :tabnew<cr>
"nnoremap <leader>to :tabonly<cr>
"nnoremap <leader>tc :tabclose<cr>
"nnoremap <leader>tj :tabp<cr>
"nnoremap <leader>t; :tabn<cr>
"map <leader>tm :tabmove
" trim trailing spaces
nnoremap <leader>s :s/\s\+$//e<CR>
nnoremap <leader>S :call StripTrailingWhitespaces()<CR>
" get rid of hightlighting after a search
nnoremap <leader><space> :noh<cr>
" copy line to system clipboard (middle click)
nnoremap <leader>y "*y
" copy line to system clipboard that can be used in Windows VM (this is
" retarded)
nnoremap <leader>wy "+y
" copy entire file to system clipboard (middle click)
nnoremap <leader>Y ggVG"*y
" copy entire file to system clipboard that can be used in Windows VM (this is
" still retarded)
nnoremap <leader>WY ggVG"+y
" slimv
let g:slimv_swank_scheme=1
" vim-notes
":let g:notes_directories = ['~/Google\ Drive/Notes']

"folding settings
set foldmethod=indent   "fold based on indent
set foldnestmax=10      "deepest fold is 10 levels
set nofoldenable        "dont fold by default
set foldlevel=1         "this is just what i use
