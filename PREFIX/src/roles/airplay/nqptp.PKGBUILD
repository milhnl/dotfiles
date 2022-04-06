pkgname=nqptp
pkgrel=1
pkgver=1.1.dev.r132.gc91a2bb
pkgdesc="Not Quite PTP"
arch=(x86_64 armv7h)
url="https://github.com/mikebrady/nqptp"
license=(GPL2)
source=("git+https://github.com/mikebrady/nqptp#commit=c91a2bb2")
md5sums=('SKIP')

pkgver() {
  cd "$srcdir/nqptp"
  git describe --long --tags | sed 's/\([^-]*-g\)/r\1/;s/-/./g'
}

build() {
  cd "$srcdir/nqptp"
  autoreconf -fi
  ./configure --prefix=/usr --with-systemd-startup
  make
}

package() {
  cd "$srcdir/nqptp"
  make DESTDIR="$pkgdir/" install
}
