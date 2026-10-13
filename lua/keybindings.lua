-- Modes
--   normal_mode = "n",
--   insert_mode = "i",
--   visual_mode = "v",
--   visual_block_mode = "x",
--   term_mode = "t",
--   command_mode = "c",

vim.g.mapleader = ";"

local opt = { noremap = true, silent = true }
local keyset = vim.keymap.set

-----------------------------------------------------------------------
-- 文件树
-----------------------------------------------------------------------
keyset("n", "<leader><leader>", ":NvimTreeToggle<CR>", opt)

-----------------------------------------------------------------------
-- 搜索（telescope）
-----------------------------------------------------------------------
local telescope_ok, builtin = pcall(require, "telescope.builtin")
if telescope_ok then
  keyset("n", "<leader>p", builtin.find_files, opt)
  keyset("n", "<leader>fg", builtin.live_grep, opt)
  keyset("n", "<leader>fb", builtin.buffers, opt)
end

-----------------------------------------------------------------------
-- 窗格快捷键
-----------------------------------------------------------------------
-- 垂直分隔
keyset("n", "<leader>v", ":vsp<CR>", opt)
-- 水平分隔
keyset("n", "<leader>sh", ":sp<CR>", opt)
-- 关闭当前
keyset("n", "<leader>sc", "<C-w>c", opt)
-- 关闭其他
keyset("n", "<leader>so", "<C-w>o", opt)

-- <leader> + hjkl 窗格之间跳转
keyset("n", "<leader>h", "<C-w>h", opt)
keyset("n", "<leader>j", "<C-w>j", opt)
keyset("n", "<leader>k", "<C-w>k", opt)
keyset("n", "<leader>l", "<C-w>l", opt)

-- 上下滚动浏览
keyset("n", "<C-j>", "5j", opt)
keyset("n", "<C-k>", "5k", opt)

-- 连续缩进
keyset("v", "<", "<gv", opt)
keyset("v", ">", ">gv", opt)

-- 退出：qq 让给「录制宏」，强退用 leader（避免 ;q 前缀冲突导致 500ms 延迟）
keyset("n", "<leader>q", ":qa!<CR>", opt)
keyset("n", "<leader>Q", ":q!<CR>", opt)

-- 选中内容前后加引号
keyset("v", "<leader>'", ":s/\\%V\\(\\w\\+\\)/'\\1'<CR>", opt)
keyset("v", '<leader>"', ':s/\\%V\\(\\w\\+\\)/"\\1"<CR>', opt)

-- 自动补全括号（nvim-autopairs 会影响 coc 的回车确认，这里保持手写映射）
keyset("i", "{", "{  }<LEFT><LEFT>", opt)
keyset("i", "(", "(  )<LEFT><LEFT>", opt)
keyset("i", "[", "[  ]<LEFT><LEFT>", opt)
keyset("i", "'", "''<LEFT>", opt)
keyset('i', '"', '""<LEFT>', opt)

-----------------------------------------------------------------------
-- buffer 之间切换
-- 注意：不要用 <Tab> 做这件事！Tab 等价于 <C-i>，
-- 一旦占用会破坏 jumplist 的前进功能（Ctrl-i）
-----------------------------------------------------------------------
keyset("n", "]b", ":bnext<CR>", opt)
keyset("n", "[b", ":bprevious<CR>", opt)
keyset("n", "<leader>bl", ":buffers<CR>", opt) -- 列出所有 buffer
keyset("n", "<leader>bd", ":bd<CR>", opt) -- 关掉当前 buffer
keyset("n", "<leader>bk", ":bd!<CR>", opt) -- 强制关（有未保存改动时）

-----------------------------------------------------------------------
-- 编辑习惯
-----------------------------------------------------------------------
-- 粘贴时不覆盖寄存器（p 之后继续 p 不会串味）
keyset("x", "<leader>p", [["_dP]], opt)

-- 保存到一半发现忘了 sudo（Linux 常用；macOS 同理）
keyset("c", "w!!", "w !sudo tee > /dev/null %", opt)

-- 快速清掉搜索高亮
keyset("n", "<ESC>", ":nohlsearch<CR>", opt)

-----------------------------------------------------------------------
-- 跨平台便利
-----------------------------------------------------------------------
-- 编辑 / 重载配置文件（mac 与 Linux 路径都由 stdpath 推导，不写死）
keyset("n", "<leader>ev", function()
  vim.cmd("edit " .. vim.fn.stdpath("config") .. "/init.lua")
end, opt)

keyset("n", "<leader>sv", function()
  vim.cmd("source $MYVIMRC")
  vim.notify("配置已重载", vim.log.levels.INFO, { title = "nvim" })
end, opt)

-- 在文件树 / 终端打开当前文件所在目录（mac 用 open，Linux 用 xdg-open）
keyset("n", "<leader>od", function()
  local dir = vim.fn.expand("%:p:h")
  if dir == "" then
    dir = vim.fn.getcwd()
  end
  local opener = (vim.fn.has("mac") == 1 or vim.fn.executable("open") == 1) and "open"
    or (vim.fn.executable("xdg-open") == 1 and "xdg-open" or nil)
  if opener then
    vim.fn.jobstart({ opener, dir }, { detach = true })
  else
    vim.notify("没有找到 open / xdg-open", vim.log.levels.WARN, { title = "nvim" })
  end
end, opt)
