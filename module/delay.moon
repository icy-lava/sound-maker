export lmath, vec2
buffer = require 'buffer'
Slider = require 'widget.slider'
class Delay extends require 'module'
	name: 'delay'
	new: (...) =>
		super ...
		@setInputCount 2
		@setOutputCount 1
		@delayIndex = 0
		
		delay = @
		
		do
			@maxDelay = Slider @, vec2(32, 24), vec2 @size.x - 64, 40
			@maxDelay.defaultValue = math.pow(1 / 10, 1 / 3)
			@maxDelay.value = @maxDelay.defaultValue
			@maxDelay.minValue = math.pow(0.001 / 10, 1 / 3)
			@maxDelay.maxValue = 1
			@maxDelay.getLabel = =>
				mdelay = delay\getMaxDelay!
				if mdelay < 0.5
					string.format('Max delay: %dms', mdelay * 1000)
				else
					string.format('Max delay: %0.1fs', mdelay)
		
		do
			@feedback = Slider @, vec2(32, 36 + 40), vec2 @size.x - 64, 40
			@feedback.defaultValue = 0
			@feedback.value = @feedback.defaultValue
			@feedback.minValue = -1
			@feedback.maxValue = 1
			@feedback.getLabel = => string.format('Feedback: %d%%', @value * 100)
	
	getMaxDelay: => @maxDelay.value ^ 3 * 10
	getMaxDelaySamples: => lmath.round @getMaxDelay! * @workspace.sampleRate
	
	_process: =>
		ibuf = @getInput 1
		dbuf = @getInput 2
		obuf = @getOutput 1
		maxDelaySamples = @getMaxDelaySamples!
		if @bufferSamples != maxDelaySamples
			@bufferSamples = maxDelaySamples
			@delayBuffer = buffer.new maxDelaySamples
			@delayIndex = 0
		delay = 1
		feedback = @feedback.value
		for i = 0, @getBufferSize! - 1
			@delayBuffer[@delayIndex] = ibuf[i]
			
			delay = dbuf[i] if @hasInput 2
			delayOffset = lmath.clamp(delay, 0, 1)
			index = @delayIndex - (maxDelaySamples - 1) * delayOffset
			index0 = math.floor(index) % maxDelaySamples
			index1 = math.ceil(index) % maxDelaySamples
			fraction = index % 1
			sample = lmath.lerp fraction, @delayBuffer[index0], @delayBuffer[index1]
			
			obuf[i] = sample
			@delayBuffer[@delayIndex] += sample * feedback
			@delayIndex = (@delayIndex + 1) % maxDelaySamples