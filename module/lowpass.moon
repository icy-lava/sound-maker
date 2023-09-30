export lmath, vec2
Slider = require 'widget.slider'
class Lowpass extends require 'module'
	name: 'low pass'
	inputLabels: {nil, 'octave offset'}
	new: (...) =>
		super ...
		@size.y = 64 * 2
		@setInputCount 2
		@setOutputCount 1
		@lastSample = 0
		
		lowpass = @
		do
			@freq = Slider @, vec2(32, 24), vec2 @size.x - 64, 40
			@freq.defaultValue = 0.5
			@freq.value = @freq.defaultValue
			@freq.minValue = 0
			@freq.maxValue = 1
			@freq.getLabel = => string.format('Cutoff: %dhz', lowpass\getFreq!)
	
	getFreq: => @freq.value ^ 2 * @workspace.sampleRate / 2
	
	_process: =>
		ibuf = @getInput 1
		fbuf = @getInput 2
		obuf = @getOutput 1
		sample = @lastSample
		sampleRate = @workspace.sampleRate
		tau = lmath.tau
		freq = @getFreq!
		for i = 0, @getBufferSize! - 1
			alpha = sampleRate / (tau * (freq * 2 ^ fbuf[i]) + sampleRate)
			alpha = lmath.clamp alpha, 1e-6, 1 - 1e-6
			sample = alpha * sample + (1 - alpha) * ibuf[i]
			obuf[i] = sample
		@lastSample = sample