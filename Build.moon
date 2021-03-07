public var AMALG: 'amalg.lua'
public var RM: 'rm', '-f', '--'
public var LUA: 'lua5.3'

var LIB_LUA: _.wildcard 'todo/**.lua'
var BIN_LUA: 'bin/ttodo'
var OUT: _.patsubst BIN_LUA, 'bin/%', 'out/%'

var MODULES: _.foreach (_.patsubst LIB_LUA, '%.lua', '%'), => @gsub '/', '.'

var INSTALL_DIR: '/usr/local/bin'
var HOME_INSTALL_DIR: if _.exists "#{os.getenv("HOME")}/bin"
	"#{os.getenv("HOME")}/bin"
else
	"#{os.getenv("HOME")}/.local/bin"

with public default target 'all'
	\after 'bin'

with public target 'bin'
	\depends OUT

with public target 'install'
	\depends OUT
	\produces _.patsubst OUT, 'out/%', "#{INSTALL_DIR}/%"
	\fn => _.cmd 'sudo', 'install', '-m755', '-o0', '-g0', @infile, @out

with public target 'homeinstall'
	\depends OUT
	\produces _.patsubst OUT, 'out/%', "#{HOME_INSTALL_DIR}/%"
	\fn => _.cmd 'install', '-m755', @infile, @out

with public target 'mrproper'
	\fn => _.cmd RM, OUT

with target OUT
	\depends BIN_LUA
	\depends LIB_LUA
	\produces '%'
	\fn =>
		_.cmd AMALG, '-o', @out, '-s', @infile, MODULES
		_.cmd 'chmod', '+x', @out
