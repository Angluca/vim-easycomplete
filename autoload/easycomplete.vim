" File:         easycomplete.vim
" Author:       @jayli <https://github.com/jayli/>
" Description:  整合了字典、代码展开和语法补全的提示插件
"
"               更多信息：
"                   <https://github.com/jayli/vim-easycomplete>

" 插件初始化入口
function! easycomplete#Enable()
  if exists("g:easy_complete_loaded") && g:easy_complete_loaded == 1
    return
  endif

  let g:easy_complete_loaded = 1
  " VI 兼容模式，连续输入时的popup兼容性好
  set cpoptions+=B
  " completeopt 需要设置成 menuonea，一个展示项也弹出菜单
  set completeopt-=menu
  set completeopt+=menuone
  " 这个是非必要设置，通常用来表示可以为所有匹配项插入通用前缀符，这样就可以
  " 为不同匹配项设置特定的标识，这个插件不需要这么复杂的设置。同时，设置
  " longest 为贪婪匹配，这里不需要
  set completeopt-=longest
  " noselect 可配可不配
  set completeopt-=noselect
  " <C-X><C-U><C-N> 时的函数回调
  let &completefunc = 'easycomplete#CompleteFunc'
  " let &completefunc = 'tsuquyomi#complete'
  " 插入模式下的回车事件监听
  inoremap <expr> <CR> TypeEnterWithPUM()
  " 插入模式下 Tab 和 Shift-Tab 的监听
  " inoremap <Tab> <C-R>=CleverTab()<CR>
  " inoremap <S-Tab> <C-R>=CleverShiftTab()<CR>
  inoremap <silent> <Plug>EasyCompTabTrigger  <C-R>=easycomplete#CleverTab()<CR>
  inoremap <silent> <Plug>EasyCompShiftTabTrigger  <C-R>=easycomplete#CleverShiftTab()<CR>

  " 配置弹框样式，支持三种，dark,light 和 rider
  if !exists("g:pmenu_scheme")
    let g:pmenu_scheme = "None"
  endif

  call s:SetPmenuScheme(g:pmenu_scheme)

  " :TsuquyomiOpen 命令启动 tsserver, 这个过程很耗时
  " 放到最后启动，避免影响vim打开速度
  let g:tsuquyomi_is_available = 1
  " autocmd! BufEnter * call tsuquyomi#config#initBuffer({ 'pattern': '*.js,*.jsx,*.ts' })
  call tsuquyomi#config#initBuffer({ 'pattern': '*.js,*.jsx,*.ts' })

  if exists("g:easycomplete_typing_popup") && g:easycomplete_typing_popup == 1 &&
        \ index([
        \   'typescript','javascript',
        \   'javascript.jsx','go',
        \   'python','vim'
        \ ], s:GetCurrentFileType()) >= 0
    call s:BindingTypingCommand()
  endif
endfunction

function! s:GetCurrentFileType()
  " SourcePost 事件中 &filetype 为空，应当从 bufname 中获取
  let filename = fnameescape(fnamemodify(bufname('%'),':p'))
  let ext_part = substitute(filename,"^.\\+[\\.]","","g")
  let filetype_dict = {
        \ 'js':'javascript',
        \ 'ts':'typescript',
        \ 'jsx':'javascript.jsx',
        \ 'tsx':'javascript.jsx',
        \ 'py':'python',
        \ 'rb':'ruby',
        \ 'sh':'shell'
        \ }
  if index(['js','ts','jsx','tsx','py','rb','sh'], ext_part) >= 0
    return filetype_dict[ext_part]
  else
    return ext_part
  endif
endfunction

function! easycomplete#typing()
  if pumvisible()
    return ''
  endif
  let g:typing_key = strpart(getline('.'), col('.') - 2, 1)
  let typing_word = s:GetTypingWord()
  if strwidth(typing_word) >= 2 || strpart(getline('.'), col('.') - 3 , 1) == '.'
    return "\<C-X>\<C-U>\<C-P>"
  endif
  return ''
