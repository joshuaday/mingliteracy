local encodings = require "encodings"
local utf8 = require "utf-8"
local json = require "json"

local function lines(iterator, state)
	local index
	
	local function getch()
		local ch
		index, ch = iterator(state, index)
		return ch
	end
	
	local function discardline()
		repeat
			local c = getch()
		until c == nil or c == string.byte '\n'
	end
	
	
	local function readline()
		-- newline
		local c
		
		while true do
			c = getch()
			if c ~= string.byte "#" then
				break
			else
				discardline()
			end
		end
		
		if c == nil then
			return nil
		else
			local w1, w2, w3 = '', '', '' -- terrible : todo - speed this up
			
			-- three words, tab separated; find a tab (and bail out if we hit the line end)
			while true do
				w1 = w1 .. utf8.encode(c)
				c = getch()
				if c == nil or c == string.byte '\n' then
					return nil
				end
				if c == string.byte '\t' then
					break
				end
			end
			
			while true do
				c = getch()
				if c == nil or c == string.byte '\n' then
					return nil
				end
				if c == string.byte '\t' then
					break
				end
				w2 = w2 .. utf8.encode(c)
			end
			
			
			while true do
				c = getch()
				if c == nil or c == string.byte '\t' then
					return nil
				end
				if c == string.byte '\n' then
					break
				end
				w3 = w3 .. utf8.encode(c)
			end
			
			return w1, w2, w3
		end
	end
	
	return readline
end

local chars = { }

local function toCodepoint(line)
	local b1, b2 = string.byte(line, 1, 2)

	if ((b1 == string.byte "U" or b1 == string.byte "U") and b2 == string.byte "+")
		or (b1 == string.byte "0" and (b2 == string.byte "x" or b == string.byte "X"))
	then
		return tonumber(string.sub(line, 3, #line), 16)
	else
		return nil
	end
end

local function addDatabase(filename)
	-- reading the whole file in takes very little time -- most of the time gets wasted constructing temporary strings later on
	print ("Indexing: " .. filename)
	
	local file = io.open(filename, "rb")
	local data = file:read("*all")
	file:close()

	data = encodings.toUtf8(data)
	
	for a, b, c in lines(utf8.chars(data)) do
		a = toCodepoint(a)
			
		if a ~= nil then
			local char = chars[a]
			if char == nil then
				char = {}
				chars[a] = char
			end
			char[b] = c
		end
	end
end

local function tojson(chars_used, columns_used)
	local digest = { }
	for k, v in pairs(chars) do
		if chars_used[k] then
			local columns = { }
			digest[utf8.encode(k)] = columns
			for k, v in pairs(v) do
				if not columns_used or columns_used[k] then
					columns[k] = v
				end
			end
		end
	end
	
	return json.encode(digest)
end

-- { separator = "\t", comment = "#", 

return {
	addDatabase = addDatabase,
	tojson = tojson
}


