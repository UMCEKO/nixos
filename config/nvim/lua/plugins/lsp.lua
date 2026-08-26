-- Filename: lua/plugins/lsp.lua
-- This is a complete and corrected configuration for your LSP setup.

return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      -- These plugins automatically manage LSP server installations
      "mason-org/mason-lspconfig.nvim",
      "mason-org/mason.nvim",
    },
    opts = {
      servers = {
        ts_ls = {
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
        },
        postgres_lsp = {
          filetypes = { "sql", "pgsql", "postgres", "sql.dockerfile" },
          settings = {
            ["postgres-language-server"] = {},
          },
        },
        yamlls = {
          settings = {
            yaml = {
              -- 1. Enable the server's built-in schema store for all other files.
              schemaStore = {
                enable = true,
              },

              schemas = {
                -- 2. Your manual override for your specific file patterns.
                --    This takes precedence.
                ["https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/v1.27.0-standalone-strict/all.json"] = {
                  "deployment.yaml",
                  "kube/*",
                },
                ["https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json"] = "docker-compose.yaml",
                -- ArgoCD ApplicationSet
                ["https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/argoproj.io/applicationset_v1alpha1.json"] = "**/argocd/*.yaml",
              },
            },
          },
        },
      },
    },
  },
}
