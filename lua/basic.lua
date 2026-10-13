-- 基础设置：与平台无关的部分放这里，平台相关的走 platform.lua

local platform = require("platform")

vim.opt.encoding = "UTF-8"
vim.opt.fileencoding = "utf-8"
-- 优先 unix 换行，遇到 dos 文件也能正确识别
vim.opt.fileformats = "unix,dos"

-- 显示行号
vim.opt.number = true
vim.opt.relativenumber = true

-- 高亮所在行
vim.opt.cursorline = true

-- hjkl 移动时光标周围保留 10 行
vim.opt.scrolloff = 10
vim.opt.sidescrolloff = 10

-- 空格替代 tab
vim.opt.expandtab = true

-- 缩进 2 个空格，等于一个 Tab
vim.opt.tabstop = 2
vim.opt.softtabstop = 2

-- >> << 时移动长度
vim.opt.shiftround = true
vim.opt.shiftwidth = 2

-- 补全最多显示 10 行
vim.opt.pumheight = 10

-- 等待键盘连击时间
vim.opt.timeoutlen = 500

-- 系统剪贴板（macOS / Linux 图形会话自动挂，SSH 场景走 OSC 52）
platform.setup_clipboard()

-------------------------------
-- coc.nvim 相关
-------------------------------

-- coc 官方强制要求 300ms，默认 4000 会让诊断和悬浮慢半拍
vim.opt.updatetime = 300

-------------------------------
-- 显示
-------------------------------

-- 开启真彩色（catppuccin 主题必须）
vim.opt.termguicolors = true

-- 固定显示符号列，否则诊断图标出现时正文会左右抖动
vim.opt.signcolumn = "yes"

-------------------------------
-- 搜索
-------------------------------

-- 小写智能忽略大小写，含大写则精确匹配
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.incsearch = true
vim.opt.hlsearch = true

-------------------------------
-- 持久化与临时文件
-------------------------------

-- 关闭再打开文件仍可 undo
vim.opt.undofile = true

-- 目录统一放在 stdpath 下，并主动创建（不同 nvim 版本 / 不同 OS 都不会踩坑）
local undo_dir = platform.stdpath("state") .. "/undo"
vim.fn.mkdir(undo_dir, "p")
vim.opt.undodir = undo_dir

-- 不生成 swap 文件（不然经常弹 "found a swap file"）
vim.opt.swapfile = false

-------------------------------
-- 分屏与窗口
-------------------------------

-- 分屏方向符合直觉：:vsp 在右边、:sp 在下边
vim.opt.splitright = true
vim.opt.splitbelow = true

-- 隐藏模式：切换 buffer 时不强制保存
vim.opt.hidden = true

-- 不响铃
vim.opt.belloff = "all"

-- 首次进入时提示缺失的可选依赖（只在本地非 SSH 时提示，避免打扰远程开发）
if not platform.is_remote() then
  vim.defer_fn(function()
    platform.report_missing_deps()
  end, 2000)
end
