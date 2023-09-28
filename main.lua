local Workspace = require 'workspace'
local Module = require 'module'
local Oscillator = require 'module.oscillator'
local Delay = require 'module.delay'
local Output = require 'module.output'
local Amp = require 'module.amp'

local sampleRate = 48000
local bitDepth = 16
local channelCount = 1
local bufferSize = 1024
local bufferCount = 4

local workspace

function love.load()
	workspace = Workspace(sampleRate, channelCount)
	local modA = Oscillator(workspace, vec2(600, 50))
	local modA2 = Oscillator(workspace, vec2(800, 50))
	local modB = Delay(workspace, vec2(100, 100))
	local modC = Output(workspace, vec2(1000, 50))
	local modD = Amp(workspace, vec2(1000, 550))
	workspace:addModule(modA)
	workspace:addModule(modA2)
	workspace:addModule(modB)
	workspace:addModule(modC)
	workspace:addModule(modD)
end

function love.keypressed(...)
	local key = ...
	
	if key == 'f11' or (key == 'return' and love.keyboard.isDown('lalt', 'ralt')) then
		love.window.setFullscreen(not love.window.getFullscreen())
		return
	end
	
	if key == 'q' and love.keyboard.isDown('lctrl', 'rctrl') then
		love.event.quit()
		return
	end
	
	workspace:keypressed(...)
end

function love.keyreleased(...)
	workspace:keyreleased(...)
end

function love.mousepressed(...)
	workspace:mousepressed(...)
end

function love.mousereleased(...)
	workspace:mousereleased(...)
end

function love.wheelmoved(...)
	workspace:wheelmoved(...)
end

function love.resize(...)
	workspace:resize(...)
end

function love.update(dt)
	workspace:update(dt)
end

function love.draw()
	workspace:draw()
end