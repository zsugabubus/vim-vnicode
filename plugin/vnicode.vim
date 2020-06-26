" Author: zsugabubus
if !exists('vnicode_datadir')
	let vnicode_datadir = fnamemodify(expand('<sfile>'), ':p:h:h').'/data'
endif

" :ascii
command! -nargs=? Unicode call vnicode#show(<f-args>)

silent! nnoremap <silent><unique> ga :Unicode<CR>
silent! nnoremap <expr><silent><unique> gA ':sbuffer '.bufnr('vnicode://NamesList.txt', 1).'<CR>:redraw<CR>:Codepoint<CR>'

augroup vnicode
	autocmd! BufReadCmd vnicode://*
	\ setlocal nobuflisted bufhidden=hide buftype=nofile noswapfile undolevels=-1|
	\ call vnicode#_read_file(matchstr(expand('<afile>'), '\m://\zs.*'))
augroup END

" Set up needed highlights.
hi def link VnicodeComment Comment
hi def link VnicodeCharComment VnicodeComment
hi def link VnicodeReference VnicodeComment
hi def link VnicodeSection Title
hi def link VnicodeNumber Number
hi def link VnicodeName Identifier
hi def link VnicodeNameAlias Normal
