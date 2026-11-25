local M = {}

-- Global variables for state management
local known_links = {}

-- ============================================================================
-- App Functions - Application-level functionality
-- ============================================================================

-- App_colourscheme_switchsafe: Safe colorscheme switching with link preservation
function M.app_colourscheme_switchsafe(colour)
    M._accurate_colorscheme(colour)
end

-- Internal function to find highlight links
local function find_links()
    known_links = {}
    local output = vim.fn.execute('highlight')
    for line in output:gmatch('[^\r\n]+') do
        local tokens = vim.split(line, '%s+')
        -- Looking for lines like "String xxx links to Constant"
        if #tokens == 5 and tokens[2] == 'xxx' and tokens[3] == 'links' and tokens[4] == 'to' then
            local fromgroup = tokens[1]
            local togroup = tokens[5]
            known_links[fromgroup] = togroup
        end
    end
end

-- Internal function to restore broken highlight links
local function restore_links()
    local output = vim.fn.execute('highlight')
    local num_restored = 0
    for line in output:gmatch('[^\r\n]+') do
        local tokens = vim.split(line, '%s+')
        -- Looking for lines like "String xxx cleared"
        if #tokens == 3 and tokens[2] == 'xxx' and tokens[3] == 'cleared' then
            local fromgroup = tokens[1]
            local togroup = known_links[fromgroup]
            if togroup and togroup ~= '' then
                vim.cmd('hi link ' .. fromgroup .. ' ' .. togroup)
                num_restored = num_restored + 1
            end
        end
    end
end

-- Internal function for accurate colorscheme switching
function M._accurate_colorscheme(colo_name)
    find_links()
    vim.cmd('colorscheme ' .. colo_name)
    restore_links()
end

-- App_colourssw_switchcolours: Color scheme cycling
function M.app_colourssw_switchcolours(dir)
    -- vim.g hands out a copy on every read, so the list is built in a local
    -- and stored whole. Inserting into vim.g.colourssw_combi changes nothing.
    local combi = vim.g.colourssw_combi
    if not combi then
        combi = {}
        for _, colorscheme in ipairs(vim.fn.getcompletion('', 'color')) do
            for _, bg in ipairs({'dark', 'light'}) do
                table.insert(combi, {colorscheme, bg})
            end
        end
        vim.g.colourssw_combi = combi
    end

    local current = {vim.g.colors_name, vim.o.background}
    if not vim.g.colourssw_default then
        vim.g.colourssw_default = current
    end

    -- Find current index, starting from the first entry when the current
    -- scheme was changed externally and is not in the list
    local current_ind = 1
    for i, combo in ipairs(combi) do
        if combo[1] == current[1] and combo[2] == current[2] then
            current_ind = i
            break
        end
    end

    -- Calculate next index
    if dir == '+' then
        current_ind = current_ind == #combi and 1 or current_ind + 1
    else
        current_ind = current_ind == 1 and #combi or current_ind - 1
    end

    current = combi[current_ind]
    vim.g.colourssw_current = current
    M.app_colourscheme_switchsafe(current[1])
    vim.o.background = current[2]
    vim.cmd('redraw')
    print(vim.inspect(current))
end

-- App_conceal_automode: Auto conceal mode management
function M.app_conceal_automode(switch)
    local switch_val = switch == 2 and 0 or switch
    if switch_val == 0 then
        return
    end

    if vim.wo.conceallevel ~= 0 then
        local conceallevel_init = vim.wo.conceallevel
        local group = vim.api.nvim_create_augroup('insertmode_conceal', {clear = true})
        vim.api.nvim_create_autocmd('InsertEnter', {
            group = group,
            callback = function()
                vim.wo.conceallevel = 0
            end
        })
        vim.api.nvim_create_autocmd('InsertLeave', {
            group = group,
            callback = function()
                vim.wo.conceallevel = conceallevel_init
            end
        })
    end
end

