-- Plugins
local path = '~/.vim/plugged'
if vim.fn.has('nvim') then
    path = vim.fn.stdpath('config') .. '/plugged'
end
local Plug = vim.fn['plug#']
vim.call('plug#begin', path)
    Plug('neovim/nvim-lspconfig')
    Plug('nvim-lua/plenary.nvim')
    Plug('nvim-telescope/telescope.nvim', { branch = '0.1.x' })
    Plug('nvim-treesitter/nvim-treesitter', { ['do'] = ':TSUpdate' })
    Plug('nvim-treesitter/nvim-treesitter-context')
    Plug('ziglang/zig.vim')
    Plug('tpope/vim-surround')
    Plug('tpope/vim-commentary')
    Plug('raimondi/delimitmate')
    Plug('hrsh7th/cmp-nvim-lsp')
    Plug('hrsh7th/cmp-buffer')
    Plug('hrsh7th/cmp-path')
    Plug('hrsh7th/cmp-cmdline')
    Plug('hrsh7th/nvim-cmp')
    Plug('hrsh7th/vim-vsnip')
    Plug('hrsh7th/cmp-nvim-lsp-signature-help')
    Plug('feline-nvim/feline.nvim')
    Plug('akinsho/toggleterm.nvim')

    -- Colors
    Plug('junegunn/seoul256.vim')
    Plug('phanviet/vim-monokai-pro')
vim.call('plug#end')

----------------------------------------
-- Options
----------------------------------------

vim.opt.mouse = {}
vim.opt.formatoptions = 'tqj'
vim.opt.number = true
vim.opt.termguicolors = true
vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.joinspaces = false
vim.opt.swapfile = false
vim.opt.ignorecase = true
vim.opt.signcolumn = 'yes'

vim.g.mapleader = ' '
vim.g.seoul256_background = 234
vim.api.nvim_set_var('delimitMate_expand_cr', true)
vim.cmd('colorscheme seoul256')

----------------------------------------
-- Toggleterm
----------------------------------------

require('toggleterm').setup({
    open_mapping = '<M-t>',
    direction = 'float'
})

----------------------------------------
-- Feline
----------------------------------------

-- require('eden.colors')
-- require('eden.feline')
-- require('feline').setup()

----------------------------------------
-- Tree Sitter
----------------------------------------

require('nvim-treesitter.configs').setup({
    ensure_installed = { 'c', 'zig', 'lua', 'rust' },
    sync_install = false,
    auto_install = true,
    highlight = {
        enable = true,
        disable = {},
    },
    incremental_selection = {
        enable = true,
        keymaps = {
            init_selection = '<M-o>',
            node_incremental = '<M-o>',
            node_decremental = '<M-i>',
        }
    }
})
require('treesitter-context').setup({
    enable = true,
    max_lines = 0,
    trim_scope = 'outer',
    min_window_height = 0,
    patterns = {
        default = {
            'class',
            'function',
            'method',
            'for',
            'while',
            'if',
            'switch',
            'case',
        },
        rust = {
            'impl_item',
            'struct',
            'enum',
        },
    },
    zindex = 20,
    mode = 'cursor',
    separator = nil,
})

----------------------------------------
-- LSP
----------------------------------------

local lsp_nmap = function(ptn, fn, bufopts)
    vim.keymap.set('n', ptn, fn, bufopts)
end
local lsp_imap = function(ptn, fn, bufopts)
    vim.keymap.set('i', ptn, fn, bufopts)
end

vim.lsp.handlers['textDocument/publishDiagnostics'] = vim.lsp.with(
    vim.lsp.diagnostic.on_publish_diagnostics,
    {
        virtual_text = false
    }
)

local opts = { noremap = true, silent = true }
lsp_nmap('<leader>e', vim.diagnostic.open_float, opts)
lsp_nmap('[d', vim.diagnostic.goto_prev, opts)
lsp_nmap(']d', vim.diagnostic.goto_next, opts)

local on_attach = function(client, bufnr)
    vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

    local bufopts = { noremap = true, silent = true, buffer = bufnr }
    lsp_nmap('gD', vim.lsp.buf.declaration, bufopts)
    lsp_nmap('gd', vim.lsp.buf.definition, bufopts)
    lsp_nmap('K', vim.lsp.buf.hover, bufopts)
    lsp_nmap('gi', vim.lsp.buf.implementation, bufopts)
    lsp_imap('<M-k>', vim.lsp.buf.signature_help, bufopts)
    lsp_nmap('<leader>D', vim.lsp.buf.type_definition, bufopts)
    lsp_nmap('<leader>r', vim.lsp.buf.rename, bufopts)
    lsp_nmap('gr', vim.lsp.buf.references, bufopts)
    lsp_nmap('<leader>F', vim.lsp.buf.formatting, bufopts)
end

