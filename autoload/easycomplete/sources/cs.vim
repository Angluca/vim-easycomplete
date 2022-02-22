if exists('g:easycomplete_cs')
  finish
endif
let g:easycomplete_cs = 1

function! easycomplete#sources#cs#constructor(opt, ctx)
  call easycomplete#RegisterLspServer(a:opt, {
      \ 'name': 'omnisharp-lsp',
      \ 'cmd': [easycomplete#installer#GetCommand(a:opt['name']), '-lsp'],
      \ 'root_uri':{server_info->easycomplete#util#GetDefaultRootUri()},
      \ 'allowlist': ['cs'],
      \ 'config': {},
      \ })
endfunction

function! easycomplete#sources#cs#completor(opt, ctx) abort
  return easycomplete#DoLspComplete(a:opt, a:ctx)
endfunction

function! easycomplete#sources#cs#GotoDefinition(...)
  return easycomplete#DoLspDefinition(["cs"])
endfunction

