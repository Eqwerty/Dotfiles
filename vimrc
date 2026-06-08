" ---------- Indentation ----------
set tabstop=4
set shiftwidth=4
set softtabstop=4
set expandtab
set smartindent

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

" Scroll screen without moving cursor
nnoremap <C-Up> <C-y>
nnoremap <C-down> <C-e>
