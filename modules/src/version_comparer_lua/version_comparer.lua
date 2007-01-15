---
-- version_comparer functions.
-- This module implements a smart version comparer.

MODULE_VERSION = "0.0.1"
MODULE_NAME = "version_comparer"
MODULE_REQUIRE_VERSION = "0.2.0"
MODULE_LICENSE = "GNU/GPL"
MODULE_URL = "http://www.freepops.org/download.php?module=version_comparer.lua"
MODULE_HOMEPAGE = "http://www.freepops.org/"


--============================================================================---- This is part of FreePOPs (http://www.freepops.org) released under GNU/GPL
--============================================================================--


local entries = {
	{rex="^([%a]+)",type="token"},
	{rex="^([%d]+)",type="token"},
	{rex="^(%.)",type="spacer"},
	{rex="^(%-)",type="spacer"},
	{rex="^(%:)",type="spacer"},
	{rex="^(%+)",type="spacer"}
}

local private = {}

function private.next_token(s)
	local s1, tok = nil, nil
	if s == nil then return nil, nil end
	table.foreachi(entries, function(_, e)
		local from, _, capture = string.find(s, e.rex)
		if capture ~= nil then
			s1 = string.sub(s,from + string.len(capture),-1)
			tok = {val=capture, type=e.type}
			return true -- stop looping
		end
	end)
	return s1, tok
end

function private.compare_token(tok1, tok2)
	if tok1 == nil and tok2 == nil then return 0 end
	if tok1 == nil and tok2 ~= nil then return -1 end
	if tok1 ~= nil and tok2 == nil then return 1 end
	if tok1.type == "spacer" and tok1.type == "spacer" then 
		if tok1.val == tok2.val then return 0 end
		return nil
	end
	if tok1.type == "spacer" and tok1.type ~= "spacer" then return 1 end
	if tok1.type ~= "spacer" and tok1.type == "spacer" then return -1 end
	local ty1 = tonumber(tok1.val)
	local ty2 = tonumber(tok2.val)
	if ty1 == nil or ty2 == nil then
		if tok1.val == tok2.val then return 0 end
		if tok1.val <  tok2.val then return -1 end
		if tok1.val >  tok2.val then return 1 end
	else
		if ty1 - ty2 == 0 then return 0 end
		if ty1 - ty2 <  0 then return -1 end
		if ty1 - ty2 >  0 then return 1 end
	end
end

--============================================================================--

module("version_comparer",package.seeall)

---
-- Compare version1 and version2.
-- @param version1 string.
-- @param version1 string.
-- @return number 0 if version1 == version2, 
-- 		-1 if version1 < version2, 
-- 		1 if version1 > version2, nil if incomparable.
function compare_versions(version1, version2)
	local v1, tok1 = private.next_token(version1)	
	local v2, tok2 = private.next_token(version2)	

	local rc = private.compare_token(tok1, tok2)
	if rc == 0 and (v1 ~= nil or v2 ~= nil) then
		return compare_versions(v1, v2)
	else
		return rc
	end
end

--function test()
--	local todo = {
--		{v1="1",		v2="1",			rc=0},
--		{v1="2",		v2="1",			rc=1},
--		{v1="1",		v2="2",			rc=-1},
--		{v1="1.0.1",		v2="1.0.1b",		rc=-1},
--		{v1="1.0.2",		v2="1.0.1",		rc=1},
--		{v1="1.1.0",		v2="1.0.99",		rc=1},
--		{v1="1.99.0",		v2="1.9.1",		rc=1},
--		{v1="1.0+p2",		v2="1.0+p1",		rc=1},
--		{v1="1.0a-1",		v2="1.0-2",		rc=1},
--		{v1="1.9a-2",		v2="1.99-1",		rc=-1},
--	}
--	table.foreach(todo, function(_, v)
--		local rc = compare_versions(v.v1, v.v2)
--		if rc ~= v.rc then
--			print("FAIL", v.v1, "Vs", v.v2)
--		else
--			print("OK", v.v1, "Vs", v.v2)
--		end
--	end)
--end
--test()
