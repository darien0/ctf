
local MPI    = require 'MPI'
local hdf5   = require 'LuaHDF5'
local buffer = require 'buffer'
local array  = require 'array'
local oo     = require 'class'
local cow    = require 'cow'

--------------------------------------------------------------------------------
-- Module-level variables defining the test
--------------------------------------------------------------------------------
local N = 16
local Nx = N*1
local Ny = N*2
local Nz = N*4
local Ng = 3 -- guard zones

local KB = 1024
local MB = 1024 * 1024
local stripe_size = 4 * MB
local dataset_names = {"dset1", "dset2", "dset3", "dset4", "dset5"}

function array.array(extent, dtype)
   local dtype = dtype or 'double'
   local N = 1
   for i,n in ipairs(extent) do N = N * n end
   local buf = buffer.new_buffer(N * buffer.sizeof(buffer[dtype]))
   return array.view(buf, dtype, extent)
end

local function comm_rank_size(comm)
   local crank = buffer.new_buffer(buffer.sizeof(buffer.int))
   local csize = buffer.new_buffer(buffer.sizeof(buffer.int))
   MPI.Comm_rank(comm, crank)
   MPI.Comm_size(comm, csize)
   local r = buffer.get_typed(crank, buffer.int, 0)
   local s = buffer.get_typed(csize, buffer.int, 0)
   return r, s
end


local TestCase = oo.class('TestCase')
function TestCase:__init__(opts)
   local domain = cow.domain_new()
   cow.domain_setndim(domain, 3)
   cow.domain_setsize(domain, 0, Nx)
   cow.domain_setsize(domain, 1, Ny)
   cow.domain_setsize(domain, 2, Nz)
   cow.domain_setguard(domain, Ng)
   cow.domain_commit(domain)

   local i0 = cow.domain_getglobalstartindex(domain, 0)
   local j0 = cow.domain_getglobalstartindex(domain, 1)
   local k0 = cow.domain_getglobalstartindex(domain, 2)
   local i1 = cow.domain_getnumlocalzonesinterior(domain, 0) + i0
   local j1 = cow.domain_getnumlocalzonesinterior(domain, 1) + j0
   local k1 = cow.domain_getnumlocalzonesinterior(domain, 2) + k0
   local Ni = i1 - i0
   local Nj = j1 - j0
   local Nk = k1 - k0
   local Nq = #dataset_names

   self.domain = domain
   self.filename = opts.filename
   self.array_shape = {Ni+2*Ng, Nj+2*Ng, Nk+2*Ng, #dataset_names}
   self.sgrid_shape = {Ni, Nj, Nk} -- subgrid shape
   self.sgrid_start = {i0, j0, k0}
   self.array = array.array(self.array_shape, 'double')

   local vec = self.array:vector()
   for i=Ng,Ni+Ng-1 do
      for j=Ng,Nj+Ng-1 do
	 for k=Ng,Nk+Ng-1 do
	    local x = cow.domain_positionatindex(domain, 0, i)
	    local y = cow.domain_positionatindex(domain, 1, j)
	    local z = cow.domain_positionatindex(domain, 2, k)
	    local xyz = {x,y,z}
	    for q=0,Nq-1 do
	       local m = i*(Nj+2*Ng)*(Nk+2*Ng) + j*(Nk+2*Ng) + k
	       vec[Nq*m + q] = xyz[q+1] or 0.0
	    end
	 end
      end
   end
   print("[ ] setting up grid: [" .. table.concat({Nx, Ny, Nz}, ', ') .. ']')

   -----------------------------------------------------------------------------
   -- Configuration options: try many to fine-tune performance
   -----------------------------------------------------------------------------
   self.file_opts = { }
   self.file_opts.mpi = {comm = MPI.COMM_WORLD,
			 info = MPI.INFO_NULL}
   self.file_opts.align = {threshold = 4 * KB,
			   alignment = stripe_size}
   self.file_opts.btree_ik = 32 -- default

   self.dset_opts = { }
   self.dset_opts.chunk = true
   self.dset_opts.mpio = 'COLLECTIVE'
end

function TestCase:close()
   cow.domain_del(self.domain)
   self.domain = nil
end

function TestCase:write()
   local file = hdf5.File(self.filename, 'w', self.file_opts)
   local group = hdf5.Group(file, "thegroup")
   local dset_opts = {shape={Nx, Ny, Nz}, dtype='double'}
   if self.dset_opts.chunk then
      dset_opts.chunk = self.sgrid_shape
   end

   local S = self.sgrid_shape
   local T = self.sgrid_start
   local Ni, Nj, Nk = S[1], S[2], S[3]
   local i0, j0, k0 = T[1], T[2], T[3]

   for i,name in ipairs(dataset_names) do
      print("[ ] writing " .. name .. ' ...')
      local dset = hdf5.DataSet(group, name, 'w', dset_opts)

      local mspace = hdf5.DataSpace(self.array_shape)
      local fspace = dset:get_space()

      local mstart = {Ng, Ng, Ng, i-1}
      local mstrid = {1, 1, 1, #dataset_names}
      local mcount = {Ni, Nj, Nk, 1}
      local mblock = {1, 1, 1, 1}
   
      local fstart = {i0, j0, k0}
      local fstrid = {1, 1, 1}
      local fcount = {Ni, Nj, Nk}
      local fblock = {1, 1, 1}

      mspace:select_hyperslab(mstart, mstrid, mcount, mblock)
      fspace:select_hyperslab(fstart, fstrid, fcount, fblock)

      dset:write(self.array:buffer(), mspace, fspace)
   end
   file:close()
end

local function main()
   if not arg[2] then
      print("please provide the name of the file to use as a test")
      return
   end
   MPI.Init()

   local test = TestCase{filename=arg[2]}
   test:write()
   test:close()

   MPI.Finalize()
end

main()
