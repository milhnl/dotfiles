# Maintainer: Anatol Pomozov <anatol.pomozov@gmail.com>

pkgname=shairport-sync
pkgrel=1
pkgver=4.1.dev.r246.g0b8fdf0d
pkgdesc='AirPlay 2 Server'
url='https://github.com/mikebrady/shairport-sync'
arch=(x86_64 armv7h aarch64)
license=(GPL)
backup=(etc/shairport-sync.conf)
depends=(openssl avahi libsoxr popt alsa-lib libconfig libpulse jack mosquitto
    libsodium libplist ffmpeg4.4 nqptp)
makedepends=(xmltoman xxd ffmpeg4.4 python)
source=("git+https://github.com/mikebrady/shairport-sync#commit=0b8fdf0d820c")
sha1sums=(SKIP)

pkgver() {
  cd "$srcdir/$pkgname"
  git describe --long --tags | sed 's/\([^-]*-g\)/r\1/;s/-/./g'
}

prepare() {
  cd shairport-sync
  sed -i 's/\sgetent/ #getent/g' Makefile.am
}

build() {
  cd shairport-sync
  export PKG_CONFIG_PATH="/usr/lib/ffmpeg4.4/pkgconfig/:$PKG_CONFIG_PATH"
  autoreconf -i -f
  ./configure --prefix=/usr --sysconfdir=/etc --with-alsa --with-pa \
    --with-avahi --with-jack --with-stdout --with-pipe --with-ssl=openssl \
    --with-soxr --with-dns_sd --with-pkg-config --with-systemd \
    --with-configfiles --with-metadata --with-mqtt-client \
    --with-mpris-interface --with-airplay-2
  make
}

package() {
  cd shairport-sync
  make DESTDIR="$pkgdir" install
  >"$srcdir"/shairport-sync.sysusers printf "%s\n" \
    'u shairport-sync - "AirPlay receiver" /var/lib/shairport-sync' \
    'g shairport-sync' \
    'm shairport-sync audio'
  install -D -m644 "$srcdir"/shairport-sync.sysusers \
    "$pkgdir"/usr/lib/sysusers.d/shairport-sync.conf
  install -D -m664 LICENSES "$pkgdir"/usr/share/licenses/$pkgname/LICENSE
  rm "$pkgdir"/etc/shairport-sync.conf.sample
}
