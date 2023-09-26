lg = love.graphics

class Workspace
	new: (@sampleRate, @channelCount, @bitDepth = 16, @bufferCount = 4, @bufferSize = 1024) =>
		@generation = 0
		-- @source = love.audio.newQueueableSource sampleRate, bitDepth, channelCount, bufferCount
		-- @source\setVolume 0.1
		@modules = {}
		@mode = { kind: 'none' }
	
	update: (dt) =>
		mpos = vec2 love.mouse.getPosition!
		@hoveredSocket = @getHoveredSocket mpos
		if @mode.kind == 'position'
			delta = @mode.fromPoint\delta mpos
			@mode.module.pos = @mode.fromPos + delta
	
	draw: =>
		mpos = vec2 love.mouse.getPosition!
		lg.clear 0.1, 0.1, 0.12, 1
		
		lg.push 'all'
		-- Draw module bodies
		for module in *@modules
			lg.push 'all'
			lg.translate module.pos.x, module.pos.y
			module\draw!
			lg.pop!
		
		-- Draw module connections
		lg.setColor 0.4, 0.35, 0.7
		lg.setLineStyle 'rough'
		lg.setLineWidth 4
		for module in *@modules
			for connection in *module.inputConnections
				p1 = @getModuleOutputPosition connection[1], connection[2]
				p2 = @getModuleInputPosition module, connection[3]
				@drawConnection p1, p2
		
		if @mode.kind == 'connect'
			socket = @mode.from
			output = @getModuleOutputPosition socket[1], socket[2]
			input = mpos
			if @hoveredSocket and @hoveredSocket[3]
				input = @getModuleInputPosition @hoveredSocket[1], @hoveredSocket[2]
			@drawConnection output, input
		
		-- Draw module sockets
		for module in *@modules
			lg.push 'all'
			lg.translate module.pos.x, module.pos.y
			module\drawSockets!
			lg.pop!
		
		lg.pop!
	
	drawConnection: (fromOutputPoint, toInputPoint) =>
		middleX = (fromOutputPoint.x + toInputPoint.x) / 2
		c1 = vec2 middleX, fromOutputPoint.y
		c2 = vec2 middleX, toInputPoint.y
		curve = love.math.newBezierCurve fromOutputPoint.x, fromOutputPoint.y, c1.x, c1.y, c2.x, c2.y, toInputPoint.x, toInputPoint.y
		line = curve\render 4
		love.graphics.line line
	
	keypressed: =>
	keyreleased: =>
	mousepressed: (x, y, button) =>
		mpos = vec2 x, y
		if button == 1
			socket = @getHoveredSocket mpos
			if socket
				return if socket[3] -- Can't drag from input
				@mode = {
					kind: 'connect'
					from: socket
				}
				return
			title = @getHoveredTitle mpos
			if title
				@mode = {
					kind: 'position'
					fromPoint: mpos.copy
					fromPos: title.pos.copy
					module: title
				}
	
	mousereleased: (x, y, button) =>
		@mode = { kind: 'none' }
	
	getModuleInputPosition: (module, index) => module.pos + module\getInputPosition index
	getModuleOutputPosition: (module, index) => module.pos + module\getOutputPosition index
	
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