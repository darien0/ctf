
# ------------------------------------------------------------------------------
# lua-mpi build instructions
# ------------------------------------------------------------------------------
#
# 1. Create a file called Makefile.in which contains macros like these:
#
#    CC = mpicc
#    LUA_HOME = /path/to/lua-5.2.1
#
#    # Additional compile flags are optional:
#
#    CFLAGS = -Wall -O2
#    LVER = lua-5.2.1 # can be lua-5.1 or other
#
#
# 2. Optionally, you may install local Lua sources by typing `make lua`.
#
#
# 3. Run `make`.
#
# ------------------------------------------------------------------------------

MAKEFILE_IN = $(PWD)/Makefile.in
include $(MAKEFILE_IN)

CFLAGS ?= -Wall
CURL ?= curl
UNTAR ?= tar -xvf
CD ?= cd
RM ?= rm -f
OS ?= generic
LVER ?= lua-5.2.1

LUA_I ?= -I$(LUA_HOME)/include
LUA_L ?= -L$(LUA_HOME)/lib -llua
HDF_I ?= -I$(HDF_HOME)/include
HDF_L ?= -L$(HDF_HOME)/lib -lz -lhdf5
FFT_I ?= -I$(FFT_HOME)/include
FFT_L ?= -L$(FFT_HOME)/lib -lfftw3

LUA_COW    = cow/lua-cow.o
LUA_MPI    = lua-mpi/lua-mpi.o
LUA_HDF5   = lua-hdf5/lua-hdf5.o
LUA_BUFFER = lua-buffer/lua-buffer.o
LUA_GLUT   = lua-glut

default : main

lua : $(LVER)

$(LVER) :
	$(CURL) http://www.lua.org/ftp/$(LVER).tar.gz -o $(LVER).tar.gz
	$(UNTAR) $(LVER).tar.gz
	$(CD) $(LVER); $(MAKE) $(OS) CC=$(CC); \
		$(MAKE) install INSTALL_TOP=$(PWD)/$(LVER)
	$(RM) $(LVER).tar.gz


cow/libcow.a : .FORCE
	$(MAKE) -C cow libcow.a MAKEFILE_IN=$(MAKEFILE_IN)

cow/lua-cow.o : .FORCE
	$(MAKE) -C cow lua-cow.o MAKEFILE_IN=$(MAKEFILE_IN)

$(LUA_MPI) : .FORCE
	$(MAKE) -C lua-mpi lua-mpi.o MAKEFILE_IN=$(MAKEFILE_IN)

$(LUA_HDF5) : .FORCE
	$(MAKE) -C lua-hdf5 lua-hdf5.o MAKEFILE_IN=$(MAKEFILE_IN)

$(LUA_BUFFER) : .FORCE
	$(MAKE) -C lua-buffer lua-buffer.o MAKEFILE_IN=$(MAKEFILE_IN)

main.o : main.c
	$(CC) $(CFLAGS) -c -o $@ $< $(LUA_I) -DINSTALL_DIR=\"$(PWD)\"

main : main.o $(LUA_MPI) $(LUA_HDF5) $(LUA_BUFFER) $(LUA_COW) cow/libcow.a
	$(CC) $(CFLAGS) -o $@ $^ $(LUA_I) $(LUA_L) $(HDF_L) $(FFT_L)

$(LUA_GLUT) :
	$(MAKE) -C lua-glut DEFS=$(LUA_I)

clean :
	$(MAKE) -C cow clean MAKEFILE_IN=$(MAKEFILE_IN)
	$(MAKE) -C lua-buffer clean MAKEFILE_IN=$(MAKEFILE_IN)
	$(MAKE) -C lua-mpi clean MAKEFILE_IN=$(MAKEFILE_IN)
	$(MAKE) -C lua-hdf5 clean MAKEFILE_IN=$(MAKEFILE_IN)
	$(MAKE) -C lua-glut clean
	$(RM) *.o main

# Also remove local Lua sources
realclean : clean
	$(RM) -r $(LVER)

.PHONY : lua-glut

.FORCE : 
