local ffi = require 'ffi'
local floatArray = ffi.typeof 'float[?]'

local buffer = {}

function buffer.new(size)
	return floatArray(size)
end

return buffer