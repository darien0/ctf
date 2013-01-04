
local buffer = require 'buffer'
local MPI = require 'MPI'
local H5 = require 'HDF5'
local cow = require 'cow'

MPI.Init()

local domain = cow.domain_new()

cow.domain_setndim(domain, 1)
cow.domain_setsize(domain, 0, 100)

cow.domain_commit(domain)
cow.domain_del(domain)

MPI.Finalize()
