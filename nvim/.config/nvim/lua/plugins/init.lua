vim.pack.add({
  { src = "https://github.com/rmagatti/auto-session" },
  { src = "https://github.com/nvim-lua/plenary.nvim" },
  { src = "https://github.com/MunifTanjim/nui.nvim" },
  { src = "https://github.com/nvim-tree/nvim-web-devicons" },
  { src = "https://github.com/nvim-neo-tree/neo-tree.nvim" },
  {
    src = "https://github.com/saghen/blink.cmp",
    version = "v1.10.2",
  },
  {
    src = "https://github.com/nvim-treesitter/nvim-treesitter",
  },
  {
    src = "https://github.com/ibhagwan/fzf-lua",
  },
  {
    src = "https://github.com/lewis6991/gitsigns.nvim",
  },
  {
    src = "https://github.com/folke/tokyonight.nvim",
  },
  {
    src = "https://github.com/nvim-lualine/lualine.nvim",
  },
  {
    src = "https://codeberg.org/mfussenegger/nvim-lint",
  },
  {
    src = "https://github.com/mfussenegger/nvim-dap",
  },
  {
    src = "https://github.com/stevearc/conform.nvim",
  },
})

vim.cmd.colorscheme("tokyonight-night")

require("auto-session").setup({
  close_filetypes_on_save = { "neo-tree" },
  post_restore_cmds = {
    "Neotree action=show source=filesystem position=left",
  },
})

require("blink.cmp").setup({
  sources = {
    default = { "lsp" },
  },
  signature = {
    -- disabling because its a bit noisy and you cant select which overload
    enabled = false,
  },
})

-- conform
require("conform").setup({
  formatters_by_ft = {
    javascript = { "prettier" },
    javascriptreact = { "prettier" },
    typescript = { "prettier" },
    typescriptreact = { "prettier" },
  },
})


-- DAP
local dap = require("dap")
vim.fn.sign_define("DapBreakpoint", {
  text = "B",
  texthl = "DiagnosticError",
})
vim.fn.sign_define("DapBreakpointRejected", {
  text = "R",
  texthl = "DiagnosticError",
})

vim.fn.sign_define("DapStopped", {
  text = "→",
  texthl = "DiagnosticWarn",
  linehl = "debugPC",
})


-- DAP: GDB 
dap.adapters.gdb = {
  type = "executable",
  command = "gdb",
  args = { "--interpreter=dap" },
}

-- C++ launch config
dap.configurations.cpp = {
  {
    name = "Launch",
    type = "gdb",
    request = "launch",
    program = function()
      return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
    end,
    cwd = "${workspaceFolder}",
    stopAtBeginningOfMainSubprogram = false,
  },
}


require("neo-tree").setup({
  default_component_configs = {
    git_status = {
      symbols = {
        added = "A",
        deleted = "D",
        modified = "M",
        renamed = "R",
        untracked = "?",
        ignored = "I",
        unstaged = "U",
        staged = "S",
        conflict = "C",
      },
    },
  },
  filesystem = {
    follow_current_file = {
      enabled = true,
    },
    filtered_items = {
      visible = false,
      hide_dotfiles = false,
      hide_by_name = {
        ".git",
        ".cache",
      },
    },
  },
})

require("nvim-treesitter").install({
  "c",
  "cpp",
  "cmake",
  "javascript",
  "lua",
  "markdown",
  "markdown_inline",
  "powershell",
  "toml",
  "tsx",
  "typescript",
  "yaml",
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = {
    "c",
    "cpp",
    "cmake",
    "javascript",
    "javascriptreact",
    "lua",
    "ps1",
    "typescript",
    "typescriptreact",
  },
  callback = function()
    vim.treesitter.start()
  end,
})

require("fzf-lua").setup({
  grep = {
    hidden = true,
  },
})

require("lualine").setup()

-- Linting
local lint = require("lint")

lint.linters_by_ft = {
  javascript = { "eslint" },
  javascriptreact = { "eslint" },
  typescript = { "eslint" },
  typescriptreact = { "eslint" },
}

vim.api.nvim_create_autocmd("BufWritePost", {
  group = vim.api.nvim_create_augroup("eslint", { clear = true }),
  pattern = { "*.js", "*.jsx", "*.ts", "*.tsx" },
  callback = function(args)
    local root = vim.fs.root(args.buf, "eslint.config.js")
    if root then
      lint.try_lint(nil, { cwd = root })
    end
  end,
})