endfunction

function! s:GetTypingKey()
  if exists('g:typing_key') && g:typing_key != ""
    return g:typing_key
  endif
  return "\<Tab>"
endfunction

function! s:GetTypingWord()
  let start = col('.') - 1
  let line = getline('.')
  while start > 0 && line[start - 1] =~ '[a-zA-Z0-9_#]'
    let start = start - 1
  endwhile
  let word = strpart(line, start, col('.') - 1)
  return word
endfunction

function! s:BindingTypingCommand()
  let l:key_liststr = 'abcdefghijklmnopqrstuvwxyz'.
                    \ 'ABCDEFGHIJKLMNOPQRSTUVWXYZ/'
  let l:cursor = 0
  while l:cursor < strwidth(l:key_liststr)
    let key = l:key_liststr[l:cursor]
    exe 'inoremap <silent> <buffer> ' . key .  ' ' . key . '<C-R>=easycomplete#typing()<CR>'
    let l:cursor = l:cursor + 1
  endwhile
endfunction

" 菜单样式设置
function! s:SetPmenuScheme(scheme_name)
  " hi Pmenu      ctermfg=111 ctermbg=235
  " hi PmenuSel   ctermfg=255 ctermbg=238
  " hi PmenuSbar              ctermbg=235
  " hi PmenuThumb             ctermbg=234
  let l:scheme_config = {
        \   'dark':[[111, 235],[255, 238],[-1,  235],[-1,  234]],
        \   'light':[[234, 251],[255, 26],[-1,  251],[-1,  247]],
        \   'rider':[[249, 237],[231, 25],[-1,  237],[-1,  239]
        \   ]
        \ }
  if has_key(l:scheme_config, a:scheme_name)
    let sch = l:scheme_config[a:scheme_name]
    let hiPmenu =      ['hi','Pmenu',      'ctermfg='.sch[0][0], 'ctermbg='.sch[0][1]]
    let hiPmenuSel =   ['hi','PmenuSel',   'ctermfg='.sch[1][0], 'ctermbg='.sch[1][1]]
    let hiPmenuSbar =  ['hi','PmenuSbar',  '',                   'ctermbg='.sch[2][1]]
    let hiPmenuThumb = ['hi','PmenuThumb', '',                   'ctermbg='.sch[3][1]]
    execute join(hiPmenu, ' ')
    execute join(hiPmenuSel, ' ')
    execute join(hiPmenuSbar, ' ')
    execute join(hiPmenuThumb, ' ')
  endif
endfunction

" 根据 vim-snippets 整理出目前支持的语言种类和缩写
function! s:GetLangTypeRawStr(lang)
  return language_alias#GetLangTypeRawStr(a:lang)
endfunction

"CleverTab tab 自动补全逻辑
function! easycomplete#CleverTab()
  setlocal completeopt-=noinsert
  if pumvisible()
    return "\<C-N>"
  elseif exists("g:snipMate") && exists('b:snip_state')
    " 代码已经完成展开时，编辑代码占位符，用tab进行占位符之间的跳转
    let jump = b:snip_state.jump_stop(0)
    if type(jump) == 1 " 返回字符串
      " 等同于 return "\<C-R>=snipMate#TriggerSnippet()\<CR>"
      return jump
    endif
  elseif &filetype == "go" && strpart(getline('.'), col('.') - 2, 1) == "."
    " Hack for Golang
    " 唤醒easycomplete菜单
    setlocal completeopt+=noinsert
    return "\<C-X>\<C-U>"
  elseif getline('.')[0 : col('.')-1]  =~ '^\s*$' ||
        \ getline('.')[col('.')-2 : col('.')-1] =~ '^\s$' ||
        \ len(s:StringTrim(getline('.'))) == 0
    " 判断空行的三个条件
    "   如果整行是空行
    "   前一个字符是空格
    "   空行
    return "\<Tab>"
  elseif match(strpart(getline('.'), 0 ,col('.') - 1)[0:col('.')-1],
        \ "\\(\\w\\|\\/\\|\\.\\)$") < 0
    " 如果正在输入一个非字母，也不是'/'或'.'
    return "\<Tab>"
  elseif exists("g:snipMate")
    " let word = matchstr(getline('.'), '\S\+\%'.col('.').'c')
    " let list = snipMate#GetSnippetsForWordBelowCursor(word, 1)

    " 如果只匹配一个，也还是给出提示
    return "\<C-X>\<C-U>"
  else
    " 正常逻辑下都唤醒easycomplete菜单
    return "\<C-X>\<C-U>"
  endif
