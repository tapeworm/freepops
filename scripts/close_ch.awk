BEGIN {DAYS=day;} 
{
 for ( i = 2 ; i <= NF ; i++) {
	 cmd=sprintf("scripts/cvs2changelog.lua %d ../%s", DAYS, $i);
	 system(cmd);
	 }
 }
