local M = {}

M.home = vim.env.HOME

function M.sleep(sec)
	os.execute(string.format("sleep %s", sec))
end

function M.t1()
	local bundles = vim.fn.glob("$MASON/share/java-debug-adapter/com.microsoft.java.debug.plugin-*jar", false, true)
	vim.list_extend(bundles, vim.fn.glob("$MASON/share/java-test/*.jar", false, true))

	Ilog = require("ilog")
	Ilog.log("bundles:", bundles)
end

-------------------------------------------------------------------------------
---Install latest neovim
-------------------------------------------------------------------------------
function M.install_neovim(version, nightly)
	local output_dir = M.get_run_dir()
	local stable_url = "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz"
	local nightly_url = "https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-x86_64.tar.gz"
	local url = stable_url
	if nightly then
		url = nightly_url
	end
	local root_filename = vim.fn.fnamemodify(url, ":t:r:r")
	local extension = vim.fn.fnamemodify(url, ":e:e")
	local download_file = root_filename .. "-" .. version .. "." .. extension
	local curl_output_file = output_dir .. "/" .. download_file
	local final_tar_output_dir = "/opt/dev/" .. root_filename .. "-" .. version
	local temp_tar_output_dir = output_dir .. "/tmp_nvim_download_" .. M.generate_random_string(12)

	vim.fn.mkdir(temp_tar_output_dir)

	if M.is_empty_string(version) then
		error("Version parameter is required.")
	end
	if M.is_directory(final_tar_output_dir) then
		error("Target already exists?? : " .. final_tar_output_dir)
	end

	local function nvim_cleanup_callback()
		local rm_options = { args = { "-rf", temp_tar_output_dir, curl_output_file } }
		M.run_async_command("rm", rm_options, nil)
	end
	local function nvim_tmp_mv_callback()
		local mv_options = { args = { temp_tar_output_dir .. "/nvim-linux-x86_64", final_tar_output_dir } }
		M.run_async_command("mv", mv_options, nvim_cleanup_callback)
	end
	local function tar_callback()
		local tar_options = { args = { "-xvf", curl_output_file, "-C", temp_tar_output_dir } }
		M.run_async_command("tar", tar_options, nvim_tmp_mv_callback)
	end
	local options = { args = { "-L", "-s", "-o", curl_output_file, url } }
	M.run_async_command("curl", options, tar_callback)
end

-- config keymaps
function M.install_key_maps()
	local keymap_source = M.home .. "/bin/shellscripts/config/nvim/lua/keymaps.lua"
	local keymap_file = M.get_nvim_directories(M.home).config .. "/" .. M.get_app_name() .. "/lua/config/keymaps.lua"
	if M.is_symlink(keymap_file) then
		print(keymap_file .. " is already symlinked.")
	else
		print("Installing symlink " .. keymap_source .. " to " .. keymap_file)
		M.mv(keymap_file, keymap_file .. "_old")
		M.ln(keymap_source, keymap_file)
	end
end
-------------------------------------------------------------------------------
-- string functions -----------------------------------------------------------
-------------------------------------------------------------------------------
function M.is_empty_string(str)
	return str == nil or #str == 0
end

function M.generate_random_string(length)
	math.randomseed(os.time())
	local charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	local result = {}
	local charset_len = #charset
	for _ = 1, length do
		local random_index = math.random(1, charset_len)
		local random_char = charset:sub(random_index, random_index)
		table.insert(result, random_char)
	end
	return table.concat(result)
end
-------------------------------------------------------------------------------
-- file handling functions ----------------------------------------------------
-------------------------------------------------------------------------------
function M.is_symlink(path)
	local ret = tonumber(vim.fn.system(string.format("file %q |cut -d\\  -f 2|grep -c symbolic", path)))
	return ret == 1
end

function M.is_symlink_valid(path)
	local command = string.format("readlink -e %q >/dev/null 2>&1", path)
	vim.fn.system(command)
	return vim.v.shell_error == 0
end

function M.is_directory(path)
	local command = string.format("test -d %q", path)
	local ret = os.execute(command)
	return ret == 0
end

function M.get_run_dir()
	return vim.fn.stdpath("run")
end

function M.ln(source_path, link_path)
	-- The `ln -s` command is used to create a symbolic link
	local command = string.format("ln -s %q %q", source_path, link_path)

	-- Execute the command
	local output = vim.fn.system(command)

	-- Check for any errors
	if vim.v.shell_error ~= 0 then
		print("Error creating symbolic link:")
		print(output)
	end
end

