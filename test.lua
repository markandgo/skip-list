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

local i = 0
for k,v in sl:iterate() do
	i = i + 1
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

local i = 0
for k,v in sl:iterate() do
	i = i + 1
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

local i = 0
for k,v in sl:iterate() do
	i = i + 1
	assert(k == pairs[i].key and v == pairs[i].value)
	assert(sl:find(k,v))
end

-- Test delete 
for i = 1,100 do
	local k,v = sl:delete(pairs[1].key,pairs[1].value)
	local t   = table.remove(pairs,1)
	assert(t.key == k and t.value == v)
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

local i = sl:length()
for k,v in sl:iterate('reverse') do
	if k ~= list[i] then
		error('Invalid key in skip list: '..k..' vs '..list[i])
	end
	i = i - 1
end
