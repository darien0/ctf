
local buffer = require 'buffer'
local array = require 'array'

local A0 = array.array{10,10,10}
local A1 = array.array{10,10,10}

local V0 = A0:vector()
local V1 = A1:vector()

for i=0,#V1-1 do V1[i] = i end

A0[{{2,8},{2,8},{2,8}}] = A1[{{2,8},{2,8},{2,8}}]

for i=0,#V0-1 do print(V0[i]) end
