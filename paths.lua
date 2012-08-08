-- temporary glue that should last until we finish 

local ffi = require "ffi"

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

local function forFiles (pattern)
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

return {
	files = forFiles
}
