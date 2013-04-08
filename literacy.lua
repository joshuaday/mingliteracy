local encodings = require "encodings"
local utf8 = require "utf-8"
local json = require "json"
local builder = require "builder"

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
			isPrimer = options.reference,
			tags = {},
			references = { }
		}		
		
		local document_index = 1 + #documents
		documents[document_index] = document
		
		local text = builder.estimate(#data) -- creates a buffer large enough to accept the data without resizing
		
		-- register all the characters!
		
		local c1, c2, c3
		
		local charnum = 0
		local isnewline, tag_builder, tagmode = true, builder.new(), false
		local tag = "body" -- if there are no tags, just treat the whole text as the body
	
		local function commit_chunk()
			if text.length > 0 then
				document.tags[tag] = tostring(text)
				text:clear()
				charnum = 0
			end
		end

		if options.reference then
			io.stdout:write ("Reference: ", filename, "\n")
		else
			io.stdout:write ("Document: ", filename, "\n")
		end
			 
		local histogram = { } -- this gets written directly for js consumption

		for i, char in utf8.chars(data) do
			if isnewline and char == string.byte ":" then
				-- start reading a new tag; first commit the previous tag and its chunk, if we had one
				commit_chunk()
				tag_builder:clear()
				tagmode = true
			elseif tagmode then
				if isnewline or char == string.byte ":" then
					tag = tostring(tag_builder)
					tagmode = false
				else
					tag_builder:appendbytes(utf8.encodebytes(char))
				end
			elseif filter(char) then
				charnum = charnum + 1

				local as_utf8 = utf8.encode(char) -- improve this not to return a string
				text:append(as_utf8) -- copy the character into the output text
				
				if tag == "body" then
					-- process the histogram and rolling trigrams only in the body
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

			isnewline = char == 10 or char == 13
		end
		
		commit_chunk()
		document.histogram = histogram
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
