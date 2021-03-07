moonbuild = require 'moonbuild'

tasks:
	release: =>
		error "no version provided" unless @v
		tasks.build!
		sh "rockbuild -m -t #{@v} upload"

	build: => moonbuild j: true
	install: => moonbuild 'install', j: true
	homeinstall: => moonbuild 'homeinstall', j: true
	mrproper: => moonbuild 'mrproper'
