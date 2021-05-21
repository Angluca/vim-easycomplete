" Installer for every lsp server

let s:installer_dir = expand('<sfile>:h:h') . '/easycomplete/installer'
let s:root_dir = expand('<sfile>:h:h')
let s:data_dir = expand('~/.config/vim-easycomplete')
" LSP Server 安装目录，目录结构：
" ~/.config/vim-easycomplete/
"     └─ servers/
"         ├─ sh/                           <------  plugin name
"         │   ├─ bash-language-server      <------  command
"         │   ├─ package.json
"         │   └─ node_modules/
"         └─ css/                          <------  plugin name
"             ├─ css-language-server       <------  command
"             ...
let s:lsp_servers_dir = s:data_dir . '/servers'

function! easycomplete#installer#InstallerDir() abort
  return s:installer_dir
endfunction

function! easycomplete#installer#LspServerDir() abort
  return s:lsp_servers_dir
endfunction

function! easycomplete#installer#GetCommand(name)
  let opt = easycomplete#GetOptions(a:name)
  if empty(opt)
    call easycomplete#util#info('error', 'plugin options is null')
    return ''
  endif
  let cmd = opt['command']
  if executable(cmd)
    return cmd
  endif
  let local_cmd = easycomplete#installer#LspServerDir() . '/' . a:name . '/' . cmd
  if executable(local_cmd)
    return local_cmd
  endif
  return ''
endfunction

function! easycomplete#installer#install(name) abort
  let opt = easycomplete#GetOptions(a:name)
  let l:install_script = easycomplete#installer#InstallerDir() . '/' . a:name . '.sh'
  let l:lsp_server_dir = easycomplete#installer#LspServerDir() . '/' . a:name

  " prepare auth of exec script
  call setfperm(l:install_script, 'rwxr-xr-x')
  call setfperm(easycomplete#installer#InstallerDir() . '/npm_install.sh', 'rwxr-xr-x')

  if !filereadable(l:install_script)
    call easycomplete#util#info('Error,', 'Install script is not exist.')
    return
  endif

  if confirm(printf('Install %s lsp server?', a:name), "&Yes\n&Cancel") !=# 1
    return
  endif

  if isdirectory(l:lsp_server_dir)
    call easycomplete#util#info('Uninstalling', a:name)
    call delete(l:lsp_server_dir, 'rf')
  endif

  call mkdir(l:lsp_server_dir, 'p')
  call easycomplete#util#info('Installing', a:name, 'lsp server ...')

  if has('nvim')
    split new
    call termopen(l:install_script, {'cwd': l:lsp_server_dir, 'on_exit': function('s:InstallServerPost', [a:name])})
    startinsert
  else
    let l:bufnr = term_start(l:install_script, {'cwd': l:lsp_server_dir})
    let l:job = term_getjob(l:bufnr)
    if l:job != v:null
      call job_setoptions(l:job, {'exit_cb': function('s:InstallServerPost', [a:name])})
    endif
  endif
endfunction

" neovim passes third argument as 'exit' while vim passes only 2 arguments
function! s:InstallServerPost(command, job, code, ...) abort
  if a:code != 0
    return
  endif
  if s:executable(a:command)
    call easycomplete#Enable()
  endif
  call easycomplete#util#info('Done!', a:command, 'lsp server installed successfully!')
endfunction

function! s:executable(cmd) abort
  if executable(a:cmd)
    return 1
  endif
  let plug_name = easycomplete#GetPlugNameByCommand(a:cmd)
  if empty(plug_name) | return 0 | endif
  let local_cmd = easycomplete#installer#LspServerDir() . '/' . plug_name . '/' . a:cmd
  if executable(local_cmd)
    return 1
  endif
  return 0
endfunction

function! easycomplete#installer#executable(...)
  return call("s:executable", a:000)
endfunction

function! s:log(...)
  return call('easycomplete#util#log', a:000)
endfunction

function! s:console(...)
  return call('easycomplete#log#log', a:000)
endfunction
