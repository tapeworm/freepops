---
-- Commonly used POP3 implementation. 
-- These functions need a <B>stat(pstate)</B> 
-- that checks if it called more than once.

common = {}

--============================================================================--
-- This is part of FreePOPs (http://freepops.sf.net) released under GNU/GPL  
--============================================================================--

---
-- Checks if a message number is in range
--
function common.check_range(pstate,msg)
	local n = get_popstate_nummesg(pstate)
	return msg >= 1 and msg <= n
end

---
-- Fill msg uidl field
function common.uidl(pstate,msg)
	return stat(pstate)
end

---
-- Fill all messages uidl field
function common.uidl_all(pstate)
	return stat(pstate)
end

---
-- Fill msg size
function common.list(pstate,msg)
	return stat(pstate)
end

---
-- Fill all messages size
function common.list_all(pstate,msg)
	return stat(pstate)
end

---
-- Do nothing
function common.noop(pstate)
	return POPSERVER_ERR_OK
end

---
-- Unflag each message merked for deletion
function common.rset(pstate)
	local st = stat(pstate)
	if st ~= POPSERVER_ERR_OK then return st end
	
	for i=1,get_popstate_nummesg(pstate) do
		unset_mailmessage_flag(pstate,i,MAILMESSAGE_DELETE)
	end
	return POPSERVER_ERR_OK
end

---
-- Mark msg for deletion
function common.dele(pstate,msg)
	local st = stat(pstate)
	if st ~= POPSERVER_ERR_OK then return st end

	if not common.check_range(pstate,msg) then
		return POPSERVER_ERR_NOMSG
	end
	set_mailmessage_flag(pstate,msg,MAILMESSAGE_DELETE)
	return POPSERVER_ERR_OK
end

---
-- A common implementation of the retr_cb used in the retr() function
-- @param data userdata the data passed to the retr function.
-- @return function the callback to use with b:pipe_uri().
function common.retr_cb(data)
-- The callbach factory for retr
--
-- A callback factory is a function that generates other functions. both retr
-- and top need a callback. the callback is called when there is some data 
-- to send to the client. this is done with popserver_callback(s,data) 
-- where s is the data and data is the opaque data that is passed to 
-- the retr/top function and is used internally by the popserve callbak. 
-- no need to know what it is, but we have to pass it. 
--
-- The callback function must accept 2 args: the data to send and an optional 
-- error message. if the data is nil it means the err contains the 
-- relative error message. If s is "" it means that the trasmission 
-- ended sucesfully (read: the socket has benn closed correclty). 
-- 
-- Here a is an opaque data structure used by the
-- stringhack module. the stringhack module implements some useful string 
-- manipulation tasks. 
-- tophack keeps track of how many lines have been 
-- processed. If more than lines (we talk of lines of mail body) have 
-- been processed the returned string will be trucated to the 
-- correct line number. 
-- dothack simply does a 'sed s/^\.$/../' but is really hard if the data 
-- is not divided in lines as in our case (ip packets are not line oriented),
-- so it is implemented in C for you. check_stop checks if the lines 
-- amount of lines have already been processed.
--

	local a = stringhack.new()
	
	return function(s,len)
		s = a:dothack(s).."\0"
			
		popserver_callback(s,data)
			
		return len,nil
	end
end

---
-- The callback for top is really similar to the retr, but checks for purging
-- unwanted data and sets globals.lines to -1 if no more lines are needed
-- @param global table you should read common.lua to understand all the fields.
-- @param data userdata the data passed to top().
-- @param truncate bool if we should truncate the commection when done or not.
-- @return function the callback for b:pipe_uri().
--
function common.top_cb(global,data,truncate)
	local purge = false
	
	return function(s,len)
		if purge == true then
			--print("purging: "..string.len(s))
			return len,nil
		end
			
		s=global.a:tophack(s,global.lines_requested)
		s =  global.a:dothack(s).."\0"
			
		popserver_callback(s,data)
	
		global.bytes = global.bytes + len

		-- check if we need to stop (in top only)
		if global.a:check_stop(global.lines_requested) then
			--print("TOP more than needed")
			purge = true
			global.lines = -1
			if(string.sub(s,-2,-1) ~= "\r\n") then
				popserver_callback("\r\n",data)
			end
			if truncate then
				return 0,nil
			else
				return len,nil
			end
		else
			global.lines = global.lines_requested - 
				global.a:current_lines()
			return len,nil
		end
	end
end

---
-- the TOP function used in raw-message webmails
-- @param b table the browser.
-- @param uri string the uri to fetch.
-- @param key string the key used with session module.
-- @param tot_bytes number the size of the mailmessage.
-- @param data userdata the data passed to top(pstate,msg,lines,data).
-- @param truncate bool if the TOP should be implemented with a Range header
-- 	field or should be implemented dropping the connection.
-- @return number POPSERVER_ERR_*.
--
function common.top(b,uri,key,tot_bytes,lines,data,truncate)
	-- build the callbacks --
	
	-- this data structure is shared between callbacks
	local global = {
		-- the current amount of lines to go!
		lines = lines, 
		-- the original amount of lines requested
		lines_requested = lines, 
		-- how many bytes we have received
		bytes = 0,
		total_bytes = tot_bytes,
		-- the stringhack (must survive the callback, since the 
		-- callback doesn't know when it must be destroyed)
		a = stringhack.new(),
		-- the first byte
		from = 0,
		-- the last byte
		to = 0,
		-- the minimum amount of bytes we receive 
		-- (compensates the mail header usually)
		base = 2048,
	}
	-- the callback for http stram
	local cb = common.top_cb(global,data,truncate)
	-- retrive must retrive from-to bytes, stores from and to in globals.
	local retrive_f = function()
		global.to = global.base + global.from + (global.lines + 1) * 100
		global.base = 0
		local extra_header = {
			"Range: bytes="..global.from.."-"..global.to
		}
		local f,err = b:pipe_uri(uri,cb,extra_header)
		global.from = global.to + 1
		--if f == nil --and rc.error == "EOF" 
		--	then
		--	return "",nil
		--end
		return f,err
	end
	-- global.lines = -1 means we are done!
	local check_f = function(_)
		return global.lines < 0 or global.bytes >= global.total_bytes
	end
	-- nothing to do
	local action_f = function(_)
		return true
	end

	-- go! 
	if not support.do_until(retrive_f,check_f,action_f) and 
	   not truncate then
		log.error_print("Top failed\n")
		-- don't remember if this should be done
		--session.remove(key())
		return POPSERVER_ERR_UNKNOWN
	end

	return POPSERVER_ERR_OK
end


