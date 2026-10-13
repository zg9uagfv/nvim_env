-- catppuccin 主题：setup 必须在 colorscheme 之前，否则集成项不生效

local flavour = vim.env.NVIM_THEME or "mocha"

require("catppuccin").setup({
  flavour = flavour,
  background = { light = "latte", dark = "mocha" },
  integrations = {
    nvimtree = true,
    telescope = true,
    treesitter = true,
    coc_nvim = true,
    native_lsp = {
      enabled = true,
      underlines = {
        errors = { "undercurl" },
        hints = { "undercurl" },
        info = { "undercurl" },
        warnings = { "undercurl" },
      },
    },
  },
})

-- 真彩色：catppuccin 必须开启，且要在 colorscheme 之前设置
vim.opt.termguicolors = true
vim.opt.background = "dark"

-- 换主题不用改代码：NVIM_THEME=latte nvim
local ok = pcall(vim.cmd, "colorscheme catppuccin-" .. flavour)
if not ok then
  vim.cmd([[ colorscheme catppuccin-mocha ]])
end
