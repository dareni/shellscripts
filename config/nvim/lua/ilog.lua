---Simple logger.
---Add to init.vim
---   package.path = package.path .. ";" .. vim.env.HOME .. "/bin/shellscripts/config/nvim/lua/?.lua"
--    require("ilog").enable()
---
---Then in the lua script:
---   ILog = require("ilog")
--    Ilog.log("note")
---

if Ilog == nil then
	Ilog = { calls = 0 }
	Ilog.data = vim.fn.stdpath("data")

	function Ilog.timestamp()
		local stamp = os.date("%H:%M:%S")
		return stamp
	end

	function Ilog.print(msg)
		print(Ilog.timestamp() .. " ; " .. msg)
	end

	function Ilog.disable()
		Ilog.print("Ilog disable.")
		if Ilog.file ~= nil then
			Ilog.file = nil
		end
		function Ilog.log() end
		function Ilog.print_trace() end
		function Ilog.output() end
		function Ilog.init() end
		return Ilog
	end

	function Ilog.enable()
		Ilog.print("Ilog enable.")
		local xdg_dir = os.getenv("XDG_RUNTIME_DIR")
		if xdg_dir == nil then
			Ilog.file = "/tmp/ilog.log"
		else
			Ilog.file = xdg_dir .. "/ilog.log"
		end

		function Ilog.log(message, obj)
			local obj_text = ""
			if obj ~= nil then
				obj_text = vim.inspect(obj)
			end
			local iter = string.gmatch(debug.traceback(), "[^\r\n]+")
			iter()
			iter()
			--the third line in the stack trace is the name of the file containing the ilog call.
			local filename = iter()
			if filename == nil then
				filename = ""
			end

			local msg_str = Ilog.calls
				.. ": "
				.. Ilog.timestamp()
				.. ": "
				.. filename
				.. " :\n  "
				.. message
				.. obj_text
				.. "\n"
			Ilog.output(msg_str)
			Ilog.calls = Ilog.calls + 1
		end

		function Ilog.print_trace()
			local msg_str = Ilog.calls .. ": " .. Ilog.timestamp() .. ": " .. debug.traceback() .. "\n"
			Ilog.output(msg_str)
			Ilog.calls = Ilog.calls + 1
		end

		function Ilog.output(msg_str)
			local handle = io.open(Ilog.file, "a")
			if handle ~= nil then
				handle:write(msg_str)
				handle:flush()
				handle:close()
			end
		end

		function Ilog.init()
			Ilog.print("Ilog init")
			local handle = io.open(Ilog.file, "w")
			if handle ~= nil then
				handle:write(Ilog.timestamp() .. ": Log for " .. Ilog.data)
				handle:flush()
				handle:close()
			end
		end

		--Ilog.init()
		--return Ilog
	end
	Ilog.print("Ilog create complete.")
	Ilog.disable()
else
	Ilog.print("Ilog exists.")
end

return Ilog

---Note: Prefer package.path over vim.o.pp or packpath
---  vim.o.pp=vim.o.pp..',~/bin/shellscripts/config/nvim'
---  vim.api.nvim_command "packadd ilog"
---
--- vim.cmd to execute vim script etc.
