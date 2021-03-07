local todofile = os.getenv("TODOFILE") or os.getenv("HOME").."/.todofile"

local todomt = {}
todomt.__get = {}
todomt.__set = {}
todomt.__index = function(self, k)
	local getter = todomt.__get[k]
	if getter then
		return getter(self, k)
	end
	return todomt[k]
end
todomt.__newindex = function(self, k, v)
	local setter = todomt.__set[k]
	if setter then
		return setter(self, v, k)
	end
	return rawset(self, k, v)
end
function todomt:new(data)
	return setmetatable(data, todomt)
end

function todomt.__get:statusnum()
	return ({
		w=-1,
		h=1,
		x=2,
		p=3,
		f=4
	})[self.s] or 0
end
function todomt.__get:status()
	return ({
		w="working",
		h="hold",
		x="done",
		p="partial",
		f="failed"
	})[self.s] or "todo"
end

function todomt.__get:europeandate()
	if self.d then
		local y, m, d = self.d:match "^(%d%d%d%d)(%d%d)(%d%d)$"
		if y then
			return d..'/'..m..'/'..y
		end
	end
end
function todomt.__get:americandate()
	if self.d then
		local y, m, d = self.d:match "^(%d%d%d%d)(%d%d)(%d%d)$"
		if y then
			return m..'/'..d..'/'..y
		end
	end
end
function todomt.__get:betterdate()
	if self.d then
		local y, m, d = self.d:match "^(%d%d%d%d)(%d%d)(%d%d)$"
		if y then
			return y..'-'..m..'-'..d
		end
	end
end
function todomt.__get:date()
	return self.d
end

function todomt:__tostring()
	local t, n = {self[1]}, 2
	for k, v in pairs(self) do
		if type(k) ~= 'number' then
			t[n], n = " +", n+1
			t[n], n = k, n+1
			t[n], n = "[", n+1
			t[n], n = v, n+1
			t[n], n = "]", n+1
		end
	end
	return table.concat(t, nil, 1, n-1)
end
function todomt.__get:text()
	return self[1]
end

local todos = {}
function todos.load()
	local fd = io.open(todofile, 'r')
	if not fd then
		todos.list = {}
		return
	end
	local list, n = {}, 1
	for l in fd:lines() do
		local data = {}
		data[1] = l:gsub("%s*%+(%S+)%[([^%]]*)%]%s*", function(k, v)
			data[k] = v
			return ""
		end)
		list[n], n = todomt:new(data), n+1
	end
	fd:close()
	todos.list = list
end

function todos.save()
	local fd = assert(io.open(todofile, 'w'))
	for _, todo in ipairs(todos.list) do
		fd:write(tostring(todo), "\n")
	end
	fd:close()
	return true
end

todos.defaultsort = {"statusnum", "date", "text"}
function todos.sort(fields)
	if not fields then fields = todos.defaultsort end
	table.sort(todos.list, function(a, b)
		for _, field in ipairs(fields) do
			local fa, fb = a[field], b[field]
			if fa and fb then
				if fa<fb then return true end
				if fa>fb then return false end
			end
		end
		return false
	end)
end

function todos.each()
	local i = 1
	return function()
		local e = todos.list[i]
		i = i + 1
		return e
	end
end

function todos.new(title, data)
	if not data then data = {} end
	data[1] = title
	table.insert(todos.list, todomt:new(data))
	return true
end

todos.todofile = todofile
todos.todomt = todomt

return todos
