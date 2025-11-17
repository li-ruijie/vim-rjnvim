-- Load the main module {{
local rjvim9 = require('rjvim9')
-- }}
-- Plug mappings {{
-- Font size adjustments {{
vim.keymap.set('n', '<Plug>(rjvim-fontsize-decrease)', function()
    rjvim9.app_fontsize('-')
end, { silent = true, desc = 'Decrease font size' })
vim.keymap.set('n', '<Plug>(rjvim-fontsize-increase)', function()
    rjvim9.app_fontsize('+')
end, { silent = true, desc = 'Increase font size' })
vim.keymap.set('n', '<Plug>(rjvim-fontsize-default)', function()
    rjvim9.app_fontsize('default')
end, { silent = true, desc = 'Reset font size to default' })
-- }}
-- Color scheme switching {{
vim.keymap.set('n', '<Plug>(rjvim-colorscheme-next)', function()
    rjvim9.app_colourssw_switchcolours('+')
end, { silent = true, desc = 'Switch to next colorscheme' })
vim.keymap.set('n', '<Plug>(rjvim-colorscheme-prev)', function()
    rjvim9.app_colourssw_switchcolours('-')
end, { silent = true, desc = 'Switch to previous colorscheme' })
-- }}
-- Spell checking {{
vim.keymap.set('n', '<Plug>(rjvim-spell-accept-first)', function()
    rjvim9.ut_spellacceptfirst()
end, { silent = true, desc = 'Accept first spelling suggestion' })
vim.keymap.set('i', '<Plug>(rjvim-spell-accept-first)', function()
    rjvim9.ut_spellacceptfirst()
end, { silent = true, desc = 'Accept first spelling suggestion' })
-- }}
-- }}
-- DTWS (Delete Trailing WhiteSpace) Setup {{
-- Load once only guard {{
if vim.g['rjvim9#DTWS_loaded'] then
    return
end
vim.g['rjvim9#DTWS_loaded'] = 1
-- }}
-- Configuration {{
if vim.g['rjvim9#DTWS'] == nil then
    vim.g['rjvim9#DTWS'] = 0
end
if vim.g['rjvim9#DTWS_action'] == nil then
    vim.g['rjvim9#DTWS_action'] = 'abort'
end
-- }}
-- Autocmds for DTWS {{
local dtws_group = vim.api.nvim_create_augroup('DTWS', { clear = true })
vim.api.nvim_create_autocmd('BufWritePre', {
    group = dtws_group,
    pattern = '*',
    callback = function()
        local ok, err = pcall(rjvim9.ut_dtws_interceptwrite)
        if not ok and err:match('^DTWS:') then
            vim.api.nvim_echo({{err:gsub('^DTWS:%s*', ''), 'ErrorMsg'}},
            true, {})
        elseif not ok then
            error(err)
        end
    end,
    desc = 'Delete trailing whitespace on write'
})
-- }}
-- DTWS Command {{
local is_modified = false
local function before_dtws()
    is_modified = vim.bo.modified
end
local function after_dtws()
    if not is_modified then
        vim.bo.modified = false
    end
end
vim.api.nvim_create_user_command('DTWS', function(opts)
    before_dtws()
    -- Force buffer modification detection
    local line1 = opts.line1
    local line2 = opts.line2
    vim.fn.setline(line1, vim.fn.getline(line1))
    after_dtws()
    rjvim9.ut_dtws_delete(line1, line2)
end, {
    range = '%',
    bar = true,
    desc = 'Delete trailing whitespace in range'
})
-- }}
-- }}
-- Additional Commands and Setup {{
-- Create commands for the main functions {{
vim.api.nvim_create_user_command('RjvimFontSizeIncrease', function()
    rjvim9.app_fontsize('+')
end, { desc = 'Increase font size' })
vim.api.nvim_create_user_command('RjvimFontSizeDecrease', function()
    rjvim9.app_fontsize('-')
end, { desc = 'Decrease font size' })
vim.api.nvim_create_user_command('RjvimFontSizeDefault', function()
    rjvim9.app_fontsize('default')
end, { desc = 'Reset font size to default' })
vim.api.nvim_create_user_command('RjvimColorschemeNext', function()
    rjvim9.app_colourssw_switchcolours('+')
end, { desc = 'Switch to next colorscheme' })
vim.api.nvim_create_user_command('RjvimColorschemePrev', function()
    rjvim9.app_colourssw_switchcolours('-')
end, { desc = 'Switch to previous colorscheme' })
vim.api.nvim_create_user_command('RjvimFormatTextShort', function()
    rjvim9.fmt_formattext_short()
end, { desc = 'Format text with short width' })
vim.api.nvim_create_user_command('RjvimFormatTextLong', function()
    rjvim9.fmt_formattext_long()
end, { desc = 'Format text with long width' })
vim.api.nvim_create_user_command('RjvimFormatTextIsolated', function()
    rjvim9.fmt_formattext_isolated()
end, { desc = 'Format text with isolation' })
vim.api.nvim_create_user_command('RjvimAutoFormatToggle', function()
    rjvim9.fmt_autoformattoggle()
end, { desc = 'Toggle auto formatting' })
vim.api.nvim_create_user_command('RjvimBreakOnPeriod', function()
    rjvim9.fmt_breakonperiod()
end, { desc = 'Break text on periods' })
vim.api.nvim_create_user_command('RjvimFixFileFormat', function()
    rjvim9.fmt_fixfileformat()
end, { desc = 'Fix file format issues' })
vim.api.nvim_create_user_command('RjvimBackupEnable', function()
    rjvim9.sys_backupenable()
end, { desc = 'Enable backup system' })
vim.api.nvim_create_user_command('RjvimSysInfo', function()
    rjvim9.sys_info()
end, { desc = 'Detect system information' })
vim.api.nvim_create_user_command('RjvimShInit', function()
    rjvim9.ft_sh_init()
end, { desc = 'Initialize shell script settings' })
vim.api.nvim_create_user_command('RjvimTemplates', function()
    rjvim9.ft_templates()
end, { desc = 'Load file templates' })
-- }}
-- Utility commands {{
vim.api.nvim_create_user_command('RjvimAddLineNumbers', function(opts)
    local args = vim.split(opts.args, '%s+')
    local pad = args[1] or ''
    local width = tonumber(args[2]) or 0
    rjvim9.ut_add_ln(pad, width)
end, {
    nargs = '*',
    desc = 'Add line numbers to buffer'
})
vim.api.nvim_create_user_command('RjvimGenSep', function(opts)
    local args = vim.split(opts.args, '%s+')
    local comment = args[1] and vim.split(args[1], ',') or {'auto'}
    local head = args[2] or ''
    local body = args[3] or '-'
    local tail = args[4] or ''
    local level = tonumber(args[5]) or 0
    rjvim9.ut_gensep(comment, head, body, tail, level)
end, {
    nargs = '*',
    desc = 'Generate separator line'
})
-- }}
-- }}
