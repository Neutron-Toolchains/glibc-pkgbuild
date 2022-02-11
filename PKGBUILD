# Maintainer:  Dakkshesh <dakkshesh5@gmail.com>
# Contributor: Allan McRae <allan@archlinux.org>

# toolchain build order: linux-api-headers->glibc->binutils->gcc->glibc->binutils->gcc
# NOTE: valgrind requires rebuilt with each major glibc version

pkgbase=glibc-x86_64
pkgname=(glibc-x86_64 lib32-glibc-x86_64)
pkgver=2.35
pkgrel=4
arch=(x86_64)
url='https://www.gnu.org/software/libc'
license=(GPL LGPL)
makedepends=(git gd lib32-gcc-libs python)
optdepends=('perl: for mtrace')
options=(!strip staticlibs)
source=("git+https://sourceware.org/git/glibc.git#branch=release/$pkgver/master"
        locale.gen.txt
        pull-locale.sh
        locale-gen
        lib32-glibc.conf
        sdt.h sdt-config.h
        disable-clone3.diff)
md5sums=('SKIP'
         'SKIP'
         'b90d6a5a703228bfe5b7dc121a6c949c'
         '476e9113489f93b348b21e144b6a8fcf'
         '6e052f1cb693d5d3203f50f9d4e8c33b'
         '91fec3b7e75510ae2ac42533aa2e695e'
         '680df504c683640b02ed4a805797c0b2'
         '780020afbb6fc77fcd7e92aa45609602')

prepare() {
  bash pull-locale.sh
  mkdir -p glibc-build lib32-glibc-build
  cd glibc

  # Disable clone3 syscall for now
  # Can be removed when eletron{9,11,12} and discord are removed or patched:
  # https://github.com/electron/electron/commit/993ecb5bdd5c57024c8718ca6203a8f924d6d574
  # Patch src: https://patchwork.ozlabs.org/project/glibc/patch/87eebkf8ph.fsf@oldenburg.str.redhat.com/
  patch -Np1 -i "${srcdir}"/disable-clone3.diff
}

