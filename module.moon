export love, vec2, lmath, ltable
buffer = require 'buffer'
lg = love.graphics

class Module
	name: 'undefined'
	font: lg.newFont 'font/Quicksand-SemiBold.ttf', 22
	labelHeight: 40
	inputLabels: {}
	outputLabels: {}
	
	new: (@workspace, @pos = vec2!) =>
		@widgets = {}
		@inputs = {}
		@outputs = {}
		@inputConnections = {}
		@size = vec2 64 * 5, 64 * 4
	
	_process: => error 'process is not implemented'
	
	process: =>
		if @generation ~= @workspace.generation
			@generation = @workspace.generation
			@receiveInputs!
			@_process! if @_process
	
	update: (dt) =>
		for widget in *@widgets
			widget\update dt
		@_update dt if @_update
	
	draw: =>
		lg.push 'all'
		
		-- Draw selectedness
		if @selected
			lg.push 'all'
			pad = 24
			radius = @labelHeight / 2 + pad
			pad = vec2 pad, pad
			size = @size + pad * 2
			lg.setColor 0.6, 0.5, 0.9, 0.2
			lg.rectangle 'fill', -pad.x, -pad.y, size.x, size.y, radius, nil, 32
			lg.setLineWidth 4
			lg.setColor 0.4, 0.4, 0.7, 1
			lg.rectangle 'line', -pad.x, -pad.y, size.x, size.y, radius, nil, 32
			lg.pop!
		
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
		lg.setColor 0.4, 0.4, 0.45, 1
		lg.print @name, fx, fy
		
		@_draw! if @_draw
		
		-- Draw widgets
		for _, widget in ltable.ripairs @widgets
			lg.push 'all'
			lg.translate widget.pos.x, widget.pos.y + @labelHeight
			widget\draw!
			lg.pop!
		
		lg.setStencilTest!
		lg.pop!
	
	getWidgetAtPoint: (point) =>
		for _, widget in ltable.ripairs @widgets
			tl = widget.pos
			br = tl + widget.size
			return widget if point.x >= tl.x and point.y >= tl.y and point.x < br.x and point.y < br.y
		return nil
	
	getMousePos: => @workspace\getMousePos! - @pos - vec2 0, @labelHeight
	
	snapToGrid: =>
		grid = @workspace.gridSize
		@pos.x = lmath.roundStep @pos.x, grid.x
		@pos.y = lmath.roundStep @pos.y, grid.y
	
	snapIfNeeded: =>
		@snapToGrid! if @workspace.snapping
	
	mousepressed: (x, y, button) =>
		widget = @getWidgetAtPoint vec2 x, y
		if widget
			wpos = widget.pos
			widget\mousepressed x - wpos.x, y - wpos.y, button
			if button == 1
				@activeWidget = widget
			elseif button == 2
				@ractiveWidget = widget
			return
		@_mousepressed x, y, button if @_mousepressed
	mousereleased: (x, y, button) =>
		if button == 1 and @activeWidget
			wpos = @activeWidget.pos
			@activeWidget\mousereleased x - wpos.x, y - wpos.y, button
			@activeWidget = nil
			return
		if button == 2 and @ractiveWidget
			wpos = @ractiveWidget.pos
			@ractiveWidget\mousereleased x - wpos.x, y - wpos.y, button
			@ractiveWidget = nil
			return
		@_mousereleased x, y, button if @_mousereleased
	
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
	
	getHoveredWidget: (point) =>
		for _, widget in ltable.ripairs @widgets
			tl = widget.pos
			br = tl + widget.size
			return widget if point.x >= tl.x and point.y >= tl.y and point.x < br.x and point.y < br.y
		return nil
	
	hasInput: (index) =>
		for connection in *@inputConnections
			return true if connection[3] == index
		return false
	
	setInputCount: (count) =>
		while @getInputCount! < count
			table.insert @inputs, buffer.new @getBufferSize!
		while @getInputCount! > count
			table.remove @inputs
	
	setOutputCount: (count) =>
		while @getOutputCount! < count
			table.insert @outputs, buffer.new @getBufferSize!
		while @getOutputCount! > count
			table.remove @outputs
	
	connect: (other, otherOutput, input) =>
		table.insert @inputConnections, {other, otherOutput, input}
	
	receiveInputs: =>
		for i = 1, @getInputCount!
			buffer.zero @getInput(i), @getBufferSize!
		
		for _, connection in ipairs @inputConnections
			connection[1]\process!
			ibuf = @getInput connection[3]
			obuf = connection[1]\getOutput connection[2]
			for i = 0, @getBufferSize! - 1
				ibuf[i] = ibuf[i] + obuf[i]
	
	getInputPosition: (index) => vec2 2, @labelHeight + 24 + 40 * (index - 1)
	getOutputPosition: (index) => vec2 @size.x - 2, @labelHeight + 24 + 40 * (index - 1)
	
	getInput: (index) => assert @inputs[index]
	getInputCount: => #@inputs
	getOutput: (index) => assert @outputs[index]
	getOutputCount: => #@outputs