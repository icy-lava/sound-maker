export love, vec2, ltable, lmath

cam11 = require 'cam11'
lg = love.graphics

class Workspace
	gridSize: vec2 64, 64
	new: (@sampleRate, @channelCount, @bitDepth = 16, @bufferCount = 4, @bufferSize = 1024) =>
		@generation = 0
		-- @source = love.audio.newQueueableSource sampleRate, bitDepth, channelCount, bufferCount
		-- @source\setVolume 0.1
		@modules = {}
		@mode = { kind: 'none' }
		@cam = cam11!
		@zoom = 0
		@cam\setZoom @getZoomAmount!
	
	update: (dt) =>
		wpos = @getMousePos!
		@hoveredSocket = @getHoveredSocket wpos
		if @mode.kind == 'position'
			delta = @mode.fromPoint\delta wpos
			pos = @mode.fromPos + delta
			pos.x = lmath.roundStep pos.x, @gridSize.x
			pos.y = lmath.roundStep pos.y, @gridSize.y
			@mode.module.pos = pos
		if @mode.kind == 'select'
			@clearSelected!
			for module in *@modules
				if @isModuleInSelection module
					module.selected = true
		if @dragInfo
			delta = wpos\delta @dragInfo.fromPoint
			@cam\setPos (delta + vec2 @cam\getPos!)\split!
	
	draw: =>
		wpos = @getMousePos!
		lg.clear 0.1, 0.1, 0.12, 1
		lg.setLineStyle 'rough'
		
		@cam\attach!
		lg.push 'all'
		
		-- Draw grid
		do
			p1 = vec2 @cam\toWorld 0, 0
			p2 = vec2 @cam\toWorld lg.getWidth!, 0
			p3 = vec2 @cam\toWorld lg.getWidth!, lg.getHeight!
			p4 = vec2 @cam\toWorld 0, lg.getHeight!
			tl = p1\min p2, p3, p4
			br = p1\max p2, p3, p4
			tl = vec2 math.floor(tl.x / @gridSize.x), math.floor(tl.y / @gridSize.y)
			br = vec2 math.ceil(br.x / @gridSize.x), math.ceil(br.y / @gridSize.y)
			lg.setColor 1, 1, 1, 0.05
			for y = tl.y, br.y
				for x = tl.x, br.x
					pos = @gridSize * vec2 x, y
					lg.circle 'fill', pos.x, pos.y, 4, 16
		
		-- Draw module bodies
		for module in *@modules
			lg.push 'all'
			lg.translate module.pos.x, module.pos.y
			module\draw!
			lg.pop!
		
		-- Draw module connections
		lg.setColor 0.4, 0.35, 0.7
		lg.setLineWidth 4
		for module in *@modules
			for connection in *module.inputConnections
				p1 = @getModuleOutputPosition connection[1], connection[2]
				p2 = @getModuleInputPosition module, connection[3]
				@drawConnection p1, p2
		
		if @mode.kind == 'connect'
			socket = @mode.from
			output = @getModuleOutputPosition socket[1], socket[2]
			input = wpos
			if @hoveredSocket and @hoveredSocket[3]
				input = @getModuleInputPosition @hoveredSocket[1], @hoveredSocket[2]
			@drawConnection output, input
		
		-- Draw module sockets
		for module in *@modules
			lg.push 'all'
			lg.translate module.pos.x, module.pos.y
			module\drawSockets!
			lg.pop!
		
		-- Draw selection
		if @mode.kind == 'select'
			lg.push 'all'
			-- lg.origin!
			tl, br = @getSelection!
			radius = 16
			pad = vec2 radius, radius
			tl -= pad
			br += pad
			size = br - tl
			lg.setColor 0.2, 0.2, 0.7, 0.4
			lg.rectangle 'fill', tl.x, tl.y, size.x, size.y, radius, radius, 32
			lg.setBlendMode 'add'
			lg.setColor 0.5, 0.5, 0.6, 0.1
			lg.rectangle 'fill', tl.x, tl.y, size.x, size.y, radius, radius, 32
			lg.setBlendMode 'alpha'
			lg.setColor 0.4, 0.4, 0.7, 1
			lg.setLineWidth 3 / @getZoomAmount!
			lg.rectangle 'line', tl.x, tl.y, size.x, size.y, radius, radius, 32
			lg.pop!
		
		lg.pop!
		@cam\detach!
	
	drawConnection: (fromOutputPoint, toInputPoint) =>
		middleX = (fromOutputPoint.x + toInputPoint.x) / 2
		c1 = vec2 middleX, fromOutputPoint.y
		c2 = vec2 middleX, toInputPoint.y
		curve = love.math.newBezierCurve fromOutputPoint.x, fromOutputPoint.y, c1.x, c1.y, c2.x, c2.y, toInputPoint.x, toInputPoint.y
		line = curve\render 4
		love.graphics.line line
	
	getZoomAmount: => 2 ^ @zoom
	
	keypressed: (key) =>
		if key == 'delete'
			@deleteSelected!
			return
	keyreleased: =>
	mousepressed: (x, y, button) =>
		wpos = @getMousePos!
		if button == 1
			socket = @getHoveredSocket wpos
			if socket
				if socket[3] -- Try disconnect from input
					for i, connection in ltable.ripairs socket[1].inputConnections
						if connection[3] == socket[2]
							table.remove socket[1].inputConnections, i
							@mode = {
								kind: 'connect'
								from: {connection[1], connection[2], false}
							}
							break
					return
				@mode = {
					kind: 'connect'
					from: socket
				}
				return
			title = @getHoveredTitle wpos
			if title
				@mode = {
					kind: 'position'
					fromPoint: wpos.copy
					fromPos: title.pos.copy
					module: title
				}
				return
			@clearSelected!
			@mode = {
				kind: 'select'
				fromPoint: wpos.copy
			}
		if button == 3
			@dragInfo = {
				fromPoint: wpos.copy
			}
	
	mousereleased: (x, y, button) =>
		if button == 1
			if @mode.kind == 'connect'
				to = @getHoveredSocket @getMousePos!
				if to and to[3] -- Is input socket
					output, outputIndex = @mode.from[1], @mode.from[2]
					input, inputIndex = to[1], to[2]
					canConnect = true
					for connection in *input.inputConnections
						if connection[1] == output and connection[2] == outputIndex and connection[3] == inputIndex
							canConnect = false
							break
					input\connect output, outputIndex, inputIndex if canConnect
				
			@mode = { kind: 'none' }
			return
		if button == 3
			@dragInfo = nil
			return
	
	wheelmoved: (dx, dy) =>
		wpos = @getMousePos!
		@zoom += dy * 0.25
		@zoom = lmath.clamp @zoom, -3, 2
		@cam\setZoom @getZoomAmount!
		newWPos = vec2 @cam\toWorld love.mouse.getPosition!
		delta = wpos\delta newWPos
		@cam\setPos (-delta + vec2 @cam\getPos!)\split!
	
	resize: (width, height) =>
		@cam\setDirty!
	
	getModuleInputPosition: (module, index) => module.pos + module\getInputPosition index
	getModuleOutputPosition: (module, index) => module.pos + module\getOutputPosition index
	
	getMousePos: => vec2 @cam\toWorld love.mouse.getPosition!
	
	clearSelected: =>
		for module in *@modules
			module.selected = nil
	
	deleteSelected: =>
		deleted = {}
		for i, module in ltable.ripairs @modules
			table.insert deleted, table.remove @modules, i if module.selected
		for module in *deleted
			for other in *@modules
				for i, connection in ltable.ripairs other.inputConnections
					table.remove other.inputConnections, i if connection[1] == module
	
	getSelection: =>
		return nil unless @mode.kind == 'select'
		start = @mode.fromPoint
		wpos = @getMousePos!
		tl = start\min wpos
		br = start\max wpos
		pad = vec2 4, 4
		return tl - pad, br + pad
	
	isModuleInSelection: (module) =>
		tl, br = @getSelection!
		return false unless tl
		mtl = module.pos
		mbr = mtl + module.size
		return tl.x <= mtl.x and tl.y <= mtl.y and br.x >= mbr.x and br.y >= mbr.y
	
	getHoveredTitle: (point) =>
		for _, module in ltable.ripairs @modules
			tl = module.pos
			br = tl + vec2 module.size.x, module.labelHeight
			if point.x >= tl.x and point.y >= tl.y and point.x < br.x and point.y < br.y
				return nil if @hoveredSocket
				return module
		return nil
	
	getHoveredSocket: (point) =>
		minDist = math.huge
		local minSocket
		for module in *@modules
			for i = 1, module\getInputCount!
				pos = @getModuleInputPosition module, i
				dist = pos\dist point
				minDist, minSocket = dist, {module, i, true} if dist < minDist
			for i = 1, module\getOutputCount!
				pos = @getModuleOutputPosition module, i
				dist = pos\dist point
				minDist, minSocket = dist, {module, i, false} if dist < minDist
		return minSocket if minDist <= 24
		return nil
	
	addModule: (mod) =>
		mod.workspace = @
		table.insert @modules, mod
	removeModule: (mod) =>
		assert mod.workspace == @, "trying to remove a module that doesn't belong to the workspace"
		for i = 1, #@modules
			if @modules[i] == mod
				mod.workspace = nil
				table.remove @modules, i
				return
		error "could not find module in workspace"