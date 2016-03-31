execute pathogen#infect()

" This must be first, because it changes other options as side effect
set nocompatible

filetype plugin on


set hidden

let mapleader=","

set nowrap        " don't wrap lines
set tabstop=4     " a tab is four spaces
set backspace=indent,eol,start     " allow backspacing over everything in insert mode
set autoindent    " always set autoindenting on
set copyindent    " copy the previous indentation on
set number        " always show line numbers
set shiftwidth=4  " number of spaces to use for autoindenting
set shiftround    " use multiple of shiftwidth when indenting with '<' and '>'
set showmatch     " set show matching parenthesis
set ignorecase    " ignore case when searching
set smartcase     " ignore case if search pattern is all lowercase, case-sensitive otherwise
set smarttab      " insert tabs on the start of a line accordi shiftwidth, not tabstop
set hlsearch      " highlight search terms
set incsearch     " show search matches as you type
                   
set history=1000         " remember more commands and search history
set undolevels=1000      " use many muchos levels of undo
set wildignore=*.swp,*.bak,*.pyc,*.class
set title                " change the terminal's title
set visualbell           " don't beep
set noerrorbells         " don't beep

" set colors
"set t_Co=256
"let g:Powerline_symbols = "fancy"

if &t_Co > 2 || has("gui_running")
    " switch syntax highlighting on, when the terminal has colors
   syntax on
endif

set pastetoggle=<F2>

nnoremap ; :

nnoremap j gj
nnoremap k gk

map <up> <nop>
map <down> <nop>
map <left> <nop>
map <right> <nop>

nmap <silent> ,/ :nohlsearch<CR>


