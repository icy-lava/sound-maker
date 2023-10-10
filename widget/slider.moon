export love, lmath, util
lg = love.graphics
class Slider extends require 'widget'
	new: (...) =>
		super ...
		@defaultValue = 0.5
		@value = @defaultValue
		@minValue = 0
		@maxValue = 1
	getLabel: => string.format '%0.2f', @value
	_mousepressed: (x, y, button) =>
		if button == 2
			@value = @defaultValue
	_update: (dt) =>
		if @isActive!
			mx = @getMousePos!.x
			@value = lmath.map mx, 0, @size.x, @minValue, @maxValue
			@value = lmath.roundStep @value, @step if @step
			@value = lmath.clamp @value, @minValue, @maxValue
	_draw: =>
		lg.setFont @font
		label = @getLabel!
		fx = lmath.round (@size.x - @font\getWidth label) / 2
		fy = lmath.round (@size.y - @font\getHeight!) / 2
		value = lmath.map @value, @minValue, @maxValue, 0, 1
		
		-- Draw background
		sfunc = -> lg.rectangle 'fill', 0, 0, @size.x, @size.y, 12, nil, 16
		lg.stencil sfunc, 'increment', 1, true
		
		lg.setStencilTest 'greater', 1
		
		lg.setColor 0.12, 0.12, 0.2, 1
		util.highlight! if @shouldHighlight!
		lg.rectangle 'fill', 0, 0, @size.x, @size.y
		
		sfunc = -> lg.rectangle 'fill', 0, 0, @size.x * value, @size.y if @size.x * value >= 1
		lg.stencil sfunc, 'increment', 1, true
		lg.setStencilTest 'greater', 2
		
		lg.setColor 0.4, 0.35, 0.7, 1
		util.highlight! if @shouldHighlight!
		lg.rectangle 'fill', 0, 0, @size.x, @size.y
		
		-- Draw background label
		lg.setStencilTest 'less', 3
		lg.setColor 0.4, 0.4, 0.45, 1
		util.highlight! if @shouldHighlight!
		lg.print label, fx, fy
		lg.setStencilTest 'greater', 2
		lg.setColor 0.12, 0.12, 0.2, 1
		util.highlight! if @shouldHighlight!
		lg.print label, fx, fy
		
		-- Draw outline
		lg.setStencilTest 'greater', 0
		lg.setColor 0.20, 0.20, 0.28, 1
		-- util.highlight! if @shouldHighlight!
		lg.setLineWidth 3
		lg.rectangle 'line', 0, 0, @size.x, @size.y, 12, nil, 16