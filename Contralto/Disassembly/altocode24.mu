 ;	A L T O C O D E 2 4 . M U

;***Derived from ALTOCODE23.MU, as last modified by
;	Ingalls, August 11, 1976  10:39 PM
;***E. McCreight, editor
;***modified by McCreight, September 19, 1977  4:34 PM
;	removed STM3: dependence on saving R40 across tasks
;***modified by Boggs, September 20, 1977  8:02 PM
;	moved constants and symbols into AltoConsts23.mu
;***modified by Dersch, August 26, 2015 4:04 PM
;   annotated with PROM addresses and Tasks for use in Contralto

;Get the symbol and constant definitions
#AltoConsts23.mu;

;LABEL PREDEFINITIONS

;The reset locations of the tasks:

!17,20,NOVEM,,,,KSEC,,,EREST,MRT,DWT,CURT,DHT,DVT,PART,KWDX,;

;Locations which may need to be accessible from the Ram, or Ram
;  locations which are accessed from the Rom (TRAP1):
!37,20,START,RAMRET,RAMCYCX,,,,,,,,,,,,,TRAP1;

;Macro-op dispatch table:
!37,20,DOINS,DOIND,EMCYCLE,NOPAR,JSRII,U5,U6,U7,,,,,,,RAMTRAP,TRAP;

;Parameterless macro-op sub-table:
!37,40,DIR,EIR,BRI,RCLK,SIO,BLT,BLKS,SIT,JMPR,RDRM,WTRM,DIRS,VERS,V15,V16,V17,MUL,DIV,V22,V23,BITBLT,,,,,,,,,,,;

;Cycle dispatch table:
!37,20,L0,L1,L2,L3,L4,L5,L6,L7,L8,R7,R6,R5,R4,R3X,R2X,R1X;

;some global R-Registers
$NWW		$R4;		State of interrupt system
$R37		$R37;		Used by MRT, interval timer and EIA
$MTEMP		$R25;		Public temporary R-Register

;The Display Controller

; its R-Registers:
$CBA		$R22;
$AECL		$R23;
$SLC		$R24;
$HTAB		$R26;
$YPOS		$R27;
$DWA		$R30;
$CURX		$R20;
$CURDATA	$R21;

; its task specific functions:
$EVENFIELD	$L024010,000000,000000; F2 = 10 DHT DVT
$SETMODE	$L024011,000000,000000; F2 = 11 DHT
$DDR		$L026010,000000,124100; F2 = 10 DWT

!1,2,DVT1,DVT11;
!1,2,MOREB,NOMORE;
!1,2,NORMX,HALFX;
!1,2,NODD,NEVEN;
!1,2,DHT0,DHT1;
!1,2,NORMODE,HALFMODE;
!1,2,DWTZ,DWTY;
!1,2,DOTAB,NOTAB;
!1,2,XNOMORE,DOMORE;

;Display Vertical Task

DV00014> DVT:	MAR<- L<- DASTART+1;
DV00001>	CBA<- L, L<- 0;
DV00005>	CURDATA<- L;
DV00006>	SLC<- L;
DV00017>	T<- MD;			CAUSE A VERTICAL FIELD INTERRUPT
DV00023>	L<- NWW OR T;
DV00036>	MAR<- CURLOC;		SET UP THE CURSOR
DV00046>	NWW<- L, T<- 0-1;
DV00047>	L<- MD XOR T;		HARDWARE EXPECTS X COMPLEMENTED
DV00050>	T<- MD, EVENFIELD;
DV00051>	CURX<- L, :DVT1;

DV00002> DVT1:	L<- BIAS-T-1, TASK, :DVT2;	BIAS THE Y COORDINATE 
DV00003> DVT11:	L<- BIAS-T, TASK;

DV00052> DVT2:	YPOS<- L, :DVT;

;Display Horizontal Task.
;11 cycles if no block change, 17 if new control block.

DH00013> DHT:	MAR<- CBA-1;
DH00053>	L<- SLC -1, BUS=0;
DH00054>	SLC<- L, :DHT0;

DH00032> DHT0:	T<- 37400;		MORE TO DO IN THIS BLOCK
DH00055>	SINK<- MD;
DH00056>	L<- T<- MD AND T, SETMODE;
DH00057>	HTAB<- L LCY 8, :NORMODE;

DH00034> NORMODE:L<- T<- 377 . T;
DH00070>	AECL<- L, :REST;	

DH00035> HALFMODE: L<- T<-  377 . T;
DH00071>	AECL<- L, :REST, T<- 0;

DH00072> REST:	L<- DWA + T,TASK;	INCREMENT DWA BY 0 OR NWRDS
DH00073> NDNX:	DWA<- L, :DHT;

DH00033> DHT1:	L<- T<- MD+1, BUS=0;
DH00074>	CBA<- L, MAR<- T, :MOREB;

DH00025> NOMORE:	BLOCK, :DNX;
DH00024> MOREB:	T<- 37400;
DH00075>	L<- T<- MD AND T, SETMODE;
DH00127>	MAR<- CBA+1, :NORMX, EVENFIELD;

DH00026> NORMX:	HTAB<- L LCY 8, :NODD;
DH00027> HALFX:	HTAB_ L LCY 8, :NEVEN;

DH00030> NODD:	L<-T<- 377 . T;
DH00130>	AECL<- L, :XREST;	ODD FIELD, FULL RESOLUTION

DH00031> NEVEN:	L_ 377 AND T;		EVEN FIELD OR HALF RESOLUTION
DH00131>	AECL<-L, T<-0;

DH00132> XREST:	L<- MD+T;
DH00133>	T_MD-1;
DH00134> DNX:	DWA<-L, L<-T, TASK;
DH00135>	SLC<-L, :DHT;

;Display Word Task

DW00011> DWT:	T<- DWA;
DW00136>	T<- -3+T+1;
DW00137>	L<- AECL+T,BUS=0,TASK;	AECL CONTAINS NWRDS AT THIS TIME
DW00140>	AECL<-L, :DWTZ;

DW00041> DWTY:	BLOCK;
DW00141>	TASK, :DWTF;

DW00040> DWTZ:	L<-HTAB-1, BUS=0,TASK;
DW00142>	HTAB<-L, :DOTAB;

DW00042> DOTAB:	DDR<-0, :DWTZ;
DW00043> NOTAB:	MAR_T_DWA;
DW00143>	L<-AECL-T-1;
DW00144>	ALUCY, L<-2+T;
DW00145>	DWA<-L, :XNOMORE;

DW00045> DOMORE:	DDR<-MD, TASK;
DW00146>	DDR_MD, :NOTAB;

DW00144> XNOMORE:DDR<- MD, BLOCK;
DW00147>	DDR<- MD, TASK;

DW00150> DWTF:	:DWT;

;Alto Ethernet Microcode, Version III, Boggs and Metcalfe

;4-way branches using NEXT6 and NEXT7
!17,20,EIFB00,EODOK,EOEOK,ENOCMD,EIFB01,EODPST,EOEPST,EOREST,EIFB10,EODCOL,EOECOL,EIREST,EIFB11,EODUGH,EOEUGH,ERBRES;

;2-way branches using NEXT7
;EOCDW1, EOCDWX, and EIGO are all related.  Be careful!
!7,10,EIDOK,EIFOK,,EOCDW1,EIDPST,EIFBAD,EOCDWX,EIGO;

;Miscellaenous address constraints
!7,10,,EOCDW0,EODATA,,,EOCDRS,EIDATA,EPOST;
!1,1,EIFB1;
!1,1,EIFRST;

;2-way branches using NEXT9
!1,2,EOINPR,EOINPN;
!1,2,EODMOR,EODEND;
!1,2,EOLDOK,EOLDBD;
!1,2,EIDMOR,EIDFUL;
!1,2,EIFCHK,EIFPRM;
!1,2,EOCDWT,EOCDGO;
!1,2,ECNTOK,ECNTZR;
!1,2,EIFIGN,EISET;
!1,2,EIFNBC,EIFBC;

;R Memory Locations

$ECNTR	$R12;	Remaining words in buffer
$EPNTR	$R13;	points BEFORE next word in buffer

;Ethernet microcode Status codes

$ESIDON	$377;	Input Done
$ESODON	$777;	Output Done
$ESIFUL	$1377;	Input Buffer full - words lost from tail of packet
$ESLOAD	$1777;	Load location overflowed
$ESCZER	$2377;	Zero word count for input or output command
$ESABRT	$2777;	Abort - usually caused by reset command
$ESNEVR	$3377;	Never Happen - Very bad if it does

;Main memory locations in page 1 reserved for Ethernet

$EPLOC	$600;	Post location
$EBLOC	$601;	Interrupt bit mask

$EELOC	$602;	Ending count location
$ELLOC	$603;	Load location

$EICLOC	$604;	Input buffer Count
$EIPLOC	$605;	Input buffer Pointer

$EOCLOC	$606;	Output buffer Count
$EOPLOC	$607;	Output buffer Pointer

$EHLOC	$610;	Host Address

;Function Definitions

$EIDFCT	$L000000,014004,000100;	BS = 4,  Input data
$EILFCT	$L016013,070013,000100;	F1 = 13, Input Look
$EPFCT	$L016014,070014,000100;	F1 = 14, Post
$EWFCT	$L016015,000000,000000;	F1 = 15, Wake-Up

$EODFCT	$L026010,000000,124000;	F2 = 10, Output data
$EOSFCT	$L024011,000000,000000;	F2 = 11, Start output
$ERBFCT	$L024012,000000,000000;	F2 = 12, Rest branch
$EEFCT	$L024013,000000,000000;	F2 = 13, End of output
$EBFCT	$L024014,000000,000000;	F2 = 14, Branch
$ECBFCT	$L024015,000000,000000;	F2 = 15, Countdown branch
$EISFCT	$L024016,000000,000000;	F2 = 16, Start input

; - Whenever a label has a pending branch, the list of possible
;   destination addresses is shown in brackets in the comment field.
; - Special functions are explained in a comment near their first ;use.
; - To avoid naming conflicts, all labels and special functions
;   have "E" as the first letter.

;Top of Ethernet Task loop

;Ether Rest Branch Function - ERBFCT
;merge ICMD and OCMD Flip Flops into NEXT6 and NEXT7
;ICMD and OCMD are set from AC0 [14:15] by the SIO instruction
;	00  neither 
;	01  OCMD - Start output
;	10  ICMD - Start input
;	11  Both - Reset interface

;in preparation for a hack at EIREST, zero EPNTR

EN00007> EREST:	L<- 0,ERBFCT;		What's happening ?
EN00152>	EPNTR<- L,:ENOCMD;	[ENOCMD,EOREST,EIREST,ERBRES]

EN00203> ENOCMD:	L<- ESNEVR,:EPOST;	Shouldn't happen
ERBRES:	L_ ESABRT,:EPOST;	Reset Command

;Post status and halt.  Microcode status in L.
;Put microstatus,,hardstatus in EPLOC, merge c(EBLOC) into NWW.
;Note that we write EPLOC and read EBLOC in one operation

;Ether Post Function - EPFCT.  Gate the hardware status
;(LOW TRUE) to Bus [10:15], reset interface.

EN00237> EPOST:	MAR<- EELOC;
EN00220>	EPNTR<- L,TASK;		Save microcode status in EPNTR
EN00222>	MD<- ECNTR;		Save ending count

EN00224>	MAR<- EPLOC;		double word reference
EN00230>	T<- NWW;
EN00240>	MD<- EPNTR,EPFCT;	BUS AND EPNTR with Status
EN00260>	L<- MD OR T,TASK;	NWW OR c(EBLOC)
EN00261>	NWW<- L,:EREST;		Done.  Wait for next command

;This is a subroutine called from both input and output (EOCDGO
;and EISET).  The return address is determined by testing ECBFCT,
;which will branch if the buffer has any words in it, which can
;only happen during input.

