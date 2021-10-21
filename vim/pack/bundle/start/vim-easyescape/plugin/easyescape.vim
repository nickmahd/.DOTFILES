" easyescape.vim        Pull out your Escape key!
" Author:               Yichao Zhou (broken.zhou AT gmail)
" Version:              0.2
" ---------------------------------------------------------------------

if &cp || exists("g:loaded_easyescape")
    finish
endif
let g:loaded_easyescape = 1
let s:haspy3 = has("python3")

if !exists("g:easyescape_chars")
    let g:easyescape_chars = { "j": 1, "k": 1 }
endif
if !exists("g:easyescape_timeout")
    if s:haspy3
        let g:easyescape_timeout = 100
    else
        let g:easyescape_timeout = 2000
    endif
endif

if !s:haspy3 && g:easyescape_timeout < 2000
    echomsg "Python3 is required when g:easyescape_timeout < 2000"
    let g:easyescape_timeout = 2000
endif

function! s:EasyescapeInsertCharPre()
    if has_key(g:easyescape_chars, v:char) == 0
        let s:current_chars = copy(g:easyescape_chars)
    endif
endfunction

function! s:EasyescapeSetTimer()
    if s:haspy3
        py3 easyescape_time = default_timer()
    endif
    let s:localtime = localtime()
endfunction

function! s:EasyescapeReadTimer()
    if s:haspy3
        py3 vim.command("let pyresult = %g" % (1000 * (default_timer() - easyescape_time)))
        return pyresult
    endif
    return 1000 * (localtime() - s:localtime)
endfunction

function! <SID>EasyescapeMap(char)
    if exists("b:easyescape_disable") && b:easyescape_disable == 1
        return a:char
    endif
    if s:current_chars[a:char] == 0
        let s:current_chars = copy(g:easyescape_chars)
        let s:current_chars[a:char] = s:current_chars[a:char] - 1
        call s:EasyescapeSetTimer()
        return a:char
    endif

    if s:EasyescapeReadTimer() > g:easyescape_timeout
        let s:current_chars = copy(g:easyescape_chars)
        let s:current_chars[a:char] = s:current_chars[a:char] - 1
        call s:EasyescapeSetTimer()
        return a:char
    endif

    let s:current_chars[a:char] = s:current_chars[a:char] - 1
    for value in values(s:current_chars)
        if value > 0
            call s:EasyescapeSetTimer()
            return a:char
        endif
    endfor

    let s:current_chars = copy(g:easyescape_chars)

    " Workaround for #3, might be less annoying but still not perfect
    let current_line = getline(".")
    let current_line_trimed  = substitute(current_line, '^\s*\(.\{-}\)\s*$', '\1', '')
    let n_chars = eval(join(values(g:easyescape_chars), "+")) - 1

    let seq = s:escape_sequence
    if col(".") == len(current_line) + 1 && n_chars == len(current_line_trimed)
        let seq = seq . '0"_D'
    endif

    return seq

endfunction

let s:current_chars = copy(g:easyescape_chars)

augroup easyescape
    au!
    au InsertCharPre * call s:EasyescapeInsertCharPre()
augroup END

for key in keys(g:easyescape_chars)
    exec "inoremap <expr>" . key . " <SID>EasyescapeMap(\"" . key . "\")"
endfor

if s:haspy3
    py3 from timeit import default_timer
    py3 import vim
    call s:EasyescapeSetTimer()
else
    let s:localtime = localtime()
endif

let s:escape_sequence = repeat("\<BS>", eval(join(values(g:easyescape_chars), "+"))-1) . "\<ESC>"

" vim:set expandtab tabstop=4 shiftwidth=4:
