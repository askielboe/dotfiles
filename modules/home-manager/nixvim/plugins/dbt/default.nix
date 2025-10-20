{
  programs.nixvim = {
    extraConfigLua = ''
      local dbt_namespace = vim.api.nvim_create_namespace('dbt_parse')

      local function run_dbt_parse()
        local bufnr = vim.api.nvim_get_current_buf()
        local filepath = vim.api.nvim_buf_get_name(bufnr)

        if not filepath:match('models/.*%.yml$') and not filepath:match('models/.*%.yaml$') then
          return
        end

        vim.diagnostic.reset(dbt_namespace, bufnr)

        local output = vim.fn.system('dbt parse 2>&1')
        local exit_code = vim.v.shell_error

        if exit_code == 0 then
          vim.notify('dbt parse: Success', vim.log.levels.INFO)
          return
        end

        local diagnostics = {}

        for line in output:gmatch('[^\r\n]+') do
          local file, line_num, msg = line:match('models/(.-)%.yml:(%d+):%s*(.*)')
          if not file then
            file, line_num, msg = line:match('models/(.-)%.yaml:(%d+):%s*(.*)')
          end

          if file and line_num and filepath:match(file) then
            table.insert(diagnostics, {
              lnum = tonumber(line_num) - 1,
              col = 0,
              severity = vim.diagnostic.severity.ERROR,
              source = 'dbt',
              message = msg,
            })
          end
        end

        if #diagnostics == 0 and exit_code ~= 0 then
          table.insert(diagnostics, {
            lnum = 0,
            col = 0,
            severity = vim.diagnostic.severity.ERROR,
            source = 'dbt',
            message = 'dbt parse failed: ' .. output:match('[^\r\n]+'),
          })
        end

        vim.diagnostic.set(dbt_namespace, bufnr, diagnostics, {})

        if #diagnostics > 0 then
          vim.notify('dbt parse: ' .. #diagnostics .. ' error(s)', vim.log.levels.ERROR)
        end
      end

      vim.api.nvim_create_user_command('DbtParse', run_dbt_parse, {})

      vim.api.nvim_create_autocmd('BufWritePost', {
        pattern = { '*/models/**/*.yml', '*/models/**/*.yaml' },
        callback = function()
          vim.defer_fn(run_dbt_parse, 100)
        end,
      })
    '';
  };
}
