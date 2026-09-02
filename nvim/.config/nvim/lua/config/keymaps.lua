vim.g.mapleader = " "
vim.g.maplocalleader = " "

local map = vim.keymap.set

-- Clear search highlighting
map("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Better window navigation
map("n", "<C-h>", "<C-w>h")
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")
map("n", "<C-l>", "<C-w>l")

-- file tree
map("n", "<leader>e", "<cmd>Neotree toggle<CR>", { desc = "Toggle file explorer" })

-- lsp
map("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
map("n", "gD", vim.lsp.buf.declaration, { desc = "Go to declaration" })
map("n", "gr", vim.lsp.buf.references, { desc = "Find references" })
map("n", "K", vim.lsp.buf.hover, { desc = "Hover documentation" })
map("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename symbol" })
map("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code action" })

-- FzfLua
map("n", "<leader>ff", "<cmd>FzfLua files<cr>", { desc = "Find files", })
map("n", "<leader>fg", "<cmd>FzfLua live_grep<cr>", { desc = "Find text", })
map("n", "<leader>fb", "<cmd>FzfLua buffers<cr>", { desc = "Find buffers", })

-- Diagnostics
map("n", "<leader>dc", vim.diagnostic.open_float, { desc = "Diagnostic at cursor", })
map("n", "<leader>df", "<cmd>FzfLua diagnostics_document<cr>", { desc = "Diagnostics in current file", })
map("n", "<leader>do", "<cmd>FzfLua diagnostics_workspace<cr>", { desc = "Diagnostics in open files", })

-- DAP
map("n", "<leader>xc", "<cmd>DapContinue<cr>", { desc = "Debug: Start/Continue" })
map("n", "<leader>xs", "<cmd>DapTerminate<cr>", { desc = "Debug: Stop" })
map("n", "<leader>xb", "<cmd>DapToggleBreakpoint<cr>", { desc = "Debug: Toggle breakpoint" })
map("n", "<leader>xo", "<cmd>DapStepOver<cr>", { desc = "Debug: Step over" })
map("n", "<leader>xi", "<cmd>DapStepInto<cr>", { desc = "Debug: Step into" })
map("n", "<leader>xu", "<cmd>DapStepOut<cr>", { desc = "Debug: Step out" })

vim.keymap.set("n", "<leader>xh", function()
  require("dap.ui.widgets").hover()
end, { desc = "Debug: Hover" })

vim.api.nvim_create_autocmd("FileType", {
  pattern = "dap-float",
  callback = function(event)
    vim.keymap.set("n", "q", "<cmd>close<cr>", {
      buffer = event.buf,
      silent = true,
    })
  end,
})

-- Git
map("n", "<leader>ghp", "<cmd>Gitsigns preview_hunk<cr>", { desc = "Preview Git hunk", })
map("n", "<leader>gd", function()
  if vim.wo.diff then
    vim.cmd.tabclose()
    return
  end

  vim.cmd.tabnew("%")
  require("gitsigns").diffthis()
end, {
desc = "Toggle Git diff",
})
