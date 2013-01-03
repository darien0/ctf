
-- http://www.hdfgroup.org/HDF5/doc/RM/CollectiveCalls.html

local MPI = require 'MPI'
local H5 = require 'HDF5'
local hdf5 = require 'LuaHDF5'
local array = require 'array'


MPI.Init()

local nper = 10
local csize = array.vector(1, 'int')
local crank = array.vector(1, 'int')

MPI.Comm_size(MPI.COMM_WORLD, csize:buffer())
MPI.Comm_rank(MPI.COMM_WORLD, crank:buffer())

local KB = 1024
local MB = 1024 * 1024
local stripe_size = 4 * MB

local mpi = {comm = MPI.COMM_WORLD,
	     info = MPI.INFO_NULL}
local align = {threshold = 4 * KB,
	       alignment = stripe_size}
local btree_ik = 32 -- default


local size = csize[0]
local rank = crank[0]

local data = array.vector(nper, 'double')

local file = hdf5.File('data/outfile.h5', 'w',
		       {mpi=mpi, align=align, btree_ik=btree_ik})
local grp = hdf5.Group(file, 'thegroup')
local dset = hdf5.DataSet(grp, 'thedata', 'w',
			  {shape={nper * size}, chunk={nper}, dtype='double'})
dset:set_mpio('COLLECTIVE')

for i=0,#data-1 do data[i] = rank * nper + i end
dset[{{rank * nper, (rank + 1) * nper}}] = data:view{nper}
if rank == 0 then
   print(H5.H5_VERS_INFO())
   print('version >= 1.8.3 ?', H5.H5_VERSION_GE(1,8,3))
   for k,v in pairs(dset:get_mpio()) do
      print(string.format("%30s: %-30s", k,v))
   end
end
file:close()

local file = hdf5.File('data/outfile.h5', 'r', mpi)
--print(unpack(file["thegroup"]["thedata"]:get_chunk()))
file:close()

MPI.Finalize()
