-- ************************************************************************** --
--  FreePOPs @foo.xx webmail interface
-- 
--  $Id$
-- 
--  Released under the GNU/GPL license
--  Written by Me <Me@myhouse>
-- ************************************************************************** --

PLUGIN_VERSION = "0.0.1"
PLUGIN_NAME = "Foo web mail"

foo_globals= {
	username="nothing",
	password="nothing"
}

-- ************************************************************************** --
-- 
-- This is the interface to the external world. These are the functions 
-- that will be called by FreePOPs.
--
-- param pstate is the userdata to pass to (set|get)_popstate_* functions
-- param username is the mail account name
-- param password is the account password
-- param msg is the message number to operate on (may be decreased dy 1)
-- param pdata is an opaque data for popserver_callback(buffer,pdata) 
-- 
-- return POPSERVER_ERR_*
-- 
-- ************************************************************************** --

-- Is called to initialize the module
function init(pstate)
	freepops.export(pop3server)
	
	log.dbg("FreePOPs plugin '"..
		PLUGIN_NAME.."' version '"..PLUGIN_VERSION.."' started!\n")

	-- the serialization module
	--if freepops.dofile("serialize.lua") == nil then 
	--	return POPSERVER_ERR_UNKNOWN 
	--end 

	-- the browser module
	if freepops.dofile("browser.lua") == nil then 
		return POPSERVER_ERR_UNKNOWN 
	end
	
	-- checks on globals
	freepops.set_sanity_checks()
		
	return POPSERVER_ERR_OK
end
-- -------------------------------------------------------------------------- --
-- Must save the mailbox name
function user(pstate,username)
	foo_globals.username = username
	print("*** the user wants to login as '"..username.."'")
	return POPSERVER_ERR_OK
end
-- -------------------------------------------------------------------------- --
-- Must login
function pass(pstate,password)
	foo_globals.password = password
	print("*** the user inserted '"..password..
		"' as the password for '"..foo_globals.username.."'")
	
	-- create a new browser
	local b = browser.new()
	-- store the browser object in globals
	foo_globals.browser = b

	-- create the data to post
	local post_data = string.format("username=%s&password=%s",
		foo_globals.username,foo_globals.password)
	-- the uri to post to
	local post_uri = "http://localhost:3000/"

	-- post it
	local file,err = nil, nil
	file,err = b:post_uri(post_uri,post_data)

	print("we received this webpage: ".. file)

	-- search the session ID
	local _,_,id = string.find(file,"session_id=(%w+)")

	if id == nil then 
		return POPSERVER_ERR_AUTH

	foo_globals.session_id = id

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
end
-- -------------------------------------------------------------------------- --
-- Fill the number of messages and their size
function stat(pstate)
end
-- -------------------------------------------------------------------------- --
-- Fill msg uidl field
function uidl(pstate,msg)
end
-- -------------------------------------------------------------------------- --
-- Fill all messages uidl field
function uidl_all(pstate)
end
-- -------------------------------------------------------------------------- --
-- Fill msg size
function list(pstate,msg)
end
-- -------------------------------------------------------------------------- --
-- Fill all messages size
function list_all(pstate)
end
-- -------------------------------------------------------------------------- --
-- Unflag each message merked for deletion
function rset(pstate)
end
-- -------------------------------------------------------------------------- --
-- Mark msg for deletion
function dele(pstate,msg)
end
-- -------------------------------------------------------------------------- --
-- Do nothing
function noop(pstate)
end
-- -------------------------------------------------------------------------- --
-- Get first lines message msg lines, must call 
-- popserver_callback to send the data
function top(pstate,msg,lines,pdata)
end
-- -------------------------------------------------------------------------- --
-- Get message msg, must call 
-- popserver_callback to send the data
function retr(pstate,msg,pdata)
end

-- EOF
-- ************************************************************************** --
