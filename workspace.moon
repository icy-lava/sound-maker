export love, util, vec2, aabb2, ltable, lmath

buffer = require 'buffer'
cam11 = require 'cam11'
lg = love.graphics

class Workspace
	gridSize: vec2 64, 64
	infoFont: lg.newFont 20
	panelFont: lg.newFont 16
	new: (@sampleRate, @channelCount, @bitDepth = 16, @bufferCount = 4, @bufferSize = 1024) =>
		@generation = 0
		@lastGeneration = @generation - 1
		-- @source = love.audio.newQueueableSource sampleRate, bitDepth, channelCount, bufferCount
		-- @source\setVolume 0.1
		@modules = {}
		@mode = { kind: 'none' }
		@rmode = { kind: 'none' }
		@cam = cam11!
		@zoom = 0
		@cam\setZoom @getZoomAmount!
		@outputPreBuffer = buffer.new bufferSize
		@outputBuffer = love.sound.newSoundData bufferSize, sampleRate, bitDepth, channelCount
		@outputSource = love.audio.newQueueableSource sampleRate, bitDepth, channelCount, bufferCount
		@snapping = true
		
		-- @moduleNames = ltable.imap love.filesystem.getDirectoryItems'module', (filename) -> (filename\gsub '%.[^%.]+$', '')
		@moduleNames = [(item\gsub '%.[^%.]+$', '') for item in *love.filesystem.getDirectoryItems'module']
		@panelOpen = false
		@panelWidth = 320
		@panelOffset = 0
	
	update: (dt) =>
		for module in *@modules
			module\update dt
		wpos = @getMousePos!
		@hoveredSocket = @getSocketAtPoint wpos
		if @mode.kind == 'position'
			module = @mode.module
			delta = @mode.fromPoint\delta wpos
			pos = @mode.fromPos + delta
			module.pos = pos
			module\snapIfNeeded!
		if @mode.kind == 'select'
			@clearSelected!
			for module in *@modules
				if @isModuleInSelection module
					module.selected = true
		if @dragInfo
			delta = wpos\delta @dragInfo.fromPoint
			@cam\setPos (delta + vec2 @cam\getPos!)\split!
		
		while true
			-- Only process if not processed already for this generation
			if @generation != @lastGeneration
				fromBuf = @outputPreBuffer
				toBuf = @outputBuffer
				
				-- Process modules
				buffer.zero fromBuf, @bufferSize
				for module in *@modules
					module\process!
				
				-- Take from sound output modules
				for i = 0, @bufferSize - 1
					toBuf\setSample i, fromBuf[i]
				
				@lastGeneration = @generation
			-- Try to queue up the buffer
			status = @outputSource\queue @outputBuffer
			@outputSource\play! unless @outputSource\isPlaying!
			break unless status
			@generation += 1
	
	draw: =>
		wpos = @getMousePos!
		lg.clear 0.1, 0.1, 0.12, 1
		lg.setLineStyle 'rough'
		lg.setLineJoin 'bevel'
		
		@cam\attach!
		lg.push 'all'
		
		-- Draw buffer of hovered module
		if @hoveredSocket
			buf = if @hoveredSocket[3]
				@hoveredSocket[1]\getInput @hoveredSocket[2]
			else
				@hoveredSocket[1]\getOutput @hoveredSocket[2]
			lg.push 'all'
			lg.origin!
			line = {}
			for i = 0, @bufferSize - 1
				x = i / (@bufferSize - 1) * lg.getWidth!
				y = (-buf[i] * 0.25 / 2 + 0.5) * lg.getHeight!
				ltable.push line, x, y
			lg.setColor 1, 1, 1, 0.05
			lg.setLineWidth 5
			lg.line line
			lg.pop!
		
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
			lg.setColor 1, 1, 1, @snapping and 0.05 or 0.02
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
		lg.setLineWidth 4
		for module in *@modules
			for connection in *module.inputConnections
				p1 = @getModuleOutputPosition connection[1], connection[2]
				p2 = @getModuleInputPosition module, connection[3]
				lg.setColor 0.4, 0.35, 0.7, 1
				if @rmode.kind == 'cut' and @checkConnectionIntersects p1, p2, @getCutLine!
					lg.setColor 0.9, 0.1, 0.1, 1
				@drawConnection p1, p2
		
		-- Draw dragged connection
		if @mode.kind == 'connect'
			socket = @mode.from
			output = @getModuleOutputPosition socket[1], socket[2]
			if output\dist(wpos) > 16
				input = wpos
				if @hoveredSocket and @hoveredSocket[3]
					input = @getModuleInputPosition @hoveredSocket[1], @hoveredSocket[2]
				lg.setColor 0.4, 0.35, 0.7, 1
				@drawConnection output, input
		
		-- Draw module sockets
		for module in *@modules
			lg.push 'all'
			lg.translate module.pos.x, module.pos.y
			module\drawSockets!
			lg.pop!
		
		-- Draw cut
		if @rmode.kind == 'cut'
			lg.push 'all'
			start, stop = @getCutLine!
			lg.setLineWidth 4 / @getZoomAmount!
			lg.setColor 0.9, 0.1, 0.1, 1
			lg.line start.x, start.y, stop.x, stop.y
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
		
		-- Draw hovered socket label
		if @hoveredSocket
			lg.push 'all'
			module = @hoveredSocket[1]
			font = module.font
			lg.setFont font
			
			label = if @hoveredSocket[3]
				module.inputLabels[@hoveredSocket[2]]
			else
				module.outputLabels[@hoveredSocket[2]]
			
			label = label or (@hoveredSocket[3] and 'input' or 'output')
			
			point = if @hoveredSocket[3]
				module\getInputPosition @hoveredSocket[2]
			else
				module\getOutputPosition @hoveredSocket[2]
			point += module.pos
			size = vec2 font\getWidth(label), font\getHeight!
			xoffset = if @hoveredSocket[3]
				-40 - size.x
			else
				40
			point += vec2 xoffset, -size.y / 2
			pad = vec2 8, 8
			tl = point - pad
			br = tl + size + pad * 2
			boxSize = br - tl
			lg.setColor 0.05, 0.05, 0.05, 0.4
			lg.rectangle 'fill', tl.x, tl.y, boxSize.x, boxSize.y, 8, nil, 16
			lg.setColor 0.5, 0.5, 0.55, 1
			lg.print label, lmath.round(point.x), lmath.round(point.y)
			lg.pop!
		
		-- Draw module selection panel
		do
			lg.push 'all'
			lg.origin!
			font = @infoFont
			font\setLineHeight 1.5
			lg.setFont font
			inner = aabb2.fromLove!
			inner\padLeft -@panelWidth if @panelOpen
			inner\pad -24
			lg.setColor 1, 1, 1, 0.1
			text = 'Press TAB to toggle module panel\nPress ` to toggle grid snapping'
			inner\drawText text, vec2!, true
			inner\drawText 'Press F11 to toggle fullscreen', vec2(1, 0), true
			-- lg.print 'Press TAB to toggle module panel\nPress ` to toggle grid snapping', offset.x, offset.y
			if @panelOpen
				font = @panelFont
				lg.setColor 0.2, 0.2, 0.22, 0.5
				lg.rectangle 'fill', 0, 0, @panelWidth, lg.getHeight!
				for i, name in ipairs @moduleNames
					bbox = @getPanelButtonBBox i
					lg.setColor 0.17, 0.17, 0.19, 1
					bbox\drawRectangle 8
					lg.setColor 0.4, 0.4, 0.45, 0.2
					bbox\pad(-16)\drawText i, vec2(0, 0.5), true
					lg.setColor 0.4, 0.4, 0.45, 1
					label = require('module.' .. name).name
					bbox\drawText label, nil, true
			lg.pop!
		
		lg.pop!
		@cam\detach!
	
	getPanelButtonBBox: (index) =>
		assert index <= #@moduleNames
		pad = 16
		spacing = 24
		height = 48
		y = pad + (index - 1) * (height + spacing) - @panelOffset
		return aabb2 pad, @panelWidth - pad, y, y + height
	
	getConnectionBezier: (fromOutputPoint, toInputPoint) =>
		c1x = lmath.lerp 1 / 2, fromOutputPoint.x, toInputPoint.x
		c2x = lmath.lerp 1 / 2, fromOutputPoint.x, toInputPoint.x
		c1x = math.max c1x, fromOutputPoint.x + 96
		c2x = math.min c2x, toInputPoint.x - 96
		c1 = vec2 c1x, fromOutputPoint.y
		c2 = vec2 c2x, toInputPoint.y
		return love.math.newBezierCurve fromOutputPoint.x, fromOutputPoint.y, c1.x, c1.y, c2.x, c2.y, toInputPoint.x, toInputPoint.y
	
	checkConnectionIntersects: (fromOutputPoint, toInputPoint, p1, p2) =>
		curve = @getConnectionBezier fromOutputPoint, toInputPoint
		line = curve\render 2
		ppoint, cpoint = nil, vec2 line[1], line[2]
		for i = 3, #line, 2
			ppoint = cpoint
			cpoint = vec2 line[i], line[i + 1]
			return true if util.checkLinesIntersect ppoint, cpoint, p1, p2
		return false
	
	drawConnection: (fromOutputPoint, toInputPoint) =>
		curve = @getConnectionBezier fromOutputPoint, toInputPoint
		line = curve\render 4
		love.graphics.line line
	
	getZoomAmount: => 2 ^ @zoom
	
	keypressed: (key) =>
		if key == 'delete'
			@deleteSelected!
			return
		if key == 'tab'
			@panelOpen = not @panelOpen
			return
		if key == '`'
			@snapping = not @snapping
			return
		num = tonumber key
		if num
			num = 10 if num == 0
			name = @moduleNames[num]
			if name
				@spawnModule name, @getMousePos!
	keyreleased: =>
	mousepressed: (x, y, button) =>
		if @panelOpen and x < @panelWidth
			mpos = vec2 x, y
			for i, name in ipairs @moduleNames
				bbox = @getPanelButtonBBox i
				if bbox\hasPoint mpos
					@spawnModule name
					break
			return
		wpos = @getMousePos!
		if button == 1
			socket = @getSocketAtPoint wpos
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
			
			module = @getModuleAtPoint wpos
			if module
				if wpos.y < module.pos.y + module.labelHeight
					for i, mod in ipairs @modules
						if mod == module
							table.insert @modules, table.remove @modules, i
							break
					@mode = {
						kind: 'position'
						fromPoint: wpos.copy
						fromPos: module.pos.copy
						module: module
					}
					return
				mpos = module.pos
				module\mousepressed wpos.x - mpos.x, wpos.y - mpos.y - module.labelHeight, button
				@activeModule = module
				return
			
			-- Do selection
			@clearSelected!
			@mode = {
				kind: 'select'
				fromPoint: wpos.copy
			}
		if button == 2
			module = @getModuleAtPoint wpos
			if module
				unless wpos.y < module.pos.y + module.labelHeight
					mpos = module.pos
					module\mousepressed wpos.x - mpos.x, wpos.y - mpos.y - module.labelHeight, button
					@ractiveModule = module
				return
			@rmode = {
				kind: 'cut'
				fromPoint: wpos.copy
			}
		if button == 3
			@dragInfo = {
				fromPoint: wpos.copy
			}
	
	mousereleased: (x, y, button) =>
		wpos = @getMousePos!
		if button == 1
			if @activeModule
				mpos = @activeModule.pos
				@activeModule\mousereleased wpos.x - mpos.x, wpos.y - mpos.y - @activeModule.labelHeight, button
				@activeModule = nil
				return
			if @mode.kind == 'connect'
				to = @getSocketAtPoint @getMousePos!
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
		if button == 2
			if @ractiveModule
				mpos = @ractiveModule.pos
				@ractiveModule\mousereleased wpos.x - mpos.x, wpos.y - mpos.y - @ractiveModule.labelHeight, button
				@ractiveModule = nil
				return
			if @rmode.kind == 'cut'
				for module in *@modules
					for i, connection in ltable.ripairs module.inputConnections
						p1 = @getModuleOutputPosition connection[1], connection[2]
						p2 = @getModuleInputPosition module, connection[3]
						if @checkConnectionIntersects p1, p2, @getCutLine!
							table.remove module.inputConnections, i
			@rmode = { kind: 'none' }
			return
		if button == 3
			@dragInfo = nil
			return
	
	wheelmoved: (dx, dy) =>
		if @panelOpen and love.mouse.getX! < @panelWidth
			@scrollPanel dy
			return
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
	
	getCutLine: =>
		return nil if @rmode.kind != 'cut'
		return @rmode.fromPoint, @getMousePos!
	
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
	
	getModuleAtPoint: (point) =>
		return nil if @hoveredSocket
		for _, module in ltable.ripairs @modules
			tl = module.pos
			br = tl + module.size
			if point.x >= tl.x and point.y >= tl.y and point.x < br.x and point.y < br.y
				return module
		return nil
	
	getSocketAtPoint: (point) =>
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
	
	scrollPanel: (dy) =>
		lastBBox = @getPanelButtonBBox #@moduleNames
		limit = lastBBox.y1 + @panelOffset - 8
		@panelOffset -= dy * 32
		@panelOffset = lmath.clamp @panelOffset, 0, limit
	
	spawnModule: (name, point) =>
		unless point
			x, y = lg.getDimensions!
			point = vec2 @cam\toWorld x / 2, y / 2
		Module = require 'module.' .. name
		mod = Module @, point
		mod.pos -= mod.size / 2
		@addModule mod
		mod\snapIfNeeded!
	
	addModule: (mod) =>
		-- NOTE: We're setting the workspace in the constructor, that's kinda sus but whatever
		-- mod.workspace = @
		table.insert @modules, mod
	removeModule: (mod) =>
		assert mod.workspace == @, "trying to remove a module that doesn't belong to the workspace"
		for i = 1, #@modules
			if @modules[i] == mod
				mod.workspace = nil
				table.remove @modules, i
				return
		error "could not find module in workspace"