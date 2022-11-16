let s:G8_FORMAT = {
\  '': '%02x ',
\  'lua': '%d ',
\}

let s:G8_REG_FORMAT = {
\  '': '\x%02x',
\  'lua': '\%d',
\}

function! vnicode#_read_file(file) abort
	let path = g:vnicode_datadir . '/' . a:file
	try
		setlocal nobuflisted bufhidden=hide buftype=nofile noswapfile undolevels=-1
		silent execute '0read' fnameescape(glob(path . '*', 1, 1)[0])
		setlocal readonly nomodifiable
		filetype detect
	catch
		echohl Error
		echom printf('vnicode: %s is missing. See :h vnicode-datafiles.', a:file)
		echohl Normal
	endtry
endfunction

function! s:get_data(file, codepoint) abort
	execute bufnr('vnicode://' . a:file, 1) . 'buffer'

	let pat = printf('^%04X;', a:codepoint)
	let lnum = searchpos(pat, 'wn')[0]
	return lnum == 0 ? [] : split(getline(lnum), ';', 1)
endfunction

function! s:echo_no_codepoints() abort
	echohl NonText
	echo '(nothing to show)'
	echohl Normal
endfunction

function! s:echo_codepoint(codepoint, unicode_data) abort
	let char = nr2char(a:codepoint)
	" Attept to show the character if not assigned so do not use "Cn" as
	" default.
	let general_category = get(a:unicode_data, 2, '')

	echohl Normal
	echon '< '
	if general_category[0] ==# 'C'
		echohl SpecialKey
		if a:codepoint < 0x20
			echon printf('^%s', nr2char(char2nr('@') + a:codepoint))
		else
			echon printf('<%x>', a:codepoint)
		endif
		echohl Normal
	elseif general_category[0] ==# 'M'
		let base = "\u25cc" " DOTTED CIRCLE
		echon base.char
	else
		echon char
	endif
	echon ' >'
endfunction

function! s:args2codepoints(...) abort
	" If no arguments given, use the character under the cursor...
	if a:0 ==# 0
		if mode() ==# 'n'
			let codepoints = matchstr(getline('.')[col('.') - 1:], '.')
		else
			let saved = @"
			silent! normal! y
			let codepoints = @"
			let @" = saved
		endif
	else
		let num = matchstr(a:1, '\v^\\?0o?\zs\o+$')
		if !empty(num)
			let codepoints = str2nr(num, 8)
		else
			let num = matchstr(a:1, '\v^\d+$')
			if !empty(num)
				let codepoints = str2nr(num, 10)
			else
				let num = matchstr(a:1, '\v^%([uU]\+?|[0\\][xX])?\zs\x+$')
				if !empty(num)
					let codepoints = str2nr(num, 16)
				else
					let codepoints = matchstr(a:1, "\\v^(['\"])?\\zs.*\\ze\\1$")
				endif
			endif
		endif
	endif

	if type(codepoints) ==# v:t_number
		return [codepoints]
	elseif type(codepoints) ==# v:t_string
		return str2list(codepoints)
	else
		return codepoints
	endif
endfunction

function! s:squeeze_codepoints(codepoints) abort
	let ret = []
	let last = -1
	for codepoint in a:codepoints
		if codepoint !=# last
			let last = codepoint
			let ret += [codepoint]
		endif
	endfor
	return ret
endfunction

function! vnicode#g8(...) abort
	let reg_format = v:register ==# '"'
		\ ? ''
		\ : get(s:G8_REG_FORMAT, &filetype, s:G8_REG_FORMAT[''])
	let format = get(s:G8_FORMAT, &filetype, s:G8_FORMAT[''])

	let codepoints = call('s:args2codepoints', a:000)
	if empty(reg_format)
		let codepoints = s:squeeze_codepoints(codepoints)
	endif
	let reg = ''

	if empty(codepoints)
		call s:echo_no_codepoints()
	endif

	try
		-tabnew
		setlocal bufhidden=wipe

		for codepoint in codepoints
			let unicode_data = s:get_data('UnicodeData.txt', codepoint)
			call s:echo_codepoint(codepoint, unicode_data)

			if codepoint <= 0x7f
				let bytes = [codepoint]
			else
				let bytes = []
				let head = 0x1f
				while 1
					let bytes += [or(0x80, and(codepoint, 0x3f))]
					let codepoint /= 0x40
					if codepoint <= head
						break
					endif
					let head /= 2
				endwhile
				let head = or(xor(head * 2, 0xfe), codepoint)
				let bytes += [head]
			endif

			call reverse(bytes)

			if !empty(reg_format)
				let reg .= len(bytes) ==# 1 ? nr2char(codepoint) : call('printf', [repeat(reg_format, len(bytes))] + bytes)
			endif

			echohl VnicodeNumber
			echon call('printf', [repeat(format, len(bytes))] + bytes)
			echohl Normal
		endfor
	finally
		tabclose
	endtry

	if !empty(reg_format)
		call setreg(v:register, reg)
	endif
endfunction

function! vnicode#ga(...) abort
	let codepoints = call('s:args2codepoints', a:000)
	let codepoints = s:squeeze_codepoints(codepoints)

	if empty(codepoints)
		call s:echo_no_codepoints()
	endif

	try
		-tabnew
		setlocal bufhidden=wipe

		let comma = 0
		for codepoint in codepoints
			if comma
				echon ','
			endif
			let comma = 1

			let unicode_data = s:get_data('UnicodeData.txt', codepoint)
			let character_name = get(unicode_data, 1, 'NO NAME')
			let general_category = get(unicode_data, 2, 'Cn')

			let name_alias = s:get_data('NameAliases.txt', codepoint)
			let alias_type = get(name_alias, 2, '')
			if alias_type ==# 'alternate'
				let character_name = printf('%s/%s', name_alias[1], character_name)
			elseif alias_type ==# 'abbreviation'
				let character_name = printf('%s (%s)', name_alias[1], character_name)
			elseif alias_type !=# ''
				let character_name = name_alias[1]
			endif

			call s:echo_codepoint(codepoint, unicode_data)

			" Decimal
			echohl VnicodeNumber
			echon printf('%d', codepoint)
			echohl Normal
			echon ', '

			" Hexadecimal
			echohl VnicodeNumber
			" Just because fucked syntax highlight.
			echon printf('U+%0*X', float2nr(pow(2, ceil(log(log(codepoint) / log(16))
			\ / log(2)))), codepoint)
			echohl Normal
			echon ', '

			" Octal
			echohl cOctalZero
			echon 0
			echohl VnicodeNumber
			echon printf('%o', codepoint)
			echohl Normal
			echon ' '

			echohl VnicodeGeneralCategory
			echon general_category . '/'

			echohl VnicodeName
			echon character_name
			echohl Normal
		endfor
	finally
		tabclose
	endtry
endfunction
