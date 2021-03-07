local ansi = {}

local csi = string.char(0x1b).."["
ansi.csi = csi

-- colors
ansi.color = {}
setmetatable(ansi.color, ansi.color)

-- normal colors
local colormt = {}
colormt.__index = colormt
function colormt:new(code)
	return setmetatable({code}, self)
end

function colormt:__tostring()
	return csi.."3"..self[1].."m"
end
function colormt:__concat(x)
	return tostring(self)..tostring(x)
end
function colormt:__call(variant)
	if variant==nil or variant=='normal' then
		return tostring(self)
	elseif variant=='bright' then
		return csi.."9"..self[1].."m"
	elseif variant=="bg" then
		return csi.."4"..self[1].."m"
	elseif variant=="brightbg" or variant=="bgbright" then
		return csi.."10"..self[1].."m"
	else
		error("Invalid variant "..variant)
	end
end
for k, v in pairs{
	black=0,
	red=1,
	green=2,
	yellow=3,
	blue=4,
	magenta=5,
	cyan=6,
	white=7
} do
	ansi.color[k] = colormt:new(v)
end

-- any color
function ansi.color:__call(r, g, b, bg)
	if r and g and b then
		if bg then
			return csi.."48;2;"..r..";"..g..";"..b.."m"
		else
			return csi.."38;2;"..r..";"..g..";"..b.."m"
		end
	elseif type(r)=='string' then
		return ansi.color[r](g)
	elseif r<=7 then
		if g then
			return csi.."4"..r.."m"
		else
			return csi.."3"..r.."m"
		end
	else
		if g then
			return csi.."48;5;"..r.."m"
		else
			return csi.."38;5;"..r.."m"
		end
	end
end

-- reset color
ansi.color.reset = setmetatable({csi.."0m"}, {
	__call=function(self) return self[1] end,
	__tostring=function(self) return self[1] end,
	__concat=function(a, b) return tostring(a)..tostring(b) end
})

-- cursor
ansi.cursor = {}
setmetatable(ansi.cursor, ansi.cursor)

function ansi.cursor.up(n)
	if not n then n = 1 end
	return csi..n.."A"
end
function ansi.cursor.down(n)
	if not n then n = 1 end
	return csi..n.."B"
end
function ansi.cursor.forward(n)
	if not n then n = 1 end
	return csi..n.."C"
end
function ansi.cursor.back(n)
	if not n then n = 1 end
	return csi..n.."D"
end
function ansi.cursor.set(x, y)
	return csi..y..";"..x.."H"
end
function ansi.cursor.save()
	return csi.."s"
end
function ansi.cursor.restore()
	return csi.."u"
end
function ansi.cursor.show()
	return csi.."?25h"
end
function ansi.cursor.hide()
	return csi.."?25l"
end
function ansi.cursor:__call(x, y)
	return ansi.cursor.set(x, y)
end

-- display
ansi.display = {}
setmetatable(ansi.display, ansi.display)

function ansi.display.clear()
	return csi.."2J"
end
function ansi.display.alternative()
	return csi.."?1049h"
end
function ansi.display.normal()
	return csi.."?1049l"
end

-- parse
function ansi.parse(code)
	if code:sub(1, 1) ~= string.char(0x1b) then return nil end
	code = code:sub(2)
	return ({
		[""]="ESC",
		["[A"]="UP",
		["[B"]="DOWN",
		["[C"]="RIGHT",
		["[D"]="LEFT"
	})[code]
end

return ansi
