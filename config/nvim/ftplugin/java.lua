-- No longer requred. This is configured by lazyvim.
-- Also not a good example of how to do this. Under lazy vim it should be configured into the lazyvim nvim-jdtls plugin configuration opts and config attributes. See LazyVim/lua/lazyvim/plugins/extras/lang/java.lua.
-- Copy to ~/.config/nvim/ftplugin
-- from https://github.com/mfussenegger/nvim-jdtls?tab=readme-ov-file#configuration-verbose
-- See `:help vim.lsp.start_client` for an overview of the supported `config` options.
local nvim_data = vim.fn.stdpath("data")
local nvim_config = vim.fn.stdpath("config")
local lazy_config_file = nvim_config .. "/lua/config/lazy.lua"
local test_core_name = "lazyvim.plugins.extras.test.core"
local dap_core_name = "lazyvim.plugins.extras.dap.core"
local test_core_config = '    { import = "lazyvim.plugins.extras.test.core" },'
local dap_core_config = '    { import = "lazyvim.plugins.extras.dap.core" },'
local lazyvim_config = "LazyVim/LazyVim"

local neotest_java_junit_dir = nvim_data .. "/neotest-java"
local app_name = vim.env.NVIM_APPNAME and vim.env.NVIM_APPNAME or "nvim"
local ram_dir = vim.env.XDG_RUNTIME_DIR
if ram_dir == nil then
  ram_dir = vim.fn.stdpath("cache")
end
local dependency_location = nvim_data
local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
local project_root_dir = vim.fs.root(0, { "pom.xml", "mvnw", "gradlew" })

local jdtls_url = "https://www.eclipse.org/downloads/download.php?file=/jdtls/milestones/1.49.0"
  .. "/jdt-language-server-1.49.0-202507311558.tar.gz"
local jdtls_install_location = dependency_location .. "/jdtls"
local jdtls_workspace = ram_dir .. "/" .. app_name .. "/jdtls/workspace/" .. project_name

-- vscode .vsix  url https://marketplace.visualstudio.com/_apis/public/gallery/publishers/{publisher}/vsextensions/{package}/{version}/vspackage?targetPlatform={target_platform}
-- targetPlatform is ommitted for universal packages
-- uniquer identifier is in the form publisjher.package eg for vscjava.vscode-java-test
-- https://marketplace.visualstudio.com/_apis/public/gallery/publishers/vscjava/vsextensions/vscode-java-test/0.43.2025040304/vspackage
local vscode_java_test_location = dependency_location .. "/vscode-java-test"
local vscode_java_test_jars = dependency_location .. "/vscode-java-test/extension/server/*.jar"
local vscode_java_test_publisher = "vscjava"
local vscode_java_test_package = "vscode-java-test"
local vscode_java_test_version = "0.43.2025040304"
local vscode_java_test_filename = "vspackage"
local vscode_java_test_url = "https://marketplace.visualstudio.com/_apis/public/gallery/publishers/"
  .. vscode_java_test_publisher
  .. "/vsextensions/"
  .. vscode_java_test_package
  .. "/"
  .. vscode_java_test_version
  .. "/"
  .. vscode_java_test_filename

local java_debug_plugin_location = dependency_location .. "/java-debug-plugin/"
local java_debug_plugin_version = "0.53.1"
local java_debug_plugin_jar = java_debug_plugin_location
  .. "/com.microsoft.java.debug.plugin-"
  .. java_debug_plugin_version
  .. ".jar"
local java_debug_plugin_url = "https://repo1.maven.org/maven2/com/microsoft/java/"
  .. "com.microsoft.java.debug.plugin/"
  .. java_debug_plugin_version
  .. "/"
  .. "com.microsoft.java.debug.plugin-"
  .. java_debug_plugin_version
  .. ".jar"

local bundles = {
  vim.fn.glob(java_debug_plugin_jar, true),
}
vim.list_extend(bundles, vim.split(vim.fn.glob(vscode_java_test_jars, true), "\n"))
local junit_jar = vim.fn.glob(neotest_java_junit_dir .. "/*jar")

if junit_jar == "" or vim.fn.isdirectory(jdtls_install_location) == 0 then
  vim.notify("Java dependencies not installed! run :JdtlsTestInstall", vim.log.levels.ERROR)
  vim.notify(
    "Use :NoiceAll to check for the completion of jdtls and vsx extraction (warning messages) then restart vim.",
    vim.log.levels.ERROR
  )
