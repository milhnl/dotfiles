.POSIX:
.SUFFIXES:
.ONESHELL:
.PHONY: dotfiles risknow

dotfiles:; git clone https://milhnl@github.com/milhnl/dotfiles ${PREFIX}/dot

finrust:
	git clone https://michieleforah@bitbucket.org/eforah/adviseursrust finrust
	cd finrust
	git switch develop

digidrust:; git clone https://michieleforah@bitbucket.org/eforah/digidrust

proxyrust:; git clone https://michieleforah@bitbucket.org/eforah/proxyrust

EVI360:
	git clone https://michieleforah@github.com/EVI-Digital/EVI360
	cd EVI360
	git switch development
	mkdir -p "$$XDG_CONFIG_HOME/composer"
	pass show misc/evi-composer >"$$XDG_CONFIG_HOME/composer/auth.json"
	sh "$$PREFIX/src/roles/mariadb"
	pmmux -1 pacman+'php7 php7-gd composer'
	</etc/php7/php.ini sed \
		-e '/^;\{0,1\}extension=gd$$/d;/\[PHP\]/aextension=gd' \
		-e '/^;\{0,1\}extension=iconv$$/d;/\[PHP\]/aextension=iconv' \
		-e '/^;\{0,1\}extension=pdo_mysql$$/d;/\[PHP\]/aextension=pdo_mysql' \
		| sudo tee '/etc/php7/php.ini.new' >/dev/null
	sudo mv /etc/php7/php.ini.new /etc/php7/php.ini
	npm ci
	make init

flexcard:; git clone https://michieleforah@github.com/gloedonline/flexcard

participatietool:
	git clone https://michieleforah@bitbucket.org/eforah/participatietool

risknow:
	git clone https://michieleforah@github.com/risknow-com/risknow "${XDG_DATA_HOME}/go/src/risknow"

firefox_cli:; git clone https://milhnl@github.com/milhnl/firefox_cli

pmmux:; git clone https://milhnl@github.com/milhnl/pmmux

ump:; git clone https://milhnl@github.com/milhnl/ump

workspace:; git clone https://milhnl@github.com/milhnl/workspace

pass:; git clone https://milhnl@github.com/milhnl/pass

mpmc:; git clone https://milhnl@github.com/milhnl/mpmc

rubbersheet:; git clone https://milhnl@github.com/milhnl/rubbersheet

ump_rs:; git clone https://milhnl@github.com/milhnl/ump_rs.git
