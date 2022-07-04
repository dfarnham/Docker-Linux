version 6.0
set wildignore+=*.hi,*.pyc,*.o,*.class
vnoremap <silent> # :s/^/#/<cr>:noh<cr>
vnoremap <silent> ## :s/^#//<cr>:noh<cr>
let g:ctrlp_custom_ignore = 'target/'
autocmd FileType crontab setlocal backupcopy=yes
setlocal formatoptions-=c formatoptions-=r formatoptions-=o
if !empty(glob("$HOME/.vim/bundle"))
    execute pathogen#infect('bundle/{}')
endif
"execute pathogen#infect()

syntax enable
filetype plugin indent on

"set statusline+=%#warningmsg#
"set statusline+=%{SyntasticStatuslineFlag()}
"set statusline+=%*
"
"let g:syntastic_always_populate_loc_list = 1
"let g:syntastic_auto_loc_list = 1
"let g:syntastic_check_on_open = 1
"let g:syntastic_check_on_wq = 0

set autoindent
set cmdheight=2
set modelines=0
set expandtab
set dictionary=/usr/share/dict/words
if has("multi_byte")
    if &termencoding == ""
        let &termencoding = &encoding
    endif
    set encoding=utf-8
    setglobal fileencoding=utf-8
    "setglobal bomb
    set fileencodings=ucs-bom,utf-8,latin1
endif
set guifont=Courier_New:h16
set helplang=en
set hlsearch
set ignorecase
set incsearch
set mouse=v
set report=1
set shell=/bin/sh
set shiftwidth=4
set showmatch
set tabstop=4
if has('gui_running')
    :colorscheme murphy
else
    :colorscheme dave
endif
:syn on
set nocursorline
set nocursorcolumn
"filetype plugin indent on
if &cp | set nocp | endif
let s:cpo_save=&cpo
set ruler
set cpo&vim
set t_Co=256
map! <S-Insert> <MiddleMouse>
cmap <D-g> <D-g>
imap <D-g> <D-g>
cmap <D-f> <D-f>
imap <D-f> <D-f>
cmap <D-a> <D-a>
imap <D-a> <D-a>
cnoremap <D-v> +
cnoremap <D-c> 
cmap <D-z> <D-z>
imap <D-z> <D-z>
cmap <S-D-s> <D-s>
imap <S-D-s> <D-s>
cmap <D-s> <D-s>
imap <D-s> <D-s>
cmap <D-w> <D-w>
imap <D-w> <D-w>
cmap <D-o> <D-o>
imap <D-o> <D-o>
cmap <D-n> <D-n>
imap <D-n> <D-n>
map - $
map ; :
map Q :q!
map W :'a,'bw 
map ^^ {!}/Users/dafa5923/dev/GitHub/par/par}
map ^ {!}/Users/dafa5923/dev/GitHub/par/par
"map s :SyntasticToggleMode
"map S :SyntasticCheck
map <C-n> :noh
nmap gx <Plug>NetrwBrowseX
map z z
nnoremap <expr> gp '`[' . strpart(getregtype(), 0, 1) . '`]'
map <S-Insert> <MiddleMouse>
nnoremap <silent> <Plug>NetrwBrowseX :call netrw#NetBrowseX(expand("<cWORD>"),0)
omap <D-g> <D-g>
vmap <D-g> <D-g>
nnoremap <D-g> n
omap <D-f> <D-f>
vmap <D-f> <D-f>
nnoremap <D-f> /
omap <D-a> <D-a>
vmap <D-a> <D-a>
nnoremap <silent> <D-a> :if &slm != ""|exe ":norm gggHG"| else|exe ":norm ggVG"|endif
omap <D-z> <D-z>
vmap <D-z> <D-z>gv
nnoremap <D-z> u
omap <S-D-s> <D-s>
vmap <S-D-s> <D-s>gv
nnoremap <S-D-s> :browse confirm saveas
omap <D-s> <D-s>
vmap <D-s> <D-s>gv
nnoremap <silent> <D-s> :if expand("%") == ""|browse confirm w| else|confirm w|endif
omap <D-w> <D-w>
vmap <D-w> <D-w>gv
nnoremap <silent> <D-w> :if winheight(2) < 0 | confirm enew | else | confirm close | endif
omap <D-o> <D-o>
vmap <D-o> <D-o>gv
nnoremap <D-o> :browse confirm e
omap <D-n> <D-n>
vmap <D-n> <D-n>gv
nnoremap <D-n> :confirm enew
vmap <BS> "-d
vnoremap <D-x> "+x
vnoremap <D-c> "+y
nnoremap <D-v> "+gP
let &cpo=s:cpo_save
unlet s:cpo_save
" vim: set ft=vim :
