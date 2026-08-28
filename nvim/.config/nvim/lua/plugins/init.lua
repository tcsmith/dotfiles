vim.pack.add({
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
})

vim.cmd.colorscheme("tokyonight-night")

require("blink.cmp").setup({
  sources = {
    default = { "lsp" },
  },
  signature = {
    -- disabling because its a bit noisy and you cant select which overload
    enabled = false,
  },
})

require("neo-tree").setup({
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
  "lua",
  "markdown",
  "markdown_inline",
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "c", "cpp", "cmake", "lua" },
  callback = function()
    vim.treesitter.start()
  end,
})

require("lualine").setup()
