
local buffer = require 'buffer'
local array = require 'array'

local A0 = array.array{10,10,10}
local A1 = array.array{10,10,10}

local V0 = A0:vector()
local V1 = A1:vector()

for i=0,#V1-1 do V1[i] = i end

local exten0 = array.vector(A0:extent(), 'int'):buffer()
local exten1 = array.vector(A1:extent(), 'int'):buffer()

local start0 = array.vector({0,0,0}, 'int'):buffer()
local start1 = array.vector({0,0,0}, 'int'):buffer()

local strid0 = array.vector({1,1,1}, 'int'):buffer()
local strid1 = array.vector({1,1,1}, 'int'):buffer()

local count0 = array.vector({10,10,10}, 'int'):buffer()
local count1 = array.vector({10,10,10}, 'int'):buffer()

print(V0)
buffer.copy(A0:buffer(), exten0, start0, strid0, count0,
	    A1:buffer(), exten1, start1, strid1, count1,
	    buffer.sizeof(buffer[A0:dtype()]))
print(V0)