else
  -- local equinox_launcher_version_number = "1.7.0.v20250519-0528"
  local equinox_launcher_version_number = "*"
  local equinox_launcher_glob = jdtls_install_location
    .. "/plugins/org.eclipse.equinox.launcher_"
    .. equinox_launcher_version_number
    .. ".jar"
  local equinox_launcher_location = vim.fn.glob(equinox_launcher_glob)
  if equinox_launcher_location == "" then
    vim.notify("Equinox launcher jar not found? " .. equinox_launcher_glob, vim.log.levels.ERROR)
    return
  end
  local config = {
    -- The command that starts the language server
    -- See: https://github.com/eclipse/eclipse.jdt.ls#running-from-the-command-line
    cmd = {

      -- 💀
      "java", -- or '/path/to/java21_or_newer/bin/java'
      -- depends on if `java` is in your $PATH env variable and if it points to the right version.

      "-Declipse.application=org.eclipse.jdt.ls.core.id1",
      "-Dosgi.bundles.defaultStartLevel=4",
      "-Declipse.product=org.eclipse.jdt.ls.core.product",
      "-Dlog.protocol=true",
      "-Dlog.level=ALL",
      "-Xmx1g",
      "--add-modules=ALL-SYSTEM",
      "--add-opens",
      "java.base/java.util=ALL-UNNAMED",
      "--add-opens",
      "java.base/java.lang=ALL-UNNAMED",

      -- 💀
      "-jar",
      equinox_launcher_location,
      -- ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^                                       ^^^^^^^^^^^^^^
      -- Must point to the                                                     Change this to
      -- eclipse.jdt.ls installation                                           the actual version

      -- 💀
      "-configuration",
      jdtls_install_location .. "/config_linux",
      -- ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^        ^^^^^^
      -- Must point to the                      Change to one of `linux`, `win` or `mac`
      -- eclipse.jdt.ls installation            Depending on your system.

      -- 💀
      -- See `data directory configuration` section in the README
      "-data",
      jdtls_workspace,
    },

    -- 💀
    -- This is the default if not provided, you can remove it. Or adjust as needed.
    -- One dedicated LSP server & client will be started per unique root_dir
    --
    -- vim.fs.root requires Neovim 0.10.
    -- If you're using an earlier version, use: require('jdtls.setup').find_root({'.git', 'mvnw', 'gradlew'}),
    --root_dir = vim.fs.root(0, { ".git", "mvnw", "gradlew" }),
    root_dir = project_root_dir,

    -- Here you can configure eclipse.jdt.ls specific settings
    -- See https://github.com/eclipse/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
    -- for a list of options
    settings = {
      java = {},
    },

    -- Language server `initializationOptions`
    -- You need to extend the `bundles` with paths to jar files
    -- if you want to use additional eclipse.jdt.ls plugins.
    --
    -- See https://github.com/mfussenegger/nvim-jdtls#java-debug-installation
    --
    -- If you don't plan on using the debugger or other eclipse.jdt.ls plugins you can remove this
    init_options = {
      bundles = bundles,
    },
  }

  -- This starts a new client & server,
  -- or attaches to an existing client & server depending on the `root_dir`.
  require("jdtls").start_or_attach(config)
end

-- read_file_to buffer -------------------------------------------------------------
local function read_file_to_buffer(filepath)
  -- Open the file in read mode ('r').
  local file = io.open(filepath, "r")

  if not file then
    print("Error: Could not open file " .. filepath)
    return nil
  end
  local buffer = {}

  for line in file:lines() do
    table.insert(buffer, line)
  end

  file:close()
  return buffer
end

-- write_buffer_to_file ------------------------------------------------------------
local function write_buffer_to_file(filepath, buffer)
  local file_out = io.open(filepath, "w")
  if file_out then
    for _, line in ipairs(buffer) do
      file_out:write(line .. "\n")
    end
    file_out:close()
  end
end

-- search buffer_for_text-------------------------------------------------------------
local function search_buffer_for_text(buffer, search_text)
  local found = 0

  -- Iterate over the lines in the file.
  for line_number, line in ipairs(buffer) do
    -- Use string.find to search for the text.
    -- The third argument, 1, tells string.find to start the search from the beginning of the string.
    -- The fourth argument, true, turns off magic characters (e.g., '.', '*', '?', '+'),
    -- treating the search_text as a literal string. This is safer for user input.
    if string.find(line, search_text, 1, true) then
      found = line_number
      break
    end
  end
  return found
end

