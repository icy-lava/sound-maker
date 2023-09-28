export lmath, vec2
Slider = require 'widget.slider'
class Sine extends require 'module'
	name: 'sine'
	new: (...) =>
		super ...
		@setInputCount 1
		@setOutputCount 1
		@phase = 0
		sine = @
		
		do
			@octave = Slider @, vec2(32, 24), vec2 @size.x - 64, 40
			@octave.defaultValue = 0
			@octave.value = @octave.defaultValue
			@octave.minValue = -8
			@octave.maxValue = 8
			@octave.step = 1
			@octave.getLabel = => string.format('Octave: %d', sine.octave.value)
		
		do
			@semitone = Slider @, vec2(32, 36 + 40), vec2 @size.x - 64, 40
			@semitone.defaultValue = 0
			@semitone.value = @semitone.defaultValue
			@semitone.minValue = -12
			@semitone.maxValue = 12
			@semitone.step = 1
			@semitone.getLabel = => string.format('Semitone: %d', sine.semitone.value)
		
		do
			@tune = Slider @, vec2(32, 48 + 40 * 2), vec2 @size.x - 64, 40
			@tune.defaultValue = 0
			@tune.value = @tune.defaultValue
			@tune.minValue = -100
			@tune.maxValue = 100
			@tune.getLabel = => string.format('Tune: %d', sine.tune.value)
	
	_process: =>
		ibuf = @getInput(1)
		obuf = @getOutput(1)
		phaseStep = 440 * 2 ^ (@octave.value + (@semitone.value + @tune.value / 100) / 12) / @workspace.sampleRate
		for i = 0, @getBufferSize! - 1
			obuf[i] = math.sin(@phase % 1 * lmath.tau)
			@phase = @phase + phaseStep * 2 ^ ibuf[i]