.POSIX:
.SUFFIXES:
.PHONY: dotfiles

dotfiles:; git clone https://milhnl@github.com/milhnl/dotfiles ${PREFIX}/dot

finrust:
	git clone https://michieleforah@bitbucket.org/eforah/adviseursrust finrust

digidrust:; git clone https://michieleforah@bitbucket.org/eforah/digidrust

proxyrust:; git clone https://michieleforah@bitbucket.org/eforah/proxyrust

EVI360:; git clone https://michieleforah@github.com/EVI-Digital/EVI360

flexcard:; git clone https://michieleforah@github.com/gloedonline/flexcard

participatietool:
	git clone https://michieleforah@bitbucket.org/eforah/participatietool

firefox_cli:; git clone https://milhnl@github.com/milhnl/firefox_cli

pmmux:; git clone https://milhnl@github.com/milhnl/pmmux

ump:; git clone https://milhnl@github.com/milhnl/ump

workspace:; git clone https://milhnl@github.com/milhnl/workspace

pass:; git clone https://milhnl@github.com/milhnl/pass

mpmc:; git clone https://milhnl@github.com/milhnl/mpmc

rubbersheet:; git clone https://milhnl@github.com/milhnl/rubbersheet
