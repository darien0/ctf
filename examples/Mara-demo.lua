
local array   = require 'array'
local MPI     = require 'MPI'
local cow     = require 'cow'
local Mara    = require 'Mara'
local LuaMara = require 'LuaMara'

MPI.Init()
cow.init(0, nil, 0) -- to reopen stdout to dev/null

Mara.start()
Mara.set_fluid('euler')
Mara.set_advance('single')
Mara.set_godunov('plm-muscl')
Mara.set_boundary('periodic')
Mara.set_riemann('hllc')

-- Global zones
local prim_names = Mara.fluid.GetPrimNames()
local Nx = 16
local Ny = 16
local Nz = 64
local Ng = 3
local Nq = #prim_names

local domain = cow.domain_new()
local domain_comm = MPI.Comm()
cow.domain_setndim(domain, 3)
cow.domain_setsize(domain, 0, Nx)
cow.domain_setsize(domain, 1, Ny)
cow.domain_setsize(domain, 2, Nz)
cow.domain_setguard(domain, Ng)
cow.domain_commit(domain)
cow.domain_getcomm(domain, domain_comm)

-- Local zones, without guard
local nx = cow.domain_getnumlocalzonesincguard(domain, 0)
local ny = cow.domain_getnumlocalzonesincguard(domain, 1)
local nz = cow.domain_getnumlocalzonesincguard(domain, 2)

local function pinit(x,y,z)
   return {1,1,0,0,0}
end

local data_man = LuaMara.MaraDataManager(domain, prim_names)
local P = data_man.array
Mara.set_domain({0,0,0}, {1,1,1}, {Nx, Ny, Nz}, Nq, Ng, domain_comm)
Mara.init_prim(P:buffer(), pinit)
Mara.units.Print()
data_man:write('chkpt.0001.h5', {file_mode='r+', dset_mode='w'})

local time, error = Mara.advance(P:buffer(), 0.1)

cow.domain_del(domain)
Mara.close()
MPI.Finalize()
