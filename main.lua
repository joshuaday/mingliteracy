local literacy = require "literacy"
local paths = require "paths"
local html = require "html"

local document = html.document()

document.title = [[Chinese Cross-Reference]]
document.head:node "link" :attr ("rel", "stylesheet") :attr ("type", "text/css") :attr ("href", "primer.css")
document.head:node "script" :attr ("type", "text/javascript") :attr ("src", "js/jquery-1.7.2.js")
document.head:node "script" :attr ("type", "text/javascript") :attr ("src", "js/chinese.js")


local primers = literacy.lexicon()


local ZWSP = 0x200B -- zero-width space

local csv = require "csv"

csv.addDatabase "unicode/Unihan_Readings.txt"
csv.addDatabase "unicode/Unihan_Variants.txt"
csv.addDatabase "unicode/Unihan_RadicalStrokeCounts.txt"
csv.addDatabase "unicode/Unihan_OtherMappings.txt"


-- process the primers
print "\nPrimers:"
for name, info in paths.files "primers/*.txt" do
	local filename = "primers/" .. name
	
	primers.scan {
		filename = filename,
		reference = true
	}
end


local cursors = { } -- one entry for every sequence of characters (including length-1?) that matches the current position -- source document, length so far, index

print "\nSteles:"
-- process the steles for subphrases
for name, info in paths.files "steles/*.txt" do
	local filename = "steles/" .. name

	primers.scan {
		filename = filename
	}
end
	
-- grab the full output as json and write it out!

print "\nGenerating output..."

document.head :node "script" :attr ("type", "text/javascript") :raw "digest = " :raw (primers.tojson()) :raw ";"
-- document.head :node "script" :attr ("type", "text/javascript") :raw "unihan = " :raw (csv.tojson(primers.characters_seen)) :raw ";"
document.head :node "script" :attr ("type", "text/javascript") :raw "unihan = " :raw (csv.tojson(primers.characters_seen, {kMandarin = true, kTang = true, kDefinition = true})) :raw ";"

-- todo : as soon as possible, switch from kMandarin to 
-- kHanyuPinlu, falling back on kXHC1983 and then kHanyuPinyin. 


--[[
for _, data in pairs(primers.documents) do
	-- add a new div for each document
	local filename = data.filename
	
	local div = document.body:node "div"
	
	div :node "div" :class "infobox" :raw (filename)
	
	local top = div :node "div" :class "text"

	local function callback(codepoint, ischar, known)
		--local included = not filter(char) or dictionary[char]
		
		if codepoint == 10 or codepoint == 13 then
			top :raw ("<br/>")
			return
		end
		
		known = known or not ischar
		
		--if spantype ~= known then
			--if known then
			--	span = div :node "span" :class "known"
			--else
			--	span = div :node "span" :class "unknown"
			--end
			
			--spantype = known
		--end
		
		top :raw (codepoint)
	end
end
]]--

document:writeto "output.html"
