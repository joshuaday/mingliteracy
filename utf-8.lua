local ffi = require "ffi"
local bit = require "bit"

local utf8 = { }

-- there's a nice table-driven technique floating around the net that it might be worth replacing this with
local function getchar (s, i)
	-- returns length, ok
	-- where ok is true if the character beginning at i is valid (nil otherwise)

	-- see RFC 3629
	if type(s) ~= "string" then return nil end
	if type(i) ~= "number" then return nil end
	
	local c = s:byte(i)
	if not c then return nil end
	
	if c < 128 then
		-- some special logic to treat cr ('\r'), lf ('\n'), and crlf ("\r\n") identically, all as if they were '\n'
		if c == string.byte "\r" then
			if s:byte(i + 1) == 10 then
				return 2, true, string.byte "\n"
			else
				c = string.byte "\n"
			end
		end
		
		return 1, true, c
	elseif c < 194 then
		return 1
	elseif c < 224 then
		-- UTF8-2
		local c2 = s:byte(i + 1)
		if not c2 then return 1 end -- early termination
		
		if c2 < 128 or c2 > 191 then
			return 1, false
		else
			return 2, true, bit.bor(bit.lshift(bit.band(c, 0x1f), 6), bit.band(c2, 0x3f))
		end
	elseif c < 240 then
		-- UTF8-3
		local c2, c3 = s:byte(i + 1, i + 2)
		if not c3 then return 1 end -- early termination
		
		if (
			(c == 224 and c2 < 160)
			or (c == 237 and c2 > 159)
			or (c2 < 128 or c2 > 191)
			or (c3 < 128 or c3 > 191)
			)
		then
			return 1
		else
			return 3, true, bit.bor(bit.lshift(bit.band(c, 0x0f), 12), bit.lshift(bit.band(c2, 0x3f), 6), bit.band(c3, 0x3f))
		end
	elseif c < 245 then
		-- UTF8-4
		local c2, c3, c4 = s:byte(i + 1, i + 3)

		if not c4 then return 1 end -- early termination

		if (
			(c == 240 and (c2 < 144 or c2 > 191))
			or (c == 244 and (c2 < 128 or c2 > 143))
			or (c2 < 128 or c2 > 191)
			or (c3 < 128 or c3 > 191)
			or (c4 < 128 or c4 > 191)
			)
		then
			return 1
		else
			return 4, true, bit.bor(bit.lshift(bit.band(c, 0x0f), 18), bit.lshift(bit.band(c2, 0x3f), 12), bit.lshift(bit.band(c3, 0x3f), 6), bit.band(c4, 0x3f))
		end
	else
		return 1
	end
end


local function start(s)
	local idx = 1
	
	-- skip the Windows BOM if it exists
	if s:byte(1) == 0xef and s:byte(2) == 0xbb and s:byte(3) == 0xbf then
		idx = 4
	end
	
	return s, idx
end

function utf8.next(str, idx)
	if idx then
		if idx <= #str then
			local charlength, validchar = getchar(str, idx)
			idx = idx + charlength
		end
	else
		str, idx = start(str)
	end

	if idx <= #str then
		return idx, utf8.codepoint(str, idx)
	else
		return nil -- just to make it explicit!
	end	
end

function utf8.len(s)
	local s, idx = start(s)
	local count, bytes = 0, #s
	
	local valid = true
	
	while idx <= bytes do
		local charlength, validchar = getchar(s, idx)
		count, idx = count + 1, idx + charlength
		valid = valid and validchar
	end
	
	return count, valid
end

function utf8.codepoint(str, idx)
	local bytes, ok, codepoint = getchar(str, idx)
	
	if ok then
		return codepoint, bytes
	else
		return 0xfffd, bytes -- the replacement character
	end
end

function utf8.encode(codepoint)
	if codepoint < 0x80 then
		return string.char(codepoint)
	elseif codepoint < 0x0800 then
		return string.char(
			bit.bor(0xc0, bit.band(0x1f, bit.rshift(codepoint, 6))),
			bit.bor(0x80, bit.band(0x3f, codepoint))
		)
	elseif codepoint < 0x010000 then
		return string.char(
			bit.bor(0xe0, bit.band(0x0f, bit.rshift(codepoint, 12))),
			bit.bor(0x80, bit.band(0x3f, bit.rshift(codepoint, 6))),
			bit.bor(0x80, bit.band(0x3f, codepoint))
		)
	elseif codepoint < 0x200000 then
		return string.char(
			bit.bor(0xf0, bit.band(0x07, bit.rshift(codepoint, 18))),
			bit.bor(0x80, bit.band(0x3f, bit.rshift(codepoint, 12))),
			bit.bor(0x80, bit.band(0x3f, bit.rshift(codepoint, 6))),
			bit.bor(0x80, bit.band(0x3f, codepoint))
		)
	else
		return ""
	end
end

function utf8.html(str)
	if type(str) == "string" then
		local doc = { }
		for idx, char in utf8.chars(str) do
			doc[1 + #doc] = utf8.html(char)
		end
		return table.concat(doc)
	elseif type(str) == "number" then
		return "&#" .. tostring(str) .. ";"
	else
		return ""
	end
end

function utf8.chars(str)
	return utf8.next, str
end

return utf8
