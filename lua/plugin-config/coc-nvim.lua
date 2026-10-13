local keyset = vim.keymap.set
local platform = require("platform")

-----------------------------------------------------------------------
-- node 定位：coc.nvim 要求 Node >= 22.15.0，而很多 Linux 发行版（比如
-- Ubuntu 24.04 自带 v18）不满足。这里按「版本号」而不是「能不能执行」来找：
--   1) PATH 里的 node 够新 → 交给 coc 自己用
--   2) 不够新 → 去 nvm / fnm / volta / homebrew 目录里找 >= 22 的
--   3) 都没有 → 提示，coc 会自己报版本错误
-----------------------------------------------------------------------
local MIN_NODE_MAJOR = 22

local function node_major(path)
  local ok, out = pcall(vim.fn.system, { path, "--version" })
  if not ok or vim.v.shell_error ~= 0 or type(out) ~= "string" then
    return nil
  end
  return tonumber(out:match("v?(%d+)"))
end

local function find_node()
  -- 1) PATH 里的已经够新
  if vim.fn.executable("node") == 1 then
    local v = node_major("node")
    if v and v >= MIN_NODE_MAJOR then
      return nil
    end
  end

  -- 2) 常见安装目录里找 >= 22 的
  local patterns = {
    vim.fn.expand("~/.nvm/versions/node/*/bin/node"),
    vim.fn.expand("~/.local/share/fnm/node-versions/*/installation/bin/node"),
    vim.fn.expand("~/.volta/bin/node"),
    "/opt/homebrew/bin/node",
    "/usr/local/bin/node",
  }
  for _, pattern in ipairs(patterns) do
    local matches = vim.fn.glob(pattern, false, true)
    for _, candidate in ipairs(matches) do
      if vim.fn.executable(candidate) == 1 then
        local v = node_major(candidate)
        if v and v >= MIN_NODE_MAJOR then
          return candidate
        end
      end
    end
  end
  return nil
end

local node_path = find_node()
if node_path then
  vim.g.coc_node_path = node_path
else
  local current = vim.fn.executable("node") == 1 and node_major("node") or nil
  if not current or current < MIN_NODE_MAJOR then
    vim.defer_fn(function()
      vim.notify(
        "coc.nvim 需要 Node >= " .. MIN_NODE_MAJOR .. "，当前是 v" .. tostring(current) .. "\n用 nvm 装一个：nvm install 22",
        vim.log.levels.WARN,
        { title = "coc.nvim" }
      )
    end, 1500)
  end
end

-----------------------------------------------------------------------
-- 开机自动安装的 coc 扩展（缺网时只会 warn，不影响启动）
-----------------------------------------------------------------------
vim.g.coc_global_extensions = {
  "coc-json",
  "coc-toml",
  "coc-snippets",
  "coc-marketplace",
  "coc-clangd",
  "coc-rust-analyzer",
  "coc-prettier",
}

-----------------------------------------------------------------------
-- 自动补全
-----------------------------------------------------------------------
function _G.check_back_space()
  local col = vim.fn.col(".") - 1
  return col == 0 or vim.fn.getline("."):sub(col, col):match("%s") ~= nil
end

local opts = { silent = true, noremap = true, expr = true, replace_keycodes = false }
keyset("i", "<TAB>", 'coc#pum#visible() ? coc#pum#next(1) : v:lua.check_back_space() ? "<TAB>" : coc#refresh()', opts)
keyset("i", "<S-TAB>", [[coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"]], opts)
keyset("i", "<cr>", [[coc#pum#visible() ? coc#pum#confirm() : "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"]], opts)

-----------------------------------------------------------------------
-- 跳转与诊断（coc 0.0.82 起移除了默认映射，必须手动接）
-- <Plug> 是递归映射，这里必须 remap = true
-----------------------------------------------------------------------
local plugopt = { silent = true, remap = true }

keyset("n", "gd", "<Plug>(coc-definition)", plugopt)
keyset("n", "gD", "<Plug>(coc-declaration)", plugopt)
keyset("n", "gi", "<Plug>(coc-implementation)", plugopt)
keyset("n", "gy", "<Plug>(coc-type-definition)", plugopt)
keyset("n", "gr", "<Plug>(coc-references)", plugopt)

-- 悬浮文档：不用跳也能看函数签名
keyset("n", "K", ":call CocActionAsync('doHover')<CR>", { silent = true })

-- 诊断：上下跳转 + 全部汇总
keyset("n", "[d", "<Plug>(coc-diagnostic-prev)", plugopt)
keyset("n", "]d", "<Plug>(coc-diagnostic-next)", plugopt)
keyset("n", "<leader>d", ":<C-u>CocList diagnostics<CR>", { silent = true, noremap = true })

-- 重命名符号
keyset("n", "<leader>rn", "<Plug>(coc-rename)", plugopt)

-- 代码修复动作
keyset("n", "<leader>a", "<Plug>(coc-codeaction-cursor)", plugopt)

-----------------------------------------------------------------------
-- 格式化：优先 prettier（装了 coc-prettier 且本地有 prettier 时），
-- 否则退回 nvim 内置 LSP 格式化，避免按了没反应或报错
-----------------------------------------------------------------------
local function has_coc_extension(name)
  if vim.fn.exists("*CocAction") == 0 then
    return false
  end
  local ok, stats = pcall(function()
    return vim.fn.CocAction("extensionStats")
  end)
  if not ok or type(stats) ~= "table" then
    return false
  end
  for _, ext in ipairs(stats) do
    if ext.id == name then
      return true
    end
  end
  return false
end

_G.smart_format = function()
  if has_coc_extension("coc-prettier") then
    vim.cmd("CocCommand prettier.forceFormatDocument")
    return
  end
  if #vim.lsp.get_clients({ bufnr = 0 }) > 0 then
    vim.lsp.buf.format({ async = false })
    return
  end
  vim.notify("没有可用的格式化器（可 :CocInstall coc-prettier 并安装 prettier）", vim.log.levels.WARN, { title = "nvim" })
end

keyset("n", "<leader>f", _G.smart_format, { silent = true, desc = "格式化文档" })

-----------------------------------------------------------------------
-- 跨平台：把内容推到「宿主」剪贴板（SSH 场景也能用）
-----------------------------------------------------------------------
keyset("n", "<leader>y", function()
  platform.yank_to_system()
end, { silent = true, desc = "复制到系统剪贴板 (OSC 52)" })
keyset("v", "<leader>y", function()
  platform.yank_to_system()
end, { silent = true, desc = "复制到系统剪贴板 (OSC 52)" })
