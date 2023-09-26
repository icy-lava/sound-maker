ffi = require 'ffi'
floatSize = ffi.sizeof 'float'
lg = love.graphics

class Module
	name: 'undefined'
	font: lg.newFont 18
	labelHeight: 40
	
	new: (@pos = vec2!) =>
		@inputs = {1, 2, 5, 5}
		@outputs = {3, 3, 3}
		@inputConnections = {}
		@size = vec2 280, 240
	
	_process: => error 'process is not implemented'
	
	process: =>
		if @generation ~= @workspace.generation
			@_process! if @_process
			@generation = @workspace.generation
	
	draw: =>
		lg.push 'all'
		lg.stencil -> lg.rectangle 'fill', 0, 0, @size.x, @size.y, @labelHeight / 2, nil, 32
		lg.setStencilTest "greater", 0
		
		-- Body
		lg.setColor 0.15, 0.15, 0.17, 1
		lg.rectangle 'fill', 0, 0, @size.x, @size.y
		-- Header
		lg.setColor 0.17, 0.17, 0.19, 1
		lg.rectangle 'fill', 0, 0, @size.x, @labelHeight
		
		-- Title
		lg.setFont @font
		fx = lmath.round (@size.x - @font\getWidth @name) / 2
		fy = lmath.round (@labelHeight - @font\getHeight!) / 2
		lg.setColor 0.1, 0.1, 0.15, 1
		lg.print @name, fx, fy
		
		@_draw! if @_draw
		
		lg.setStencilTest!
		lg.pop!
	
	drawSockets: =>
		for i = 1, @getInputCount!  do @drawSocket i, true
		for i = 1, @getOutputCount! do @drawSocket i, false
	
	drawSocket: (index, isInput) =>
		pos = isInput and (@getInputPosition index) or (@getOutputPosition index)
		if @isSocketHovered index, isInput
			lg.setColor 0.7, 0.6, 0.8, 0.1
			lg.circle 'fill', pos.x, pos.y, 20, 64
			lg.setColor 0.7, 0.6, 0.8, 1
			lg.circle 'fill', pos.x, pos.y, 11, 64
		else
			lg.setColor 0.4, 0.35, 0.7, 1
			lg.circle 'fill', pos.x, pos.y, 10, 64
	
	isSocketHovered: (index, isInput) =>
		hovered = @workspace.hoveredSocket
		return false unless hovered
		return false if hovered[1] != @
		return false if hovered[2] != index
		return false if (not not hovered[3]) != (not not isInput)
		return true
		
	getBufferSize: => @workspace.bufferSize
	getStart: => @generation * @workspace.bufferSize
	
	connect: (other, otherOutput, input) =>
		table.insert @inputConnections, {other, otherOutput, input}
	
	receiveInputs: (generation) =>
		assert generation
		
		for i = 1, @getInputCount!
			-- zero-fill buffer
			ffi.fill @getInput(i).buffer, @getBufferSize! * floatSize
		
		for _, connection in ipairs(@inputConnections)
			connection[1]\process generation
			ibuf = @getInput(connection[3]).buffer
			obuf = connection[1]\getOutput(connection[2]).buffer
			for i = 0, @getBufferSize! - 1
				ibuf[i] = ibuf[i] + obuf[i]
	
	getInputPosition: (index) => vec2 2, @labelHeight + 24 + 40 * (index - 1)
	getOutputPosition: (index) => vec2 @size.x - 2, @labelHeight + 24 + 40 * (index - 1)
	
	getInput: (index) => assert @inputs[index]
	getInputCount: (index) => #@inputs
	getOutput: (index) => assert @outputs[index]
	getOutputCount: (index) => #@outputs