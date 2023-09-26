floatArray = require'ffi'.typeof 'float[?]'

buffer = {}
buffer.new = (size) -> floatArray(size)

return buffer