if exists('loaded_vnicode')
	finish
endif
let loaded_vnicode = 1

let s:vnicode_rootdir = fnamemodify(expand('<sfile>'), ':p:h:h')
if !exists('vnicode_datadir')
	let vnicode_datadir = s:vnicode_rootdir.'/data'
endif

" :ascii
command! -nargs=? Unicode call vnicode#ga(<f-args>)
command! -nargs=? UTF8 call vnicode#g8(<f-args>)

silent! nnoremap <silent><unique> ga :Unicode<CR>
silent! nnoremap <silent><unique> g8 :UTF8<CR>
if has('nvim')
	silent! xnoremap <silent><unique> ga <Cmd>Unicode<CR>
	silent! xnoremap <silent><unique> g8 <Cmd>UTF8<CR>
endif
silent! nnoremap <expr><silent><unique> gA ':sbuffer '.bufnr('vnicode://NamesList.txt', 1).'<CR>:redraw<CR>:Codepoint<CR>'

command! -nargs=? VnicodeUpdate execute printf(
	\  '!make -C %s datadir=%s %s',
	\  shellescape(s:vnicode_rootdir),
	\  shellescape(vnicode_datadir),
	\  <q-args>
	\)

augroup vnicode
	autocmd! BufReadCmd vnicode://* ++nested call vnicode#_read_file(matchstr(expand('<afile>'), '\m://\zs.*'))
augroup END

" Set up needed highlights.
hi def link VnicodeComment Comment
hi def link VnicodeCharComment VnicodeComment
hi def link VnicodeReference VnicodeComment
hi def link VnicodeSection Title
hi def link VnicodeNumber Number
hi def link VnicodeName Identifier
hi def link VnicodeNameAlias Normal
hi def link VnicodeGeneralCategory Normal
