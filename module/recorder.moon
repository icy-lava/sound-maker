export lmath, vec2
Button = require 'widget.button'
Toggle = require 'widget.toggle'
-- Slider = require 'widget.slider'
BufferDisplay = require 'widget.buffer_display'
class Recorder extends require 'module'
	name: 'recorder'
	inputLabels: {nil, 'phase offset', 'octave offset', 'play (rising edge)', 'stop (rising edge)'}
	new: (...) =>
		super ...
		@size.x = 64 * 9
		@size.y = 64 * 6
		@setInputCount 5
		@setOutputCount 1
		
		rec = @
		
		@phase = 0
		@canPlay = true
		@canStop = false
		
		do
			@display = BufferDisplay @, vec2(32, 36), vec2 @size.x - 64, 64 * 3
		
		do
			size = (@size.x - 32 * 2 - 16 * 3) / 4
			@play = Toggle @, vec2(32, 24 + 52 * 5 - 12), vec2 size, 40
			@play.label = 'play'
			
			@record = Toggle @, vec2(32 + size + 16, 24 + 52 * 5 - 12), vec2 size, 40
			@record.label = 'record'
			
			@clear = Button @, vec2(32 + (size + 16) * 2, 24 + 52 * 5 - 12), vec2 size, 40
			@clear.label = 'clear'
			@clear.action = => rec.display\clear!
			
			@loop = Toggle @, vec2(32 + (size + 16) * 3, 24 + 52 * 5 - 12), vec2 size, 40
			@loop.label = 'loop'
		
		-- do
		-- 	@smooth = Slider @, vec2(32, 24 + 52 * 6), vec2 @size.x - 64, 40
		-- 	@smooth.defaultValue = 0.5
		-- 	@smooth.value = @smooth.defaultValue
		-- 	@smooth.minValue = 1e-12
		-- 	@smooth.maxValue = 1
		-- 	@smooth.getLabel = => 'Smoothing'
	
	_process: =>
		ibuf = @getInput 1
		phbuf = @getInput 2
		fbuf = @getInput 3
		pbuf = @getInput 4
		sbuf = @getInput 5
		obuf = @getOutput 1
		
		phase = @phase
		phaseStep = 1 / @workspace.sampleRate
		display = @display
		isPlaying = @play.status
		isLooping = @loop.status
		isRecording = @record.status
		canPlay = @canPlay
		canStop = @canStop
		
		if isRecording
			display\appendBuffer ibuf
		
		for i = 0, @getBufferSize! - 1
			if pbuf[i] > 0.5
				if canPlay
					isPlaying = true
					phase = 0
					canPlay = false
			else canPlay = true
			if sbuf[i] > 0.5
				if canStop
					isPlaying = false
					phase = 0
					canStop = false
			else canStop = true
			if isPlaying
				obuf[i] = display\getSample phase + phbuf[i]
				phase += phaseStep * 2 ^ fbuf[i]
			else
				obuf[i] = 0
			while true
				len = display\getLength!
				break if phase < len
				if isLooping
					phase -= len
				else
					isPlaying = false
					phase = 0
					break
		@display.phase = phase
		@phase = phase
		@play.status = isPlaying
		@canPlay = canPlay
		@canStop = canStop