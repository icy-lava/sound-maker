export lmath, util
class Sine extends require 'module.amp'
	name: 'output'
	new: (...) =>
		super ...
		@setInputCount 1
		@setOutputCount 0
		@maxAmp = 1
		@db\action!
		@slider.value = -6
	
	_process: =>
		ibuf = @getInput(1)
		obuf = @workspace.outputPreBuffer
		amp = @getAmp!
		for i = 0, @getBufferSize! - 1
			obuf[i] += ibuf[i] * amp