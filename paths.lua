-- temporary glue that should last until we finish 

local ffi = require "ffi"
local forFiles

if ffi.os == "Windows" then
	ffi.cdef[[ 
	#pragma pack(push)
	#pragma pack(1)
	  struct WIN32_FIND_DATAA
	  {
		uint32_t dwFileAttributes;
		uint64_t ftCreationTime;
		uint64_t ftLastAccessTime;
		uint64_t ftLastWriteTime;
		struct
		{
		  union
		  {
			uint64_t packed;
			struct
			{
			  uint32_t high;
			  uint32_t low;
			};
		  };
		} nFileSize;
		uint32_t dwReserved[2];
		char cFileName[260];
		char cAlternateFileName[14];
	  };
	#pragma pack(pop)
	  void* FindFirstFileA(const char* pattern, struct WIN32_FIND_DATAA* fd);
	  bool FindNextFileA(void* ff, struct WIN32_FIND_DATAA* fd);
	  bool FindClose(void* ff);
	]]

	local WIN32_FIND_DATAA = ffi.typeof("struct WIN32_FIND_DATAA")
	local INVALID_HANDLE = ffi.cast("void*", -1)

	function forFiles (pattern)
		local descriptor = ffi.new(WIN32_FIND_DATAA)

		local files = {}
		local handle = ffi.C.FindFirstFileA(pattern, descriptor)
		if handle ~= INVALID_HANDLE then
			ffi.gc(handle, ffi.C.FindClose)
			repeat
				if ffi.abi "le" then
					descriptor.nFileSize.low, descriptor.nFileSize.high = descriptor.nFileSize.high, descriptor.nFileSize.low
				end
				files[ffi.string(descriptor.cFileName)] = {
					attr = descriptor.dwFileAttributes,
					creationtime = descriptor.ftCreationTime,
					accesstime = descriptor.ftLastAccessTime,
					writetime = descriptor.ftLastWriteTime,
					size = tonumber(descriptor.nFileSize.packed),
					kb = tonumber(descriptor.nFileSize.packed / 1024),
				}
			until not ffi.C.FindNextFileA(handle, descriptor)
			ffi.C.FindClose(ffi.gc(handle, nil))
		end
		return next, files
	end
else
	local headerfile = io.open("file-header.h", "r")
	if not headerfile then
		os.execute("./generate-header.sh")
		headerfile = io.open("file-header.h", "r")
	end
	if not headerfile then
		error "generate-header.sh apparently failed to produce a usable header"
	end

	ffi.cdef (headerfile:read("*all"))

	local function findlast(str, pat)
		local idx, nxt = 0, 0
		repeat
			idx = nxt
			nxt = str:find(pat, idx + 1, true)
		until nxt == nil
		return idx
	end

	local function matcheswildcard(str, pat)
		pat = pat:lower():gsub("%.", "%."):gsub("%*", ".+")
		if str:lower():match(pat) then
			return true
		else
			return false
		end
	end

	function forFiles (pattern)
		-- the pattern is a Windows-style deal, although it does use forward
		-- slashes; we've got to parse it ourselves

		local slash = findlast(pattern, "/")
		local dir, match = pattern:sub(1, slash - 1), pattern:sub(slash + 1)

		local dp = ffi.C.opendir(dir)
		local files = {}

		if dp ~= nil then
			ffi.gc(dp, ffi.C.closedir)

			local statbuf = ffi.new("struct stat")

			while true do
				local ep = ffi.C.readdir(dp)
				
				if ep ~= nil then
					local name = ffi.string(ep.d_name)
					if matcheswildcard(name, match) then
						files[name] = {
							attr = 0,
							creationtime = statbuf.st_ctim,
							accesstime = statbuf.st_atim,
							writetime = statbuf.st_mtim,
							size = tonumber(statbuf.st_size),
							kb = tonumber(statbuf.st_size / 1024),
						}
					end
				else
					break
				end
			end
			ffi.C.closedir(ffi.gc(dp, nil))
		end

		return next, files
	end
end

return {
	files = forFiles
}