local lsp_flags = {
    debounce_text_changes = 150,
}
local lsp = require('lspconfig')
local capabilities = require('cmp_nvim_lsp').update_capabilities(
    vim.lsp.protocol.make_client_capabilities()
)
local settings = {
    capabilities = capabilities,
    on_attach = on_attach
}
lsp.rust_analyzer.setup(settings)
lsp.luau_lsp.setup(settings)
lsp.clangd.setup(settings)
lsp.zls.setup(settings)

----------------------------------------
-- Cmp
----------------------------------------

local has_words_before = function()
    local line, col = unpack(vim.api.nvim_win_get_cursor(0))
    return col ~= 0
        and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]
            :sub(col, col)
            :match('%s') == nil
end

local feedkey = function(key, mode)
    vim.api.nvim_feedkeys(
        vim.api.nvim_replace_termcodes(key, true, true, true),
        mode,
        true
    )
end

local cmp = require('cmp')
cmp.setup({
    snippet = {
        expand = function(args)
            vim.fn['vsnip#anonymous'](args.body)
        end,
    },
    window = {
        completion = cmp.config.window.bordered(),
        documentation = cmp.config.window.bordered(),
    },
    mapping = {
        ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_next_item()
            elseif vim.fn['vsnip#available'](1) == 1 then
                feedkey('<Plug>(vsnip-expand-or-jump)', '')
            elseif has_words_before() then
                cmp.complete()
            else
                fallback()
            end
        end, { 'i', 's' }),

        ['<S-Tab>'] = cmp.mapping(function()
            if cmp.visible() then
                cmp.select_prev_item()
            elseif vim.fn['vsnip#jumpable'](-1) == 1 then
                feedkey('<Plug>(vsnip-jump-prev)', '')
            else
                fallback()
            end
        end, { 'i', 's' }),

        ['<M-n>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_next_item()
            else
                fallback()
            end
        end, { 'i', 's' }),

        ['<M-p>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_prev_item()
            else
                fallback()
            end
        end, { 'i', 's' }),

        ['<C-e>'] = cmp.mapping.abort(),
        ['<CR>'] = cmp.mapping.confirm({ select = true }),
    },
    sources = cmp.config.sources({
        { name = 'nvim_lsp' },
        { name = 'vsnip' },
        { name = 'nvim_lsp_signature_help' },
    }, {
        { name = 'buffer' },
    }),
    cmp.setup.cmdline(':', {
        sources = {
            { name = 'cmdline' }
        }
    }),
    cmp.setup.cmdline('/', {
        mapping = cmp.mapping.preset.cmdline(),
        sources = { { name = 'buffer' } }
    })
})

----------------------------------------
-- Autocmd
----------------------------------------

vim.api.nvim_create_autocmd('BufWritePre', {
    pattern = {'*.rs'},
    callback = vim.lsp.buf.formatting
})

----------------------------------------
-- Keymap
----------------------------------------

local map = function(mode, key, cmd)
    vim.api.nvim_set_keymap(mode, key, cmd, { noremap = true })
end
local nmap = function(key, cmd)
    map('n', key, cmd)
end
local imap = function(key, cmd)
    map('i', key, cmd)
end
local vmap = function(key, cmd)
    map('v', key, cmd)
end

imap('<M-BS>', '<C-w>')
nmap('<leader>f', '<cmd>Telescope find_files<cr>')
nmap('<leader>/', '<cmd>Telescope live_grep<cr>')
nmap('<leader>b', '<cmd>Telescope buffers<cr>')
nmap('<leader>s', '<cmd>Telescope lsp_document_symbols<cr>')
nmap('<leader>S', '<cmd>Telescope lsp_workspace_symbols<cr>')
nmap('<leader>t', '<cmd>Telescope<cr>')
nmap('<leader>q', '<cmd>bwipeout<cr>')
nmap('<leader>wj', '<cmd>wincmd j<cr>')
nmap('<leader>wk', '<cmd>wincmd k<cr>')
nmap('<leader>wh', '<cmd>wincmd h<cr>')
nmap('<leader>wl', '<cmd>wincmd l<cr>')
nmap('<leader>wq', '<cmd>wincmd q<cr>')
nmap('<leader>bd', '<cmd>bp<bar>sp<bar>bn<bar>bd!<cr>')
nmap('<leader>a', '<cmd>lua vim.lsp.buf.code_action()<cr>')
nmap('<leader>l', '$')
nmap('<leader>h', '^')
nmap('<leader>p', '"+p')
nmap('<leader>y', '"+y')
vmap('<leader>y', '"+y')
nmap('gl', '$')
nmap('gh', '^')
nmap('<M-}>', 'gt')
nmap('<M-{>', 'gT')
nmap('<Up>', '<C-y>')
nmap('<Down>', '<C-e>')
nmap('<M-j>', '<C-e>')
imap('<M-j>', '<C-e>')
nmap('<M-k>', '<C-y>')
imap('<M-k>', '<C-y>')
nmap('<M-;>', '<cmd>Commentary<cr>')
vmap('<M-;>', '<Plug>Commentary')
nmap('\\', '<cmd>noh<cr>')

