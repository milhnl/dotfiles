# Accumulated cruft

This repository contains most of my configuration and helper programs. There is
another repository like it, called `shadow` (in the `passwd` sense) that
contains non-public files.

One central theme in this work is bootstrapping with the least amount of
dependencies. Most of what is contained here should run and integrate with
macOS, WSL, Alpine, Arch, OpenWRT unchanged.

## Organisation

The top-level directories are all environment variable names. The paths those
map to differ between macOS and Linux. The Makefile creates symbolic links for
every single file.

## Idioms and significant locations

Every script is POSIX2024 compatible, without the `local` variable extension.
The last constraint is possibly a bit over-the top as I don't know any systems
missing `local`, but I try my hardest to avoid shell variables where possible.
My scripting style is terse, almost to the point of golfing. I think it is more
readable but I know I am the exception in this.

- `PREFIX/lib/sh/lazyload`: Packages with an executable entrypoint that don't
  need any specific initialization and are configured via `XDG_CONFIG_HOME`
  etc. are automatically installed via a 'declarative' description that is in
  this directory. Almost every file here specifies
  [pmmux](https://github.com/eforah-oss/pmmux) as the interpreter, which calls
  the package manager of the current system and then `exec`s into it.
- `PREFIX/src/roles`: [judo](https://github.com/rollcat/judo) scripts that act
  a bit like Ansible roles. I do not like Ansible or similar technologies due
  to bootstrapping issues and overcomplicated design. These files and folders
  are scripts that modify a system to make it perform a certain role. `init` is
  the role that runs on literally every system I own, other roles vary in their
  specificity. There is a bundled `systemd-{tmpfiles,sysusers}` implementation
  for systems that lack it.
- `XDG_BIN_HOME/write_os`: Writes an OS image to a file or device, and runs it
  via QEMU if requested. This image will execute the bundled configuration (via
  the same roles as `judo`) on first boot. Currently it also includes a helper
  that'll ensure a necessary subset of packages is present. This is a temporary
  solution(tm) until I figure out how to add this to `apk` itself, if the
  maintainers like a version of the idea. `write_os` (and most of this
  repository) should work without an Internet connection.
- `PREFIX/src/abuild-repo`: Contains APKBUILDs for programs that do not
  necessarily need to be installed via a role. APKBUILDs are run via a wrapper
  script called `abuild_wrap` by the way, to enable on-first-boot installation.
- `XDG_CONFIG_HOME/workspace/config`: This configuration file allows
  [workspace](https://github.com/eforah-oss/workspace) to manage and lazily
  initialize repository folders (by default in `$XDG_DATA_HOME/workspace`).
  Most programs linked in this document are there.
