export love, lmath, vec2
lg = love.graphics
class XY extends require 'widget'
	new: (...) =>
		super ...
		@target = vec2!
		@actual = vec2!
		@smoothing = 0.5
	_mousereleased: (x, y, button) =>
		if button == 2
			@target = vec2!
			@actual = vec2!
	_update: (dt) =>
		if @isActive!
			@target = @getMousePos! / @size * 2 - vec2 1, 1
			if love.keyboard.isDown 'lctrl', 'rctrl'
				@target.x = lmath.roundStep @target.x, 0.5
				@target.y = lmath.roundStep @target.y, 0.5
			@target.x = lmath.clamp @target.x, -1, 1
			@target.y = lmath.clamp @target.y, -1, 1
	_draw: =>
		-- Draw background
		lg.setColor 0.12, 0.12, 0.2, 1
		lg.rectangle 'fill', 0, 0, @size.x, @size.y, 12, nil, 16
		
		-- Grid
		lg.setColor 0.20, 0.20, 0.28, 1
		for i = 1, 3
			lg.setLineWidth i == 2 and 3 or 1
			lg.line 0, i / 4 * @size.y, @size.x, i / 4 * @size.y
		for i = 1, 3
			lg.setLineWidth i == 2 and 3 or 1
			lg.line i / 4 * @size.x, 0, i / 4 * @size.x, @size.y
		
		lg.setLineWidth 3
		lg.rectangle 'line', 0, 0, @size.x, @size.y, 12, nil, 16
		
		-- Draw points
		x, y = ((@actual + vec2(1, 1)) / 2 * @size)\split!
		lg.setColor 0.20, 0.20, 0.28, 1
		lg.circle 'fill', x, y, 8, 16
		tx, ty = ((@target + vec2(1, 1)) / 2 * @size)\split!
		lg.setColor 0.4, 0.35, 0.7, 1
		lg.circle 'fill', tx, ty, 8, 16