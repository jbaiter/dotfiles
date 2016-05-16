set nocompatible            " be iMproved
filetype off                " required!

set binary                  " preserve EOLs

if has('nvim')
    runtime! python_setup.vim
endif

function! UpdateRPlugin(info)
  if has('nvim')
    silent UpdateRemotePlugins
    echomsg 'rplugin updated: ' . a:info['name'] . ', restart vim for changes'
  endif
endfunction

" +---------+
"   Plugins
" +---------+
call plug#begin('~/.config/nvim/plugged')
Plug 'ervandew/supertab'
" " syntax and error highlighter
Plug 'scrooloose/syntastic'
" very agreeable colorscheme
"Plug 'altercation/vim-colors-solarized'
"Plug 'chriskempson/vim-tomorrow-theme'
Plug 'easysid/mod8.vim'
" quoting/parenthesizing made simple
Plug 'tpope/vim-surround'
" snip-snap
"Plug 'SirVer/ultisnips'
Plug 'honza/vim-snippets'
" grep through multiple files from vim
Plug 'Numkil/ag.vim'
" Library needed for quickfixsigns
Plug 'tomtom/vimtlib'
" Mark quickfix and list items with signs
Plug 'tomtom/quickfixsigns_vim'
" Fuzzy file, buffer, mru, tag, etc finder
Plug 'ctrlpvim/ctrlp.vim'
Plug 'tinymode.vim'
" Better statusline
"Plug 'Lokaltog/vim-powerline'
Plug 'bling/vim-airline'
" Git integration
Plug 'tpope/vim-fugitive'
" Better session management
Plug 'tpope/vim-obsession'
" Repeating for plugin maps
Plug 'tpope/vim-repeat'
" Easier navigation
Plug 'Lokaltog/vim-easymotion'
" Easer commenting
"Plug 'scrooloose/nerdcommenter'
Plug 'tpope/vim-commentary'
" Ledger syntax
Plug 'ledger/vim-ledger', {'for': 'ledger'}
" Better line numbers
Plug 'myusuf3/numbers.vim'
" Fast and fuzzy completion
Plug 'Valloric/YouCompleteMe', {'do': './install.sh --clang-completer --tern-completer --racer-completer', 'for': ['python', 'c', 'cpp', 'javascript', 'rust']}
Plug 'rdnetto/YCM-Generator', { 'branch': 'stable'}
" Better Python support
"Plug 'davidhalter/jedi-vim'
" Higlight opening/closing tags in XML
Plug 'Valloric/MatchTagAlways', {'for': ['xml', 'html']}
" better reStructured Text support
Plug 'Rykka/riv.vim', {'for': 'rst'}
Plug 'Rykka/clickable.vim', {'for': 'rst'}
" py.test integration
Plug 'alfredodeza/pytest.vim', {'for': 'python'}
" support for ReactJS' JSX format
Plug 'mxw/vim-jsx'
"Plug 'jelera/vim-javascript-syntax', {'for': 'javascript'}
Plug 'pangloss/vim-javascript', {'for': 'javascript'}
Plug 'nathanaelkane/vim-indent-guides'
Plug 'Raimondi/delimitMate'
Plug 'marijnh/tern_for_vim', {'for': 'javascript', 'do': 'npm install'}
Plug 'kana/vim-textobj-user'
Plug 'christoomey/vim-tmux-navigator'
"Plug 'vim-scripts/DrawIt'
"Plug 'ardagnir/vimbed'
Plug 'kchmck/vim-coffee-script', {'for': 'coffee'}

Plug 'elzr/vim-json', {'for': 'json'}

" Clojure stuff
Plug 'tpope/vim-leiningen', {'for': 'clojure'}
"Plug 'tpope/vim-projectionist', {'for': 'clojure'}
Plug 'tpope/vim-dispatch', {'for': 'clojure'}
Plug 'tpope/vim-fireplace', {'for': 'clojure'}
Plug 'guns/vim-clojure-static', {'for': 'clojure'}
Plug 'guns/vim-clojure-highlight', {'for': 'clojure'}
Plug 'guns/vim-sexp', {'for': 'clojure'}
Plug 'tpope/vim-sexp-mappings-for-regular-people', {'for': 'clojure'}
Plug 'kien/rainbow_parentheses.vim', {'for': 'clojure'}
Plug 'tpope/vim-classpath', {'for': ['clojure', 'java']}
Plug 'venantius/vim-eastwood', {'for': 'clojure'}
Plug 'snoe/nvim-parinfer.js', { 'do': function('UpdateRPlugin'), 'for': 'clojure'}
Plug 'venantius/vim-cljfmt', {'for': 'clojure'}

" Better completion behavior
"Plug 'Shougo/neocomplete', {'for': 'clojure'}

Plug 'neovim/node-host'

" Haskell
Plug 'bitc/vim-hdevtools', {'for': 'haskell'}
Plug 'neovimhaskell/haskell-vim', {'for': 'haskell'}
"Plug 'enomsg/vim-haskellConcealPlus', {'for': 'haskell'}

