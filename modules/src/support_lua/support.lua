---
-- This module implements some looping primitives, some useful wrappers.
-- should be used to make code shorter.

support = {}

---
-- A simple do while loop in a more compatc way.
-- Gets somthing with retrive, then calls action on it and loops until
-- check_retrive
--@param retrive function to retrive the page, 
--	called with no parameters;
--	<i>returns (file|nil),errorstring</i>.
--@param check_retrive function that checks for another retrival 
--	and eventually changes retrive behaviour, called with retrived file;
--	<i>returns (true|false)</i>.
--@param action function called with retrived file;
--	<i>returns (true|false), errorstring</i>.
--@return last action result.
function support.do_until(retrive,check_retrive,action)
	local file = nil
	local rc = nil
	local err = nil
	
	if not retrive then
		log.error_print("INTERNAL: retrive is nil\n")
	end

	if not check_retrive then
		log.error_print("INTERNAL: check_retrive is nil\n")
	end
	
	if not action then
		log.error_print("INTERNAL: action is nil\n")
	end
	
	repeat
		file,err = retrive()
		if not file then 
			if not err then
				err = "INTERNAL: function retrive() "..
					"must return an error message as "..
					"the second return if the first one"..
					" is nil"
			end
			log.error_print(err.."\n")
			break
		end
		rc,err = action(file)
		if not rc then 
			if not err then
				err = "INTERNAL: function action() "..
					"must return an error message as "..
					"the second return if the first one"..
					" is nil"
			end
			log.error_print(err.."\n")
			break
		end
	until check_retrive(file)
	
	return rc
end

---
-- Generates a function that tryes n times retrive.
-- @param retrive function to retrive the page, 
--	called with no parameters, returns (file|nil),errorstring.
function support.retry_n(n,retrive)
	local retrive_n = function(...)
		local i = 0
		local file = nil
		local err = nil
		repeat
			file,err = retrive(unpack(arg))
			if file then 
				break 
			else
				--print("skipping" .. err)
			end
			i = i + 1
		until i >= n
		return file,err
	end
	return retrive_n
end

---
-- Returns a retrive function for do_until that retrives uri u with browser b
function support.do_retrive(b,u)
	return function()
		local f,r = b:get_uri(u)
		return f,r.error
	end
end

---
-- This is the check to make do_until exit after the first repeat
function support.check_fail()
	return true
end

---
-- This creates a function for do_until action that puts the capture of
-- exp in t[field]
function support.do_extract(t,field,exp)
	--sanity checks
	if field == nil or exp == nil or t == nil then
		return function (s) 
			return nil,"t, field and exp must be non-nil!\n"..
				"support.do_extract not called properly."
		end
	end
	--the real code
	return function (s)
		if s == nil then
			return nil,"Unable to capture "..exp
		end
		local _,_,r = string.find(s,exp)
		if not r then
			return nil,"Unable to capture "..exp
		else
			t[field] = r	
			return true,nil
		end
	end
end

---
-- Check if v is nil, and eventually logs the error, return nil if ok,
-- true if an error occurred
function support.check(v,err)
	if not v then
		log.print_err(err)
		return true
	end
	return nil
end