ESETUP:	NOP;
	L_ MD,BUS=0;		check for zero length
	T_ MD-1,:ECNTOK;	[ECNTOK,ECNTZR] start-1

ECNTZR:	L_ ESCZER,:EPOST;	Zero word count.  Abort

;Ether Countdown Branch Function - ECBFCT.
;NEXT7 = Interface buffer not empty.

ECNTOK:	ECNTR_ L,L_ T,ECBFCT,TASK;
	EPNTR_ L,:EODATA;	[EODATA,EIDATA]

;Ethernet Input

;It turns out that starting the receiver for the first time and
;restarting it after ignoring a packet do the same things.

EIREST:	:EIFIGN;		Hack

;Address filtering code.

;When the first word of a packet is available in the interface
;buffer, a wakeup request is generated.  The microcode then
;decides whether to accept the packet.  Decision must be reached
;before the buffer overflows, within about 14*5.44 usec.
;if EHLOC is zero, machine is 'promiscuous' - accept all packets
;if destination byte is zero, it is a 'broadcast' packet, accept.
;if destination byte equals EHLOC, packet is for us, accept.

;EIFRST is really a subroutine that can be called from EIREST
;or from EIGO, output countdown wait.  If a packet is ignored
;and EPNTR is zero, EIFRST loops back and waits for more
;packets, else it returns to the countdown code.

;Ether Branch Function - EBFCT
;NEXT7 = IDL % OCMD % ICMD % OUTGONE % INGONE (also known as POST)
;NEXT6 = COLLision - Can't happen during input

EIFRST:	MAR_ EHLOC;		Get Ethernet address
	T_ 377,EBFCT;		What's happening?
	L_ MD AND T,BUS=0,:EIFOK;[EIFOK,EIFBAD] promiscuous?

EIFOK:	MTEMP_ LLCY8,:EIFCHK;	[EIFCHK,EIFPRM] Data wakeup

EIFBAD:	ERBFCT,TASK,:EIFB1;	[EIFB1] POST wakeup; xCMD FF set?
EIFB1:	:EIFB00;		[EIFB00,EIFB01,EIFB10,EIFB11]

EIFB00:	:EIFIGN;		IDL or INGONE, restart rcvr
EIFB01:	L_ ESABRT,:EPOST;	OCMD, abort
EIFB10:	L_ ESABRT,:EPOST;	ICMD, abort
EIFB11:	L_ ESABRT,:EPOST;	ICMD and OCMD, abort

EIFPRM:	TASK,:EIFBC;		Promiscuous. Accept

;Ether Look Function - EILFCT.  Gate the first word of the 
;data buffer to the bus, but do not increment the read pointer.

EIFCHK:	L_ T_ 177400,EILFCT;	Mask off src addr byte (BUS AND)
	L_ MTEMP-T,SH=0;	Broadcast?
	SH=0,TASK,:EIFNBC;	[EIFNBC,EIFBC] Our Address?

EIFNBC:	:EIFIGN;		[EIFIGN,EISET]

EIFBC:	:EISET;			[EISET] Enter input main loop

;Ether Input Start Function - EISFCT.  Start receiver.  Interface
;will generate a data wakeup when the first word of the next
;packet arrives, ignoring any packet currently passing.

EIFIGN:	SINK_ EPNTR,BUS=0,EPFCT;Reset; Called from output?
	EISFCT,TASK,:EOCDWX;	[EOCDWX,EIGO] Restart rcvr

EOCDWX:	EWFCT,:EOCDWT;		Return to countdown wait loop

EISET:	MAR_ EICLOC,:ESETUP;	Double word reference

;Input Main Loop

;Ether Input Data Function - EIDFCT.  Gate a word of data to
;the bus from the interface data buffer, increment the read ptr.
;		* * * * * W A R N I N G * * * * *
;The delay from decoding EIDFCT to gating data to the bus is
;marginal, so this loop causes SysClk to stop for one cycle by
;referencing MD in cycle 4.

EIDATA:	L_ MAR_ EPNTR+1,EBFCT;	What's happening?
	T_ ECNTR-1,BUS=0,:EIDOK;[EIDOK,EIDPST] word count zero?
EIDOK:	EPNTR_ L,L_ T,:EIDMOR;	[EIDMOR,EIDFUL]
EIDMOR:	MD_ EIDFCT,TASK;	Read a word from interface
	ECNTR_ L,:EIDATA;

EIDPST:	L_ ESIDON,:EPOST;	[EPOST] Presumed to be INGONE

EIDFUL:	L_ ESIFUL,:EPOST;	Input buffer overrun

;Ethernet output

;It is possible to get here due to a collision.  If a collision
;happened, the interface was reset (EPFCT) to shut off the
;transmitter.  EOSFCT is issued to guarantee more wakeups while
;generating the countdown.  When this is done, the interface is
;again reset, without really doing an output.

EN00207> EOREST:	MAR<- ELLOC;		Get load
EN00274>	L<- R37;			Use clock as random # gen
EN00275>	EPNTR<- LLSH1;		Use bits [2:9]
EN00276>	L<- MD,EOSFCT;		L<- current load
EN00277>	SH<0,ECNTR<- L;		Overflowed?
EN00300>	MTEMP<- LLSH1,:EOLDOK;	[EOLDOK,EOLDBD]

EOLDBD:	L_ ESLOAD,:EPOST;	Load overlow

EN00301> EOLDOK:	MAR<- ELLOC;		Write updated load
EN00242>	L<- MTEMP+1;
EN00302>	MTEMP<- L,TASK;
EN00303>	MD<- MTEMP,:EORST1;	New load = (old lshift 1) + 1

EN00304> EORST1:	L<- EPNTR;		Continue making random #
EN00305>	EPNTR<- LLSH1;
EN00306>	T<- 177400;
EN00307>	L<- EPNTR AND T,TASK;
EN00310>	EPNTR<- LLCY8,:EORST2;

;At this point, EPNTR has 0,,random number, ENCTR has old load.

EN00311> EORST2:	MAR<- EICLOC;		Has an input buffer been set up?
EN00312>	T<- ECNTR;
EN00313>	L<- EPNTR AND T;		L_ Random & Load
EN00314>	SINK<- MD,BUS=0;
EN00315>	ECNTR<- L,SH=0,EPFCT,:EOINPR;[EOINPR,EOINPN] 

EN00154> EOINPR:	EISFCT,:EOCDWT;		[EOCDWT,EOCDGO] Enable in under out

EOINPN:	:EOCDWT;		[EOCDWT,EOCDGO] No input.

;Countdown wait loop.  MRT will wake generate a wakeup every
;37 usec which will decrement ECNTR.  When it is zero, start
;the transmitter.

;Ether Wake Function - EWFCT.  Sets a flip flop which will cause
;a wakeup to this task the next time MRT wakes up (every 37 usec).
;Wakeup is cleared when Ether task next runs.  EWFCT must be
;issued in the instruction AFTER a task.

EN00250> EOCDWT:	L<- 177400,EBFCT;	What's happening?
	EPNTR_ L,ECBFCT,:EOCDW0;[EOCDW0,EOCDRS] Packet coming in?
EOCDW0:	L_ ECNTR-1,BUS=0,TASK,:EOCDW1; [EOCDW1,EIGO]
EOCDW1:	ECNTR_ L,EWFCT,:EOCDWT;	[EOCDWT,EOCDGO]

EOCDRS:	L_ ESABRT,:EPOST;	[EPOST] POST event

EIGO:	:EIFRST;		[EIFRST] Input under output

;Output main loop setup

EOCDGO:	MAR_ EOCLOC;		Double word reference
	EPFCT;			Reset interface
	EOSFCT,:ESETUP;		Start Transmitter

;Ether Output Start Function - EOSFCT.  The interface will generate
;a burst of data requests until the interface buffer is full or the
;memory buffer is empty, wait for silence on the Ether, and begin
;transmitting.  Thereafter it will request a word every 5.44 us.

;Ether Output Data Function - EODFCT.  Copy the bus into the
;interface data buffer, increment the write pointer, clears wakeup
;request if the buffer is now nearly full (one slot available).

;Output main loop

EODATA:	L_ MAR_ EPNTR+1,EBFCT;	What's happening?
	T_ ECNTR-1,BUS=0,:EODOK; [EODOK,EODPST,EODCOL,EODUGH]
EODOK:	EPNTR_ L,L_ T,:EODMOR;	[EODMOR,EODEND]
EODMOR:	ECNTR_ L,TASK;
	EODFCT_ MD,:EODATA;	Output word to transmitter

EODPST:	L_ ESABRT,:EPOST;	[EPOST] POST event

EODCOL:	EPFCT,:EOREST;		[EOREST] Collision

EODUGH:	L_ ESABRT,:EPOST;	[EPOST] POST + Collision

;Ether EOT Function - EEFCT.  Stop generating output data wakeups,
;the interface has all of the packet.  When the data buffer runs
;dry, the interface will append the CRC and then generate an
;OUTGONE post wakeup.

EODEND:	EEFCT;			Disable data wakeups
	TASK;			Wait for EEFCT to take
	:EOEOT;			Wait for Outgone

;Output completion.  We are waiting for the interface buffer to
;empty, and the interface to generate an OUTGONE Post wakeup.

EOEOT:	EBFCT;			What's happening?
	:EOEOK;			[EOEOK,EOEPST,EOECOL,EOEUGH]

EOEOK:	L_ ESNEVR,:EPOST;	Runaway Transmitter. Never Never.

EOEPST:	L_ ESODON,:EPOST;	POST event.  Output done

EOECOL:	EPFCT,:EOREST;		Collision

EOEUGH:	L_ ESABRT,:EPOST;	POST + Collision


;Memory Refresh Task,
;Mouse Handler,
;EIA Handler,
;Interval Timer,
;Calender Clock, and
;part of the cursor.

!17,20,TX0,TX6,TX3,TX2,TX8,TX5,TX1,TX7,TX4,,,,,,,;
!1,2,DOTIMER,NOTIMER;
!1,2,NOTIMERINT,TIMERINT;
!1,2,DOCUR,NOCUR;
!1,2,SHOWC,WAITC;
!1,2,SPCHK,NOSPCHK;

!1,2,NOCLK,CLOCK;
!1,1,DTODD;
!1,1,MRTLAST;
!1,2,CNOTLAST,CLAST;

$CLOCKTEMP$R11;

MR00351> MRT:	SINK<- MOUSE, BUS;	MOUSE DATA IS ANDED WITH 17B
MR00360> MRTA:	L<- T<- -2, :TX0;		DISPATCH ON MOUSE CHANGE
MR00340> TX0:	L<- T<- R37 AND NOT T;	CHECK FOR INTERVAL TIMER/EIA
MR00361>	SH=0, L<-T<- 77+T+1;	
MR00362>	:DOTIMER, R37<- L, ALUCY;	
NOTIMER:L_ CURX, :NOCLK;
NOCLK:	T_ REFMSK, SH=0;
	MAR_ R37 AND T, :DOCUR;
NOCUR:	CURDATA_ L, TASK;
MRTLAST:CURDATA_ L, :MRT;	END OF MAIN LOOP


MR00373> DOTIMER:MAR<-EIALOC;		INTERVAL TIMER/EIA INTERFACE
MR00374> DTODD:	L<-2 AND T;
MR00375>	SH=0, L<-T<-BIAS.T;
MR00376>	CURDATA<-L, :SPCHK;	CURDATA_CURRENT TIME WITHOUT CONTROL BITS

MR00352> SPCHK:	SINK<-MD, BUS=0, TASK;	CHECK FOR EIA LINE SPACING
MR00377> SPIA:	:NOTIMERINT, CLOCKTEMP<-L;

NOSPCHK:L_MD;			CHECK FOR TIME=NOW
	MAR_TRAPDISP-1;		CONTAINS TIME AT WHICH INTERRUPT SHOULD HAPPEN
	MTEMP_L;		IF INTERRUPT IS CAUSED, LINE STATE WILL BE STORED
	L_ MD-T;
	SH=0, TASK, L_MTEMP, :SPIA;