endfunction

" CleverShiftTab 逻辑判断，无补全菜单情况下输出<Tab>
" Shift-Tab 在插入模式下输出为 Tab，仅为我个人习惯
function! easycomplete#CleverShiftTab()
  return pumvisible()?"\<C-P>":"\<Tab>"
endfunction

" 回车事件的行为，如果补全浮窗内点击回车，要判断是否
" 插入 snipmete 展开后的代码，否则还是默认回车事件
function! TypeEnterWithPUM()
  " 如果浮窗存在且 snipMate 已安装
  if pumvisible() && exists("g:snipMate")
    " 得到当前光标处已匹配的单词
    let word = matchstr(getline('.'), '\S\+\%'.col('.').'c')
    " 根据单词查找 snippets 中的匹配项
    let list = snipMate#GetSnippetsForWordBelowCursor(word, 1)
    " 关闭浮窗

    " 1. 优先判断是否前缀可被匹配 && 是否完全匹配到 snippet
    if snipMate#CanBeTriggered() && !empty(list)
      call s:CloseCompletionMenu()
      call feedkeys( "\<Plug>snipMateNextOrTrigger" )
      return ""
    endif

    " 2. 如果安装了 jedi，回车补全单词
    if &filetype == "python" &&
          \ exists("g:jedi#auto_initialization") &&
          \ g:jedi#auto_initialization == 1
      return "\<C-Y>"
    endif
  endif
  if pumvisible()
    return "\<C-Y>"
  endif
  return "\<CR>"
endfunction

" 将 snippets 原始格式做简化，用作浮窗提示展示用
" 主要将原有格式里的占位符替换成单个单词，比如下面是原始串
" ${1:obj}.ajaxSend(function (${1:request, settings}) {
" 替换为=>
" obj.ajaxSend(function (request, settings) {
function! s:GetSnippetSimplified(snippet_str)
  let pfx_len = match(a:snippet_str,"${[0-9]:")
  if !empty(a:snippet_str) && pfx_len < 0
    return a:snippet_str
  endif

  let simplified_str = substitute(a:snippet_str,"\${[0-9]:\\(.\\{\-}\\)}","\\1", "g")
  return simplified_str
endfunction

" 插入模式下模拟按键点击
function! s:SendKeys( keys )
  call feedkeys( a:keys, 'in' )
endfunction

" 将Buff关键字和Snippets做合并
" keywords is List
" snippets is Dict
function! s:MixinBufKeywordAndSnippets(keywords,snippets)
  if empty(a:snippets) || len(a:snippets) == 0
    return a:keywords
  endif

  let snipabbr_list = []
  for [k,v] in items(a:snippets)
    let snip_obj  = s:GetSnip(v)
    let snip_body = s:MenuStringTrim(get(snip_obj,'snipbody'))
    let menu_kind = s:StringTrim(s:GetLangTypeRawStr(get(snip_obj,'langtype')))
    " kind 内以尖括号表示语言类型
    " let menu_kind = substitute(menu_kind,"\\[\\(\\w\\+\\)\\]","\<\\1\>","g")
    call add(snipabbr_list, {"word": k , "menu": snip_body, "kind": menu_kind})
  endfor

  call extend(snipabbr_list , a:keywords)
  return snipabbr_list
