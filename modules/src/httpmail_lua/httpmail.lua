--============================================================================--
-- This is part of FreePOPs (http://freepops.sf.net) released under GNU/GPL  
--============================================================================--



httpmail = {}

--httpmail.debug = true
httpmail.debug = false 

-- ------------------------------------------------------------------------ --
-- this is the xml <---> Txml namespace conversion table
httpmail.Txml_convmap = {
	["DAV:"]="D",
	["urn:schemas:httpmail:"]="hm",
	["urn:schemas:mailheader:"]="h"
}

-- ---------------------------------------------------------------------- --
-- this should list props for inbox and the root of folders...
--  but the server returns always everithing
httpmail.R_folder_root_Txml = 
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
httpmail.R_folder_root_header = {
	"Depth: 0", "Brief: t", -- "Accept-Charset: UTF-8", --ignored 
}
httpmail.R_folder_root_xml = table2xml.table2xml(httpmail.R_folder_root_Txml,":")

-- ---------------------------------------------------------------------- --
-- this should list all folders, giving theyr URIs, but lists everithing
--  as usual
httpmail.R_folder_list_Txml = 
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
httpmail.R_folder_list_header = {
	"Depth: 1", -- "Depth: 1,noroot", 
	"Brief: t", -- "Accept-Charset: UTF-8", --ignored
}
httpmail.R_folder_list_xml = table2xml.table2xml(httpmail.R_folder_list_Txml,":")

-- ---------------------------------------------------------------------- --
-- list the folder contents, as usual the server does what he wants
--  and _need_ the xmlns:m="urn:schemas:mailheader:" or it fails ;)
httpmail.R_folder_content_Txml = {
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
httpmail.R_folder_content_header = {
	"Depth: 1", -- "Depth: 1,noroot", 
	"Brief: t", -- "Accept-Charset: UTF-8", --ignored
}
httpmail.R_folder_content_xml = table2xml.table2xml(httpmail.R_folder_content_Txml,":")

-- this function simply gets all the uris in the response
function httpmail.href_of_Txml(answer)
	local uri = {}
	xml2table.forach_son(answer,"D__response",
		function(t) table.insert(uri,t.D__href._content) end)
	return uri
end

function httpmail.propfind(b,uri,post,header)
	if httpmail.debug then
		print("sending",uri,post)
	end
	local ans,err = b:custom_post_uri(uri,"PROPFIND",post,header)
	return ans,err
end

function httpmail.delete(b,uri,extraheader)
	local ans,err = b:custom_get_uri(uri,"DELETE",extraheader)
	return ans,err
end

function httpmail.get(b,uri,extraheader)
	local ans,err = b:get_uri(uri,extraheader)
	return ans,err
end

function httpmail.pipe(b,uri,cb,extraheader)
	return b:pipe_uri(uri,cb,extraheader)
end

function httpmail.safe_traverse(t,...)
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

-- returns the base uri for folders
function httpmail.login(b,uri,username,password,authbasic)
	b.curl:setopt(curl.OPT_USERPWD,username..":"..password)
	if not authbasic then
		-- this is untested
		b.curl:setopt(curl.OPT_HTTPAUTH,curl.AUTH_DIGEST)
	end
	local ans,err = httpmail.propfind(b,uri,
		httpmail.R_folder_root_xml,httpmail.R_folder_root_header)
	if ans ~= nil then
		local answer,msg,_,_ = 
			xml2table.xml2table(ans,httpmail.Txml_convmap,"UTF-8")
		
		if answer == nil then
			return answer,msg
		end

		local base_uri,err = httpmail.safe_traverse(answer,
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

-- retuns a table of {uri,name}
function httpmail.folderlist(b,uri)
	local ans,err =httpmail.propfind(b,uri,
		httpmail.R_folder_list_xml,httpmail.R_folder_list_header)
	if ans ~= nil then
		local answer,msg,_,_ = 
			xml2table.xml2table(ans,httpmail.Txml_convmap,"UTF-8")
	
		if answer == nil then
			return answer,msg
		end
			
		local folders = {}
		xml2table.forach_son(answer,"D__response",
		function(t)
			local uri = 
				httpmail.safe_traverse(t,"D__href","_content")
			local name = (
				(httpmail.safe_traverse(t,
					"D__propstat",
					"D__prop",
					"D__displayname")) or
				(httpmail.safe_traverse(t,
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

-- returns a table of {uri,size}
function httpmail.stat(b,uri)
	local ans,err =httpmail.propfind(b,uri,
		httpmail.R_folder_content_xml,httpmail.R_folder_content_header)
	if ans ~= nil then
		local answer,msg,_,_ = 
			xml2table.xml2table(ans,httpmail.Txml_convmap,"UTF-8")
		if answer == nil then
			return answer,msg
		end
		
		local mails = {}

		xml2table.forach_son(answer,"D__response",
		function(t)
			local uri = 
				httpmail.safe_traverse(t,"D__href","_content")
			local size = httpmail.safe_traverse(t,
					"D__propstat",
					"D__prop",
					"D__getcontentlength",
					"_content")
			table.insert(mails,{uri=uri,size=size})
		end)
		
		return mails,nil
	else
		return ans,err
	end
end

-- eof