" Prolog
Plug 'adimit/prolog.vim', {'for': 'prolog'}

" Pandoc
Plug 'vim-pandoc/vim-pandoc', {'for': 'pandoc'}
Plug 'vim-pandoc/vim-pandoc-syntax', {'for': 'pandoc'}
Plug 'Shougo/unite.vim', {'for': 'pandoc'}
Plug 'rafaqz/citation.vim', {'for': 'pandoc'}

" Rust
Plug 'rust-lang/rust.vim', {'for': 'rust'}
Plug 'cespare/vim-toml'

Plug 'mtth/scratch.vim'
Plug 'vim-scripts/SWIG-syntax'
call plug#end()

" +----------------+
"   Basic settings
" +----------------+

syntax on                   " syntax highlighing
filetype on                 " try to detect filetypes
filetype plugin indent on   " enable loading indent file for filetype
set number                  " Display line numbers
set numberwidth=1           " using only 1 column (and 1 space) while possible
set background=dark         " We are using a dark background in vim
set title                   " show title in console title bar
set wildmenu                " Menu completion in command mode on <Tab>
set wildmode=full           " <Tab> cycles between all matching choices.
set encoding=utf-8          " Set encoding to unicode
set ttyfast                 " Improves redrawing
set lazyredraw
" show a line at column 79
if exists("&colorcolumn")
    set colorcolumn=79
endif
""" Moving Around/Editing
"set cursorline              " have a line indicate the cursor location
set ruler                   " show the cursor position all the time
set nostartofline           " Avoid moving cursor to BOL when jumping around
set virtualedit=block       " Let cursor move past the last char in <C-v> mode
set scrolloff=3             " Keep 3 context lines above and below the cursor
set backspace=2             " Allow backspacing over autoindent, EOL, and BOL
set showmatch               " Briefly jump to a paren once it's balanced
set matchtime=2             " (for only .2 seconds).
set nowrap                  " don't wrap text
set linebreak               " don't wrap textin the middle of a word
set autoindent              " always set autoindenting on
set tabstop=4               " <tab> inserts 4 spaces
set shiftwidth=4            " but an indent level is 2 spaces wide.
set softtabstop=4           " <BS> over an autoindent deletes both spaces.
set expandtab               " Use spaces, not tabs, for autoindent/tab key.
set shiftround              " rounds indent to a multiple of shiftwidth
"set matchpairs+=<:>         " show matching <> (html mainly) as well
set foldmethod=indent       " allow us to fold on indents
set foldlevel=99            " don't fold by default
set hidden                  " only hide buffers on switch
set undofile                " Enable persistent history
set smartindent             " Smart indendation
"set iskeyword-=_            " Make '_' behave as a word boundary

""" Disable moving around with arrow key
nnoremap <up> <nop>
nnoremap <down> <nop>
nnoremap <left> <nop>
nnoremap <right> <nop>
inoremap <up> <nop>
inoremap <down> <nop>
inoremap <left> <nop>
inoremap <right> <nop>

map J 25j
"map K 25k

" close preview window automatically when we move around
autocmd CursorMovedI * if pumvisible() == 0|pclose|endif
autocmd InsertLeave * if pumvisible() == 0|pclose|endif

"""" Reading/Writing
set noautowrite             " Never write a file unless I request it.
set noautowriteall          " NEVER.
set noautoread              " Don't automatically re-read changed files.
set modeline                " Allow vim options to be embedded in files;
set modelines=5             " they must be within the first or last 5 lines.
set ffs=unix,dos,mac        " Try recognizing dos, unix, and mac line
                            " endings.

"""" Messages, Info, Status
set ls=2                    " allways show status line
set vb t_vb=                " Disable all bells.  I hate ringing/flashing.
set confirm                 " Y-N-C prompt if closing with unsaved changes.
set showcmd                 " Show incomplete normal mode commands as I
                            " type.
set report=0                " : commands always print changed line count.
set shortmess+=a            " Use [+]/[RO]/[w] for
                            " modified/readonly/written.
