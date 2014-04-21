local argreader = { }

function argreader.parse(args)
	local switches = { }
	local files = { }

	switches["--"] = files
	for i = 1, #args do
		local arg = args[i]
		if arg:match("^-") then
			files = switches[arg] or { }
			switches[arg] = files
		else
			files[1 + #files] = arg
		end
	end

	return switches
end

return argreader

