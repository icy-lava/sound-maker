export lmath, vec2, util
Slider = require 'widget.slider'

ATTACK  = 0
DECAY   = 1
SUSTAIN = 2
RELEASE = 3

class ADSR extends require 'module'
	name: 'adsr'
	inputLabels: {'input', 'on (rising edge)', 'off (falling edge)'}
	new: (...) =>
		super ...
		@size.x = 64 * 7
		@size.y = 64 * 3
		@setInputCount 3
		@setOutputCount 1
		@state = 0
		@phase = 0
		@amp = 0
		@releaseAmp = 0
		adsr = @
		@canStart = true
		@canStop = false
		
		do
			size = (@size.x - 32 * 2 - 16) / 2
			
			@attack = Slider @, vec2(32, 24), vec2 size, 40
			@attack.minValue = 1e-9
			@attack.defaultValue = (0.02 / 10) ^ (1 / 3)
			@attack.value = @attack.defaultValue
			@attack.getLabel = => string.format 'Attack: %s', util.seconds adsr\getAttack!
			
			@decay = Slider @, vec2(32 + size + 16, 24), vec2 size, 40
			@decay.minValue = 1e-9
			@decay.defaultValue = (0.1 / 10) ^ (1 / 3)
			@decay.value = @decay.defaultValue
			@decay.getLabel = => string.format 'Decay: %s', util.seconds adsr\getDecay!
		
		do
			size = (@size.x - 32 * 2 - 16) / 2
			
			@sustain = Slider @, vec2(32, 40 + 40), vec2 size, 40
			@sustain.getLabel = => string.format 'Sustain: %d%%', adsr\getSustain! * 100
			
			@release = Slider @, vec2(32 + size + 16, 40 + 40), vec2 size, 40
			@release.minValue = 1e-9
			@release.defaultValue = (0.25 / 10) ^ (1 / 3)
			@release.value = @release.defaultValue
			@release.getLabel = => string.format 'Release: %s', util.seconds adsr\getRelease!
	
	getAttack: => @attack.value ^ 3 * 10
	getDecay: => @decay.value ^ 3 * 10
	getSustain: => @sustain.value
	getRelease: => @release.value ^ 3 * 10
	
	_process: =>
		ibuf = @getInput 1
		onbuf = @getInput 2
		offbuf = @getInput 3
		obuf = @getOutput 1
		
		hasInput1 = @hasInput 1
		state = @state
		phase = @phase
		amp = @amp
		releaseAmp = @releaseAmp
		
		attack = @getAttack!
		decay = @getDecay!
		sustain = @getSustain!
		isustain = 1 - sustain
		release = @getRelease!
		
		phaseStep = 1 / @workspace.sampleRate
		isPlaying = @isPlaying
		canStart = @canStart
		canStop = @canStop
		sample = 1
		
		for i = 0, @getBufferSize! - 1
			sample = ibuf[i] if hasInput1
			if onbuf[i] > 0.5
				if canStart
					state = ATTACK
					isPlaying = true
					phase = 0
					amp = 0
					releaseAmp = 0
					canStart = false
			else canStart = true
			if offbuf[i] <= 0.5
				if canStop
					state = if isPlaying
						releaseAmp = amp
						RELEASE
					else
						amp = 0
						releaseAmp = 0
						ATTACK
					phase = 0
					canStop = false
			else canStop = true
			
			if state == ATTACK
				amp = phase / attack
			elseif state == DECAY
				amp = 1 - phase / decay * isustain
			elseif state == SUSTAIN
				amp = sustain
			elseif state == RELEASE
				amp = (1 - phase / release) * releaseAmp
			
			obuf[i] = amp * sample
			if isPlaying
				phase += phaseStep
				while true
					if state == ATTACK
						if phase >= attack
							phase -= attack
							state += 1
						else
							break
					elseif state == DECAY
						if phase >= decay
							phase -= decay
							state += 1
						else
							break
					elseif state == SUSTAIN
						break
					elseif state == RELEASE
						if phase >= release
							phase = 0
							isPlaying = false
							state = ATTACK
						else
							break
						
		@state = state
		@phase = phase
		@amp = amp
		@releaseAmp = releaseAmp
		@isPlaying = isPlaying
		@canStart = canStart
		@canStop = canStop