build() {

  configure_glibc_64() {
    "$srcdir/glibc/configure" \
          --host=x86_64-pc-linux-gnu \
          --prefix=/usr \
          --libdir=/usr/lib \
          --libexecdir=/usr/lib \
          --with-headers=/usr/include \
          --with-bugurl=https://bugs.archlinux.org/ \
          --enable-add-ons \
          --enable-bind-now \
          --enable-cet \
          --enable-kernel=5.10 \
          --enable-lock-elision \
          --enable-multi-arch \
          --enable-stack-protector=strong \
          --enable-stackguard-randomization \
          --disable-profile \
          --enable-static-pie \
          --enable-systemtap \
          --disable-crypt \
          --disable-werror
  }

  configure_glibc_32() {
    "$srcdir/glibc/configure" \
          --host=i686-pc-linux-gnu \
          --prefix=/usr \
          --libdir=/usr/lib32 \
          --libexecdir=/usr/lib32 \
          --with-headers=/usr/include \
          --with-bugurl=https://bugs.archlinux.org/ \
          --enable-add-ons \
          --enable-bind-now \
          --enable-cet \
          --enable-kernel=4.19 \
          --enable-lock-elision \
          --enable-multi-arch \
          --enable-stack-protector=strong \
          --enable-stackguard-randomization \
          --disable-profile \
          --enable-static-pie \
          --enable-systemtap \
          --disable-crypt \
          --disable-werror
  }

  unset_flags() {
    unset CFLAGS
    unset CXXFLAGS
  }

  configparms_fortify_source() {
    echo "CFLAGS += -Wp,-D_FORTIFY_SOURCE=2" >> configparms
  }

  configparms_enable_programs() {
    sed -i "/build-programs=/s#no#yes#" configparms
  }

  configparms_disable_programs() {
    echo "build-programs=no" >> configparms
  }

  make_build_64 () {
    make -O CFLAGS="$MAKE_FLAGS_64_FULL" CXXFLAGS="$MAKE_FLAGS_64_FULL" -j$(nproc --all)
  }

  make_build_32 () {
    make -O CFLAGS="$MAKE_FLAGS_32_FULL" CXXFLAGS="$MAKE_FLAGS_32_FULL" -j$(nproc --all)
  }

  MAKE_FLAGS_64="-O2 -pipe"
  MAKE_FLAGS_32="-mno-tls-direct-seg-refs -O2 -pipe"

  cd "$srcdir/glibc-build"
  echo "slibdir=/usr/lib" >> configparms
  echo "rtlddir=/usr/lib" >> configparms
  echo "sbindir=/usr/bin" >> configparms
  echo "rootsbindir=/usr/bin" >> configparms

  unset_flags
  configure_glibc_64
  # build libraries with fortify disabled
  configparms_disable_programs
  MAKE_FLAGS_64_FULL="$MAKE_FLAGS_64 -U_FORTIFY_SOURCE -ffunction-sections -fdata-sections"
  make_build_64

  # re-enable fortify for programs
  configparms_enable_programs
  unset_flags
  configure_glibc_64
  configparms_fortify_source
  MAKE_FLAGS_64_FULL="$MAKE_FLAGS_64 -Wp,-D_FORTIFY_SOURCE=2 -ffunction-sections -fdata-sections"
  make_build_64

  # build info pages manually for reprducibility
  make info -j$(nproc --all)

  cd "$srcdir/lib32-glibc-build"
  export CC="gcc -m32 -mstackrealign"
  export CXX="g++ -m32 -mstackrealign"

  echo "slibdir=/usr/lib32" >> configparms
  echo "rtlddir=/usr/lib32" >> configparms
  echo "sbindir=/usr/bin" >> configparms
  echo "rootsbindir=/usr/bin" >> configparms

  unset_flags
  configure_glibc_32
  # build libraries with fortify disabled
  configparms_disable_programs
  MAKE_FLAGS_32_FULL="$MAKE_FLAGS_32 -U_FORTIFY_SOURCE -ffunction-sections -fdata-sections"
  make_build_32

  # re-enable fortify for programs
  configparms_enable_programs
  unset_flags
  configure_glibc_32
  configparms_fortify_source
  MAKE_FLAGS_32_FULL="$MAKE_FLAGS_32 -Wp,-D_FORTIFY_SOURCE=2 -ffunction-sections -fdata-sections"
  make_build_32

}

skip_test() {
  test=$1
  file=$2
  sed -i "s/\b$test\b//" $srcdir/glibc/$file
}

