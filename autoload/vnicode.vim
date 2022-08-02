function! vnicode#_read_file(file) abort
	let path = g:vnicode_datadir.'/'.a:file
	try
		setlocal nobuflisted bufhidden=hide buftype=nofile noswapfile undolevels=-1
		execute '0read' fnameescape(glob(path.'*', 1, 1)[0])
		setlocal readonly nomodifiable
		filetype detect
	catch
		echohl Error
		echom printf('vnicode: %s is missing. See :h vnicode-datafiles.', a:file)
		echohl Normal
	endtry
endfunction

function! s:echochar(charnr) abort
	let char = nr2char(a:charnr)

	echohl Normal
	echon '< '
	if a:charnr < char2nr(' ')
		echohl SpecialKey
		echon printf('^%s', nr2char(a:charnr + char2nr('@')))
		echohl Normal
	else
		" Show zerowidth characters on a "Dotted Circle"
		let zerowidth = strwidth(char) ==# strwidth("\u25cc".char)
		echon (zerowidth ? "\u25cc" : '').char
	endif
	echon ' >'
endfunction

function! s:args2charnrs(for_display, ...) abort
	" If no arguments given, use the character under the cursor...
	if a:0 ==# 0
		if mode() ==# 'n'
			let chars = matchstr(getline('.')[col('.') - 1:], '.')
		else
			let saved = @"
			silent! normal! y
			let chars = @"
			let @" = saved
		endif
	else
		let num = matchstr(a:1, '\v^\\?0o?\zs\o+$')
		if !empty(num)
			let chars = str2nr(num, 8)
		else
			let num = matchstr(a:1, '\v^\d+$')
			if !empty(num)
				let chars = str2nr(num, 10)
			else
				let num = matchstr(a:1, '\v^%([uU]\+?|[0\\][xX])?\zs\x+$')
				if !empty(num)
					let chars = str2nr(num, 16)
				else
					let chars = matchstr(a:1, "\\v^(['\"])?\\zs.*\\ze\\1$")
				endif
			endif
		endif
	endif

	" Get list of codepoints.
	if type(chars) ==# v:t_number
		let chars = [chars]
	elseif type(chars) ==# v:t_string
		let chars = str2list(chars)
	endif

	if a:for_display
		" For some unknown reasons [ \t\n]{2,} matches combining characters after
		" but "  +|..." is not. At the end, it seems better to operate on bytes so
		" we can clean inputs coming from other sources too.
		let prev_char = 0
		function! s:charfilter(i, char) abort closure
			if a:char ==# prev_char
				return 0
			endif
			let prev_char = a:char
			return 1
		endfunction
		call filter(chars, function('s:charfilter'))
	endif

	return chars
endfunction

let s:G8_FORMAT = {
	\  '': '%02x ',
	\  'lua': '%d ',
	\}

let s:G8_REG_FORMAT = {
	\  '': '\x%02x',
	\  'lua': '\%d',
	\}

function! vnicode#g8(...) abort
	let reg = ''
	let reg_format = v:register ==# '"'
		\ ? ''
		\ : get(s:G8_REG_FORMAT, &filetype, s:G8_REG_FORMAT[''])

	let chars = call('s:args2charnrs', [empty(reg_format)] + a:000)

	let format = get(s:G8_FORMAT, &filetype, s:G8_FORMAT[''])

	while !empty(chars)
		let charnr = chars[0]

		call s:echochar(charnr)

		if charnr <= 0x7f
			let bytes = [charnr]
		else
			let bytes = []
			let head = 0x1f
			while 1
				let bytes += [or(0x80, and(charnr, 0x3f))]
				let charnr /= 64
				if charnr <= head
					break
				endif
				let head /= 2
			endwhile
			let bytes += [or(xor(head * 2, 254), charnr)]
		endif

		call reverse(bytes)

		if !empty(reg_format)
			let reg .= len(bytes) ==# 1 ? nr2char(charnr) : call('printf', [repeat(reg_format, len(bytes))] + bytes)
		endif

		echohl VnicodeNumber
		echon call('printf', [repeat(format, len(bytes))] + bytes)
		echohl Normal

		unlet chars[0]
	endwhile

	if !empty(reg_format)
		call setreg(v:register, reg)
	endif
endfunction

function! vnicode#ga(...) abort
	let chars = call('s:args2charnrs', [1] + a:000)

	if empty(chars)
		echohl NonText
		echo '(nothing to show)'
		echohl Normal
		return
	endif

	let databuf = bufnr('vnicode://UnicodeData.txt', 1)
	let aliasbuf = bufnr('vnicode://NameAliases.txt', 1)

	try
		let tabnr = tabpagenr()
		" Open our UnicodeData.txt in the ``background''.
		execute 'tab' databuf.'sbuffer'

		" Now show every codepoint one-by-one.
		while 1
			let charnr = chars[0]
			let hexnr = printf('^%04X;', charnr)

			execute aliasbuf.'buffer'
			let lnum = searchpos(hexnr, 'wn')[0]
			if lnum != 0
				" Unconditionally use the first name.
				let charname = split(getline(lnum), ';', 1)[1]
			else

				execute databuf.'buffer'
				let lnum = searchpos(hexnr, 'wn')[0]
				if lnum != 0
					" https://www.unicode.org/reports/tr44/#UnicodeData.txt
					let charname = split(getline(lnum), ';', 1)[1]
				else
					let charname = ''
				endif

			endif

			call s:echochar(charnr)

			" Decimal
			echohl VnicodeNumber
			echon printf('%d', charnr)
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
			echon ' '

			echohl VnicodeName
			echon charname
			echohl Normal

			unlet chars[0]
			if empty(chars)
				break
			endif

			echon ','
		endwhile
	finally
		tabclose
		execute tabnr.'tabnext'
	endtry
endfunction
