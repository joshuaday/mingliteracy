local ffi = require "ffi"

local builder = { }
local __index = { }
local mt = {__index = __index}

local newchar = ffi.typeof("char[?]")

function ensuresize(s, len)
	if len + s.length > s.bufferlength then
		local newbufferlength = 2 * (len + s.length)
		local newbuffer = newchar(newbufferlength)
		
		ffi.copy(newbuffer, s.buffer, s.length)
		
		rawset(s, "bufferlength", newbufferlength)
		rawset(s, "buffer", newbuffer)
	end	
end

function __index.append(s, ...)
	for i = 1, select("#", ...) do
		local v = select(i, ...)
		local len
		
		if getmetatable(v) == mt then
			v, len = v.buffer, v.length
		else
			v = tostring(v)
			len = #v
		end
		
		ensuresize(s, len)
		
		ffi.copy(s.buffer + s.length, v, len)
		rawset(s, "length", s.length + len)
	end
	
	rawset(s, "asstring", nil)
	
	return s
end

function __index.appendbytes(s, ...)
	local len = select("#", ...)
	ensuresize(s, len)
	
	for i = 1, len do
		s.buffer[s.length + i - 1] = select(i, ...)
	end	
	
	rawset(s, "length", s.length + len)
	rawset(s, "asstring", nil)
end

function __index.clear(s)
	rawset(s, "length", 0)
	rawset(s, "asstring", nil)
	
	return s
end

function mt.__tostring(s)
	if not s.asstring then
		rawset(s, "asstring", ffi.string(s.buffer, s.length))
	end
	return s.asstring
end

function mt.__concat(a, b)
	-- need to return an incompletely constructed instance to represent the concatenation
	return builder.new(a, b)
end

function mt.__length(s)
	return s.length
end

function builder.new(...)
	s = setmetatable({}, mt)
	rawset(s, "length", 0)
	rawset(s, "bufferlength", 256)
	rawset(s, "buffer", newchar(s.bufferlength))
	
	s:append(...)
	
	return s
end

function builder.estimate(estimated_max)
	s = setmetatable({}, mt)
	rawset(s, "length", 0)
	rawset(s, "bufferlength", math.ceil(256 + estimated_max))
	rawset(s, "buffer", newchar(s.bufferlength))
	
	return s
end

return builder
