lg = love.graphics

class Workspace
	new: (@sampleRate, @channelCount, @bitDepth = 16, @bufferCount = 4, @bufferSize = 1024) =>
		@generation = 0
		@source = love.audio.newQueueableSource sampleRate, bitDepth, channelCount, bufferCount
		@source\setVolume 0.1
		@modules = {}
	
	update: (dt) =>
		
	
	draw: =>
		lg.clear 0.1, 0.1, 0.12, 1
		lg.push 'all'
		
		-- Draw module bodies
		for module in *@modules
			module\draw!
		
		-- Draw module connections
		lg.setColor 0.4, 0.35, 0.7
		lg.setLineStyle 'rough'
		lg.setLineWidth 4
		for module in *@modules
			for connection in *module.inputConnections
				other = connection[1]
				opos = vec2 other.x, other.y
				mpos = vec2 module.x, module.y
				p1 = opos + other\getOutputPosition connection[2]
				p2 = mpos + module\getInputPosition connection[3]
				middleX = (p1.x + p2.x) / 2
				c1 = vec2 middleX, p1.y
				c2 = vec2 middleX, p2.y
				curve = love.math.newBezierCurve p1.x, p1.y, c1.x, c1.y, c2.x, c2.y, p2.x, p2.y
				line = curve\render 3
				love.graphics.line line
		
		lg.pop!
	
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