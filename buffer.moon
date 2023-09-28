ffi = require 'ffi'
doubleArray = ffi.typeof 'double[?]'
doubleSize = ffi.sizeof 'double'

buffer = {}
buffer.new = (size) -> doubleArray(size)
buffer.zero = (buf, len) -> ffi.fill buf, len * doubleSize

return buffer