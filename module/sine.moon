export lmath
class Sine extends require 'module'
	name: 'sine'
	new: (...) =>
		super ...
		-- @setInputCount 1
		@setOutputCount 1
		@phase = 0
		@freq = 440
	
	_process: =>
		obuf = @getOutput(1)
		for i = 0, @getBufferSize! - 1
			obuf[i] = math.sin(@phase % 1 * lmath.tau)
			@phase = @phase + @freq / @workspace.sampleRate