endfunction

" 从一个完整的SnipObject中得到Snippet最有用的两个信息
" 一个是snip原始代码片段，一个是语言类型
function! s:GetSnip(snipobj)
  let errmsg    = "[Unknown snippet]"
  let snip_body = ""
  let lang_type = ""

  if empty(a:snipobj)
    let snip_body = errmsg
  else
    let v = values(a:snipobj)
    let k = keys(a:snipobj)
    if !empty(v[0]) && !empty(k[0])
      let snip_body = v[0][0]
      let lang_type = split(k[0], "\\s")[0]
    else
      let snip_body = errmsg
    endif
  endif
  return {"snipbody":snip_body,"langtype":lang_type}
endfunction

" 相当于 trim，去掉首尾的空字符
function! s:StringTrim(str)
  if !empty(a:str)
    let a1 = substitute(a:str, "^\\s\\+\\(.\\{\-}\\)$","\\1","g")
    let a1 = substitute(a:str, "^\\(.\\{\-}\\)\\s\\+$","\\1","g")
    return a1
  endif
  return ""
endfunction

" 弹窗内需要展示的代码提示片段的 'Trim'
function! s:MenuStringTrim(localstr)
  let default_length = 28
  let simplifed_result = s:GetSnippetSimplified(a:localstr)

  if !empty(simplifed_result) && len(simplifed_result) > default_length
    let trim_str = simplifed_result[:default_length] . ".."
  else
    let trim_str = simplifed_result
  endif

  return split(trim_str,"[\n]")[0]
endfunction

" 如果 vim-snipmate 已经安装，用这个插件的方法取 snippets
function! g:GetSnippets(scopes, trigger) abort
  if exists("g:snipMate")
    return snipMate#GetSnippets(a:scopes, a:trigger)
  endif
  return {}
endfunction

" 读取缓冲区词表和字典词表，两者合并输出大词表
function! s:GetKeywords(base)
  let bufKeywordList        = s:GetBufKeywordsList()
  let wrappedBufKeywordList = s:GetWrappedBufKeywordList(bufKeywordList)
  return s:MenuArrayDistinct(extend(
        \       wrappedBufKeywordList,
        \       s:GetWrappedDictKeywordList()
        \   ),
        \   a:base)
endfunction

"popup 菜单内关键词去重，只做buff和dict里的keyword去重
"传入的 list 不应包含 snippet 缩写
"base 是要匹配的原始字符串
function! s:MenuArrayDistinct(menuList, base)
  if empty(a:menuList) || len(a:menuList) == 0
    return []
  endif

  let menulist_tmp = []
  for item in a:menuList
    call add(menulist_tmp, item.word)
  endfor

  let menulist_filter = uniq(filter(menulist_tmp,
        \ 'matchstrpos(v:val, "'.a:base.'")[1] == 0'))

  "[word1,word2,word3...]
  let menulist_assetlist = []
  "[{word:word1,kind..},{word:word2,kind..}..]
  let menulist_result = []

  for item in a:menuList
    let word = get(item, "word")
    if index(menulist_assetlist, word) >= 0
      continue
    elseif index(menulist_filter, word) >= 0
      call add(menulist_result,deepcopy(item))
      call add(menulist_assetlist, word)
    endif
  endfor

  return menulist_result
endfunction

" 获取当前所有 buff 内的关键词列表
function! s:GetBufKeywordsList()
  let tmpkeywords = []
  for buf in getbufinfo()
    let lines = getbufline(buf.bufnr, 1 ,"$")
    for line in lines
      call extend(tmpkeywords, split(line,'[^A-Za-z0-9_#]'))
    endfor
  endfor

  let keywordList = s:ArrayDistinct(tmpkeywords)
  let keywordFormedList = []
  for v in keywordList
    call add(keywordFormedList, v)
  endfor

  return keywordFormedList
