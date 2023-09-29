export lmath, util
class Sine extends require 'module.amp'
	name: 'output'
	inputLabels: {'system audio'}
	new: (...) =>
		super ...
		@setInputCount 1
		@setOutputCount 0
		@maxAmp = 1
		@defaultAmp = 0.5
		@defaultDB = util.amp2db 0.25
		@db\action!
		@slider.value = @defaultDB
	
	_process: =>
		ibuf = @getInput(1)
		obuf = @workspace.outputPreBuffer
		amp = @getAmp!
		for i = 0, @getBufferSize! - 1
			obuf[i] += ibuf[i] * amp