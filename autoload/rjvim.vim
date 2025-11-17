let s:cpo_save = &cpo
set cpo&vim

function! rjvim#app_colourscheme_switchsafe(colour) " {{
    if !exists('s:known_links') " {{
        let s:known_links = {}
    endif " }}
    function! s:Find_links() " {{
        " Find and remember links between highlighting groups.
        redir => listing
        try
            silent highlight
        finally
            redir END
        endtry
        for line in split(listing, "\n")
            let tokens = split(line)
            " We're looking for lines like "String xxx links to Constant" in the
            " output of the :highlight command.
            if len(tokens) ==# 5 && tokens[1] ==# 'xxx' && tokens[2] ==# 'links' && tokens[3] ==# 'to'
                let fromgroup = tokens[0]
                let togroup = tokens[4]
                let s:known_links[fromgroup] = togroup
            endif
        endfor
    endfunction " }}
    function! s:Restore_links() " {{
        " Restore broken links between highlighting groups.
        redir => listing
        try
            silent highlight
        finally
            redir END
        endtry
        let num_restored = 0
        for line in split(listing, "\n")
            let tokens = split(line)
            " We're looking for lines like "String xxx cleared" in the
            " output of the :highlight command.
            if len(tokens) ==# 3 && tokens[1] ==# 'xxx' && tokens[2] ==# 'cleared'
                let fromgroup = tokens[0]
                let togroup = get(s:known_links, fromgroup, '')
                if !empty(togroup)
                    execute 'hi link' fromgroup togroup
                    let num_restored += 1
                endif
            endif
        endfor
    endfunction " }}
    function! s:AccurateColorscheme(colo_name) " {{
        call <SID>Find_links()
        exec "colorscheme " a:colo_name
        call <SID>Restore_links()
    endfunction " }}
    call <SID>AccurateColorscheme(a:colour)
endfunction " }}
function! rjvim#app_colourssw_switchcolours(dir) " {{
    if !exists('g:colourssw_combi')
        for i in getcompletion('', 'color')
            for j in ['dark', 'light']
                let g:colourssw_combi += [[i, j]]
            endfor
        endfor
    endif
    if !exists('g:colourssw_default')
        let g:colourssw_default = [g:colors_name, &g:background]
    endif
    let g:colourssw_current       = [g:colors_name, &g:background]
    let g:colourssw_current_ind   = index(g:colourssw_combi, g:colourssw_current)
    let g:colourssw_current_ind = a:dir ==# '+' ?
        \ g:colourssw_current_ind ==# (len(g:colourssw_combi) - 1) ?
        \ 0 : g:colourssw_current_ind + 1 :
        \ g:colourssw_current_ind ==# 0 ?
        \ len(g:colourssw_combi) - 1 : g:colourssw_current_ind - 1
    let g:colourssw_current = g:colourssw_combi[g:colourssw_current_ind]
    call rjvim#app_colourscheme_switchsafe(g:colourssw_current[0])
    let &background = g:colourssw_current[1]
    redraw | echo g:colourssw_current
endfunction " }}
function! rjvim#app_conceal_automode(switch) " {{{
    let l:switch = a:switch ==# 2 ? !a:switch : a:switch
    if l:switch ==# 0
        return
    endif
    if &l:conceallevel !=# 0
        let l:conceallevel_init = &l:conceallevel
        augroup insertmode_conceal
            autocmd!
            autocmd InsertEnter * let &l:conceallevel = 0
            autocmd InsertLeave * let &l:conceallevel = l:conceallevel_init
        augroup END
    endif
endfunction " }}}
function! rjvim#app_fontsize(adjust) " {{
    " Neovide font size adjustment {{
    if g:neovide
        if !exists('g:rjvim#defaultneovidescale')
            if exists('g:neovide_scale_factor')
                let g:rjvim#defaultneovidescale = g:neovide_scale_factor
            endif
        endif
        if a:adjust ==# 'default'
            if exists('g:rjvim#defaultneovidescale')
                let g:neovide_scale_factor = g:rjvim#defaultneovidescale
            endif
        else
            let l:newsize =
                \ eval(g:neovide_scale_factor . ' ' . a:adjust . ' 0.1')
            :execute 'let g:neovide_scale_factor = ' . l:newsize
        endif
    endif " }}
