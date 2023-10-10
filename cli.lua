local argparse = require 'argparse'
local parser = argparse()

parser:flag '--moonscript' :default(false):hidden(true)

parser:group('Display options',
	parser:option('--display', 'Which monitor to open on (1 is primary)'):default '1':convert(tonumber),
	parser:flag('--vsync', 'Enable screen vsync (default)'):target'vsync':action 'store_true',
	parser:flag('--no-vsync', 'Disable screen vsync'):target'vsync':default(true):action 'store_false'
)

option = parser:parse(love.arg.parseGameArguments(arg))