endfunction

" 将 Buff 关键词简单列表转换为补全浮窗所需的列表格式
" 比如原始简单列表是 ['abc','def','efd'] ，输出为
" => [{"word":"abc","kind":"[ID]"},{"word":"def","kind":"[ID]"}...]
function! s:GetWrappedBufKeywordList(keywordList)
  if empty(a:keywordList) || len(a:keywordList) == 0
    return []
  endif

  let wrappedList = []
  for word_str in a:keywordList
    call add(wrappedList,{"word":word_str,"kind":"[ID]"})
  endfor
  return wrappedList
endfunction

" 将字典简单词表转换为补全浮窗所需的列表格式
" 比如字典原始列表为 ['abc','def'] ，输出为
" => [{"word":'abc',"kind":"[ID]","menu":"common.dict"}...]
function! s:GetWrappedDictKeywordList()
  if exists("b:globalDictKeywords")
    return b:globalDictKeywords
  endif
  let b:globalDictKeywords = []

  " 如果当前 Buff 所读取的字典目录存在
  if !empty(&dictionary)
    let dictsFiles   = split(&dictionary,",")
    let dictkeywords = []
    let dictFile = ""
    for onedict in dictsFiles
      try
        let lines = readfile(onedict)
      catch /.*/
        "echoe "关键词字典不存在!请删除该字典配置 ".
        "           \ "dictionary-=".onedict
        continue
      endtry

      " jayli
      if dictFile == ""
        let dictFile = substitute(onedict,"^.\\+[\\/]","","g")
        let dictFile = substitute(dictFile,".txt","","g")
      endif
      let filename         = dictFile
      let localdicts       = []
      let localWrappedList = []

      if empty(lines)
        continue
      endif

      for line in lines
        call extend(localdicts, split(line,'[^A-Za-z0-9_#]'))
      endfor

      let localdicts = s:ArrayDistinct(localdicts)

      for item in localdicts
        call add (dictkeywords, {
              \   "word" : item ,
              \   "kind" : "[ID]",
              \   "menu" : filename
              \ })
      endfor
    endfor

    let b:globalDictKeywords = dictkeywords
    return dictkeywords
  else
    return []
  endif
endfunction

" List 去重，类似 uniq，纯数字要去掉
function! s:ArrayDistinct( list )
  if empty(a:list)
    return []
  else
    let tmparray = []
    let uniqlist = uniq(a:list)
    for item in uniqlist
      if !empty(item) &&
            \ !str2nr(item) &&
            \ len(item) != 1
        call add(tmparray,item)
      endif
    endfor
    return tmparray
  endif
endfunction

" 关闭补全浮窗
function! s:CloseCompletionMenu()
  if pumvisible()
    call s:SendKeys( "\<ESC>a" )
  endif
endfunction

