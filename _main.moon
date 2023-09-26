buffer_new = require'buffer'.new

Workspace = require 'workspace'
Module = require 'module'

sampleRate = 48000
bitDepth = 16
channelCount = 1
bufferSize = 1024
bufferCount = 4

local workspace

love.load = ->
	workspace = Workspace sampleRate, channelCount
	workspace\addModule Module!

love.update = (dt) ->
	workspace\update dt

love.draw = ->
	workspace\draw!