set ruler                   " Show some info, even without statuslines.
set laststatus=2            " Always show statusline, even if only 1 window.
set statusline=%<%f\ (%{&ft})%=%-19(%3l,%02c%03V%)%{fugitive#statusline()}
let g:Powerline_symbols = "unicode"

" displays tabs with :set list & displays when a line runs off-screen
set listchars=tab:>-,trail:-,precedes:<,extends:>
set list
"
""" Searching and Patterns
set ignorecase              " Default to using case insensitive searches,
set smartcase               " unless uppercase letters are used in the
                            " regex.
set hlsearch                " Highlight searches by default.
set incsearch               " Incrementally search while typing a /regex

"""" Display
"let g:solarized_termtrans=0
"let g:solarized_termcolors=256
"if has('gui-running')
"    let g:solarized_visibility="low"
""    colorscheme Tomorrow
"else
"let g:solarized_visibility="normal"
"    "colorscheme Tomorrow-Night
"endif
colorscheme mod8

""" Syntastic configuration
let g:syntastic_mode_map = { 'mode': 'passive',
                           \ 'active_filetypes': ['python', 'haskell', 'javascript'] }
let g:syntastic_phpcs_disable = 1
let g:syntastic_javascript_checkers=['eslint']
let g:syntastic_python_checkers = ['python', 'flake8']
let g:syntastic_check_on_open = 1
let g:syntastic_error_symbol = '✗'
let g:syntastic_warning_symbol = '⚠'

""" CtrlP configuration
" BUG! Opening a matching file with gvim --remote will fail with E479!
" See here for more information: http://marc.info/?l=vim-dev&m=116906111713031
set wildignore+=*.so,*.swp,*.zip,*.tmp,*/target/*
let g:ctrlp_custom_ignore = {
  \ 'dir':  '\v[\/](\.(git|hg|svn)|node_modules|out|target)$',
  \ 'file': '\v\.(exe|so|dll)$',
  \ 'link': 'some_bad_symbolic_links',
  \ }



""" Backup/Swap/Undo file path
set dir=~/.config/nvim/swap
set backupdir=~/.config/nvim/backup
set undodir=~/.config/nvim/undo

""" MatchingTag configuration
let g:mta_filetypes = {
    \ 'html' : 1,
    \ 'xhtml' : 1,
    \ 'xml' : 1,
    \ 'xslt' : 1,
    \ 'template' : 1,
    \ 'jinja' : 1
    \}

" +-----------------+
"   Custom mappings
" +-----------------+
let mapleader="\<Space>"

" paste from system clipboard
nnoremap <leader>v "+P"
" yank into system clipboard
nnoremap <leader>c "+y"

" Clear current search highlight
nnoremap <esc> :noh<return><esc>

" ctrl-jklm  changes to that split
map <c-j> <c-w>j
map <c-k> <c-w>k
map <c-l> <c-w>l
map <c-h> <c-w>h

" and let's make these all work in insert mode too ( <C-O> makes next cmd
"  happen as if in command mode )
imap <C-W> <C-O><C-W>

" cd into the file's directory
map <leader>cd :lcd %:p:h<CR>

" CtrlP mappings
map <leader>p :CtrlP<CR>
map <leader>b :CtrlPBuffer<CR>
map <leader>m :CtrlPMRU<CR>

" Switch between relative and absolute line numbering
nnoremap <F3> :NumbersToggle<CR>

" py.test mappings
map <leader>tf :Pytest file<CR>
map <leader>tc :Pytest class<CR>
map <leader>tfunc :Pytest function<CR>
map <leader>tp :Pytest project<CR>

au BufRead,BufNewFile *.php,*.xml,*.xslt,*.html,*.js,*.jsx,*.css,*.clj* setl sw=2 sts=2 ts=2 et
au BufRead,BufNewFile *.py,*.java setl sw=4 sts=4 ts=4 et

" clojure
au VimEnter *.clj,*.cljs RainbowParenthesesToggle
au Syntax *.clj,*.cljs RainbowParenthesesLoadRound
au Syntax *.clj,*.cljs RainbowParenthesesLoadSquare
au Syntax *.clj,*.cljs RainbowParenthesesLoadBraces
let g:clojure_align_multiline_strings = 1

" Make UltiSnips work with YCM
let g:SuperTabDefaultCompletionType    = '<C-n>'
let g:SuperTabCrMapping                = 0
let g:UltiSnipsExpandTrigger           = '<tab>'
let g:UltiSnipsJumpForwardTrigger      = '<tab>'
let g:UltiSnipsJumpBackwardTrigger     = '<s-tab>'
let g:ycm_key_list_select_completion   = ['<C-j>', '<C-n>', '<Down>']
let g:ycm_key_list_previous_completion = ['<C-k>', '<C-p>', '<Up>']
let g:ycm_rust_src_path = '~/.multirust/toolchains/stable/src'

set omnifunc=syntaxcomplete#Complete

au FileType haskell nnoremap <buffer> <F1> :HdevtoolsType<CR>
au FileType haskell nnoremap <buffer> <silent> <F2> :HdevtoolsClear<CR>

let g:javascript_conceal_function   = "ƒ"
let g:javascript_conceal_null       = "ø"
let g:javascript_conceal_this       = "@"
let g:javascript_conceal_undefined  = "¿"
let g:javascript_conceal_NaN        = "ℕ"
let g:javascript_conceal_prototype  = "¶"
let g:javascript_conceal_static     = "•"
let g:javascript_conceal_super      = "Ω"

let g:citation_vim_file_path=["/home/jojo/.zotero/zotero/xg4ok7b6.default"]
let g:citation_vim_file_format="zotero"
nmap , [unite] nnoremap [unite]
nnoremap <silent>[unite]c :<C-u>Unite -buffer-name=citation -start-insert -default-action=append bibtex<cr>


:tnoremap <Esc> <C-\><C-n>

set cole=1

let g:ag_working_path_mode='r'
