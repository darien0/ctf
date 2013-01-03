
-- http://www.hdfgroup.org/HDF5/doc/RM/CollectiveCalls.html

local MPI = require 'MPI'
local hdf5 = require 'LuaHdf5'
local array = require 'array'


MPI.Init()

local nper = 10
local csize = array.vector(1, 'int')
local crank = array.vector(1, 'int')

MPI.Comm_size(MPI.COMM_WORLD, csize:buffer())
MPI.Comm_rank(MPI.COMM_WORLD, crank:buffer())

local mpi = {comm=MPI.COMM_WORLD,
	     info=MPI.INFO_NULL}
local size = csize[0]
local rank = crank[0]

local data = array.vector(nper, 'double')

local file = hdf5.File('outfile.h5', 'w', mpi)
local grp = hdf5.Group(file, 'thegroup')
local dset = hdf5.DataSet(grp, 'thedata', 'w',
			  {shape={nper * size}, chunk={nper}, dtype='double'})
dset:set_mpio('COLLECTIVE')

for i=0,#data-1 do data[i] = rank * nper + i end
dset[{{rank * nper, (rank + 1) * nper}}] = data:view{nper}
for k,v in pairs(dset:get_mpio()) do
   print(string.format("%30s: %-30s", k,v))
end
file:close()

local file = hdf5.File('outfile.h5', 'r', mpi)
--print(unpack(file["thegroup"]["thedata"]:get_chunk()))
file:close()

MPI.Finalize()
