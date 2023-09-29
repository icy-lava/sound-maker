export lmath, vec2
Slider = require 'widget.slider'
XY = require 'widget.xy'
class XYPad extends require 'module'
	name: 'xy pad'
	outputLabels: {'x', 'y'}
	new: (...) =>
		super ...
		@size.y = 64 * 7
		@setOutputCount 2
		
		do
			@pad = XY @, vec2(32, 36), vec2 @size.x - 64, @size.x - 64
		
		do
			@smooth = Slider @, vec2(32, 24 + 52 * 6), vec2 @size.x - 64, 40
			@smooth.defaultValue = 0.5
			@smooth.value = @smooth.defaultValue
			@smooth.minValue = 1e-12
			@smooth.maxValue = 1
			@smooth.getLabel = => 'Smoothing'
	
	getSmoothing: => @smooth.value ^ 5 * 0.05
	
	_process: =>
		xbuf = @getOutput 1
		ybuf = @getOutput 2
		x, y = @pad.actual\split!
		tx, ty = @pad.target\split!
		smooth = @getSmoothing!
		dt = 1 / @workspace.sampleRate
		for i = 0, @getBufferSize! - 1
			xbuf[i] = x
			ybuf[i] = -y
			x = lmath.damp smooth, dt, x, tx
			y = lmath.damp smooth, dt, y, ty
		@pad.actual = vec2 x, y