---
-- Internalize XML into LUA.
--
-- This module allows you to transform an XML string into a Txml lua table.
-- But first, what is Txml? Another tag based language? <b>NO</b>.<br/>
-- Im' not an XML guru, so take my personal opinions with the right doubts.<br/>
-- XML is a pretty flexible language, good for doing nothig, bad for doing all.
-- Since it is really generic it may allow the reuse of of some tools... 
-- But what do you think?! Isn't grep a reused peace of code?
-- Anyway it seems that doing XML stuff is for real men.
-- So everithing is done in XML nowadays.<br/>
-- Why I don't like it much? Simple, there is no way to access it 
-- with the language. You have to parse it and transform it in a 
-- more handy format for your internal purpose, elaborate it and 
-- then retransform you data structure in XML.<br/>
-- So this module is
-- for the step of internalizing an XML tree into a LUA table. 
-- This means that you will be able to travferse the tree in the
-- same way you traverse a table.<br/>
-- <pre>
-- Txml = { tag_name = "father",
--          name = "Mario",
--          { tag_name = "son",
--            {"son content"}
--          }
-- }
-- </pre>
-- This table represents this xml<br/>
-- <pre>
-- &lt;?xml version="1.0"?&gt;
-- &lt;father name="Mario"&gt;
--   &lt;son&gt;son content&lt;/son&gt;
-- &lt;/father&gt;
-- </pre>
-- This modules is able to convert the XML into the Txml format in
-- a quite smart way.
-- For example this code is valid:<br/>
-- <pre>
-- father = xml2table.xml2table(the xml string you have seen before)
-- print(father.name)
-- print(father.son._content)
-- </pre>
-- and the result will be "Mario" and "son content".
-- And now a more complex example with namespaces.<br/>
-- <pre>
-- &lt;?xml version="1.0"?&gt;
-- &lt;D:multistatus xmlns:D="Dav:"&gt;
--   &lt;D:response&gt;
--     &lt;D:href&gt;http://ref1&lt;/D:href&gt;
--     &lt;D:propstat&gt;
--       &lt;D:status&gt;HTTP/1.1 200&lt;/D:status&gt;
--     &lt;/D:propstat&gt;
--   &lt;/D:response&gt;
--   &lt;D:response&gt;
--     &lt;D:href&gt;http://ref2&lt;/D:href&gt;
--     &lt;D:propstat&gt;
--       &lt;D:status&gt;HTTP/1.1 404&lt;/D:status&gt;
--     &lt;/D:propstat&gt;
--   &lt;/D:response&gt;
-- &lt;/D:multistatus&gt;
-- </pre>
-- we can convert this to Txml in tree ways:
-- <pre>
-- tml1 = xml2table.xml2table(xml2)
-- tml2 = xml2table.xml2table(xml2,{})
-- tml3 = xml2table.xml2table(xml2,{["Dav:"]="d"})
-- </pre>
-- The information stored is the same, but only the third is the good one.
-- The first has "Dav:" aded to each tag name. Impossiblo to type it in LUA.
-- The second doesn't do anithing. The third one trnasforms each 
-- shortcut to his mapped. Each shortcut to "Dav:" will be replaced with 
-- a shortcut to "d". This is nice for two reasons. First it converts the ":"
-- to <tt>__</tt> and so you can type it in LUA. Second you can forget what
-- the XML uses as a shortcut, it will be replaced with "d" in any case.
--
-- <pre>
-- > print(tml1.tag_name)
-- Dav::multistatus
-- > print(tml1[1].tag_name)
-- Dav::response
-- 
-- > print(tml2.tag_name)
-- D:multistatus
-- > print(tml2[1].tag_name)
-- D:response
-- 
-- > print(tml3.tag_name)
-- d__multistatus
-- > print(tml3[1].tag_name)
-- d__response
-- > print(tml3.d__response.d__href._content)
-- http://ref1
-- 
-- > xml2table.forach_son(tml3,"d__response",
-- >> function(k) 
-- >>    print(k.d__href._content) 
-- >> end)
-- http://ref1
-- http://ref2
-- </pre>

MODULE_VERSION = "0.0.1"
MODULE_NAME = "xml2table"
MODULE_REQUIRE_VERSION = "0.0.99"
MODULE_LICENSE = "GNU/GPL"
MODULE_URL = "http://www.freepops.org/download.php?module=xml2table.lua"
MODULE_HOMEPAGE = "http://www.freepops.org/"

local Private = {}

--============================================================================--
-- This is part of FreePOPs (http://www.freepops.org) released under GNU/GPL  
--============================================================================--

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
			local tok =  string.match(k,"^xmlns:(%w+)")
			local c = string.match(k,"^(xmlns)")
			if c then
				if tok then
					abbr[tok] = m[v] 
				else
					abbr["_"] = m[v]
				end
			end
		end
	end)

	local x,tok =  string.match(t.tag_name,"^(%w+):(%w+)")
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

module("xml2table",package.seeall)

---
-- Converts XML data in a table.
-- If m is {} namespaces are not expanded
-- If m is { ["namespace"] = "xxx" } than namespaces will be 
--  expanded according to m rules, but not listed namespaces will
--  not be expanded
-- If m is nil namespaces are expanded every time it is possible.
-- @param s string the xml data.
-- @param m table the map.
-- @param force_encoding string To force the encoding of the XML,
--  putting "UTF-8" solves some problems with strange encodings.
-- @return table the resulting table or nil follwed by msg,line,col.
function xml2table(s,m,force_encoding)
	local tab = {s=Private.stack.new()}
	local handle_namespaces = nil
	if m == nil then
		handle_namespaces = ":"
	end
	local p = lxp.new(Private.lpx_cb_factory(tab),handle_namespaces)
	if force_encoding then
		if type(p.setencoding) == "function" then
			p:setencoding(force_encoding)
		else
			s = string.gsub(s,'encoding="[%w%-]+"',
				'encoding="'..force_encoding..'"')
		end
	end       
	local ok, msg, line, col, pos = p:parse(s)
	if not ok then
		return nil,msg.." line="..line.." col="..col.." pos="..pos..
			" '"..string.sub(s,
				math.max(pos-20,0),
				math.min(pos+20,string.len(s)))..
			"...'"
	end
	if m ~= nil then
		Private.map_namespaces(tab.root,m)	
	end
	return tab.root
end

---
-- This is a selective table-foreach.
-- A correct usage is forach_son(t,"D__resposnse",f).
function forach_son(t,sonname,f)
	table.foreachi(t,function(_,v)
		if v.tag_name == sonname then
			f(v)
		end
	end)
end
