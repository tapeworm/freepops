prefix = "modules/include/"
__dofile = dofile
dofile = function(s)
	__dofile(prefix..s)
end
dofile("browser.lua")
dofile("table2xml.lua")
dofile("xml2table.lua")

lycos_uri = "http://webdav.lycos.it/httpmail.asp"


b = browser.new()
--b:verbose_mode()

first = 
{ tag_name = "D__propfind",
  xmlns__D = "Dav:",
  xmlns__hm = "urn:schemas:httpmail:",
  { tag_name = "D__prop",
    --{tag_name = "hm__contacts"},
    {tag_name = "hm__inbox"},
    {tag_name = "hm__msgfolderroot"},
    --{tag_name = "hm__outbox"},
    --{tag_name = "hm__sendmsg"},
    --{tag_name = "hm__sentitems"},
    --{tag_name = "hm__deleteditems"},
    --{tag_name = "hm__drafts"},
  }
}
request1 = table2xml.table2xml(first,":")
second = 
{ tag_name = "D__propfind",
  xmlns__D = "Dav:",
  xmlns__hm = "urn:schemas:httpmail:",
  { tag_name = "D__prop",
    {tag_name = "D__isfolder"},
    {tag_name = "D__displayname"},
    {tag_name = "D__hassubs"},
    {tag_name = "D__nosubs"},
    --{tag_name = "D__visiblecount"},
    {tag_name = "hm__unreadcount"},
    {tag_name = "hm__special"},
  }
}
request2 = table2xml.table2xml(second,":")
header1 = {
	"Depth: 0",
	"Brief: t",
	--"Accept-Charset: UTF-8"
}
header2 = {
	"Depth: 1", --"Depth: 1,noroot",
	"Brief: t",
	--"Accept-Charset: UTF-8"
}

convmap = {
	["DAV:"]="D",
	["urn:schemas:httpmail:"]="hm",
	["urn:schemas:mailheader:"]="h"
}

b.curl:setopt(curl.OPT_USERPWD,"gareuselesinge2@lycos.it:supermario")
ans,err = b:custom_post_uri(lycos_uri,"PROPFIND",request1,header1)
--print(ans)
answer,msg,l,c = xml2table.xml2table(ans,convmap,"UTF-8")

print("\n\n\n=========== answer ========",msg,l,c)
base = answer.D__response.D__propstat.D__prop.hm__msgfolderroot._content
print("base = ",base)
ans,err = b:custom_post_uri(base,"PROPFIND",request2,header2)
--print(ans)
answer,msg,l,c = xml2table.xml2table(ans,convmap,"UTF-8")
print("\n\n\n=========== answer ========",msg,l,c)
folder = nil
xml2table.forach_son(answer,"D__response",
	function(t)
		print(t.D__href._content)
		local name = (t.D__propstat.D__prop.D__displayname or
			t.D__propstat.D__prop.hm__special)._content
		print("  name",name)
		print("  unred",
			t.D__propstat.D__prop.hm__unreadcount._content)
		print("  total",
			t.D__propstat.D__prop.D__visiblecount._content)
		print("  has subdirs",
			t.D__propstat.D__prop.D__hassubs._content)
		if name == "inbox" then
			folder = t.D__href._content
		end
	end)

request = {
  tag_name  = "D__propfind",
  xmlns__D  = "Dav:",
  xmlns__hm = "urn:schemas:httpmail:",
  -- if I omit this the server complains "not found".. ha ha ha 
  -- really DAV compliant IIS
  xmlns__m  = "urn:schemas:mailheader:",
  { tag_name = "D__getcontentlength"},
  { tag_name = "hm__read"},
}
request = table2xml.table2xml(request,":")
header = {
	"Depth: 1", --noroot
	"Brief: t",
	--"Accept-Charset: UTF-8"
}
ans,err = b:custom_post_uri(folder,"PROPFIND",request,header)
--print(ans)
answer,msg,l,c = xml2table.xml2table(ans,convmap,"UTF-8")
print("\n\n\n=========== answer ========",msg,l,c)
unread = {}
xml2table.forach_son(answer,"D__response",
	function(t)
		print(t.D__href._content)
		print("  size",
			t.D__propstat.D__prop.D__getcontentlength._content)
		table.insert(unread,t.D__href._content)
		
	end)
ans,err = b:get_uri(unread[1])
print("\n\n\n=========== answer ========",msg,l,c)
print(ans)
--ans,err = b:custom_get_uri(unread[1],"DELETE")
--print(ans)
--answer,msg,l,c = xml2table.xml2table(ans,convmap,"UTF-8")

