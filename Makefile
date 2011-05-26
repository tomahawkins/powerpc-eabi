# Builds and installs GCC (c, c++, ada) for embedded PowerPC.
# Must remove '.' from path before starting.  Causes gcc to reference a local 'as', which is the wrong assembler.
# Requires same GGC version as build machine.

PREFIX:=/tools/share/powerpc-eabi-amd64host
TARGET:=powerpc-eabi

GCC_VER:=4.5.3
BINUTILS_VER:=2.21
GMP_VER:=5.0.2
MPC_VER:=0.9
MPFR_VER:=3.0.1
NEWLIB_VER:=1.19.0

## posible entries: c,c++,ada,fortran
## NOTE: fortran not allowed (yet)
ENABLE_LANGUAGES:=c,c++

#MIRROR=http://astromirror.uchicago.edu/gnu

## also located in illinois, but with more recent gcc versions
MIRROR=ftp://mirror.team-cymru.org/gnu

INSTALLER=
#INSTALLER=sudo

## turn off old-fashioned implicit rules
.SUFFIXES:

GCC_DIR:=gcc-$(GCC_VER)

.PHONY: all
all: gcc2-install.log

##############
#  binutils  #
##############
BINUTILS_DIR:=binutils-$(BINUTILS_VER)
BINUTILS_TARBALL:=binutils-$(BINUTILS_VER).tar.gz

$(BINUTILS_TARBALL):
	wget $(MIRROR)/binutils/$@

$(BINUTILS_DIR): $(BINUTILS_TARBALL)
	tar -xzmf $(BINUTILS_TARBALL)

#########
#  gmp  #
#########
GMP_DIR:=$(GCC_DIR)/gmp
GMP_TARBALL:=gmp-$(GMP_VER).tar.gz

$(GMP_TARBALL):
	wget $(MIRROR)/gmp/$@

$(GMP_DIR): $(GMP_TARBALL)
	tar -xzmf $(GMP_TARBALL)
	mv gmp-$(GMP_VER) $(GMP_DIR)
	
##########
#  mpfr  #
##########
MPFR_DIR:=$(GCC_DIR)/mpfr
MPFR_TARBALL:=mpfr-$(MPFR_VER).tar.gz

$(MPFR_TARBALL):
	wget $(MIRROR)/mpfr/$@

$(MPFR_DIR): $(MPFR_TARBALL)
	tar -xzmf $(MPFR_TARBALL)
	mv mpfr-$(MPFR_VER) $(MPFR_DIR)

#########
#  mpc  #
#########
MPC_DIR:=$(GCC_DIR)/mpc
MPC_TARBALL:=mpc-$(MPC_VER).tar.gz

$(MPC_TARBALL):
	wget http://www.multiprecision.org/mpc/download/$@

$(MPC_DIR): $(MPC_TARBALL)
	tar -xzmf $(MPC_TARBALL)
	mv mpc-$(MPC_VER) $(MPC_DIR)
	
############
#  newlib  #
############
NEWLIB_DIR:=newlib-$(NEWLIB_VER)
NEWLIB_TARBALL:=newlib-$(NEWLIB_VER).tar.gz

$(NEWLIB_TARBALL):
	wget ftp://sources.redhat.com/pub/newlib/$@

$(NEWLIB_DIR): $(NEWLIB_TARBALL)
	echo $(NEWLIB_DIR)
	tar -xzmf $(NEWLIB_TARBALL)

#######
#  c  #
#######
GCC_CORE_TARBALL:=gcc-core-$(GCC_VER).tar.gz

$(GCC_CORE_TARBALL):
	wget $(MIRROR)/gcc/$(GCC_DIR)/$@

$(GCC_DIR): $(GCC_CORE_TARBALL)
	tar -xzmf $(GCC_CORE_TARBALL)

#########
#  c++  #
#########
GCC_CPLUSPLUS_TARBALL:=gcc-g++-$(GCC_VER).tar.gz
ifeq ($(findstring c++, $(ENABLE_LANGUAGES)), c++)
GCC_CPLUSPLUS_DIR:=$(GCC_DIR)/gcc/cp

$(GCC_CPLUSPLUS_TARBALL):
	wget $(MIRROR)/gcc/$(GCC_DIR)/$@

$(GCC_CPLUSPLUS_DIR): $(GCC_DIR) $(GCC_CPLUSPLUS_TARBALL)
	tar -xzmf $(GCC_CPLUSPLUS_TARBALL)

endif
#########
#  ada  #
#########
GCC_ADA_TARBALL:=gcc-ada-$(GCC_VER).tar.gz
ifeq ($(findstring ada, $(ENABLE_LANGUAGES)), ada)
GCC_ADA_DIR:=$(GCC_DIR)/gcc/ada

define prepare_ada
patch $(GCC_ADA_DIR)/adaint.h                    patches/gcc/gcc/ada/adaint.h.patch                   # Remove reference to <derint.h>.
patch $(GCC_ADA_DIR)/adaint.c                    patches/gcc/gcc/ada/adaint.c.patch                   # Remove reference to <derint.h>.  Remove functions that use DIR.
patch $(GCC_ADA_DIR)/gsocket.h                   patches/gcc/gcc/ada/gsocket.h.patch                  # Undefine sockets.
patch $(GCC_ADA_DIR)/s-oscons-tmplt.c            patches/gcc/gcc/ada/s-oscons-tmplt.c.patch           # Remove reference to <termios.h>.
patch $(GCC_ADA_DIR)/gcc-interface/Makefile.in   patches/gcc/gcc/ada/gcc-interface/Makefile.in.patch  # Disable sockets.
endef