endfunction " }}

function! rjvim#ft_sh_init() " {{
    function! Run()
        set filetype=sh
        set foldenable
        set foldmethod=syntax
        let g:is_bash         = 1
        let g:sh_fold_enabled = 7
        let g:sh_no_error     = 0
    endfunction
    augroup ftshinit " {{
        autocmd!
        autocmd FileType sh call Run()
    augroup END " }}
endfunction " }}
function! rjvim#ft_templates() " {{
    function! GetFF(file) " {{
        let l:file =
            \ expand(a:file)
            \ ->fnameescape()
            \ ->readblob()
            \ ->string()
            \ ->split('.\{2}\zs', ' ')
        let l:fileindex  = 0
        let l:cont       = 1
        let l:filelen    = len(l:file)
        let l:filelenbrk = l:filelen > 80 ? l:filelen / 2 : l:filelen
        while l:cont ==# 1
            let l:check = l:file[l:fileindex] ==# '0A'
            if l:check || l:fileindex >=# l:filelenbrk
                let l:cont = 0
            else
                let l:fileindex += 1
            endif
        endwhile
        let l:fileformat =
            \ l:file[l:fileindex - 1] ==# '0D' ?
            \ 'dos' : 'unix'
        return l:fileformat
    endfunction " }}
    function! GetTemplateFN(ext) " {{
        return expand(g:templates_path)
            \ . (g:os ==# 'windows' ? '\' : '/')
            \ . g:templates_prefix
            \ . '.'
            \ . expand(a:ext)
    endfunction " }}
    let l:template = GetTemplateFN('%:e')
    if !filereadable(l:template)
        return
    endif
    let l:insert = readfile(l:template)
    call appendbufline(bufnr(), 0, l:insert)
    let &l:fileformat = GetFF(l:template)
endfunction " }}

function! rjvim#fmt_autoformattoggle() " {{
    let l:formatoptionsoperator = strridx(&l:formatoptions, "a") > 0 ?
        \ '-' : '+'
    execute ":setlocal formatoptions" . l:formatoptionsoperator . "=a" |
        \ echom "autoformat".l:formatoptionsoperator
endfunction " }}
function! rjvim#fmt_breakonperiod() " {{
    call rjvim#fmt_formattext_long()
    silent! execute "normal! mT:.s/\\. /.\\r/e\<CR>`T:delmarks T\<CR>^:DeleteTrailingWhitespace\<CR>"
endfunction " }}
function! rjvim#fmt_formattext_short() " {{
    let s:origtextwidth = &l:textwidth
    let &l:textwidth    = g:textwidth
    execute 'normal! gwap\<CR>'
    let &l:textwidth = s:origtextwidth
endfunction " }}
function! rjvim#fmt_formattext_long() " {{
    let s:origtextwidth = &l:textwidth
    let &l:textwidth = 800000000
    silent! execute "normal! mTgwap\<CR>`T"
    silent! execute 's/\s\s\+/ /e'
    silent! execute 's/\(\.\)\( \u\l\)/\1 \2/e'
    silent! execute "normal! ^:DeleteTrailingWhitespace\<CR>`T:delmarks T\<CR>"
    let &l:textwidth = s:origtextwidth
endfunction " }}
function! rjvim#fmt_formattext_isolated() " {{
    silent! execute "normal! mT"
    call rjvim#fmt_insert_blank("updown")
    call rjvim#fmt_formattext_short()
    silent! execute "normal! {dd}dd`T:delmarks T\<CR>"
endfunction " }}
function! rjvim#fmt_insert_blank(mode) " {{
    let l:insertexp =  a:mode ==# 'up'     ?
        \ "O\<C-o>j" : a:mode ==# 'down'   ?
        \ "o\<C-o>k" : a:mode ==# 'updown' ?
        \ "O\<C-o>j\<C-o>o\<C-o>k" : ""
    silent! execute "normal! mT" . l:insertexp . "\<C-o>`T\<C-o>:delmarks T\<CR>"
endfunction " }}

function! rjvim#sys_backupenable() " {{
    function! s:setupbackup()
        let l:filename  =
            \ expand('%')
            \ ->fnameescape()
        let l:backupdir =
            \ ('.vbak/' . l:filename)
            \ ->fnameescape()
        if empty(glob(l:backupdir))
            call mkdir(l:backupdir, "p")
        endif
        let &l:backupdir = l:backupdir

        let l:fileftime = getftime(l:filename)
        let l:tformat = '%Y%m%d%H%M%S'
        let &l:backupext = '.' . (l:fileftime ==# -1 ?
            \ strftime("%Y%m%d%H%M%S") :
            \ strftime(l:tformat, getftime(l:filename)))
    endfunction
    setlocal undofile
    setlocal backup
    augroup enablebackupsprewrite " {{
        autocmd!
        autocmd BufWritePre * call <SID>setupbackup()
    augroup END " }}
endfunction " }}
function! rjvim#sys_info() " {{
    function! IsWin()
        return map(['win16', 'win32', 'win64'], 'has(v:val)') ->max()
    endfunction
    let g:os =
        \ IsWin()      ? 'windows' :
        \ has('linux') ? 'linux'   :
        \ 'unknown'
    let g:root =
        \ g:os ==# 'windows' ?
        \ filewritable('C:\Windows\System32') :
        \ system('printf ''%s'' "$USER"') ==# 'root' ?
        \ 1 : 0
    let g:dirsep =
        \ g:os ==# 'windows' ?
        \ '\' : '/'
endfunction " }}
function! rjvim#sys_insertmute_on(motion) " {{
    set eventignore+=InsertLeave,InsertEnter
    return "\<C-o>" . a:motion
endfunction " }}
function! rjvim#sys_insertmute_off() " {{
    set eventignore-=InsertLeave,InsertEnter
    return "\<Ignore>"
endfunction " }}

function! rjvim#ut_add_ln(pad, width) " {{
    let s:width =
        \ a:width ==# 0 ?
        \ strlen(line("$")) : a:width
    let s:pad =
        \ a:pad ==# '' || a:pad ==# '0' ?
        \ a:pad : '0'
    silent! execute '%s/^/\=printf(''%' . s:pad . s:width . 'd '', line(''.''))'
endfunction " }}
function! rjvim#ut_gensep(comment, head, body, tail, level) " {{
    let l:textwidth   = exists('g:textwidth') ? g:textwidth : 80
    let l:length      = l:textwidth - (a:level * 10)
    let l:comment     = a:comment ==# ['auto'] ? split(&l:commentstring, '%s') : a:comment
    let l:comment_len = len(l:comment)
    if !(l:comment_len == 0 || l:comment_len > 2)
        let l:head = l:comment[0] . a:head
        let l:tail = len(l:comment) == 2 ?  a:tail . l:comment[1] : a:tail
    else
        return 'ERROR'
    endif
    let l:line      = getline('.')
    let l:sep       =
        \ l:head
        \ . repeat(a:body,
        \ reduce(map([ l:head, a:body, l:tail ],
        \ 'strlen(v:val)'), { acc, val -> acc - val},
        \ l:length + 1))
        \ . l:tail
    call setline('.',
        \ strpart(l:line, 0, col('.') - 1)
        \ . l:sep
        \ . strpart(l:line, col('.') - 1))
endfunction " }}
function! rjvim#ut_initvar(var, val) " {{
    execute 'let ' . a:var . ' = exists(''' . a:var . ''') ? ' . a:var . ': ' . a:val
endfunction " }}
function! rjvim#ut_spellacceptfirst() " {{
    execute 'normal! mT1z=`T:delmarks T\<CR>'
endfunction " }}

let &cpo = s:cpo_save
unlet s:cpo_save
