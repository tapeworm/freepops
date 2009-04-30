---
-- MIME Mail Emulator.
-- Module to build on the fly a message from a header, a body (both in html or
-- plain text format), a list of attachments urls

MODULE_VERSION = "0.1.5"
MODULE_NAME = "mimer"
MODULE_REQUIRE_VERSION = "0.2.0"
MODULE_LICENSE = "GNU/GPL"
MODULE_URL = "http://www.freepops.org/download.php?module=mimer.lua"
MODULE_HOMEPAGE = "http://www.freepops.org/"


--============================================================================--
-- This is part of FreePOPs (http://www.freepops.org) released under GNU/GPL  
--============================================================================--

--<==========================================================================>--
local Private = {}

-- FIXME add more from: http://www.w3.org/TR/html401/sgml/entities.html
Private.html_coded = {

	["szlig"]	= "ß",
	["Ntilde"]	= "Ñ",
	["ntilde"]	= "ñ",
	["Ccedil"]	= "Ç",
	["ccedil"]	= "ç",
	
	["auml"]	= "ä",
	["euml"]	= "ë",
	["iuml"]	= "ï",
	["ouml"]	= "ö",
	["uuml"]	= "ü",
	["Auml"]	= "Ä",
	["Euml"]	= "Ë",
	["Iuml"]	= "Ï",
	["Ouml"]	= "Ö",
	["Uuml"]	= "Ü",
	["aacute"]	= "á",
	["eacute"]	= "é",
	["iacute"]	= "í",
	["oacute"]	= "ó",
	["uacute"]	= "ú",
	["Aacute"]	= "Á",
	["Eacute"]	= "É",
	["Iacute"]	= "Í",
	["Oacute"]	= "Ó",
	["Uacute"]	= "Ú",
	["acirc"]	= "â",
	["ecirc"]	= "ê",
	["icirc"]	= "î",
	["ocirc"]	= "ô",
	["ucirc"]	= "û",
	["Acirc"]	= "Â",
	["Ecirc"]	= "Ê",
	["Icirc"]	= "Î",
	["Ocirc"]	= "Ô",
	["Ucirc"]	= "Û",
	["agrave"]	= "à",
	["igrave"]	= "ì",
	["egrave"]	= "è",
	["ograve"]	= "ò",
	["ugrave"]	= "ù",
	["Agrave"]	= "À",
	["Igrave"]	= "Ì",
	["Egrave"]	= "È",
	["Ograve"]	= "Ò",
	["Ugrave"]	= "Ù",

	["euro"]	= '€',
	["pound"]	= '£',
	["yen"]		= '¥',
	["cent"]	= '¢',
	["iquest"]	= '¿',
	["iexcl"]	= '¡',
	["quot"]	= '"',
	["lt"]		= '<',
	["gt"]		= '>',
	["nbsp"]	= ' ',
	["amp"]		= '&',
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
	["i"] = "/",
	["/i"] = "/",
	["big"] = "",
	["/big"] = "",
	["small"] = "",
	["/small"] = "",
	["strong"] = " *",
	["/strong"] = "* ",
	["em"] = "/",
	["/em"] = "/",
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
			x = string.match(string.sub(s,stop+2,-1),'^([^"]*)')
		else
			x = string.match(string.sub(s,stop+1,-1),'^([^ ]*)')
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
	["!doctype"] = "",
	["void"] = "",
	["/void"] = "",
	["comment"] = "",
	["/comment"] = "",
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
	["b"] = "*",
	["/b"] = "*",
	["i"] = "/",
	["/i"] = "/",
	["big"] = "",
	["/big"] = "",
	["small"] = "",
	["/small"] = "",
	["strong"] = "*",
	["/strong"] = "*",
	["em"] = "/",
	["/em"] = "/",
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
	["hr"] = "\n" .. string.rep("-",44) .. "\n",
	["font"] = "",
	["/font"] = "",
	["!doctype"] = "",
	["void"] = "",
	["/void"] = "",
	["comment"] = "",
	["/comment"] = "",
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


-- ------------------------------------------------------------------------- --
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

-- ------------------------------------------------------------------------- --
function Private.needs_encoding(content_type)
	if content_type ~= "text/plain" and
	   content_type ~= "text/html" then
		return true
	else
		return false
	end
end

-- ------------------------------------------------------------------------- --
function Private.content_transfer_encoding_of(content_type)
	if not Private.needs_encoding(content_type) then
		return "Content-Transfer-Encoding: quoted-printable\r\n"
	else
		return "Content-Transfer-Encoding: base64\r\n"
	end
end

-- ------------------------------------------------------------------------- --
Private.base64wrap = 45

function base64_io_slave(cb)
	local buffer = ""
	return function(s,len)
		buffer = buffer .. s
		
		local todo_table = {}
		while string.len(buffer) >= Private.base64wrap do
			local chunk = string.sub(buffer,1,Private.base64wrap)
			table.insert(todo_table,base64.encode(chunk).."\r\n")
			buffer = string.sub(buffer,Private.base64wrap + 1,-1)
		end
		if #todo_table > 0 then
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

Private.base64_io_slave = base64_io_slave

-- ------------------------------------------------------------------------- --
Private.qpewrap=73
Private.eq = string.byte("=",1)
Private.lf = string.byte("\n",1)
Private.cr = string.byte("\r",1)

-- ------------------------------------------------------------------------- --
---
-- Encodes the message for mail transfer.
-- must be
function Private.quoted_printable_encode(s)
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

-- ------------------------------------------------------------------------- --
function Private.qpr_eval_expansion(s)
	local count = 0
	local to = 0
	local eq = Private.eq
	local lf = Private.lf
	local cr = Private.cr
	
	for i=1,string.len(s) do
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

-- ------------------------------------------------------------------------- --
-- a callback that implements the "quoted printable" encoding
function Private.quoted_printable_io_slave(cb)
	local buffer = ""
	return function(s,len)
		local saved_len = len 
		buffer = buffer .. s
		
		local todo_table = {}
		local wrap,forced,len = Private.qpr_eval_expansion(buffer)
		while forced or wrap do
			local chunk = string.sub(buffer,1,len)
			if forced then
				chunk = string.gsub(chunk,"[\r\n]","")
				table.insert(todo_table,
				Private.quoted_printable_encode(chunk).."\r\n")
			else
				table.insert(todo_table,
				Private.quoted_printable_encode(chunk).."=\r\n")
			end
			
			buffer = string.sub(buffer,len + 1,-1)
			wrap,forced,len = Private.qpr_eval_expansion(buffer)
		end
		if #todo_table > 0 then
			cb(table.concat(todo_table))
		end
		if len == 0 then
			cb(Private.qpr_eval_expansion(buffer))
			buffer = ""
		end
		return saved_len
	end

end

-- ------------------------------------------------------------------------- --
-- wrapper for the NEW and OLD implementation
function Private.attach_it(browser,boundary,send_cb,inlineids)
	-- switch here between the old and tested implementation and
	-- the new and more efficient hack
	return Private.attach_it_new(browser,boundary,send_cb,inlineids)
	--return Private.attach_it_old(browser,boundary,send_cb)
end

---
-- a micro implementation of magic numbers to content types
Private.sniffer = {
-- FIXME many more content-types can be addded... :)
["image/gif"]	= "GIF",
["image/jpeg"]	= "\255\216", -- FFD8
["image/png"]	= "\137PNG",
--[[
["text/html"]	= "%s-<%s-[Hh][Tt][Mm][Ll]",
]]
}

-- ------------------------------------------------------------------------- --
-- This is the NEW implementation. 
-- 
-- PRO:  + only one HTTP request, the header callback sets content_type and the
--         body callback chooses on the fly the io slave.
--       + no mere HEAD (sometimes not supported by CGIs)
--       + acts as a browser
-- CONS: - the code is harder
--       - worse HTTP header parsing, no error detection. May find the 
--         404 HTML page attached in your mail if the URL is wrong
--       - more cpu intense, one check and a function call more than before
--       
function Private.attach_it_new(browser,boundary,send_cb,inlineids)
	return function(k,uri)
		local inlineid = inlineids[k]
		-- the 2 callbacks and the shared variable content_type
		local cb_h,cb_b = nil,nil
		local content_type = nil
		local file_name = k
		
		-- the header parser, simply sets the content_type variable
		-- this is fed the header one line at a time
		-- strangely, the len given is not the length but is identical to h!
		cb_h = function(h,len)
			-- FIXME, may be an incorrect URL and not a 200 HTTP
			
--			log.dbg("mimer cb_h: header=\n"..h)
--			log.dbg("mimer cb_h: len="..h)
			
			-- try to extract the content type
			local x = string.match(h or "",
			  "[Cc][Oo][Nn][Tt][Ee][Nn][Tt]%-[Tt][Yy][Pp][Ee]%s*:%s*([^\r]*)")
			-- we might not be processing the right line, so only
			--  set if we found something.
			if x then
			  content_type = x
			  --log.dbg("mimer cb_h: content_type="..(content_type or "?"))
			end

			-- try to extract the filename
			local x = string.match(h or "",
			  '[Cc][Oo][Nn][Tt][Ee][Nn][Tt]%-[Dd][Ii][Ss][Pp][Oo][Ss][Ii][Tt][Ii][Oo][Nn]:.-[Ff][Ii][Ll][Ee][Nn][Aa][Mm][Ee]="(.-)"')
			if x then
				file_name = x
				--log.dbg("mimer cb_h: file_name="..(file_name or "?"))
			end
            
			return len
		end

		-- a static variable for the callback that contains the real
		-- io slave callback
		local real_cb = nil
		
		cb_b = function(s,len)
--			log.dbg("mimer cb_b: body=\n"..s)
			-- the first time we choose the encoding depending on 
			-- the content_type shared variable set by the cb_h
			if real_cb == nil then
				local detected_content_type = nil
				for n,b in pairs(Private.sniffer) do
					if string.find(s or "", b) == 1 then
						detected_content_type = n
						break
					end
				end
				if content_type ~= nil and 
				   detected_content_type ~= nil and
				   string.upper(detected_content_type) ~= 
				   string.upper(content_type) then
					content_type = detected_content_type
				end
				content_type = content_type or 
					"application/octet-stream"
				
--				log.dbg("mimer cb_b: content_type="..content_type)
					
				if Private.needs_encoding(content_type) then
					real_cb = Private.
					  base64_io_slave(send_cb)
				else
					real_cb = Private.
					  quoted_printable_io_slave(send_cb)
				end
				-- we send the mime header

				if ((not inlineid) or (inlineid == "")) then
					send_cb("--"..boundary.."\r\n"..
						"Content-Type: "..content_type.."\r\n"..
						"Content-Disposition: attachment; "..
						'filename="'..file_name..'"\r\n'..
						Private.content_transfer_encoding_of(
							content_type)..
						"\r\n")
				else
					send_cb("--"..boundary.."\r\n"..
						"Content-Type: "..content_type.."\r\n"..
						"Content-Disposition: inline\r\n"..
						"Content-ID: <"..inlineid..">\r\n"..
						Private.content_transfer_encoding_of(
							content_type)..
						"\r\n")
				end
			end
			-- we simply use the real io slave
			return real_cb(s,len)
		end
	
		-- do the work
		browser:pipe_uri_with_header(uri,cb_h,cb_b)

		-- flush last bytes
		cb_b("",0)
	end
end

-- ------------------------------------------------------------------------- --
-- this is the OLD implementation
--
-- PRO:  + safe and tested
--       + less cpu intensive
-- CONS: - more HTTP requests than a real browser
--       - if HEAD is not supported a GET is done
--       
function Private.attach_it_old(browser,boundary,send_cb)	
	return function(k,uri)

		local h,err = browser:get_head(uri,{},true)

		local x = string.match(h or "",
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

-- ------------------------------------------------------------------------- --
function Private.send_alternative(text_encoding,body,body_html,send_cb,keep_this_boundary)
	local boundary, rc

	if keep_this_boundary then
		boundary = keep_this_boundary
	else
		-- we create the boud, thus we write also the ctype
		boundary = Private.randomize_boundary()
		rc = send_cb(
			"MIME-Version: 1.0 (produced by FreePOPs/MIMER)\r\n"..
			"Content-Type: multipart/alternative; "..
			"boundary=\""..boundary.."\"\r\n"..
			"\r\n")
		if rc ~= nil then return rc end
	end

	rc = send_cb("--"..boundary.."\r\n"..
		"Content-Type: text/plain; "..
		"charset=\""..text_encoding.."\"\r\n"..
		"Content-Transfer-Encoding: quoted-printable\r\n"..
		"\r\n"..
		body)
	if rc ~= nil then return rc end

	rc = send_cb("--"..boundary.."\r\n"..
		"Content-Type: text/html; charset=\""..text_encoding.."\"\r\n"..
		"Content-Transfer-Encoding: quoted-printable\r\n"..
		"\r\n"..
		body_html)
	if rc ~= nil then return rc end

	if not keep_this_boundary then
		send_cb("--"..boundary.."--\r\n\r\n")
	end
end

-- ------------------------------------------------------------------------- --
function Private.token_of(c)
	local x,y = string.match(c,"^%s*([/!]?)%s*(%a+)%s*")
	return (x or "") .. (y or "")
end

-- ------------------------------------------------------------------------- --
function Private.html2txt(s,base_uri,html_coded,html_tags,all)
	s = string.gsub(s,"<%s*[Ss][Cc][Rr][Ii][Pp][Tt].->.-<%s*/%s*[Ss][Cc][Rr][Ii][Pp][Tt].->","")
	s = string.gsub(s,"<%s*[Ss][Tt][Yy][Ll][Ee].->.-<%s*/%s*[Ss][Tt][Yy][Ll][Ee].->","")
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
	s = string.gsub(s,"&(%a-);",function(c)
		c = string.lower(c)
		return html_coded[c] or ("["..c.."]")
	end)
	s = string.gsub(s,"&#(%d-);", function(c)
--	  log.dbg("html2txt &#(%d-); substitution: "..tostring(c))
      if tonumber(c) < 256 then
	    return string.char(c)
	  end
	  -- FIXME: handle unicode characters?
	  return "?"
	end)
	if all then
		local n = 1
		while n > 0 do 
			s,n = string.gsub(s,"^%s*\n%s*\n","\n")
		end
	end
	return s
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
-- Converts a plain text string to a \r\n encoded message, ready to send as
-- a RETR response.
-- 
function Private.txt2mailnotencoded(s)
	s = string.gsub(s,'\r','')
	s = string.gsub(s,'\n','\r\n')
	s = string.gsub(s,'\r\n%.\r\n','\r\n..\r\n')
	if string.sub(s,-2,-1) ~= '\r\n' then
		s = s .. '\r\n'
	end
	return s
end

function Private.txt2mailquotedprintable(s)
	local d = Private.quoted_printable_encode(s)
	return Private.txt2mailnotencoded(d)
end

function Private.tablesize(t)
	local i = 0
	for _ in pairs(t) do i = i + 1 end
	return i
end

--<==========================================================================>--
module("mimer",package.seeall)

---
-- Converts a plain text string to a \r\n encoded message, ready to send as
-- a RETR response.
-- 
function txt2mail(s)
	return Private.txt2mailnotencoded(s)
end

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
-- @param inlineids table a table { ["filename"] = "content-Ids" } which
-- 	  contains the ids for inline attachments (default {}).
-- @param text_encoding string default "iso-8859-1"	  
function pipe_msg(headers,body,body_html,base_uri,attachments,browser,send_cb,inlineids,text_encoding)
	attachments = attachments or {}
	inlineids = inlineids or {}
	text_encoding = text_encoding or "iso-8859-1"
	local rc = nil

	if not (body or body_html) then
		error("Mimer needs either body or body_html. "..
			"Email wasn't processed.")
		return
	end

	local isAlt, isMultipart, isAttached, boundary, cType

	isAttached = Private.tablesize(attachments) >= 
		     Private.tablesize(inlineids) 
	    	 and Private.tablesize(attachments) >0
	body = body or html2txtmail(body_html,base_uri)
	isAlt = body and body_html
	isMultipart = next(attachments) ~= nil or isAlt 
	boundary = Private.randomize_boundary()

	if isAttached then
		if next(inlineids) == nil then
			cType = "multipart/mixed"
		else
			cType = "multipart/related"
		end
	else
		if isAlt then
			cType = "multipart/alternative"
		else
			cType ="text/plain"
		end
	end
	
	local mime
	if isMultipart then
		mime = 'boundary="' .. boundary .. '"\r\n'
	else
		mime =	"charset=\""..text_encoding.."\"\r\n"..
			"Content-Transfer-Encoding: quoted-printable\r\n\r\n"
	end
	mime = "MIME-Version: 1.0 (produced by FreePOPS/MIMER)\r\n" ..
		"Content-Type: " .. cType .. "; " .. mime
	
	-- send headers
	headers=remove_lines_in_proper_mail_header(headers, 
		{"content%-type","MIME%-Version"})
	rc = send_cb(headers .. mime .. "\r\n")
	if rc ~= nil then return end
	
	if not isMultipart then
		rc = send_cb(Private.txt2mailquotedprintable(body) .. "\r\n")
		if rc ~= nil then return end
	else
		-- send the body
		if isAlt and isAttached then
			rc = send_cb("--"..boundary.."\r\n")
			if rc ~= nil then return end

			rc = Private.send_alternative(text_encoding,
				Private.txt2mailquotedprintable(body),
				Private.txt2mailquotedprintable(body_html),
				send_cb,nil)
			if rc ~= nil then return end	
		elseif isAlt then
			rc = Private.send_alternative(text_encoding,
				Private.txt2mailquotedprintable(body),
				Private.txt2mailquotedprintable(body_html),
				send_cb,boundary)
			if rc ~= nil then return end	
		else
			rc = send_cb("--"..boundary.."\r\n"..
				"Content-Type: text/plain; "..
					"charset=\""..text_encoding.."\"\r\n"..
				"Content-Disposition: inline\r\n" ..
				"Content-Transfer-Encoding: "..
					"quoted-printable\r\n"..
				"\r\n"..
				Private.txt2mailquotedprintable(body)..
				"\r\n")
			if rc ~= nil then return end	
		end
	
		rc = table.foreach(attachments,
			Private.attach_it(browser,boundary,send_cb,inlineids))
		if rc ~= nil then return end
		
		-- close message
		rc = send_cb("--"..boundary.."--".."\r\n")
		if rc ~= nil then return end
	end
end

---
-- Tryes to convert an HTML document to a human readable plain text.
--
function html2txtmail(s,base_uri)
	return Private.html2txt(s,base_uri,Private.html_coded,Private.html_tags,true)
end

---
-- Converts an HTML document to a plain text file, removing tags and
-- unescaping &XXXX; sequences.
--
function html2txtplain(s,base_uri)
	return Private.html2txt(s,base_uri,Private.html_coded,
		Private.html_tags_plain,false)
end

---
--Removes unwanted tags from an html string.
--@param p table a list of tags in this form {"head","p"}.
--@return string the cleaned html.
function remove_tags(s,p)
	table.foreachi(p,function(k,v)
		s = string.gsub(s,Private.domatch("<%s*[!/]?",v,"[^>]*>"),"")
	end)
	return s
end

---
-- Deletes some fields in a mail header.
--@param s string a valid mail header.
--@param p table a list of mail headers in this form {"content%-type","date"} 
-- 	(with - escaped with %).
--@return string the cleaned header.
function remove_lines_in_proper_mail_header(s,p)
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
				local x = string.match (l,
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
function callback_mangler(f) 
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

---
-- Converts all unicode characters (>127) into UTF-8 character sets
--@param unicode ASCII or unicoded string
--@return a UTF-8 representation
function encodeUTF8(unicode)

   local math = math
   local utf8 = ""

   for i=1,string.len(unicode) do
      local v = string.byte(unicode,i)
      local n, s, b = 1, "", 0
      if v >= 67108864 then n = 6; b = 252
      elseif v >= 2097152 then n = 5; b = 248
      elseif v >= 65536 then n = 4; b = 240
      elseif v >= 2048 then n = 3; b = 224
      elseif v >= 128 then n = 2; b = 192
      end
      for i = 2, n do
         local c = math.mod(v, 64); v = math.floor(v / 64)
         s = string.char(c + 128)..s
      end
      s = string.char(v + b)..s
      utf8 = utf8..s
   end

   return utf8
end

---
-- Converts all UTF-8 character sets to unicode/ASCII characters
-- to generate ISO-8859-1 email bodies etc.
--@param utf8 UTF-8 encoded string
--@return a ASCII/ISO-8859-1 8-bit conform string
function decodeUTF8(utf8)

   local unicode = ""
   local mod = math.mod

   local pos = 1
   while pos < string.len(utf8)+1 do

      local v = 1
      local c = string.byte(utf8,pos)
      local n = 0

      if c < 128 then v = c
      elseif c < 192 then v = c
      elseif c < 224 then v = mod(c, 32) n = 2
      elseif c < 240 then v = mod(c, 16) n = 3
      elseif c < 248 then v = mod(c,  8) n = 4
      elseif c < 252 then v = mod(c,  4) n = 5
      elseif c < 254 then v = mod(c,  2) n = 6
      else v = c end

      for i = 2, n do
         pos = pos + 1
         c = string.byte(utf8,pos)
         v = v * 64 + mod(c, 64)
      end

      pos = pos + 1
      if v < 255 then unicode = unicode..string.char(v) end

   end

   return unicode
end

---
-- Decodes a quoted printable string (7-bit) into an 8-bit encoded string
--@param qp quoted printable string
--@return a ASCII/ISO-8859-1 8-bit conform string
function decodeQuotedPrintable(qp)

   local plain = string.gsub(qp,"=(%w%w)", function (c)
      local num = tonumber("0x"..c, 16)
      if num > 255 then return "" end
      return string.char(num)
   end)

   return plain
end