" 判断当前是否正在输入一个地址path
" base 原本想传入当前文件名字，实际上传不进来，这里也没用到
function! easycomplete#TypingAPath(findstart, base)
  " 这里不清楚为什么
  " 输入 ./a/b/c ，./a/b/  两者得到的prefx都为空
  " 前者应该得到 c
  " 这里只能临时将base透传进来表示文件名
  let line  = getline('.')
  let coln  = col('.') - 1
  let prefx = ' ' . line[0:coln - 1]

  " Hack: 第二次进来 getline('.')时把光标所在的字符吃掉了，原因不明
  " 所以这里临时存一下 line 的值
  if exists('l:tmp_line_str') && a:findstart == 1
    let l:tmp_line_str = line
  elseif exists('l:tmp_line_str') && a:findstart == 0
    let line = l:tmp_line_str
    unlet l:tmp_line_str
  endif

  " 需要注意，参照上一个注释，fpath和spath只是path，没有filename
  " 从正在输入的一整行字符(行首到光标)中匹配出一个path出来
  " TODO 正则不严格，需要优化，下面这几个情况匹配要正确
  "   \ a <Tab>  => done
  "   \<Tab> => done
  "   xxxss \ xxxss<Tab> => done
  "   "/<tab>" => 不起作用, fixed at 2019-09-28
  let fpath = matchstr(prefx,"\\([\\(\\) \"'\\t\\[\\]\\{\\}]\\)\\@<=" .
        \   "\\([\\/\\.\\~]\\+[\\.\\/a-zA-Z0-9\\_\\- ]\\+\\|[\\.\\/]\\)")

  " 兼容单个 '/' 匹配的情况
  let spath = s:GetPathName( substitute(fpath,"^[\\.\\/].*\\/","./","g") )
  " 清除对 '\' 的路径识别
  let fpath = s:GetPathName(fpath)

  let pathDict                 = {}
  let pathDict.line            = line
  let pathDict.prefx           = prefx
  " fname 暂没用上，放这里备用
  let pathDict.fname           = s:GetFileName(prefx)
  let pathDict.fpath           = fpath " fullpath
  let pathDict.spath           = spath " shortpath
  let pathDict.full_path_start = coln - len(fpath) + 2
  if trim(pathDict.fname) == ''
    let pathDict.short_path_start = coln - len(spath) + 2
  else
    let pathDict.short_path_start = coln - len(pathDict.fname)
  endif

  " 排除掉输入注释的情况
  " 因为如果输入'//'紧跟<Tab>不应该出<C-X><C-U><C-N>出补全菜单
  if len(fpath) == 0 || match(prefx,"\\(\\/\\/\\|\\/\\*\\)") >= 0
    let pathDict.isPath = 0
  else
    let pathDict.isPath = 1
  endif

  return pathDict
endfunction

" 根据输入的 path 匹配出结果，返回的是一个List ['f1','f2','d1','d2']
" 查询条件实际上是用 base 来做的，typing_path 里无法包含当前敲入的filename
" ./ => 基于当前 bufpath 查询
" ../../ => 当前buf文件所在的目录向上追溯2次查询
" /a/b/c => 直接从根查询
" TODO ~/ 的支持
function! s:GetDirAndFiles(typing_path, base)
  let fpath   = a:typing_path.fpath
  let fname   = bufname('%')
  let bufpath = s:GetPathName(fname)

  if len(fpath) > 0 && fpath[0] == "."
    let path = simplify(bufpath . fpath)
  else
    let path = simplify(fpath)
  endif

  if a:base == ""
    " 查找目录下的文件和目录
    let result_list = systemlist('ls '. path .
          \ " 2>/dev/null")
  else
    " 这里没考虑Cygwin的情况
    let result_list = systemlist('ls '. s:GetPathName(path) .
          \ " 2>/dev/null")
    " 使用filter过滤，没有使用grep过滤，以便后续性能调优
    " TODO：当按<Del>键时，自动补全窗会跟随匹配，但无法做到忽略大小写
    " 只有首次点击<Tab>时能忽略大小写，
    " 应该在del跟随和tab时都忽略大小写才对
    let result_list = filter(result_list,
          \ 'tolower(v:val) =~ "^'. tolower(a:base) . '"')
  endif

  return s:GetWrappedFileAndDirsList(result_list, s:GetPathName(path))
endfunction

" 将某个目录下查找出的列表 List 的每项识别出目录和文件
" 并转换成补全浮窗所需的展示格式
function! s:GetWrappedFileAndDirsList(rlist, fpath)
  if len(a:rlist) == 0
    return []
  endif

  let result_with_kind = []

  for item in a:rlist
    let localfile = simplify(a:fpath . '/' . item)
    if isdirectory(localfile)
      call add(result_with_kind, {"word": item . "/", "kind" : "[Dir]"})
    else
      call add(result_with_kind, {"word": item , "kind" : "[File]"})
    endif
  endfor

  return result_with_kind
