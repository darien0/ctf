
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
local Nx = 32
local Ny = 32
local Ng = 3
local Nq = #prim_names

local domain = cow.domain_new()
local domain_comm = MPI.Comm()
cow.domain_setndim(domain, 2)
cow.domain_setsize(domain, 0, Nx)
cow.domain_setsize(domain, 1, Ny)
cow.domain_setguard(domain, Ng)
cow.domain_commit(domain)
cow.domain_getcomm(domain, domain_comm)

local function pinit(x,y,z)
   return {1,1,0,0,0}
end

local data_man = LuaMara.MaraDataManager(domain, prim_names)
local P = data_man.array
Mara.set_domain({0,0}, {1,1}, {Nx, Ny}, Nq, Ng, domain_comm)
Mara.init_prim(P:buffer(), pinit)
Mara.units.Print()
data_man:write('chkpt.0001.h5', {file_mode='w', dset_mode='w'})

local time, error = Mara.advance(P:buffer(), 0.1)

cow.domain_del(domain)
Mara.close()
MPI.Finalize()
