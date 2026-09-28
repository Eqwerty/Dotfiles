" ---------- Indentation ----------
set autoindent
set expandtab
set tabstop=4
set shiftwidth=4
set softtabstop=4

filetype plugin indent on

" ---------- Search ----------
set ignorecase
set smartcase
set incsearch
set hlsearch

" ---------- UI ----------
set number
set cursorline
syntax on
set laststatus=2
set statusline=%f   " show relative file path at bottom

" ---------- Clipboard ----------
set clipboard=

" ---------- Keymaps ----------
" Jump between methods/classes
nnoremap <A-Up>   [m
nnoremap <A-Down> ]m

" Move word by word
nnoremap <A-Left>  b
nnoremap <A-Right> w
xnoremap <A-Left>  b
xnoremap <A-Right> w
inoremap <A-Left>  <S-Left>
inoremap <A-Right> <S-Right>
cnoremap <A-Left>  <S-Left>
cnoremap <A-Right> <S-Right>

" Scroll screen without moving cursor
nnoremap <C-Up> <C-y>
nnoremap <C-down> <C-e>
