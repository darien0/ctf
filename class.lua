--------------------------------------------------------------------------------
--
--        Partial implementation of the Python class model for Lua
--
--                   Copyright (c) 2012, Jonathan Zrake
--
--------------------------------------------------------------------------------
--
-- Exports the following functions:
-- 
-- + class
-- + isclass
-- + isinstance
-- + classname
-- + super
-- 
-- and the following classes:
--
-- + object
--
-- Classes support multiple inheritance and casting via super to any base
-- class. The method resolution order is depth-first. All classes inherit from
-- object.
--------------------------------------------------------------------------------

local class_meta = { }
local instance_meta = { }
local class_module = { }

--------------------------------------------------------------------------------
-- Module functions
--------------------------------------------------------------------------------
local function isclass(c)
   return getmetatable(c) == class_meta
end
local function isinstance(instance, class)
   return instance.__class__ == class
end
local function classname(A)
   return isclass(A) and A.__name__ or A.__class__.__name__
end
local function super(instance, base)
   if not base then
      return instance.__class__.__base__[1]()
   else
      for i,v in ipairs(instance.__class__.__base__) do
         if v == base then
            local proxy = v()
            rawset(proxy, '__dict__', instance.__dict__)
            return proxy
         end
      end
   end
   -- returns nil if super call cannot be made
end
local function issubclass(instance, base)
   return super(instance, base) and true or false
end
local function rawresolve(key, ...)
   local table_list = {...}
   for i,t in pairs(table_list) do
      for j,b in ipairs(t) do
         local val = b.__dict__[key]
         if val then return val end
      end
   end
end
local function instresolve(self, key)
   return rawresolve(key, {self.__class__, self}, self.__class__.__base__)
end
local function class(name, ...)
   local base = {...}
   if #base == 0 and name ~= 'object' then
      base[1] = class_module.object
   end
   return setmetatable({__name__=name,
                        __base__=base,
                        __dict__={ }}, class_meta)
end

--------------------------------------------------------------------------------
-- Class metatable
--------------------------------------------------------------------------------
function class_meta:__call(...)
   local dict = { }
   local base = { }
   for k,v in pairs(self.__base__) do base[k] = v end
   local new = setmetatable({__name__=self.__name__,
                             __dict__=dict,
                             __class__=self}, instance_meta)
   if new.__init__ then
      new:__init__(...)
   end
   return new
end
function class_meta:__index(key)
   return rawresolve(key, {self}, self.__base__)
end
function class_meta:__newindex(key, value)
   self.__dict__[key] = value
end
function class_meta:__tostring(key, value)
   return string.format('<Class: %s[%s]>', classname(self),
                        string.sub(tostring(self.__dict__), 8))
end

--------------------------------------------------------------------------------
-- Instance metatable
--------------------------------------------------------------------------------
function instance_meta:__index(key)
   local index = instresolve(self, '__index__')
   local def = instresolve(self, key)
   if type(index) == 'function' then return index(self, key) or def
   else return index[key] or def
   end
end
function instance_meta:__newindex(key, value)
   local newindex = instresolve(self, '__newindex__')
   if self.__dict__[key] then
      self.__dict__[key] = value
   else
      newindex(self, key, value)
   end
end
function instance_meta:__tostring()
   return instresolve(self, '__tostring__')(self)
end

--------------------------------------------------------------------------------
-- object Class definition
--------------------------------------------------------------------------------
local object = class('object')
function object:__index__(key)
   return instresolve(self, key)
end
function object:__newindex__(key)
   self.__dict__[key] = value
end
function object:__tostring__()
   return string.format('<Class instance: %s[%s]>', classname(self),
                        string.sub(tostring(self.__dict__), 8))
end

--------------------------------------------------------------------------------
-- Class module definition
--------------------------------------------------------------------------------
class_module.object = object
class_module.class = class
class_module.isclass = isclass
class_module.isinstance = isinstance
class_module.classname = classname
class_module.super = super

--------------------------------------------------------------------------------
-- Unit test
--------------------------------------------------------------------------------
local function test()
   local SoftObject = class('SoftObject')
   function SoftObject:set_softness(val)
      self._softness = val
   end
   function SoftObject:get_softness(val)
      return self._softness
   end

   local Animal = class('Animal')
   function Animal:speak()
      return 'unknown noise'
   end
   function Animal:eat()
      return 'unknown food'
   end
   function Animal:jump()
      return 'cannot jump'
   end

   local Cat = class('Cat', Animal, SoftObject)
   function Cat:__init__(softness)
      self._softness = softness
   end
   function Cat:__tostring__()
      return '<:crazy cat:>'
   end
   function Cat:__index__(key)
      if key == 'food' then
         return 'starving'
      end
   end
   function Cat:__newindex__(key, value) -- boring over-ride
      self.__dict__[key] = value
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
   assert(super(blue):speak() == 'unknown noise')
   assert(super(blue, Animal):jump() == 'cannot jump')
   assert(tostring(blue) == '<:crazy cat:>')

   -- proxy class returned by super retains __dict__
   assert(super(blue, Animal).tree == 'blue tree')

   assert(isclass(Animal))
   assert(isinstance(blue, Cat))
   assert(issubclass(blue, Animal))
   assert(issubclass(blue, SoftObject))
   assert(not isclass({ }))
   assert(not isclass(blue))
   assert(not issubclass(blue, class('BogusBase')))
end

--------------------------------------------------------------------------------
-- Run test or export module
--------------------------------------------------------------------------------
if ... then -- if __name__ == "__main__"
   return class_module
else
   test()
   print(debug.getinfo(1).source, ": All tests passed")
end
