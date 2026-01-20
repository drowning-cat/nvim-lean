vim.g.mapleader = " "

vim.o.number = true
vim.o.relativenumber = true

vim.o.signcolumn = "yes"

vim.o.updatetime = 250
vim.o.timeoutlen = 300

vim.o.splitbelow = true
vim.o.splitright = true
vim.o.tabclose = "uselast"

vim.o.confirm = true

vim.o.breakindent = true
vim.o.wrap = false

vim.o.expandtab = true
vim.o.tabstop = 4
vim.o.shiftwidth = 2
vim.o.softtabstop = -1

vim.o.foldmethod = "indent"
vim.o.foldtext = ""
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99
vim.o.foldnestmax = 10

vim.o.undofile = true
vim.o.undolevels = 10000

vim.o.ignorecase = true
vim.o.smartcase = true

vim.opt.iskeyword:append("-")

vim.o.list = true
vim.o.listchars = "tab:▷ ,trail:·,nbsp:○"

vim.o.spell = true
vim.o.spelllang = "en_us,ru"
vim.o.spelloptions = "camel"

vim.opt.backup = true
vim.opt.backupdir = vim.fn.stdpath("state") .. "/backup"
