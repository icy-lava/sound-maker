export vec2
format = string.format
util = {}

ccw = (a, b, c) -> (c.y - a.y) * (b.x - a.x) > (b.y - a.y) * (c.x - a.x)
util.checkLinesIntersect = (a, b, c, d) -> return ccw(a, c, d) != ccw(b, c, d) and ccw(a, b, c) != ccw(a, b, d)

util.amp2db = (amp) -> 20 * math.log10 amp
util.db2amp = (db) -> 10 ^ (db / 20)

util.seconds = (s) ->
	return format '%0.1fms', s * 1000 if s < 1
	return format '%0.1fs', s

return util