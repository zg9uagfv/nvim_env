-- 跨平台 Neovim 配置入口（macOS / Linux 通用）
-- 目录：~/.config/nvim  （Linux 无 XDG_CONFIG_HOME 时同样是 $HOME/.config/nvim）

-- 1. 基础设置（内部会做平台探测与剪贴板适配）
require("basic")

-- 2. 插件（lazy.nvim 自动 bootstrap；主题在插件的 config 里设置）
require("plugins")

-- 3. 快捷键映射
require("keybindings")

-- 4. 兜底：万一 lazy 没装上，也要有可用的配色
if vim.g.colors_name == nil then
  pcall(vim.cmd, "colorscheme default")
end
