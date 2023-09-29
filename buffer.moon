ffi = require 'ffi'
doubleArray = ffi.typeof 'double[?]'
doubleSize = ffi.sizeof 'double'

buffer = {}
buffer.new = (size) -> doubleArray(size)
buffer.zero = (buf, len) -> ffi.fill buf, len * doubleSize
buffer.copy = (dest, source, len) -> ffi.copy dest, source, len * doubleSize

return buffer