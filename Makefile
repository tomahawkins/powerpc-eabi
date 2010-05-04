# Builds and installs GCC (c, c++, ada) for embedded PowerPC.
# Must remove '.' from path before starting.  Causes gcc to reference a local 'as', which is the wrong assembler.
# Requires same GGC version as build machine.

PREFIX=/usr/local
HOST=i686-pc-linux-gnu
TARGET=powerpc-eabi

GCC=4.4.3
BINUTILS=2.20
GMP=5.0.1
MPC=0.8.1
MPFR=2.4.2
NEWLIB=1.18.0

MIRROR=http://astromirror.uchicago.edu/gnu

#INSTALLER =
INSTALLER = sudo

TARBALLS = \
  binutils-$(BINUTILS).tar.gz \
  gcc-core-$(GCC).tar.gz \
  gcc-ada-$(GCC).tar.gz \
  gcc-g++-$(GCC).tar.gz \
  gmp-$(GMP).tar.gz \
  mpfr-$(MPFR).tar.gz \
  mpc-$(MPC).tar.gz \
  newlib-$(NEWLIB).tar.gz

.PHONY: all
all: build-binutils build-gcc1 build-newlib build-gcc2

binutils-$(BINUTILS).tar.gz:
	wget $(MIRROR)/binutils/binutils-$(BINUTILS).tar.gz

gcc-core-$(GCC).tar.gz:
	wget $(MIRROR)/gcc/gcc-$(GCC)/gcc-core-$(GCC).tar.gz

gcc-ada-$(GCC).tar.gz:
	wget $(MIRROR)/gcc/gcc-$(GCC)/gcc-ada-$(GCC).tar.gz

gcc-g++-$(GCC).tar.gz:
	wget $(MIRROR)/gcc/gcc-$(GCC)/gcc-g++-$(GCC).tar.gz

gmp-$(GMP).tar.gz:
	wget $(MIRROR)/gmp/gmp-$(GMP).tar.gz

mpfr-$(MPFR).tar.gz:
	wget $(MIRROR)/mpfr/mpfr-$(MPFR).tar.gz

mpc-$(MPC).tar.gz:
	wget http://www.multiprecision.org/mpc/download/mpc-$(MPC).tar.gz

newlib-$(NEWLIB).tar.gz:
	wget ftp://sources.redhat.com/pub/newlib/newlib-$(NEWLIB).tar.gz

.PHONY: build-binutils
build-binutils: binutils-$(BINUTILS).tar.gz
	tar xzf binutils-$(BINUTILS).tar.gz
	cd binutils-$(BINUTILS) && ./configure --prefix=$(PREFIX) --target=$(TARGET) 2>&1 | tee ../binutils-configure.log
	cd binutils-$(BINUTILS) && make all 2>&1 | tee ../binutils-make.log
	cd binutils-$(BINUTILS) && $(INSTALLER) make install 2>&1 | tee ../binutils-install.log

.PHONY: build-gcc1
build-gcc1: gcc-core-$(GCC).tar.gz gcc-ada-$(GCC).tar.gz gcc-g++-$(GCC).tar.gz gmp-$(GMP).tar.gz mpfr-$(MPFR).tar.gz mpc-$(MPC).tar.gz
	tar xzf gcc-core-$(GCC).tar.gz
	tar xzf gcc-ada-$(GCC).tar.gz
	tar xzf gcc-g++-$(GCC).tar.gz
	tar xzf gmp-$(GMP).tar.gz
	tar xzf mpfr-$(MPFR).tar.gz
	tar xzf mpc-$(MPC).tar.gz
	mv gmp-$(GMP) gcc-$(GCC)/gmp
	mv mpc-$(MPC) gcc-$(GCC)/mpc
	mv mpfr-$(MPFR) gcc-$(GCC)/mpfr
	patch gcc-$(GCC)/gcc/ada/adaint.h                    patches/gcc/gcc/ada/adaint.h.patch                   # Remove reference to <derint.h>.
	patch gcc-$(GCC)/gcc/ada/adaint.c                    patches/gcc/gcc/ada/adaint.c.patch                   # Remove reference to <derint.h>.  Remove functions that use DIR.
	patch gcc-$(GCC)/gcc/ada/gsocket.h                   patches/gcc/gcc/ada/gsocket.h.patch                  # Undefine sockets.
	patch gcc-$(GCC)/gcc/ada/s-oscons-tmplt.c            patches/gcc/gcc/ada/s-oscons-tmplt.c.patch           # Remove reference to <termios.h>.
	patch gcc-$(GCC)/gcc/ada/gcc-interface/Makefile.in   patches/gcc/gcc/ada/gcc-interface/Makefile.in.patch  # Disable sockets.
	mkdir -p build-gcc
	cd build-gcc && ../gcc-$(GCC)/configure --prefix=$(PREFIX) --host=$(HOST) --target=$(TARGET) --enable-languages=c,c++,ada --with-newlib --without-headers 2>&1 | tee ../gcc1-configure.log
	cd build-gcc && make all-gcc 2>&1 | tee ../gcc1-make.log
	cd build-gcc && $(INSTALLER) make install-gcc 2>&1 | tee ../gcc1-install1.log

.PHONY: build-newlib
build-newlib: newlib-$(NEWLIB).tar.gz
	tar xzf newlib-$(NEWLIB).tar.gz
	mkdir -p build-newlib
	patch newlib-$(NEWLIB)/libgloss/rs6000/Makefile.in patches/newlib/libgloss/rs6000/Makefile.in.patch  # Apply patch to remove references to removed xil-exit.c file.
	export PATH=$(PREFIX)/bin:$(PATH) && cd build-newlib && ../newlib-$(NEWLIB)/configure --prefix=$(PREFIX) --host=$(HOST) --target=$(TARGET) --enable-languages=c,c++,ada 2>&1 | tee ../newlib-configure.log
	export PATH=$(PREFIX)/bin:$(PATH) && cd build-newlib && make all 2>&1 | tee ../newlib-make.log
	export PATH=$(PREFIX)/bin:$(PATH) && cd build-newlib && $(INSTALLER) make install 2>&1 | tee ../newlib-install.log

.PHONY: build-gcc2
build-gcc2:
	cd build-gcc && ../gcc-$(GCC)/configure --prefix=$(PREFIX) --host=$(HOST) --target=$(TARGET) --enable-languages=c,c++,ada --with-newlib --disable-shared --disable-libssp 2>&1 | tee ../gcc2-configure.log
	cd build-gcc && make all 2>&1 | tee ../gcc2-make.log
	cd build-gcc && make $(INSTALLER) install 2>&1 | tee ../gcc2-install.log

.PHONY: clean
clean:
	-rm -rf binutils-$(BINUTILS)
	-rm -rf gcc-$(GCC)
	-rm -rf gmp-$(GMP)
	-rm -rf mpfr-$(MPFR)
	-rm -rf mpc-$(MPC)
	-rm -rf newlib-$(NEWLIB)
	-rm -rf build-gcc
	-rm -rf build-newlib
	-rm -rf *.log

.PHONY: clean-all
clean-all: clean
	-rm binutils-$(BINUTILS).tar.gz
	-rm gcc-core-$(GCC).tar.gz
	-rm gcc-ada-$(GCC).tar.gz
	-rm gcc-g++-$(GCC).tar.gz
	-rm gmp-$(GMP).tar.gz
	-rm mpfr-$(MPFR).tar.gz
	-rm mpc-$(MPC).tar.gz
	-rm newlib-$(NEWLIB).tar.gz

