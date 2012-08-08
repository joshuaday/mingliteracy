local utf8 = require "utf-8"
local html = { }

local WIDTH = 80

local nodemt
local textmt

local onwrite =  {
	html = function(e)
		e.head:firstOrPrepend("title"):raw(e.title or "Untitled")
		
		e.head:node ("meta", 1) :attr("http-equiv", "Content-Type") :attr("content", "text/html; charset=utf-8")
	end
}

local onmake = {
	html = function(e)
		e.head = e:node "head"
		e.body = e:node "body"
		
		e._locked = true
	end
}

local emptyelements = {
	meta = true,
	link = true,
	script = false
}

function encode(codepoint)
	if type(codepoint) == "number" then
		if codepoint > 0 and codepoint < 128 then
			return string.char(codepoint)
		else
			return utf8.encode(codepoint)
			--return "&#" .. tostring(codepoint) .. ";"
		end
	else
		return ""
	end
end


local function node(name)
	local n = setmetatable({_name = name, _attr = {}}, nodemt)
	if onmake[name] then
		onmake[name](n)
	end
	return n
end

local function text(txt)
	return setmetatable({text = txt}, textmt)
end

textmt = {
	__index = {
		writeto = function (e, file, tab)
			-- find the last whitespace (or end-of-string) before tab + index > WIDTH, or, if there is none, find the first whitespace
			
			local haswidth = false
			
			local width = WIDTH - #tab
			local text = e.text
			
			local x, idx, wordidx, endidx = width, 0, nil, nil
			local needspace, firstline = false, true
			
			while true do
				-- skip characters as long as they're just control characters or whitespace
				repeat
					idx = idx + 1
					local c = string.byte(text, idx)
					if c == nil then
						file:write("\n")
						return
					end
				until c > 32
				
				-- peek at characters until one is whitespace or nil
				wordidx = idx
				repeat
					idx = idx + 1
					local c = string.byte(text, idx)
				until c == nil or c <= 32
				
				endidx = idx - 1
				
				local wordwidth = 1 + endidx - wordidx
				if haswidth and x + wordwidth > width then
					if not firstline then
						file:write "\n"
					end
					file:write(tab)
					x = 1
					needspace, firstline = false, false
				else
					if needspace then
						file:write " "
						needspace = false
						x = x + 1
					end
				end
				
				file:write(string.sub(text, wordidx, endidx))
				
				x = x + wordwidth
				needspace = true
			end
		end
	}
}

nodemt = {
	__index = {
		append = function(e, e2, idx)
			if not e._locked then
				-- e2._up = e
				table.insert(e, idx or (#e + 1), e2)
			end
			
			return e
		end,
		
		attr = function(e, name, value)
			e._attr[name] = value -- todo : parse it and be clever
			return e
		end,
		
		node = function(e, name, idx)
			local n = node(name)
			e:append(n, idx)
			return n
		end,
		
		raw = function(e, txt)
			if type(txt) == "number" then
				txt = encode(txt)
			end
			if e[#e] and e[#e].text then
				e[#e].text = e[#e].text .. txt
			else
				e:append(text(txt))
			end
			return e
		end,
		
		class = function(e, txt)
			e._attr.class = txt .. " " .. (e._attr.class or "") -- for now!
			return e
		end,
		
		style = function(e, txt)
			e._attr.style = txt .. " " .. (e._attr.style or "") -- for now!
			return e
		end,
		
		writeto = function (e, file, tab)
			local close = false
			if type(file) == "string" then
				file, close = io.open(file, "w"), true
			end
			
			tab = tab or ""
			
			if e._name and onwrite[e._name] then
				onwrite[e._name](e)
			end			
			
			file:write(tab, "<", e._name)
			for attr, text in pairs(e._attr) do
				file:write(" ", attr, [[="]], text, [["]]) -- todo : escape text properly
			end
			
			
			if #e == 0 and emptyelements[e._name] then
				file:write("/>", "\n")
			else
				file:write(">", "\n")
				
				for i = 1, #e do
					e[i]:writeto(file, tab .. "  ")
				end
				file:write(tab, "</", e._name, ">", "\n")
			end
			
			if close then
				file:close()
			end
		end,
		
		firstOrPrepend = function(e, tagname)
			for i = 1, #e do
				if e[i]._name == tagname then -- todo : should this be case insensitive?
					return e[i]
				end
			end
			
			local n = node(tagname)
			e:append(n, 1)
			return n
		end,
		
		select = function(e, selector)
			return 
		end
	}
}

function html.document()
	return node "html"
end


return html
