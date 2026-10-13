-- 插件管理：lazy.nvim（packer 已停止维护，lazy 在 mac / Linux 上行为一致）
-- 首次启动会自动 clone lazy.nvim 本体，之后用 :Lazy 管理其余插件

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.notify("正在安装 lazy.nvim ...", vim.log.levels.INFO, { title = "nvim" })
  local out = vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--branch=stable",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.notify("lazy.nvim 克隆失败，请检查网络 / git：\n" .. out, vim.log.levels.ERROR, { title = "nvim" })
  end
end

vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  ------------------------------------------------------------------
  -- 主题：最先加载
  ------------------------------------------------------------------
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    lazy = false,
    config = function()
      require("colorscheme")
    end,
  },

  ------------------------------------------------------------------
  -- 开机页面
  ------------------------------------------------------------------
  { "mhinz/vim-startify", lazy = false },

  ------------------------------------------------------------------
  -- 文件树（常驻，保证 ;; 第一次按下就能用）
  ------------------------------------------------------------------
  {
    "nvim-tree/nvim-tree.lua",
    lazy = false,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("plugin-config.nvim-tree")
    end,
  },

  ------------------------------------------------------------------
  -- 补全 / LSP（coc.nvim，必须常驻，懒加载会导致首次补全失效）
  ------------------------------------------------------------------
  {
    "neoclide/coc.nvim",
    branch = "release",
    lazy = false,
    config = function()
      require("plugin-config.coc-nvim")
    end,
  },

  ------------------------------------------------------------------
  -- 模糊搜索
  ------------------------------------------------------------------
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.8",
    lazy = false,
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("plugin-config.telescope")
    end,
  },

  ------------------------------------------------------------------
  -- 语法高亮 / 缩进
  ------------------------------------------------------------------
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("plugin-config.treesitter")
    end,
  },
}, {
  -- 插件根目录走 stdpath，mac / Linux 各存各的，互不干扰
  root = vim.fn.stdpath("data") .. "/lazy",
  defaults = { lazy = true },
  checker = { enabled = false }, -- 不做自动更新检查，没网时不卡顿
  git = {
    -- Linux 服务器 clone 慢 / 超时时的兜底
    timeout = 120,
  },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
