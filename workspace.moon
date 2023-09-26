lg = love.graphics

class Workspace
	new: (@sampleRate, @channelCount, @bitDepth = 16, @bufferCount = 4, @bufferSize = 1024) =>
		@generation = 0
		@source = love.audio.newQueueableSource sampleRate, bitDepth, channelCount, bufferCount
		@source\setVolume 0.1
		@modules = {}
	
	update: (dt) =>
		@hoveredSocket = @getHoveredSocket vec2 love.mouse.getPosition!
	
	draw: =>
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
				other = connection[1]
				opos = other.pos
				mpos = module.pos
				p1 = opos + other\getOutputPosition connection[2]
				p2 = mpos + module\getInputPosition connection[3]
				middleX = (p1.x + p2.x) / 2
				c1 = vec2 middleX, p1.y
				c2 = vec2 middleX, p2.y
				curve = love.math.newBezierCurve p1.x, p1.y, c1.x, c1.y, c2.x, c2.y, p2.x, p2.y
				line = curve\render 3
				love.graphics.line line
		
		-- Draw module sockets
		for module in *@modules
			lg.push 'all'
			lg.translate module.pos.x, module.pos.y
			module\drawSockets!
			lg.pop!
		
		lg.pop!
	
	keypressed: =>
	keyreleased: =>
	mousepressed: (x, y, button) =>
		mpos = vec2 x, y
		if button == 1
			print @getHoveredTitle mpos
	
	mousereleased: =>
	
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
				table.remove modules, i
				return
		error "could not find module in workspace"