TIMERINT: MAR_ ITQUAN;		STORE THE THING IN CLOCKTEMP AT ITQUAN
	L_ CURDATA;
	R37_ L;
	T_NWW;			AND CAUSE AN INTERRUPT ON THE CHANNELS 
	MD_CLOCKTEMP;		SPECIFIED BY ITQUAN+1
	L_MD OR T, TASK;
	NWW_L;

NOTIMERINT: SINK_CURDATA, BUS=0, :NOTIMER;

CLOCK:	MAR_ CLOCKLOC;		R37 OVERFLOWED. UPDATE CLOCK
	NOP;
	L_ MD+1;
	MAR_ CLOCKLOC;
	MTEMP_ L, TASK;
	MD_ MTEMP, :NOTIMER;

DOCUR:	L_ T_ YPOS;		CHECK FOR VISIBLE CURSOR ON THIS SCAN
	SH < 0, L_ 20-T-1;
	SH<0, L_ 2+T, :SHOWC;

WAITC:	YPOS_ L, L_ 0, TASK, :MRTLAST;
SHOWC:	MAR_ CLOCKLOC+T+1, :CNOTLAST;

CNOTLAST: T_ CURX, :CURF;
CLAST:	T_ 0;
CURF:	YPOS_ L, L_ T;
	CURX_ L;
	L_ MD, TASK;
	CURDATA_ L, :MRT;


;AFTER THIS DISPATCH, T WILL CONTAIN XCHANGE, L WILL CONTAIN YCHANGE-1

TX1:	L_ T_ ONE +T, :M00;		Y=0, X=1
TX2:	L_ T_ ALLONES, :M00;		Y=0, X=-1
TX3:	L_ T_ 0, :M00;			Y=1, X= 0
TX4:	L_ T_ ONE AND T, :M00;		Y=1, X=1
TX5:	L_ T_ ALLONES XOR T, :M00;	Y=1, X=-1
TX6:	T_ 0, :M00;			Y= -1, X=0
TX7:	T_ ONE, :M00;			Y= -1, X=1
TX8:	T_ ALLONES, :M00;		Y= -1, X= -1

M00:	MAR_ MOUSELOC;			START THE FETCH OF THE COORDINATES
	MTEMP_ L;			YCHANGE -1
	L_ MD+ T;			X+ XCHANGE
	T_ MD;				Y
	MAR_ MOUSELOC;			NOW RESTORE THE UPDATED COORDINATES
	T_ MTEMP+ T+1;			Y+ (YCHANGE-1) + 1
	MTEMP_ L, L_ T;
	MD_ MTEMP;
	MAR_ MOUSELOC+1;
	MTEMP_ L, TASK;
	MD_ MTEMP, :MRTA;


;CURSOR TASK

;Cursor task specific functions
$XPREG		$L026010,000000,124000; F2 = 10
$CSR		$L026011,000000,124000; F2 = 11

CU00012> CURT:	XPREG<- CURX, TASK;
CU00437>	CSR<- CURDATA, :CURT;


;PREDEFINITION FOR PARITY TASK
!7,10,PR0,,PR2,PR3,PR4,PR5,PR6,PR7;

;NOVA EMULATOR

$SAD	$R5;
$PC	$R6;		USED BY MEMORY INIT


!7,10,Q0,Q1,Q2,Q3,Q4,Q5,Q6,Q7;
!1,2,FINSTO,INCPC;
!1,2,EReRead,FINJMP;	***X21 addition.
!1,2,EReadDone,EContRead;	***X21 addition.
!1,2,EtherBoot,DiskBoot;	***X21 addition.

EM00000> NOVEM:	IR_L_MAR_0, :INXB,SAD_ L;  LOAD SAD TO ZERO THE BUS. STORE PC AT 0
EM00460> Q0:	L_ ONE, :INXA;	EXECUTED TWICE
EM00461> Q1:	L_ TOTUWC, :INXA;
EM00462> Q2:	L_402, :INXA;	FIRST READ HEADER INTO 402, THEN
EM00463> Q3:	L_ 402, :INXA;	STORE LABEL AT 402
EM00464> Q4:	L_ ONE, :INXA;	STORE DATA PAGE STARTING AT 1
EM00465> Q5:	L_377+1, :INXE;	Store Ethernet Input Buffer Length ***X21.
EM00466> Q6:	L_ONE, :INXE;	Store Ethernet Input Buffer Pointer ***X21.
EM00467> Q7:	MAR_ DASTART;		CLEAR THE DISPLAY POINTER
EM00441>	T_ BIAS;
EM00451>	L_ R37 AND T;
EM00451>	R37_ L;
EM00472>	MD_ 0;
EM00473>	MAR_ 177034;			FETCH KEYBOARD
EM00474>	L_ 100000;
EM00475>	NWW_ L, T_ 0-1;
EM00476>	L_ MD XOR T, BUSODD;	*** X21 change.
EM00477>	MAR_ BDAD, :EtherBoot;	[EtherBoot, DiskBoot]  *** X21 change.
		; BOOT DISK ADDRESS GOES IN LOCATION 12
EM00471> DiskBoot: SAD_ L, L_ 0+1;
EM00500>	MD_ SAD;
EM00501>	MAR_ KBLKADR, :FINSTO;


; Ethernet boot section added in X21.
$NegBreathM1	$177175;
$EthNovaGo	$3;	First data location of incoming packet

EM00470> EtherBoot: L_EthNovaGo, :EReRead; [EReRead, FINJMP]

EM00454> EReRead:MAR_ EHLOC;	Set the host address to 377 for breath packets
EM00502>	TASK;
EM00503>	MD_ 377;

EM00504>	MAR_ EPLOC;	Zero the status word and start 'er up
EM00505>	SINK_ 2, STARTF;
EM00506>	MD _ 0;

EM00457> EContRead: MAR_ EPLOC;	See if status is still 0
EM00507>	T_ 377;		Status for correct read
EM00510>	L_ MD XOR T, TASK, BUS=0;
EM00511>	SAD_ L, :EReadDone; [EReadDone, EContRead]

EM00456> EReadDone: MAR_ 2;	Check the packet type
EM00512>	T_ NegBreathM1;	-(Breath-of-life)-1
EM00513>	T_MD+T+1;
EM00514>	L_SAD OR T;
EM00515>	SH=0, :EtherBoot;


; SUBROUTINE USED BY INITIALIZATION TO SET UP BLOCKS OF MEMORY
$EIOffset	$576;

EM00516> INXA:	T_ONE, :INXCom;	***X21 change.
EM00517> INXE:	T_EIOffset, :INXCom;		***X21 addition.

EM00520> INXCom: MAR_T_IR_ SAD+T;	*** X21 addition.
EM00521>	PC_ L, L_ 0+T+1;	*** X21 change.
EM00522> INXB:	SAD_ L;
EM00523>	SINK_ DISP, BUS,TASK;
EM00524>	MD_ PC, :Q0;


;REGISTERS USED BY NOVA EMULATOR 
$AC0	$R3;	AC'S ARE BACKWARDS BECAUSE THE HARDWARE SUPPLIES THE
$AC1	$R2;	COMPLEMENT ADDRESS WHEN ADDRESSING FROM IR
$AC2	$R1;
$AC3	$R0;
$XREG	$R7;


;PREDEFINITIONS FOR NOVA

!17,20,GETAD,G1,G2,G3,G4,G5,G6,G7,G10,G11,G12,G13,G14,G15,G16,G17;
!17,20,XCTAB,XJSR,XISZ,XDSZ,XLDA,XSTA,CONVERT,,,,,,,,,;
!3,4,SHIFT,SH1,SH2,SH3;
!1,2,MAYBE,NOINT;
!1,2,DOINT,DIS0;
!1,2,SOMEACTIVE,NOACTIVE;
!1,2,IEXIT,NIEXIT;
!17,1,ODDCX;
!1,2,EIR0,EIR1;
!7,1,INTCODE;
!1,2,INTSOFF,INTSON;***X21 addition for DIRS
!7,10,EMCYCRET,RAMCYCRET,CYX2,CYX3,CYX4,CONVCYCRET,,;
!7,2,MOREBLT,FINBLT;
!1,2,DOIT,DISABLED;

; ALL INSTRUCTIONS RETURN TO START WHEN DONE

EM00020> START:	T<- MAR_PC+SKIP;
EM00525> START1:	L<- NWW, BUS=0;	BUS# 0 MEANS DISABLED OR SOMETHING TO DO
EM00576>	:MAYBE, SH<0, L<- 0+T+1;  	SH<0 MEANS DISABLED
EM00526> MAYBE:	PC<- L, L<- T, :DOINT;
EM00527> NOINT:	PC<- L, :DIS0;

EM00534> DOINT:	MAR<- WWLOC, :INTCODE;	TRY TO CAUSE AN INTERRUPT

;DISPATCH ON FUNCTION FIELD IF ARITHMETIC INSTRUCTION,
;OTHERWISE ON INDIRECT BIT AND INDEX FIELD

EM00535> DIS0:	L<- T<- IR<- MD;	SKIP CLEARED HERE

;DISPATCH ON SHIFT FIELD IF ARITHMETIC INSTRUCTION,
;OTHERWISE ON THE INDIRECT BIT OR IR[3-7]

EM00612> DIS1:	T<- ACSOURCE, :GETAD;

;GETAD MUST BE 0 MOD 20
EM00540> GETAD: T<- 0, :DOINS;			PAGE 0
EM00541> G1:	T<- PC -1, :DOINS;		RELATIVE
EM00542> G2:	T<- AC2, :DOINS;			AC2 RELATIVE
EM00543> G3:	T<- AC3, :DOINS;			AC3 RELATIVE
EM00544> G4:	T<- 0, :DOINS;			PAGE 0 INDIRECT
EM00545> G5:	T<- PC -1, :DOINS;		RELATIVE INDIRECT
EM00546> G6:	T<- AC2, :DOINS;			AC2 RELATIVE INDIRECT
EM00547> G7:	T<- AC3, :DOINS;			AC3 RELATIVE INDIRECT
EM00550> G10:	L<- 0-T-1, TASK, :SHIFT;		COMPLEMENT
EM00551> G11:	L<- 0-T, TASK, :SHIFT;		NEGATE
EM00552> G12:	L<- 0+T, TASK, :SHIFT;		MOVE
EM00553> G13:	L<- 0+T+1, TASK, :SHIFT;		INCREMENT
EM00554> G14:	L<- ACDEST-T-1, TASK, :SHIFT;	ADD COMPLEMENT
EM00555> G15:	L<- ACDEST-T, TASK, :SHIFT;	SUBTRACT
EM00556> G16:	L<- ACDEST+T, TASK, :SHIFT;	ADD
EM00557> G17:	L<- ACDEST AND T, TASK, :SHIFT;

EM00530> SHIFT:	DNS<- L LCY 8, :START; 	SWAP BYTES
EM00531> SH1:	DNS<- L RSH 1, :START;	RIGHT 1
EM00532> SH2:	DNS<- L LSH 1, :START;	LEFT 1
EM00533> SH3:	DNS<- L, :START;		NO SHIFT

EM00060> DOINS:	L<- DISP + T, TASK, :SAVAD, IDISP;	DIRECT INSTRUCTIONS
EM00061> DOIND:	L<- MAR<- DISP+T;				INDIRECT INSTRUCTIONS
EM00613>	XREG<- L;
EM00614>	L<- MD, TASK, IDISP, :SAVAD;

BRI:	L_ MAR_ PCLOC	;INTERRUPT RETURN BRANCH
BRI0:	T_ 77777;
	L_ NWW AND T, SH < 0;
	NWW_ L, :EIR0;	BOTH EIR AND BRI MUST CHECK FOR INTERRUPT
