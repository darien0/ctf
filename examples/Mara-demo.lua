
local array  = require 'array'
local cow    = require 'cow'
local Mara   = require 'Mara'
local MPI    = require 'MPI'

MPI.Init()
cow.init(0, nil, 0) -- to reopen stdout to dev/null

-- Global zones
local Nx = 16
local Ny = 16
local Nz = 16
local Ng = 3
local Nq = 5

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
local P = array.array{nx,ny,nz,Nq}

Mara.start()
Mara.set_domain({0,0,0}, {1,1,1}, {Nx, Ny, Nz}, Nq, Ng, domain_comm)
Mara.init_prim(P:buffer(), pinit)
Mara.set_fluid('euler')
Mara.set_advance('single')
Mara.set_godunov('plm-muscl')
Mara.set_boundary('periodic')
Mara.set_riemann('hllc')

Mara.units.Print()

local time, error = Mara.advance(P:buffer(), 0.1)

cow.domain_del(domain)
Mara.close()
MPI.Finalize()
