# Builds and installs GCC (c, c++, ada for embedded PowerPC.
# Must remove '.' from path before starting.  Causes gcc to reference a local 'as', which is the wrong assembler.
GCC_VER:=4.5.3
BINUTILS_VER:=2.21
GMP_VER:=5.0.2
MPC_VER:=0.9
MPFR_VER:=3.0.1
NEWLIB_VER:=1.19.0

## posible entries: c,c++,ada,fortran
## NOTE: fortran not allowed (yet)
ENABLE_LANGUAGES:=c,c++


## NOTE: tried ftp mirror, but wget and ftp doesn't work well
## from inside corporate network
##################
#   ftp mirrors  #
##################
## mirror location: illinois usa
#MIRROR=ftp://mirror.team-cymru.org/gnu

##################
#  http mirrors  #
##################
## mirror location: bangladesh
#MIRROR=http://mirrors.ispros.com.db/gnu

## mirror location: illinois usa
#MIRROR=http://astromirror.uchicago.edu/gnu

## mirror location: illinois usa
MIRROR=http://mirror.team-cymru.org/gnu

## mirror location: pakistan
#MIRROR:=http://mirror-cybernet.lums.edu.pk/pub/gnu

## mirror location: taiwan
#MIRROR=http://ftp.twaren.net/unix/gnu/gnu

UNAME:=$(shell uname -a)
ifeq ($(findstring x86_64,$(UNAME)), x86_64)
CROSSTOOL_SUFFIX:=-x86_64
endif
PREFIX:=/tools/share/powerpc-eabi-$(GCC_VER)$(CROSSTOOL_SUFFIX)
TARGET:=powerpc-eabi
PATH:=$(PREFIX)/bin:$(PATH)

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
## NOTE: wget and ftp don't work well behind corporate proxy.
##       newlib is only available via ftp.  So... we must call
##       an old-school ftp script to get the tarball
NEWLIB_DIR:=newlib-$(NEWLIB_VER)
NEWLIB_TARBALL:=newlib-$(NEWLIB_VER).tar.gz

$(NEWLIB_TARBALL):
	./get_newlib $@

$(NEWLIB_DIR): $(NEWLIB_TARBALL)
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

## NOTE: 'tee'ing output cause 'make' to continue even if the 
##       command has failed.  In an effort to log the build, 
##       the user loses the ability to see all the text fly
##       by on the console screen.  Sorry.
binutils-configure.log: $(BINUTILS_DIR)
	cd $(BINUTILS_DIR) \
	&& ./configure --prefix=$(PREFIX) --target=$(TARGET) > ../binutils-configure.tmp.log 2>&1
	mv binutils-configure.tmp.log binutils-configure.log

binutils-make.log: binutils-configure.log
	$(MAKE) all -C $(BINUTILS_DIR) > binutils-make.tmp.log 2>&1
	mv binutils-make.tmp.log binutils-make.log

binutils-install.log: binutils-make.log
	$(INSTALLER) $(MAKE) install -C $(BINUTILS_DIR) > binutils-install.tmp.log 2>&1
	mv binutils-install.tmp.log binutils-install.log

gcc1-configure.log: $(GCC_DIR) $(GCC_CPLUSPLUS_DIR) $(GCC_ADA_DIR) \
                  $(GMP_DIR) $(MPFR_DIR) $(MPC_DIR) binutils-install.log
	mkdir -p build-gcc
	cd build-gcc \
	&& ../$(GCC_DIR)/configure $(GCC_CONFIG_OPTS) --without-headers > ../gcc1-configure.tmp.log 2>&1
	mv gcc1-configure.tmp.log gcc1-configure.log

gcc1-make.log: gcc1-configure.log
	$(MAKE) all-gcc -C build-gcc > gcc1-make.tmp.log 2>&1
	mv gcc1-make.tmp.log gcc1-make.log

gcc1-install.log: gcc1-make.log
	$(INSTALLER) $(MAKE) install-gcc -C build-gcc > gcc1-install.tmp.log 2>&1
	mv gcc1-install.tmp.log gcc1-install.log

newlib-configure.log: $(NEWLIB_DIR) gcc1-install.log
	mkdir -p build-newlib
	echo NOT_USED: patch newlib-$(NEWLIB_VER)/libgloss/rs6000/Makefile.in patches/newlib/libgloss/rs6000/Makefile.in.patch  # Apply patch to remove references to removed xil-exit.c file.
	cd build-newlib \
	&& ../newlib-$(NEWLIB_VER)/configure --prefix=$(PREFIX) --target=$(TARGET) --enable-languages=$(ENABLE_LANGUAGES) > ../newlib-configure.tmp.log 2>&1
	mv newlib-configure.tmp.log newlib-configure.log 

newlib-make.log: newlib-configure.log
	$(MAKE) all -C build-newlib > newlib-make.tmp.log 2>&1
	mv newlib-make.tmp.log newlib-make.log

newlib-install.log: newlib-make.log
	$(INSTALLER) $(MAKE) install -C build-newlib > newlib-install.tmp.log 2>&1
	mv newlib-install.tmp.log newlib-install.log

gcc2-configure.log: newlib-install.log
	cd build-gcc \
	&& ../$(GCC_DIR)/configure $(GCC_CONFIG_OPTS) > ../gcc2-configure.tmp.log 2>&1
	mv gcc2-configure.tmp.log gcc2-configure.log

gcc2-make.log: gcc2-configure.log
	$(MAKE) all -C build-gcc > gcc2-make.tmp.log 2>&1
	mv gcc2-make.tmp.log gcc2-make.log

gcc2-install.log: gcc2-make.log
	$(INSTALLER) $(MAKE) install -C build-gcc > gcc2-install.tmp.log 2>&1
	mv gcc2-install.tmp.log gcc2-install.log

.PHONY: clean
clean:
	-rm -rf $(BINUTILS_DIR)
	-rm -rf $(GCC_DIR)
	-rm -rf $(NEWLIB_DIR)
	-rm -rf build-gcc
	-rm -rf build-newlib
	-rm -rf *.log

.PHONY: clean-all
clean-all: clean
	-rm $(BINUTILS_TARBALL)
	-rm $(GCC_CORE_TARBALL)
	-rm $(GCC_CPLUSPLUS_TARBALL)
	-rm $(GCC_ADA_TARBALL)
	-rm $(GMP_TARBALL)
	-rm $(MPFR_TARBALL)
	-rm $(MPC_TARBALL)
	-rm $(NEWLIB_TARBALL)

