#! /usr/bin/env luajit

local argreader = require "argreader"
local arguments = argreader.parse(arg)

local literacy = require "literacy"
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

local primer_filenames, stele_filenames = arguments["--primers"], arguments["--steles"]

if not primer_filenames then
	local paths = require "paths"
	primer_filenames = { }
	for name, info in paths.files "primers/*.txt" do
		local filename = "primers/" .. name
		primer_filenames[1 + #primer_filenames] = filename
	end
end

if not stele_filenames then
	local paths = require "paths"
	stele_filenames = { }
	for name, info in paths.files "steles/*.txt" do
		local filename = "steles/" .. name
		stele_filenames[1 + #stele_filenames] = filename
	end
end

-- process the primers
print "\nPrimers:"
for i = 1, #primer_filenames do
	local filename = primer_filenames[i]
	
	primers.scan {
		filename = filename,
		reference = true
	}
end

print "\nSteles:"
-- process the steles for subphrases
for i = 1, #stele_filenames do
	local filename = stele_filenames[i]

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

document:writeto "output.html"

print "\nDone.\n"

