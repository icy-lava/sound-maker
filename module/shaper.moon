export lmath, vec2
Curves = require 'widget.curves'
class Shaper extends require 'module'
	name: 'shaper'
	new: (...) =>
		super ...
		@size.x = 64 * 6
		@size.y = 64 * 7
		@setInputCount 1
		@setOutputCount 1
		
		do
			@curves = Curves @, vec2(32, 24), vec2 @size.x - 64, @size.x - 64
	
	getSmoothing: => @smooth.value ^ 5 * 0.05
	
	_process: =>
		ibuf = @getInput 1
		obuf = @getOutput 1
		xs = {}
		ys = {}
		points = @curves.points
		plen = #points
		for i = 1, plen
			xs[i] = points[i].x
			ys[i] = points[i].y
		for i = 0, @getBufferSize! - 1
			sample = ibuf[i]
			if sample <= xs[1]
				sample = ys[1]
			elseif sample >= xs[plen]
				sample = ys[plen]
			else
				index0 = 0
				for j = 1, plen
					break if sample < xs[j]
					index0 = j
				index1 = index0 + 1
				y0 = ys[index0]
				y1 = ys[index1]
				x0 = xs[index0]
				x1 = xs[index1]
				sample = lmath.lerp (sample - x0) / (x1 - x0), y0, y1
			obuf[i] = sample