-- App_fontsize: Font size adjustment (Neovide-specific)
function M.app_fontsize(adjust)
    -- Neovide font size adjustment
    if vim.g.neovide then
        if not vim.g['rjvim#defaultneovidescale'] then
            if vim.g.neovide_scale_factor then
                vim.g['rjvim#defaultneovidescale'] = vim.g.neovide_scale_factor
            end
        end
        if adjust == 'default' then
            if vim.g['rjvim#defaultneovidescale'] then
                vim.g.neovide_scale_factor = vim.g['rjvim#defaultneovidescale']
            end
        else
            local current_scale = vim.g.neovide_scale_factor or 1.0
            local new_scale
            if adjust == '+' then
                new_scale = current_scale + 0.1
            elseif adjust == '-' then
                new_scale = current_scale - 0.1
            else
                new_scale = current_scale
            end
            vim.g.neovide_scale_factor = new_scale
        end
    end
end

-- ============================================================================
-- Fmt Functions - Text formatting utilities
-- ============================================================================

-- Fmt_autoformattoggle: Toggle auto formatting
function M.fmt_autoformattoggle()
    local fo = vim.bo.formatoptions
    local has_a = fo:find('a') ~= nil
    local operator = has_a and '-' or '+'
    vim.cmd('setlocal formatoptions' .. operator .. '=a')
    print('autoformat' .. operator)
end

-- Fmt_breakonperiod: Break text on periods
function M.fmt_breakonperiod()
    M.fmt_formattext_long()
    local lnum, col = vim.fn.line('.'), vim.fn.col('.')
    -- Split in Lua. A :substitute would follow the user's 'gdefault', which
    -- inverts the g flag and splits the first sentence only.
    local joined = vim.fn.getline(lnum):gsub('%. ', '.\n')
    local sentences = vim.split(joined, '\n', { plain = true })
    if #sentences > 1 then
        for i, sentence in ipairs(sentences) do
            sentences[i] = sentence:gsub('%s+$', '')
        end
        vim.api.nvim_buf_set_lines(0, lnum - 1, lnum, false, sentences)
        vim.fn.cursor(lnum, col)
    end
end

-- Fmt_fixfileformat: Fix file format issues
function M.fmt_fixfileformat()
    if vim.bo.modified then
        print('Save the file first.')
        return 1
    end

    local result = vim.fn.execute('%s/\\r//en'):gsub('^\\n', '')
    if result ~= '' then
        local fforig = vim.bo.fileformat
        if vim.bo.fileformat == 'dos' then
            vim.bo.fileformat = 'unix'
            vim.cmd('write')
        end
        vim.cmd('edit ++fileformat=dos')
        vim.bo.fileformat = fforig
    end
end

-- Collapse each run of blanks after the indent of text to one space
local function one_space(text)
    return (text:gsub('(%S)%s%s+', '%1 '))
end

-- Reformat the current paragraph with gw at the given textwidth. An operator
-- in a closed fold takes the whole fold, so folding is off while it runs, and
-- joined lines get one space after a sentence end.
local function format_paragraph(textwidth)
    local orig_textwidth = vim.bo.textwidth
    local orig_foldenable = vim.wo.foldenable
    local orig_joinspaces = vim.o.joinspaces
    vim.bo.textwidth = textwidth
    vim.wo[0][0].foldenable = false
    vim.o.joinspaces = false
    local ok, err = pcall(vim.cmd, 'normal! gwap')
    vim.bo.textwidth = orig_textwidth
    vim.wo[0][0].foldenable = orig_foldenable
    vim.o.joinspaces = orig_joinspaces
    return ok, err
end

-- Fmt_formattext_short: Format text with short width
function M.fmt_formattext_short()
    -- An insert-mode cursor past the end of the line comes back from gw on
    -- the last character, so step it over that character again.
    local pastend = vim.fn.col('.') > #vim.fn.getline('.')
    local ok, err = format_paragraph(vim.g.textwidth or 80)
    if not ok then
        error(err, 0)
    end
    if pastend then
        vim.fn.setcursorcharpos(vim.fn.line('.'), vim.fn.charcol('.') + 1)
    end
end

