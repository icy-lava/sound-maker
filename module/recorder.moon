export lmath, vec2, love
ffi = require 'ffi'
Button = require 'widget.button'
Toggle = require 'widget.toggle'
-- Slider = require 'widget.slider'
BufferDisplay = require 'widget.buffer_display'
class Recorder extends require 'module'
	name: 'recorder'
	inputLabels: {nil, 'phase offset', 'octave offset', 'sync (rising edge)', 'play (rising edge)', 'stop (falling edge)'}
	new: (...) =>
		super ...
		@size.x = 64 * 9
		@size.y = 64 * 6
		@setInputCount 6
		@setOutputCount 1
		
		rec = @
		
		@canSync = true
		@canPlay = true
		@canStop = false
		
		do
			@display = BufferDisplay @, vec2(32, 36), vec2 @size.x - 64, 64 * 3
			@display.phase = 0
		
		do
			size = (@size.x - 32 * 2 - 16 * 4) / 5
			@play = Toggle @, vec2(32, 24 + 52 * 5 - 12), vec2 size, 40
			@play.label = 'play'
			
			@record = Toggle @, vec2(32 + size + 16, 24 + 52 * 5 - 12), vec2 size, 40
			@record.label = 'record'
			
			@clear = Button @, vec2(32 + (size + 16) * 2, 24 + 52 * 5 - 12), vec2 size, 40
			@clear.label = 'clear'
			@clear.action = =>
				rec.display\clear!
				rec.phase = 0
			
			@loop = Toggle @, vec2(32 + (size + 16) * 3, 24 + 52 * 5 - 12), vec2 size, 40
			@loop.label = 'loop'
			
			@export = Button @, vec2(32 + (size + 16) * 4, 24 + 52 * 5 - 12), vec2 size, 40
			@export.label = 'export'
			@export.action = =>
				filename = os.date '%Y-%m-%d_%H_%M_%S_'
				filename ..= @module.workspace.generation .. '.wav'
				
				buffers = rec.display.buffers
				bufferLength = @module\getBufferSize!
				bufferSize = bufferLength * 8
				bufferCount = #buffers
				
				sampleCount = rec.display\getSampleCount!
				sampleRate = @module.workspace.sampleRate
				dataRate = sampleRate * 8
				blockSize = 8
				bitsPerSample = 8 * 8
				
				fmtHeader = love.data.pack 'string', '<c4I4I2I2I4I4I2I2', 'fmt ', 16, 3, 1, sampleRate, dataRate, blockSize, bitsPerSample
				factHeader = love.data.pack 'string', '<c4I4I4', 'fact', 4, sampleCount
				dataHeader = love.data.pack 'string', '<c4I4', 'data', sampleCount * 8
				
				riffSize = 12
				totalBytes = riffSize + #fmtHeader + #factHeader + #dataHeader + sampleCount * 8
				data = love.data.newByteData totalBytes
				
				chunkSize = totalBytes - 8
				riffHeader = love.data.pack 'string', '<c4I4c4', 'RIFF', chunkSize, 'WAVE'
				pointer = ffi.cast 'uint8_t*', data\getFFIPointer!
				ffi.copy pointer, riffHeader, #riffHeader
				pointer += #riffHeader
				ffi.copy pointer, fmtHeader, #fmtHeader
				pointer += #fmtHeader
				ffi.copy pointer, factHeader, #factHeader
				pointer += #factHeader
				ffi.copy pointer, dataHeader, #dataHeader
				pointer += #dataHeader
				for i = 1, bufferCount
					ffi.copy pointer, buffers[i], bufferSize
					pointer += bufferSize
				
				assert love.filesystem.write filename, data
				statusLine = string.format 'Last export: %s/%s', love.filesystem.getRealDirectory(filename), filename
				@module.workspace.exportStatus = statusLine
	
	_process: =>
		ibuf = @getInput 1
		phbuf = @getInput 2
		fbuf = @getInput 3
		sybuf = @getInput 4
		pbuf = @getInput 5
		sbuf = @getInput 6
		obuf = @getOutput 1
		
		phase = @display.phase
		phaseStep = 1 / @workspace.sampleRate
		display = @display
		isPlaying = @play.status
		isLooping = @loop.status
		isRecording = @record.status
		canSync = @canSync
		canPlay = @canPlay
		canStop = @canStop
		
		if isRecording
			display\appendBuffer ibuf
		
		for i = 0, @getBufferSize! - 1
			if sybuf[i] > 0.5
				if canSync
					phase = 0
					canSync = false
			else canSync = true
			if pbuf[i] > 0.5
				if canPlay
					isPlaying = true
					canPlay = false
			else canPlay = true
			if sbuf[i] <= 0.5
				if canStop
					isPlaying = false
					canStop = false
			else canStop = true
			if isPlaying
				obuf[i] = display\getSample phase + phbuf[i]
				phase += phaseStep * 2 ^ fbuf[i]
			else
				obuf[i] = 0
			while true
				len = display\getLength!
				break if phase < len or len == 0
				if isLooping
					phase -= len
				else
					isPlaying = false
					phase = 0
					break
		@display.phase = phase
		@play.status = isPlaying
		@canSync = canSync
		@canPlay = canPlay
		@canStop = canStop