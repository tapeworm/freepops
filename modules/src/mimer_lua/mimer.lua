---
-- MIME Mail Emulator.
-- Module to build on the fly a message from a header, a body (both in html or
-- plain text format), a list of attachments urls

mimer = {}

--============================================================================--
-- This is part of FreePOPs (http://freepops.sf.net) released under GNU/GPL  
--============================================================================--

--<==========================================================================>--
local Private = {}

-- FIXME add more from: http://www.w3.org/TR/html401/sgml/entities.html
Private.html_coded = {
	["amp"]    = "&", 
	["agrave"] = "à", 
	["igrave"] = "ì", 
	["egrave"] = "è",
	["ograve"] = "ò", 
	["ugrave"] = "ù", 
	["quot"]   = '"',
	["lt"]     = '<',
	["gt"]     = '>',
	["nbsp"]   = " ",
	["iuml"]   = "I",
}

Private.html_tags = {
	["br"] = '\n',
	["/br"] = '\n',
	["li"] = '\t-',
	["/li"] = '\n',
	["ul"] = "",
	["/ul"] = "",
	["ol"] = "",
	["/ol"] = "",
	["img"] = '[image]',
	["/tr"] = '\n',
	["tr"] = "",
	["td"] = "\t",
	["/td"] = "",
	["th"] = "",
	["/th"] = "",
	["table"] = "",
	["/table"] ="",
	["pre"] = "",
	["/pre"] = "",
	["b"] = " *",
	["/b"] = "* ",
	["strong"] = " *",
	["/strong"] = "* ",
	["u"] = " _",
	["/u"] = "_ ",
	["div"] = "",
	["/div"] = "",
	["html"] = "",
	["/html"] = "",
	["head"] = "",
	["/head"] = "",
	["body"] = "",
	["/body"] = "",
	["p"] = "",
	["/p"] = "\n",
	["a"] = function (s,base_uri) 
		local start,stop = string.find(s,'[Hh][Rr][Ee][Ff]%s*=%s*')
		if start == nil or stop == nil then
			return "[" .. s .. "]"
		end
		local _,x = nil,nil
		if string.byte(s,stop+1) == string.byte('"') then
			_,_,x = string.find(string.sub(s,stop+2,-1),'^([^"]*)')
		else
			_,_,x = string.find(string.sub(s,stop+1,-1),'^([^ ]*)')
		end
		x = x or "link"
		if string.sub(x,1,1) == '/' then
			x = (base_uri or '/') .. x
		end
		return "[" .. x .. "]"
		end,
	["/a"] = "",
	["hr"] = "\n" .. string.rep("-",72) .. "\n",
	["font"] = "",
	["/font"] = "",
	["em"] = "",
	["/em"] = "",
	["!doctype"] = "",
	["void"] = "",
	["/void"] = "",
	["style"] = "",
	["/style"] = "",
	["meta"] = "",
}

Private.html_tags_plain = {
	["br"] = '\n',
	["/br"] = '\n',
	["li"] = '',
	["/li"] = '',
	["ul"] = "",
	["/ul"] = "",
	["ol"] = "",
	["/ol"] = "",
	["img"] = '',
	["/tr"] = '',
	["pre"] = "",
	["/pre"] = "",
	["b"] = "",
	["/b"] = "",
	["strong"] = " *",
	["/strong"] = "* ",
	["u"] = "",
	["/u"] = "",
	["div"] = "",
	["/div"] = "",
	["html"] = "",
	["/html"] = "",
	["head"] = "",
	["/head"] = "",
	["body"] = "",
	["/body"] = "",
	["p"] = "",
	["/p"] = "",
	["a"] = "",
	["/a"] = "",
	["hr"] = "",
	["font"] = "",
	["/font"] = "",
	["em"] = "",
	["/em"] = "",
	["!doctype"] = "",
	["void"] = "",
	["/void"] = "",
	["style"] = "",
	["/style"] = "",
	["meta"] = "",
	["tr"] = "",
	["td"] = "\t",
	["/td"] = "",
	["table"] = "",
	["/table"] ="",
	["th"] = "",
	["/th"] = "",
}


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
		buffer = buffer .. s
		
		local todo_table = {}
		while string.len(buffer) >= Private.base64wrap do
			local chunk = string.sub(buffer,1,Private.base64wrap)
			table.insert(todo_table,base64.encode(chunk).."\r\n")
			buffer = string.sub(buffer,Private.base64wrap + 1,-1)
		end
		if table.getn(todo_table) > 0 then
			cb(table.concat(todo_table))
		end

		if len == 0 then
			--empty the buffer
			cb(base64.encode(buffer).."\r\n")
			buffer = ""
		end

		return len
	end
end

Private.qpewrap=73
Private.eq = string.byte("=",1)
Private.lf = string.byte("\n",1)
Private.cr = string.byte("\r",1)

---
-- Encodes the message for mail transfer.
-- must be
function mimer.quoted_printable_encode(s)
	local out = {}
	local eq = Private.eq
	
	for i=1,string.len(s) do
		local b = string.byte(s,i)
		if b > 127 or b == eq then
			--FIXME: slow!
			table.insert(out,string.format("=%2X",b))
		else
			table.insert(out,string.char(b))
		end
	end
	return table.concat(out)
end

function Private.qpr_eval_expansion(s)
	local count = 0
	local to = 0
	local eq = Private.eq
	local lf = Private.lf
	local cr = Private.cr
	
	for i=0,string.len(s) do
		local b = string.byte(s,i)

		--FIXME not perfect if "...\r" trunk "\n..."
		if b == cr then
			if i+1 <= string.len(s) and 
				string.byte(s,i+1) == lf then
				return true,true,i+1
			else
				return true,true,i
			end
		end

		if b == lf then
			return true,true,i
		end
		
		if b > 127 or b == eq then
			count = count + 3
		else
			count = count + 1
		end
		if count > Private.qpewrap then	
			return true,false,i
		end
	end

	return false,false,string.len(s)
end

function Private.quoted_printable_io_slave(cb)
	local buffer = ""
	return function(s,len)
		buffer = buffer .. s
		
		local todo_table = {}
		local wrap,forced,len = Private.qpr_eval_expansion(buffer)
		while forced or wrap do
			local chunk = string.sub(buffer,1,len)
			if forced then
				chunk = string.gsub(chunk,"[\r\n]","")
				table.insert(todo_table,
				mimer.quoted_printable_encode(chunk).."\r\n")
			else
				table.insert(todo_table,
				mimer.quoted_printable_encode(chunk).."=\r\n")
			end
			
			buffer = string.sub(buffer,len + 1,-1)
			wrap,forced,len = Private.qpr_eval_expansion(buffer)
		end
		if table.getn(todo_table) > 0 then
			cb(table.concat(todo_table))
		end
		if len == 0 then
			cb(Private.qpr_eval_expansion(buffer))
			buffer = ""
		end
		return len
	end

end

function Private.attach_it(browser,boundary,send_cb)
	return function(k,uri)

		local h,err = browser:get_head(uri,{},true)

		local _,_,x = string.find(h or "",
		"[Cc][Oo][Nn][Tt][Ee][Nn][Tt]%-[Tt][Yy][Pp][Ee]%s*:%s*([^\r]*)")

		x = x or "application/octet-stream"

		send_cb("--"..boundary.."\r\n"..
			"Content-Type: "..x.."\r\n"..
			"Content-Disposition: attachment; "..
				"filename=\""..k.."\"\r\n"..
			Private.content_transfer_encoding_of(x)..
			"\r\n")
			
		local cb = nil
		if Private.needs_encoding(x) then
			cb = Private.base64_io_slave(send_cb)
		else
			cb = Private.quoted_printable_io_slave(send_cb)
		end
	
		-- do the work
		browser:pipe_uri(uri,cb)

		-- flush last bytes
		cb("",0)
	end
end

function Private.send_alternative(body,body_html,send_cb)
	local boundary = Private.randomize_boundary()
	local rc = nil
	
	rc = send_cb("MIME-Version: 1.0 (produced by FreePOPs/MIMER)\r\n"..
		"Content-Type: Multipart/alternative; "..
			"boundary=\""..boundary.."\"\r\n"..
		"\r\n")
	if rc ~= nil then return rc end
	
	rc = send_cb("--"..boundary.."\r\n"..
		"Content-Type: text/plain charset=\"iso-8859-1\"\r\n"..
		"Content-Transfer-Encoding: quoted-printable\r\n"..
		"\r\n"..
		body)
	if rc ~= nil then return rc end
	
	rc = send_cb("--"..boundary.."\r\n"..
		"Content-Type: text/html charset=\"iso-8859-1\"\r\n"..
		"Content-Transfer-Encoding: quoted-printable\r\n"..
		"\r\n"..
		body_html)
	if rc ~= nil then return rc end	

	send_cb("--"..boundary.."--".."\r\n")
end



function Private.token_of(c)
	local _,_,x,y = string.find(c,"^%s*([/!]?)%s*(%a+)%s*")
	return (x or "") .. (y or "")
end

function Private.html2txt(s,base_uri,html_coded,html_tags,all)
	s = string.gsub(s,"&(%a-);",function(c)
		c = string.lower(c)
		return html_coded[c] or ("["..c.."]")
	end)
	s = string.gsub(s,"<%s*[Ss][Cc][Rr][Ii][Pp][Tt][^>]*>.-<%s*/%s*[Ss][Cc][Rr][Ii][Pp][Tt][^>]*>","")
	s = string.gsub(s,"<%s*[Ss][Tt][Yy][Ll][Ee][^>]*>.-<%s*/%s*[Ss][Tt][Yy][Ll][Ee][^>]*>","")
	s = string.gsub(s,"<([^>]-)>",function(c)
		c = string.lower(c)
		local t = Private.token_of(c)
		local r = html_tags[t]
		
		if type(r) == "string" then
			return r
		elseif type(r) == "function" then
			return r(c,base_uri)
		end
		if all then
			return "["..c.."]"
		else
			return "<" .. c ..">"
		end
	end)
	if all then
		local n = 1
		while n > 0 do 
			s,n = string.gsub(s,"^%s*\n%s*\n","\n")
		end
	end
	return s
end

--<==========================================================================>--

---
-- Builds a MIME encoded message and pipes it to send_cb.
-- @param headers string the mail headers, already mail encoded (\r\n) but
--        without the blank line separator.
-- @param body string the plain text body, if null it is inferred from the 
--        html body that must be present in that case.
-- @param body_html string the html body, may be null.
-- @param base_uri string is used to mangle hrefs in the mail html body.
-- @param attachments table a table { ["filename"] = "http://url" }.
-- @param browser table used to fetch the attachments.
-- @param send_cb function the callback to send the message, 
--        may be called more then once and may return not nil to stop 
--        the ending process.
function mimer.pipe_msg(headers,body,body_html,base_uri,attachments,browser,send_cb)
	attachments = attachments or {}
	local rc = nil

	if body == nil and body_html == nil then
		error("one of body/body_html must be non nil")
		return
	end

	body = body or mimer.html2txtmail(body_html,base_uri)

	if table.getn(attachments) > 0 then
		local boundary = Private.randomize_boundary()
		
		local mime = "MIME-Version: 1.0 "..
				"(produced by FreePOPS/MIMER)\r\n"..
			--"Content-Type: Multipart/Related; "..
			"Content-Type: Multipart/Mixed; "..
				"boundary=\""..boundary.."\"\r\n"
		
		-- send headers
		rc = send_cb(headers .. mime .. "\r\n")
		if rc ~= nil then return end
	
		-- send the body
		if body_html == nil then
			rc = send_cb("--"..boundary.."\r\n"..
				"Content-Type: text/plain; "..
					"charset=\"iso-8859-1\"\r\n"..
				"Content-Disposition: inline\r\n" ..
				"Content-Transfer-Encoding: "..
					"quoted-printable\r\n"..
				"\r\n"..
				mimer.txt2mail(
					mimer.quoted_printable_encode(body))..
				"\r\n")
			if rc ~= nil then return end	
		else
			rc = send_cb("--"..boundary.."\r\n")
			if rc ~= nil then return end

			rc = Private.send_alternative(
				mimer.txt2mail(
					mimer.quoted_printable_encode(body)),
				mimer.txt2mail(
					mimer.quoted_printable_encode(
						body_html)),
				send_cb)
			if rc ~= nil then return end	
		end
	
		rc = table.foreach(attachments,
			Private.attach_it(browser,boundary,send_cb))
		if rc ~= nil then return end
		
		-- close message
		rc = send_cb("--"..boundary.."--".."\r\n")
		if rc ~= nil then return end
	else
		if body_html == nil then
			rc = send_cb(headers .. "\r\n")
			if rc ~= nil then return end
			
			rc = send_cb(mimer.txt2mail(body))
			if rc ~= nil then return end
		else
			rc = send_cb(headers)
			if rc ~= nil then return end
			
			rc = Private.send_alternative(
				mimer.txt2mail(
					mimer.quoted_printable_encode(body)),
				mimer.txt2mail(
					mimer.quoted_printable_encode(
						body_html)),
				send_cb)
			if rc ~= nil then return end	
		end
	end
end

---
-- Tryes to convert an HTML document to a human readable plain text.
--
function mimer.html2txtmail(s,base_uri)
	return Private.html2txt(s,base_uri,Private.html_coded,Private.html_tags,true)
end

---
-- Converts an HTML document to a plain text file, removing tags and
-- unescaping &XXXX; sequences.
--
function mimer.html2txtplain(s,base_uri)
	return Private.html2txt(s,base_uri,Private.html_coded,
		Private.html_tags_plain,false)
end

---
-- Converts a plain text string to a \r\n encoded message, ready to send as
-- a RETR response.
-- 
function mimer.txt2mail(s)
	s = string.gsub(s,'\r','')
	s = string.gsub(s,'\n','\r\n')
	s = string.gsub(s,'\r\n.\r\n','\r\n..\r\n')
	if string.sub(s,-2,-1) ~= '\r\n' then
		return s .. '\r\n'
	else
		return s
	end
end

Private.extra = {
	string.byte("%",1),
	string.byte("-",1)
}

function Private.is_an_extra(c)
	return table.foreach(Private.extra,
		function(_,m) 
			if m == c then 
				return true 
			end 
		end) or false
end

function Private.domatch(b,v,a)
	local vU = string.upper(v)
	local vL = string.lower(v)
	local r = {}
	for i=1,string.len(v) do
		if Private.is_an_extra(string.byte(vU,i)) then
			r[i] = string.char(string.byte(vU,i))
		else
			r[i]="["..string.char(string.byte(vU,i))..
				string.char(string.byte(vL,i)).."]"
		end
	end
	return b .. table.concat(r) .. a
end

---
--Removes unwanted tags from an html string.
--@param p table a list of tags in this form {"head","p"}.
--@return string the cleaned html.
function mimer.remove_tags(s,p)
	table.foreachi(p,function(k,v)
		s = string.gsub(s,Private.domatch("<%s*[!/]?",v,"[^>]*>"),"")
	end)
	return s
end

function Private.lines_of_string(s)
	local result = {}
	while s ~= "" do
		local a,b = string.find(s,"\n")
		if a == nil then
			table.insert(result,s)
			break
		end
		table.insert(result,string.sub(s,1,a))
		s = string.sub(s,b+1,-1)
	end
	return result
end

---
-- Deletes some fields in a mail header.
--@param s string a valid mail header.
--@param p table a list of mail headers in this form {"content%-type","date"} 
-- 	(with - escaped with %).
--@return string the cleaned header.
function mimer.remove_lines_in_proper_mail_header(s,p)
	local s1 = Private.lines_of_string(s)
	local remove_next = false
	local result = {}
	
	for i,l in ipairs(s1) do
		local skip = false
		if remove_next then
			if string.byte(l,1)==string.byte(" ") or
				string.byte(l,1)==string.byte("\t")then
				skip = true
			else
				remove_next = false
			end
		end
			
		if not skip then
			local match = table.foreach(p,function(k,m)
				local _,_,x = string.find (l,
					Private.domatch("^(",m,")"))
				if x ~= nil then
					return true
				end
			end)

			if match == nil then
				table.insert(result,l)
			else
				remove_next = true
			end
		end
	end
	return table.concat(result)
end

---
-- Transforms a classical callback f(s,len) to a mimer compliant callback.
--@param f function a function that takes s,len and returns len,error.
--@return function a callback that returns non nil to stop (instead of 
--                 0,"" or nil,"").
function mimer.callback_mangler(f) 
	return function(s)
		local b,err = f(s,string.len(s))
		if b == 0 or b == nil then
			if b == nil then
				log.error_print(err or "bad callback?")
			end
			return true
		else
			return nil
		end
	end
end

