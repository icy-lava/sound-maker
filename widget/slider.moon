export love, lmath
lg = love.graphics
class Slider extends require 'widget'
	new: (...) =>
		super ...
		@defaultValue = 0.5
		@value = @defaultValue
		@minValue = 0
		@maxValue = 1
	getLabel: => string.format '%0.2f', @value
	_mousereleased: (x, y, button) =>
		if button == 2
			@value = @defaultValue
	_update: (dt) =>
		if @isActive!
			mx = @getMousePos!.x
			@value = lmath.map mx, 0, @size.x, @minValue, @maxValue
			@value = lmath.roundStep @value, @step if @step
			@value = lmath.clamp @value, @minValue, @maxValue
	_draw: =>
		-- Draw background
		lg.setColor 0.12, 0.12, 0.13, 1
		lg.rectangle 'fill', 0, 0, @size.x, @size.y, 12, nil, 16
		value = lmath.map @value, @minValue, @maxValue, 0, 1
		if @size.x * value >= 1
			lg.setColor 0.1, 0.1, 0.3, 1
			lg.rectangle 'fill', 0, 0, @size.x * value, @size.y, 12, nil, 16
		lg.setColor 0.17, 0.17, 0.19, 1
		lg.setLineWidth 3
		lg.rectangle 'line', 0, 0, @size.x, @size.y, 12, nil, 16
		
		-- Draw label
		lg.setFont @font
		label = @getLabel!
		fx = lmath.round (@size.x - @font\getWidth label) / 2
		fy = lmath.round (@size.y - @font\getHeight!) / 2
		lg.setColor 0.4, 0.4, 0.45, 1
		lg.print label, fx, fy