local ansi = require 'todo.ansi'

local util = {}

function util.writei(table, str)
	str = str
		:gsub("${([^:]-):(.-)}", function(k, fmt)
			local v = table[k]
			local n = tonumber(fmt)
			if v then
				v = tostring(v)
				return v..string.rep(" ", n-#v)
			end
			return string.rep(".", n)
		end)
		:gsub("${(.-)}", function(k)
			return table[k] or "..."
		end)
		:gsub("#{(.-),(.-),(.-)}", function(r, g, b)
			return ansi.color(r, g, b)
		end)
		:gsub("#{(.-)}", function(color)
			return ansi.color(color)
		end)
	return io.write(str)
end
function util.printi(table, str)
	return util.writei(table, str.."\n")
end

function util.lpad(str, len, fill)
	str = tostring(str)
	return fill:rep(len-#str)..str
end

return util
