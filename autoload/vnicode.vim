" Author: zsugabubus
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

function s:echochar(charnr) abort
	let char = nr2char(a:charnr)

	echohl Normal
	echon printf('< ')
	if a:charnr < char2nr(' ')
		echohl SpecialKey
		echon printf('^%s', nr2char(a:charnr + char2nr('@')))
		echohl Normal
	else
		" Show zerowidth characters on a "Dotted Circle"
		let zerowidth = strwidth(char) ==# strwidth("\u25cc".char)
		echon printf('%s', (zerowidth ? "\u25cc" : '').char)
	endif
	echon printf(' >')
endfunction

function! s:args2charnrs(...) abort
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

	return chars
endfunction

let s:G8_HEX_FORMAT = ['%02x ', '%02x %02x ', '%02x %02x %02x ', '%02x %02x %02x %02x ']
let s:G8_DEC_FORMAT = ['%d', '%d %d', '%d %d %d', '%d %d %d %d']
let s:G8_DEC_FILETYPES = ['lua']

function! vnicode#g8(...) abort
	let chars = call('s:args2charnrs', a:000)

	while !empty(chars)
		let charnr = chars[0]

		call s:echochar(charnr)

		" Tail bytes.
		let t2 = or(0x80, and(charnr / 64 / 64, 0x3f))
		let t1 = or(0x80, and(charnr / 64, 0x3f))
		let t0 = or(0x80, and(charnr, 0x3f))

		echohl VnicodeNumber

		let format = 0 <=# index(s:G8_DEC_FILETYPES, &filetype) ? s:G8_DEC_FORMAT : s:G8_HEX_FORMAT

		if charnr <= 0x7f
			echon printf(format[0], charnr)
		elseif charnr <= 0x07ff
			let h = or(0xc0, charnr / 64)
			echon printf(format[1], h, t0)
		elseif charnr <= 0xffff
			let h = or(0xe0, charnr / 64 / 64)
			echon printf(format[2], h, t1, t0)
		elseif charnr <= 0x10ffff
			let h = or(0xf0, charnr / 64 / 64 / 64)
			echon printf(format[3], h, t2, t1, t0)
		else
			echon printf('%08x ', charnr)
		endif
		echohl Normal

		unlet chars[0]
	endwhile
endfunction

function! vnicode#ga(...) abort
	let chars = call('s:args2charnrs', a:000)

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
