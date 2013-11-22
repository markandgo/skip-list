skip_list = require 'skip_list'

sl = skip_list:new()

-----------------------------
-- TEST INSERTION & ITERATE
-----------------------------

local list = {}
for i = 1,100 do
	local v = math.random(1,100)
	table.insert(list,v)
	sl:insert(v)
end

table.sort(list)

for i,k,v in sl:iterate() do
	if k ~= list[i] then
		error('Invalid key in skip list: '..k..' vs '..list[i])
	end
end

-----------------------------
-- TEST FIND
-----------------------------

for i = 1,100 do
	assert(sl:find(list[math.random(1,100)]))
end

-----------------------------
-- TEST POP
-----------------------------

for i = 1,10 do
	assert(sl:pop() == table.remove(list,1))
end

-----------------------------
-- TEST DELETE
-----------------------------

for i = 1,40 do
	local x = math.random(1,i)
	assert(sl:delete(list[x]) == table.remove(list,x),x)
end
	
-----------------------------
-- CHECK LIST AGAIN
-----------------------------
local j = 1

for i,k,v in sl:iterate() do
	assert(k == list[j])
	j = j + 1
end

-----------------------------
-- TEST KEY-VALUE PAIR
-----------------------------
sl:clear()

local pairs = {}
for i = 1,100 do
	pairs[i] = {key = i,value = math.random(1,100)}
	sl:insert(pairs[i].key,pairs[i].value)
end

for i,k,v in sl:iterate() do
	assert(k == pairs[i].key and v == pairs[i].value)
	assert(sl:find(k,v))
end

-----------------------------
-- TEST REVERSE ORDER
-----------------------------
sl = skip_list:new(nil,function(a,b) return a > b end)

local list = {}
for i = 1,100 do
	local v = math.random(1,100)
	table.insert(list,v)
	sl:insert(v)
end

table.sort(list,function(a,b) return a > b end)

for i,k,v in sl:iterate() do
	if k ~= list[i] then
		error('Invalid key in skip list: '..k..' vs '..list[i])
	end
end
