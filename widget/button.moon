export love, lmath
lg = love.graphics
class Button extends require 'widget'
	new: (...) =>
		super ...
		@label = '?'
	_mousereleased: (x, y, button) =>
		if button == 1
			@action! if @action and x >= 0 and y >= 0 and x < @size.x and y < @size.y
	_draw: =>
		-- Draw background
		lg.setColor 0.12, 0.12, 0.2, 1
		lg.rectangle 'fill', 0, 0, @size.x, @size.y, 12, nil, 16
		lg.setColor 0.20, 0.20, 0.28, 1
		lg.setLineWidth 3
		lg.rectangle 'line', 0, 0, @size.x, @size.y, 12, nil, 16
		
		-- Draw label
		lg.setFont @font
		fx = lmath.round (@size.x - @font\getWidth @label) / 2
		fy = lmath.round (@size.y - @font\getHeight!) / 2
		lg.setColor 0.4, 0.4, 0.45, 1
		lg.print @label, fx, fy