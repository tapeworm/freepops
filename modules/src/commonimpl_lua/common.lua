---
-- Commonly used POP3 implementation. These functions need a <B>stat(pstate)</B>
-- that checks if it called more than once.

--============================================================================--
-- This is part of FreePOPs (http://freepops.sf.net) released under GNU/GPL  
--============================================================================--

common = {}

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


