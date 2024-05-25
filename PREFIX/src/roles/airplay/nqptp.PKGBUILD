pkgname=nqptp
pkgrel=1
pkgver=1.2.5.dev.r10.gcfa8315
pkgdesc="Not Quite PTP"
arch=(x86_64 armv7h aarch64)
url="https://github.com/mikebrady/nqptp"
license=(GPL2)
source=("git+https://github.com/mikebrady/nqptp#commit=cfa8315e")
md5sums=('SKIP')

pkgver() {
  cd "$srcdir/nqptp"
  git describe --long --tags | sed 's/\([^-]*-g\)/r\1/;s/-/./g'
}

prepare() {
  cd "$srcdir/nqptp"
  sed -i 's/\sgetent/ #getent/g' Makefile.am
}

build() {
  cd "$srcdir/nqptp"
  autoreconf -fi
  ./configure --prefix=/usr --with-systemd-startup
  make
}

package() {
  cd "$srcdir/nqptp"
  make DESTDIR="$pkgdir" install
  >"$srcdir"/nqptp.sysusers printf "%s\n" \
    'u nqptp - "Not Quite PTP" /var/lib/nqptp' \
    'g nqptp'
  install -D -m644 "$srcdir"/nqptp.sysusers \
    "$pkgdir"/usr/lib/sysusers.d/nqptp.conf
  install -D -m664 LICENSE "$pkgdir"/usr/share/licenses/$pkgname/LICENSE
}
