.POSIX:
.SUFFIXES:
.ONESHELL:
.PHONY: dotfiles risknow

setWorkAccount = git config user.email "michiel@eforah.nl"

dotfiles:; git clone https://milhnl@github.com/milhnl/dotfiles ${PREFIX}/dot

finrust:
	git clone https://michieleforah@bitbucket.org/eforah/adviseursrust finrust
	cd finrust
	${setWorkAccount}
	git switch develop

digidrust:;
	git clone https://michieleforah@bitbucket.org/eforah/digidrust
	cd digidrust
	${setWorkAccount}

proxyrust:;
	git clone https://michieleforah@bitbucket.org/eforah/proxyrust
	cd proxyrust
	${setWorkAccount}

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

flexcard:;
	git clone https://michieleforah@github.com/gloedonline/flexcard
	cd flexcard
	${setWorkAccount}

participatietool:
	git clone https://michieleforah@bitbucket.org/eforah/participatietool
	cd participatietool
	${setWorkAccount}

risknow:
	git clone https://michieleforah@bitbucket.org/eforah/risknow "${XDG_DATA_HOME}/go/src/risknow"
	cd "${XDG_DATA_HOME}/go/src/risknow"
	${setWorkAccount}
	<.env.default sed "s/test@example.com/michiel@eforah.nl/" >.env
	make init

firefox_cli:; git clone https://milhnl@github.com/milhnl/firefox_cli

pmmux:; git clone https://milhnl@github.com/milhnl/pmmux

ump:; git clone https://milhnl@github.com/milhnl/ump

workspace:; git clone https://milhnl@github.com/milhnl/workspace

pass:; git clone https://milhnl@github.com/milhnl/pass

mpmc:; git clone https://milhnl@github.com/milhnl/mpmc

rubbersheet:; git clone https://milhnl@github.com/milhnl/rubbersheet

ump_rs:; git clone https://milhnl@github.com/milhnl/ump_rs.git
