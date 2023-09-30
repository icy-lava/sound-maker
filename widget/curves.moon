export love, lmath, vec2, ltable
lg = love.graphics
class Curves extends require 'widget'
	new: (...) =>
		super ...
		@points = {vec2(-1, -1), vec2(1, 1)}
	_mousepressed: (x, y, button) =>
		mpos = vec2 x, y
		if button == 1
			@activePoint = @getPointAtPos mpos
			if @activePoint
				@activePointOffset = @activePoint - @pos2unit mpos
			else
				@activePointOffset = vec2!
				@activePoint = @pos2unit mpos
				i = 1
				for j = 1, #@points
					break if @activePoint.x < @points[j].x
					i = j + 1
				table.insert @points, i, @activePoint
			return
		if button == 2
			if #@points > 2
				i = ltable.ifind @points, @getPointAtPos mpos
				table.remove @points, i if i
			return
	_mousereleased: (x, y, button) =>
		if button == 1
			@activePoint = nil
			return
	pos2unit: (pos) =>
		x = lmath.map pos.x, 0, @size.x, -1, 1
		y = lmath.map pos.y, @size.y, 0, -1, 1
		vec2 x, y
	unit2pos: (unit) =>
		x = lmath.map unit.x, -1, 1, 0, @size.x
		y = lmath.map unit.y, -1, 1, @size.y, 0
		vec2 x, y
	_update: (dt) =>
		if @activePoint
			mpos = @getMousePos!
			@activePoint\set @activePointOffset + @pos2unit mpos
			if love.keyboard.isDown 'lctrl', 'rctrl'
				@activePoint.x = lmath.roundStep @activePoint.x, 0.25
				@activePoint.y = lmath.roundStep @activePoint.y, 0.25
			i = ltable.ifind @points, @activePoint
			assert i, 'point not found'
			minPoint = @points[i - 1]
			minX = minPoint and minPoint.x or -1
			maxPoint = @points[i + 1]
			maxX = maxPoint and maxPoint.x or 1
			@activePoint.x = lmath.clamp @activePoint.x, minX, maxX
			@activePoint.y = lmath.clamp @activePoint.y, -1, 1
	getPointAtPos: (pos) =>
		minDist = math.huge
		local minPoint
		for i, point in ipairs @points
			dist = pos\dist @unit2pos point
			minDist, minPoint = dist, point if dist < minDist
		return minPoint if minDist <= 24
	_draw: =>
		-- Draw background
		sfunc = ->
			lg.setColorMask true, true, true, true
			lg.setColor 0.12, 0.12, 0.2, 1
			lg.rectangle 'fill', 0, 0, @size.x, @size.y, 12, nil, 16
		lg.stencil sfunc, 'increment', 1, true
		lg.setStencilTest 'greater', 1
		
		-- Grid
		lg.setColor 0.20, 0.20, 0.28, 1
		for i = 1, 7
			lg.setLineWidth i == 4 and 3 or 1
			y = lmath.map i, 0, 8, 0, @size.y
			lg.line 0, y, @size.x, y
		for i = 1, 7
			lg.setLineWidth i == 4 and 3 or 1
			x = lmath.map i, 0, 8, 0, @size.x
			lg.line x, 0, x, @size.y
		
		-- Draw line
		do
			line = {(@unit2pos(@points[1]) - vec2(@size.x, 0))\split!}
			for i = 1, #@points
				ltable.push line, @unit2pos(@points[i])\split!
			ltable.push line, (@unit2pos(@points[#@points]) + vec2(@size.x, 0))\split!
			lg.setLineWidth 2
			lg.setColor 0.4, 0.35, 0.7, 1
			lg.line line
		
		-- Draw points
		hoveredPoint = @getPointAtPos @getMousePos!
		for i = 1, #@points
			point = @points[i]
			pos = @unit2pos point
			radius = 8
			if point == hoveredPoint
				radius = 9
				lg.setColor 0.7, 0.6, 0.8, 0.1
				lg.circle 'fill', pos.x, pos.y, 20, 32
				lg.setColor 0.7, 0.6, 0.8, 1
			else
				lg.setColor 0.4, 0.35, 0.7, 1
			lg.circle 'fill', pos.x, pos.y, radius, 16
		
		lg.setStencilTest 'greater', 0
		
		-- Draw outline
		lg.setLineWidth 3
		lg.setColor 0.20, 0.20, 0.28, 1
		lg.rectangle 'line', 0, 0, @size.x, @size.y, 12, nil, 16
		
		-- Draw points again
		for i = 1, #@points
			point = @points[i]
			continue if point == hoveredPoint
			x = lmath.map point.x, -1, 1, 0, @size.x
			y = lmath.map point.y, -1, 1, @size.y, 0
			lg.setColor 0.4, 0.35, 0.7, 0.25
			lg.circle 'fill', x, y, 8, 16