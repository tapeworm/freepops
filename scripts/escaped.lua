#!/usr/bin/lua

assert(os.setlocale("en_US"),"unable to set locale")

res = {}
for i=0,255 do
	local _,_,c = string.find(string.char(i),"(%C)")
	if c ~= nil then
		table.insert(res,string.format("%s = %03d",c,string.byte(c)))
	end
end

q = math.ceil(table.getn(res)/4)
fake = "       "
for i=1,q-1 do
	print(string.format("\t%s\t\t%s\t\t%s\t\t%s",
		res[i] or fake,
		res[i+q] or fake,
		res[i+q+q] or fake,
		res[i+q+q+q] or fake))
end
