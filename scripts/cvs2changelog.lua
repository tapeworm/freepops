#!/usr/bin/lua

--print("called with :")
--table.foreach(arg,print)

function is_all(s,c)
	for i=1,string.len(s) do
		if string.byte(s,i) ~= string.byte(c) then
			return false
		end
	end
	return true
end

function basename(s)
	local _,_,x,y = string.find(s,"(.*)/(.*)")
	if x == nil or y == nil then
		return s
	else
		return basename(y)
	end
end

if #arg < 2 then
	print([[
	cvs2changelog.lua should be called with 2 aguments:
	 1) the number of days
	 2) the file name
	]])
	os.exit(1)
end

file =  "/tmp/cvs2changelog-"..string.gsub(arg[2],"/","-")..arg[1]


os.execute("cvs log -d \">"..arg[1].." day ago\" "..arg[2].." 2</dev/null > ".. file)

f = io.open(file,"r")

log = {}
current = {}
status = "nothing"
for l in f:lines() do
	local _,_,x = string.find(l,"^(revision)")
	-- the begin of a block
	if x ~= nil and status == "nothing" then
		table.insert(log,current)
		status = "revision"
		current = {}
	end

	if status == "revision" then
		local _,_,r = string.find(l,"^revision ([%d%.]+)")
		current.revision = r
		status = "date"
	elseif status == "date" then
		local _,_,a = string.find(l,"author: ([%w]+);")
		local _,_,n = string.find(l,"lines: (.+)$")
		current.author = a
		current.lines = n
		status = "comment"
	elseif status == "comment" then
		if is_all(l,"-") or is_all(l,"=") then
			status = "nothing"
		else
			current.comment = (current.comment or "" ) .. 
				string.gsub(l,"\n","")
		end
	end
end

table.insert(log,current)

table.foreach(log,function(_,v)
	if v.revision ~= nil then
		print("- " .. basename(arg[2]) .. ": "	.. v.comment ..
			" ("..v.author..")")
	end
end)
