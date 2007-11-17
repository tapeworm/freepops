#! /usr/bin/lua

status = "nothing"
curfile = nil
for l in io.lines() do
	f = string.match(l,"^Working file: (.*)")
	curfile = f or curfile
	r = string.match(l,"selected revisions: (%d*)")
	if r ~= nil and tonumber(r) ~= nil and tonumber(r) > 0 then
		print(curfile)
	end
end

