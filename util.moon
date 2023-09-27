export vec2
util = {}

ccw = (a, b, c) -> (c.y - a.y) * (b.x - a.x) > (b.y - a.y) * (c.x - a.x)
util.checkLinesIntersect = (a, b, c, d) -> return ccw(a, c, d) != ccw(b, c, d) and ccw(a, b, c) != ccw(a, b, d)

util.amp2db = (amp) -> 20 * math.log10 amp
util.db2amp = (db) -> 10 ^ (db / 20)

return util