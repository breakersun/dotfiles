syntax on
set noswapfile
set hlsearch
set ignorecase
set incsearch
set number
set mouse=a
set clipboard+=unnamedplus
set encoding=UTF-8
set nocompatible

call plug#begin('~/AppData/Local/nvim/plugged')

Plug 'sheerun/vim-polyglot'

Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

Plug 'preservim/nerdtree'

Plug 'tpope/vim-fugitive'

"Plug 'itchyny/lightline.vim'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

Plug 'luochen1990/rainbow'

Plug 'prettier/vim-prettier', { 'do': 'yarn install --frozen-lockfile --production' }

Plug 'preservim/nerdcommenter'

Plug 'ryanoasis/vim-devicons'
Plug 'ggandor/lightspeed.nvim'

Plug 'liuchengxu/vim-which-key'

"Plug 'adi/vim-indent-rainbow'
Plug 'python-mode/python-mode', { 'for': 'python', 'branch': 'develop' }
call plug#end()

let mapleader = ' '

"for fzf
nnoremap <leader>pv :Vex<CR>
nnoremap <leader>pf :Files<CR>
nnoremap <C-p> :GFiles<CR>
"quick save
inoremap jk <esc>:w<CR>
"dragging line 
nnoremap <A-j> :m .+1<CR>==
nnoremap <A-k> :m .-2<CR>==
inoremap <A-j> <Esc>:m .+1<CR>==gi
inoremap <A-k> <Esc>:m .-2<CR>==gi
vnoremap <A-j> :m '>+1<CR>gv=gv
vnoremap <A-k> :m '<-2<CR>gv=gv
"for nerd tree file-browser
nnoremap <leader>n :NERDTreeFocus<CR>
nnoremap <C-n> :NERDTree<CR>
nnoremap <C-t> :NERDTreeToggle<CR>
nnoremap <C-f> :NERDTreeFind<CR>

nnoremap <silent> <leader> :<c-u>WhichKey '<Space>'<CR>
vnoremap <silent> <leader> :<c-u>WhichKeyVisual '<Space>'<CR>

"enable luochen1990/rainbow
let g:rainbow_active = 1
let g:airline_powerline_fonts = 1
let g:NERDTreeWinPos = "right"

let g:which_key_map =  {'pf' : 'FuzzyFiles', 'pv' : 'NERDTree'}
let g:which_key_map.c = {'name' : '+NERDComment' }
call which_key#register('<Space>', "g:which_key_map")
