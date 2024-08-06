highlight pythonComment ctermfg=darkgray

highlight javaScriptLineComment ctermfg=darkgray

highlight Comment ctermfg=darkgray

set title

set titlestring=%F

set tabstop=2

set shiftwidth=2

set softtabstop=2

set expandtab

filetype plugin indent on

" JavaScript specific settings

autocmd FileType javascript setlocal shiftwidth=2

autocmd FileType javascript setlocal tabstop=2

autocmd FileType javascript setlocal softtabstop=2

autocmd FileType javascript setlocal expandtab
" Ensure syntax highlighting is enabled
syntax on

" Define a custom color for comments
highlight Comment ctermfg=LightGray guifg=#B0B0B0
