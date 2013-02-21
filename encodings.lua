local utf8 = require "utf-8"
--local utf16 = require "utf-16"
--local gb = require "cn-gb"
--local big5 = require "cn-big5"

local encodings = { }

function encodings.detect(str)
	return utf8
end

function encodings.toUtf8(str)
	return str
end

function encodings.lines(filename)
	
end

local mt = {
	
}

-- local function wrap_string_type(

return encodings

