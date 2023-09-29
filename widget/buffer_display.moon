export love, lmath, ltable
buffer = require 'buffer'
lg = love.graphics
class BufferDisplay extends require 'widget'
	new: (...) =>
		super ...
		@buffers = {}
	appendBuffer: (buf) =>
		len = @module\getBufferSize!
		newBuf = buffer.new len
		buffer.copy newBuf, buf, len
		table.insert @buffers, newBuf
	getSampleCount: => @module\getBufferSize! * #@buffers
	_getSample: (index) =>
		bsize = @module\getBufferSize!
		bufIndex = math.floor index / bsize
		buf = @buffers[bufIndex + 1]
		subindex = index - bufIndex * bsize
		return buf[subindex]
	getLength: => @getSampleCount! / @module.workspace.sampleRate
	getSample: (t) =>
		len = @getSampleCount!
		index = t * @module.workspace.sampleRate
		index0 = math.floor index
		index1 = math.ceil index
		return 0 if index0 < 0 or index1 >= len
		fract = index % 1
		return lmath.lerp fract, @_getSample(index0), @_getSample(index1)
	clear: => @buffers = {}
	_draw: =>
		-- Draw background
		sfunc = ->
			lg.setColorMask true, true, true, true
			lg.setColor 0.12, 0.12, 0.2, 1
			lg.rectangle 'fill', 0, 0, @size.x, @size.y, 12, nil, 16
		lg.stencil sfunc, 'increment', 1, true
		lg.setStencilTest 'greater', 1
		
		lg.setColor 0.20, 0.20, 0.28, 1
		lg.setLineWidth 2
		-- Draw waveform
		line = {}
		-- bsize = @module\getBufferSize!
		-- bcount = #@buffers
		-- sampleCount = bsize * bcount
		-- for i = 1, bcount
		-- 	buf = @buffers[i]
		-- 	for j = 0, bsize - 1
		-- 		x = lmath.map (i - 1) * bsize + j, 0, sampleCount - 1, 0, @size.x
		-- 		y = lmath.map buf[j], -1, 1, @size.y, 0
		-- 		ltable.push line, x, y
		sampleCount = 256
		length = @getLength!
		for i = 0, sampleCount - 1
			t = i / (sampleCount - 1)
			sample = @getSample t * length
			x = t * @size.x
			y = lmath.map sample, -1, 1, @size.y, 0
			ltable.push line, x, y
		lg.line line if line[1]
		if @phase
			lg.setColor 0.4, 0.35, 0.7, 1
			x = @phase / length * @size.x
			lg.line x, 0, x, @size.y
			lg.setColor 0.20, 0.20, 0.28, 1
		
		lg.setStencilTest 'greater', 0
		
		-- Draw outline
		lg.setLineWidth 3
		lg.rectangle 'line', 0, 0, @size.x, @size.y, 12, nil, 16