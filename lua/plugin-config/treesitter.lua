-- nvim-treesitter 适配层
--
-- 这个插件在 v0.9.3 之后有一次破坏性改动：
--   旧版（<= v0.9.3）：require('nvim-treesitter.configs').setup({ highlight = ..., indent = ... })
--   新版（main 分支）  ：只负责 parser 安装，setup() 几乎只剩 install_dir 选项，
--                        高亮 / 缩进交给 nvim 0.11+ 内置的 vim.treesitter
-- 两台机器上的 nvim 版本可能不同，这里按实际装到的版本自动二选一。

local langs = {
  "lua",
  "vim",
  "vimdoc",
  "query",
  "bash",
  "python",
  "json",
  "toml",
  "markdown",
  "c",
  "cpp",
  "rust",
}

-----------------------------------------------------------------------
-- 1) 旧版：走 configs.setup
-----------------------------------------------------------------------
local ok_old, configs = pcall(require, "nvim-treesitter.configs")
if ok_old then
  configs.setup({
    ensure_installed = langs,
    sync_install = false,
    auto_install = false, -- 打开没装的语言时不自动下载（没网时会卡）
    highlight = {
      enable = true,
      additional_vim_regex_highlighting = false,
    },
    indent = { enable = true },
  })
  return
end

-----------------------------------------------------------------------
-- 2) 新版（main）：只管 parser，高亮由 nvim 原生 treesitter 提供
-----------------------------------------------------------------------
local ok_new, ts = pcall(require, "nvim-treesitter")
if not ok_new then
  vim.notify("nvim-treesitter 未正确加载，跳过配置", vim.log.levels.WARN, { title = "nvim" })
  return
end

ts.setup({})

-- 提示还缺哪些 parser（不自动下载：离线 / GitHub 不通时下载会把启动卡住）
vim.defer_fn(function()
  local installed_map = {}
  local ok, installed = pcall(function()
    return ts.get_installed("parsers")
  end)
  if ok and type(installed) == "table" then
    for _, name in ipairs(installed) do
      installed_map[name] = true
    end
  end

  local missing = {}
  for _, name in ipairs(langs) do
    if not installed_map[name] then
      table.insert(missing, name)
    end
  end

  if #missing > 0 then
    vim.notify(
      "缺少 treesitter parser: " .. table.concat(missing, " ") .. "\n执行 :TSInstall " .. table.concat(missing, " "),
      vim.log.levels.INFO,
      { title = "nvim-treesitter" }
    )
  end
end, 3000)