;			REQUESTS WHICH MAY HAVE COME IN WHILE
;			INTERRUPTS WERE OFF

EIR0:	L_ MD, :DOINT;
EIR1:	L_ PC, :DOINT;

;***X21 addition
; DIRS - 61013 - Disable Interrupts and Skip if they were On
DIRS:	T_100000;
	L_NWW AND T;
	L_PC+1, SH=0;

;DIR - 61000 - Disable Interrupts
DIR:	T_ 100000, :INTSOFF;
INTSOFF: L_ NWW OR T, TASK, :INTZ;

INTSON: PC_L, :INTSOFF;

;EIR - 61001 - Enable Interrupts
EIR:	L_ 100000, :BRI0;

;SIT - 61007 - Start Interval Timer by ORing AC0 into R37
SIT:	T_ AC0;
	L_ R37 OR T, TASK;
	R37_ L, :START;

FINJSR:	L_ PC;
	AC3_ L, L_ T, TASK;
EM00455> FINJMP:	PC<- L, :START;
EM00626> SAVAD:	SAD<- L, :XCTAB;

;JSRII - 64400 - JSR double indirect, PC relative.  Must have X=1 in opcode
;JSRIS - 65000 - JSR double indirect, AC2 relative.  Must have X=2 in opcode
JSRII:	MAR_ DISP+T;	FIRST LEVEL
EM00627>	IR<- JSRCX;	<JSR 0>
EM00630>	T_ MD, :DOIND;	THE IR_ INSTRUCTION WILL NOT BRANCH	

;TRAP ON UNIMPLEMENTED OPCODES.  SAVES  PC AT
;TRAPPC, AND DOES A JMP@ TRAPVEC ! OPCODE.
TRAP:	XREG_ L LCY 8;	THE INSTRUCTION
TRAP1:	MAR_ TRAPPC;***X13 CHANGE: TAG 'TRAP1' ADDED
	IR_ T_ 37;
	T_ XREG.T;
	T_ TRAPCON+T+1;		T NOW CONTAINS 471+OPCODE
	MD_ PC, :DOIND;		THIS WILL DO JMP@ 530+OPCODE


;***X21 CHANGE: ADDED TAG RAMTRAP
RAMTRAP: SWMODE, :TRAP;

; Parameterless operations come here for dispatch.

!1,2,NPNOTRAP,NPTRAP;

NOPAR:	XREG_L LCY 8;	***X21 change. Checks < 25.
	T_25;		***X21. Greatest defined op is 24.
	L_DISP-T;
	ALUCY;
	SINK_DISP, SINK_X37, BUS, TASK, :NPNOTRAP;

NPNOTRAP: :DIR;

NPTRAP: :TRAP1;

;***X21 addition for debugging w/ expanded DISP Prom
U5:	:RAMTRAP;
U6:	:RAMTRAP;
U7:	:RAMTRAP;

;***X21 change. Traps numbered instead of lettered.
V15:	:TRAP1;		;Alto II DREAD
V16:	:TRAP1;		;Alto II DWRITE
V17:	:TRAP1;		;Alto II DEXCH
V22:	:TRAP1;		;Alto II DIOG1
V23:	:TRAP1;		;Alto II DIOG2

;MAIN INSTRUCTION TABLE.  GET HERE:
;		(1) AFTER AN INDIRECTION
;		(2) ON DIRECT INSTRUCTIONS 

