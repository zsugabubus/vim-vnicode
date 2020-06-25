" Author: zsugabubus
function! vnicode#_read_file(file) abort
	let path = g:vnicode_datadir.'/'.a:file
	if !filereadable(path)
		try
			echohl Question
			" NOTE: getchar() cannot be used because echo does not show up for some
			" reason.
			let answer = input(printf('vnicode: %s is missing. Download now into %s?[Y/n] ', a:file, fnamemodify(g:vnicode_datadir, ':~')))
		finally
			echohl Normal
		endtry
		if answer =~? '\v^|y$'
			call mkdir(g:vnicode_datadir, 'p')

			let jobid = jobstart(['curl', '-sgLo', g:vnicode_datadir.'/'.a:file, 'https://www.unicode.org/Public/UCD/latest/ucd/'.a:file], {
			\ 'file': a:file,
			\ 'stderr_buffered': 1,
			\	'on_stderr': function('s:on_event'),
			\	'on_exit': function('s:on_event')
			\})
			if jobid ># 0
				echo printf('Downloading %s...', a:file)
			else
				throw 'vnicode: failed to start download job'
			endif
			return
		endif
	endif
	execute '0read' fnameescape(path)
	setlocal readonly nomodifiable
	filetype detect
endfunction

function s:on_event(job_id, data, event) dict abort
	if a:event ==# 'exit'
		if a:data ==# 0
			if self.file ==# 'UnicodeData.txt'
				" Purge remains of previous data file.
				silent! execute bufnr('vnicode://'.self.file) 'bwipeout'
				call vnicode#show()
			elseif self.file ==# 'NamesList.txt'
				try
					execute bufnr('vnicode://'.self.file) 'buffer'
					call vnicode#_read_file(self.file)
				catch
					" Buffer has been deleted since.
				endtry
			endif
		else
			echoe printf('Download terminated with exit status %d', data)
		endif
	elseif a:event ==# 'stderr' && !empty(a:data[0])
		echoe 'vnicode: '.join(a:data, '\n')
	endif
endfunction

function! vnicode#show() abort
	let currbuf = bufnr()
	let view = winsaveview()

	try
		let ft = &filetype
		let buf = bufnr('vnicode://UnicodeData.txt', 1)
		let charnr = char2nr(getline('.')[col('.') - 1:])

		execute buf.'buffer'

		let lnum = searchpos(printf('^%04X;', charnr), 'w')[0]
		if lnum != 0
			let chardata = split(getline(lnum), ';', 1)
			let charname = chardata[1].(!empty(chardata[10]) ? '/'.chardata[10] : '')
		else
			let charname = ''
		endif

		if charnr < char2nr(' ')
			echohl SpecialKey
			echon printf('<^%s> ', nr2char(charnr + char2nr('@')))
		else
			echohl Normal
			echon printf('<%s> ', nr2char(charnr))
		endif

		" Decimal
		echohl VnicodeNumber
		echon printf('%3d', charnr)
		echohl Normal
		echon ', '

		" Hexadecimal
		echohl VnicodeNumber
		" Just because fucked syntax highlight.
		echon printf('U+%0*X', float2nr(pow(2, ceil(log(log(charnr) / log(16))
		\ / log(2)))), charnr)
		echohl Normal
		echon ', '

		" Octal
		echohl cOctalZero
		echon 0
		echohl VnicodeNumber
		echon printf('%o', charnr)
		echohl Normal
		echon '  '

		echohl VnicodeName
		echon charname
		echohl Number
	catch
		echom v:exception
		call getchar()
		normal! ga
	finally
		execute currbuf.'buffer'
		call winrestview(view)
	endtry
endfunction
