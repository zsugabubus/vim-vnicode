if get(b:, 'current_syntax', '') ==# 'vnicode-nameslist'
  finish
endif

syn match VnicodeName /\v\t[-0-9A-Z ]+$/
syn match VnicodeNumber /\v<[0-9A-F]{4,}>/
syn match VnicodeSection /@\+\t.*/
syn match VnicodeComment /^@@*[^@].*/ keepend
syn match VnicodeComment /^;.*/ keepend
syn match VnicodeNameAlias /^\t\zs= .*/ keepend
syn match VnicodeComment   /^\t\zs\* .*/ keepend
syn match VnicodeReference /^\t\zsx .*/ keepend

if !exists('b:current_syntax')
  let b:current_syntax = 'vnicode-nameslist'
endif