$(GCC_ADA_TARBALL):
	wget $(MIRROR)/gcc/$(GCC_DIR)/$@

$(GCC_ADA_DIR): $(GCC_CORE_DIR) $(GCC_ADA_TARBALL)
	tar -xzmf $(GCC_ADA_TARBALL)
	$(prepare_ada)

endif

GCC_CONFIG_OPTS:= \
    --prefix=$(PREFIX) \
    --target=$(TARGET) \
    --enable-languages=$(ENABLE_LANGUAGES) \
    --with-newlib \
    --disable-nls \
    --disable-shared \
    --disable-libssp

binutils-configure.log: $(BINUTILS_DIR)
	cd $(BINUTILS_DIR) && ./configure --prefix=$(PREFIX) --target=$(TARGET) 2>&1 | tee ../binutils-configure.log.tmp \
	&& mv ../binutils-configure.log.tmp ../binutils-configure.log

binutils-make.log: binutils-configure.log
	cd $(BINUTILS_DIR) && make all 2>&1 | tee ../binutils-make.log.tmp \
	&& mv ../binutils-make.log.tmp ../binutils-make.log

binutils-install.log: binutils-make.log
	cd $(BINUTILS_DIR) && $(INSTALLER) make install 2>&1 | tee ../binutils-install.log.tmp \
	&& mv ../binutils-install.log.tmp ../binutils-install.log

gcc1-configure.log: $(GCC_DIR) $(GCC_CPLUSPLUS_DIR) $(GCC_ADA_DIR) \
                  $(GMP_DIR) $(MPFR_DIR) $(MPC_DIR) binutils-install.log
	mkdir -p build-gcc
	cd build-gcc && ../$(GCC_DIR)/configure $(GCC_CONFIG_OPTS) --without-headers 2>&1 | tee ../gcc1-configure.log.tmp \
	&& mv ../gcc1-configure.log.tmp ../gcc1-configure.log

gcc1-make.log: gcc1-configure.log
	cd build-gcc && make all-gcc 2>&1 | tee ../gcc1-make.log.tmp \
	&& mv ../gcc1-make.log.tmp ../gcc1-make.log

gcc1-install.log: gcc1-make.log
	cd build-gcc && $(INSTALLER) make install-gcc 2>&1 | tee ../gcc1-install1.log.tmp \
	&& mv ../gcc1-install1.log.tmp ../gcc1-install1.log

newlib-configure.log: $(NEWLIB_DIR) gcc1-install.log
	mkdir -p build-newlib
	echo NOT_USED: patch newlib-$(NEWLIB_VER)/libgloss/rs6000/Makefile.in patches/newlib/libgloss/rs6000/Makefile.in.patch  # Apply patch to remove references to removed xil-exit.c file.
	export PATH=$(PREFIX)/bin:$(PATH) && cd build-newlib && ../newlib-$(NEWLIB_VER)/configure --prefix=$(PREFIX) --target=$(TARGET) --enable-languages=c,c++,ada 2>&1 | tee ../newlib-configure.log.tmp \
	&& mv ../newlib-configure.log.tmp ../newlib-configure.log

newlib-make.log: newlib-configure.log
	export PATH=$(PREFIX)/bin:$(PATH) && cd build-newlib && make all 2>&1 | tee ../newlib-make.log.tmp \
	&& mv ../newlib-make.log.tmp ../newlib-make.log

newlib-install.log: newlib-make.log
	export PATH=$(PREFIX)/bin:$(PATH) && cd build-newlib && $(INSTALLER) make install 2>&1 | tee ../newlib-install.log.tmp \
	&& mv ../newlib-install.log.tmp ../newlib-install.log

gcc2-configure.log: newlib-install.log
	cd build-gcc && ../$(GCC_DIR)/configure $(GCC_CONFIG_OPTS) 2>&1 | tee ../gcc2-configure.log.tmp \
	&& mv ../gcc2-configure.log.tmp ../gcc2-configure.log

gcc2-make.log: gcc2-configure.log
	cd build-gcc && make all 2>&1 | tee ../gcc2-make.log.tmp \
	&& mv ../gcc2-make.log.tmp ../gcc2-make.log

gcc2-install.log: gcc2-make.log
	cd build-gcc && make $(INSTALLER) install 2>&1 | tee ../gcc2-install.log.tmp \
	&& mv ../gcc2-install.log.tmp ../gcc2-install.log

.PHONY: clean
clean:
	-rm -rf $(BINUTILS_DIR)
	-rm -rf $(GCC_DIR)
	-rm -rf $(NEWLIB_DIR)
	-rm -rf build-gcc
	-rm -rf build-newlib
	-rm -rf *.log
	-rm -rf *.log.tmp

.PHONY: clean-all
clean-all: clean
	-rm $(BINUTILS_TARBALL)
	-rm $(GCC_CORE_TARBALL)
	-rm $(GCC_CPLUSPLUS_TARBALL)
	-rm $(GCC_ADA_TARBALL)
	-rm $(GMP_TARBALL)
	-rm $(MPFR_TABALL)
	-rm $(MPC_TARBALL)
	-rm $(NEWLIB_TARBALL)