-- Add configuration to lazy for test.core and dap.core-------------------------------
local function config_lazy_test_dap_core()
  local lazy_config_buffer = read_file_to_buffer(lazy_config_file)
  local lazy_config_exists = search_buffer_for_text(lazy_config_buffer, lazyvim_config)
  local test_core_exists = search_buffer_for_text(lazy_config_buffer, test_core_name)
  local dap_core_exists = search_buffer_for_text(lazy_config_buffer, dap_core_name)

  if lazy_config_exists == 0 then
    vim.notify("Can not find LazyVim config?", vim.log.levels.ERROR)
  else
    if test_core_exists == 0 and dap_core_exists == 0 then
      vim.notify("Adding test.core and dap.core config to " .. lazy_config_file, vim.log.levels.INFO)
      -- Backup the config.
      local _, error = os.rename(lazy_config_file, lazy_config_file .. ".orig")
      if error ~= nil then
        vim.notify("Rename file " .. lazy_config_file .. " failed. '" .. error .. "'.", vim.log.levels.ERROR)
        return
      end
      -- Add config customisations to the buffer.
      if lazy_config_buffer ~= nil then
        table.insert(lazy_config_buffer, lazy_config_exists + 1, test_core_config)
        table.insert(lazy_config_buffer, lazy_config_exists + 1, dap_core_config)
        write_buffer_to_file(lazy_config_file, lazy_config_buffer)
      else
        vim.notify("Buffer is nil? for " .. lazy_config_file, vim.log.levels.ERROR)
      end
    elseif test_core_exists ~= 0 and dap_core_exists ~= 0 then
      vim.notify("Config complete for test.core and dap.core config in " .. lazy_config_file, vim.log.levels.INFO)
    else
      vim.notify(
        "Config incomplete for test.core and dap.core config in " .. lazy_config_file,
        vim.log.levels.ERROR
      )
    end
  end
end

local uv = vim.uv

