---
-- Do not use this directly. 
-- browser uses this module for his internal purpose.


--<==========================================================================>--
-- build data structures for parsing
local Private = {}

function Private.create_match(v)
	local vU = string.upper(v)
	local vL = string.lower(v)
	local r = {}
	for i=1,string.len(v) do
		r[i]="["..string.char(string.byte(vU,i))..
			string.char(string.byte(vL,i)).."]"
	end
	return "("..table.concat(r)..")"
end

Private.cookie_av={
	"domain",
	"path",
	"comment",
	"secure",
	"version",
	"max-age",
	"expires"
}

Private.value = {}
Private.value.token='=%s*("?[%w%.%_%-%%%/%+%-%*%|%=]+"?)'
Private.value.name="^(%s*[%w%_]+)"
Private.value.domain='=%s*("?%.[%w%.%_%-%%%/%+%-%*]+"?)'
Private.value.expires="=%s*(%a+%s*,%s*[%w%:%s%-]+)"
Private.value.secure="(%s?)"
Private.value.version="=%s*(%d)"

Private.left_table = {}
table.foreach(Private.cookie_av,function(_,v) 
	Private.left_table[v] = Private.create_match(v) 
	end)
Private.left_table["name"]=Private.value.name

function Private.eat(name,value)
	return function(s,t)
		local b,e,l,r =
			string.find(s,Private.left_table[name].."%s*"..value)
		if b then
			t[name]= r
			return string.sub(s,1,b-1)..string.sub(s,e+1,-1)
		end
		return s
	end
end

function Private.eat2(name1,name2,value)
	return function(s,t)
		local b,e,l,r = 
			string.find(s,Private.left_table[name1].."%s*"..value)
		if b then
			t[name1]=l
			t[name2]=r
			return string.sub(s,1,b-1)..string.sub(s,e+1,-1)
		end
		return s
	end
end


Private.types = {}
table.foreach(Private.cookie_av,function(_,v) 
	Private.types[v] = Private.value[v] or Private.value["token"]
	end)
Private.types["name"] = Private.value["token"]

Private.syntax = {}
table.foreach(Private.cookie_av,function(_,v) 
	Private.syntax[v] = Private.eat(v,Private.types[v])
	end)
Private.syntax["name"] = Private.eat2("name","value",Private.types["name"])

--<==========================================================================>--
-- helper functions

function Private.parse_cookie(s,h)
	local t = {}
	local s1 = s
	table.foreach(Private.syntax,function(n,f) s1 = f(s1,t) end)
	if t.expires ~= nil then
		local tmp = getdate.toint(t.expires)
		t["expires-raw"] = t["expires"]
		if tmp ~= -1 then
			t["expires"] = tmp
		end
	end
	t.timestamp = os.time()
	t.host = h
	return t
end

function Private.split_cookies(s)
	local t = {}
	while true do
	local l1 = string.find(s,",")
	local l3,l3b = string.find(s,Private.left_table["expires"]..
		"%s*=%s*%w+%s*")
	if not l1 then
		table.insert(t,s)
		return t
	end
	if l1 and l3 and l1<l3 then
		table.insert(t,string.sub(s,1,l1))
		s = string.sub(s,l1+1,-1)
	end
	if l1 and l3 and l1>l3 then
		if l3b then
			if l1 == l3b+1 then
				local l2  = string.find(s,",",l1+1)
				if l2 then
					table.insert(t,string.sub(s,1,l2))
					s = string.sub(s,l2+1,-1)
				else
					table.insert(t,s)
					return t
				end
			end
		else
			table.insert(t,s)
			return t
		end
		
	end
	end
end

function Private.parse_cookie_table(t,h)
	local r = {}
	table.foreach(t,function(_,s) 
		table.insert(r,Private.parse_cookie(s,h)) 
	end)
	return r
end

function Private.is_expired(c)
	local date = os.time()
	if c["max-age"] then
		if c["max-age"] > date then
			return true
		end
	end	
	
	-- this should not be necessary, but...
	if c["expires"] ~= nil and type(c["expires"]) == "string" then
		c["expires"] = getdate.toint(c["expires"])
	end
	
	if c["expires"] and c["timestamp"] then
		if os.difftime(date,c["timestamp"]) > c["expires"] then
			return true
		end
	end
	return false
end

function Private.split_uri(path)
	local t = {}
	if not path then return t end
	for w in string.gfind(path,"/[%w%%%_%.%~]*") do
		table.insert(t,string.sub(w,2,-1))
	end
	return t
end

function Private.subpath_len(path,sub)
	if not sub then
		return -1 --no path was
	end
	--print(path,sub)
	local t1 = Private.split_uri(path)
	local t2 = Private.split_uri(sub)
	local n = 0
	local function count(i,v)
		if t2[i] == v then
			n = n + 1
		else
			return false
		end
	end
	table.foreachi(t1,count)
	return n
end

--<==========================================================================>--

cookie = {}

-- cookie interface
function cookie.parse_cookies(s,h)
	if s then
		return Private.parse_cookie_table(Private.split_cookies(s),h)
	else
		return nil
	end
end

function cookie.merge(t2,t1)
	if not t1 then
		return
	end
	table.foreach(t1,function(_,c)
		local match = 0
		table.foreach(t2,function(_,c2)
			if c["name"] == c2["name"] and
			   c["host"] == c2["host"] then
				table.foreach(c,function(n,_)
					c2[n] = c[n] or c2[n] -- fix shit
				end)
				match = 1
				return 1 -- exit loop
			end
			end)
		if match == 0 then
			-- add it to the c
			table.insert(t2,c)
		end
	end)
end

function cookie.get(t,res,domain,host)
	local r = {}
	--print(res,domain,host)
	table.foreach(t,function(_,c)
		local l = Private.subpath_len(res,c["path"])
		--print(Private.is_expired(c),l,c["domain"],c.host)
		if not Private.is_expired(c) and
		   l ~= 0 and
		   ("."..domain == c["domain"] or c.host == host)
			then
			table.insert(r,{c=c,l=l})
		end
	end)
	table.sort(r,function(a,b) return a.l > b.l end)
	local s = ""
	table.foreach(r,function(_,w)
		s = "; \r\n        ".. s .. w.c.name .. "=" .. w.c.value 
		if w.c.domain then
			s = s .. '; $Domain = "' .. w.c.domain .. '"'
		end
		if w.c.path then
			s = s .. '; $Path = "' .. w.c.path .. '"'
		end
	end)
	if s ~= "" then
		return '$Version = "1" ' .. s
	else
		return nil
	end
end
