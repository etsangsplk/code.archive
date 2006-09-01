/ control external (.z.p*) access to  a kdb+ session, log access errors to file
/ use <loadinvalidaccess.q> to load and display table INVALIDACCESS
/ control access (in customaccess.q) by:
/ setting .access.VALIDHOSTPATTERNS - list of allowed hoststring patterns (";"vs ...) 
/ setting .access.VALIDCMDPATTERNS - list of allowed cmdstring patterns
/ setting .access.STOPWORDS - list of words that can't be used
/ setting .access.VALIDCMDSYMBOLS - list of allowed commands  
/ adding rows to .access.USERS for .z.u matches 
/ ordinary user can only run canned commands
/ poweruser can run (some) sql commands (select .. etc)
/ superuser can do anything
\l saveorig.q
\d .access
/vpw:{loginvalid[;`pw;x]defaultuser x}
vpo:{loginvalid[;`po;x]$[defaultuser .z.u;validhost .z.a;0b]}
vpg:{loginvalid[;`pg;x]validcmd[.z.u;x]}
vps:{loginvalid[;`ps;x]$[poweruser .z.u;validcmd[.z.u;x];0b]}
vpi:{loginvalid[;`pi;x]superuser .z.u}
vph:{loginvalid[;`ph;x]superuser .z.u}
vpp:{loginvalid[;`pp;x]superuser .z.u}
superuser:validuser[;0b;1b];poweruser:validuser[;1b;0b];defaultuser:validuser[;0b;0b]
adduser:{[u;pu;su]USERS,:(u;pu;su);}
addsuperuser:adduser[;0b;1b];addpoweruser:adduser[;1b;0b];adddefaultuser:adduser[;0b;0b]
deleteusers:{delete from `.access.USERS where u in x;}
if[not`USERS in system"a";
	FIRSTTIME:1b;
	USERS:([u:`symbol$()]poweruser:`boolean$();superuser:`boolean$());
	USERS,:(`;0b;0b);USERS,:(.z.u;1b;1b);
	VALIDHOSTPATTERNS:(string .Q.host .z.a;"127.0.0.1";"localhost");
	VALIDCMDPATTERNS:("select*";"count*");
	STOPWORDS:`delete`exit`access`value`save`read0`read1`insert`update`system;
	VALIDCMDSYMBOLS:`symbol$();
	@[value;"\\l controlaccess.custom.q";::]]
loginvalid:{[ok;zcmd;cmd]	
	if[not ok;H enlist(`LOADINVALIDACCESS;`INVALIDACCESS;(.z.z;zcmd;.z.a;.z.w;.z.u;.dotz.txt[zcmd;cmd]))];ok}
.q.likeany:{$[count y;$[x like first y;1b;.z.s[x;1_y]];0b]}
words:{`$1_'(where not x in .Q.an)_ x:" ",x}
validhost:{[za](.dotz.ipa za)likeany VALIDHOSTPATTERNS}
validuser:{[zu;pu;su]$[su;exec any(`,zu)in u from USERS where superuser;$[pu;exec any(`,zu)in u from USERS where poweruser or superuser;exec any(`,zu)in u from USERS]]}
validcmd:{[u;cmd]
	if[superuser u;:1b];
	tc:type cmd,:();fc:first cmd;
	if[$[11h=tc;1b;(0h=tc)and -11h=type fc];:fc in VALIDCMDSYMBOLS];
	$[poweruser u;$[not(any";{"in cmd)or any STOPWORDS in words cmd;cmd likeany VALIDCMDPATTERNS;0b];0b]}
\d .dotz
TXTW:50
/ if file doesn't exist create and initialise it
if[()~key .access.FILE;.[.access.FILE;();:;()]]
.access.H:hopen .access.FILE
/ allow .z.pw, it can take care of itself 
/.z.pw:{$[.access.vpw[y];x[y;z];0b]}.z.pw 
.z.po:{$[.access.vpo[y];x y;hclose .z.w]}.z.po
/ .z.pc - untouched, close is always allowed
.z.pg:{$[.access.vpg[y];x y;'`access]}.z.pg
.z.ps:{$[.access.vps[y];x y;'`access]}.z.ps
.z.pi:{$[.access.vpi[y];x y;'`access]}.z.pi
.z.ph:{$[.access.vph[y];x y;hclose .z.w]}.z.ph
.z.pp:{$[.access.vpp[y];x y;hclose .z.w]}.z.pp
\
note that you can put global restrictions on the amount of memory used, and
the maximum time a single interaction can take by setting command line parameters:
-T NNN (where NNN seconds is the maximum duration) - q will signal 'stop
-w NNN (where NNN MB is the maximum memory) - q will *EXIT* with wsfull
reserve memory at startup by doing something like:
key 260000000 / to reserve 1GB     
use .h.uh on http input if need to check for STOPWORDS etc 