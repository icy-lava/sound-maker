export lmath, vec2, util
Toggle = require 'widget.toggle'
class PolarMap extends require 'module'
	name: 'bipolar <=> unipolar'
	new: (...) =>
		super ...
		@setInputCount 1
		@setOutputCount 1
		@size.y = 64 * 3
		
		b2u = 'bipolar => unipolar'
		u2b = 'unipolar => bipolar'
		@polar = Toggle @, vec2(32, 24), vec2 96 * 2, 40
		@polar.label = b2u
		@fromBipolar = true
		@updateLabels!
		
		@clip = Toggle @, vec2(@size.x - 80, 24), vec2 48, 40
		@clip.label = 'clip'
		
		do
			size = (@size.x - 32 * 2 - 16) / 2
			@invertInput = Toggle @, vec2(32, 40 + 40), vec2 size, 40
			@invertInput.label = 'invert in'
			
			@invertOutput = Toggle @, vec2(32 + size + 16, 40 + 40), vec2 size, 40
			@invertOutput.label = 'invert out'
		
		map = @
		@polar.toggle = =>
			map.fromBipolar = not @status
			@label = map.fromBipolar and b2u or u2b
			map\updateLabels!
	updateLabels: =>
		@inputLabels = @fromBipolar and {'bipolar input'} or {'unipolar input'}
		@outputLabels = @fromBipolar and {'unipolar output'} or {'bipolar output'}
	_process: =>
		ibuf = @getInput 1
		obuf = @getOutput 1
		fromMin = @fromBipolar and -1 or 0
		fromMax = 1
		toMin = @fromBipolar and 0 or -1
		toMax = 1
		clip = @clip.status
		inputMul = @invertInput.status and -1 or 1
		outputMul = @invertOutput.status and -1 or 1
		for i = 0, @getBufferSize! - 1
			sample = lmath.map ibuf[i] * inputMul, fromMin, fromMax, toMin, toMax
			sample = lmath.clamp sample, toMin, toMax if clip
			obuf[i] = sample * outputMul