" Author: zsugabubus
if exists('b:did_ftplugin')
	finish
endif

" Add current position to jumplist.
normal! m'

" Do not care about b:undo_ftplugin.
setlocal nonumber norelativenumber nolist tabstop=8

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

" FIXME: TOC looks trash. Somebody tell me what those symbols mean.
function! s:show_toc() abort
	call cursor(1, 1)
	let lnum = 1
	let [head, sub] = [0, 0]
	let loclist = []
	let bufnr = bufnr()

	while 1
		call search('\v^\@+\t', 'W')
		if line('.') ==# lnum
			break
		endif
		let lnum = line('.')
		let [_, ats, title; _] = matchlist(getline('.'), '\v^(\@+)\t*(.*)$')
		if strlen(ats) ==# 1
			let [head, sub] = [head + 1, 0]
			let title = printf('%d. %s', head, title)
		else
			let sub += 1
			let title = printf('%d.%d. %s', head, sub, title)
		endif

		call add(loclist, {'lnum': line('.'), 'bufnr': bufnr(), 'col': 0, 'pattern': '', 'valid': 1, 'vcol': 0, 'nr': 0, 'type': '', 'module': '', 'text': title})
	endwhile

	call setloclist(0, loclist)
	lwindow
endfunction

" Go to previous group.
nnoremap <silent><buffer> [[ :call search('\v^\@+\t', 'bW')<CR>
nmap <silent><buffer> { [[
" Go to next group.
nnoremap <silent><buffer> ]] :call search('\v^\@+\t', 'W')<CR>
nmap <silent><buffer> } ]]
" Up to next character.
nnoremap <silent><buffer> ( :call search('\m^[^\t]', 'bW')<CR>
" Down to next character.
nnoremap <silent><buffer> ) :call search('\m^[^\t]', 'W')<CR>
" Jump to character.
nnoremap <silent><buffer> K :call search('\v<\x{4,}', 'c')<CR>K
" Move to character line.
nmap <silent><buffer> < :call search('\m^[^\t]', 'bWc')<CR>
" Close window.
nnoremap <silent><buffer> q :close<CR>
" Copy character to register.
nmap <silent><buffer> + <"+yl:echo 'Yanked to +:' @+<CR>
nmap <silent><buffer> * <"*yl:echo 'Yanked to *:' @*<CR>
" Put.
nmap <silent><buffer> p <yl<C-w>wp<C-w>w
" Put and go.
nmap <silent><buffer> P <yl<C-w>wp
" Append and edit.
nmap <silent><buffer> A <yl<C-w>wpa
nmap <silent><buffer> a A
" Append and edit before.
nmap <silent><buffer> I <yl<C-w>wpi
nmap <silent><buffer> i I
" Yank and go.
nmap <silent><buffer> yy <yl<C-w>w
nmap <silent><buffer> yc <$F<Tab>yb<C-w>w
nmap <silent><buffer> yn <$T<Tab>y$<C-w>w
nmap <silent><buffer> Y yy
" Go.
nmap <silent><buffer> <Tab> <C-w>w
" Show TOC.
nmap <silent><buffer> gO :<C-u>call <SID>show_toc()<CR>
