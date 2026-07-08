return {
  {
    "tpope/vim-dotenv",
  },

  {
    "tpope/vim-dotenv",
    -- The 'config' function for this plugin itself
    config = function()
      -- vim.g.dotenv_file = vim.fn.expand("~/.config/my_project/.env") -- Example: If you customize global dotenv behavior

      -- Create the autocmd directly within this plugin's config function
      vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
        group = vim.api.nvim_create_augroup("DotenvLoader", { clear = true }),
        pattern = {
          -- Add all filetypes relevant to your microservices
          "*.sql",
          "*.go",
          "*.js",
          "*.ts",
          "*.rs",
          "*.py",
          "*.rb",
          "*.php",
          "docker-compose.yml",
          "Dockerfile", -- Often have associated .env files
          -- You might also want to include common config files, e.g., "*.json", "*.yaml", etc.
        },
        callback = function()
          local current_file = vim.api.nvim_buf_get_name(0)
          if current_file == "" then
            return
          end

          local current_dir = vim.fn.fnamemodify(current_file, ":p:h")
          local env_file_path = vim.fn.findfile(".env", current_dir .. ";")

          if env_file_path ~= "" then
            local current_database_url = vim.env.DATABASE_URL
            local status, err = pcall(vim.cmd, "Dotenv " .. env_file_path)
            if status then
              -- print("Loaded .env from: " .. env_file_path) -- Uncomment for debug feedback
              -- This print message might get annoying in daily use, so keep it for debugging only.
            else
              vim.notify("Failed to load .env: " .. err, vim.log.levels.ERROR)
            end
          end
        end,
      })
    end,
  },
}
