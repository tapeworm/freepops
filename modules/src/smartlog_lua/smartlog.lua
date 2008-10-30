---
-- A module to customize the logging behavior
-- 
MODULE_VERSION = "0.0.1"
MODULE_NAME = "smartlog"
MODULE_REQUIRE_VERSION = "0.2.8"
MODULE_LICENSE = "GNU/GPL"
MODULE_URL = "http://www.freepops.org/download.php?module=smartlog.lua"
MODULE_HOMEPAGE = "http://www.freepops.org/"

--============================================================================--
-- This is part of FreePOPs (http://www.freepops.org) released under GNU/GPL  
--============================================================================--

module("smartlog",package.seeall)

-- We intercept log.dbg, log.err, etc. to add more detailed logging to log.txt
--   The current date and time is also prefixed.
-- 
-- Example entry:
--   12/05/04 03:48:17 : My Log Line
--   --------------------------------------------------
--   My Data
--   --------------------------------------------------
--

-- Globals
--
local DBG_LEN = 500

-- The platform dependent End Of Line string
-- e.g. this can be changed to "\n" under UNIX, etc.
-- this is presently just used for the log file.
local EOL = "\r\n"

-- The logging functions
--
log = log or {} -- fast hack to make the xml generator happy
log.err = log.error_print
-- logging functions:
log.kinds = { "err", "dbg", "warn", "say" }

-- keep a copy of the original log function table
local log_original = {}

-- copies all elements from src into dest
function copy_from(dest, src)
  for i, v in pairs(src) do
    dest[i] = v
  end
end

-- modify the log table to reroute calls to do_log
function use_do_log()
  copy_from(log_original, log)
  -- redirect log functions to use do_log
  for i,kind in pairs(log.kinds) do
    log[kind] = function( line, data )
      log_do_log(kind, line, data)
    end
  end
  -- use log.err but also intercept log.error_print
  log.error_print = log.err
end

function dbg_limit(str)
  if (str ~= nil) and (type(str) == "string") and DBG_LEN and (DBG_LEN >= 0) then
    str = string.sub(str,1,DBG_LEN)
  end
  return str
end

-- NOTE: the standard log functions will not accept a second data
--  parameter.  e.g. something like log.dbg(line, data) will cause
--  lua to crash with "L: lua stack image...", so we must always
--  install replacements.
use_do_log()

-- central logging function
log_do_log = function( kind, line, data )
  -- intercepting the logger calls adds stack frames, causing
  --  the currentline in log.txt to be incorrect, so we add
  --  the actual line number as a prefix.
  -- 1=this, 2=caller (generated), 3=caller's caller (source)
  local info = debug.getinfo(3, "Sl") -- l=currentline, S=info.short_src
  local prefix = logger_prefix_cb(kind, info)

  -- call original logger to write to FreePOPs log.txt
  func = log_original[kind]
  func(prefix .. dbg_limit(line))
end

function setLoggingPrefixCallBack(cb) 
  logger_prefix_cb = cb
end

local logger_prefix_cb = function(kind, info) 
  local prefix = ""
  if info then
    prefix = "["..kind.."@"..tostr(info.currentline) .. "] "
  else
    prefix = "["..kind.."@?] "
  end
  return prefix  
end