-- Fmt_formattext_long: Join the paragraph into one long line, with one space
-- between words and after each sentence, and no trailing whitespace
function M.fmt_formattext_long()
    format_paragraph(800000000)
    -- gw keeps the cursor on the same text, which is now on the joined line.
    -- A position saved before the join would name a line further down, in
    -- the next paragraph whenever the cursor started below the first line.
    local lnum = vim.fn.line('.')
    local text = vim.fn.getline(lnum)
    local before = text:sub(1, vim.fn.col('.') - 1)
    local tidy = one_space(text):gsub('%s+$', '')
    -- only this line is rewritten, and only when it changes (touching more
    -- forces a full-buffer fold recompute under foldmethod=expr)
    if tidy ~= text then
        vim.fn.setline(lnum, tidy)
    end
    vim.fn.cursor(lnum, #one_space(before) + 1)
end

-- Fmt_formattext_isolated: Format the current line as a paragraph of its own
function M.fmt_formattext_isolated()
    if vim.fn.getline('.'):match('^%s*$') then
        return
    end
    local lnum = vim.fn.line('.')
    -- Blank lines added around the line keep gwap from reaching past it, and
    -- are removed again afterwards.
    vim.fn.append(lnum, '')
    vim.fn.append(lnum - 1, '')
    M.fmt_formattext_short()
    -- gw leaves the cursor in the block, so the first blank line below it is
    -- the one added under the block.
    vim.fn.deletebufline(vim.fn.bufnr(), vim.fn.search([[^\s*$]], 'nW'))
    vim.fn.deletebufline(vim.fn.bufnr(), lnum)
end

-- Fmt_insert_blank: Insert blank lines
function M.fmt_insert_blank(mode)
    local lnum = vim.fn.line('.')
    -- Insert below first, since inserting above moves the line down.
    if mode == 'down' or mode == 'updown' then
        vim.fn.append(lnum, '')
    end
    if mode == 'up' or mode == 'updown' then
        vim.fn.append(lnum - 1, '')
    end
end

-- ============================================================================
-- Ft Functions - Filetype-specific functions
-- ============================================================================

-- Ft_sh_init: Shell script initialization
function M.ft_sh_init()
    local group = vim.api.nvim_create_augroup('ftshinit', {clear = true})
    vim.api.nvim_create_autocmd('FileType', {
        group = group,
        pattern = 'sh',
        callback = M._run_ftshinit
    })
end

-- Internal function for shell script setup
function M._run_ftshinit()
    vim.bo.filetype = 'sh'
    vim.wo.foldenable = true
    vim.wo.foldmethod = 'syntax'
    vim.g.is_bash = 1
    vim.g.sh_fold_enabled = 7
    vim.g.sh_no_error = 0
end

-- Ft_templates: Template handling
function M.ft_templates()
    -- Skip for special buffers (preview, help, quickfix, etc.)
    if vim.bo.buftype ~= '' then
        return
    end

    -- Skip if buffer has no name or unusual name
    local bufname = vim.fn.expand('%')
    if bufname == '' or bufname:match('^%[') then
        return
    end

    local template = M._get_template_fn(vim.fn.expand('%:e'))
    if not vim.fn.filereadable(template) or template == '' then
        return
    end

    -- Protected call to handle any file reading errors
    local ok, insert = pcall(vim.fn.readfile, template)
    if not ok then
        return
    end

    vim.fn.appendbufline(vim.fn.bufnr(), 0, insert)
    vim.bo.fileformat = M._get_ff(template)
end

-- Internal function to get file format
function M._get_ff(file)
    local file_bytes = vim.fn.readblob(vim.fn.fnameescape(vim.fn.expand(file)))
    local file_str = vim.fn.string(file_bytes)
    local bytes = vim.split(file_str, '..\\zs')

    local fileindex = 0
    local cont = true
    local filelen = #bytes
    local filelenbrk = filelen > 80 and math.floor(filelen / 2) or filelen

    while cont do
        local check = bytes[fileindex + 1] == '0A'
        if check or fileindex >= filelenbrk then
            cont = false
        else
            fileindex = fileindex + 1
        end
    end

    local fileformat = bytes[fileindex] == '0D' and 'dos' or 'unix'
    return fileformat
end

-- Internal function to get template filename
function M._get_template_fn(ext)
    local sep = vim.g.os == 'windows' and '\\' or '/'
    return vim.fn.expand(vim.g.templates_path) .. sep .. vim.g.templates_prefix .. '.' .. vim.fn.expand(ext)
end

-- ============================================================================
-- Sys Functions - System utilities
-- ============================================================================

-- Sys_backupenable: Enable backup system
function M.sys_backupenable()
    vim.bo.undofile = true
    vim.go.backup = true
    local group = vim.api.nvim_create_augroup('enablebackupsprewrite', {clear = true})
    vim.api.nvim_create_autocmd('BufWritePre', {
        group = group,
        pattern = '*',
        callback = M._setup_backup
    })
end

-- Internal function to setup backup
function M._setup_backup()
    local filename = vim.fn.expand('%')
    local backupdir = '.vbak/' .. filename
    if vim.fn.empty(vim.fn.glob(backupdir)) == 1 then
        vim.fn.mkdir(backupdir, 'p')
    end
    vim.o.backupdir = backupdir

    local fileftime = vim.fn.getftime(filename)
    local tformat = '%Y%m%d%H%M%S'
    local backup_ext = fileftime == -1 and vim.fn.strftime(tformat) or vim.fn.strftime(tformat, fileftime)
    vim.o.backupext = '.' .. backup_ext
end

-- Sys_info: System information detection
function M.sys_info()
    vim.g.os = M._is_win() and 'windows' or (vim.fn.has('linux') == 1 and 'linux' or 'unknown')

    if vim.g.os == 'windows' then
        vim.g.root = vim.fn.filewritable('C:\\Windows\\System32') == 1 and 1 or 0
    else
        vim.g.root = vim.fn.system('printf "%s" "$USER"'):gsub('%s+', '') == 'root' and 1 or 0
    end

    vim.g.dirsep = vim.g.os == 'windows' and '\\' or '/'
end

-- Internal function to detect Windows
function M._is_win()
    return vim.fn.has('win16') == 1 or vim.fn.has('win32') == 1 or vim.fn.has('win64') == 1
end

-- Sys_insertmute_off: Turn off insert mode muting
function M.sys_insertmute_off()
    vim.o.eventignore = vim.o.eventignore:gsub('InsertLeave,?', ''):gsub('InsertEnter,?', ''):gsub(',,', ','):gsub('^,', ''):gsub(',$', '')
    return vim.keycode('<Ignore>')
end

-- Sys_insertmute_on: Turn on insert mode muting
function M.sys_insertmute_on(motion)
    local current = vim.o.eventignore
    if current == '' then
        vim.o.eventignore = 'InsertLeave,InsertEnter'
    else
        vim.o.eventignore = current .. ',InsertLeave,InsertEnter'
    end
    return vim.keycode('<C-o>') .. motion
end

-- Sys_insertmute_move: Muted movement in insert mode
function M.sys_insertmute_move(motion)
    return M.sys_insertmute_on(motion) .. M.sys_insertmute_off()
end

-- ============================================================================
-- Ut Functions - General utilities
-- ============================================================================

-- Ut_add_ln: Add line numbers
function M.ut_add_ln(pad, width)
    local width_val = width == 0 and vim.fn.strlen(vim.fn.line('$')) or width
    local pad_val = (pad == '' or pad == '0') and pad or '0'
    local format_str = '%' .. pad_val .. width_val .. 'd '
    vim.cmd([[%s/^/\=printf(']] .. format_str .. [[', line('.'))/ ]])
end

-- Ut_gensep: Generate separator
function M.ut_gensep(comment, head, body, tail, level)
    local textwidth = vim.g.textwidth or 80
    local length = textwidth - (level * 10)

    local comment_val
    if type(comment) == 'table' and comment[1] == 'auto' then
        comment_val = vim.split(vim.bo.commentstring, '%%s')
    else
        comment_val = comment
    end

    local comment_len = #comment_val
    local head_val, tail_val

    if comment_len == 0 or comment_len > 2 then
        return 'ERROR'
    end

    head_val = comment_val[1] .. head
    tail_val = comment_len == 2 and (tail .. comment_val[2]) or tail

    local lengths = {vim.fn.strlen(head_val), vim.fn.strlen(body), vim.fn.strlen(tail_val)}
    local total_len = 0
    for _, len in ipairs(lengths) do
        total_len = total_len + len
    end

    local repeat_count = length + 1 - total_len
    local sep = head_val .. string.rep(body, repeat_count) .. tail_val

    local line = vim.fn.getline('.')
    local col = vim.fn.col('.')
    local new_line = line:sub(1, col - 1) .. sep .. line:sub(col)
    vim.fn.setline('.', new_line)

    return ''
end

-- Ut_initvar: Initialize variable if not exists
function M.ut_initvar(var, val)
    if not vim.g[var] then
        vim.g[var] = val
    end
end

-- Ut_multifunc: Apply multiple functions
function M.ut_multifunc(funcs, init)
    local result = init
    for _, func in ipairs(funcs) do
        result = func(result)
    end
    return result
end

-- Ut_spellacceptfirst: Accept first spelling suggestion
function M.ut_spellacceptfirst()
    local save_pos = vim.fn.getcurpos()
    vim.cmd('normal! 1z=')
    vim.fn.setpos('.', save_pos)
end

-- ============================================================================
-- DTWS Functions - Delete Trailing WhiteSpace utilities
-- ============================================================================

-- Ut_DTWS_delete: Delete trailing whitespace
function M.ut_dtws_delete(start_lnum, end_lnum)
    local save_cursor = vim.fn.getpos('.')
    vim.cmd(start_lnum .. ',' .. end_lnum .. 'substitute/' .. vim.fn.escape(M.ut_dtws_pattern(), '/') .. '//e')
    vim.fn.histdel('search', -1)
    vim.fn.setpos('.', save_cursor)
end

-- Ut_DTWS_get: Get DTWS setting
function M.ut_dtws_get()
    return vim.b['rjvim9#DTWS'] or vim.g['rjvim9#DTWS']
end

-- Ut_DTWS_getaction: Get DTWS action
function M.ut_dtws_getaction()
    return vim.b['rjvim9#DTWS_action'] or vim.g['rjvim9#DTWS_action']
end

-- Ut_DTWS_hastrailingwhitespace: Check for trailing whitespace
function M.ut_dtws_hastrailingwhitespace()
    return vim.fn.search(M.ut_dtws_pattern(), 'cnw') > 0
end

-- Ut_DTWS_interceptwrite: Intercept write operations
function M.ut_dtws_interceptwrite()
    if M.ut_dtws_isset() and M.ut_dtws_isaction() then
        if not vim.bo.modifiable and M.ut_dtws_getaction() == 'delete' then
            vim.api.nvim_echo({{'Cannot automatically delete trailing whitespace, buffer is not modifiable', 'WarningMsg'}}, true, {})
            vim.cmd('sleep 1')
            return
        end
        M.ut_dtws_delete(1, vim.fn.line('$'))
    end
end

-- Ut_DTWS_isaction: Check if DTWS action should be performed
function M.ut_dtws_isaction()
    local action = M.ut_dtws_getaction()
    if action == 'delete' then
        return true
    elseif action == 'abort' then
        if not vim.v.cmdbang and M.ut_dtws_hastrailingwhitespace() then
            error('DTWS: Trailing whitespace found, aborting write (add ! to override, or :DTWS to eradicate)')
        end
        return true
    else
        error('ASSERT: Invalid value for DTWS_action: ' .. vim.inspect(action))
    end
end

-- Ut_DTWS_isset: Check if DTWS is enabled
function M.ut_dtws_isset()
    local value = M.ut_dtws_get()
    if not value or value == 0 then
        return false
    elseif value == 'always' or value == 1 then
        return true
    else
        return false
    end
end

-- Ut_DTWS_pattern: Get trailing whitespace pattern
function M.ut_dtws_pattern()
    return '\\s\\+$'
end

return M
