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
		self._count = 0
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
	find = function(self,key,value)
		local node = self.head
		local comp = self.comp
		-- Start search at the highest level
		for level = self._levels,1,-1 do
			-- Move to the next node if its key is <= desired
			while node[level] and comp(node[level].key,key) do	
				node = node[level]
				if node.key == key then
					-- Search for key-value pair if there is value argument
					if value then
						-- Search "left" and "right" sides for matching value
						local prev = node
						while prev do
							if prev.key == key and prev.value == value then
								return prev.key,prev.value
							end
							prev = prev[-1]
						end
						local next = node[1]
						while next do
							if next.key == key and next.value == value then
								return next.key,next.value
							end
							next = next[1]
						end
						return false
					end
					return node.key,node.value,node
				end
			end 
		end
		-- Return false if nothing was found
		return false
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
				if node[level] then
					node[level][-level] = new_node
				end
				node[level] = new_node
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
	-- Otherwise, return false
	delete = function(self,key,value)
		local k,v,node = self:find(key,value)
		if not node then return false end
		self:_delete(node)
		return k,v
	end,
	
	-- Return the first key,value
	-- Return false if empty
	pop = function(self)
		local node  = self.head[1]
		if not node then return false end
		self:_delete(node)
		return node.key,node.value
	end,
	
	-- Iterate in order
	-- Return the index,key,value
	iterate = function(self)
		local node  = self.head[1]
		local count = 0
		return function()
			if node then
				local k,v= node.key,node.value
				-- Move to the next node
				node     = node[1] 
				count    = count + 1
				return count,k,v
			end
		end
	end,
}
skip_list.__index = skip_list

return skip_list