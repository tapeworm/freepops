---
-- Module to emulate the old psock library on top of luasoocket:
-- line oriented client sockets.

MODULE_VERSION = "0.2.7"
MODULE_NAME = "psock"
MODULE_REQUIRE_VERSION = "0.2.7"
MODULE_LICENSE = "GNU/GPL"
MODULE_URL = "http://www.freepops.org/download.php?module=psock.lua"
MODULE_HOMEPAGE = "http://www.freepops.org/"

--============================================================================--
-- This is part of FreePOPs (http://www.freepops.org) released under GNU/GPL  
--============================================================================--

local socket = require "socket"
local log = require "log"
local string = require "string"

module("psock")

---
-- Creates and connect a socket.
-- @param host string The host you want to connect to.
-- @param port number The port you want to connect to.
-- @param verbose bool True to log every message.
-- @return userdata The socket object, or nil on failure;
-- the returned object has a send(s) method that sends s.."\r\n" 
-- and returns a positive number on success; and a recv method,
-- returning a string with '\r\n' stripped on success or nil on 
-- filure.
function connect(host, port, verbose)
	local handler = socket.tcp()
	local rc, err = handler:connect(host,port)
	if rc ~= 1 then 
		log.error_print(err) 
		return nil, err
	end
	return {handler = handler,
		send = function(self,s)
			local msg = s..'\r\n'
			if verbose then log.dbg('SEND: '..msg) end
			local len = string.len(msg)
			local i,err,j=1,nil,1
			repeat 
				j, err = self.handler:send(msg,i)
				if j then i=i+j end
			until (j == nil or i > len)
			if not j then return -1 else return len end
		end,
		recv = function(self)
			local data = self.handler:receive('*l')
			if verbose then 
				log.dbg('RECV: '..(data or 'nil')..'\r\n') 
			end
			return data
		end}
end

