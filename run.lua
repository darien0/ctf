

local buffer = require 'buffer'
local MPI = require 'MPI'
local H5 = require 'HDF5'
local cow = require 'cow'

MPI.Init()

local crank = buffer.new_buffer(buffer.sizeof(buffer.int))

local domain = cow.domain_new()
local comm = MPI.Comm()

cow.domain_setndim(domain, 1)
cow.domain_setsize(domain, 0, 100)

cow.domain_commit(domain)

cow.domain_getcomm(domain, comm)
MPI.Comm_rank(comm, crank)

cow.domain_del(domain)

MPI.Finalize()