00560> XCTAB:	L<- SAD, TASK, :FINJMP;	JMP
XJSR:	T_ SAD, :FINJSR;	JSR
XISZ:	MAR_ SAD, :ISZ1;	ISZ
XDSZ:	MAR_ SAD, :DSZ1;	DSZ
XLDA:	MAR_ SAD, :FINLOAD;	LDA 0-3
XSTA:	MAR_ SAD;		/*NORMAL
	L_ ACDEST, :FINSTO;	/*NORMAL

;	BOUNDS-CHECKING VERSION OF STORE
;	SUBST ";**<CR>" TO "<CR>;**" TO ENABLE THIS CODE:
;**	!1,2,XSTA1,XSTA2;
;**	!1,2,DOSTA,TRAPSTA;
;**XSTA:	MAR_ 10;	LOCS 10,11 CONTAINS HI,LO BOUNDS
;**	T_ SAD
;**	L_ MD-T;	HIGHBOUND-ADDR
;**	T_ MD, ALUCY;
;**	L_ SAD-T, :XSTA1;	ADDR-LOWBOUND
;**XSTA1:	TASK, :XSTA3;
;**XSTA2:	ALUCY, TASK;
;**XSTA3:	L_ 177, :DOSTA;
;**TRAPSTA:	XREG_ L, :TRAP1;	CAUSE A SWAT
;**DOSTA:	MAR_ SAD;	DO THE STORE NORMALLY
;**	L_ ACDEST, :FINSTO;
;**

DSZ1:	T_ ALLONES, :FINISZ;
ISZ1:	T_ ONE, :FINISZ;

00452> FINSTO:	SAD_ L,TASK;
00646> FINST1:	MD_SAD, :START;

FINLOAD: NOP;
LOADX:	L_ MD, TASK;
LOADD:	ACDEST_ L, :START;

FINISZ:	L_ MD+T;
	MAR_ SAD, SH=0;
	SAD_ L, :FINSTO;

INCPC:	L_ PC+1;
	PC_ L, TASK, :FINST1;

;DIVIDE.  THIS DIVIDE IS IDENTICAL TO THE NOVA DIVIDE EXCEPT THAT
;IF THE DIVIDE CANNOT BE DONE, THE INSTRUCTION FAILS TO SKIP, OTHERWISE
;IT DOES.  CARRY IS UNDISTURBED.

!1,2,DODIV,NODIV;
!1,2,DIVL,ENDDIV;
!1,2,NOOVF,OVF;
!1,2,DX0,DX1;
!1,2,NOSUB,DOSUB;

DIV:	T_ AC2;
DIVX:	L_ AC0 - T;	DO THE DIVIDE ONLY IF AC2>AC0
	ALUCY, TASK, SAD_ L, L_ 0+1;
	:DODIV, SAD_ L LSH 1;		SAD_ 2.  COUNT THE LOOP BY SHIFTING

NODIV:	:FINBLT;		***X21 change.
DODIV:	L_ AC0, :DIV1;

DIVL:	L_ AC0;
DIV1:	SH<0, T_ AC1;	WILL THE LEFT SHIFT OF THE DIVIDEND OVERFLOW?
	:NOOVF, AC0_ L MLSH 1, L_ T_ 0+T;	L_ AC1, T_ 0

OVF:	AC1_ L LSH 1, L_ 0+INCT, :NOV1;		L_ 1. SHIFT OVERFLOWED
NOOVF:	AC1_ L LSH 1 , L_ T;			L_ 0. SHIFT OK

NOV1:	T_ AC2, SH=0;
	L_ AC0-T, :DX0;

DX1:	ALUCY;		DO THE TEST ONLY IF THE SHIFT DIDN'T OVERFLOW.  IF 
;			IT DID, L IS STILL CORRECT, BUT THE TEST WOULD GO
;			THE WRONG WAY.
	:NOSUB, T_ AC1;

DX0:	:DOSUB, T_ AC1;

DOSUB:	AC0_ L, L_ 0+INCT;	DO THE SUBTRACT
	AC1_ L;			AND PUT A 1 IN THE QUOTIENT

NOSUB:	L_ SAD, BUS=0, TASK;
	SAD_ L LSH 1, :DIVL;

ENDDIV:	L_ PC+1, TASK, :DOIT; ***X21 change. Skip if divide was done.


;MULTIPLY.  THIS IS AN EXACT EMULATION OF NOVA HARDWARE MULTIPLY.
;AC2 IS THE MULTIPLIER, AC1 IS THE MULTIPLICAND.
;THE PRODUCT IS IN AC0 (HIGH PART), AND AC1 (LOW PART).
;PRECISELY: AC0,AC1 _ AC1*AC2  + AC0

!1,2,DOMUL,NOMUL;
!1,2,MPYL,MPYA;
!1,2,NOADDIER,ADDIER;
!1,2,NOSPILL,SPILL;
!1,2,NOADDX,ADDX;
!1,2,NOSPILLX,SPILLX;


MUL:	L_ AC2-1, BUS=0;
MPYX:	XREG_L,L_ 0, :DOMUL;	GET HERE WITH AC2-1 IN L. DON'T MUL IF AC2=0
DOMUL:	TASK, L_ -10+1;
	SAD_ L;		COUNT THE LOOP IN SAD

MPYL:	L_ AC1, BUSODD;
	T_ AC0, :NOADDIER;

NOADDIER: AC1_ L MRSH 1, L_ T, T_ 0, :NOSPILL;
ADDIER:	L_ T_ XREG+INCT;
	L_ AC1, ALUCY, :NOADDIER;

SPILL:	T_ ONE;
NOSPILL: AC0_ L MRSH 1;
	L_ AC1, BUSODD;
	T_ AC0, :NOADDX;

NOADDX:	AC1_ L MRSH 1, L_ T, T_ 0, :NOSPILLX;
ADDX:	L_ T_ XREG+ INCT;
	L_ AC1,ALUCY, :NOADDX;

SPILLX:	T_ ONE;
NOSPILLX: AC0_ L MRSH 1;
	L_ SAD+1, BUS=0, TASK;
	SAD_ L, :MPYL;

NOMUL:	T_ AC0;
	AC0_ L, L_ T, TASK;	CLEAR AC0
	AC1_ L;			AND REPLACE AC1 WITH AC0
MPYA:	:FINBLT;		***X21 change.

;CYCLE AC0 LEFT BY DISP MOD 20B, UNLESS DISP=0, IN WHICH
;CASE CYCLE BY AC1 MOD 20B
;LEAVES AC1 = CYCLE COUNT-1 MOD 20B

$CYRET		$R5;	Shares space with SAD.
$CYCOUT		$R7;	Shares space with XREG.

!1,2,EMCYCX,ACCYCLE;
!1,1,Y1;
!1,1,Y2;
!1,1,Y3;
!1,1,Z1;
!1,1,Z2;
!1,1,Z3;

EMCYCLE: L_ DISP, SINK_ X17, BUS=0;	CONSTANT WITH BS=7
CYCP:	T_ AC0, :EMCYCX;

ACCYCLE: T_ AC1;
	L_ 17 AND T, :CYCP;

EMCYCX: CYCOUT_L, L_0, :RETCYCX;

RAMCYCX: CYCOUT_L, L_0+1;

RETCYCX: CYRET_L, L_0+T;
	SINK_CYCOUT, BUS;
	TASK, :L0;

;TABLE FOR CYCLE
R4:	CYCOUT_ L MRSH 1;
Y3:	L_ T_ CYCOUT, TASK;
R3X:	CYCOUT_ L MRSH 1;
Y2:	L_ T_ CYCOUT, TASK;
R2X:	CYCOUT_ L MRSH 1;
Y1:	L_ T_ CYCOUT, TASK;
R1X:	CYCOUT_ L MRSH 1, :ENDCYCLE;

L4:	CYCOUT_ L MLSH 1;
Z3:	L_ T_ CYCOUT, TASK;
L3:	CYCOUT_ L MLSH 1;
Z2:	L_ T_ CYCOUT, TASK;
L2:	CYCOUT_ L MLSH 1;
Z1:	L_ T_ CYCOUT, TASK;
L1:	CYCOUT_ L MLSH 1, :ENDCYCLE;
L0:	CYCOUT_ L, :ENDCYCLE;

L8:	CYCOUT_ L LCY 8, :ENDCYCLE;
L7:	CYCOUT_ L LCY 8, :Y1;
L6:	CYCOUT_ L LCY 8, :Y2;
L5:	CYCOUT_ L LCY 8, :Y3;

R7:	CYCOUT_ L LCY 8, :Z1;
R6:	CYCOUT_ L LCY 8, :Z2;
R5:	CYCOUT_ L LCY 8, :Z3;

ENDCYCLE: SINK_ CYRET, BUS, TASK;
	:EMCYCRET;

EMCYCRET: L_CYCOUT, TASK, :LOADD;

RAMCYCRET: T_PC, BUS, SWMODE, :TORAM;

; Scan convert instruction for characters. Takes DWAX (Destination
; word address)-NWRDS in AC0, and a pointer to a .AL-format font
; in AC3. AC2+displacement contains a pointer to a two-word block
; containing NWRDS and DBA (Destination Bit Address).

$XH		$R10;
$DWAX		$R35;
$MASK		$R36;

!1,2,HDLOOP,HDEXIT;
!1,2,MERGE,STORE;
!1,2,NFIN,FIN;
!17,2,DOBOTH,MOVELOOP;

CONVERT: MAR_XREG+1;	Got here via indirect mechanism which
;			left first arg in SAD, its address in XREG. 
	T_17;
	L_MD AND T;

	T_MAR_AC3;
	AC1_L;		AC1_DBA&#17
	L_MD+T, TASK;
	AC3_L;		AC3_Character descriptor block address(Char)

	MAR_AC3+1;
	T_177400;
	IR_L_MD AND T;		IR_XH
	XH_L LCY 8, :ODDCX;	XH register temporarily contains HD
ODDCX:	L_AC0, :HDENTER;

HDLOOP: T_SAD;			(really NWRDS)
	L_DWAX+T;

HDENTER: DWAX_L;		DWAX _ AC0+HD*NWRDS
	L_XH-1, BUS=0, TASK;
	XH_L, :HDLOOP;

HDEXIT:	T_MASKTAB;
	MAR_T_AC1+T;		Fetch the mask.
	L_DISP;
	XH_L;			XH register now contains XH
	L_MD;
	MASK_L, L_0+T+1, TASK;
	AC1_L;			***X21. AC1 _ (DBA&#17)+1

	L_5;			***X21. Calling conventions changed.
	IR_SAD, TASK;
	CYRET_L, :MOVELOOP;	CYRET_CALL5

MOVELOOP: L_T_XH-1, BUS=0;
	MAR_AC3-T-1, :NFIN;	Fetch next source word
NFIN:	XH_L;
	T_DISP;			(really NWRDS)
	L_DWAX+T;		Update destination address
	T_MD;
	SINK_AC1, BUS;
	DWAX_L, L_T, TASK, :L0;	Call Cycle subroutine

CONVCYCRET: MAR_DWAX;
	T_MASK, BUS=0;
	T_CYCOUT.T, :MERGE;	Data for first word. If MASK=0
				; then store the word rather than
				; merging, and do not disturb the
				; second word.
MERGE:	L_XREG AND NOT T;	Data for second word.
	T_MD OR T;		First word now merged,
	MAR_DWAX;			restore it.
	XREG_L, L_T;
	MTEMP_L;
	SINK_XREG, BUS=0, TASK;
	MD_MTEMP, :DOBOTH;	XREG=0 means only one word
				; is involved.

DOBOTH: MAR_DWAX+1;
	T_XREG;
	L_MD OR T;
	MAR_DWAX+1;
	XREG_L, TASK;		***X21. TASK added.
STORE:	MD_XREG, :MOVELOOP;

FIN:	L_AC1-1;		***X21. Return AC1 to DBA&#17.
	AC1_L;			*** ... bletch ...
	IR_SH3CONST;
	L_MD, TASK, :SH1;


;RCLK - 61003 - Read the Real Time Clock into AC0,AC1
RCLK:	MAR_ CLOCKLOC;
	L_ R37;
	AC1_ L, :LOADX;

;SIO - 61004 - Put AC0 on the bus, issue STARTF,
;Read Host address from Ethernet interface into AC0.
SIO:	L_ AC0, STARTF;
	T_77777;		***X21 sets AC0[0] to 0
	L_ RSNF AND T;
LTOAC0:	AC0_ L, TASK, :TOSTART;


;ENGBUILD is a constant returned by VERS that contains a discription
;of the Alto and it's Microcode. The conposition of ENGBUILD is:
;	bits 0-3	Alto engineering number
;	bits 4-7	Alto build
;	bits 8-15	Version number of Microcode
;Use of the Alto Build number has been abandoned.
$EngNumber	$1;	This is an Alto I

VERS:	T_ EngNumber;		***X21 addition
	L_ 3+T, :LTOAC0;	Altocode24 is called ucode version 3

;BLT - 61005 - Block Transfer
;BLKS - 61006 - Block Store
; Accepts in
;	AC0/ BLT: Address of first word of source block-1
;	     BLKS: Data to be stored
;	AC1/ Address of last word of destination block 
;	AC3/ NEGATIVE word count
; Leaves
;	AC0/ BLT: Address of last word of source block+1
;	     BLKS: Unchanged
;	AC1/ Unchanged
;	AC2/ Unchanged
;	AC3/ 0
; These instructions are interruptable.  If an interrupt occurs,
; the PC is decremented by one, and the ACs contain the intermediate
; so the instruction can be restarted when the interrupt is dismissed.

!1,2,PERHAPS, NO;

BLT:	L_ MAR_ AC0+1;
	AC0_ L;
	L_ MD, :BLKSA;

BLKS:	L_ AC0;
BLKSA:	T_ AC3+1, BUS=0;
	MAR_ AC1+T, :MOREBLT;

MOREBLT: XREG_ L, L_ T;
	AC3_ L, TASK;
	MD_ XREG;		STORE
	L_ NWW, BUS=0;		CHECK FOR INTERRUPT
	SH<0, :PERHAPS, L_ PC-1;	Prepare to back up PC.

NO:	SINK_ DISP, SINK_ M7, BUS, :DISABLED;

PERHAPS:SINK_ DISP, SINK_ M7, BUS, :DOIT;

DOIT:	PC_L, :FINBLT;	***X21. Reset PC, terminate instruction.

DISABLED::DIR;	GOES TO BLT OR BLKS

FINBLT:	T_777;	***X21. PC in [177000-177777] means Ram return
	L_PC+T+1;
	L_PC AND T, TASK, ALUCY;
TOSTART: XREG_L, :START;

RAMRET: T_XREG, BUS, SWMODE;
TORAM:	:NOVEM;

;PARAMETERLESS INSTRUCTIONS FOR DIDDLING THE WCS.

;JMPRAM - 61010 - JUMP TO THE RAM ADDRESS SPECIFIED BY AC1
JMPR:	T_AC1, BUS, SWMODE, :TORAM;


;RDRAM - 61011 - READ THE RAM WORD ADDRESSED BY AC1 INTO AC0
RDRM:	T_ AC1, RDRAM;
	L_ ALLONES, TASK, :LOADD;


;WRTRAM - 61012 - WRITE AC0,AC3 INTO THE RAM LOCATION ADDRESSED BY AC1
WTRM:	T_ AC1;
	L_ AC0, WRTRAM;
	L_ AC3, :FINBLT;

;INTERRUPT SYSTEM.  TIMING IS 0 CYCLES IF DISABLED, 18 CYCLES
;IF THE INTERRUPTING CHANEL IS INACTIVE, AND 36+6N CYCLES TO CAUSE
;AN INTERRUPT ON CHANNEL N

EM00567> INTCODE:PC<- L, IR<- 0;	
EM01107>	T<- NWW;
EM01110>	T<- MD OR T;
EM01111>	L<- MD AND T;
EM01112>	SAD<- L, L<- T, SH=0;		SAD HAD POTENTIAL INTERRUPTS
EM01113>	NWW<- L, L<- 0+1, :SOMEACTIVE;	NWW HAS NEW WW

EM00537> NOACTIVE: MAR<- WWLOC;		RESTORE WW TO CORE
EM01114>	L<- SAD;			AND REPLACE IT WITH SAD IN NWW
EM01115>	MD<- NWW, TASK;
EM01116> INTZ:	NWW<- L, :START;

EM00536> SOMEACTIVE: MAR<- PCLOC;	STORE PC AND SET UP TO FIND HIGHEST PRIORITY REQUEST
EM01117>	XREG<- L, L<- 0;
EM01120>	MD<- PC, TASK;

EM01121> ILPA:	PC<- L;
EM01122> ILP:	T<- SAD;
EM01123> 	L<- T<- XREG AND T;
EM01124>	SH=0, L<- T, T<- PC;
EM01125>	:IEXIT, XREG<- L LSH 1;

NIEXIT:	L_ 0+T+1, TASK, :ILPA;
EM00570> IEXIT:	MAR<- PCLOC+T+1;		FETCH NEW PC. T HAS CHANNEL #, L HAS MASK

EM01126>	XREG<- L;
EM01127>	T<- XREG;
EM01130>	L<- NWW XOR T;	TURN OFF BIT IN WW FOR INTERRUPT ABOUT TO HAPPEN
EM01131>	T<- MD;
EM01132>	NWW<- L, L<- T;
EM01133>	PC<- L, L<- T<- 0+1, TASK;
EM01134>	SAD<- L MRSH 1, :NOACTIVE;	SAD_ 1B5 TO DISABLE INTERRUPTS

;
;	************************
;	* BIT-BLT - 61024 *
;	************************
;
;	/* NOVA REGS
;	AC2 -> BLT DESCRIPTOR TABLE, AND IS PRESERVED
;	AC1 CARRIES LINE COUNT FOR RESUMING AFTER AN
;		INTERRUPT. MUST BE 0 AT INITIAL CALL
;	AC0 AND AC3 ARE SMASHED TO SAVE S-REGS
;
;	/* ALTO REGISTER USAGE
;DISP CARRIES:	TOPLD(100), SOURCE(14), OP(3)

$MASK1		$R0;
$YMUL		$R2;	HAS TO BE AN R-REG FOR SHIFTS
$RETN		$R2;
$SKEW		$R3;
$TEMP		$R5;
$WIDTH		$R7;
$PLIER		$R7;	HAS TO BE AN R-REG FOR SHIFTS
$DESTY		$R10;
$WORD2		$R10;
$STARTBITSM1	$R35;
$SWA		$R36;
$DESTX		$R36;
$LREG		$R40;	HAS TO BE R40 (COPY OF L-REG)
$NLINES		$R41;
$RAST1		$R42;
$SRCX		$R43;
$SKMSK		$R43;
$SRCY		$R44;
$RAST2		$R44;
$CONST		$R45;
$TWICE		$R45;
$HCNT		$R46;
$VINC		$R46;
$HINC		$R47;
$NWORDS		$R50;
$MASK2		$R51;	WAS $R46;
;
$LASTMASKP1	$500;	MASKTABLE+021
$170000		$170000;
$CALL3		$3;	SUBROUTINE CALL INDICES
$CALL4		$4;
$DWAOFF		$2;	BLT TABLE OFFSETS
$DXOFF		$4;
$DWOFF		$6;
$DHOFF		$7;
$SWAOFF		$10;
$SXOFF		$12;
$GRAYOFF	$14;	GRAY IN WORDS 14-17
$LASTMASK	$477;	MASKTABLE+020	**NOT IN EARLIER PROMS!


;	BITBLT SETUP - CALCULATE RAM STATE FROM AC2'S TABLE
;----------------------------------------------------------
;
;	/* FETCH COORDINATES FROM TABLE
	!1,2,FDDX,BLITX;
	!1,2,FDBL,BBNORAM;
	!17,20,FDBX,,,,FDX,,FDW,,,,FSX,,,,,;	FDBL RETURNS (BASED ON OFFSET)
;	        (0)     4    6      12
BITBLT:	L_ 0;
	SINK_ LREG, BUSODD;	SINK_ -1 IFF NO RAM
	L_ T_ DWOFF, :FDBL;
BBNORAM: TASK, :NPTRAP;		TRAP IF NO RAM
;
FDW:	T_ MD;			PICK UP WIDTH, HEIGHT
	WIDTH_ L, L_ T, TASK, :NZWID;
NZWID:	NLINES_ L;
	T_ AC1;
	L_ NLINES-T;
	NLINES_ L, SH<0, TASK;
	:FDDX;
;
FDDX:	L_ T_ DXOFF, :FDBL;	PICK UP DEST X AND Y
FDX:	T_ MD;
	DESTX_ L, L_ T, TASK;
	DESTY_ L;
;
	L_ T_ SXOFF, :FDBL;	PICK UP SOURCE X AND Y
FSX:	T_ MD;
	SRCX_ L, L_ T, TASK;
	SRCY_ L, :CSHI;
;
;	/* FETCH DOUBLEWORD FROM TABLE (L_ T_ OFFSET, :FDBL)
FDBL:	MAR_ AC2+T;
	SINK_ LREG, BUS;
FDBX:	L_ MD, :FDBX;
;
;	/* CALCULATE SKEW AND HINC
	!1,2,LTOR,RTOL;
CSHI:	T_ DESTX;
	L_ SRCX-T-1;
	T_ LREG+1, SH<0;	TEST HORIZONTAL DIRECTION
	L_ 17.T, :LTOR;	SKEW _ (SRCX - DESTX) MOD 16
RTOL:	SKEW_ L, L_ 0-1, :AH, TASK;	HINC _ -1
LTOR:	SKEW_ L, L_ 0+1, :AH, TASK;	HINC _ +1
AH:	HINC_ L;
;
;	CALCULATE MASK1 AND MASK2
	!1,2,IFRTOL,LNWORDS;
	!1,2,POSWID,NEGWID;
CMASKS:	T_ DESTX;
	T_ 17.T;
	MAR_ LASTMASKP1-T-1;
	L_ 17-T;		STARTBITS _ 16 - (DESTX.17)
	STARTBITSM1_ L;
	L_ MD, TASK;
	MASK1_ L;		MASK1 _ @(MASKLOC+STARTBITS)
	L_ WIDTH-1;
	T_ LREG-1, SH<0;
	T_ DESTX+T+1, :POSWID;
POSWID:	T_ 17.T;
;	T_ 0+T+1;	**
;	MAR_ LASTMASKP1-T-1;	**REPLACE THESE 2 BY 1 BELOW IN #21
	MAR_ LASTMASK-T-1;
	T_ ALLONES;		MASK2 _ NOT
	L_ HINC-1;
	L_ MD XOR T, SH=0, TASK;	@(MASKLOC+(15-((DESTX+WIDTH-1).17)))
	MASK2_ L, :IFRTOL;
;	/* IF RIGHT TO LEFT, ADD WIDTH TO X'S AND EXCH MASK1, MASK2
IFRTOL:	T_ WIDTH-1;	WIDTH-1
	L_ SRCX+T;
	SRCX_ L;		SRCX _ SCRX + (WIDTH-1)
	L_ DESTX+T;
	DESTX_ L;	DESTX _ DESTX + (WIDTH-1)
	T_ DESTX;
	L_ 17.T, TASK;
	STARTBITSM1_ L;	STARTBITS _ (DESTX.17) + 1
	T_ MASK1;
	L_ MASK2;
	MASK1_ L, L_ T,TASK;	EXCHANGE MASK1 AND MASK2
	MASK2_L;
;
;	/* CALCULATE NWORDS
	!1,2,LNW1,THIN;
LNWORDS:T_ STARTBITSM1+1;
	L_ WIDTH-T-1;
	T_ 177760, SH<0;
	T_ LREG.T, :LNW1;
LNW1:	L_ CALL4;		NWORDS _ (WIDTH-STARTBITS)/16
	CYRET_ L, L_ T, :R4, TASK; CYRET_CALL4
;	**WIDTH REG NOW FREE**
CYX4:	L_ CYCOUT, :LNW2;
THIN:	T_ MASK1;	SPECIAL CASE OF THIN SLICE
	L_MASK2.T;
	MASK1_ L, L_ 0-1;	MASK1 _ MASK1.MASK2, NWORDS _ -1
LNW2:	NWORDS_ L;	LOAD NWORDS
;	**STARTBITSM1 REG NOW FREE**
;
;	/* DETERMINE VERTICAL DIRECTION
	!1,2,BTOT,TTOB;
	T_ SRCY;
	L_ DESTY-T;
	T_ NLINES-1, SH<0;
	L_ 0, :BTOT;	VINC _ 0 IFF TOP-TO-BOTTOM
BTOT:	L_ ALLONES;	ELSE -1
BTOT1:	VINC_ L;
	L_ SRCY+T;		GOING BOTTOM TO TOP
	SRCY_ L;			ADD NLINES TO STARTING Y'S
	L_ DESTY+T;
	DESTY_ L, L_ 0+1, TASK;
	TWICE_L, :CWA;
;
TTOB:	T_ AC1, :BTOT1;		TOP TO BOT, ADD NDONE TO STARTING Y'S
;	**AC1 REG NOW FREE**;
;
;	/* CALCULATE WORD ADDRESSES - DO ONCE FOR SWA, THEN FOR DWAX
CWA:	L_ SRCY;	Y HAS TO GO INTO AN R-REG FOR SHIFTING
	YMUL_ L;
	T_ SWAOFF;		FIRST TIME IS FOR SWA, SRCX
	L_ SRCX;
;	**SRCX, SRCY REG NOW FREE**
DOSWA:	MAR_ AC2+T;		FETCH BITMAP ADDR AND RASTER
	XREG_ L;
	L_CALL3;
	CYRET_ L;		CYRET_CALL3
	L_ MD;
	T_ MD;
	DWAX_ L, L_T, TASK;
	RAST2_ L;
	T_ 177760;
	L_ T_ XREG.T, :R4, TASK;	SWA _ SWA + SRCX/16
CYX3:	T_ CYCOUT;
	L_ DWAX+T;
	DWAX_ L;
;
	!1,2,NOADD,DOADD;
	!1,2,MULLP,CDELT;	SWA _ SWA + SRCY*RAST1
	L_ RAST2;
	SINK_ YMUL, BUS=0, TASK;	NO MULT IF STARTING Y=0
	PLIER_ L, :MULLP;
MULLP:	L_ PLIER, BUSODD;		MULTIPLY RASTER BY Y
	PLIER_ L RSH 1, :NOADD;
NOADD:	L_ YMUL, SH=0, TASK;	TEST NO MORE MULTIPLIER BITS
SHIFTB:	YMUL_ L LSH 1, :MULLP;
DOADD:	T_ YMUL;
	L_ DWAX+T;
	DWAX_ L, L_T, :SHIFTB, TASK;
;	**PLIER, YMUL REG NOW FREE**
;
	!1,2,HNEG,HPOS;
	!1,2,VPOS,VNEG;
	!1,1,CD1;	CALCULATE DELTAS = +-(NWORDS+2)[HINC] +-RASTER[VINC]
CDELT:	L_ T_ HINC-1;	(NOTE T_ -2 OR 0)
	L_ T_ NWORDS-T, SH=0;	(L_NWORDS+2 OR T_NWORDS)
CD1:	SINK_ VINC, BUSODD, :HNEG;
HNEG:	T_ RAST2, :VPOS;
HPOS:	L_ -2-T, :CD1;	(MAKES L_-(NWORDS+2))
VPOS:	L_ LREG+T, :GDELT, TASK;	BY NOW, LREG = +-(NWORDS+2)
VNEG:	L_ LREG-T, :GDELT, TASK;	AND T = RASTER
GDELT:	RAST2_ L;
;
;	/* END WORD ADDR LOOP
	!1,2,ONEMORE,CTOPL;
	L_ TWICE-1;
	TWICE_ L, SH<0;
	L_ RAST2, :ONEMORE;	USE RAST2 2ND TIME THRU
ONEMORE:	RAST1_ L;
	L_ DESTY, TASK;	USE DESTY 2ND TIME THRU
	YMUL_ L;
	L_ DWAX;		USE DWAX 2ND TIME THRU
	T_ DESTX;	CAREFUL - DESTX=SWA!!
	SWA_ L, L_ T;	USE DESTX 2ND TIME THRU
	T_ DWAOFF, :DOSWA;	AND DO IT AGAIN FOR DWAX, DESTX
;	**TWICE, VINC REGS NOW FREE**
;
;	/* CALCULATE TOPLD
	!1,2,CTOP1,CSKEW;
	!1,2,HM1,H1;
	!1,2,NOTOPL,TOPL;
CTOPL:	L_ SKEW, BUS=0, TASK;	IF SKEW=0 THEN 0, ELSE
CTX:	IR_ 0, :CTOP1;
CTOP1:	T_ SRCX;	(SKEW GR SRCX.17) XOR (HINC EQ 0)
	L_ HINC-1;
	T_ 17.T, SH=0;	TEST HINC
	L_ SKEW-T-1, :HM1;
H1:	T_ HINC, SH<0;
	L_ SWA+T, :NOTOPL;
HM1:	T_ LREG;		IF HINC=-1, THEN FLIP
	L_ 0-T-1, :H1;	THE POLARITY OF THE TEST
NOTOPL:	SINK_ HINC, BUSODD, TASK, :CTX;	HINC FORCES BUSODD
TOPL:	SWA_ L, TASK;		(DISP _ 20 FOR TOPLD)
	IR_ 20, :CSKEW;
;	**HINC REG NOW FREE**
;
;	/* CALCULATE SKEW MASK
	!1,2,THINC,BCOM1;
	!1,2,COMSK,NOCOM;
CSKEW:	T_ SKEW, BUS=0;	IF SKEW=0, THEN COMP
	MAR_ LASTMASKP1-T-1, :THINC;
THINC:	L_HINC-1;
	SH=0;			IF HINC=-1, THEN COMP
BCOM1:	T_ ALLONES, :COMSK;
COMSK:	L_ MD XOR T, :GFN;
NOCOM:	L_ MD, :GFN;
;
;	/* GET FUNCTION
GFN:	MAR_ AC2;
	SKMSK_ L;
	T_ 17;	**THIS MASK IS ONLY FOR SAFETY
	T_ MD.T;
	L_ DISP+T, TASK;
	IR_ LREG, :BENTR;		DISP _ DISP .OR. FUNCTION

;	BITBLT WORK - VERT AND HORIZ LOOPS WITH 4 SOURCES, 4 FUNCTIONS
;-----------------------------------------------------------------------
;
;	/* VERTICAL LOOP: UPDATE SWA, DWAX
	!1,2,DO0,VLOOP;
VLOOP:	T_ SWA;
	L_ RAST1+T;	INC SWA BY DELTA
	SWA_ L;
	T_ DWAX;
	L_ RAST2+T, TASK;	INC DWAX BY DELTA
	DWAX_ L;
;
;	/* TEST FOR DONE, OR NEED GRAY
	!1,2,MOREV,DONEV;
	!1,2,BMAYBE,BNOINT;
	!1,2,BDOINT,BDIS0;
	!1,2,DOGRAY,NOGRAY;
BENTR:	L_ T_ NLINES-1;		DECR NLINES AND CHECK IF DONE
	NLINES_ L, SH<0;
	L_ NWW, BUS=0, :MOREV;	CHECK FOR INTERRUPTS
MOREV:	L_ 3.T, :BMAYBE, SH<0;	CHECK DISABLED
BNOINT:	SINK_ DISP, SINK_ lgm10, BUS=0, :BDIS0, TASK;
BMAYBE:	SINK_ DISP, SINK_ lgm10, BUS=0, :BDOINT, TASK;	TEST IF NEED GRAY(FUNC=8,12)
BDIS0:	CONST_ L, :DOGRAY;
;
;	/* INTERRUPT SUSPENSION (POSSIBLY)
	!1,1,DOI1;	MAY GET AN OR-1
BDOINT:	:DOI1;	TASK HERE
DOI1:	T_ AC2;
	MAR_ DHOFF+T;		NLINES DONE = HT-NLINES-1
	T_ NLINES;
	L_ PC-1;		BACK UP THE PC, SO WE GET RESTARTED
	PC_ L;
	L_ MD-T-1, :BLITX, TASK;	...WITH NO LINES DONE IN AC1
;
;	/* LOAD GRAY FOR THIS LINE (IF FUNCTION NEEDS IT)
	!1,2,PRELD,NOPLD;
DOGRAY:	T_ CONST-1;
	T_ GRAYOFF +T+1;
	MAR_ AC2+T;
	NOP;	UGH
	L_ MD;
NOGRAY:	SINK_ DISP, SINK_ lgm100, BUS=0, TASK;	TEST TOPLD
	CONST_ L, :PRELD;
;
;	/* NORMAL COMPLETION
NEGWID:	L_ 0, :BLITX, TASK;
DONEV:	L_ 0, :BLITX, TASK;	MAY BE AN OR-1 HERE!
BLITX:	AC1_ L, :FINBLT;
;
;	/* PRELOAD OF FIRST SOURCE WORD (DEPENDING ON ALIGNMENT)
PRELD:	T_ HINC;
	MAR_ SWA-T;	PRELOAD SOURCE PRIOR TO MAIN LOOP
	NOP;
	L_ MD, TASK;
	WORD2_ L, :NOPLD;
;
;
;	/* HORIZONTAL LOOP - 3 CALLS FOR 1ST, MIDDLE AND LAST WORDS
	!1,2,FDISPA,LASTH;
	%17,17,14,DON0,,DON2,DON3;		CALLERS OF HORIZ LOOP
;	NOTE THIS IGNORES 14-BITS, SO lgm14 WORKS LIKE L_0 FOR RETN
	!14,1,LH1;	IGNORE RESULTING BUS
NOPLD:	L_ 3, :FDISP;		CALL #3 IS FIRST WORD
DON3:	L_ NWORDS;
	HCNT_ L, SH<0;		HCNT COUNTS WHOLE WORDS
DON0:	L_ HCNT-1, :DO0;	IF NEG, THEN NO MIDDLE OR LAST
DO0:	HCNT_ L, SH<0;		CALL #0 (OR-14!) IS MIDDLE WORDS
;	UGLY HACK SQUEEZES 2 INSTRS OUT OF INNER LOOP:
	L_ DISP, SINK_ lgm14, BUS, TASK, :FDISPA;	(WORKS LIKE L_0)
LASTH:	:LH1;	TASK AND BUS PENDING
LH1:	L_ 2, :FDISP;		CALL #2 IS LAST WORD
DON2:	:VLOOP;
;
;
;	/* HERE ARE THE SOURCE FUNCTIONS
	!17,20,,,,F0,,,,F1,,,,F2,,,,F3;	IGNORE OP BITS IN FUNCTION CODE
	!17,20,,,,F0A,,,,F1A,,,,F2A,,,,;	SAME FOR WINDOW RETURNS
	!3,4,OP0,OP1,OP2,OP3;
FDISP:	SINK_ DISP, SINK_lgm14, BUS, TASK;
FDISPA:	RETN_ L, :F0;
F0:	:WIND;			FUNC 0 - WINDOW
F1:	:WIND;			FUNC 1 - NOT WINDOW
F1A:	T_ CYCOUT;
	L_ ALLONES XOR T, TASK, :F3A;
F2:	:WIND;			FUNC 2 - WINDOW .AND. GRAY
F2A:	T_ CYCOUT;
	L_ ALLONES XOR T;
	TEMP_ L;		TEMP _ NOT WINDOW
	MAR_ DWAX;
	L_ CONST AND T;		WINDOW .AND. GRAY
	T_ TEMP;
	T_ MD .T;		DEST.AND.NOT WINDOW
	L_ LREG OR T, TASK, :F3A;	(TRANSPARENT)
F3:	L_ CONST, TASK;	FUNC 3 - CONSTANT (COLOR)
F3A:	CYCOUT_ L;
;
;
;	/* HERE ARE THE OPERATIONS - ENTER WITH SOURCE IN CYCOUT
	%16,17,15,STFULL,STMSK;	MASKED OR FULL STORE (LOOK AT 2-BIT)
F0A:	SINK_ DISP, SINK_ lgm3, BUS;	DISPATCH ON OP
OPX:	T_ MAR_ DWAX, :OP0;	OP 0 - SOURCE
OP0:	SINK_ RETN, BUS;	TEST IF UNMASKED
OP0A:	L_ HINC+T, :STFULL;	ELSE :STMSK
OP1:	T_ CYCOUT;		OP 1 - SOURCE .OR. DEST
	L_ MD OR T, :OPN, TASK;
OP2:	T_ CYCOUT;		OP 2 - SOURCE .XOR. DEST
	L_ MD XOR T, :OPN, TASK;
OP3:	T_ CYCOUT;		OP 3 - (NOT SOURCE) .AND. DEST
	L_ 0-T-1;
	T_ LREG;
	L_ MD AND T, TASK;
OPN:	CYCOUT_ L, :OPX;
;
;
;	/* STORE MASKED INTO DESTINATION
	!1,2,STM2,STM1;
STMSK:	L_ MD;
	SINK_ RETN, BUSODD, TASK;	DETERMINE MASK FROM CALL INDEX
	TEMP_ L, :STM2;		STACHE DEST WORD IN TEMP
STM1:	T_MASK1, :STM3;
STM2:	T_MASK2, :STM3;
STM3:	L_ CYCOUT AND T;  ***X24. Removed TASK clause.
	CYCOUT_ L, L_ 0-T-1;	AND INTO SOURCE
	T_ LREG;		T_ MASK COMPLEMENTED
	T_ TEMP .T;		AND INTO DEST
	L_ CYCOUT OR T, TASK;
	CYCOUT_ L;		OR TOGETHER THEN GO STORE
	T_ MAR_ DWAX, :OP0A;
;
;	/* STORE UNMASKED FROM CYCOUT (L=NEXT DWAX)
STFULL:	MD_ CYCOUT;
STFUL1:	SINK_ RETN, BUS, TASK;
	DWAX_ L, :DON0;
;
;
;	/* WINDOW SOURCE FUNCTION
;	TASKS UPON RETURN, RESULT IN CYCOUT
	!1,2,DOCY,NOCY;
	!17,1,WIA;
	!1,2,NZSK,ZESK;
WIND:	MAR_ SWA;		ENTER HERE (7 INST TO TASK)
	L_ T_ SKMSK;
	L_ WORD2.T, SH=0;
	CYCOUT_ L, L_ 0-T-1, :NZSK;	CYCOUT_ OLD WORD .AND. MSK
ZESK:	L_ MD;	ZERO SKEW BYPASSES LOTS
	CYCOUT_ L, :NOCY;
NZSK:	T_ MD;
	L_ LREG.T;
	TEMP_ L, L_T, TASK;	TEMP_ NEW WORD .AND. NOTMSK
	WORD2_ L;
	T_ TEMP;
	L_ T_ CYCOUT OR T;		OR THEM TOGETHER
	CYCOUT_ L, L_ 0+1, SH=0;	DONT CYCLE A ZERO ***X21.
	SINK_ SKEW, BUS, :DOCY;
DOCY:	CYRET_ L LSH 1, L_ T, :L0;	CYCLE BY SKEW ***X21.
NOCY:	T_ SWA, :WIA;	(MAY HAVE OR-17 FROM BUS)
CYX2:	T_ SWA;
WIA:	L_ HINC+T;
	SINK_ DISP, SINK_ lgm14, BUS, TASK;	DISPATCH TO CALLER 
	SWA_ L, :F0A;

;	THE DISK CONTROLLER

;	ITS REGISTERS:
$DCBR		$R34;
$KNMAR		$R33;
$CKSUMR		$R32;
$KWDCT		$R31;
$KNMARW		$R33;
$CKSUMRW	$R32;
$KWDCTW		$R31;

;	ITS TASK SPECIFIC FUNCTIONS AND BUS SOURCES:
$KSTAT		$L020012,014003,124100;	DF1 = 12 (LHS) BS = 3 (RHS)
$RWC		$L024011,000000,000000;	NDF2 = 11
$RECNO		$L024012,000000,000000;	NDF2 = 12
$INIT		$L024010,000000,000000;	NDF2 = 10
$CLRSTAT	$L016014,000000,000000;	NDF1 = 14
$KCOMM		$L020015,000000,124000;	DF1 = 15 (LHS only) Requires bus def
$SWRNRDY	$L024014,000000,000000;	NDF2 = 14
$KADR		$L020016,000000,124000;	DF1 = 16 (LHS only) Requires bus def
$KDATA		$L020017,014004,124100;	DF1 = 17 (LHS)  BS = 4 (RHS)
$STROBE		$L016011,000000,000000;	NDF1 = 11
$NFER		$L024015,000000,000000;	NDF2 = 15
$STROBON	$L024016,000000,000000;	NDF2 = 16
$XFRDAT		$L024013,000000,000000;	NDF2 = 13
$INCRECNO	$L016013,000000,000000;	NDF1 = 13

;	THE DISK CONTROLLER COMES IN TWO PARTS. THE SECTOR
;	TASK HANDLES DEVICE CONTROL AND COMMAND UNDERSTANDING
;	AND STATUS REPORTING AND THE LIKE. THE WORD TASK ONLY
;	RUNS AFTER BEING ENABLED BY THE SECTOR TASK AND
;	ACTUALLY MOVES DATA WORDS TO AND FRO. 

;   THE SECTOR TASK

;	LABEL PREDEFINITIONS:
!1,2,COMM,NOCOMM;
!1,2,COMM2,IDLE1;
!1,2,BADCOMM,COMM3;
!1,2,COMM4,ILLSEC;
!1,2,COMM5,WHYNRDY;
!1,2,STROB,CKSECT;
!1,2,STALL,CKSECT1;
!1,2,KSFINI,CKSECT2;
!1,2,IDLE2,TRANSFER;
!1,2,STALL2,GASP;
!1,2,INVERT,NOINVERT;

SE00004> KSEC:	MAR<- KBLKADR2;
SE01574> KPOQ:	CLRSTAT;	RESET THE STORED DISK ADDRESS
SE01575>	MD<-L<-ALLONES+1, :GCOM2;	ALSO CLEAR DCB POINTER

GETCOM:	MAR_KBLKADR;	GET FIRST DCB POINTER
GCOM1:	NOP;
	L_MD;
SE01601> GCOM2:	DCBR<-L,TASK;
SE01602>	KCOMM<-TOWTT;	IDLE ALL DATA TRANSFERS

SE01603>	MAR<-KBLKADR3;	GENERATE A SECTOR INTERRUPT
SE01604>	T<-NWW;
SE01605>	L<-MD OR T;

SE01606>	MAR<-KBLKADR+1;	STORE THE STATUS
SE01607>	NWW<-L, TASK;
SE01610>	MD<-KSTAT;

SE01611>	MAR<-KBLKADR;	WRITE THE CURRENT DCB POINTER
SE01612>	KSTAT<-5;	INITIAL STATUS IS INCOMPLETE
SE01613>	L<-DCBR,TASK,BUS=0;
SE01614>	MD<-DCBR, :COMM;

;	BUS=0 MAPS COMM TO NOCOMM

SE01546> COMM:	T<-2;	GET THE DISK COMMAND
SE01615>	MAR<-DCBR+T;
SE01616>	T<-TOTUWC;
SE01617>	L<-MD XOR T, TASK, STROBON;
SE01620>	KWDCT<-L, :COMM2;

;	STROBON MAPS COMM2 TO IDLE1

SE01550> COMM2:	T<-10;	READ NEW DISK ADDRESS
SE01621>	MAR<-DCBR+T+1;
SE01622>	T<-KWDCT;
SE01623>	L<-ONE AND T;
SE01624>	L<- -400 AND T, SH=0;
SE01625>	T<-MD, SH=0, :INVERT;

;	SH=0 MAPS INVERT TO NOINVERT

SE01572> INVERT:	L<-2 XOR T, TASK, :BADCOMM;
SE01573> NOINVERT: L<-T, TASK, :BADCOMM;

;	SH=0 MAPS BADCOMM TO COMM3

COMM3:	KNMAR_L;

SE01626>	MAR<-KBLKADR2;	WRITE THE NEW DISK ADDRESS
SE01627>	T<-SECT2CM;	CHECK FOR SECTOR > 13
SE01630>	L<-T<-KDATA<-KNMAR+T;	NEW DISK ADDRESS TO HARDWARE
SE01631>	KADR<-KWDCT,ALUCY;	DISK COMMAND TO HARDWARE
SE01632>	L<-MD XOR T,TASK, :COMM4;	COMPARE OLD AND NEW DISK ADDRESSES

;	ALUCY MAPS COMM4 TO ILLSEC

SE01554> COMM4:	CKSUMR<-L;

SE01633>	MAR<-KBLKADR2;	WRITE THE NEW DISK ADDRESS
SE01634>	T<-CADM,SWRNRDY;	SEE IF DISK IS READY
SE01635>	L<-CKSUMR AND T, :COMM5;

;	SWRNRDY MAPS COMM5 TO WHYNRDY

COMM5:	SH=0,TASK;
	MD_KNMAR, :STROB;	COMPLETE THE WRITE

;	SH=0 MAPS STROB TO CKSECT

CKSECT:	T_KNMAR,NFER;
	L_KSTAT XOR T, :STALL;

;	NFER MAPS STALL TO CKSECT1

CKSECT1: CKSUMR_L,XFRDAT;
	T_CKSUMR, :KSFINI;

;	XFRDAT MAPS KSFINI TO CKSECT2

CKSECT2: L_SECTMSK AND T;
KSLAST:	BLOCK,SH=0;
GASP:	TASK, :IDLE2;

;	SH=0 MAPS IDLE2 TO TRANSFER

TRANSFER: KCOMM_TOTUWC;	TURN ON THE TRANSFER

!1,2,ERRFND,NOERRFND;
!1,2,EF1,NEF1;

DMPSTAT: MAR_DCBR+1;	WRITE FINAL STATUS
	T_COMERR1;	SEE IF STATUS REPRESENTS ERROR
	L_KSTAT AND T;
	KWDCT_L,TASK,SH=0;
	MD_KSTAT,:ERRFND;

;	SH=0 MAPS ERRFND TO NOERRFND

NOERRFND: T_6;	PICK UP NO-ERROR INTERRUPT WORD

INTCOM:	MAR_DCBR+T;
	T_NWW;
	L_MD OR T;
	SINK_KWDCT,BUS=0,TASK;
	NWW_L,:EF1;

;	BUS=0 MAPS EF1 TO NEF1

NEF1:	MAR_DCBR,:GCOM1;	FETCH ADDRESS OF NEXT CONTROL BLOCK

ERRFND:	T_7,:INTCOM;	PICK UP ERROR INTERRUPT WORD

SE01646> EF1:	:KSEC;

NOCOMM:	L_ALLONES,CLRSTAT,:KSLAST;

IDLE1:	L_ALLONES,:KSLAST;

IDLE2:	KSTAT_LOW14, :GETCOM;	NO ACTIVITY THIS SECTOR

SE01552> BADCOMM: KSTAT<-7;	ILLEGAL COMMAND ONLY NOTED IN KBLK STAT
SE01661>	BLOCK;
SE01662>	TASK,:EF1;

WHYNRDY: NFER;
STALL:	BLOCK, :STALL2;

;	NFER MAPS STALL2 TO GASP

STALL2:	TASK;
	:DMPSTAT;

ILLSEC:	KSTAT_7, :STALL;	ILLEGAL SECTOR SPECIFIED

STROB:	CLRSTAT;
	L_ALLONES,STROBE,:CKSECT1;

KSFINI:	KSTAT_4, :STALL;	COMMAND FINISHED CORRECTLY


;DISK WORD TASK
;WORD TASK PREDEFINITIONS
!37,37,,,,RP0,INPREF1,CKP0,WP0,,PXFLP1,RDCK0,WRT0,REC1,,REC2,REC3,,,REC0RC,REC0W,R0,,CK0,W0,,R2,,W2,,REC0,,KWD;
!1,2,RW1,RW2;
!1,2,CK1,CK2;
!1,2,CK3,CK4;
!1,2,CKERR,CK5;
!1,2,PXFLP,PXF2;
!1,2,PREFDONE,INPREF;
!1,2,,CK6;
!1,2,CKSMERR,PXFLP0;

KWD:	BLOCK,:REC0;

;	SH<0 MAPS REC0 TO REC0
;	ANYTHING=INIT MAPS REC0 TO KWD

REC0:	L_2, TASK;	LENGTH OF RECORD 0 (ALLOW RELEASE IF BLOCKED) 
	KNMARW_L;

	T_KNMARW, BLOCK, RWC;	 GET ADDR OF MEMORY BLOCK TO TRANSFER
	MAR_DCBR+T+1, :REC0RC;

;	WRITE MAPS REC0RC TO REC0W
;	INIT MAPS REC0RC TO KWD

REC0RC:	T_MFRRDL,BLOCK, :REC12A;	FIRST RECORD READ DELAY
REC0W:	T_MFR0BL,BLOCK, :REC12A;	FIRST RECORD 0'S BLOCK LENGTH

REC1:	L_10, INCRECNO;	 LENGTH OF RECORD 1 
	T_4, :REC12;
REC2:	L_PAGE1, INCRECNO;	 LENGTH OF RECORD 2 
	T_5, :REC12;
REC12:	MAR_DCBR+T, RWC;	 MEM BLK ADDR FOR RECORD
	KNMARW_L, :RDCK0;

;	RWC=WRITE MAPS RDCK0 INTO WRT0
;	RWC=INIT MAPS RDCK0 INTO KWD

RDCK0:	T_MIRRDL, :REC12A;
WRT0:	T_MIR0BL, :REC12A;

REC12A:	L_MD;
	KWDCTW_L, L_T;
COM1:	KCOMM_ STUWC, :INPREF0;

INPREF:	L_CKSUMRW+1, INIT, BLOCK;
INPREF0: CKSUMRW_L, SH<0, TASK, :INPREF1;

;	INIT MAPS INPREF1 TO KWD

INPREF1: KDATA_0, :PREFDONE;

;	SH<0 MAPS PREFDONE TO INPREF

PREFDONE: T_KNMARW;	COMPUTE TOP OF BLOCK TO TRANSFER
KWDX:	L_KWDCTW+T,RWC;		(ALSO USED FOR RESET)
	KNMARW_L,BLOCK,:RP0;

;	RWC=CHECK MAPS RP0 TO CKP0
;	RWC=WRITE MAPS RP0 AND CKP0 TO WP0
;	RWC=INIT MAPS RP0, CKP0, AND WP0 TO KWD

RP0:	KCOMM_STRCWFS,:WP1;

CKP0:	L_KWDCTW-1;	ADJUST FINISHING CONDITION BY 1 FOR CHECKING ONLY
	KWDCTW_L,:RP0;

WP0:	KDATA_ONE;	WRITE THE SYNC PATTERN
WP1:	L_KBLKADR,TASK,:RW1;	INITIALIZE THE CHECKSUM AND ENTER XFER LOOP


XFLP:	MAR_T_L_KNMARW-1;	BEGINNING OF MAIN XFER LOOP
	KNMARW_L,RWC;
	L_KWDCTW-T,:R0;

;	RWC=CHECK MAPS R0 TO CK0
;	RWC=WRITE MAPS R0 AND CK0 TO W0
;	RWC=INIT MAPS R0, CK0, AND W0 TO KWD

R0:	T_CKSUMRW,SH=0,BLOCK;
	MD_L_KDATA XOR T,TASK,:RW1;

;	SH=0 MAPS RW1 TO RW2

RW1:	CKSUMRW_L,:XFLP;

W0:	T_CKSUMRW,BLOCK;
	KDATA_L_MD XOR T,SH=0;
	TASK,:RW1;

;	AS ALREADY NOTED, SH=0 MAPS RW1 TO RW2

CK0:	T_KDATA,BLOCK,SH=0;
	L_MD XOR T,BUS=0,:CK1;

;	SH=0 MAPS CK1 TO CK2

CK1:	L_CKSUMRW XOR T,SH=0,:CK3;

;	BUS=0 MAPS CK3 TO CK4

CK3:	TASK,:CKERR;

;	SH=0 MAPS CKERR TO CK5

CK5:	CKSUMRW_L,:XFLP;

CK4:	MAR_KNMARW, :CK6;

;	SH=0 MAPS CK6 TO CK6

CK6:	CKSUMRW_L,L_0+T;
	MTEMP_L,TASK;
	MD_MTEMP,:XFLP;

CK2:	L_CKSUMRW-T,:R2;

;	BUS=0 MAPS R2 TO R2

RW2:	CKSUMRW_L;

	T_KDATA_CKSUMRW,RWC;	THIS CODE HANDLES THE FINAL CHECKSUM
	L_KDATA-T,BLOCK,:R2;

;	RWC=CHECK NEVER GETS HERE
;	RWC=WRITE MAPS R2 TO W2
;	RWC=INIT MAPS R2 AND W2 TO KWD

R2:	L_MRPAL, SH=0;	SET READ POSTAMBLE LENGTH, CHECK CKSUM
	KCOMM_TOTUWC, :CKSMERR;

;	SH=0 MAPS CKSMERR TO PXFLP0

W2:	L_MWPAL, TASK;	SET WRITE POSTAMBLE LENGTH
	CKSUMRW_L, :PXFLP;

CKSMERR: KSTAT_0,:PXFLP0;	0 MEANS CHECKSUM ERROR .. CONTINUE

PXFLP:	L_CKSUMRW+1, INIT, BLOCK;
PXFLP0:	CKSUMRW_L, TASK, SH=0, :PXFLP1;

;	INIT MAPS PXFLP1 TO KWD

PXFLP1:	KDATA_0,:PXFLP;

;	SH=0 MAPS PXFLP TO PXF2

PXF2:	RECNO, BLOCK;	DISPATCH BASED ON RECORD NUMBER
	:REC1;

;	RECNO=2 MAPS REC1 INTO REC2
;	RECNO=3 MAPS REC1 INTO REC3
;	RECNO=INIT MAPS REC1 INTO KWD

REC3:	KSTAT_4,:PXFLP;	4 MEANS SUCCESS!!!

CKERR:	KCOMM_TOTUWC;	TURN OFF DATA TRANSFER
	L_KSTAT_6, :PXFLP1;	SHOW CHECK ERROR AND LOOP

;The Parity Error Task
;Its label predefinition is way earlier
;It dumps the following interesting registers:
;614/ DCBR	Disk control block
;615/ KNMAR	Disk memory address
;616/ DWA	Display memory address
;617/ CBA	Display control block
;620/ PC	Emulator program counter
;621/ SAD	Emulator temporary register for indirection

PA00015> PART:	T<- 7;
PA01765>	L<- SAD, :PX;
PR7:	L_ PC, :PX;
PR6:	L_ CBA, :PX;
PR5:	L_ DWA, :PX;
PR4:	L_ KNMAR, :PX;
PR3:	L_ DCBR, :PX;
PR2:	L_ NWW OR T, TASK;	T CONTAINS 1 AT THIS POINT
PA01774> PR0:	NWW<- L, :PART;

PA01767> PX:	MAR<- 612+T;
PA01770>	MTEMP<- L, L<- T;
PA01771>	CURDATA<- L;		THIS CLOBBERS THE CURSOR FOR ONE 
PA01772>	T<- CURDATA-1, BUS;	FRAME WHEN AN ERROR OCCURS
PA01773>	MD_ MTEMP, :PR0;
