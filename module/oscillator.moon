export lmath, vec2
Slider = require 'widget.slider'
class Oscillator extends require 'module'
	name: 'oscillator'
	inputLabels: {'amplitude', 'octave offset'}
	new: (...) =>
		super ...
		@size.y = 64 * 5
		@setInputCount 2
		@setOutputCount 1
		@phase = 0
		oscillator = @
		
		do
			@octave = Slider @, vec2(32, 24), vec2 @size.x - 64, 40
			@octave.defaultValue = 0
			@octave.value = @octave.defaultValue
			@octave.minValue = -8
			@octave.maxValue = 8
			@octave.step = 1
			@octave.getLabel = => string.format('Octave: %d', oscillator.octave.value)
		
		do
			@semitone = Slider @, vec2(32, 36 + 40), vec2 @size.x - 64, 40
			@semitone.defaultValue = 0
			@semitone.value = @semitone.defaultValue
			@semitone.minValue = -12
			@semitone.maxValue = 12
			@semitone.step = 1
			@semitone.getLabel = => string.format('Semitone: %d', oscillator.semitone.value)
		
		do
			@tune = Slider @, vec2(32, 48 + 40 * 2), vec2 @size.x - 64, 40
			@tune.defaultValue = 0
			@tune.value = @tune.defaultValue
			@tune.minValue = -100
			@tune.maxValue = 100
			@tune.getLabel = => string.format('Tune: %d', oscillator.tune.value)
		
		do
			@osc = Slider @, vec2(32, 60 + 40 * 3), vec2 @size.x - 64, 40
			@osc.defaultValue = 1
			@osc.value = @osc.defaultValue
			@osc.minValue = 1
			@osc.maxValue = 4
			@osc.step = 1
			@osc.getLabel = => string.format('%s', oscillator.oscillators[@value][1])
	
	oscillators: {
		{'sine', (t) -> math.sin(t % 1 * lmath.tau)},
		{'triangle', (t) -> math.abs(((t + 0.75) % 1) - 0.5) * 4 - 1},
		{'square', (t) -> t % 1 < 0.5 and 1 or -1},
		{'saw', (t) -> ((t + 0.5) % 1) * 2 - 1},
	}
	
	_process: =>
		abuf = @getInput 1
		fbuf = @getInput 2
		obuf = @getOutput 1
		phaseStep = 440 * 2 ^ (@octave.value + (@semitone.value + @tune.value / 100) / 12) / @workspace.sampleRate
		osc = @oscillators[@osc.value][2]
		amp = 1
		for i = 0, @getBufferSize! - 1
			amp = abuf[i] if @hasInput 1
			obuf[i] = osc(@phase) * amp
			@phase = @phase + phaseStep * 2 ^ fbuf[i]