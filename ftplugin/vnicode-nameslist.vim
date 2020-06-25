" Author: zsugabubus
if exists('b:did_ftplugin')
	finish
endif

" Add current position to jumplist.
normal! m'

" Do not care about b:undo_ftplugin.
setlocal nonumber norelativenumber nolist

" Jump to {codepoint}.
command! -nargs=1 Codepoint call search('\V\t<args>\>', 'w')|normal! m'
setlocal keywordprg=:Codepoint

" TODO: Make it faster somehow.
setlocal modifiable noreadonly
call setline(1, map(getline(1, '$'),
\ {i,line-> substitute(line, '\v\C^\zs\ze(\x+)', {m-> nr2char(str2nr(m[1], 16))."\t"}, '')}))
setlocal nomodifiable readonly

if exists('g:no_plugin_maps')
	finish
endif

nnoremap <silent><buffer> [[ :call search('\v^\@+\t', 'bW')<CR>
nnoremap <silent><buffer> ]] :call search('\v^\@+\t', 'W')<CR>
nmap <silent><buffer> u :call search('\m^[^\t]', 'bW')<CR>
nmap <silent><buffer> d :call search('\m^[^\t]', 'W')<CR>
nnoremap <silent><buffer> K :call search('\v<\x{4,}', 'c')<CR>K
nmap <silent><buffer> . :call search('\m^[^\t]', 'bWc')<CR>
nnoremap <silent><buffer> q :close<CR>
nmap <silent><buffer> + ."+yl
nmap <silent><buffer> yy .yl<C-w>w
nmap <silent><buffer> Y yy
nmap <silent><buffer> yc $F<Tab>yb<C-w>w
nmap <silent><buffer> <CR> .ylq
