export love, lmath, util
lg = love.graphics
class Toggle extends require 'widget.button'
	new: (...) =>
		super ...
		@status = false
	action: =>
		@status = not @status
		@toggle @status if @toggle
	_draw: =>
		unless @status
			super._draw @
			return
		-- Draw background
		lg.setColor 0.1, 0.1, 0.3, 1
		util.highlight! if @shouldHighlight!
		lg.rectangle 'fill', 0, 0, @size.x, @size.y, 12, nil, 16
		lg.setColor 0.4, 0.4, 0.7, 1
		-- util.highlight! if @shouldHighlight!
		lg.setLineWidth 3
		lg.rectangle 'line', 0, 0, @size.x, @size.y, 12, nil, 16
		
		-- Draw label
		lg.setFont @font
		fx = lmath.round (@size.x - @font\getWidth @label) / 2
		fy = lmath.round (@size.y - @font\getHeight!) / 2
		lg.setColor 0.4, 0.4, 0.7, 1
		util.highlight! if @shouldHighlight!
		lg.print @label, fx, fy
		