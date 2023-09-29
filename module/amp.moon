export lmath, vec2, util
Toggle = require 'widget.toggle'
Slider = require 'widget.slider'
class Amp extends require 'module'
	name: 'amp'
	new: (...) =>
		super ...
		@setInputCount 1
		@setOutputCount 1
		@size.y = 128
		
		@minAmp = 0
		@maxAmp = 2
		@minDB = -96
		@defaultAmp = 1
		@defaultDB = 0
		
		@slider = Slider @, vec2(32, 24), vec2 96 * 2, 40
		@slider.defaultValue = @defaultAmp
		@slider.value = @slider.defaultValue
		@slider.minValue = @minAmp
		@slider.maxValue = @maxAmp
		
		@asDB = false
		@db = Toggle @, vec2(@size.x - 80, 24), vec2 48, 40
		@db.label = 'dB'
		
		amp = @
		@db.toggle = =>
			slider = amp.slider
			if @status
				amp.asDB = true
				slider.defaultValue = amp.defaultDB
				slider.value = util.amp2db slider.value
				slider.minValue = amp.minDB
				slider.maxValue = util.amp2db amp.maxAmp
				lmath.clamp slider.value, slider.minValue, slider.maxValue
			else
				amp.asDB = false
				slider.defaultValue = amp.defaultAmp
				slider.value = if slider.value <= -96
					0
				else
					util.db2amp slider.value
				slider.minValue = amp.minAmp
				slider.maxValue = amp.maxAmp
		@slider.getLabel = =>
			value = amp.slider.value
			return if amp.asDB
				if value <= amp.minDB then '-inf dB'
				else string.format '%0.1f dB', amp.slider.value
			else string.format '%0.1f%%', amp.slider.value * 100
	getAmp: => 
		value = @slider.value
		if @asDB
			if value <= @minDB then 0
			else util.db2amp @slider.value
		else value
	
	_process: =>
		ibuf = @getInput 1
		obuf = @getOutput 1
		amp = @getAmp!
		for i = 0, @getBufferSize! - 1
			obuf[i] = ibuf[i] * amp