endfunction

" 从一个完整的 path 串中得到 FileName
" 输入的 Path 串可以带有文件名
function! s:GetFileName(path)
  let path  = simplify(a:path)
  let fname = matchstr(path,"\\([\\/]\\)\\@<=[^\\/]\\+$")
  return fname
endfunction

" 同上
function! s:GetPathName(path)
  let path =  simplify(a:path)
  let pathname = matchstr(path,"^.*\\/")
  return pathname
endfunction

" 根据词根返回语法匹配的结果，每个语言都需要单独处理
function! s:GetSyntaxCompletionResult(base) abort
  let syntax_complete = []
  " 处理 Javascript 语法匹配
  if s:IsTsSyntaxCompleteReady()
    call tsuquyomi#complete(0, a:base)
    " tsuquyomi#complete 这里先创建菜单再 complete_add 进去
    " 所以这里 ts_comp_result 总是空
    let syntax_complete = []
  endif
  " 处理 Go 语法匹配
  if s:IsGoSyntaxCompleteReady()
    if !exists("g:g_syntax_completions")
      let g:g_syntax_completions = [1,[]]
    endif
    let syntax_complete = g:g_syntax_completions[1]
  endif
  return syntax_complete
endfunction

function! s:IsGoSyntaxCompleteReady()
  if &filetype == "go" && exists("g:go_loaded_install")
    return 1
  else
    return 0
  endif
endfunction

function! s:IsTsSyntaxCompleteReady()
  if exists('g:loaded_tsuquyomi') && exists('g:tsuquyomi_is_available') &&
        \ g:loaded_tsuquyomi == 1 &&
        \ g:tsuquyomi_is_available == 1 &&
        \ &filetype =~ "^\\(typescript\\|javascript\\)"
    return 1
  else
    return 0
  endif
endfunction

