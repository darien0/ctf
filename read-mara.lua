

local buffer = require 'buffer'
local MPI = require 'MPI'
local hdf5 = require 'LuaHDF5'
local cow = require 'cow'
local array = require 'array'

function array.array(extent, dtype)
   local dtype = dtype or 'double'
   local N = 1
   for i,n in ipairs(extent) do N = N * n end
   local buf = buffer.new_buffer(N * buffer.sizeof(buffer[dtype]))
   return array.view(buf, dtype, extent)
end

if not arg[2] then
   print("please provide a Mara HDF5 file to open")
end

MPI.Init()

local crank = buffer.new_buffer(buffer.sizeof(buffer.int))
local csize = buffer.new_buffer(buffer.sizeof(buffer.int))

MPI.Comm_rank(MPI.COMM_WORLD, crank)
MPI.Comm_size(MPI.COMM_WORLD, csize)

local rank = buffer.get_typed(crank, buffer.int, 0)
local size = buffer.get_typed(csize, buffer.int, 0)
local ng = 2
local h5mpi = {comm = MPI.COMM_WORLD,
	       info = MPI.INFO_NULL}

local h5file = hdf5.File(arg[2], "r", {mpi=h5mpi})

local prim = h5file["prim"]
local members = prim:keys()
local domain_size = prim[members[1]]:get_space():get_extent()
h5file:close()

h5mpi.comm = MPI.Comm()
local domain = cow.domain_new()

cow.domain_setndim(domain, #domain_size)
for i,s in ipairs(domain_size) do
   cow.domain_setsize(domain, i-1, s)
end
cow.domain_setguard(domain, ng)
cow.domain_commit(domain)
cow.domain_getcomm(domain, h5mpi.comm)

local dfield = cow.dfield_new()
for _,member in pairs(members) do
   cow.dfield_addmember(dfield, member)
end
cow.dfield_setdomain(dfield, domain)
cow.dfield_commit(dfield)

local i0 = cow.domain_getglobalstartindex(domain, 0)
local j0 = cow.domain_getglobalstartindex(domain, 1)
local k0 = cow.domain_getglobalstartindex(domain, 2)
local i1 = cow.domain_getnumlocalzonesinterior(domain, 0) + i0
local j1 = cow.domain_getnumlocalzonesinterior(domain, 1) + j0
local k1 = cow.domain_getnumlocalzonesinterior(domain, 2) + k0
local Ni = i1 - i0
local Nj = j1 - j0
local Nk = k1 - k0

local shape = {Ni+2*ng, Nj+2*ng, Nk+2*ng, #members}
local dfield_array = array.array(shape)

cow.dfield_setdatabuffer(dfield, dfield_array:buffer())


local h5file = hdf5.File(arg[2], "r", {mpi=mpi})
local prim = h5file["prim"]

print("memory usage: "..collectgarbage("count")/1024 .." MB")
print("array size: "..array.sizeof('double')*#dfield_array/(1024*1024).." MB")

for i,member in ipairs(members) do
   local mspace = hdf5.DataSpace(shape)
   local fspace = prim[member]:get_space()

   local mstart = {ng, ng, ng, i-1}
   local mstrid = {1, 1, 1, #members}
   local mcount = {Ni, Nj, Nk, 1}
   local mblock = {1, 1, 1, 1}
   
   local fstart = {i0, j0, k0}
   local fstrid = {1, 1, 1}
   local fcount = {Ni, Nj, Nk}
   local fblock = {1, 1, 1}

   mspace:select_hyperslab(mstart, mstrid, mcount, mblock)
   fspace:select_hyperslab(fstart, fstrid, fcount, fblock)

   prim[member]:read(dfield_array:buffer(), mspace, fspace)
   print("reading", member)
end

prim:close()
h5file:close()

cow.dfield_syncguard(dfield)
cow.dfield_del(dfield)
cow.domain_del(domain)

MPI.Finalize()
