local encodings = require "encodings"
local utf8 = require "utf-8"
local json = require "json"

local function filter(codepoint)
	-- allow characters in these UNICODE pages:
	-- CJK Unified Ideographs Extension A
	-- Yijing Hexagram Symbols
	-- CJK Unified Ideographs
	-- And the following extensions:
	-- 20000¡V215FF
	-- 21600¡V230FF
	-- 23100¡V245FF
	-- 24600¡V260FF
	-- 26100¡V275FF
	-- 27600¡V290FF
	-- 29100¡V2A6DF
	-- 2A700¡V2B73F
	-- 2B740¡V2B81F
	

	return (codepoint >= 0x3400 and codepoint <= 0x9fff) or (codepoint >= 0x20000 and codepoint <= 0x2B81F)
end

local function triadize(c1, c2, c3)
	-- there are 0x6C00 characters in the primary range that interests us; for characters in the 20000 - 2B81F range, we'll get overlapping results,
	-- but because of the rarity of those characters and the nature of these triads, that's still just fine for our hashing

	return ((c1 - 0x3400) * 0x6c00 + (c2 - 0x3400)) * 0x6c00 + (c3 - 0x3400)
end

local function lexicon()
	local documents = { }
	local store, triads = { }, { }

	local function scan(options)
		local descriptor = { }
	
		local filename = options.filename
		
		local file = io.open(filename, "rb")
		local data = file:read("*all")
		file:close()
		
		--[[
			get the correct encoding.  encodings.detect looks at the entire body of data to make sure it's got it right,
			so it definitely introduces some overhead -- but to avoid seemingly bizarre misinterpretations, this is the
			right thing to do.  right now, we assume that the text we're processing is entirely Chinese, and we assume
			that we have a fixed file format (free text comments on top, a line of ##### and then document text), but all
			of the text is assumed to be in the same encoding, so we get the encoding first
		]]--
		
		data = encodings.toUtf8(data)
		
		local document = {
			filename = encodings.toUtf8(filename),
			text = data,
			isPrimer = options.reference,
			references = { }
		}		
		
		local document_index = 1 + #documents
		documents[document_index] = document
		
		
		-- register all the characters!
		
		local c1, c2, c3
		
		if options.reference then
			print ("Reference: " .. filename)
			 
			local histogram = { } -- this gets written directly for js consumption
			local charnum = 0
			for i, char in utf8.chars(data) do
				charnum = charnum + 1
				if filter(char) then
					local as_utf8 = utf8.encode(char)
					
					c1, c2, c3 = c2, c3, char
				
					for i = 1 + #store, char - 1 do
						store[i] = false
					end
					
					local entry = store[char]
					if not entry then
						entry = { }
						store[char] = entry
					end
					
					entry[1 + #entry] = {document, i} -- in this document, at position i (might want to include the encoding?) -- no, because output is always utf8
					
					histogram[as_utf8] = 1 + (histogram[as_utf8] or 0)
					
					if c1 then
						local triad = triadize(c1, c2, c3)
						
						local entry = triads[triad]
						if not entry then
							entry = { }
							triads[triad] = entry
						end
						
						entry[1 + #entry] = {
							document = document_index,
							character = charnum
						} -- in this document, ending at character number i
					end
				end
			end
			
			document.histogram = histogram;
		else
			print ("Processing: " .. filename)
			local callback = options.callback or function () end
			local charnum = 0
			
			for i, char in utf8.chars(data) do
				charnum = charnum + 1
				
				local filtered = filter(char)
				local known = false
				
				if filtered then
					c1, c2, c3 = c2, c3, char
					known = not not store[char]
					
					if c1 then
						local triad = triadize(c1, c2, c3)
						local entry = triads[triad]
						if entry then
							document.references[1 + #document.references] = entry -- maybe not the best?
						end
					end
				end
				
				callback(char, filtered, known)
			end
		end
	end
	
	local function tojson()
		local digest = {
			documents = documents
		}
		
		return json.encode(digest)
	end
	
	return {
		scan = scan,
		documents = documents,
		characters_seen = store,
		tojson = tojson
	}
end


return {
	lexicon = lexicon
}
