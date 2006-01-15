---
-- HTTPMAIL, what else.
--
-- This module implements the HTTPMAIL protocol on top of the browser
-- module and the xml2table/table2xml modules.
 
require("xml2table")
require("table2xml")

local Private = {}

--============================================================================--
-- This is part of FreePOPs (http://www.freepops.org) released under GNU/GPL  
--============================================================================--

--Private.debug = true
Private.debug = false 

---
-- This is the xml to Txml namespace conversion table used by xml2table.
Private.Txml_convmap = {
	["DAV:"]="D",
	["urn:schemas:httpmail:"]="hm",
	["urn:schemas:mailheader:"]="h",
	["http://schemas.microsoft.com/hotmail/"]="m",
	["urn:schemas:contacts:"]="c",
	["urn:schemas:calendar:"]="cal"
}

Private.default_charset = "iso-8859-1"

---
-- This should list props for inbox and the root of folders.
-- The server returns always everithing.
Private.R_folder_root_Txml = 
{ tag_name = "D__propfind",
  xmlns__D = "Dav:",
  xmlns__hm = "urn:schemas:httpmail:",
  { tag_name = "D__prop",
    --{tag_name = "hm__contacts"}, -- useless
    --{tag_name = "hm__inbox"}, -- useless
    {tag_name = "hm__msgfolderroot"},
    --{tag_name = "hm__outbox"}, -- useless
    --{tag_name = "hm__sendmsg"}, -- useless
    --{tag_name = "hm__sentitems"}, -- useless
    --{tag_name = "hm__deleteditems"}, -- useless
    --{tag_name = "hm__drafts"}, -- useless
  }
}
---
-- The corresponding extra header.
Private.R_folder_root_header = {
	"Depth: 0", "Brief: t", -- "Accept-Charset: UTF-8", --ignored 
}
---
-- The xml of table2xml(R_folder_root_Txml).
Private.R_folder_root_xml = 
	table2xml.table2xml(Private.R_folder_root_Txml,":")

---
-- This should list all folders, giving theyr URIs.
-- but lists everithing as usual.
Private.R_folder_list_Txml = 
{ tag_name = "D__propfind",
  xmlns__D = "Dav:",
  xmlns__hm = "urn:schemas:httpmail:",
  { tag_name = "D__prop",
    --{tag_name = "D__isfolder"}, -- useless
    {tag_name = "D__displayname"},
    --{tag_name = "D__hassubs"}, -- useless
    --{tag_name = "D__nosubs"}, -- useless
    --{tag_name = "D__visiblecount"}, -- useless
    --{tag_name = "hm__unreadcount"}, -- useless
    {tag_name = "hm__special"}, 
  }
}
---
-- The corresponding header.
Private.R_folder_list_header = {
	"Depth: 1", -- "Depth: 1,noroot", 
	"Brief: t", -- "Accept-Charset: UTF-8", --ignored
}
---
-- The xml of R_folder_list_Txml.
Private.R_folder_list_xml = 
	table2xml.table2xml(Private.R_folder_list_Txml,":")

---
-- List the folder contents.
-- As usual the server does what he wants
--  and _need_ the xmlns:m="urn:schemas:mailheader:" or it fails ;).
Private.R_folder_content_Txml = {
  tag_name  = "D__propfind",
  xmlns__D  = "Dav:",
  xmlns__hm = "urn:schemas:httpmail:",
  -- if I omit this the server complains "not found".. ha ha ha 
  -- really DAV compliant IIS
  xmlns__m  = "urn:schemas:mailheader:",
  { tag_name = "D__getcontentlength"},
  --{ tag_name = "hm__read"}, -- useless
  --{ tag_name = "m__hasattachment" }, -- useless
  --{ tag_name = "m__to" }, -- useless
  --{ tag_name = "m__from" }, -- useless
  --{ tag_name = "m__subject" }, -- useless
  --{ tag_name = "m__date" }, -- useless
}
---
-- The corresponding header.
Private.R_folder_content_header = {
	"Depth: 1", -- "Depth: 1,noroot", 
	"Brief: t", -- "Accept-Charset: UTF-8", --ignored
}
---
-- The xml of table2xml.
Private.R_folder_content_xml = 
	table2xml.table2xml(Private.R_folder_content_Txml,":")

--<=========================================================================>--
	
module("httpmail")

---
-- Resources mentioned in the answer.
-- This function simply gets all the uris in the response.
-- @param answer table a Txml object.
-- @return table a uri list.
function href_of_Txml(answer)
	local uri = {}
	xml2table.forach_son(answer,"D__response",
		function(t) table.insert(uri,t.D__href._content) end)
	return uri
end

---
-- Executes a proprind dav request.
-- Tailors the browser b to a DAV request.
-- @param header table is in the browser fashion extra header.
-- @param post string is an XML string.
-- @return string the returned page.
function propfind(b,uri,post,header)
	if Private.debug then
		print("HTTPMAIL: sending (uri,post): ",uri,post)
	end
	local ans,err = b:custom_post_uri(uri,"PROPFIND",post,header)
	if Private.debug then
		print("HTTPMAIL: received (err,ans): ",err,ans)
	end
	return ans,err
end

---
-- Deletes a dav resource, use this for mails.
function delete(b,uri,extraheader)
	local ans,err = b:custom_get_uri(uri,"DELETE",extraheader)
	return ans,err
end

---
-- Retrives a dav resuorce, use this for mails.
function get(b,uri,extraheader)
	local ans,err = b:get_uri(uri,extraheader)
	return ans,err
end

