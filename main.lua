local buffer_new = require 'buffer'.new
local Module = require 'module'

local source
local buffer
local currentGeneration
local lastGeneration

local sampleRate = 48000
local bitDepth = 16
local channelCount = 1
local bufferSize = 1024
local bufferCount = 4

local rootModule

local function nextGeneration()
	currentGeneration = currentGeneration + 1
end

local function registerModules()
	Module.register {
		name = 'sine',
		create = function()
			local mod = {}
			
			mod.pos = 0
			mod.width = 240
			mod.height = 200
			mod.freq = 440
			mod.inputs = {}
			mod.outputs = {}
			
			table.insert(mod.outputs, {
				buffer = buffer_new(bufferSize)
			})
			
			return mod
		end,
		process = function(self)
			local buf = self.outputs[1].buffer
			for i = 0, self.bufferSize do
				local freq = self.freq
				buf[i] = math.sin(self.pos % 1 * math.pi * 2)
				self.pos = self.pos + freq / sampleRate
			end
		end,
		draw = function(self)
			love.graphics.setColor(0.4, 0.4, 0.4, 1)
			love.graphics.rectangle('fill', 0, 0, self.width, self.height, 12, nil, 32)
		end
	}
end

function love.load()
	source = love.audio.newQueueableSource(sampleRate, bitDepth, channelCount, bufferCount)
	source:setVolume(0.1)
	buffer = love.sound.newSoundData(bufferSize, sampleRate, bitDepth, channelCount)
	currentGeneration = 0
	lastGeneration = currentGeneration - 1
	registerModules()
	rootModule = Module.instance('sine', bufferSize, 100, 100)
end

local function fillBuffer()
	rootModule:process(currentGeneration)
	for i = 0, bufferSize - 1 do
		buffer:setSample(i, rootModule.outputs[1].buffer[i])
	end
end

function love.update()
	while true do
		if lastGeneration ~= currentGeneration then
			fillBuffer()
			lastGeneration = currentGeneration
		end
		local status = source:queue(buffer)
		if not source:isPlaying() then source:play() end
		if not status then break end
		nextGeneration()
	end
end

function love.draw()
	rootModule:draw()
end

function love.keypressed(key)
	if key == 'f11' or (key == 'return' and love.keyboard.isDown('lalt', 'ralt')) then
		love.window.setFullscreen(not love.window.getFullscreen())
	end
end