-- run_async_command----------------------------------------------------------------
-- eg
--command = "curl"
--options = {
-- args = { "-L", "-o", output_dir .. "/" .. download_file, url },
-- env = {},
-- cwd = "",
-- uid = "",
-- gid = "",
-- verbatim = false,
-- detached = false,
-- hide = true,
-- stdio = { stdout = uv.new_pipe(false), stderr = uv.new_pipe(false) },
---@param  cmd string
---@param  options uv.spawn.options
---@param  callback function(code integer, signal integer) ie process os code and signal
local function run_async_command(cmd, options, callback)
  -- A table to hold the output chunks
  local stdout_output_chunks = {}
  local stderr_output_chunks = {}

  -- Create a new pipes for the child process's stdout,stderr
  local stdout = uv.new_pipe(false)
  local stderr = uv.new_pipe(false)

  options.stdio = { nil, stdout, stderr }

  local on_read_stdout = function(err, chunk)
    if stdout == nil then
      vim.notify("Pipe does not exist?", vim.log.levels.ERROR)
      return
    end
    if err then
      -- Handle read errors
      vim.notify("Error reading stdout :" .. err, vim.log.levels.ERROR)
      return
    end

    if chunk then
      -- Append the chunk to our table
      table.insert(stdout_output_chunks, chunk)
    else
      -- A nil chunk indicates the end of the stream (EOF)
      stdout:read_stop()
    end
  end

  local on_read_stderr = function(err, chunk)
    if stderr == nil then
      vim.notify("Pipe does not exist?", vim.log.levels.ERROR)
      return
    end
    if err then
      -- Handle read errors
      vim.notify("Error reading stderr :" .. err, vim.log.levels.ERROR)
      return
    end

    if chunk then
      -- Append the chunk to our table
      table.insert(stderr_output_chunks, chunk)
    else
      -- A nil chunk indicates the end of the stream (EOF)
      stderr:read_stop()
    end
  end

  -- The function to be called when the process exits
  local on_exit = function(exit_code, signal)
    -- Close the pipe handles
    if stdout ~= nil then
      stdout:close()
    end
    if stderr ~= nil then
      stderr:close()
    end

    if next(stdout_output_chunks) ~= nil then
      vim.notify(
        "Process '" .. cmd .. "' stdout output: " .. table.concat(stdout_output_chunks),
        vim.log.levels.INFO
      )
    end
    if next(stderr_output_chunks) ~= nil then
      vim.notify(
        "Process '" .. cmd .. "' stderr output: " .. table.concat(stderr_output_chunks),
        vim.log.levels.ERROR
      )
    end

    if exit_code ~= 0 or signal ~= 0 then
      vim.notify(
        "Command '" .. cmd .. "' failed exit code:" .. exit_code .. " signal:" .. signal,
        vim.log.levels.ERROR
      )
    else
      vim.notify(
        "Command '" .. cmd .. "' successful exit code:" .. exit_code .. " signal:" .. signal,
        vim.log.levels.INFO
      )
      if callback ~= nil then
        callback()
      end
    end
  end

  vim.notify("Spawn '" .. cmd .. "' options:" .. vim.inspect(options), vim.log.levels.DEBUG)
  local process = uv.spawn(cmd, options, on_exit)

  -- attach callbacks to pipes before the process ends to process any pipe data.
  if stdout ~= nil then
    stdout:read_start(on_read_stdout)
  end
  if stderr ~= nil then
    stderr:read_start(on_read_stderr)
  end
  if process == nil then
    vim.notify(cmd .. " process failed: " .. vim.inspect(options), vim.log.levels.ERROR)
  end
end

-- download_file_async---------------------------------------------------------
---@param url string The target resource.
---@param output_dir string The absolute path to directory to contain the resulting url resource.
---@param callback function A function(success, output_dir) containing logic for processing the result of the invocation.
local function download_file_async(url, output_dir, callback)
  if vim.fn.isdirectory(output_dir) == 0 then
    local status = vim.fn.mkdir(output_dir, "p", "0o755")
    if status ~= 1 then
      vim.notify(
        "Error could not create directory: " .. output_dir .. " status:" .. vim.inspect(status),
        vim.log.levels.ERROR
      )
      return
    end
  else
    vim.notify(
      "Will not attempt fetch for resource " .. url .. " because the destination directory exists.",
      vim.log.levels.INFO
    )
    return
  end

  local download_file = vim.fs.basename(url)
  local cmd = "curl"
  local options = {
    args = { "-L", "-s", "-o", output_dir .. "/" .. download_file, url },
    stdio = { stdout = uv.new_pipe(false), stderr = uv.new_pipe(false) },
  }
  run_async_command(cmd, options, callback)
end

-- vsx_package_unzip---------------------------------------------------------------------------
local vsx_package_unzip = function(success, op_dir)
  local abs_package_name = vscode_java_test_location .. "/" .. vscode_java_test_filename
  vim.notify("Extract " .. abs_package_name, vim.log.levels.INFO)
  local cmd = "unzip"
  local options = {
    args = { abs_package_name },
    cwd = vscode_java_test_location,
  }
  vim.notify("Please wait for vsx package extraction to complete ...", vim.log.levels.WARN)
  run_async_command(cmd, options, function()
    vim.notify("Completed vsx package extraction.", vim.log.levels.WARN)
  end)
end

-- vsx_package_decompress----------------------------------------------------------------------
local vsx_package_decompress = function()
  local abs_package_name = vscode_java_test_location .. "/" .. vscode_java_test_filename
  local _, error = os.rename(abs_package_name, abs_package_name .. ".gz")
  if error ~= nil then
    vim.notify("Rename file " .. abs_package_name .. " failed. '" .. error .. "'.", vim.log.levels.ERROR)
    return
  end

  vim.notify("Decompress " .. abs_package_name .. ".gz", vim.log.levels.INFO)
  local cmd = "gunzip"
  local options = {
    args = { abs_package_name .. ".gz" },
  }
  run_async_command(cmd, options, vsx_package_unzip)
end

local jdtls_extract = function()
  local archive_filename = vim.fs.basename(jdtls_url)
  local abs_archive_path = jdtls_install_location .. "/" .. archive_filename
  vim.notify("Extract" .. abs_archive_path, vim.log.levels.DEBUG)
  local cmd = "tar"
  local options = {
    args = { "-xzf", abs_archive_path },
    cwd = jdtls_install_location,
  }
  vim.notify("Please wait for jdtls extraction to complete ...", vim.log.levels.WARN)
  run_async_command(cmd, options, function()
    vim.notify("Completed jdtls extraction.", vim.log.levels.WARN)
  end)
end

-------------------------------------------------------------------------------
local function install_java_test_modules()
  vim.notify("install test modules", vim.log.levels.INFO)
  config_lazy_test_dap_core()
  download_file_async(java_debug_plugin_url, java_debug_plugin_location, function() end)
  download_file_async(vscode_java_test_url, vscode_java_test_location, vsx_package_decompress)
  download_file_async(jdtls_url, jdtls_install_location, jdtls_extract)

  if
    vim.fn.isdirectory(java_debug_plugin_location) == 1
    and vim.fn.isdirectory(vscode_java_test_location) == 1
    and vim.fn.isdirectory(jdtls_install_location) == 1
  then
    vim.cmd("TSInstall java")
    vim.cmd("NeotestJava setup")
  else
    vim.notify("Error: install not complete. Check the logs and rerun JdtlsTestInstall.", vim.log.levels.ERROR)
  end
end

vim.api.nvim_create_user_command(
  "JdtlsTestInstall",
  install_java_test_modules,
  { desc = "Install nvim-jdtls dependencies." }
)