" 补全菜单展示逻辑入口，光标跟随或者<Tab>键呼出
" 由于性能问题，推荐<Tab>键呼出
" 菜单格式说明（参照 YouCompleteMe 的菜单格式）
" 目前包括四类：当前缓冲区keywords，字典keywords，代码片段缩写，目录查找
" 其中目录查找和其他三类不混排（同样参照 YouCompleteMe的逻辑）
" 补全菜单格式样例 =>
"   Function    [JS]    javascript function PH (a,b)
"   fun         [ID]
"   Funny       [ID]
"   Function    [ID]    common.dict
"   function    [ID]    node.dict
"   ./Foo       [File]
"   ./b/        [Dir]
function! easycomplete#CompleteFunc( findstart, base )
  let typing_path = easycomplete#TypingAPath(a:findstart, a:base)

  " 如果正在敲入一个文件路径 ---- {{{
  if typing_path.isPath && a:findstart " 第一次调用求起始位置
    " 兼容这几种情况 =>
    " ./a/b/c/d
    " ../asdf./
    " /a/b/c/ds
    " /a/b/c/d/
    " ~/
    return typing_path.short_path_start
  elseif typing_path.isPath " 第二次调用返回匹配结果
    " 查找目录
    let result = s:GetDirAndFiles(typing_path, a:base)
    if len(result) == 0
      call s:CloseCompletionMenu()
      if strwidth(s:GetTypingKey()) != 1
        call s:SendKeys("\<Tab>")
      endif
      return 0
    endif
    return result
  endif
  " 文件路径处理结束         ---- }}}

  " 常规的关键字处理         ---- {{{
  if a:findstart
    " 第一次调用，定位当前关键字的起始位置
    let line = getline('.')
    let start = col('.') - 1
    " Hack: 如果是 '//' 后紧跟<Tab>，直接输出<Tab>
    if strpart(line, start - 2, 2) == '//'
      return start
    endif

    if a:findstart == 1
      " for go
      if s:IsGoSyntaxCompleteReady()
        execute "silent let g:g_syntax_completions = " . language#go#GocodeAutocomplete()
      else
        let g:g_syntax_completions = [1,[]]
      endif
    endif

    if s:IsTsSyntaxCompleteReady()
      call tsuquyomi#complete(1, a:base)
    endif

    " Hack: 如果是 "." 后面应该点出来上下文语义匹配的结果
    if strpart(line, start - 1, 1 ) == '.'
      return start
    endif

    while start > 0 && line[start - 1] =~ '[a-zA-Z0-9_#]'
      let start -= 1
    endwhile
    return start
  endif

  " 第二次调用，给出匹配列表
  if has_key(g:snipMate.scope_aliases, &filetype)
        \ && get(g:snipMate.scope_aliases, &filetype) != ""
    let t_filetypes = split(g:snipMate.scope_aliases[&filetype],",")
  else
    let t_filetypes = [&filetype]
  endif

  " 获得关键词匹配结果
  let all_result = []
  let keywords_result = s:GetKeywords(a:base)
  " 获得常用代码片段简写项
  let snippets_result = g:GetSnippets(t_filetypes, a:base)
  " 以上两者混合
  let all_result      = s:MixinBufKeywordAndSnippets(keywords_result, snippets_result)
  " 获得语法匹配结果
  let syntax_complete = s:GetSyntaxCompletionResult(a:base)

  " 这里主要是处理前缀是否为'.'，如果是则只返回语法结果，无语法结果就不做动
  " 作，否则返回全量结果
  let line = getline('.')
  let start = col('.') - 1
  if len(a:base) == 0 && s:IsTsSyntaxCompleteReady()
    " 如果是点
    " TSServer 自动语法匹配
    let all_result = []
  elseif len(a:base) > 0 &&
        \ strpart(getline('.'), start-1 , 1) == '.' &&
        \ s:IsTsSyntaxCompleteReady()
    let all_result = []
    " 如果是点后字符匹配
    " TSServer 自动语法匹配
  elseif len(a:base) > 0 && match(strpart(getline('.'), 0 ,start)[0:start],"\\.\\w\\+$") > 0 &&
        \ s:IsTsSyntaxCompleteReady()
    let all_result = []
    " TSServer 自动语法匹配
  elseif len(a:base) == 0 && len(syntax_complete) > 0
    " 直接输入'.'后匹配
    let all_result = syntax_complete
  elseif len(a:base) > 0 && strpart(line, start - 1, 1) == '.'
    " 点后一个字符匹配(最常用的形式避免正则，速度更快一些)
    let all_result = syntax_complete
  elseif len(a:base) > 0 && match(strpart(getline('.'), 0 ,start)[0:start],"\\.\\w\\+$") > 0
    " 点后两个或两个以上字符，用正则匹配
    let all_result = syntax_complete
  elseif len(a:base) == 0 && len(syntax_complete) == 0
    let all_result = []
  else
    let all_result = syntax_complete + all_result
  endif

  " TODO 如果匹配不出任何结果，还是执行原有按键，我这里用tab，实际上还
  " 有一种选择，暂停行为，给出match不成功的提示，我建议要强化insert输入
  " tab 用 s-tab (我个人习惯)，而不是一味求全 tab 的容错，容错不报错也
  " 是一个问题，Shift-Tab 被有些人用来设定为Tab回退，可能会被用不习惯，
  " 这里需要使用者注意
  if len(all_result) == 0 && !s:IsTsSyntaxCompleteReady()
    call s:CloseCompletionMenu()
    if strwidth(s:GetTypingKey()) != 1
      call s:SendKeys("\<Tab>")
    endif
    return 0
  endif

  return all_result
  " 常规的关键字处理         ---- }}}
endfunction

function! s:log(msg)
  echohl MoreMsg
  echom '>>> '. string(a:msg)
  echohl NONE
endfunction

