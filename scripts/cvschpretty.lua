#!/usr/bin/lua

comments = {}

for l in io.stdin:lines() do
	--print("processo ", l)
	local fname = string.match(l,"- ([^:]*):")	
	local comment = string.match(l,"- [^:]*:(.*)")
	--print("ottengo" , fname, comment)
	if comment and fname and fname ~= 'ChangeLog' then
		if comments[comment] == nil then
			comments[comment] = {fname}
		else
			table.insert(comments[comment],fname)
		end
	end
end

lines = {}

for k,v in pairs(comments) do
	table.sort(v)
	filename = table.concat(v,", ")
	k = string.gsub(k,"  "," ")
	table.insert(lines, "- " .. filename .. ":" .. k)
end

table.sort(lines)
for _,l in ipairs(lines) do print(l) end
