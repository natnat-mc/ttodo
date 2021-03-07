local ansi = require 'todo.ansi'

local screenw, screenh

local window = {}
window.__index = window
function window:new(x, y, w, h)
	if not x then x = 1 end
	if not y then y = 1 end
	if not w then w = '#-2' end
	if not h then h = '#-2' end
	return setmetatable({x=x, y=y, w=w, h=h}, self)
end

function window:recalcsize()
	local fd = assert(io.popen('tput cols', 'r'))
	screenw = tonumber(assert(fd:read '*a'))
	fd:close()
	fd = assert(io.popen('tput lines', 'r'))
	screenh = tonumber(assert(fd:read '*a'))
	fd:close()
end

function window:drawall(...)
	local t = {ansi.display.clear()}
	for i=1, select("#", ...) do
		local x = select(i, ...)
		if not x.draw then
			for _, e in ipairs(x) do
				e:draw(t)
			end
		else
			x:draw(t)
		end
	end
	io.write(table.concat(t))
	io.flush()
end

function window:with(fn)
	local winlist = {}

	io.write(ansi.display.clear(), ansi.cursor.hide(), ansi.display.alternative())
	io.flush()
	os.execute('stty min 1 time 0 -icanon -echo')
	io.stdin:setvbuf('no')

	local coro = coroutine.create(fn)
	local ok, err = coroutine.resume(coro, winlist)
	if not ok then error(err) end
	while coroutine.status(coro) ~= "dead" do
		window:drawall(winlist)
		local input = io.read(1)
		if input == string.char(0x1b) then
			local chars, n, c = {input}, 2, nil
			repeat
				c = io.read(1)
				if c == nil or c == string.char(0x1b) then break end
				chars[n], n = c, n+1
			until c:match "[a-zA-Z]"
			input = table.concat(chars, nil, 1, n-1)
		end
		window:recalcsize()
		ok, err = coroutine.resume(coro, input)
		if not ok then error(err) end
	end

	io.stdin:setvbuf('line')
	os.execute('stty sane')
	io.write(ansi.cursor.show(), ansi.display.normal(), ansi.cursor(1, 1))
	io.flush()
end

function window:draw(buf)
	local putbuf = false
	if not buf then
		buf = {}
		putbuf = true
	end
	local n = #buf+1

	local function w(x)
		if type(x) == 'function' or type(x) == 'table' then
			x = x()
		end
		buf[n], n = x, n+1
	end

	local _x, _y, _w, _h = self:realx(), self:realy(), self:realw(), self:realh()
	w(ansi.cursor(_x, _y))
	w(ansi.color.reset)
	w("┏")
	w(string.rep("━", _w))
	w("┓")
	for y=1, _h do
		w(ansi.cursor(_x, y+_y))
		w("┃")
		local line = self[y] or {}
		local llen = 0
		for _, p in ipairs(line) do
			local txt, ctrl = p[1], p[2]
			llen = llen + #txt
			if ctrl then w(ctrl) end
			w(txt)
			if ctrl then w(ansi.color.reset) end
		end
		w(string.rep(" ", _w-llen))
		w("┃")
	end
	w(ansi.cursor(_x, _y+_h+1))
	w("┗")
	w(string.rep("━", _w))
	w("┛")

	if putbuf then
		io.write(table.concat(buf, nil, 1, n-1))
		io.flush()
	end
end

function window:real(v, d)
	if type(v) == 'number' then
		return v
	end
	local dim
	if d=='w' then dim=screenw
	elseif d=='h' then dim=screenh
	elseif d=='ww' then dim=self:realw()
	elseif d=='wh' then dim=self:realh()
	end
	return math.floor((loadstring or load)("return "..v:gsub('#', dim))())
end
function window:realx() return self:real(self.x, 'w') end
function window:realy() return self:real(self.y, 'h') end
function window:realw() return self:real(self.w, 'w') end
function window:realh() return self:real(self.h, 'h') end

function window:locate(x, y, txt, ctr)
	x, y, w = self:real(x, 'ww'), self:real(y, 'wh'), self:realw()
	txt = tostring(txt)
	local sx, ex = x, x+#txt

	-- here be dragons
	-- no idea why it works, if it doesn't break, don't fix it
	local t = self[y]
	if not t then
		t = {}
		self[y] = t
	end
	local _x = 1
	local i, n = 1, #t
	while i <= n do
		local b = t[i]
		local e = b[1]
		_x = _x+#e
		if _x >= sx then
			local dx = _x-sx
			b[1] = e:sub(1, -dx-1)
			i = i + 1
			table.insert(t, i, {txt, ctr})
			if _x > ex then
				i = i + 1
				table.insert(t, i, {e:sub(ex+#e-_x+1), b[2]})
			end
			while i <= n and _x < ex do
				b = table.remove(t, i+1)
				if b == nil then return end
				_x = _x+#b[1]
				if _x > ex then
					table.insert(t, i+1, {b[1]:sub(ex-_x), b[2]})
				end
			end
			return
		end
		i = i + 1
	end
	if _x < sx then
		table.insert(t, {string.rep(" ", sx-_x)})
	end
	table.insert(t, {txt, ctr})
end
function window:locatecenter(y, txt, ctr)
	txt = tostring(txt)
	return self:locate("#/2+1-"..(#txt/2), y, txt, ctr)
end
function window:write(x, y, ...)
	x = self:real(x, "ww")
	for i=1, select('#', ...), 2 do
		local txt, ctr = select(i, ...)
		txt = tostring(txt)
		self:locate(x, y, txt, ctr)
		x = x + #txt
	end
end

function window:clearline(y)
	self[self:real(y, "wh")] = {}
end
function window:clear()
	for y=1, self:realw() do
		self[y] = {}
	end
end

window:recalcsize()

return window
