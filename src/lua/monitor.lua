-- ************************************************************************** --
--  FreePOPs @--put here domain-- webmail interface
-- 
--  $Id$
-- 
--  Released under the GNU/GPL license
--  Written by --put Name here-- <--put email here-->
-- ************************************************************************** --

PLUGIN_VERSION = "0.0.1"
PLUGIN_NAME = "monitor"
PLUGIN_REQUIRE_VERSION = "0.2.6"
PLUGIN_LICENSE = "GNU/GPL"
PLUGIN_URL = "http://www.freepops.org"
PLUGIN_HOMEPAGE = "http://www.freepops.org/download.php?module=monitor.lua"
PLUGIN_AUTHORS_NAMES = {"Enrico Tassi"}
PLUGIN_AUTHORS_CONTACTS = {"gareuselesinge@users.sourceforge.net"}
PLUGIN_DOMAINS = {"@monitor"}
PLUGIN_REGEXES = {}
PLUGIN_PARAMETERS = { 
	{name="action", 
	 description={en="one of: new_connections"}},
}
PLUGIN_DESCRIPTIONS = {
	en=[[Monitors the internal state and statistics of freepops]]
}

internal_state = {
	stat_done = false,
	username=nil,
}

function init(pstate)
	freepops.export(pop3server)
	
	log.dbg("FreePOPs plugin '"..
		PLUGIN_NAME.."' version '"..PLUGIN_VERSION.."' started!\n")

	require("stats")
	require("stringhack")
	
	-- checks on globals
	freepops.set_sanity_checks()
		
	return POPSERVER_ERR_OK
end
-- -------------------------------------------------------------------------- --
-- Must save the mailbox name
function user(pstate,username)
	internal_state.username = username
	return POPSERVER_ERR_OK
end
-- -------------------------------------------------------------------------- --
-- Must login
function pass(pstate,password)
	return POPSERVER_ERR_OK
end
-- -------------------------------------------------------------------------- --
-- Must quit without updating
function quit(pstate)
	return POPSERVER_ERR_OK
end
-- -------------------------------------------------------------------------- --
-- Update the mailbox status and quit
function quit_update(pstate)
	return POPSERVER_ERR_OK
end

function uidl(pstate,msg)
        return common.uidl(pstate,msg)
end
function uidl_all(pstate)
        return common.uidl_all(pstate)
end
function list(pstate,msg)
        return common.list(pstate,msg)
end
function list_all(pstate)
        return common.list_all(pstate)
end
function rset(pstate)
        return common.rset(pstate)
end
function dele(pstate,msg)
        return common.dele(pstate,msg)
end
function noop(pstate)
        return common.noop(pstate)
end
function stat(pstate)
	if internal_state.stat_done then
		return POPSERVER_ERR_OK
	else
		set_popstate_nummesg(pstate,1)
		set_mailmessage_size(pstate,1,100)
		set_mailmessage_uidl(pstate,1,tostring(os.date("%s")))
	end
end

function top(pstate,msg,lines,pdata)
	return retr(pstate,msg,pdata)
end

function retr(pstate,msg,pdata)
	local a = stringhack.new()
	local function send(s) 
		s = a:dothack(s).."\0"
		popserver_callback(s,pdata)
	end
	send("Subject: Monitor\r\n")
	send("From: freepops@monitor\r\n")
	send("To: "..internal_state.username.."\r\n")
	send("\r\n")
	send("new_connection: "..tostring(stats.new_connection()).."\r\n")

	return POPSERVER_ERR_OK
end

function assert_ok(s,ifnot)
	if (not(string.match(s or "","^+OK"))) then
		print(ifnot)
		error(ifnot)
	end
end

function main(args)
	require "psock"
	require "stringhack"
	require "stats"

	local host = args[1] or "localhost"
	local port = args[2] or 2000
	local command = args[3] or "help"

	if command == "help" then
		print("usage: freepopsd -e monitor host port command params")
		print()
		print("defaults are host=localhost port=2000 command=help")
		print()
		print("available commands:")
		for k,_ in pairs(stats) do
			print('\t'..k)
		end
		print('\thelp')
		return 1
	end


	s = psock.connect(host,port,psock.NONE)
	if s == nil then
		print("Error connecting to "..host.." port "..port)
		return 1
	end
	assert_ok(s:recv(), "Not a POP3 server")
	s:send("user foo@monitor?command="..command)
	assert_ok(s:recv(), "Failed 'user'")
	s:send("pass xxxx")
	assert_ok(s:recv(), "Failed 'pass'")
	s:send("retr 1")
	assert_ok(s:recv(), "Failed 'retr'")

	local lines = function() return s:recv() end

	for l in lines do
		if l == "." then
			s:send("quit")
			assert_ok(s:recv() ,"Failed 'quit'") 
			break
		end
		print(l)
	end

	return 0
end
