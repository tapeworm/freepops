#!/usr/bin/lua

comments = {}

for l in io.stdin:lines() do
	--print("processo ", l)
	local _,_,fname = string.find(l,"- ([%a%.]*):")	
	local _,_,comment = string.find(l,"- [%a%.]*:(.*)")
	--print("ottengo" , fname, comment)
	--
	comment = comment or 'nil'
	fname = fname or 'nil'
	if comments[comment] == nil then
		comments[comment] = {fname}
	else
		table.insert(comments[comment],fname)
	end
end

table.foreach(comments,function(k,v)
	filename = ""
	already = {}
	for _,x in pairs(v) do
		if already[x] == nil then
 			filename = filename .. x .. ", "
			already[x] = true
		end
	end
	filename = string.sub(filename,0,-3)
	k = string.gsub(k,"  "," ")
	print("- " .. filename .. ":" .. k)
end)
