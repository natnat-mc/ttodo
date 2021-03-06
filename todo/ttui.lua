local todos = require 'todo.todos'
local ansi = require 'todo.ansi'
local util = require 'todo.util'
local tui = require 'todo.tui'

function ui(windows)
	local listwin = tui:new(1, 1, "#-2", 1)
	local actionwin = tui:new(1, "#-4", "#-2", 3)
	table.insert(windows, listwin)
	table.insert(windows, actionwin)

	local cursor = 1
	local windowstart = 1
	local updated = false
	local noconfirm = false

	local function updatelistwin()
		local ntodos = #todos.list
		local maxh = listwin:real("#-7", "h")
		if ntodos == 0 then
			cursor = nil
			windowstart = 1
			listwin.h = 1
			local msg = "No todos yet"
			listwin:clear()
			listwin:write("#/2+1-"..(#msg/2), 1, msg, ansi.color.yellow)
		else
			if cursor == nil then cursor = 1 end
			if cursor > ntodos then cursor = ntodos end
			if cursor < windowstart then windowstart = cursor end
			if cursor >= windowstart+maxh then windowstart = cursor-maxh+1 end
			listwin.h = math.min(ntodos, maxh)
			listwin:clear()
			for i=windowstart, windowstart+maxh-1 do
				local todo = todos.list[i]
				if not todo then break end
				listwin:write(3, i-windowstart+1, todo.betterdate or "no date", ansi.color.green)
				listwin:write(14, i-windowstart+1, todo.status, ansi.color.cyan)
				listwin:write(22, i-windowstart+1, todo.text)
			end
			listwin:write(1, cursor-windowstart+1, ">", ansi.color.yellow 'bright')
			listwin:write("#", cursor-windowstart+1, "<", ansi.color.yellow 'bright')
			if windowstart ~= 1 then
				listwin:write(2, 1, "|", ansi.color.blue 'bright')
				listwin:write("#-1", 1, "|", ansi.color.blue 'bright')
			else
				listwin:write(2, 1, " ")
				listwin:write("#-1", 1, " ")
			end
			if windowstart+maxh <= ntodos then
				listwin:write(2, "#", "|", ansi.color.blue 'bright')
				listwin:write("#-1", "#", "|", ansi.color.blue 'bright')
			else
				listwin:write(2, "#", " ")
				listwin:write("#-1", "#", " ")
			end
		end

		if updated then
			actionwin:write(81, "#", "*", ansi.color.green 'bright')
		else
			actionwin:write(81, "#", " ")
		end
	end
	updatelistwin()

	local function popup(text, title)
		local popup = tui:new("#/8-1", "#/3-1", "#/4*3", "#/3")
		text = tostring(text)
		popup:locatecenter("#/2", text)
		if title then
			popup:locatecenter(1, title, ansi.color.yellow 'bright')
		end
		table.insert(windows, popup)
		coroutine.yield()
		table.remove(windows)
	end

	local function confirm(text, title)
		if noconfirm then return true end
		local popup = tui:new("#/8-1", "#/3-1", "#/4*3", "#/3")
		text = tostring(text)
		popup:locatecenter("#/2", text)
		if title then
			popup:locatecenter(1, title, ansi.color.yellow 'bright')
		end
		popup:write("#/2-8", "#",
			"ENTER", ansi.color.yellow, ": yes ", nil,
			"x", ansi.color.yellow, ": no"
		)
		table.insert(windows, popup)
		while true do
			local input = coroutine.yield()
			if input == '\n' then
				table.remove(windows)
				return true
			elseif input == 'x' then
				table.remove(windows)
				return false
			end
		end
	end

	local function sorttodos()
		if not cursor then return end
		local todo = todos.list[cursor]
		todos.sort(sort)
		for i, t in ipairs(todos.list) do
			if t==todo then
				cursor = i
				return
			end
		end
	end

	actionwin:write(2, 1, "n", ansi.color.yellow, ": New") 
	actionwin:write(2, 2, "d", ansi.color.yellow, ": Delete")
	actionwin:write(2, 3, "q", ansi.color.yellow, ": Quit")
	actionwin:write(19, 1, "x", ansi.color.yellow, ": Mark as done")
	actionwin:write(19, 2, "p", ansi.color.yellow, ": Mark as partially done")
	actionwin:write(19, 3, "f", ansi.color.yellow, ": Mark as failed")
	actionwin:write(49, 1, "h", ansi.color.yellow, ": Mark as on hold")
	actionwin:write(49, 2, "w", ansi.color.yellow, ": Mark as working")
	actionwin:write(49, 3, "t", ansi.color.yellow, ": Mark as todo")
	actionwin:write(79, 1, "z", ansi.color.yellow, ": Set date")
	actionwin:write(79, 2, "r", ansi.color.yellow, ": Rename")
	actionwin:write(79, 3, "s", ansi.color.yellow, ": Save todos")

	local commands = {}
	function commands.q()
		if updated and not confirm("Exit without saving?", "Exit") then return end
		return {exit=true}
	end
	function commands.s()
		if not confirm("Save changes?", "Save") then return end
		todos.save()
		popup("Successfully saved todos", "Save")
		updated = false
	end
	function commands.d()
		if not cursor then return end
		if not confirm("Remove todo \""..todos.list[cursor].text..'"?', "Remove") then return end
		table.remove(todos.list, cursor)
		updated = true
	end
	for _, c in ipairs({"x", "p", "f", "h", "w", "t"}) do
		commands[c] = function()
			if not cursor then return end
			todos.list[cursor].s = c
			updated = true
		end
	end
	local n = 1
	function commands.n()
		local title = "New todo #"..n
		n = n + 1
		todos.new(title, {d=os.date("%Y%m%d")})
		cursor = #todos.list
		commands.r()
		commands.z()
		updated = true
	end
	function commands.z()
		if not cursor then return end
		local todo = todos.list[cursor]
		local win = tui:new("#/2-10", "#/2-3", 18, 6)
		win:locatecenter(1, "Set date", ansi.color.yellow 'bright')
		win:write(3, "#-1", "x", ansi.color.yellow, ": Remove date")
		win:write(6, "#", "ENTER", ansi.color.yellow, ": OK")
		table.insert(windows, win)

		local y, m, d
		if todo.date then
			y, m, d = todo.date:match("(%d%d%d%d)(%d%d)(%d%d)")
		end
		if not y then
			y, m, d = os.date("%Y%m%d"):match("(%d%d%d%d)(%d%d)(%d%d)")
		end
		y, m, d = tonumber(y), tonumber(m), tonumber(d)
		local cursor = 1

		while true do
			win:clearline(3)
			win:write(2, 3,
				"Date: ", nil,
				util.lpad(y, 4, '0'), ansi.color[cursor==1 and 'green' or 'yellow'] 'bright',
				'/', nil,
				util.lpad(m, 2, '0'), ansi.color[cursor==2 and 'green' or 'yellow'] 'bright',
				'/', nil,
				util.lpad(d, 2, '0'), ansi.color[cursor==3 and 'green' or 'yellow'] 'bright'
			)
			local input = coroutine.yield()
			if input == 'x' then
				todo.d = nil
				break
			elseif input == '\n' then
				todo.d = util.lpad(y, 4, '0')..util.lpad(m, 2, '0')..util.lpad(d, 2, '0')
				break
			end
			input = ansi.parse(input)
			if input == "UP" then
				if cursor==1 then y = y-1
				elseif cursor==2 then m = m-1
				else d = d-1 end
			elseif input == "DOWN" then
				if cursor==1 then y = y+1
				elseif cursor==2 then m = m+1
				else d = d+1 end
			elseif input == "LEFT" then
				cursor = cursor - 1
				if cursor==0 then cursor = 3 end
			elseif input == "RIGHT" then
				cursor = cursor + 1
				if cursor==4 then cursor = 1 end
			end
			if y<1970 then y=1970 end
			if m<1 then m=1 end
			if d<1 then d=1 end
			if y>9999 then y=9999 end
			if m>12 then m=12 end
			if d>31 then d=31 end
		end

		table.remove(windows)
		updated = true
	end
	function commands.r()
		if not cursor then return end
		local todo = todos.list[cursor]

		local win = tui:new(1, "#/2-4", "#-2", 5)
		win:locatecenter(1, "Rename", ansi.color.yellow 'bright')
		win:write("#/2-4", "#", "ENTER", ansi.color.yellow, ": OK")
		table.insert(windows, win)

		local name = todo.text
		while true do
			win:clearline(3)
			win:write(2, 3, "Title: \"", nil, name, ansi.color.green 'bright', "\"")

			local input = coroutine.yield()
			if input == '\n' then
				todo[1] = name
				break
			elseif input == string.char(127) then
				name = name:sub(1, -2)
			elseif input:match("^[-a-zA-Z0-9_ \"',:;!%?%.$%*%(%)~%%%[%]{}%^<>#|\\/@=&]") then
				name = name..input
			end
		end

		table.remove(windows)
		updated = true
	end

	while true do
		local c = coroutine.yield()
		if c:match "^[A-Z]$" then
			c = c:lower()
			noconfirm = true
		end
		if commands[c] then
			local ret = commands[c]()
			if type(ret) == 'table' and ret.exit then return end
			sorttodos()
			updatelistwin()
		else
			local key = ansi.parse(c)
			if key=="UP" and cursor then
				cursor = cursor-1
				if cursor < 1 then cursor = #todos.list end
				updatelistwin()
			elseif key=="DOWN" and cursor then
				cursor = cursor + 1
				if cursor > #todos.list then cursor = 1 end
				updatelistwin()
			end
		end
		noconfirm = false
	end
end

todos.load()
todos.sort()
tui:with(ui)

