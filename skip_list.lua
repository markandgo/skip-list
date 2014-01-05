--[[
    Copyright (C) 2013 Minh Ngo

    Permission is hereby granted, free of charge, to any person 
obtaining a copy of this software and associated documentation 
files (the "Software"), to deal in the Software without 
restriction, including without limitation the rights to use, 
copy, modify, merge, publish, distribute, sublicense, and/or 
sell copies of the Software, and to permit persons to whom the  
Software is furnished to do so, subject to the following 
conditions:

    The above copyright notice and this permission notice shall be 
included in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND 
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS 
BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN 
ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN 
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE 
SOFTWARE.
--]]

local min,floor,log,random = math.min,math.floor,math.log,math.random

local logb = function(n,base)
	return log(n) / log(base)
end

-- Probability that a node appears in a higher level
local p = 0.5

local skip_list = {

	clear = function(self)
		self.head   = {}
		self._levels= 1
		self._count = 0
		self._size  = 2^self._levels
	end,
	
	-- comp: < or > (Duplicate keys are inserted at the beginning)
	-- comp: <= or >= (Duplicate keys are inserted at the end)
	new = function(class,initial_size,comp)
		initial_size= initial_size or 100
		
		local levels= floor( logb(initial_size,1/p) )
		
		return setmetatable({
			head   = {},
			_levels= levels, -- recommended by Pugh
			_count = 0,
			_size  = 2^levels,
			comp   = comp or function(a,b) return a <= b end},
			class)
	end,
	
	length = function(self)
		return self._count
	end,
	
	-- Return the key, value, and node
	-- If value is omitted, return any matching key and value
	find = function(self,key,value)
		local node = self.head
		local comp = self.comp
		-- Start search at the highest level
		for level = self._levels,1,-1 do
			-- Move to the next node if its key is <= desired
			while node[level] and (node[level].key == key or comp(node[level].key,key)) do	
				node = node[level]
				if node.key == key then
					-- Search for key-value pair if there is value argument
					if value then
						-- Search "left" and "right" sides for matching value
						local prev = node
						while prev do
							if prev.key == key and prev.value == value then
								return prev.key,prev.value,prev
							end
							prev = prev[-1]
						end
						local next = node[1]
						while next do
							if next.key == key and next.value == value then
								return next.key,next.value,next
							end
							next = next[1]
						end
						return
					end
					return node.key,node.value,node
				end
			end 
		end
	end,
	
	insert = function(self,key,value)
		-- http://stackoverflow.com/questions/12067045/random-level-function-in-skip-list
		-- Using a uniform distribution, we find the number of levels 
		-- by using the cdf of a geometric distribution
		-- cdf(k)   = 1 - ( 1 - p )^k
		-- levels-1 = log(1-cdf)/log(1-p)
		local levels = floor( log(1-random())/log(1-p) ) + 1
		levels       = min(levels,self._levels)
		local comp   = self.comp
		
		local new_node = {key = key, value = value}
		
		local node = self.head
		-- Search for the biggest node <= to our key on each level
		for level = self._levels,1,-1 do
			while node[level] and comp(node[level].key,key) do
				node = node[level]
			end
			-- Connect the nodes to the new node
			if level <= levels then
				new_node[-level] = node
				new_node[level]  = node[level]
				node[level]      = new_node
				if new_node[level] then
					local next_node   = new_node[level]
					next_node[-level] = new_node
				end
			end
		end

		-- Increment counter and dynamically increase the size 
		-- of the skip list if necessary
		self._count = self._count + 1
		if self._count > self._size then
			self._levels = self._levels + 1
			self._size   = self._size*2
		end
	end,
	
	_delete = function(self,node)
		local level = 1
		while node[-level] do
			local next = node[level]
			local prev = node[-level]
			prev[level]= next
			if next then next[-level] = prev end
			level = level + 1
		end
		self._count = self._count - 1
	end,
	
	-- Return the key,value if successful
	-- If value is omitted, delete any matching key
	delete = function(self,key,value)
		local k,v,node = self:find(key,value)
		if not node then return end
		self:_delete(node)
		return k,v
	end,
	
	-- Return the first key,value
	pop = function(self)
		local node  = self.head[1]
		if not node then return end
		self:_delete(node)
		return node.key,node.value
	end,
	
	-- Check but do not remove the first key,value
	peek = function(self)
		local node = self.head[1]
		if not node then return end
		return node.key,node.value
	end,
	
	-- Iterate in order or reverse
	-- Return the key,value
	iterate = function(self,mode)
		mode = mode or 'normal'
		if not (mode == 'normal' or mode == 'reverse') then
			error('Invalid mode')
		end
		
		local node,incr = self.head[1],1
		
		if mode == 'reverse' then
			-- Search for the node at the end
			for level = self._levels,1,-1 do
				while node[level] do
					node = node[level]
				end
			end
			incr = -1
		end
		return function()
			if node then
				local k,v= node.key,node.value
				-- Move to the next node
				node     = node[incr] 
				return k,v
			end
		end
	end,
	
	-- Check the integrity of the skip list
	-- Return true if it passes else error!
	check = function(self)
		local level = 0
		while self.head[level+1] do
			level      = level + 1
			local prev = self.head
			local node = self.head[level]
			while node do
				if prev ~= node[-level] then
					local template = 'Node with key %d at level %d has invalid back reference!'
					error( template:format(node.key,level) )
				end
				if node[level] then
					if not self.comp(node.key,node[level].key) and node.key ~= node[level].key then
						local template = 'Skip list is out of order on level %d: key %s is before %s!'
						error(template:format(level,tostring(node.key),tostring(node[level].key)))
					end
					if node[level] == node then
						error('Node self reference!')
					end
				end
				
				-- If the node has a link at this level, it must also have a
				-- link at the lower level
				if level > 1 then
					for direction = -1,1,2 do
						if node[direction*level] and not node[direction*(level-1)] then
							error(string.format('Missing node link at level %d',level-1))
						end
					end
				end
				
				prev = node
				node = node[level]
			end
		end
		do 
			local template = 'Node level %d exceeds maximum: %d'
			assert(level <= self._levels,template:format(#self.head,self._levels))
		end
		return true
	end,
}
skip_list.__index = skip_list

return skip_list