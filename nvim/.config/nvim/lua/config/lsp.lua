vim.lsp.config("clangd", {
  cmd = { "clangd" },
  filetypes = { "c", "cpp" },
  root_markers = {
    ".clangd",
    ".git",
  },
  capabilities = require("blink.cmp").get_lsp_capabilities(),
})

vim.lsp.enable("clangd")

vim.lsp.config("lua_ls", {
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  root_markers = { ".luarc.json", ".luarc.jsonc", ".git" },

  settings = {
    Lua = {
      runtime = {
        version = "LuaJIT",
      },
      diagnostics = {
        globals = { "vim" },
      },
      workspace = {
        library = {
          vim.env.VIMRUNTIME,
        },
      },
    },
  },
})

vim.lsp.enable("lua_ls")

vim.lsp.config("neocmake", {
  cmd = { "neocmakelsp", "stdio" },
  filetypes = { "cmake" },
  root_markers = { ".git" },
  capabilities = require("blink.cmp").get_lsp_capabilities(),
})

vim.lsp.enable("neocmake")

vim.lsp.config("basedpyright", {
  cmd = { "basedpyright-langserver", "--stdio" },
  filetypes = { "python" },
  root_markers = {
    "pyproject.toml",
    ".git",
  },
  capabilities = require("blink.cmp").get_lsp_capabilities(),
})

vim.lsp.enable("basedpyright")

vim.lsp.config("typescript_ls", {
  cmd = { "typescript-language-server", "--stdio" },
  filetypes = {
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
  },
  root_markers = {
    "tsconfig.json",
    "jsconfig.json",
    "package.json",
    ".git",
  },
  capabilities = require("blink.cmp").get_lsp_capabilities(),
})

vim.lsp.enable("typescript_ls")


-- PowerShell
local powershell_es_path =
  vim.fs.joinpath(vim.fn.stdpath("data"), "powershell-editor-services")

local powershell_es_start_script =
  vim.fs.joinpath(
    powershell_es_path,
    "PowerShellEditorServices",
    "Start-EditorServices.ps1"
  )

local powershell_es_session =
  vim.fs.joinpath(vim.fn.stdpath("state"), "powershell_es.session.json")

vim.lsp.config("powershell_es", {
  cmd = {
    "pwsh",
    "-NoLogo",
    "-NoProfile",
    "-Command",
    string.format(
      "& '%s' -BundledModulesPath '%s' -SessionDetailsPath '%s' -Stdio -LogLevel Error",
      powershell_es_start_script,
      powershell_es_path,
      powershell_es_session
    ),
  },
  filetypes = { "ps1" },
  root_markers = {
    "PSScriptAnalyzerSettings.psd1",
    ".git",
  },
  workspace_required = false,
  capabilities = require("blink.cmp").get_lsp_capabilities(),
})

vim.lsp.enable("powershell_es")
