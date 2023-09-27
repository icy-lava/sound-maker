export lmath
buffer = require 'buffer'
class Sine extends require 'module'
	name: 'delay'
	new: (...) =>
		super ...
		@setInputCount 1
		@setOutputCount 1
		@delay = 0.5
		@maxDelay = 1
		@delaySamples = lmath.round @maxDelay * @workspace.sampleRate
		@delayBuffer = buffer.new @delaySamples
		@delayIndex = 0
	
	_process: =>
		ibuf = @getInput 1
		obuf = @getOutput 1
		for i = 0, @getBufferSize! - 1
			@delayBuffer[@delayIndex] = ibuf[i]
			
			delayOffset = math.min(@delay, @maxDelay) / @maxDelay
			index = @delayIndex - (@delaySamples - 1) * delayOffset
			index0 = math.floor(index) % @delaySamples
			index1 = math.ceil(index) % @delaySamples
			fraction = index % 1
			sample = lmath.lerp fraction, @delayBuffer[index0], @delayBuffer[index1]
			
			obuf[i] = sample
			@delayIndex = (@delayIndex + 1) % @delaySamples