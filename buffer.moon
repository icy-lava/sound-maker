ffi = require 'ffi'
floatArray = ffi.typeof 'float[?]'
floatSize = ffi.sizeof 'float'

buffer = {}
buffer.new = (size) -> floatArray(size)
buffer.zero = (buf, len) -> ffi.fill buf, len * floatSize

return buffer