function M.mv(source_path, target_path)
	-- The `mv``command is used to move a file
	local command = string.format("mv %q %q", source_path, target_path)

	-- Execute the command
	local output = vim.fn.system(command)

	-- Check for any errors
	if vim.v.shell_error ~= 0 then
		print("Error moving file:")
		print(output)
	end
end
-------------------------------------------------------------------------------
-- file access functions ------------------------------------------------------
-------------------------------------------------------------------------------
function M.read_file_to_buffer(filepath)
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
function M.write_buffer_to_file(filepath, buffer)
	local file_out = io.open(filepath, "w")
	if file_out then
		for _, line in ipairs(buffer) do
			file_out:write(line .. "\n")
		end
		file_out:close()
	end
end
-- search buffer_for_text-------------------------------------------------------------
function M.search_buffer_for_text(buffer, search_text)
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
-------------------------------------------------------------------------------
-- vim specific functions------------------------------------------------------
-------------------------------------------------------------------------------
function M.get_app_name()
	local app_name = vim.env.NVIM_APPNAME
	if app_name == nil then
		app_name = "nvim"
	end
	return app_name
end

function M.get_nvim_directories(home)
	return {
		config = home .. "/.config",
		data = home .. "/.local/share",
		state = home .. "/.local/state",
		cache = home .. "/.cache",
	}
end

--Create dirs for .cache and .local/state
function M.refresh_cache()
	local vim_tmp_dir = M.get_run_dir() .. "/" .. M.get_app_name()
	if not M.is_directory(vim_tmp_dir) then
		vim.notify("create dirs in " .. vim_tmp_dir, vim.log.levels.INFO)
		vim.fn.mkdir(vim_tmp_dir .. "/state", "p")
		vim.fn.mkdir(vim_tmp_dir .. "/cache", "p")
	else
		vim.notify("dir " .. vim_tmp_dir .. " exists!", vim.log.levels.INFO)
	end
end

--Create nvim java.
--eg require('iutil').reset_nvim_config_java("/run/user/1000","/home/daren", "jvim")
---@param store string the containing directory for the config storage.
---@param target string  typically a user home eg /home/bob
---@param app_name string the neovim instance.
-- mv_nvim_config -------------------------------------------------------------
function M.reset_nvim_config_java(store, target, app_name)
	--rm -rf lvim_cache/* lvim_local/* lvim_state/* ~/.config/lvim/lazy-lock.json  ~/.config/lvim/lazyvim.json
	if M.is_empty_string(target) then
		error("'target' must contain a value.")
	elseif not M.is_directory(target) then
		error(target .. " directory must exist.")
	end

	if M.is_empty_string(store) then
		error("'store' must contain a value.")
	elseif not M.is_directory(store) then
		error(store .. " directory must exist.")
	end

	if M.is_empty_string(app_name) then
		error("'app_name' must contain a value.")
	end
	local store_dir = store .. "/" .. app_name
	if M.is_directory(store_dir) then
		vim.fn.delete(store_dir, "rf")
	end
	vim.fn.mkdir(store_dir)

	local vim_storage = M.get_nvim_directories(target)

	for src, dest in pairs(vim_storage) do
		local src_abs = store_dir .. "/" .. src
		vim.fn.mkdir(src_abs)
		local dest_link = dest .. "/" .. app_name

		if not (vim.fn.filereadable(dest_link) and M.is_symlink(dest_link) and M.is_symlink_valid(dest_link)) then
			vim.fn.delete(dest_link, "rf")
			M.ln(src_abs, dest_link)
		else
			print("not doing anything")
		end
	end
	local nvim_config_dir = store_dir .. "/config"
	if M.is_directory(nvim_config_dir) then
		local callback = function()
			M.adj_nvim_config_java(nvim_config_dir)
		end
		-- M.git_clone("https://github.com/LazyVim/starter", nvim_config_dir, callback)
		M.git_clone("https://github.com/LazyVim/starter", nvim_config_dir, nil)
	end
	--Link neotest-java plugin configuration.
	local neotestjava_plugin_file = M.home .. "/" .. "bin/shellscripts/config/nvim/plugin/neotest-java.lua"
	local neogit_plugin_file = M.home .. "/" .. "bin/shellscripts/config/nvim/plugin/neogit.lua"
	local plugin_config_dest = nvim_config_dir .. "/lua/plugins"
	local tries = 0
	while not M.is_directory(plugin_config_dest) and tries < 10 do
		M.sleep(0.2)
		tries = tries + 1
	end
	if vim.fn.filereadable(neotestjava_plugin_file) and M.is_directory(plugin_config_dest) then
		M.ln(neotestjava_plugin_file, plugin_config_dest)
		M.ln(neogit_plugin_file, plugin_config_dest)
	else
		vim.notify("Could not install :" .. neotestjava_plugin_file(" ") .. "to " .. plugin_config_dest .. ".")
	end
	--Cinfig init.lua for custom settings
	local init_file = nvim_config_dir .. "/init.lua"
	local nvim_init_buffer = M.read_file_to_buffer(init_file)
	local nvim_mod_path_config = 'package.path = package.path .. ";" .. vim.env.HOME .. "/bin/shellscripts/config/nvim/lua/?.lua"\n'
		.. 'require("icustom")'
	if nvim_init_buffer ~= nil then
		table.insert(nvim_init_buffer, 1, nvim_mod_path_config)
		table.insert(nvim_init_buffer, 2, 'require("iutil").refresh_cache()')
		M.write_buffer_to_file(init_file, nvim_init_buffer)
	end
end

function M.adj_nvim_config_java(nvim_config_dir)
	--Install LazyVim starter and adjust for java.
	local lazyvim_config = "LazyVim/LazyVim"
	local test_core_name = "lazyvim.plugins.extras.test.core"
	local dap_core_name = "lazyvim.plugins.extras.dap.core"
	local lang_java_name = "lazyvim.plugins.extras.lang.java"
	local extras_config = '    { import = "lazyvim.plugins.extras.test.core" },\n'
		.. '    { import = "lazyvim.plugins.extras.dap.core" },\n'
		.. '    { import = "lazyvim.plugins.extras.lang.java" },\n'

	local lazy_config_file = nvim_config_dir .. "/lua/config/lazy.lua"

	local lazy_config_buffer = M.read_file_to_buffer(lazy_config_file)
	local lazy_config_exists = M.search_buffer_for_text(lazy_config_buffer, lazyvim_config)
	local test_core_exists = M.search_buffer_for_text(lazy_config_buffer, test_core_name)
	local dap_core_exists = M.search_buffer_for_text(lazy_config_buffer, dap_core_name)
	local lang_java_exists = M.search_buffer_for_text(lazy_config_buffer, lang_java_name)

	if lazy_config_exists == 0 then
		vim.notify("Can not find LazyVim config?", vim.log.levels.ERROR)
	else
		if test_core_exists == 0 and dap_core_exists == 0 and lang_java_exists == 0 then
			vim.notify("Adding lang.java, test.core and dap.core config to " .. lazy_config_file, vim.log.levels.INFO)
			-- Backup the config.
			local _, error = os.rename(lazy_config_file, lazy_config_file .. ".orig")
			if error ~= nil then
				vim.notify("Rename file " .. lazy_config_file .. " failed. '" .. error .. "'.", vim.log.levels.ERROR)
				return
			end
			-- Add config customisations to the buffer.
			if lazy_config_buffer ~= nil then
				table.insert(lazy_config_buffer, lazy_config_exists + 1, extras_config)
				M.write_buffer_to_file(lazy_config_file, lazy_config_buffer)
			else
				vim.notify("Buffer is nil? for " .. lazy_config_file, vim.log.levels.ERROR)
			end
		elseif test_core_exists ~= 0 and dap_core_exists ~= 0 and lang_java_exists ~= 0 then
			vim.notify(
				"Config complete for lang.java, test.core and dap.core config in " .. lazy_config_file,
				vim.log.levels.INFO
			)
		else
			vim.notify(
				"Config incomplete for test.core and dap.core config in " .. lazy_config_file,
				vim.log.levels.ERROR
			)
		end
	end
end

-------------------------------------------------------------------------------
-- git clone ------------------------------------------------------------------
-------------------------------------------------------------------------------
---@param  repo string Url of the git repo.
---@param  dest string Destination directory of the git clone.
---@param  callback? function() Only called on success.
function M.git_clone(repo, dest, callback)
	if M.is_empty_string(repo) then
		error("Paramater 'repo' must contain a valid git repo url!")
	end
	if M.is_empty_string(dest) then
		error("Parameter 'dest' must contain the directory path to the clone destination")
	end
	local options = { args = { "clone", repo, dest } }
	M.run_async_command("git", options, callback)
end
-------------------------------------------------------------------------------
-- job execution --------------------------------------------------------------
-------------------------------------------------------------------------------
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
---@param  callback? function() Only called on success.
function M.run_async_command(cmd, options, callback)
	-- A table to hold the output chunks
	local stdout_output_chunks = {}
	local stderr_output_chunks = {}

	-- Create a new pipes for the child process's stdout,stderr
	local stdout = uv.new_pipe(false)
	local stderr = uv.new_pipe(false)

	options.stdio = { nil, stdout, stderr }

	local on_read_stdout = function(err, chunk)
		if stdout == nil then
			vim.schedule(function()
				vim.notify("Pipe does not exist?", vim.log.levels.ERROR)
			end)
			return
		end
		if err then
			-- Handle read errors
			vim.schedule(function()
				vim.notify("Error reading stdout :" .. err, vim.log.levels.ERROR)
			end)
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
			vim.schedule(function()
				vim.notify("Pipe does not exist?", vim.log.levels.ERROR)
			end)
			return
		end
		if err then
			-- Handle read errors
			vim.schedule(function()
				vim.notify("Error reading stderr :" .. err, vim.log.levels.ERROR)
			end)
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
			vim.schedule(function()
				vim.notify(
					"Process '" .. cmd .. "' stdout output: " .. table.concat(stdout_output_chunks),
					vim.log.levels.INFO
				)
			end)
		end
		if next(stderr_output_chunks) ~= nil then
			vim.schedule(function()
				vim.notify(
					"Process '" .. cmd .. "' stderr output(may not be an error): " .. table.concat(stderr_output_chunks),
					vim.log.levels.ERROR
				)
			end)
		end

		if exit_code ~= 0 or signal ~= 0 then
			vim.schedule(function()
				vim.notify(
					"Command '" .. cmd .. "' failed exit code:" .. exit_code .. " signal:" .. signal,
					vim.log.levels.ERROR
				)
			end)
		else
			vim.schedule(function()
				vim.notify(
					"Command '" .. cmd .. "' successful exit code:" .. exit_code .. " signal:" .. signal,
					vim.log.levels.INFO
				)
			end)
			if callback ~= nil then
				callback()
			end
		end
	end

	vim.schedule(function()
		vim.notify("Spawn '" .. cmd .. "' options:" .. vim.inspect(options), vim.log.levels.DEBUG)
	end)
	local process = uv.spawn(cmd, options, on_exit)

	-- attach callbacks to pipes before the process ends to process any pipe data.
	if stdout ~= nil then
		stdout:read_start(on_read_stdout)
	end
	if stderr ~= nil then
		stderr:read_start(on_read_stderr)
	end
	if process == nil then
		vim.schedule(function()
			vim.notify(cmd .. " process failed: " .. vim.inspect(options), vim.log.levels.ERROR)
		end)
	end
end

-- download_file_async---------------------------------------------------------
---@param url string The target resource.
---@param output_dir string The absolute path to directory to contain the resulting url resource.
---@param callback function A function(success, output_dir) containing logic for processing the result of the invocation.
function M.download_file_async(url, output_dir, callback)
	if M.is_directory(output_dir) == 0 then
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
	M.run_async_command(cmd, options, callback)
end

function M.test()
	require("ilog").enable()

	-- create test dirjj
	local tempdir = M.get_run_dir()
	if not M.is_directory(tempdir) then
		tempdir = "/tmp"
	end
	local testdir = tempdir .. "/iutil_test_" .. M.generate_random_string(10)
	vim.fn.mkdir(testdir)
	assert(M.is_directory(testdir), "Could not create test dir??")

	-- test M.mv
	local dira = testdir .. "/a"
	local dirb = testdir .. "/b"
	vim.fn.mkdir(dira)
	M.mv(dira, dirb)
	assert(M.is_directory(dirb))
	assert(not M.is_directory(dira))
	-- test M.ln
	M.ln(dirb, dira)
	assert(M.is_symlink(dira), "Failed to detect '/a' is a symlink!")
	assert(M.is_symlink_valid(dira), "Symlink create failed?")
	assert(not M.is_symlink(dirb), "b is not a symlink!")
	vim.fn.delete(dirb, "d")
	assert(not M.is_symlink_valid(dira), "Symlink should be invalid?")
	vim.fn.delete(dira)
	vim.fn.delete(dirb)
	--test reset_nvim_config_java
	local app_name = "jvim"
	local store = testdir .. "/store"
	local target = testdir .. "/target"
	vim.fn.mkdir(store)
	vim.fn.mkdir(target)
	for _, name in pairs(M.get_nvim_directories(target)) do
		vim.fn.mkdir(name, "p")
	end
	M.reset_nvim_config_java(store, target, app_name)
	-- vim.fn.mkdir(testdir .. "/a") require("ilog").disable()
end

function M.reload()
	package.loaded["iutil"] = nil
	return require("iutil")
end

return M
