

local class_meta = { }
local instance_meta = { }



local function isclass(c)
   return getmetatable(c) == class_meta
end
local function isinstance(instance, class)
   return instance.__class__ == class
end
local function super(instance, base)
   if not base then
      return instance.__base__[1]()
   else
      for i,v in ipairs(instance.__base__) do
	 if v == base then return v() end
      end
      error('does not inherit from requested base')
   end
end
local function classname(instance)
   return instance.__class__.__name__
end


function class_meta:__call(...)
   local dict = { }
   local base = { }
   for k,v in pairs(self.__dict__) do dict[k] = v end
   for k,v in pairs(self.__base__) do base[k] = v end
   local new = setmetatable({__name__=self.__name__,
			     __base__=self.__base__,
			     __dict__=dict,
			     __class__=self}, instance_meta)
   if new.__init__ then
      new:__init__(...)
   end
   return new
end
function class_meta:__index(key)
   for i,b in ipairs(self.__base__) do
      local val = b.__dict__[key]
      if val then return val end
   end
end
function class_meta:__newindex(key, value)
   self.__dict__[key] = value
end



function instance_meta:__index(key)
   if self.__dict__.__index__ then
      local val = self.__dict__:__index__(key)
      if val then return val end
   end
   local val = self.__dict__[key]
   if val then return val end
   return class_meta.__index(self, key)
end
function instance_meta:__newindex(key, value)
   if self.__dict__.__newindex__ then
      if self.__dict__:__newindex__(key, value) then return end
   end
   self.__dict__[key] = value
end
function instance_meta:__tostring()
   if self.__tostring__ then return self:__tostring__() end
   return '<Class>'
end



local function class(name, ...)
   return setmetatable({__name__=name,
			__base__={...},
			__dict__={ }}, class_meta)
end






local SoftObject = class('SoftObject')
function SoftObject:set_softness(val)
   self._softness = val
end
function SoftObject:get_softness(val)
   return self._softness
end
function SoftObject:jump()
   return 'cannot jump'
end

local Animal = class('Animal')
function Animal:speak()
   return 'unknown noise'
end
function Animal:eat()
   return 'unknown food'
end

Cat = class('Cat', Animal, SoftObject)
function Cat:__init__(softness)
   self._softness = softness
end
function Cat:__tostring__()
   return self:speak()
end
function Cat:__index__(key)
   if key == 'food' then
      return 'starving'
   end
end
function Cat:__newindex__(key, value)
   -- if false or nil is returned then default __newindex is carried out
end
function Cat:speak()
   return 'meow'
end
function Cat:jump()
   return 'can jump'
end
local blue = Cat(100)


blue.tree = 'blue tree'
assert(blue.food == 'starving')
assert(blue.tree == 'blue tree')
assert(blue:jump() == 'can jump')
assert(type(blue.get_softness) == 'function')
assert(blue:get_softness() == 100)
assert(blue:speak() == 'meow')
assert(blue:eat() == 'unknown food')
assert(super(blue).speak(blue) == 'unknown noise')
assert(super(blue, SoftObject).jump(blue) == 'cannot jump')
assert(tostring(blue) == 'meow')


assert(isclass(Animal))
assert(not isclass({}))
assert(isinstance(blue, Cat))
assert(not isclass(blue))