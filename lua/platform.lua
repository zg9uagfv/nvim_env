-- 平台探测与跨平台适配层
-- 目标：一份配置同时跑在 macOS 和 Linux（含 WSL），不写死任何路径

local uv = vim.uv or vim.loop
local uname = uv.os_uname()

local M = {
  os = uname.sysname, -- "Darwin" / "Linux"
  is_mac = uname.sysname == "Darwin",
  is_linux = uname.sysname == "Linux",
  is_wsl = false,
}

-- Linux 下再细分是不是 WSL（/proc/version 里带 microsoft）
if M.is_linux and vim.fn.filereadable("/proc/version") == 1 then
  local ok, lines = pcall(vim.fn.readfile, "/proc/version", "", 1)
  if ok and lines and lines[1] then
    M.is_wsl = lines[1]:lower():find("microsoft") ~= nil
  end
end

function M.executable(name)
  return vim.fn.executable(name) == 1
end

-- 本机有没有可用的系统剪贴板工具
function M.has_clipboard_tool()
  return M.executable("pbcopy") -- macOS
    or M.executable("wl-copy") -- Wayland
    or M.executable("xclip") -- X11
    or M.executable("xsel") -- X11
    or M.executable("clip.exe") -- WSL
    or M.executable("termux-clipboard-set") -- Termux
end

-- 有没有图形会话（决定 Linux 上能不能用系统剪贴板）
function M.has_display()
  return (vim.env.DISPLAY ~= nil and vim.env.DISPLAY ~= "")
    or (vim.env.WAYLAND_DISPLAY ~= nil and vim.env.WAYLAND_DISPLAY ~= "")
end

-- SSH 远程会话（剪贴板走不了本地工具，只能靠终端 OSC 52）
function M.is_remote()
  return (vim.env.SSH_TTY ~= nil and vim.env.SSH_TTY ~= "")
    or (vim.env.SSH_CONNECTION ~= nil and vim.env.SSH_CONNECTION ~= "")
end

-- stdpath 兼容：state 是 nvim 0.11+ 才有的，旧版本回落到 cache
function M.stdpath(kind)
  local ok, path = pcall(vim.fn.stdpath, kind)
  if ok and path and path ~= "" then
    return path
  end
  return vim.fn.stdpath("cache")
end

-----------------------------------------------------------------------
-- OSC 52：通过终端转义序列把内容写进「宿主机器」的剪贴板
-- 纯 Lua 实现，不依赖任何外部程序，mac/Linux/WSL/SSH 通用
-----------------------------------------------------------------------

local b64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

-- LuaJIT 是 Lua 5.1，没有位运算符，用算术实现
local function b64encode(data)
  local out = {}
  for i = 1, #data, 3 do
    local c1, c2, c3 = data:byte(i, i + 2)
    local n = c1 * 65536 + (c2 or 0) * 256 + (c3 or 0)
    local i1 = math.floor(n / 262144)
    local i2 = math.floor(n / 4096) % 64
    local i3 = c2 and math.floor(n / 64) % 64 or 64
    local i4 = c3 and n % 64 or 64
    out[#out + 1] = b64chars:sub(i1 + 1, i1 + 1)
      .. b64chars:sub(i2 + 1, i2 + 1)
      .. (i3 == 64 and "=" or b64chars:sub(i3 + 1, i3 + 1))
      .. (i4 == 64 and "=" or b64chars:sub(i4 + 1, i4 + 1))
  end
  return table.concat(out)
end

function M.osc52(text)
  if text == nil or text == "" then
    return
  end
  local osc = "\27]52;c;" .. b64encode(text) .. "\7"
  -- 写 stderr：既连着 tty，又不会和 nvim 的重绘输出打架
  local ok = pcall(function()
    vim.fn.chansend(vim.v.stderr, osc)
  end)
  if not ok then
    local tty = io.open("/dev/tty", "a")
    if tty then
      tty:write(osc)
      tty:close()
    end
  end
end

-- 什么时候需要 OSC 52 兜底
function M.needs_osc52()
  if M.is_remote() then
    return true
  end
  if M.is_linux and not M.has_display() then
    return true
  end
  return false
end

-- 统一的剪贴板初始化
function M.setup_clipboard()
  -- macOS / WSL 直接挂系统剪贴板；
  -- Linux 只有在有图形会话 + 有剪贴板工具时才挂，否则 nvim 会每次 yank 都徒劳调用外部程序
  if M.is_mac then
    vim.opt.clipboard:append("unnamedplus")
  elseif M.is_wsl then
    vim.opt.clipboard:append("unnamedplus")
  elseif M.is_linux and M.has_display() and M.has_clipboard_tool() then
    vim.opt.clipboard:append("unnamedplus")
  end

  -- 远程 SSH / 无图形会话：yank 时额外发一份 OSC 52
  if M.needs_osc52() then
    local group = vim.api.nvim_create_augroup("cross_platform_osc52", { clear = true })
    vim.api.nvim_create_autocmd("TextYankPost", {
      group = group,
      callback = function()
        if vim.v.event.operator ~= "y" then
          return
        end
        local ok, content = pcall(vim.fn.getreg, '"')
        if ok then
          M.osc52(content)
        end
      end,
    })
  end
end

-- 手动把当前行 / 选区推到宿主剪贴板（映射在 keybindings.lua 里）
function M.yank_to_system()
  local mode = vim.fn.mode()
  local content
  if mode == "v" or mode == "V" or mode == "\22" then
    vim.cmd([[normal! "zy]])
    content = vim.fn.getreg("z")
  else
    content = vim.fn.getline(".")
  end
  M.osc52(content)
  vim.notify("已复制到系统剪贴板（OSC 52）", vim.log.levels.INFO, { title = "nvim" })
end

-- 依赖体检：:checkhealth 之外，快速列出缺了什么
function M.report_missing_deps()
  local missing = {}
  local required = { "git", "curl" } -- 装插件用
  local optional = { "rg", "fd", "node", "gcc", "clangd" }

  for _, name in ipairs(required) do
    if not M.executable(name) then
      table.insert(missing, name .. " (必需)")
    end
  end
  for _, name in ipairs(optional) do
    if not M.executable(name) then
      table.insert(missing, name .. " (可选)")
    end
  end

  if #missing > 0 then
    vim.notify("缺少依赖: " .. table.concat(missing, ", "), vim.log.levels.WARN, { title = "nvim 环境" })
  end
  return missing
end

return M
