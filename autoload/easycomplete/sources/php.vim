if exists('g:easycomplete_php')
  finish
endif
let g:easycomplete_php = 1

function! easycomplete#sources#php#constructor(opt, ctx)
  call easycomplete#RegisterLspServer(a:opt, {
      \ 'name': 'intelephense',
      \ 'cmd': {server_info->[easycomplete#installer#GetCommand(a:opt['name']), '--stdio']},
      \ 'root_uri':{server_info -> "file://" . fnamemodify(expand('%'), ':p:h')},
      \ 'config': {'refresh_pattern': '\(\$[a-zA-Z0-9_:]*\|\k\+\)$'},
      \ 'allowlist': ['php'],
      \ })
endfunction

function! easycomplete#sources#php#completor(opt, ctx) abort
  return easycomplete#DoLspComplete(a:opt, a:ctx)
endfunction

function! easycomplete#sources#php#GotoDefinition(...)
  return easycomplete#DoLspDefinition(["php"])
endfunction

function! easycomplete#sources#php#filter(matches)
  let ctx = easycomplete#context()
  let matches = a:matches
  let matches = map(copy(matches), function("easycomplete#util#FunctionSurffixMap"))
  return matches
endfunction