---
-- Avoids wrong entities.
-- @param s string the ugly XML.
-- @return string the cleaned XML.
function clean_entities(s)
	local function content_clean(s, start_tag, stop_tag)
		return string.gsub(s,start_tag .. "(.-)" .. stop_tag,function(c)
			local s = nil
			s = string.gsub(c,"<","&lt;")
			s = string.gsub(s,">","&gt;")
			return start_tag .. s .. stop_tag
		end)
	end
	s = string.gsub(s,"&iexcl;","!")
	s = string.gsub(s,"&nbsp;"," ")
	s = string.gsub(s,"& ","&amp;")
	s = string.gsub(s,"&([^;][^;][^;][^;][^;][^;])$","&amp;%1")
	s = string.gsub(s,"&([^;][^;][^;][^;][^;])$","&amp;%1")
	s = string.gsub(s,"&([^;][^;][^;][^;])$","&amp;%1")
	s = string.gsub(s,"&([^;][^;][^;])$","&amp;%1")
	s = string.gsub(s,"&([^;][^;])$","&amp;%1")
	s = string.gsub(s,"&([^;])$","&amp;%1")
	s = string.gsub(s,"&$","&amp;")
	s = string.gsub(s,"&([^;][^;][^;][^;][^;][^;][^;])","&amp;%1")
	-- this is a REAL shit used only by jubii.dk
	s = content_clean(s, "<m:from>", "</m:from>")
	return s
end

---
-- Pipes a dav resource, works as the pipe_uri method of the browser object.
function pipe(b,uri,cb,extraheader)
	return b:pipe_uri(uri,cb,extraheader)
end

---
-- Descends a Txml tree.
-- A correct call is 
-- local base_uri,err = httpmail.safe_traverse(answer,
--  "D__response", "D__propstat", "D__prop", "hm__msgfolderroot", "_content").
-- @return string the content, or nil and an error message.
function safe_traverse(t,...)
	local err = "Stopping at "
	for _,f in ipairs(arg) do
		if t ~= nil then
			t = t[f]
			err = err .. "." .. f
		else
			return nil,err
		end
	end
	return t,nil
end

---
-- Basic HTTP authentication (plain base64(username:pwd)).
LOGIN_BASIC = 1 

---
-- Digest HTTP authentication (untested)
LOGIN_DIGEST = 2

---
-- HTTPMAIL login implementation.
-- Finds where the mailboxes are rooted.
-- @param auth number one of httpmail.LOGIN_*.
-- @return string base_uri of the folders, and err if nil.
function login(b,uri,username,password,auth)
	b.curl:setopt(curl.OPT_USERPWD,username..":"..password)
	if auth == LOGIN_DIGEST then
		b.curl:setopt(curl.OPT_HTTPAUTH,curl.AUTH_DIGEST)
	elseif auth ~= LOGIN_BASIC then
		return nil, "httpmail.login: auth must be httpmail.LOGIN_*"
	end
	local ans,err = propfind(b,uri,
		Private.R_folder_root_xml,Private.R_folder_root_header)
	if ans ~= nil then
		local answer,msg,_,_ = 
			xml2table.xml2table(clean_entities(ans),
				Private.Txml_convmap,
				Private.default_charset)
		
		if answer == nil then
			return answer,msg
		end

		local base_uri,err = safe_traverse(answer,
			"D__response",
			"D__propstat",
			"D__prop",
			"hm__msgfolderroot",
			"_content")
		return base_uri,err
	else
		return ans,err
	end
end

---
-- HTTPMAIL folder disocevery implementation.
-- currently finds only the first level folders and not subfolders.
-- @return table like {{uri="uri",name="name"},...,{uri="uri",name="name"}}.
function folderlist(b,uri)
	local ans,err =propfind(b,uri,
		Private.R_folder_list_xml,Private.R_folder_list_header)
	if ans ~= nil then
		local answer,msg,_,_ = 
			xml2table.xml2table(clean_entities(ans),
				Private.Txml_convmap,
				Private.default_charset)
	
		if answer == nil then
			return answer,msg
		end
			
		local folders = {}
		xml2table.forach_son(answer,"D__response",
		function(t)
			local uri = 
				safe_traverse(t,"D__href","_content")
			local name = (
				(safe_traverse(t,
					"D__propstat",
					"D__prop",
					"D__displayname")) or
				(safe_traverse(t,
					"D__propstat",
					"D__prop",
					"hm__special"))
				)._content
			table.insert(folders,{name=name,uri=uri})
		end)
		return folders,nil
	else
		return ans,err
	end

end

---
-- HTTPMAIL stat implementation.
-- Does a STAT for the folder pointed by uri.
-- @return table like {{uri="uri",size=1234},...,{uri="uri",size=1234}}.
function stat(b,uri)
	local ans,err =propfind(b,uri,
		Private.R_folder_content_xml,Private.R_folder_content_header)
	if ans ~= nil then
		local answer,msg,_,_ = 
			xml2table.xml2table(clean_entities(ans),
				Private.Txml_convmap,
				Private.default_charset)
		if answer == nil then
			return answer,msg
		end
		
		local mails = {}

		xml2table.forach_son(answer,"D__response",
		function(t)
			if t == nil then return end
			local uri = 
				safe_traverse(t,"D__href","_content")
			local size = safe_traverse(t,
					"D__propstat",
					"D__prop",
					"D__getcontentlength",
					"_content") or 1
			table.insert(mails,{uri=uri,size=size})
		end)
		
		return mails,nil
	else
		return ans,err
	end
end

-- eof
