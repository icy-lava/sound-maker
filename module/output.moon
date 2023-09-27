export lmath
class Sine extends require 'module'
	name: 'output'
	new: (...) =>
		super ...
		@setInputCount 1
	
	_process: =>
		ibuf = @getInput(1)
		obuf = @workspace.outputPreBuffer
		for i = 0, @getBufferSize! - 1
			obuf[i] += ibuf[i]