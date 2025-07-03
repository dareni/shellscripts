---Simple logger.
---Add to init.vim
---   package.path = package.path .. ";" .. vim.env.HOME .. "/bin/shellscripts/config/nvim/lua/?.lua"
---
---Then in the lua script:
---   ILog = require("ilog")
--    Ilog.log("note")
---

if Ilog == nil then
	Ilog = { calls = 0 }

	Ilog.file = io.open("/tmp/ilog.log", "w")
	Ilog.data = vim.fn.stdpath("data")

	function Ilog.log(message, obj)
		local obj_text = ""
		if obj ~= nil then
			obj_text = vim.inspect(obj)
		end
		Ilog.file:write(Ilog.calls .. ": " .. message .. obj_text .. "\n")
		Ilog.file:flush()
		Ilog.calls = Ilog.calls + 1
	end
end

return Ilog

---Note: Prefer package.path over vim.o.pp or packpath
---  vim.o.pp=vim.o.pp..',~/bin/shellscripts/config/nvim'
---  vim.api.nvim_command "packadd ilog"
---
--- vim.cmd to execute vim script etc.
