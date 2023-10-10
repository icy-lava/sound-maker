VERSION = '0.1.0'

require 'cli'

if option.moonscript then
	require 'moonscript'
end

lithium = require 'lithium.init'
ltable = lithium.table
lio = lithium.io
lstring = lithium.string
lmath = lithium.math
color = lithium.color
vec2 = lithium.vec2
aabb2 = require 'aabb2'
util = require 'util'

function love.conf(t)
	t.identity = 'sound-maker'
	t.window.vsync = option.vsync and 1 or 0
	t.window.title = 'Sound Maker'
	t.window.display = option.display
	t.window.height = 720
	t.window.width = math.floor(t.window.height * 4 / 3)
	t.window.resizable = true
	t.window.msaa = 4
end

function love.run()
	if love.load then love.load(love.arg.parseGameArguments(arg), arg) end

	-- We don't want the first frame's dt to include time taken by love.load.
	if love.timer then love.timer.step() end

	local dt = 0

	-- Main loop time.
	return function()
		-- Process events.
		if love.event then
			love.event.pump()
			for name, a,b,c,d,e,f in love.event.poll() do
				if name == "quit" then
					if not love.quit or not love.quit() then
						return a or 0
					end
				end
				love.handlers[name](a,b,c,d,e,f)
			end
		end

		-- Update dt, as we'll be passing it to update
		if love.timer then dt = love.timer.step() end

		-- Call update and draw
		if love.update then love.update(dt) end -- will pass 0 if love.timer is disabled

		if love.graphics and love.graphics.isActive() then
			love.graphics.origin()
			love.graphics.clear(love.graphics.getBackgroundColor())

			if love.draw then love.draw() end

			love.graphics.present()
		end

		if love.timer then love.timer.sleep(0.002) end
	end
end