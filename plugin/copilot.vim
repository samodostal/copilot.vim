if exists('g:loaded_copilot')
  finish
endif
let g:loaded_copilot = 1
let g:copilot_echo_num_completions = 0

scriptencoding utf-8

command! -bang -nargs=? -range=-1 -complete=customlist,copilot#CommandComplete Copilot exe copilot#Command(<line1>, <count>, +"<range>", <bang>0, "<mods>", <q-args>)

if v:version < 800
  finish
endif

function! s:ColorScheme() abort
  if &t_Co == 256
    hi def CopilotSuggestion guifg=#808080 ctermfg=244
  else
    hi def CopilotSuggestion guifg=#808080 ctermfg=8
  endif
endfunction

function! s:MapTab() abort
  if get(g:, 'copilot_no_tab_map') || get(g:, 'copilot_no_maps')
    return
  endif
  let tab_map = maparg('<Tab>', 'i', 0, 1)
  if empty(tab_map)
    imap <script><silent><nowait><expr> <Tab> copilot#Accept()
  elseif tab_map.rhs !~# 'copilot'
    if tab_map.expr
      let tab_fallback = '{ -> ' . tab_map.rhs . ' }'
    else
      let tab_fallback = substitute(json_encode(tab_map.rhs), '<', '\\<', 'g')
    endif
    let tab_fallback = substitute(tab_fallback, '<SID>', '<SNR>' . get(tab_map, 'sid') . '_', 'g')
    if get(tab_map, 'noremap') || get(tab_map, 'script') || mapcheck('<Left>', 'i') || mapcheck('<Del>', 'i')
      exe 'imap <script><silent><nowait><expr> <Tab> copilot#Accept(' . tab_fallback . ')'
    else
      exe 'imap <silent><nowait><expr>         <Tab> copilot#Accept(' . tab_fallback . ')'
    endif
  endif
endfunction

function! s:Event(type) abort
  try
    call call('copilot#On' . a:type, [])
  catch
    call copilot#logger#Exception()
  endtry
endfunction

augroup github_copilot
  autocmd!
  autocmd InsertLeave          * call s:Event('InsertLeave')
  autocmd BufLeave             * if mode() =~# '^[iR]'|call s:Event('InsertLeave')|endif
  autocmd InsertEnter          * call s:Event('InsertEnter')
  autocmd BufEnter             * if mode() =~# '^[iR]'|call s:Event('InsertEnter')|endif
  autocmd CursorMovedI         * call s:Event('CursorMovedI')
  autocmd CompleteChanged      * call s:Event('CompleteChanged')
  autocmd ColorScheme,VimEnter * call s:ColorScheme()
  autocmd VimEnter             * call s:MapTab()
  autocmd BufReadCmd copilot://* setlocal buftype=nofile bufhidden=wipe nobuflisted readonly nomodifiable
augroup END

call s:ColorScheme()
call s:MapTab()
if !get(g:, 'copilot_no_maps')
  if empty(mapcheck('<C-]>', 'i'))
    imap <silent><script><nowait><expr> <C-]> copilot#Dismiss() . "\<C-]>"
  endif
endif

call copilot#Init()

let s:dir = expand('<sfile>:h:h')
if getftime(s:dir . '/doc/copilot.txt') > getftime(s:dir . '/doc/tags')
  silent! execute 'helptags' fnameescape(s:dir . '/doc')
endif

imap <silent><nowait><expr> <C-z> copilot#NextResult(1)
