--============================================================================--
-- This is part of FreePOPs (http://freepops.sf.net) released under GNU/GPL  
--============================================================================--

Private = {}

Private.stack = {}
function Private.stack.mt(t) return {
	__index = {
		push = function(_,e)
			table.insert(t,1,e)
		end,
		pop = function()
			table.remove(t,1)
		end,
		top = function()
			return t[1]
		end
		},
	__newindex = function(t,k,v) error("Internal error") end
	}
end
Private.stack.new = function()
	local x = {}
	setmetatable(x,Private.stack.mt({}))
	return x
end

function Private.lpx_cb_factory(t)
return {
	CharacterData = function(p,s)
		if t.curnode[1] == nil then
			t.curnode[1] = {s}
		end
	end,
	EndElement = function(p, elementName) 
		local tmp = t.s:top()
		if tmp ~= nil then
			table.insert(tmp,t.curnode)
			t.curnode = tmp
			t.s:pop()
		else
			t.root = t.curnode
			t.curnode = nil
			t.s = nil
		end
	end,
        StartElement= function(p, elementName, attributes)
		if t.curnode ~= nil and 
		   t.curnode[1] ~= nil and 
		   t.curnode[1].tag_name == nil then
			table.remove(t.curnode,1)
		end
		t.s:push(t.curnode)
		t.curnode = {tag_name=elementName}
		setmetatable(t.curnode,Private.smart_metatable)
		table.foreach(attributes,function(k,v)
			if type(k) ~= "number" then
				t.curnode[k] = v
			end
		end)
	end,
	}
end

Private.smart_metatable = {
	__index = function(t,k)
		if k == "_content" then
			local son = t[1]
			if son ~= nil and son.tag_name == nil then
				return son[1]
			else
				return nil
			end
		else
			local i = table.foreachi(t,function(i,son)
				if son.tag_name == k then
					return i
				end 
			end)
			if i ~= nil then
				return t[i]
			else	
				return nil
			end
		end
	end
}

function Private.map_namespaces(t,m,abbr)
	if t.tag_name == nil then
		return true
	end
	abbr = abbr or {}
	m = m or {}

	-- find namespaces abbreviations
	table.foreach(t, function (k,v) 
		if type(k) ~= "number" then
			local _,_,tok =  string.find(k,"^xmlns:(%w+)")
			local _,_,c = string.find(k,"^(xmlns)")
			if c then
				if tok then
					abbr[tok] = m[v] 
				else
					abbr["_"] = m[v]
				end
			end
		end
	end)

	local _,_,x,tok =  string.find(t.tag_name,"^(%w+):(%w+)")
	local replace = abbr[x] or m[x]

	if replace ~= nil or abbr["_"] ~= nil then
		if replace then
			t.tag_name = replace .. "__" .. tok
		else
			t.tag_name = abbr["_"] .. "__" .. (tok or t.tag_name)
		end
	end


	table.foreachi(t,function(_,k) 
		Private.map_namespaces(k,m,abbr) 
	end)
end
--==========================================================================--
-- extern function
--==========================================================================--

xml2table = {}

---
-- Converts XML data in a table.
-- If m is {} namespaces are not expanded
-- If m is { ["namespace"] = "xxx" } than namespaces will be 
--  expanded according to m rules, but not listed namespaces will
--  not be expanded
-- If m is nil namespaces are expanded every time it is possible.
-- @param s string the xml data.
-- @param m table the map.
-- @return table the resulting table or nil follwed by msg,line,col.
function xml2table.xml2table(s,m,force_encoding)
	local tab = {s=Private.stack.new()}
	local handle_namespaces = nil
	if m == nil then
		handle_namespaces = ":"
	end
	local p = lxp.new(Private.lpx_cb_factory(tab),handle_namespaces)
	if force_encoding then
		if type(b.setencoding) == "function" then
			b:setencoding(force_encoding)
		else
			s = string.gsub(s,'encoding="[%w%-]+"',
				'encoding="'..force_encoding..'"')
		end
	end       
	local ok, msg, line, col = p:parse(s)
	if not ok then
		return nil,msg,line,col
	end
	if m ~= nil then
		Private.map_namespaces(tab.root,m)	
	end
	return tab.root
end

---
-- This is a selective table.foreach.
function xml2table.forach_son(t,sonname,f)
	table.foreachi(t,function(_,v)
		if v.tag_name == sonname then
			f(v)
		end
	end)
end