check() {
  cd glibc-build

  # adjust/remove buildflags that cause false-positive testsuite failures
  sed -i '/FORTIFY/d' configparms                                     # failure to build testsuite
  sed -i 's/-Werror=format-security/-Wformat-security/' config.make   # failure to build testsuite
  sed -i '/CFLAGS/s/-fno-plt//' config.make                           # 16 failures
  sed -i '/CFLAGS/s/-fexceptions//' config.make                       # 1 failure
  LDFLAGS=${LDFLAGS/,-z,now/}                                         # 10 failures

  # The following tests fail due to restrictions in the Arch build system
  # The correct fix is to add the following to the systemd-nspawn call:
  # --capability=CAP_IPC_LOCK --system-call-filter="@clock @pkey"
  skip_test test-errno-linux sysdeps/unix/sysv/linux/Makefile
  skip_test tst-ntp_gettime  sysdeps/unix/sysv/linux/Makefile
  skip_test tst-ntp_gettimex sysdeps/unix/sysv/linux/Makefile
  skip_test tst-mlock2       sysdeps/unix/sysv/linux/Makefile
  skip_test tst-pkey         sysdeps/unix/sysv/linux/Makefile
  skip_test tst-adjtime      time/Makefile
  skip_test tst-clock2       time/Makefile

  make -O check
}
package_glibc-x86_64() {
  pkgdesc='GNU C Library'
  depends=('linux-api-headers>=5.10' tzdata filesystem)
  provides=("glibc=${pkgver}")
  conflicts=('glibc')
  optdepends=('gd: for memusagestat')
  install=glibc.install
  backup=(etc/gai.conf
          etc/locale.gen
          etc/nscd.conf)

  install -dm755 "$pkgdir/etc"
  touch "$pkgdir/etc/ld.so.conf"

  make -C glibc-build install_root="$pkgdir" install -j$(($(nproc --all) + 2))
  rm -f "$pkgdir"/etc/ld.so.{cache,conf}

  # Shipped in tzdata
  rm -f "$pkgdir"/usr/bin/{tzselect,zdump,zic}

  cd glibc

  install -dm755 "$pkgdir"/usr/lib/{locale,systemd/system,tmpfiles.d}
  install -m644 nscd/nscd.conf "$pkgdir/etc/nscd.conf"
  install -m644 nscd/nscd.service "$pkgdir/usr/lib/systemd/system"
  install -m644 nscd/nscd.tmpfiles "$pkgdir/usr/lib/tmpfiles.d/nscd.conf"
  install -dm755 "$pkgdir/var/db/nscd"

  install -m644 posix/gai.conf "$pkgdir"/etc/gai.conf

  install -m755 "$srcdir/locale-gen" "$pkgdir/usr/bin"

  # Create /etc/locale.gen
  install -m644 "$srcdir/locale.gen.txt" "$pkgdir/etc/locale.gen"
  sed -e '1,3d' -e 's|/| |g' -e 's|\\| |g' -e 's|^|#|g' \
    "$srcdir/glibc/localedata/SUPPORTED" >> "$pkgdir/etc/locale.gen"

  if check_option 'debug' n; then
    find "$pkgdir"/usr/bin -type f -executable -exec strip $STRIP_BINARIES {} + 2> /dev/null || true
    find "$pkgdir"/usr/lib -name '*.a' -type f -exec strip $STRIP_STATIC {} + 2> /dev/null || true

    # Do not strip these for gdb and valgrind functionality, but strip the rest
    find "$pkgdir"/usr/lib \
      -not -name 'ld-*.so' \
      -not -name 'libc-*.so' \
      -not -name 'libpthread-*.so' \
      -not -name 'libthread_db-*.so' \
      -name '*-*.so' -type f -exec strip $STRIP_SHARED {} + 2> /dev/null || true
  fi

  # Provide tracing probes to libstdc++ for exceptions, possibly for other
  # libraries too. Useful for gdb's catch command.
  install -Dm644 "$srcdir/sdt.h" "$pkgdir/usr/include/sys/sdt.h"
  install -Dm644 "$srcdir/sdt-config.h" "$pkgdir/usr/include/sys/sdt-config.h"

  # Provided by libxcrypt; keep the old shared library for backwards compatibility
  rm -f "$pkgdir"/usr/include/crypt.h "$pkgdir"/usr/lib/libcrypt.{a,so}
}

package_lib32-glibc-x86_64() {
  pkgdesc='GNU C Library (32-bit)'
  depends=("glibc=$pkgver")
  provides=("lib32-glibc=${pkgver}")
  conflicts=('lib32-glibc')
  options+=('!emptydirs')

  cd lib32-glibc-build

  make install_root="$pkgdir" install -j$(($(nproc --all) + 2))
  rm -rf "$pkgdir"/{etc,sbin,usr/{bin,sbin,share},var}

  # We need to keep 32 bit specific header files
  find "$pkgdir/usr/include" -type f -not -name '*-32.h' -delete

  # Dynamic linker
  install -d "$pkgdir/usr/lib"
  ln -s ../lib32/ld-linux.so.2 "$pkgdir/usr/lib/"

  # Add lib32 paths to the default library search path
  install -Dm644 "$srcdir/lib32-glibc.conf" "$pkgdir/etc/ld.so.conf.d/lib32-glibc.conf"

  # Symlink /usr/lib32/locale to /usr/lib/locale
  ln -s ../lib/locale "$pkgdir/usr/lib32/locale"

  if check_option 'debug' n; then
    find "$pkgdir"/usr/lib32 -name '*.a' -type f -exec strip $STRIP_STATIC {} + 2> /dev/null || true
    find "$pkgdir"/usr/lib32 \
      -not -name 'ld-*.so' \
      -not -name 'libc-*.so' \
      -not -name 'libpthread-*.so' \
      -not -name 'libthread_db-*.so' \
      -name '*-*.so' -type f -exec strip $STRIP_SHARED {} + 2> /dev/null || true
  fi

  # Provided by lib32-libxcrypt; keep the old shared library for backwards compatibility
  rm -f "$pkgdir"/usr/lib32/libcrypt.{a,so}
}
