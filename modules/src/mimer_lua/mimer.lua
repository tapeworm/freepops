mimer = {}
local Private = {}

Private.boundary_chars=
	"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890"

function Private.randomize_boundary()
	local t = {}
	local len = string.len(Private.boundary_chars)

	for i=1,10 do
		local x = math.random(1,len)
		table.insert(t,
			string.char(string.byte(Private.boundary_chars,x)))
	end

	return table.concat(t)
end

function Private.content_type_of_string(b)
	local _,_,x = string.find(b,"^(<html>)")
	if x ~= nil then
		return "Content-Type: text/html\r\n"
	else
		return "Content-Type: text/plain; charset=us-ascii\r\n"
	end
end

function Private.needs_encoding(content_type)
	if content_type ~= "text/plain" and
	   content_type ~= "text/html" then
		return true
	else
		return false
	end
end

function Private.content_transfer_encoding_of(content_type)
	if not Private.needs_encoding(content_type) then
		return "Content-Transfer-Encoding: quoted-printable\r\n"
	else
		return "Content-Transfer-Encoding: base64\r\n"
	end
end

Private.base64wrap = 45

function Private.base64_io_slave(cb)
	local buffer = ""
	return function(s,len)
		
		print("HO " .. len .. " BYTES")
		
		buffer = buffer .. s
		
		while string.len(buffer) >= Private.base64wrap do
			local chunk = string.sub(buffer,1,Private.base64wrap)
			--FIXME don't call the callback fr each line
			cb(base64.encode(chunk).."\0")
			cb("\r\n")
			buffer = string.sub(buffer,Private.base64wrap + 1,-1)
		end

		if len == 0 then
			--empty the buffer
			cb(base64.encode(buffer).."\0")
			cb("\r\n")
			buffer = ""
		end

		return len
	end
end

function Private.attach_it(browser,boundary,send_cb)
	return function(k,uri)
		local h,err = browser:get_head(uri)

		--print(h)

		local _,_,x = string.find(h,
		"[Cc][Oo][Nn][Tt][Ee][Nn][Tt]%-[Tt][Yy][Pp][Ee]%s*:%s*([^\r]*)")

		send_cb("--"..boundary.."\r\n"..
			"Content-Type: "..x.."\r\n"..
			"Content-Disposition: attachment; "..
				"filename=\""..k.."\"\r\n"..
			Private.content_transfer_encoding_of(x)..
			"\r\n")
			
		local cb = nil
		if Private.needs_encoding(content_type) then
			cb = Private.base64_io_slave(send_cb)
		else
			cb = function(s,len)
				if len == 0 then return 0 end
				send_cb(s.."\0")
				return len
			end
		end
		print("---------"..uri)
		print(browser:pipe_uri(uri,cb))
		print("---------")
		
		cb("",0)
	end
end

function Private.wrap72(s)
	--FIXME
	return s.."\r\n"
end

function mimer.pipe_msg(headers,body,attachments,browser,send_cb)
	local boundary = Private.randomize_boundary()
	
	local mime = "MIME-Version: 1.0 (produced by FreePOPS/MIMER)\r\n"..
		"Content-Type: Multipart/Mixed; boundary=\""..boundary.."\"\r\n"
	local separe = "\r\n"

	-- send headers
	send_cb(headers .. mime .. separe)

	-- send the body
	send_cb("--"..boundary.."\r\n"..
		Private.content_type_of_string(body) ..
		"Content-Disposition: inline\r\n" ..
		separe..
		Private.wrap72(body))

	send_cb(separe)

	table.foreach(attachments,Private.attach_it(browser,boundary,send_cb))

	-- close message
	send_cb("--"..boundary.."--".."\r\n")
end
