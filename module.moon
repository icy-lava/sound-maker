ffi = require 'ffi'
floatSize = ffi.sizeof 'float'
lg = love.graphics

class Module
	name: 'undefined'
	font: lg.newFont 18
	labelHeight: 40
	
	new: (@x = 0, @y = 0) =>
		@inputs = {1, 2, 5, 5}
		@outputs = {3, 3, 3}
		@inputConnections = {}
		@outputConnections = {}
		@width = 280
		@height = 240
	_process: => error 'process is not implemented'
	
	process: =>
		if @generation ~= @workspace.generation
			@_process!
			@generation = @workspace.generation
	
	draw: =>
		lg.push 'all'
		lg.stencil -> lg.rectangle 'fill', @x, @y, @width, @height, @labelHeight / 2, nil, 32
		lg.setStencilTest "greater", 0
		
		lg.translate @x, @y
		
		-- Body
		lg.setColor 0.15, 0.15, 0.17, 1
		lg.rectangle 'fill', 0, 0, @width, @height
		-- Header
		lg.setColor 0.17, 0.17, 0.19, 1
		lg.rectangle 'fill', 0, 0, @width, @labelHeight
		
		-- Title
		lg.setFont @font
		fx = lmath.round (@width - @font\getWidth @name) / 2
		fy = lmath.round (@labelHeight - @font\getHeight!) / 2
		lg.setColor 0.1, 0.1, 0.15, 1
		lg.print @name, fx, fy
		
		@_draw! if @_draw
		
		lg.setStencilTest!
		
		lg.setColor 0.4, 0.35, 0.7
		for i = 1, @getInputCount!
			pos = @getInputPosition i
			lg.circle 'fill', pos.x, pos.y, 10, 64
		
		for i = 1, @getOutputCount!
			pos = @getOutputPosition i
			lg.circle 'fill', pos.x, pos.y, 10, 64
		
		lg.pop!
	
	start: => @generation * @bufferSize
	
	connect: (other, otherOutput, input) =>
		table.insert @inputConnections, {other, otherOutput, input}
	
	receiveInputs: (generation) =>
		assert generation
		
		for i = 1, @getInputCount!
			-- zero-fill buffer
			ffi.fill @getInput(i).buffer, @bufferSize * floatSize
		
		for _, connection in ipairs(@inputConnections)
			connection[1]\process generation
			ibuf = @getInput(connection[3]).buffer
			obuf = connection[1]\getOutput(connection[2]).buffer
			for i = 0, @bufferSize - 1
				ibuf[i] = ibuf[i] + obuf[i]
	
	getInputPosition: (index) => vec2 2, @labelHeight + 24 + 40 * (index - 1)
	getOutputPosition: (index) => vec2 @width - 2, @labelHeight + 24 + 40 * (index - 1)
	
	getInput: (index) => assert @inputs[index]
	getInputCount: (index) => #@inputs
	getOutput: (index) => assert @outputs[index]
	getOutputCount: (index) => #@outputs