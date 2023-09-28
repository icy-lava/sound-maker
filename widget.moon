export love, vec2
lg = love.graphics
class Widget
	new: (@module, @pos = vec2!, @size = vec2 32, 32) =>
		table.insert @module.widgets, @
	font: lg.newFont 16
	
	mousepressed: (...) => @_mousepressed ... if @_mousepressed
	mousereleased: (...) => @_mousereleased ... if @_mousereleased
	keypressed: (...) => @_keypressed ... if @_keypressed
	keyreleased: (...) => @_keyreleased ... if @_keyreleased
	
	update: (dt) => @_update dt if @_update
	draw: => @_draw! if @_draw
	
	getMousePos: => @module\getMousePos! - @pos
	isActive: => @ == @module.activeWidget
	isRActive: => @ == @module.ractiveWidget