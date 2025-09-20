;
; TRS-80 Model 100 ROM Source Code Listing by JdR (Dutchtronix)
;
; Based on VirtualT disassembly using an updated version of VirtualT
; All generated numeric labels (code and data) have been replaced with
; (hopefully) meaningful names.
;
; Other sources:
; 	Ken Pettit M100 disassembly m100_dis_2013.txt
;	Steven Adolph VT100 code
;	Steven Adolph HWSCROLL code
;	Microsoft Basic-80 5.2 Source
;	https://bitchin100.com/wiki/index.php?title=RAM_File_Handling
;	https://bitchin100.com/wiki/index.php?title=Low_Level_Filesystem_Access
;	https://bitchin100.com/wiki/index.php?title=Description_of_Machine_Code_File_Handling_Routines
;	https://bitchin100.com/wiki/index.php?title=Model_100/102_RAM_Pointers
;
;	Microsoft Basic-80 version N82
;
; When choosing the "Original M100 configuration" option below, the resulting binary is identical
; to the M100 ROM (patched for Y2K)
; The code is relocatable but is not adviced since many entry points addresses have been published.
;
; Other versions of the M100 Rom can be produced.
;
; 	VT100
;	This version supports screen text output to the serial port.
;	Best results if the receiving end is some kind of MVT100 supported device (Steven Adolph)
;	the MVT100 C# app in Windows works great.
;	This version disables support for the built-in M100 Modem
;	LCDPATCH & !HWMODEM required for VT100INROM
;
;	HWSCROLL
;	Steven Adolph's ROM version that uses the LCD hardware to speed up scrolling
;	BASEPATCH or LCDPATCH required for HWSCROLL
;	UNTESTED
;
; Both versions maintain the original published addresses (where possible)
;
; These versions are mutually exclusive.
;
; References to Epson M100 (!REALM100) are for a future project
;
; Assemble this file using "Makroassembler AS v1.42" by Alfred Arnold, ported to windows in a package
; called "aswcurr" http://john.ccac.rwth-aachen.de:8000/as/:
;
;	..aswcurr\bin\asw -i . -cpu 8085UNDOC -L <M100-Source>.asm
;	..\aswcurr\bin\p2bin.exe <M100-Source> -r $0000-$7fff
;
; There are 4 source files:
;
;	M100-Source.asm
;	VT100inROM.asm
;	VT100inROM2.asm
;	HWScroll.asm
;	
; Notes
;	VirtualT does not emulate telephone modem hardware completely.
;	Enabling the relay and modem are ignored.
;
;	Using TERM with no emulated serial port hangs VirtualT because it VirtualT
;	never returns ready on the serial port. This can easily be fixed in VirtualT
;
	if	1
;Original M100 configuration
BASEPATCH	equ	0
LCDPATCH	equ	0
HWSCROLL	equ	0
HWMODEM		equ	1
VT100INROM	equ	0
AUXCON		equ	0						;Bar code reader hardware mod. No space available.
OPTROM		equ	1						;support for Tandy supplied Option ROM
DVIENABLED	equ	1						;support for DVI box
DEADCODE	equ	1						;unused Code
REALM100	equ	1						;as opposed to Epson M100.
	endif

	if	0
; VT100 configuration
BASEPATCH	equ	0
LCDPATCH	equ	1
HWSCROLL	equ	0
HWMODEM		equ	0
VT100INROM	equ	1
AUXCON		equ	1						;Bar code reader hardware mod. No space available.
OPTROM		equ	1						;support for Tandy supplied Option ROM
DVIENABLED	equ	1						;support for DVI box
DEADCODE	equ	1						;unused Code
REALM100	equ	1						;as opposed to Epson M100.
	endif
	
	if	0
; HWSCROLL configuration
BASEPATCH	equ	1
LCDPATCH	equ	0
HWSCROLL	equ	1
HWMODEM		equ	1
VT100INROM	equ	0
AUXCON		equ	1						;Bar code reader hardware mod. No space available.
OPTROM		equ	1						;support for Tandy supplied Option ROM
DVIENABLED	equ	1						;support for DVI box
DEADCODE	equ	1						;unused Code
REALM100	equ	1						;as opposed to Epson M100.
	endif

BOOTMARKER	equ	8A4DH
AUTOPWRDWN	equ	9C0BH
;
; for Epson M100. See Z80-MBC2 design.
;
STO_OPCODE	equ	0						;port 0
EXC_WR_OPCODE equ 1						;port 1
;
; FCB definitions
;
;Byte:
;      0 - File mode (0-not open, 1-open for input, 2 open for 
;          output, 8 open for append)
;  2 & 3 - Address of file directory entry+1: points to File Data
;      4 - File device (248-RAM, 249-Modem, 250-LinePrinTer, 
;          251-WAND, 252-COM, 253-CASsette, 254-CRT, 255-LCD)
;      6 - Offset from buffer start (see bytes 9) for start of next 
;          record
;      7 & 8 -  Relative position of next 256 byte block from
;          beginning of file
;      9 - Start of 256 byte buffer for data transfer
;
STAT_IN_FCB_OFS	equ	0
DIR_IN_FCB_OFS	equ	2
DEV_IN_FCB_OFS	equ	4
BUFOFS_IN_FCB_OFS equ	6
FILPOS_IN_FCB_OFS equ	7
BUFFER_IN_FCB_OFS equ	9
;
LCD_DEV	 equ	0FFH					;index 0..7
CRT_DEV	 equ	0FEH
CAS_DEV	 equ	0FDH
COM_DEV	 equ	0FCH
WAND_DEV equ	0FBH
LPT_DEV	 equ	0FAH
MDM_DEV	 equ	0F9H
RAM_DEV	 equ	0F8H
;
DCBOPN_FUN	equ	0
DCBCLS_FUN	equ	2
DCBOUT_FUN	equ	4
DCBIN_FUN	equ	6						;DCB In function
DCBIO_FUN 	equ	8
;
PASTE_KEY equ	0BH
SHIFT_PRINT_KEY equ	0CH
PRINT_KEY equ	0DH
LABEL_KEY equ	0EH
; ==============================================
;File Directory Entry:
;	type				1 byte
;	file data ptr		2 bytes
;	name				6+2 bytes
;
;	type				bit 4: Option Rom
;						bit 5: CO file
;						bit 6: DO file
;
; Directory Filetype bits
; 7	0 if a killed file
; 6	1 if a DO file
; 5	1 if a CO file
; 4	1 if located in Option ROM
; 3	1 for invisible file
; 2	Reserved
; 1	For DO files, true indicates "opened"
; 0	Internal use only (known to be used by LNKFIL)
; value 0F0H (11110000) used for Option Rom file
; value 0B0H (10110000)used for ROM command file
; ================================================
_DIR_ACTIVE	equ	80H
_DIR_DOFILE	equ	40H
_DIR_COFILE	equ	20H
_DIR_INROM	equ	10H
_DIR_INVIS	equ	08H
_DIR_DOOPEN	equ	02H
RAMDIRLEN	equ	0BH						;length of 1 entry: type (1), Ptr (2), name (6+2)
RAMDIRCNT	equ	27						;max number of directory entries

MAXCHRROW	equ	8 						;max char rows on LCD screen
MAXCHRCOLUMN equ 40						;max char column on LCD screen
MAXPIXROW	equ	64 						;max pixel rows on LCD screen
MAXPIXCOLUMN equ 240					;max pixel column on LCD screen
MAXSERCNT	equ	64  					;max buffered Serial count. Must be power of 2
;
; the next 2 macros need to expand to 2 bytes exactly
;
OUTPORT	macro	arg, {noexpand}
	if REALM100
	out		arg
	else
	rst		7
	db		arg-47H
	endif
	endm
	
INPORT	macro	arg, {noexpand}
	if REALM100
	in		arg
	else
	rst		7
	db		arg - 47H + 8
	endif
	endm
;Compare next byte with M
SYNCHK	macro	arg, {noexpand}
	rst		1
	db		arg
	endm
;Get next non-white char from M
CHRGET	macro	{noexpand}
	rst		2
	endm
;Compare DE and HL
COMPAR	macro	{noexpand}
	rst		3
	endm
;Send character in A to screen/printer
OUTCHR	macro	{noexpand}
	rst		4
	endm
;Determine type of last var used
LSTTYP	macro	{noexpand}
	rst		5
	endm
;Get sign of FAC1
FSIGN	macro	{noexpand}
	rst		6
	endm
;Jump to RST 38H Vector entry of following byte
RST38H	macro	arg, {noexpand}
	rst		7
	db		arg
	endm
;get DE from M. Full Increment
GETDEFROMM macro {noexpand}
	MOV     E,M
    INX     H
    MOV     D,M
	INX		H
	endm
;get DE from M. Partial Increment
GETDEFROMMNOINC macro {noexpand}
	MOV     E,M
    INX     H
    MOV     D,M
	endm
;get HL from M. Partial Increment
GETHLFROMM macro {noexpand}
	MOV     A,M
    INX     H
    MOV     H,M
	MOV		L,A
	endm
; Skip XRA A, sets A != 0
SKIP_XRA_A	macro {noexpand}
    DB      0F6H						;Tricked out ORI 0AFH
	endm
; skip XRA A. A unaffected. Sets flags
SKIP_XRA_A_CP macro {noexpand}
	DB      0FEH						;Tricked out CPI 0AFH
	endm
; skip the next 1 byte instruction. A affected. TODO replace SKIP_XRA_A
SKIP_BYTE_INST macro {noexpand}
    DB      3EH							;Tricked out MVI A,0AFH
	endm
; skip ORA M. B affected
SKIP_BYTE_INST_B macro {noexpand}
	DB      06H							;Tricked out MVI B,xxH
	endm
; skip POP PSW or similar. C affected.
SKIP_BYTE_INST_C macro {noexpand}
	DB      0EH							;Tricked out MVI C,xxH
	endm
; skip POP PSW or similar. D affected.
SKIP_BYTE_INST_D macro {noexpand}
	DB      16H							;Tricked out MVI D,xxH
	endm
; skip POP PSW or similar. E affected.
SKIP_BYTE_INST_E macro {noexpand}
	DB      1EH							;Tricked out MVI E,xxH
	endm
; skip MVI C,80H (or similar) or two 1 byte instructions. HL affected
SKIP_2BYTES_INST_HL macro {noexpand}
    DB      21H							;Tricked out LXI H,800EH
	endm
; skip MVI E,0BH (or similar) or two 1 byte instructions. BC affected
SKIP_2BYTES_INST_BC macro {noexpand}
    DB      01H							;Tricked out LXI B,0E3D1H
	endm
; skip MVI B,9CH (or similar) or two 1 byte instructions. DE affected
SKIP_2BYTES_INST_DE macro {noexpand}
    DB		11H							;Tricked out LXI D,9C06H
	endm
; skip two instructions. DE affected
SKIP_2INSTS	macro {noexpand}
    DB		11H							;Tricked out LXI D,9C06H
	endm
; skip two 1 byte instructions. Requires carry clear to avoid jumping
SKIP_2BYTES_INST_JC macro {noexpand}
    DB		0DAH						;Tricked out JC xxxxH
	endm
; skip two 1 byte instructions. Requires Zero clear to avoid jumping
SKIP_2BYTES_INST_JZ macro {noexpand}
    DB		0CAH						;Tricked out JZ xxxxH
	endm
; skip two 1 byte instructions. Requires Zero set to avoid jumping
SKIP_2BYTES_INST_JNZ macro {noexpand}
    DB		0C2H						;Tricked out JNZ xxxxH
	endm
;
; 0F5F0H (SYSRAM_R) to 0F67FH RAM are initialized from R_FUN_INIT_IMAGE (144 bytes) at cold boot
;
SYSSTK_R	equ	0F5E6H					;cold boot stack
SYSRAM_R	equ	0F5F0H					;start of system RAM
AUTPWR_R	equ	0F5F2H					;auto power down flag
HIMEM_R		equ	0F5F4H					;Highest memory available to BASIC (clear value)
BOOTHK_R	equ	0F5F6H					;hook Boot-up
WANDHK_R	equ	0F5F9H					;wand hook
SERHK_R		equ	0F5FCH					;This is the RST 6.5 routine (RS232 receive interrupt) hook
SYSHK_R		equ	0F5FFH					;This is the RST 7.5 routine (SYSINT) hook
PWRDOWN_R	equ	0F602H					;power down trap
ROMJMP_R	equ	0F624H					;Launch Option ROM
ROMTST_R	equ	0F605H					;code to test for Option Rom
ROMFLG_R	equ	0F62AH					;Option ROM installed flag
MDMSPD_R	equ	0F62BH					;Dial speed (1=10pps), 2=20pps
FNKMAC_R	equ 0F62CH					;Pointer to FKey text (from FKey table) for selected FKey
PBUFIDX_R	equ	0F62EH					;index into Paste Buffer
FKEYSTAT_R	equ	0F630H					;Function key status table (1 = on) (8 bytes)
CONDEV_R	equ	0F638H					;New Console device flag
CSRY_R		equ	0F639H					;current cursor Y position (row)
CSRX_R		equ	0F63AH					;current cursor X position (1-40) (column)
LINCNT_R	equ	0F63BH					;Console height
LINWDT_R	equ	0F63CH					;Console width
LINPROT_R	equ	0F63DH					;Label line protect status
SCRLDIS_R	equ	0F63EH					;Scrolling disable flag
CURSTAT_R	equ	0F63FH					;Cursor status (0 = off)
LCDCSY_R	equ	0F640H					;Cursor row (1-8) initialized to 1
LCDCSX_R	equ	0F641H					;Cursor column (1-40) initialized to 1
DVIROWCOL_R	equ	0F642H					;initialized to 1,1
DVIMAXROW_R equ 0F644H					;initialized to 25
DVIMAXCOL_R	equ	0F645H					;initialized to 40 unless VT100INROM
ESCRST20_R	equ	0F646H					;ESC mode flag for OUTCHR (RST 20H)
;			equ 0F647H					;used for Double ESC
REVFLG_R	equ	0F648H					;Reverse video flag (FF=reverse/00=normal)
PRTWDTH_R	equ	0F649H					;Printer output width from CTRL-Y
PRTBUF_R	equ	0F64AH					;4 byte text buffer
XPLOT_R		equ	0F64EH					;X coord of last point plotted
YPLOT_R		equ	0F64FH					;Y coord of last point plotted
FNKMOD_R	equ	0F650H					;Function key mode/ BIT 7=in TEXT (0x80); BIT 6=in TELCOM (0x40)
EDITFLG_R	equ	0F651H					;Flag used during EDITing a BASIC program.
ACTONERR_R	equ	0F652H					;Active On Error Handler
PNDINT_R	equ	0F654H					;pending interrupt count
TIMMON_R	equ	0F655H					;current month. Initialized to 0
PWROFF_R	equ	0F656H					;Power off exit condition switch
TIMDWN_R	equ	0F657H					;POWER down time (1/10ths of a minute)
DUPLEX_R	equ	0F658H					;Full/Half duplex switch
ECHO_R		equ	0F659H					;Echo switch
LFFLG_R		equ	0F65AH					;Auto linefeed on RS232 output switch (non zero send line feeds with each carriage return)
SERMOD_R	equ	0F65BH					;Serial initialization string like "98N1D"
										;LSTCAL_R-1 (0F660H) contains JMP instruction
LSTCAL_R	equ	0F661H					;Address last called (2 bytes)
INRCODE_R	equ	0F663H					;contains 1CH: INR E instruction. 0F664H contains RET
DCRCODE_R	equ	0F665H					;contains 15H: DCR D instruction. 0F666H contains RET
OUTCODE_R	equ	0F667H					;contains 0D3H: OUT instruction. 0F669H contains RET
INCODE_R	equ	0F66AH					;contains 0DBH: IN instruction.  0F66CH contains RET
COLONTXT_R	equ	0F66DH					;contains ':'. 5 bytes
ERRFLG_R	equ	0F672H					;Last Error code (1 byte)
LPTPOS_R	equ	0F674H					;Line printer head position (based from zero)
PRTFLG_R	equ	0F675H					;Flag 0FFH=send output to lpt
COLWRAP_R	equ	0F676H					;comma value for print. contains 14 or 56 if 80 columns width
STRBUF_R	equ	0F678H					;BASIC string buffer pointer/Top of available RAM
CURLIN_R	equ	0F67AH					;Current Basic executing line number
TXTTAB_R	equ	0F67CH					;Start of BASIC program pointer
VALSTRPTR_R equ	0F67EH					;ptr used by VAL_STR_FUN() (2 bytes)
; ======================================
; end of R_FUN_INIT_IMAGE
; ======================================
EOSMRK_R	equ	0F680H					;End of Statement marker
TOKTMP_R	equ	0F681H					;temp storage for tokenized line:
										;	next line (2 bytes) + line number (2 bytes)
INPBUF_R	equ	0F685H					;Start of keyboard crunch buffer for line input routine (90 bytes)
ESCESC_R	equ	0F6DFH					;Clear storage for key read from keyboard to test for ESC ESC (1 byte)
SAVESCESC_R	equ	0F6E0H					;saved ESCESC_R
PNDERR_R	equ	0F6E1H					;Pending error
DOADDR_R	equ	0F6E2H					;Start address in .DO file of SELection for copy/cut
DOEND_R		equ	0F6E4H					;End address in .DO file of SELection for copy/cut (2 bytes)
PASTEFLG_R	equ	0F6E6H					;paste buffer related
TMPLIN_R	equ	0F6E7H					;temp storage for line ptr (2 bytes)
PREVLINE_R	equ	0F6E9H					;2 bytes
TXTLINTBL_R equ 0F6EBH					;Storage of TEXT Line ptrs. Length at least 8 ptr entries, possibly 26 (DVI). (52 bytes)
SEARCHSTR_R	equ	0F71FH					;Used to store search string in editor (72 bytes)
DOLOAD_R	equ	0F767H					;Load start address of .DO file being edited (2 bytes)
; potentially unused space 0F769H..0F786, 30 bytes
UNUSED4_R	equ	0F787H					;1 bytes. Only ever cleared
CURHPOS_R	equ	0F788H					;Horiz. position of cursor (0-39)
FNKSTR_R	equ	0F789H					;Function key definition area. 128 bytes
FILTYP_R	equ	0F809H					;File type
BASFNK_R	equ	0F80AH					;BASIC's function keys. 128 bytes
SHFTPRNT_R	equ	0F88AH					;SHIFT-PRINT key sequence Function text
EOMFILE_R	equ	0F88CH					;end of file area/ptr to PASTE buffer (2 bytes)
SAVCURPOS_R	equ	0F88EH					;temporarily saved current char position in line buffer
DSPCOFF_R	equ	0F890H					;Current column offset within display line buffer
CURPOS_R	equ	0F892H					;current char position in line buffer
LINBUF_R	equ	0F894H					;line buffer (140 chars)
LCDPRT_R	equ	0F920H					;LCD vs Printer output indication - output to LCD
WWRAP_R		equ	0F921H					;Get word-wrap enable flag
OUTFMTWIDTH_R equ 0F922H				;Output format width (40 or something else for CTRL-Y)
; 40 bits (10 nibbles) Clock Chip Data. Each nibble from the Clock Chip is stored in a byte
TIMBUF_R	EQU	0F923H					;(10 bytes)
TIMYR1_R	equ	0F92DH					;Year 2 bytes (ones), (tens)
TIMCNT_R	equ	0F92FH					;2Hz count-down value
; next 2 variables need to stay together
TIMCN2_R	equ	0F930H					;Counter (12 to 1)
PWRCNT_R	equ	0F931H					;Power down countdown value
PWRDWN_R	equ	0F932H					;Power Down Flag, either 0 or 0FFH
CLKCHP_R	equ	0F933H					;Clock Chip Buffer (10 bytes)
TIMINT_R	equ	0F93DH					;Time for ON TIME interrupt (SSHHMM or SSMMHH, 6 bytes)
ONTIMETRIGD_R equ 0F943H				;ON TIME interrupt currently triggered
SYSINT_R	equ	0F944H					;System Interrupt Table: 10 * 3 bytes = 30 (1EH)
; RAMDIR_R size = RAMDIRCNT * RAMDIRLEN = 297 (129H) bytes
; First 5 entries are ROM functions (BASIC, TEXT, TELCOM, ADDRSS, SCHEDL), 55/037H bytes
; Next 3 entries are for internal use (SUZUKI, HAYASHI, RICKY) 33/021H bytes
; 19 user entries available 209/0D1H bytes
; Total: 55+33+209 = 297/0129H. 0F962H..0FA8AH
RAMDIR_R	equ	0F962H					;start of RAM directory.
SUZUKI_R	equ	0F999H					;Suzuki Directory Entry.
;			equ	0F99AH					;BASIC program not saved pointer.
HAYASHI_R	equ	0F9A4H					;Hayashi Directory Entry
;			equ	0F9A5H					;paste buffer ptr.

	if		HWSCROLL
;---------------------------------------------------------------------
; Hardware Scroll Patch
;---------------------------------------------------------------------
page_loc	equ	0F9ADH
scroll_active equ 0F9AEH
	endif								;HWSCROLL

RICKY_R		equ	0F9AFH					;Ricky Directory Entry.
;			equ	0F9B0H					;ptr 8099H
USRRAM_R	equ	0F9BAH					;start of user RAMDIR, 19 entries max, 11 bytes each
ENDUSRRAM_R	equ	0FA8AH					;last byte of RAMDIR_R
RAMDIRPTR_R	equ	0FA8CH					;(2 bytes)
CASFILSTAT_R equ 0FA8EH					;Cassette File Status
FILSTAT_R	equ	0FA8FH					;File Status (1/2 bytes)
FILSTATTBL_R equ 0FA91H					;Basic File Status Table (16 bytes)
LSTPST_R	equ	0FAA1H					;Last Paste Character
FILNUM_R	equ	0FAA2H					;zero extended validated file number (2 bytes)
ROMSW_R		equ	0FAA4H					;code to switch back to the option rom
LASTLPT_R	equ	0FAACH					;Last char sent to printer
LINENA_R	equ	0FAADH					;Label line enable flag
PORTA8_R	equ	0FAAEH 					;Contents of port 0A8H. NOTE PORT 0A8H never read
IPLNAM_R	equ	0FAAFH					;Start of IPL filename (9 bytes)
LASTLST_R	equ	0FABAH					;Address where last BASIC list started
NXTLINE_R	equ	0FABCH					;line (ptr) used on Edit/List mode
POWRSP_R	equ	0FABEH					;SP save area for power up/down
LOMEM_R		equ	0FAC0H					;Lowest RAM address in system (8000H for 32K system)
SER_UPDWN_R	equ	0FAC2H					;2 flags used in TELCOM Upload and Download
DOFILPTR_R	equ	0FAC4H					;ptr to DO file (2 bytes)
TLCMKEY_R	equ	0FAC6H					;saved key in Telcom code
POPPSW_R	equ	0FAC7H					;Conditionally POP PSW from stack based on this flag
UNUSED5_R	equ	0FAC8H					;set to 0 or 0FFH but never tested
RST38ARG_R	equ	0FAC9H					;data byte following rst 7
CSRXSVD_R	equ	0FACAH					;saved Cursor column
OLDCURSTAT_R equ 0FACBH					;Storage if cursor was on before BASIC CTRL-S
LINPROT2_R	equ	0FACCH					;Saved Line 8 Protect status
LPT_MOVING_R equ 0FACDH					;LPT head is moving
;
; next 5 words need to stay in order
;
LOADADR_R	equ	0FACEH					;'Load address' of current program (2 bytes)
LASTLEN_R	equ	0FAD0H					;Length of last program (2 bytes)
LASTSTRT_R	equ	0FAD2H					;Start of  last program (2 bytes)
; 0FAD4H..0FAD7H						;4 bytes used for CAS
XXSTRT_R	equ	0FAD8H					;2 bytes
RST38_R		equ	0FADAH					;Start of RST 38H vector table: 48 * 2 bytes (60H)
HCHGET_R	EQU	0FADEH					;CHGET hook entry
HCHSNS_R	EQU	0FAE0H					;CHSNS hook entry
HCHPUT_R	EQU	0FAE2H					;CHPUT (print) hook entry
HOOKT2_R	equ	0FB14H					;start of second section of RST38_R
ENDHKT2_R	equ	0FB39H					;last byte of RST38 Table
LCDBITS_R	equ	0FB3AH					;reflects the Reverse Video status of each char on LCD screen (40 bytes, 320 bits)
TXTEND_R	equ	0FB62H					;Pointer to end of .DO storage
; next 2 variables need to be together
CRELOC_R	equ	0FB64H					;Create/Locate switch for variables used in the main evaluation routine (Locate=0, Create>0).
VALTYP_R	equ	0FB65H					;Type of last expression used: (2-Integer, 3-String, 4-Single Precision, 5-Double Precision)
; DORES_R 
; WHETHER CAN OR CAN'T CRUNCH RESERVED WORDS
; TURNED ON WHEN "DATA" BEING SCANNED BY CRUNCH SO UNQUOTED
; STRINGS WON'T BE CRUNCHED.
DORES_R		equ	0FB66H					;WHETHER CAN OR CAN'T CRUNCH RES'D WORDS
MEMSIZ_R	equ	0FB67H					;Start address for file buffer area (2 bytes)
TEMPPT_R	equ	0FB69H					;String Stack ptr (2 bytes)
TEMPST_R	equ	0FB6BH					;String Stack 30 bytes (10 string descriptors)
STRSTKEND_R	equ	0FB88H					;end of String Stack
TRSNSTR_R	equ	0FB89H					;transient string storage (3 bytes)
FRETOP_R	equ	0FB8CH					;Pointer to free location in BASIC string buffer (2 bytes). Goes down.
TEMP3_R		equ	0FB8EH					;1/2 byte
TEMP8_R		equ	0FB90H					;2 bytes
MSTMP3_R	equ	0FB92H					;2 bytes
DATALIN_R	equ	0FB94H					;Line number of current data statement
SUBFLG_R	equ	0FB96H					;DONT RECOGNIZE SUBSCRIPTED VARIABLES flag
PROFLG_R	equ	0FB97H					;1 byte. TODO Only ever cleared
PRT_USING_R	equ	0FB98H					;Print Using Flag (1 byte
LSTVAR_R	equ	0FB99H					;Address of last variable assigned (2 bytes)
SAVTXT_R	equ	0FB9BH					;Most recent or currenly running line pointer
BASSTK_R	equ	0FB9DH					;SP used by BASIC to reinitialize the stack
ERRLIN_R	equ	0FB9FH					;Line number of last error
DOT_R		equ	0FBA1H					;Most recent entered/ listed/ or edited line
ERRTXT_R	equ	0FBA3H					;Pointer to occurance of error
ONERR_R		equ	0FBA5H					;Address of ON ERROR routine
PRGRUN_R	equ	0FBA7H					;Basic program running flag
TEMP2_R		equ	0FBA8H					;temp pointer
OLDLIN_R	equ	0FBAAH					;Line where last break, END, or STOP occured (2 bytes)
;
; OLDTXT_R
; A STORED TEXT POINTER OF ZERO IS SETUP BY STKINI AND INDICATES THERE IS NOTHING TO CONTINUE
;
OLDTXT_R	equ	0FBACH					;Address where program stoped on last break, END, or STOP (2)
DOSTRT_R	equ	0FBAEH					;Pointer to the start of the DO files and end of the BA files (2 bytes)
COSTRT_R	equ	0FBB0H					;Pointer to the start of CO files (2 bytes)
;
;POINTER TO START OF SIMPLE VARIABLE SPACE
;UPDATED WHENEVER THE SIZE OF THE PROGRAM CHANGES
;SET TO [TXTTAB] BY SCRATCH ("NEW")
;
VARTAB_R	equ	0FBB2H					;Pointer to the start of variable table (2 bytes)
;
;POINTER TO BEGINNING OF ARRAY TABLE
;INCREMENTED BY 6 WHENEVER A NEW SIMPLE VARIABLE IS FOUND, AND
;SET TO [VARTAB] BY CLEARC.
;
ARYTAB_R	equ	0FBB4H					;Pointer to the start of array table (2 bytes)
;
;END OF STORAGE IN USE
;INCREASED WHENEVER A NEW ARRAY OR SIMPLE VARIABLE IS ENCOUNTERED
;SET TO [VARTAB] BY CLEARC.
;
STRGEND_R	equ	0FBB6H					;Pointer to the start of the systems unused memory (2 bytes)
;
;POINTER TO DATA. INITIALIZED TO POINT AT THE ZERO IN FRONT OF [TXTTAB]
;BY "RESTORE" WHICH IS CALLED BY CLEARC
;UPDATED BY EXECUTION OF A "READ"
;
DATAPTR_R	equ	0FBB8H					;Address where DATA search will begin on next READ statement (2 bytes)
;
;THIS GIVES THE DEFAULT VALTYP FOR EACH LETTER OF THE ALPHABET
;IT IS SET UP BY "CLEAR" AND CHANGED BY "DEFSTR" "DEFINT" "DEFSNG" "DEFDBL" AND USED
;BY PTRGET WHEN ! # % OR $ DON'T FOLLOW A VARAIBLE NAME
;
DEFTBL_R	equ	0FBBAH					;table for default variable types declared by the DEF statement.
										;Each entry corresponds to one of the letters A-Z.
										;The contents of each entry are 2 for an integer, 3 for a string,
										;4 for a single precision number, and 8 for a double precision number. (26 bytes)
UNUSED7_R	equ	0FBD4H					;cleared and only used as a label.
UNUSED6_R	equ	0FBD6H					;only ever cleared (2 bytes)
; PRMPRV_R is used in mbasic 5.2 for CP/M for User Defined Functions, which are not
; supported in M100 basic. Looks like a left-over from that code
PRMPRV_R	equ	0FBD9H					;THE POINTER AT THE PREVIOUS PARAMETER(2 bytes)
UNUSED3_R	equ	0FBDBH					;Only ever cleared, never referenced (2 bytes)
ARYTA2_R	equ	0FBDFH					;(2 bytes)
UNUSED2_R	equ	0FBE1H					;Only ever cleared, never referenced (1 byte)
TEMP9_R		equ	0FBE2H					;2 bytes
UNUSED1_R	equ	0FBE4H					;Only ever cleared, never referenced (2 bytes)
VALSTRDAT_R	equ	0FBE6H					;used by VAL_STR_FUN(). Only valid if VALSTRPTR_R != 0 (1 byte)
FPTMP1_R	equ	0FBE7H					;Floating Point Temp 1 (2 bytes) OVERLAPS
MBUFFER_R	equ	0FBE8H					;number string stored here
FPTMP4_R	equ	0FC12H					;Temps
FPTMP5_R	equ	0FC14H
FPTMP6_R	equ	0FC16H
FPTMP7_R	equ	0FC17H
; extended precision FAC1 is 15 bytes
DFACLO_R	equ	0FC18H					;Floating Point Accumulator (FAC1)
IFACLO_R	equ	0FC1AH					;FAC1 for integers
;
; BCD temps are referenced at their lowest digit, meaning highest address
; memory layout starts at 0FC27H
;
BCDTMPS_R	equ	0FC27H
BCDTMP1_R	equ	0FC2FH					;BCD_TEMP1	These temps must be in this order
BCDTMP2_R	equ	0FC37H					;BCD_TEMP2
BCDTMP3_R	equ	0FC3FH					;BCD_TEMP3
BCDTMP4_R	equ	0FC47H					;BCD_TEMP4
BCDTMP5_R	equ	0FC4FH					;BCD_TEMP5
BCDTMP6_R	equ	0FC57H					;BCD_TEMP6
BCDTMP7_R	equ	0FC5FH					;BCD_TEMP7 (x2)
; overloaded memory
FPTMP2_R	equ	0FC60H					;Floating Point Temp 2
BCDTMP8_R	equ	0FC67H					;Temp BCD value for computation
DFACLO2_R	equ	0FC69H					;Second FAC (FAC2) 16 bytes
IFACLO2_R	equ	0FC6BH					;FAC2 for integers
FPRND_R		equ	0FC79H					;Floating Point Random number (8 bytes)
DVI_STAT_R	equ 0FC81H					;DVI being used
MAXFILES_R	equ	0FC82H					;Maxfiles
FCBTBL_R	equ	0FC83H					;ptr to File number description table pointer (2 bytes)
FCB1_BUF_R	equ	0FC87H					;ptr to buffer first file(2 bytes)
FCBLAST_R	equ	0FC8CH					;FCB ptr for the last file used (2 bytes)
EXCFLG_R	equ	0FC92H					;Flag to execute BASIC program
FILNAM_R	equ	0FC93H					;9 byte area for setting file names for search or open (9 bytes)
FILNM2_R	equ	0FC9CH					;Second file name/ same format as above. Used by NAME (11 bytes) last 2 bytes unused?
OPNFIL_R	equ 0FCA7H					;Any open files flag
BOOTSTK_R	equ	0FCA8H					;0FCA8H..0FCBFH	18H/24 byte stack area during boot
;
; ALTLCD_R and LCD_R need to be consecutive
; ALTLCD_R area only used in terminal mode
;
ALTLCD_R	equ	0FCC0H					;Screen buffer 0 (Previous page for Telcom)
MNU2RAM_R	equ	0FDA1H					;Map of MENU entry positions to RAM directory
TMP_UTIL_R	equ	0FDD7H					;temp to store a ptr (2 bytes)
STRNAM_R	equ	0FDD9H					;filename string. 8 bytes
MENUCMD_R	equ	0FDEDH					;Menu command entry count
MENPOS_R	equ	0FDEEH					;Current MENU directory location. Sometimes Used as Lfnd flag 
MENMAX_R	equ	0FDEFH					;Maximum MENU directory location
TMPCONDEV_R	equ	0FDFAH					;temporary Console Device Flag
LCD_R		equ	0FE00H					;Screen buffer 1 (LCD memory)
XONXOFF_R	equ	0FF40H					;XON/XOFF protocol control
;
; Zero 0FF40H..0FFFCH, basically all RAM >= XONXOFF_R at cold boot time.
;
XONXOFF1_R	equ	0FF41H					;Second XON/XOFF protocol control
XONFLG_R	equ	0FF42H					;XON/XOFF enable flag
SERINIT_R	equ	0FF43H					;RS232 initialization status
SNDFLG_R	equ	0FF44H					;Sound flag: 0 means sound allowed
PORTE8_R	equ	0FF45H					;Contents of port E8H
SERBUF_R	equ	0FF46H					;RS232 Character buffer
SERCNT_R	equ	0FF86H					;RS232 buffer count
SERPTR_R	equ	0FF88H					;RS232 buffer input pointer
CTRLS_R		equ	0FF8AH					;Control-S status
BAUDRT_R	equ	0FF8BH					;UART baud rate timer value (2 bytes)
PARMSK_R	equ	0FF8DH					;Serial Ignore Parity Mask byte. Used to remove bits if 'I' parity
CASPLS_R	equ	0FF8EH					;Cassette port pulse control
KBDSKIP_R	equ	0FF8FH					;Skip count for keyboard scanning. Initialized to 3
KBDCNTR_R	equ	0FF90H					;Keyboard counter. Set to 2
; next 17 bytes need to be consecutive
KBDCOL1_R	equ	0FF91H					;start of keyboard columns storage area 1: 9 columns
SPCLKEY_R	equ	0FF97H					;special key storage, 8 bits: SPACE, DEL, TAB, ESC, PASTE, LABEL, PRINT, ENTER
FUNKEY_R	equ	0FF98H					;Function key storage, 8 bits: F1 F2 F3 F4 F5 F6 F7 F8
;			equ	0FF99H					;end of keyboard scan column storage #1. 8 bits:
										;SHIFT, CTRL, GRPH, CODE, NUM, CAPSLOCK
KBDCOL2_R	equ	0FF9AH					;start of keyboard columns storage area 2: 9 columns
ENDKBDCL2_R	equ	0FFA2H					;end of keyboard scan column storage @2. 8 bits:
										;SHIFT, CTRL, GRPH, CODE, NUM, CAPSLOCK
; variables below must stay together
KEYSHFT_R	equ	0FFA3H					;Shift key status storage
KEYCNT_R	equ	0FFA4H					;Key repeat start delay counter
KEYCNT2_R	equ	0FFA5H
KEYSTRG_R	equ	0FFA6H					;Key position storage
KEYXXXX_R	equ	0FFA7H					;Key related.
KEYPTR_R	equ	0FFA8H					;Pointer to entry in 2nd Storage Buffer for key (2 bytes)
KBCNT_R		equ	0FFAAH					;Keyboard buffer count. Buffer must follow
KBBUF_R		equ	0FFABH					;keyboard typeahead buffer (64 bytes 40H)
PNDCTRL_R	equ	0FFEBH					;Holds CTRL-C or CTRL-S until it is processed
LCDBUF_R		equ	0FFECH					;6 byte LCD buffer
CSRSTAT_R	equ	0FFF2H					;cursor blink on-off status. Value 0, 1 or 080H (disabled)
CSRCNT_R	equ	0FFF3H					;Time until next cursor blink
; LCTEY_R and LCTEX_R are 0 based. Keep these 2 together.
LCTEY_R		equ	0FFF4H					;LCD row 0..7 of character position to be printed
LCTEX_R		equ	0FFF5H					;LCD column 0..39 of character position to be printed
PBTABLE_R	equ	0FFF6H					;stored LCD Driver Selection table (2 bytes)
SAVEDSP_R	equ	0FFF8H					;stored SP value
	if DVIENABLED
DVIBOX_R	equ	0FFFAH					;DVI MAILBOX SELECT area
DVIFLG_R	equ	0FFFBH					;optional external controller flag
	endif
VIDFLG_R	equ	0FFFCH

	if VT100INROM
LAST_RAM	equ	var1
	else
LAST_RAM	equ	VIDFLG_R
	endif
;
; Reset Vector
;
R_RESET_VECTOR:							;0000H
    JMP     R_BOOT_ROUTINE				;Boot routine

L_MENU_MSG:
    DB      "MENU",00H
;
; Compare next byte with M: SYNCHR
;
R_COMP_BYTE_M:							;0008H
    MOV     A,M
    XTHL
    CMP     M
    JNZ     R_GEN_SN_ERROR				;Generate Syntax error
    INX     H
    XTHL
;
; Get next non-white char from M: CHRGET
;
R_RST_10H:
    JMP     L_CHRGTR					;Get next non-white char from M
;
; TXTLINTBL_R to DE, Compare DE, HL
;
L_ISFRSTLIN:
    XCHG
    LHLD    TXTLINTBL_R					;Get first TEXT Line ptr to DE
    XCHG
;
;Compare DE and HL
; HL - DE
; OUT:
;	Z		equal or not equal
;	carry	if HL < DE
;	A		0 if Z set
;
R_COMP_DE_HL:							;0018H
    MOV     A,H
    SUB     D
    RNZ
    MOV     A,L
    SUB     E
    RET
;
; Send a space to screen/printer
;
R_PRINT_SPACE:							;001EH
    MVI     A,' '
;
; Send character in A to screen/printer
;
R_PRINT_CHAR:							;0020H
    JMP     R_SEND_A_LCD_LPT			;Send A to screen or printer
    NOP    
;
; Power down TRAP
;
R_PWR_DOWN_TRAP:						;0024H
    JMP     PWRDOWN_R
    NOP    
;
; Determine type of last var used RST 5
;
; RST 28H routine
; Determine type of last var used
; C: Clear = Double Precision
; P: Clear = Single Precision
; Z: Set = String
; S: Set = Integer
;
R_DET_LAST_VAR_TYPE:				    ;0028H
    JMP     R_RST_28H				    ;RST 28H routine
    NOP    
;
; RST 5.5 -- Bar Code Reader
;
R_RST_5_5:								;002CH
    DI 
    JMP     WANDHK_R					;RAM
;
; Get sign of FAC1 RST 6
;
R_GET_FAC1_SIGN:						;0030H
    JMP     R_RST_30H_FUN				;Get sign of SGL or DBL precision
    NOP									;Filler
;
; RST 6.5 -- RS232 character pending
;
R_RST_6_5:								;0034H
    DI 
    JMP     R_RST6_5_ISR				;RST 6.5 routine (RS232 receive interrupt)
;
; RAM vector table driver
;
R_RST38H:							    ;0038H
    JMP     R_RAM_VCTR_TBL_DRIVER		;RST 38H RAM vector driver routine
    NOP									;Filler
;
; RST 7.5 -- Timer background task
;
R_RST_7_5:								;003CH
    DI 
    JMP     R_TIMER_ISR			 	   ;RST 7.5 interrupt routine
;
; test relocatability of code
;
;	nop									;xxxx move everything over 1 byte
;
; Function vector table for SGN to MID$
;
R_FUN_VCTR_TBL:								  	;0040H
    DW      R_SGN_FUN, R_INT_FUN, R_ABS_FUN
    DW      R_FRE_FUN, R_INP_FUN, R_LPOS_FUN
    DW      R_POS_FUN, R_SQR_FUN, R_RND_FUN
    DW      R_LOG_FUN, R_EXP_FUN, R_COS_FUN
    DW      R_SIN_FUN, R_TAN_FUN, R_ATN_FUN
    DW      R_PEEK_FUN, R_EOF_FUN, R_LOC_FUN
    DW      R_LOF_FUN, R_CINT_FUN, R_CSNG_FUN
    DW      L_FRCDBL, R_FIX_FUN, R_LEN_FUN
    DW      R_STR_FUN, R_VAL_FUN, R_ASC_FUN
    DW      R_CHR_FUN, R_SPACE_FUN, R_LEFT_FUN
    DW      R_RIGHT_FUN, R_MID_FUN
;
;BASIC statement keyword table END to NEW
;
; Basic-80 N82 predates the ALPHA DISPATCH TABLE
;
R_BASIC_KEYWORD_TBL:				    ;0080H
Q	SET		128
    DB      80H | 'E',"ND"				;token value 80H
_END EQU	Q
Q	SET		Q+1
    DB      80H | 'F',"OR"				;token value 81H
_FOR EQU	Q
Q	SET		Q+1
    DB      80H | 'N',"EXT"				;token value 82H
_NEXT EQU	Q
Q	SET		Q+1
    DB      80H | 'D',"ATA"				;token value 83H
_DATA EQU	Q
Q	SET		Q+1
    DB      80H | 'I',"NPUT"			;token value 84H
_INPUT EQU	Q
Q	SET		Q+1
    DB      80H | 'D',"IM"				;token value 85H
_DIM EQU	Q
Q	SET		Q+1
    DB      80H | 'R',"EAD"				;token value 86H
_READ EQU	Q
Q	SET		Q+1
    DB      80H | 'L',"ET"				;token value 87H
_LET EQU	Q
Q	SET		Q+1
    DB      80H | 'G',"OTO"				;token value 88H
_GOTO EQU	Q
Q	SET		Q+1
    DB      80H | 'R',"UN"				;token value 89H
_RUN EQU	Q
Q	SET		Q+1
    DB      80H | 'I',"F"				;token value 8AH
_IF EQU	Q
Q	SET		Q+1
    DB      80H | 'R',"ESTORE"			;token value 8BH
_RESTORE EQU	Q
Q	SET		Q+1
    DB      80H | 'G',"OSUB"			;token value 8CH
_GOSUB EQU	Q
Q	SET		Q+1
    DB      80H | 'R',"ETURN"			;token value 8DH
_RETURN EQU	Q
Q	SET		Q+1
    DB      80H | 'R',"EM"				;token value 8EH
_REM EQU	Q
Q	SET		Q+1
    DB      80H | 'S',"TOP"				;token value 8FH
_STOP EQU	Q
Q	SET		Q+1
    DB      80H | 'W',"IDTH"			;token value 90H
_WIDTH EQU	Q
Q	SET		Q+1
    DB      80H | 'E',"LSE"				;token value 91H
_ELSE EQU	Q
Q	SET		Q+1
    DB      80H | 'L',"INE"				;token value 92H
_LINE EQU	Q
Q	SET		Q+1
    DB      80H | 'E',"DIT"				;token value 93H
_EDIT EQU	Q
Q	SET		Q+1
    DB      80H | 'E',"RROR"			;token value 94H
_ERROR EQU	Q
Q	SET		Q+1
    DB      80H | 'R',"ESUME"			;token value 95H
_RESUME EQU	Q
Q	SET		Q+1
    DB      80H | 'O',"UT"				;token value 96H
_OUT EQU	Q
Q	SET		Q+1
    DB      80H | 'O',"N"				;token value 97H
_ON EQU	Q
Q	SET		Q+1
    DB      80H | 'D',"SKO$"			;token value 98H
_DSKO_ EQU	Q
Q	SET		Q+1
    DB      80H | 'O',"PEN"				;token value 99H
_OPEN EQU	Q
Q	SET		Q+1
    DB      80H | 'C',"LOSE"			;token value 9AH
_CLOSE EQU	Q
Q	SET		Q+1
    DB      80H | 'L',"OAD"				;token value 9BH
_LOAD EQU	Q
Q	SET		Q+1
    DB      80H | 'M',"ERGE"			;token value 9CH
_MERGE EQU	Q
Q	SET		Q+1
    DB      80H | 'F',"ILES"			;token value 9DH
_FILES EQU	Q
Q	SET		Q+1
    DB      80H | 'S',"AVE"				;token value 9EH
_SAVE EQU	Q
Q	SET		Q+1
    DB      80H | 'L',"FILES"			;token value 9FH
_LFILES EQU	Q
Q	SET		Q+1
    DB      80H | 'L',"PRINT"			;token value 0A0H
_LPRINT EQU	Q
Q	SET		Q+1
    DB      80H | 'D',"EF"				;token value 0A1H
_DEF EQU	Q
Q	SET		Q+1
    DB      80H | 'P',"OKE"				;token value 0A2H
_POKE EQU	Q
Q	SET		Q+1
    DB      80H | 'P',"RINT"			;token value 0A3H
_PRINT EQU	Q
Q	SET		Q+1
    DB      80H | 'C',"ONT"				;token value 0A4H
_CONT EQU	Q
Q	SET		Q+1
    DB      80H | 'L',"IST"				;token value 0A5H
_LIST EQU	Q
Q	SET		Q+1
    DB      80H | 'L',"LIST"			;token value 0A6H
_LLIST EQU	Q
Q	SET		Q+1
    DB      80H | 'C',"LEAR"			;token value 0A7H
_CLEAR EQU	Q
Q	SET		Q+1
    DB      80H | 'C',"LOAD"			;token value 0A8H
_CLOAD EQU	Q
Q	SET		Q+1
    DB      80H | 'C',"SAVE"			;token value 0A9H
_CSAVE EQU	Q
Q	SET		Q+1
    DB      80H | 'T',"IME$"			;token value 0AAH
_TIME_ EQU	Q
Q	SET		Q+1
    DB      80H | 'D',"ATE$"			;token value 0ABH
_DATE_ EQU	Q
Q	SET		Q+1
    DB      80H | 'D',"AY$"				;token value 0ACH
_DAY_ EQU	Q
Q	SET		Q+1
    DB      80H | 'C',"OM"				;token value 0ADH
_COM EQU	Q
Q	SET		Q+1
    DB      80H | 'M',"DM"				;token value 0AEH
_MDM EQU	Q
Q	SET		Q+1
    DB      80H | 'K',"EY"				;token value 0AFH
_KEY EQU	Q
Q	SET		Q+1
    DB      80H | 'C',"LS"				;token value 0B0H
_CLS EQU	Q
Q	SET		Q+1
    DB      80H | 'B',"EEP"				;token value 0B1H
_BEEP EQU	Q
Q	SET		Q+1
    DB      80H | 'S',"OUND"			;token value 0B2H
_SOUND EQU	Q
Q	SET		Q+1
    DB      80H | 'L',"COPY"			;token value 0B3H
_LCOPY EQU	Q
Q	SET		Q+1
    DB      80H | 'P',"SET"				;token value 0B4H
_PSET EQU	Q
Q	SET		Q+1
    DB      80H | 'P',"RESET"			;token value 0B5H
_PRESET EQU	Q
Q	SET		Q+1
    DB      80H | 'M',"OTOR"			;token value 0B6H
_MOTOR EQU	Q
Q	SET		Q+1
    DB      80H | 'M',"AX"				;token value 0B7H
_MAX EQU	Q
Q	SET		Q+1
    DB      80H | 'P',"OWER"			;token value 0B8H
_POWER EQU	Q
Q	SET		Q+1
    DB      80H | 'C',"ALL"				;token value 0B9H
_CALL EQU	Q
Q	SET		Q+1
    DB      80H | 'M',"ENU"				;token value 0BAH
_MENU EQU	Q
Q	SET		Q+1
    DB      80H | 'I',"PL"				;token value 0BBH
_IPL EQU	Q
Q	SET		Q+1
    DB      80H | 'N',"AME"				;token value 0BCH
_NAME EQU	Q
Q	SET		Q+1
    DB      80H | 'K',"ILL"				;token value 0BDH
_KILL EQU	Q
Q	SET		Q+1
    DB      80H | 'S',"CREEN"			;token value 0BEH
_SCREEN EQU	Q
Q	SET		Q+1
    DB      80H | 'N',"EW"				;token value 0BFH
_NEW EQU	Q
Q	SET		Q+1
;
; Function keyword table TAB to <
;
R_FUN_KEYWORD_TBL1:								;018FH
    DB      80H | 'T',"AB("				;token value 0C0H
_TAB_ EQU	Q
Q	SET		Q+1
    DB      80H | 'T',"O"				;token value 0C1H
_TO EQU	Q
Q	SET		Q+1
    DB      80H | 'U',"SING"			;token value 0C2H
_USING EQU	Q
Q	SET		Q+1
    DB      80H | 'V',"ARPTR"			;token value 0C3H
_VARPTR EQU	Q
Q	SET		Q+1
    DB      80H | 'E',"RL"				;token value 0C4H
_ERL EQU	Q
Q	SET		Q+1
    DB      80H | 'E',"RR"				;token value 0C5H
_ERR EQU	Q
Q	SET		Q+1
    DB      80H | 'S',"TRING$"			;token value 0C6H
_STRING_ EQU	Q
Q	SET		Q+1
    DB      80H | 'I',"NSTR"			;token value 0C7H
_INSTR EQU	Q
Q	SET		Q+1
    DB      80H | 'D',"SKI$"			;token value 0C8H
_DSKI_ EQU	Q
Q	SET		Q+1
    DB      80H | 'I',"NKEY$"			;token value 0C9H
_INKEY_ EQU	Q
Q	SET		Q+1
    DB      80H | 'C',"SRLIN"			;token value 0CAH
_CSRLIN EQU	Q
Q	SET		Q+1
    DB      80H | 'O',"FF"				;token value 0CBH
_OFF EQU	Q
Q	SET		Q+1
    DB      80H | 'H',"IMEM"			;token value 0CCH
_HIMEM EQU	Q
Q	SET		Q+1
    DB      80H | 'T',"HEN"				;token value 0CDH
_THEN EQU	Q
Q	SET		Q+1
    DB      80H | 'N',"OT"				;token value 0CEH
_NOT EQU	Q
Q	SET		Q+1
    DB      80H | 'S',"TEP"				;token value 0CFH
_STEP EQU	Q
Q	SET		Q+1
    DB      80H | '+'					;token value 0D0H
_PLUS_ EQU	Q
Q	SET		Q+1
    DB      80H | '-'					;token value 0D1H
_MINUS_ EQU	Q
Q	SET		Q+1
    DB      80H | '*'					;token value 0D2H
_MULT_ EQU	Q
Q	SET		Q+1
    DB      80H | '/'					;token value 0D3H
_DIV_ EQU	Q
Q	SET		Q+1
    DB      80H | '^'					;token value 0D4H
_HAT_ EQU	Q
Q	SET		Q+1
    DB      80H | 'A',"ND"				;token value 0D5H
_AND EQU	Q
Q	SET		Q+1
    DB      80H | 'O',"R"				;token value 0D6H
_OR EQU	Q
Q	SET		Q+1
    DB      80H | 'X',"OR"				;token value 0D7H
_XOR EQU	Q
Q	SET		Q+1
    DB      80H | 'E',"QV"				;token value 0D8H
_EQV EQU	Q
Q	SET		Q+1
    DB      80H | 'I',"MP"				;token value 0D9H
_IMP EQU	Q
Q	SET		Q+1
    DB      80H | 'M',"OD"				;token value 0DAH
_MOD EQU	Q
Q	SET		Q+1
    DB      80H | '\\'					;token value 0DBH
_BACKSLASH_ EQU	Q
Q	SET		Q+1
    DB      80H | '>'					;token value 0DCH
_GT_ EQU	Q
Q	SET		Q+1
    DB      80H | '='					;token value 0DDH
_EQUAL_ EQU	Q
Q	SET		Q+1
    DB      80H | '<'					;token value 0DEH
_LT_ EQU	Q
Q	SET		Q+1
;
; Function keyword table SGN to MID$
;
R_FUN_KEYWORD_TBL2:						;01F0H
    DB      80H | 'S',"GN"				;token value 0DFH
_SGN EQU	Q
Q	SET		Q+1
    DB      80H | 'I',"NT"				;token value 0E0H
_INT EQU	Q
Q	SET		Q+1
    DB      80H | 'A',"BS"				;token value 0E1H
_ABS EQU	Q
Q	SET		Q+1
    DB      80H | 'F',"RE"				;token value 0E2H
_FRE EQU	Q
Q	SET		Q+1
    DB      80H | 'I',"NP"				;token value 0E3H
_INP EQU	Q
Q	SET		Q+1
    DB      80H | 'L',"POS"				;token value 0E4H
_LPOS EQU	Q
Q	SET		Q+1
    DB      80H | 'P',"OS"				;token value 0E5H
_POS EQU	Q
Q	SET		Q+1
    DB      80H | 'S',"QR"				;token value 0E6H
_SQR EQU	Q
Q	SET		Q+1
    DB      80H | 'R',"ND"				;token value 0E7H
_RDN EQU	Q
Q	SET		Q+1
    DB      80H | 'L',"OG"				;token value 0E8H
_LOG EQU	Q
Q	SET		Q+1
    DB      80H | 'E',"XP"				;token value 0E9H
_EXP EQU	Q
Q	SET		Q+1
    DB      80H | 'C',"OS"				;token value 0EAH
_COS EQU	Q
Q	SET		Q+1
    DB      80H | 'S',"IN"				;token value 0EBH
_SIN EQU	Q
Q	SET		Q+1
    DB      80H | 'T',"AN"				;token value 0ECH
_TAN EQU	Q
Q	SET		Q+1
    DB      80H | 'A',"TN"				;token value 0EDH
_ATN EQU	Q
Q	SET		Q+1
    DB      80H | 'P',"EEK"				;token value 0EEH
_PEEK EQU	Q
Q	SET		Q+1
    DB      80H | 'E',"OF"				;token value 0EFH
_EOF EQU	Q
Q	SET		Q+1
    DB      80H | 'L',"OC"				;token value 0F0H
_LOC EQU	Q
Q	SET		Q+1
    DB      80H | 'L',"OF"				;token value 0F1H
_LOF EQU	Q
Q	SET		Q+1
    DB      80H | 'C',"INT"				;token value 0F2H
_CINT EQU	Q
Q	SET		Q+1
    DB      80H | 'C',"SNG"				;token value 0F3H
_CSNG EQU	Q
Q	SET		Q+1
    DB      80H | 'C',"DBL"				;token value 0F4H
_CDBL EQU	Q
Q	SET		Q+1
    DB      80H | 'F',"IX"				;token value 0F5H
_FIX EQU	Q
Q	SET		Q+1
    DB      80H | 'L',"EN"				;token value 0F6H
_LEN EQU	Q
Q	SET		Q+1
    DB      80H | 'S',"TR$"				;token value 0F7H
_STR_ EQU	Q
Q	SET		Q+1
    DB      80H | 'V',"AL"				;token value 0F8H
_VAL EQU	Q
Q	SET		Q+1
    DB      80H | 'A',"SC"				;token value 0F9H
_ASC EQU	Q
Q	SET		Q+1
    DB      80H | 'C',"HR$"				;token value 0FAH
_CHR_ EQU	Q
Q	SET		Q+1
    DB      80H | 'S',"PACE$"			;token value 0FBH
_SPACE_ EQU	Q
Q	SET		Q+1
    DB      80H | 'L',"EFT$"			;token value 0FCH
_LEFT_ EQU	Q
Q	SET		Q+1
    DB      80H | 'R',"IGHT$"			;token value 0FDH
_RIGHT_ EQU	Q
Q	SET		Q+1
    DB      80H | 'M',"ID$"				;token value 0FEH
_MID_ EQU	Q
Q	SET		Q+1			
;	DB      80H | 27H					;single quote. token value 0FFH
    DB      80H | '\''

_QUOTE_ EQU	Q
Q	SET		Q+1
    DB      80H | ''
_NONE_ EQU	Q
Q	SET		Q+1

;
;BASIC statement vector table for END to NEW
;
R_BASIC_VECTOR_TBL:						;0262H
    DW      R_END_STMT, R_FOR_STMT, R_NEXT_STMT
    DW      R_DATA_STMT, R_INPUT_STMT, R_DIM_STMT
    DW      R_READ_STMT, R_LET_STMT, R_GOTO_STMT
    DW      R_RUN_STMT, R_IF_STMT, R_RESTORE_STMT
    DW      R_GOSUB_STMT, R_RETURN_STMT, R_REM_STMT
    DW      R_STOP_STMT, R_WIDTH_STMT, R_REM_STMT
    DW      R_LINE_STMT, R_EDIT_STMT, R_ERROR_STMT
    DW      R_RESUME_STMT, R_OUT_STMT, R_ON_STMT
    DW      R_DSKO_FUN, R_OPEN_STMT, R_CLOSE_STMT
    DW      R_LOAD_STMT, R_MERGE_STMT, R_FILES_STMT
    DW      R_SAVE_STMT, R_LFILES_FUN, R_LPRINT_STMT
    DW      R_DEF_STMT, R_POKE_FUN, R_PRINT_STMT
    DW      R_CONT_STMT, R_LIST_STMT, R_LLIST_STMT
    DW      R_CLEAR_STMT, R_CLOAD_STMT, R_CSAVE_STMT
    DW      R_TIME_STMT, R_DATE_STMT, R_DAY_STMT
    DW      R_COM_MDM_STMT, R_COM_MDM_STMT, R_KEY_STMT
    DW      R_CLS_STMT, R_BEEP_STMT, R_SOUND_STMT
    DW      R_LCOPY_STMT, R_PSET_STMT, R_PRESET_STMT
    DW      R_MOTOR_STMT, R_MAX_FUN2, R_POWER_STMT
    DW      R_CALL_STMT, R_MENU_ENTRY, R_IPL_STMT
    DW      R_NAME_STMT, R_KILL_STMT, R_SCREEN_STMT
    DW      R_NEW_STMT

;
; Math operator priority table
;
R_MATH_PRIORITY_TBL:				    ;02E2H
    DB      79H,79H,7CH,7CH,7FH,50H,46H,3CH
    DB      32H,28H,7AH,7BH
;
; Vector table for math operations
; Used for type conversions
;
R_MATH_VCTR_TBL:						;02EEH
    DW      L_FRCDBL, 0
    DW      R_CINT_FUN, L_CHKSTR, R_CSNG_FUN
L_MATH_TBL_1:
    DW      R_DBL_ADD, R_DBL_SUB, R_DBL_MULT
    DW      R_DBL_DIV, R_DBL_EXP, R_CMP_FAC1_FAC2
L_MATH_TBL_2:
    DW      R_SNGL_ADD_BCDE, R_SNGL_SUB, R_SNGL_MULT_BCDE
    DW      R_SNGL_DIV, R_SNGL_EXP, R_SNGL_CMP_BCDE_FAC1
L_MATH_TBL_3:
    DW      R_SINT_ADD, R_SINT_SUB, R_SINT_MULT
    DW      R_INT16_DIV, R_INT_EXP, R_SINT_CMP
;
;BASIC error message text
;
R_BASIC_ERR_MSG_TXT:				       	;031CH
    DB      "NF"
    DB      "SN"
    DB      "RG"
    DB      "OD"
    DB      "FC"
    DB      "OV"
    DB      "OM"
    DB      "UL"
    DB      "BS"
    DB      "DD"
    DB      "/0"
    DB      "ID"
    DB      "TM"
    DB      "OS"
    DB      "LS"
    DB      "ST"
    DB      "CN"
    DB      "IO"
    DB      "NR"
    DB      "RW"
    DB      "UE"
    DB      "MO"
    DB      "IE"
    DB      "BN"
    DB      "FF"
    DB      "AO"
    DB      "EF"
    DB      "NM"
    DB      "DS"
    DB      "FL"
    DB      "CF"
;
; Initialization image loaded to F5F0H (SYSRAM_R) by COLD BOOT
;
R_FUN_INIT_IMAGE:						;035AH
	DW	 BOOTMARKER						;COLD vs WARM boot marker (at address 0F5F0H/SYSRAM_R)
	DW	 0000H							;Auto PowerDown signature (at address 0F5F2H)
	DW	 SYSRAM_R 						;initial value of HIMEM (at address 0F5F4H)
	if	VT100INROM
	JMP		phook
	else
	RET									;This RET can be changed to JMP to hook Boot-up (0F5F6H)
	DW	0000H							;Space for address for JMP
	endif
	EI									;This is the hook for WAND (F5F9H) (RST 5.5)
	RET									;Replace EI, RET, NOP with a JMP instruction
	NOP
	RET									;This is the RST 6.5 routine (RS232 receive interrupt) hook (0F5FCH/SERHK_R)
	DW	0000H							;Replace RET, NOP, NOP with a JMP instruction
	RET									;This is the RST 7.5 hook (Background tick) (F5FFH)
	DW	0000H
	JMP R_LOW_PWR_TRAP					;Normal TRAP (low power) interrupt routine - Hook at F602H

	if OPTROM
; ===================================
; Copy Option Rom routine to RAM to be used for switching back to the Option ROM after
;      calling a routine in the Main ROM.
;0040H  F5		 PUSH PSW				;Preserve the PSW
;0041H  3A 45 FF LDA PORTE8_R		 	;Contents of port E8H
;0044H  3C		 INR A				    ;Prepare to switch to OptRom. Set bit 0
;0045H  D3 E0	 OUT E0H				;Switch to OptRom
;0047H  F7		 RST 6
; ===================================	
	MVI	A,01H							;0F605H (ROMTST_R)
	OUT	0E8H							;ROM Select: 1 Option Rom
	LXI	H,0040H							;copy 0040-0047 from Option Rom to RAM
	LXI D,ROMSW_R						;location of code to switch back to the option rom
	MOV	A,M								;F60DH
	STAX D
;F60FH:
	INX	H
	INX	D
	MOV	A,L
	SUI 48H								;check if HL == 0048H
	JNZ 0F60FH
	OUT	0E8H							;A == 0 => 0 Standard Rom
	LHLD ROMSW_R						;Start of code to switch back to the option rom
	LXI	D,4354H							;validity check?
	JMP	R_COMP_DE_HL					;0018H
	DI									;0F624H Launch ROM command file from MENU program
	MVI	A,01H							;0F625H (63013) initialize TS-DOS ROM.
	OUT 0E8H							;ROM Select: 1 Option Rom
	RST 0
	DB		00H							;0F62AH Option Rom Flag Initial Value (ROMFLG_R)
	DB		01H							;0F62BH Dial speed (1=10pps), 2=20pps (MDMSPD_R)
	DW		0000H						;0F62CH pointer to FKey text (from FKey table) for selected FKey (FNKMAC_R)
	DW		0FFFFH						;0F62EH index into paste buffer (PBUFIDX_R)
	else								;OPTROM
	;RAM area F605H..F623H available
	DB		00H,00H,00H,00H,00H,00H,00H,00H			;0F605H (ROMTST_R)
	DB		00H,00H,00H,00H,00H,00H,00H,00H			;0F60DH
	DB		00H,00H,00H,00H,00H,00H,00H,00H			;0F615H
	DB		00H,00H,00H,00H,00H,00H,00H				;0F61DH
	DI												;0F624H Launch ROM command file from MENU program
	MVI	A,01H										;0F625H (63013) initialize TS-DOS ROM.
	OUT 0E8H										;ROM Select: 1 Option Rom
	RST 0											;restart
	DB		00H										;0F62AH Option Rom Flag Initial Value (ROMFLG_R)
	DB		01H										;0F62BH Dial speed (1=10pps), 2=20pps (MDMSPD_R)
	DW		0000H									;0F62CH pointer to FKey text (from FKey table) for selected FKey (FNKMAC_R)
	DW		0FFFFH									;0F62EH index into paste buffer (PBUFIDX_R)
	endif				;OPTROM
	
 	DB		00H,00H,00H,00H,00H       				;0F630H }	FKEYSTAT_R
	DB		00H,00H,00H,00H,01H,01H,08H,28H       	;0F635H }

	if VT100INROM
	DB		00H,00H,00H,01H,01H,01H,01H,18H       	;0F63DH } set DVIMAXROW_R to 24 by 80
	DB		50H,00H,00H,00H,50H,38H,30H,00H       	;0F645H }
	else											;!VT100INROM
	DB		00H,00H,00H,01H,01H,01H,01H,19H       	;0F63DH }
	DB		28H,00H,00H,00H,50H,38H,30H,00H       	;0F645H }
	endif											;VT100INROM

	DB		00H,00H,00H,00H,00H,00H,00H,00H       	;0F64DH } Initialized Data space at F6XXH
	DB		00H,00H,64H,0FFH,00H,00H,'M','7'      	;0F655H } (TIMMON_R)
	DB		'I','1','E',0C3H,00H,00H,00H,0C9H     	;0F65DH }
	DB		00H,0C9H,0D3H,00H,0C9H,0DBH,00H,0C9H  	;0F665H }
	DB		':',00H,00H,00H,00H,00H,00H,00H       	;0F66DH }
	DB		00H,0EH,00H,15H,0FDH,0FEH,0FFH,0B2H   	;0F675H }
	DB		0FCH,00H,00H
R_FUN_INIT_IMAGE_END:
;
;BASIC message strings
;
R_ERROR_MSG:							;03EAH
    DB      " Error",00H
R_IN_MSG:
    DB      " in "
R_NULL_MSG:
    DB      00H
R_OK_MSG:
    DB      "Ok",0DH,0AH,00H
R_BREAK_MSG:
    DB      "Break",00H
;
; FNDFOR IS USED FOR FINDING "FOR" ENTRIES ON
; THE STACK, WHENEVER A "FOR" IS EXECUTED A
; 24 BYTE ENTRY IS PUSHED ONTO THE STACK,
; BEFORE THIS IS DONE, HOWEVER, A CHECK
; MUST BE MADE TO SEE IF THERE
; ARE ANY "FOR" ENTRIES ALREADY ON THE STACK
; FOR THE SAME LOOP VARIABLE, IF SO, THAT "FOR" ENTRY
; AND ALL OTHER "FOR" ENTRIES THAT WERE MADE AFTER IT
; ARE ELIMINATED FROM THE STACK, THIS IS SO A
; PROGRAM THAT JUMPS OUT OF THE MIDDLE
; OF A "FOR" LOOP AND THEN RESTARTS THE LOOP AGAIN
; AND AGAIN WON'T USE UP 24 BYTES OF STACK
; SPACE EVERY TIME, THE "NEXT" CODE ALSO
; CALLS FNDFOR TO SEARCH FOR A "FOR" ENTRY WITH
; THE LOOP VARIABLE IN
; THE "NEXT". AT WHATEVER POINT A MATCH IS FOUND
; THE STACK IS RESET, IF NO MATCH IS FOUND A
; "NEXT WITHOUT FOR" ERROR OCCURS. GOSUB EXECUTION
; ALSO PUTS A 6 BYTE ENTRY ON STACK,
; WHEN A RETURN IS EXECUTED FNDFOR IS
; CALLED WITH A VARIABLE POINTER THAT CAN'T
; BE MATCHED, WHEN "FNDFOR" HAS RUN
; THROUGH ALL THE "FOR" ENTRIES ON THE STACK
; IT RETURNS AND THE RETURN CODE MAKES
; SURE THE ENTRY THAT WAS STOPPED ON
; IS A GOSUB ENTRY, THIS ASSURES THAT
; IF YOU GOSUB TO A SECTION OF CODE
; IN WHICH A FOR LOOP IS ENTERED BUT NEVER
; EXITED THE RETURN WILL STILL BE
; ABLE TO FIND THE MOST RECENT
; GOSUB ENTRY, THE "RETURN" CODE ELIMINATES THE
; "GOSUB" ENTRY AND ALL "FOR" ENTRIES MADE AFTER	
; ThE GOSUB ENTRY,
;
; FIND A FOR ENTRY ON THE STACK WITH THE VARIABLE POINTER
; PASSED IN DE
;
; IN:
;	DE		ptr to variable
; OUT:
;	HL		virtual stack ptr
;	Z		set if matching variable found
;
FNDFOR:
	LXI     H,0004H						;IGNORING EVERYONE'S "L_NEWSTT" AND THE RETURN ADDRESS OF THIS
	DAD		SP							;SUBROUTINE, SET HL += SP
FNDFOR_HL:								;HL is Virtual Stack Ptr
	MOV		A,M							;SEE WHAT TYPE OF THING IS ON THE STACK
	INX		H
	CPI		_FOR						;IS THIS STACK ENTRY A FOR?
	RNZ									;brif no _FOR match
	MOV		C,M							;get ptr to loop variable to BC from M
	INX		H
	MOV		B,M
	INX		H
	PUSH	H							;save virtual stack ptr
	MOV		H,B							;loop variable ptr to HL
	MOV		L,C
	MOV		A,D							;FOR THE "NEXT" STATEMENT WITHOUT AN ARGUMENT
	ORA		E							;WE MATCH ON ANYTHING
	XCHG								;MAKE SURE WE RETURN loop variable ptr
	JZ		POPGOF						;POINTING TO THE VARIABLE
	XCHG								;undo previous XCHG
	COMPAR								;compare input variable ptr and loop variable ptr: HL - DE
POPGOF:
	LXI		B,0016H						;Offset to next FOR ENTRY
	POP		H							;restore virtual stack ptr
	RZ									;retif match
	DAD		B							;update virtual stack ptr
	JMP		FNDFOR_HL					;TRY THE NEXT ONE
;
; Initialize system and go to BASIC ready
;
R_INIT_AND_READY:						;0422H
    LXI     B,R_POP_GO_BASIC_RDY
    JMP     R_RESTORE_JMP_BC			;Restore stack & runtime and jump to BC
; 
; Normal end of program reached
; 
L_END_OF_PROG:
    LHLD    CURLIN_R					;Currently executing line number
    MOV     A,H							;test for 0FFFFH
    ANA     L
    INR     A
    JZ      +							;brif CURLIN_R == 0FFFFH
; CURLIN_R != 0FFFFH. PRGRUN_R should be FALSE
    LDA     PRGRUN_R					;BASIC Program Running Flag
    ORA     A
    MVI     E,13H						;preload error #
    JNZ     R_GEN_ERR_IN_E				;Generate error 13H
+	JMP     L_ENDCON
; TODO unreachable
    JMP     R_GEN_ERR_IN_E				;Generate error in E

; 
; Generate SN error on DATA statement line
; 
L_GEN_DATA_SN_ERROR:
    LHLD    DATALIN_R					;Line number of current data statement
    SHLD    CURLIN_R					;Currently executing line number
;
; Generate Syntax error
;
R_GEN_SN_ERROR:							;0446H
    MVI     E,02H						;Load value for SN Error
	SKIP_2BYTES_INST_BC
;
; Generate /0 error
;
R_GEN_D0_ERROR:							;0449H
    MVI     E,0BH						;Load value for /0 Error
	SKIP_2BYTES_INST_BC
;
; Generate NF error
;
R_GEN_NF_ERROR:							;044CH
    MVI     E,01H						;Load value for NF Error
	SKIP_2BYTES_INST_BC
;
; Generate DD error
;
R_GEN_DD_ERROR:							;044FH
    MVI     E,0AH						;Load value for DD Error
	SKIP_2BYTES_INST_BC
;
; Generate RW error
;
R_GEN_RW_ERROR:							;0452H
    MVI     E,14H						;Load value for RW Error
	SKIP_2BYTES_INST_BC
;
; Generate OV error
;
R_GEN_OV_ERROR:							;0455H
    MVI     E,06H						;Load value for OV Error
	SKIP_2BYTES_INST_BC
;
; Generate MO error
;
R_GEN_MO_ERROR:							;0458H
    MVI     E,16H						;Load value for MO Error
	SKIP_2BYTES_INST_BC
;
; Generate TM error
;
R_GEN_TM_ERROR:							;045BH
    MVI     E,0DH						;Load value for TM Error
;
; Generate error in E
;
R_GEN_ERR_IN_E:							;045DH
    XRA     A
    STA     OPNFIL_R
;
; R_VAL_FUN() temporarily modified memory
;
    LHLD    VALSTRPTR_R					;test ptr past string data
    MOV     A,H
    ORA     L
    JZ      +							;brif ptr past string data==0: no VAL(str) active
    LDA     VALSTRDAT_R					;value past string data
    MOV     M,A							;restore value past string data
    LXI     H,0
    SHLD    VALSTRPTR_R					;clear ptr past string data
+	EI     
    LHLD    ACTONERR_R					;active ON ERROR handler vector
    PUSH    H							;Push ERROR handler vector to stack
    MOV     A,H							;test ERROR handler vector
    ORA     L
    RNZ									;retif ERROR handler vector != 0, execute active ON ERROR handler vector
    LHLD    CURLIN_R					;Currently executing line number
    SHLD    ERRLIN_R					;Line number of last error
    MOV     A,H							;test for 0FFFFH
    ANA     L
    INR     A
    JZ      L_GEN_ERR_IN_E_1			;Skip save of most recent lineNo if BASIC not running
    SHLD    DOT_R						;Most recent used or entered line number
L_GEN_ERR_IN_E_1:
    LXI     B,L_PRNT_ERR_IN_E			;Continuation function: ERROR print routine
;
; Restore stack & runtime and jump to BC
;
; IN:
;	BC code address
;
R_RESTORE_JMP_BC:						;048DH
    LHLD    BASSTK_R					;SP used by BASIC to reinitialize the stack
    JMP     L_INIT_BASIC_0

; 
; Generate Error in E Print routine
; 
L_PRNT_ERR_IN_E:
    POP     B
    MOV     A,E
    MOV     C,E
    STA     ERRFLG_R					;Last Error code
    LHLD    SAVTXT_R					;Most recent or currenly running line pointer
    SHLD    ERRTXT_R					;Pointer to occurance of error
    XCHG
    LHLD    ERRLIN_R					;Line number of last error
    MOV     A,H							;test for 0FFFFH
    ANA     L
    INR     A
    JZ      +
    SHLD    OLDLIN_R					;Line where break), END), or STOP occurred
    XCHG
    SHLD    OLDTXT_R					;Address where program stopped on last break), END), or STOP
    LHLD    ONERR_R						;Address of ON ERROR routine
    MOV     A,H
    ORA     L
    XCHG
+	LXI     H,PRGRUN_R				    ;BASIC Program Running Flag
    JZ      R_PRINT_BASIC_ERR			;Print BASIC error message - XX error in XXX
    ANA     M
    JNZ     R_PRINT_BASIC_ERR			;Print BASIC error message - XX error in XXX
    DCR     M
    XCHG
    JMP     L_NEWSTT_2					;Jump into Execute BASIC program loop
;
; Print BASIC error message - XX error in C
;
R_PRINT_BASIC_ERR:						;04C5H
    XRA     A
    MOV     M,A
    MOV     E,C
    CALL    R_LCD_NEW_LINE				;Move LCD to blank line (send CRLF if needed)
    MOV     A,E
    CPI     ';'
    JNC     +
    CPI     '2'
    JNC     L_PRNT_ERR_1
    CPI     17H
    JC      L_PRNT_ERR_2
+	MVI     A,'0'
L_PRNT_ERR_1:
    SUI     1BH
    MOV     E,A
L_PRNT_ERR_2:
    MVI     D,00H
    LXI     H,R_BASIC_ERR_MSG_TXT-2		;Code Based. 
    DAD     D
    DAD     D
    MVI     A,'?'						;3FH
    OUTCHR								;Send character in A to screen/printer
    MOV     A,M							;Code based
    OUTCHR								;Send character in A to screen/printer
    CHRGET								;Code Based. Get next non-white char from M
    OUTCHR								;Send character in A to screen/printer
    LXI     H,R_ERROR_MSG				;Code Based. 
    PUSH    H
    LHLD    ERRLIN_R					;Line number of last error
    XTHL
L_ERRFIN:
    CALL    R_PRINT_STRING				;Code Based. Print buffer at M until NULL or '"'
    POP     H
    MOV     A,H
    ANA     L
    INR     A
    CNZ     R_PRNT_BASIC_ERR_TERM    	;Finish printing BASIC ERROR message " in " line #
	SKIP_BYTE_INST						;Sets A to 0AFH
;
; Pop stack and vector to BASIC ready
;
R_POP_GO_BASIC_RDY:						;0501H
    POP     B
;
; Vector to BASIC ready - print Ok
;
R_GO_BASIC_RDY_OK:						;0502H
    CALL    R_SET_OUT_DEV_LCD			;Reinitialize output back to LCD
    CALL    L_CLS_FILE0					;close file 0 & Load LSTVAR_R
    CALL    R_LCD_NEW_LINE				;Move LCD to blank line (send CRLF if needed)
    LXI     H,R_OK_MSG					;Code Based. 
    CALL    R_PRINT_STRING				;Print buffer at M until NULL or '"'
;
; Silent vector to BASIC ready
;
L_MAIN:
R_GO_BASIC_RDY:							;0511H
    LXI     H,0FFFFH
    SHLD    CURLIN_R					;Currently executing line number
    LXI     H,COLONTXT_R				;contains ':'
    SHLD    SAVTXT_R					;Most recent or Currently running line pointer
    CALL    R_INP_DISP_LINE_NO_Q     	;Input and display (no "?") line and store
    JC      R_GO_BASIC_RDY				;IGNORE ^C
;
; Perform operation at M and return to ready
;
L_PROCESS_BASIC:						;0523H
    CHRGET								;Get next non-white char from M. Returns Carry flag if Numeric. Zero flag if 0
    INR     A							;test A while preserving carry
    DCR     A
    JZ      R_GO_BASIC_RDY				;brif empty line: vector to BASIC ready
    PUSH    PSW							;save carry
    CALL    L_LINGET					;Convert line number at M to binary in DE
    JNC     L_PROC_BAS_1				;brif OK
; number overflow
    CALL    L_TST_FCBLAST
    JZ      R_GEN_SN_ERROR				;brif FCBLAST == 0: Generate Syntax error
L_PROC_BAS_1:							;line number in DE
    DCX     H							;backup
    MOV     A,M
    CPI     ' '
    JZ      L_PROC_BAS_1				;brif A == ' '
    CPI     09H							;TAB
    JZ      L_PROC_BAS_1				;brif A == TAB
    INX     H							;next char
    MOV     A,M
    CPI     ' '
    CZ      L_INCHL						;Increment HL: skip ' '
    PUSH    D							;save line number
    CALL    R_CRUNCH					;Perform Token compression. Returns carry.
    POP     D							;restore line number
    POP     PSW							;restore carry
    SHLD    SAVTXT_R					;Most recent or currently running line pointer
    JNC     L_LINE_NONUM				;brif line didn't start with a number
    PUSH    D							;save line number
    PUSH    B							;save BC
; DONT ALLOW ANY FUNNY BUSINESS WITH EXISTING PGM
    XRA     A
    STA     PROFLG_R					;clear
    CHRGET								;Get next non-white char from M
    ORA     A							;test char
    PUSH    PSW							;save char & flags
    XCHG								;line number to HL
    SHLD    DOT_R						;Most recently entered line number
    XCHG								;line number back to DE
    CALL    L_FNDLIN					;Find line number in DE. Preserve carry for a while
										;returns ptr to link field in BC if carry
    JC      +							;found existing line
; line number doesn't exist
    POP     PSW							;retrieve char & flags
    PUSH    PSW
    JZ      R_GEN_UL_ERROR				;brif end of line: Generate UL error
    ORA     A							;test char
; BC ptr to link field in line
+	PUSH    B							;save link field ptr
    JNC     +							;brif forward if no carry, not Z
    CALL    L_COPY_TO_VARTAB			;Copy from (DE) to (BE) until DE == [VARTAB_R]
    MOV     A,C							;compute BC - DE
    SUB     E
    MOV     C,A
    MOV     A,B
    SBB     D
    MOV     B,A
    LHLD    DOSTRT_R					;DO files pointer
    DAD     B
    SHLD    DOSTRT_R					;DO files pointer
    LHLD    COSTRT_R					;CO files pointer
    DAD     B
    SHLD    COSTRT_R					;CO files pointer
    LHLD    XXSTRT_R
    DAD     B
    SHLD    XXSTRT_R
+	POP     D
    POP     PSW
    PUSH    D
    JZ      +
    POP     D
    LXI     H,0
    SHLD    ONERR_R						;Address of ON ERROR routine
    LHLD    VARTAB_R					;Start of variable data pointer
    XTHL
    POP     B
    PUSH    H
    DAD     B
    PUSH    H
    CALL    L_CPY_BC_TO_HL_CHK			;Copy data from BC to HL down until BC == DE w/ check
    POP     H
    SHLD    VARTAB_R					;Start of variable data pointer
    XCHG
    MOV     M,H
    POP     B
    POP     D
    PUSH    H
    INX     H
    INX     H
    MOV     M,E
    INX     H
    MOV     M,D
    INX     H
    LXI     D,TOKTMP_R					;temp storage for tokenized line
    PUSH    H
    LHLD    DOSTRT_R					;DO files pointer
    DAD     B
    SHLD    DOSTRT_R					;DO files pointer
    LHLD    COSTRT_R					;CO files pointer
    DAD     B
    SHLD    COSTRT_R					;CO files pointer
    LHLD    XXSTRT_R
    DAD     B
    SHLD    XXSTRT_R
    POP     H
;
; insert the new line
;
-	LDAX    D
    MOV     M,A
    INX     H							;next
    INX     D
    ORA     A
    JNZ     -
+	POP     D
    CALL    R_CHEAD						;Fixup all links. Find end of BASIC program.
    LHLD    FCBLAST_R					;FCB ptr for the last file used (2 bytes)
    SHLD    TEMP2_R
    CALL    R_INIT_BASIC_VARS			;Initialize BASIC Variables for new execution
    LHLD    TEMP2_R
    SHLD    FCBLAST_R					;FCB ptr for the last file used (2 bytes)
    JMP     R_GO_BASIC_RDY				;Silent vector to BASIC ready
;
; Update line addresses for current BASIC program
;
R_UPDATE_LINE_ADDR:						;05F0H
    LHLD    TXTTAB_R					;Start of BASIC program ptr
    XCHG								;BASIC program txt ptr to DE
;
; CHEAD GOES THROUGH PROGRAM STORAGE AND FIXES
; UP ALL THE LINKS, THE END OF EACH LINE IS
; FOUND BY SEARCHING FOR THE ZERO AT THE END,
; THE DBL ZERO LINK IS USED TO DETECT THE END OF THE PROGRAM
;
; IN:
;	DE		BASIC program line ptr
;
R_CHEAD:
    MOV     H,D							;copy BASIC program line ptr to HL
    MOV     L,E
    MOV     A,M							;SEE IF END OF CHAIN
    INX     H
    ORA     M
    RZ									;retif 0000 link found
	INX     H							;FIX HL TO START OF TEXT
    INX     H							;skip line number
    INX     H
    XRA     A							;clear
-	CMP     M							;find end of BASIC line
    INX     H
    JNZ     -							;loop
    XCHG								;HL ptr to previous line. DE ptr to current line
    MOV     M,E							;FIRST BYTE OF FIXUP
    INX     H							;next
    MOV     M,D							;2ND BYTE OF FIXUP
    JMP     R_CHEAD						;KEEP CHAINING TIL DONE
;
; Evaluate LIST statement arguments
; SCNLIN SCANS A LINE RANGE OF
; THE FORM #-# OK # OR #- OR -# OR BLANK
; AND THEN FINDS THE FIRST LINE IN THE RANGE
;
; OUT:
;	BC		First line ptr in the range
;
R_SCNLIN:
R_EVAL_LIST_ARGS:						;060AH
    LXI     D,0
    PUSH    D
    JZ      +
    POP     D
	CALL	 LINGET						;GET A LINE #, IF NONE, RETURNS ZERO
;    CALL    R_EVAL_LINE_NUM				;Evaluate line number text at M. IF NONE, RETURNS ZERO
    PUSH    D
    JZ      L_SCNLIN_1					;brif zero (no more arguments)
	SYNCHK	_MINUS_						;0D1H	token '-'
+	LXI     D,0FFFAH					;-4
    CNZ     R_EVAL_LINE_NUM				;Evaluate line number text at M
    JNZ     R_GEN_SN_ERROR				;Generate Syntax error
L_SCNLIN_1:
    XCHG
    POP     D
L_SCNLIN_2:								;Entry with DE linenumber
    XTHL
    PUSH    H
;
; Find line number in DE
; IN:
;	DE
; OUT:
;	BC
;	HL
;	carry
;
; L_FNDLIN SEARCHES THE PROGRAM TEXT FOR THE LINE
; WHOSE LINE # PASSED IN (D,E), (D,E) IS PRESERVED.
; THERE ARE THREE POSSIBLE RETURNS:
;
; 1) ZERO FLAG SET, CARRY NOT SET, LINE NOT FOUND
;	 NO LINE IN PROGRAM GREATER THAN ONE SOUGHT,
;	 (B,C) POINTS TO TWO ZERO BYTES AT END OF PROGRAM,
;	 (H,L)= (B,C) 
; 2) ZERO, CARRY SET,
;	 (B,C) POINTS TO THE LINK FIELD IN THE LINE
;	 WHICH IS THE LINE SEARCHED FOR,
;	 (H,L) POINTS TO THE LINK FIELD IN THE NEXT LINE,
; 3) NON-ZERO, CARRY NOT SET,
;	 LINE NOT FOUND, [B,C] POINTS TO LINE IN PROGRAM
;	 GREATER THAN ONE SEARCHED FOR,
;	 (H,L) POINTS TO THE LINK FIELD IN THE NEXT LINE.
;
;BASIC program:
;	2 bytes ptr to next line, 2 bytes line number, crunched text, 0 terminated
;	zero ptr to next line indicates end of program text
;
L_FNDLIN:								;0628H
    LHLD    TXTTAB_R					;Start of BASIC program pointer
;
; Find target line number in DE starting at HL (current txt ptr)
; Result in BC
;
L_FNDLIN_2:				   				;062BH
    MOV     B,H							;current BASIC txt ptr
    MOV     C,L
    MOV     A,M							;test for end of program: double 0
    INX     H							;next
    ORA     M
    DCX     H							;backup
    RZ									;retif double 0 found
    INX     H							;skip ptr to next line
    INX     H
    MOV     A,M							;get next line # to HL
    INX     H
    MOV     H,M
    MOV     L,A
    COMPAR								;Compare DE and HL: carry if HL < DE. No carry if next line # (HL) >= DE: HL - DE
    MOV     H,B							;restore BASIC txt ptr
    MOV     L,C
    MOV     A,M							;ptr to next BASIC line to HL
    INX     H							;no flags affected
    MOV     H,M
    MOV     L,A
    CMC									;complement carry
    RZ									;retif line numbers match (COMPAR result)
    CMC									;complement carry
    RNC									;retif next line # >= target line #
    JMP     L_FNDLIN_2     				;continue
;
; Perform Token compression
; HL points to identifier
; token value returned in C?
; return Carry and HL
;
R_CRUNCH:								;0646H
    XRA     A
    STA     DORES_R						;ALLOW CRUNCHING
    MOV     C,A
    LXI     D,TOKTMP_R					;temp storage for tokenized line: output ptr.
										;4 bytes before INPBUF_R
L_CRUNCH_0:
    MOV     A,M							;get char
    CPI     ' '							;skip space
    JZ      L_CRUNCH_4
    MOV     B,A							;save char
    CPI     '"'
    JZ      L_CRUNCH_6					;brif string
    ORA     A							;test
    JZ      L_CRUNCH_7					;brif end of identifier
    INX     H							;next
    ORA     A							;test
    JM      L_CRUNCH_0					;brif >= 128
    DCX     H							;previous
    LDA     DORES_R						;WHETHER CAN OR CAN'T CRUNCH RES'D WORDS
    ORA     A							;test
    MOV     A,M							;reload char
    JNZ     L_CRUNCH_4					;brif WHETHER CAN OR CAN'T CRUNCH RES'D WORDS TRUE
    CPI     '?'
    MVI     A,_PRINT					;PRINT token
    JZ      L_CRUNCH_4
    MOV     A,M							;reload char
    CPI     '0'
    JC      +							;brif < '0'
    CPI     '<'
    JC      L_CRUNCH_4					;brif < '<'
+	PUSH    D							;still TOKTMP_R
    LXI     D,R_BASIC_KEYWORD_TBL-1		;Code Based.
    PUSH    B							;save
    LXI     B,L_CRUNCH_CNT				;insert continuation function
    PUSH    B
    MVI     B,_END-1					;7FH start token value-1
    MOV     A,M							;get identifier char
; TODO could call R_CONV_A_TOUPPER() here
    CPI     'a'
    JC      L_CRUNCH_1					;brif < 'a'
    CPI     'z'+1						;7BH
    JNC     L_CRUNCH_1					;brif >= '{'
    ANI     5FH							;01011111 convert to upper case
    MOV     M,A							;update identifier char
L_CRUNCH_1:
    MOV     C,M
    XCHG								;keywords ptr to HL Code Based
-	INX     H							;next
    ORA     M							;Code Based find start of keyword
    JP      -							;brif bit 7 clear
    INR     B							;token value
    MOV     A,M							;Code Based get keyword char
    ANI     7FH							;clear bit 7
    RZ									;end of table
    CMP     C							;identifier char
    JNZ     -							;brif different
    XCHG								;keywords ptr back to DE
    PUSH    H							;save identifier start ptr
L_CRUNCH_2:
    INX     D							;next keyword char ptr
    LDAX    D							;Code based get keyword char
    ORA     A							;test for next keyword
    JM      L_CRUNCH_3					;end of keyword found
    MOV     C,A							;save
    MOV     A,B							;token value
    CPI     _GOTO						;special token value for "GOTO"
    JNZ     +
    CHRGET								;Get next non-white char from M
    DCX     H
+	INX     H
    MOV     A,M							;identifier char
;
; note conversion to UC was done earlier for first character
;
    CPI     'a'							;61H
    JC      +							;brif < 'a'
    ANI     5FH							;01011111B convert to upper case
+	CMP     C							;compare identifier and keyword
    JZ      L_CRUNCH_2					;brif match
    POP     H							;restore identifier start ptr
    JMP     L_CRUNCH_1
;
; end of keyword found
;
L_CRUNCH_3:
    MOV     C,B							;tokenized value of identifier
    POP     PSW							;removed saved BC?
    XCHG
    RET

L_CRUNCH_CNT:
    XCHG
    MOV     A,C
    POP     B							;Restore line length from stack
    POP     D							;Restore output pointer from stack
    XCHG								;HL=output pointer, DE = input string
    CPI     _ELSE						;91H Test for ELSE token
    MVI     M,':'						;3AH insert ':' before ELSE
    JNZ     +							;brif not ELSE. Ignore previous insertion
    INR     C							;effectuate insertion
    INX     H
+	CPI     _QUOTE_						;0FFH Test for "'" token (Alternate REM)
    JNZ     +							;brif !comment
; replace "'" comment with ':' _REM
    MVI     M,':'						;3AH
    INX     H							;insert ':' indicating end of statement
    MVI     B,_REM						;8EH Load value for REM token
    MOV     M,B
    INX     H
    INR     C
    INR     C
+	XCHG								;HL=input line, DE = output pointer
;
; Save token in A to (DE)
;
L_CRUNCH_4:
    INX     H							;next char
    STAX    D							;store token in buffer
    INX     D							;next
    INR     C							;count
    SUI     ':'							;3AH Test for ':' token and rebase
    JZ      +							;brif A was ':'
    CPI     _DATA-':'					;test for DATA token (83H - 3AH = 49H)
    JNZ     L_CRUNCH_5
; A == 0. ':' or _DATA found: clear DORES_R
+	STA     DORES_R						;WHETHER CAN OR CAN'T CRUNCH RES'D WORDS
L_CRUNCH_5:
    SUI     _REM-':'					;54H Test for REM statement
    JZ      +							;brif match. A == 0
    SUI     _QUOTE_-_REM				;71H	Test for _QUOTE_ token
    JNZ     L_CRUNCH_0					;brif !match. Continue crunching
; A == 0. _REM or _QUOTE_ found
+	MOV     B,A							;Save termination marker as NULL (end of string)
;
; Copy data directly to (DE) for strings, _REM and _QUOTE_ token
;
-	MOV     A,M							;get next char
    ORA     A
    JZ      L_CRUNCH_7					;brif end of string
    CMP     B							;B == termination char
    JZ      L_CRUNCH_4					;Jump to Save token if termination char found (QUOTE or NULL)
;
; Copy Next byte of string or _REM to (DE)
; Entry point for string (B == '"')
;
L_CRUNCH_6:
    INX     H
    STAX    D
    INR     C							;count
    INX     D
    JMP     -							;Jump to test next byte for termination marker (QUOTE or NULL)
;
; End of string to tokenize found.
; A == 0
; C == count/line length
; DE
;
L_CRUNCH_7:
    LXI     H,0005H						;Prepare to add 5 to line length for Address, Line # & termination
    MOV     B,H							;zero extend C to BC (H == 0)
    DAD     B
    MOV     B,H							;new line length to BC
    MOV     C,L
    LXI     H,EOSMRK_R					;Load pointer to End of statement marker
    STAX    D							;Store Zero to output - End of line marker
    INX     D
    STAX    D							;Store 2nd zero to output - NULL next BASIC line address LSB
    INX     D
    STAX    D							;Store 3rd zero to output - NULL next BASIC line address MSB
    RET
;
; FOR statement
;
;	FOR var=start to final [step increment]
;
; A FOR ENTRY ON THE STACK HAS THE FOLLOWING FORMAT
; LOW ADRESS:
;
;	TOKEN (_FOR IN HIGH BYTE) 1 BYTE
;	A POINTER TO THE LOOP VARIABLE 2 BYTES (LSTVAR_R)
;	A BYTE REFLECTING THE SIGN OF THE INCREMENT 1 BYTE  ??? PLUS TYPE
;	THE STEP 8 BYTES.
;	THE UPPER VALUE 8 BYTES
;	THE LINE # OF THE "FOR" STATEMENT 2 BYTES
;	A TEXT POINTER INTO THE "FOR" STATEMENT 2 BYTES
;
; HIGH ADDRESS
;
; TOTAL 24 BYTES
;
R_FOR_STMT:								;0726H
    MVI     A,64H						;01100100 100.
    STA     SUBFLG_R					;DONT RECOGNIZE SUBSCRIPTED VARIABLES flag
;READ THE VARIABLE AND ASSIGN IT THE CORRECT INTIAL VALUE
;AND STORE A POINTER TO THE VARTABLE IN (TEMP)
    CALL    R_LET_STMT
    POP     B							;return address to BC
    PUSH    H							;TEXT PTR ON THE STACK (2 bytes)
	CALL    R_DATA_STMT				    ;DATA statement. Returns text ptr
    SHLD    MSTMP3_R					;save text ptr
    LXI     H,0002H
    DAD     SP
; FNDFOR MUST HAVE VARIABLE POINTER IN DE
-	CALL    FNDFOR_HL					;FNDFOR. Check for existing FOR loop for DE variable
    JNZ     +							;brif NOT found
; Found FOR loop structure for this variable on the stack
; FNDFOR_HL returns FOR structures size in BC, virtual stack ptr in HL
    DAD     B							;index virtual stack ptr to start of  
    PUSH    D							;save DE
    DCX     H							;get DE from M decrementing: must be loop variable ptr
    MOV     D,M
    DCX     H
    MOV     E,M
    INX     H							;reset virtual stack ptr
    INX     H
    PUSH    H							;save virtual stack ptr
    LHLD    MSTMP3_R					;saved loop variable for this FOR loop
    COMPAR								;HL - DE
    POP     H							;restore virtual stack ptr
    POP     D							;restore DE
    JNZ     -							;brif no match
    POP     D							;restore DE
    SPHL								;set SP to virtual stack ptr
    SHLD    BASSTK_R					;SP used by BASIC to reinitialize the stack
	SKIP_BYTE_INST_C
+	POP     D
    XCHG
    MVI     C,0CH
    CALL    R_GETSTK					;Test for 12 units free in stack space
    PUSH    H
    LHLD    MSTMP3_R					;FOR loop text ptr
    XTHL								;swap with saved HL: build _FOR loop structure on stack
    PUSH    H
    LHLD    CURLIN_R					;Currently executing line number
    XTHL								;swap with saved HL: build _FOR loop structure on stack
	SYNCHK	_TO							;TO Token
;
; TO statement
;
R_TO_STMT:								;076BH
    LSTTYP								;Determine type of last var used: C Clr = DBL P Clr = SNGL Z Set = String S: Set = Integer
    JZ      R_GEN_TM_ERROR				;Generate TM error if STRING type
    PUSH    PSW							;save type
    CALL    L_FRMEVL					;Main BASIC evaluation routine
    POP     PSW							;restore type
    PUSH    H							;text ptr
    JNC     L_TO_DOUBLE					;brif type DBL
    JP      L_TO_SINGLE					;brif type SNGL
    CALL    R_CINT_FUN					;CINT function
    XTHL								;swapped with saved text ptr: build _FOR loop structure on stack (just 2 bytes, not 8)
    LXI     D,0001H						;default step size
    MOV     A,M							;get next char/token
;
; STEP statement for integer type
;
R_STEP_STMT:							;0783H
    CPI     _STEP						;optional
    CZ      L_GETINT					;Evaluate expression at M. Result in DE 
    PUSH    D							;save step result: build _FOR loop structure on stack
    PUSH    H							;save text ptr
    XCHG								;step result to HL
    CALL    L_EVAL_HL					;Z, -1 or 1
    JMP     L_STEP_INT_SNGL				;2 items on stack: integer step value & txt ptr. BCDE used
;
; TO <DBL>
;
L_TO_DOUBLE:
    CALL    L_FRCDBL				    ;CDBL function
    POP     D							;restore DE
; create 8 bytes on the stack
    LXI     H,0FFF8H					;Load -8 into HL
    DAD     SP							;add to SP
    SPHL								;set new SP
    PUSH    D							;save DE
    CALL    L_CPY_FAC1_TO_M				;move FAC1 to M: build _FOR loop structure on stack
    POP     H
    MOV     A,M
    CPI     _STEP						;0CFH
    LXI     D,R_DBL_ONE					;Code Based. 1.0 default DBL step value
    MVI     A,01H						;preload 1 (step value positive)
    JNZ     +							;brif !_STEP token
    CHRGET								;Get next non-white char from M
    CALL    L_FRMEVL					;Main BASIC evaluation routine
    PUSH    H							;save text ptr
    CALL    L_FRCDBL				   	;CDBL function
    FSIGN								;Return 1 or -1 in A based on Sign bit of FAC1
    LXI     D,DFACLO_R				    ;FAC1
    POP     H							;restore text ptr
;:								;D now has ptr to Double TO value
+	MOV     B,H							;save text ptr
    MOV     C,L
; create 8 bytes on the stack for STEP value
    LXI     H,0FFF8H					;Load -8 into HL
    DAD     SP
    SPHL
    PUSH    PSW							;save step value sign
    PUSH    B							;save text ptr
    CALL    R_MOVE_TYP_BYTES_INC		;from (DE) to M
    POP     H							;restore text ptr to HL
    POP     PSW							;restore step value sign
    JMP     L_FOR_COMMON
;
; TO <SNGL>
;
L_TO_SINGLE:
    CALL    R_CSNG_FUN				    ;CSNG function
    CALL    R_SNGL_BCDE_EQ_FAC1      	;Load single precision FAC1 to BCDE
    POP     H							;restore text ptr
    PUSH    B							;save single precision TO value in BCDE:
    PUSH    D							;	build _FOR loop structure on stack
    LXI     B,1041H						;default SNGL constant 1.0 to BCDE 
    LXI     D,0
    MOV     A,M							;get next crunched char
    CPI     _STEP						;0CFH
    MVI     A,01H						;preload 1 (step value positive)
    JNZ     L_STEP_INT_SNGL_1			;brif no _STEP BCDE loaded
    CALL    L_FRMCHK      				;Main BASIC_1 evaluation routine _STEP value
    PUSH    H							;save text ptr
    CALL    R_CSNG_FUN				    ;CSNG function
    CALL    R_SNGL_BCDE_EQ_FAC1      	;Load single precision FAC1 to BCDE
    FSIGN								;Return 1 or -1 in A based on Sign bit of FAC1
;
; 2 items on stack at this entry point:
;	TO value (INT) and text ptr OR TO value (SNGL) and text ptr
;
L_STEP_INT_SNGL:
    POP     H							;restore text ptr
L_STEP_INT_SNGL_1:
    PUSH    D							;save SNGL STEP value in BCDE
    PUSH    B
    PUSH    B							;reserve 8 dummy bytes on stack
    PUSH    B
    PUSH    B
    PUSH    B
;	TO value (DBL) and text ptr
;	A Step value sign
L_FOR_COMMON:
    ORA     A							;step value sign
    JNZ     +							;brif != 0
    MVI     A,02H						;special sign value if 0
+	MOV     C,A							;save Step value sign in C
    LSTTYP								;Determine type of last var used: C Clr = DBL P Clr = SNGL Z Set = String S: Set = Integer
    MOV     B,A							;save in B
    PUSH    B							;save B & C: build _FOR loop structure on stack
    PUSH    H							;save text ptr
    LHLD    LSTVAR_R					;Address of last variable assigned
    XTHL								;swap LSTVAR_R and pushed text ptr: build _FOR loop structure on stack
L_PUSH_FOR:
    MVI     B,_FOR						;push _FOR on stack: build _FOR loop structure on stack
    PUSH    B
    INX     SP							;1 byte only
;
; NEW STATEMENT FETCHER
;
; BACK HERE FOR NEW STATEMENT. CHARACTER POINTED TO BY [H,L]
; ":" OR END-OF-LINE. THE ADDRESS OF THIS LOCATION IS
; LEFT ON THE STACK WHEN A STATEMENT IS EXECUTED SO
; IT CAN MERELY DO A RETURN WHEN IT IS DONE.
;
L_NEWSTT:								;0804H
    CALL    R_CHECK_RS232_QUEUE      	;Check RS232 queue for pending characters
    CNZ     L_PROCESS_ON_INT			;calif TRUE: process ON COM interrupt
    LDA     PNDINT_R					;test PNDINT_R
    ORA     A
    CNZ     L_PROCESS_ON_INT_1			;calif != 0: Process ON KEY/TIME$/COM/MDM interrupts
L_NEWSTT_1:
    CALL    L_CHK_KEY_CTRL				;Test for CTRL-C or CTRL-S
    SHLD    SAVTXT_R					;Most recent or currenly running line pointer
    XCHG
    LXI     H,0
    DAD     SP							;get SP into HL
    SHLD    BASSTK_R					;SP used by BASIC to reinitialize the stack
    XCHG
    MOV     A,M
    CPI     ':'
    JZ      R_RUN_BASIC_AT_HL			;Start executing BASIC program at HL
    ORA     A							;expect end of BASIC line here
    JNZ     R_GEN_SN_ERROR				;Generate Syntax error
    INX     H							;next BASIC line
L_NEWSTT_2:								;entry point with HL loaded
    MOV     A,M							;test ptr at M: next BASIC line
    INX     H
    ORA     M
    JZ      L_END_OF_PROG				;brif end of BASIC program
    INX     H							;advance to line number
	GETDEFROMMNOINC						;get line number in DE
    XCHG
    SHLD    CURLIN_R					;Currently executing line number

	if 0
	LDA	TRCFLG							;SEE IF TRACE IS ON
	ORA	A								;NON-ZERO MEANS YES
	JZ	L_NOTTRC						;SKIP THIS PRINTING
	PUSH	D							;SAVE THE TEXT POINTER
	MVI	A,'['							;FORMAT THE LINE NUMBER
	CALL	OUTDO						;OUTPUT IT
	CALL	LINPRT						;PRINT THE LINE # IN HL
	MVI	A,']'							;SOME MORE FORMATING
	CALL	OUTDO
	POP	D								;DE=TEXT POINTER
L_NOTTRC:
	endif

    XCHG
;
; Start executing BASIC program at HL
;
L_GONE:
R_RUN_BASIC_AT_HL:						;083AH
    CHRGET								;Get next non-white char from M
    LXI     D,L_NEWSTT					;continuation code
    PUSH    D
L_GONE3:
L_RUN_BASIC_PGRM_4:
    RZ									;to continuation if char == 0
;
; Execute token in A, HL points to crunched text
;
L_GONE2:
R_EXEC_INST_IN_A:						;0840H
    SUI     _END						;80H
    JC      R_LET_STMT				    ;brif A < _END LET statement equivalent
    CPI     _TAB_-_END					;40H
    JNC     L_IS_MIDSTR					;brif 0 based token >= 40H: must be MID$
;
; A now 0 based token range 0 (_END)..3FH (_NEW)
;
    RLC									;times 2
    MOV     C,A							;zero extend to BC
    MVI     B,00H
    XCHG								;HL to DE
    LXI     H,R_BASIC_VECTOR_TBL		;Code Based. 
    DAD     B							;index into R_BASIC_VECTOR_TBL
    MOV     C,M							;get function in BC
    INX     H
    MOV     B,M
    PUSH    B							;push function on stack as return address
    XCHG								;restore HL
;
; NEWSTT FALLS INTO CHRGET. THIS FETCHES THE FIRST CHAR AFTER
; THE STATEMENT TOKEN AND THE CHRGET'S "RET" DISPATCHES TO STATEMENT; Fall through to get the next non-white char
;
; RST 10H routine with pre-increment of HL
; Get next non-white char from M
; Returns Carry flag if Numeric. Zero flag if 0.
;
L_CHRGTR:								;0858H
    INX     H
    MOV     A,M
    CPI     ':'							;IS IT END OF STATMENT OR BIGGER
    RNC									;return if A >= ':' => non-numeric
L_CHRCON:
    CPI     ' '
    JZ      L_CHRGTR					;skip space
    CPI     0BH
    JNC     +							;brif A >= VT
    CPI     09H
    JNC     L_CHRGTR					;brif A < VT && A >= TAB, incl. LF
+   CPI     '0'							;Carry set if A < '0'
    CMC									;complement carry: Carry set if A >= '0'
    INR     A							;set flags except Carry
    DCR     A
    RET
;
; DEF statement
;
R_DEF_STMT:								;0872H
    CPI     _INT						;0E0H
    JZ      R_DEFINT_STMT				;DEFINT statement
    CPI     'D'
    JNZ     L_TRY_DEFSNG				;brif != 'D':try DEFSNG or DEFSTR
    CHRGET								;Get next non-white char from M
	SYNCHK	'B'
	SYNCHK	'L'
;
; DEFDBL statement
;
R_DEFDBL_STMT:							;0881H
    MVI     E,08H
    JMP     R_DECL_VAR_TYPE_E			;Declare variable at M to be type DBL
;
; DEFINT statement
;
R_DEFINT_STMT:							;0886H
    CHRGET								;Get next non-white char from M
    MVI     E,02H
    JMP     R_DECL_VAR_TYPE_E			;Declare variable at M to be type INT

L_TRY_DEFSNG:
	SYNCHK	'S'							;53H
    CPI     'N'							;4EH
    JNZ     L_VER_DEFSTR				;brif A != 'N'
    CHRGET								;Get next non-white char from M
	SYNCHK	'G'							;47H
;
; DEFSNG statement
;
R_DEFSNG_STMT:							;0896H
    MVI     E,04H
    JMP     R_DECL_VAR_TYPE_E			;Declare variable at M to be type SNGL
;
; Verify DEFSTR
;
L_VER_DEFSTR:
	SYNCHK	'T'							;54H
	SYNCHK	'R'							;52H
;
; DEFSTR statement
;
R_DEFSTR_STMT:							;089FH
    MVI     E,03H						;type STRING
;
; Declare variable at M to be type E
;
R_DECL_VAR_TYPE_E:						;08A1H
    CALL    R_ISLET_M				    ;Check if M is alpha character
    LXI     B,R_GEN_SN_ERROR			;continuation function
    PUSH    B
    RC									;retif no alpha
    SUI     'A'
    MOV     C,A							;rescaled character base 0
    MOV     B,A							;save
    CHRGET								;Get next non-white char from M
    CPI     _MINUS_						;token '-': letter range
    JNZ     +
    CHRGET								;Get next non-white char from M: end range
    CALL    R_ISLET_M				    ;Check if M is alpha character
    RC									;retif no alpha
    SUI     'A'							;rescale character base 0
    MOV     B,A							;save to B
    CHRGET								;Get next non-white char from M
+	MOV     A,B							;end letter range
    SUB     C
    RC 									;brif A < C
    INR     A							;make it a count
    XTHL								;remove continuation address, save text ptr
    LXI     H,DEFTBL_R				    ;DEF definition table
    MVI     B,00H						;zero extend C to BC
    DAD     B							;index
-	MOV     M,E							;set type
    INX     H							;next letter
    DCR     A							;count
    JNZ     -
    POP     H							;restore text ptr
    MOV     A,M							;next char
    CPI     ','
    RNZ									;retif done
    CHRGET								;Get next non-white char from M
    JMP     R_DECL_VAR_TYPE_E			;Declare another variable at M to be type E

L_EVAL_POS_EXPR_PREINC:
    CHRGET								;pre-increment
L_EVAL_POS_EXPR:						;Evaluate positive expression at M-1
    CALL    L_GETIN2					;Evaluate expression at M-1 to DE
    RP									;retif positive result
;
; Generate FC error
;
R_GEN_FC_ERROR:							;08DBH
    MVI     E,05H
    JMP     R_GEN_ERR_IN_E				;Generate error 5
;
; Evaluate line number text at M
;
LINGET:
R_EVAL_LINE_NUM:						;08E0H
    MOV     A,M							;next char
    CPI     '.'
    XCHG
    LHLD    DOT_R						;preload Most recent used or entered line number in DE
    XCHG
    JZ      L_CHRGTR					;brif period: Get next non-white char from M and return
;
; L_LINGET READS A LINE # FROM THE CURRENT TEXT POSITION
;
; LINE NUMBERS RANGE FROM 0 TO 65529
;
; THE ANSWER IS RETURNED IN [D,E].
; [H,L] IS UPDATED TO POINT TO THE TERMINATING CHARACTER
; AND [A] CONTAINS THE TERMINATING CHARACTER WITH CONDITION
; CODES SET UP TO REFLECT ITS VALUE.
;
; OUT:
;	A			TERMINATING CHARACTER
;	carry		FALSE if not numeric
;				TRUE if number overflow
;	DE			binary line number
;
L_LINGET:								;08EBH
    DCX     H							;correct for PREINC
L_LINGET_PREINC:					    ;08ECH
    LXI     D,0							;clear accumulated line number
L_MORLIN:
	CHRGET								;Get next non-white char from M
    RNC									;Return if not ASCII Digit '0-9'
    PUSH    H							;save txt ptr
    PUSH    PSW							;save new digit
    LXI     H,1998H						;Load value of 65520 / 10
    COMPAR								;Compare current binary number and 1998H: HL - DE
    JC      L_POPHSR					;brif line # would be too big. FORCE CALLER TO SEE DIGIT AND GIVE SYNTAX ERROR
    MOV     H,D							;intermediate result from DE
    MOV     L,E
    DAD     D							;x2
    DAD     H							;x4
    DAD     D							;x5
    DAD     H							;x10
    POP     PSW							;restore new digit
    SUI     '0'							;rebase
    MOV     E,A							;zero extend to DE
    MVI     D,00H
    DAD     D							;add new digit
    XCHG								;new intermediate result in DE	
    POP     H							;restore txt ptr
    JMP     L_MORLIN					;Loop
L_POPHSR:
	POP     PSW							;restore new digit
    POP     H							;restore txt ptr
    RET
;
; RUN statement
;
; IN:
;	Z		set is end of statement
;
R_RUN_STMT:								;090FH
    JZ      R_INIT_BASIC_VARS			;brif end of statement:
										;	Initialize BASIC Variables for new execution
    JNC     R_RUN_STMT_2				;RUN_2 statement
    CALL    R_INIT_BASIC_VARS_2
    LXI     B,L_NEWSTT					;continuation function
    JMP     L_RUNC2						;do GOTO
;
; GOSUB statement
;
R_GOSUB_STMT:							;091EH
    MVI     C,03H
    CALL    R_GETSTK					;Test for 3 units free in stack space
    POP     B							;remove return address
    PUSH    H							;save txt ptr
    PUSH    H							;prepare XTHL
    LHLD    CURLIN_R					;Currently executing line number
    XTHL								;CURLIN_R to stack, txt ptr to HL	
    LXI     B,0
    PUSH    B
    LXI     B,L_NEWSTT					;continuation function
    MVI     A,_GOSUB
    PUSH    PSW
    INX     SP							;only push byte _GOSUB
L_RUNC2:
    PUSH    B							;push continuation function address
;
; GOTO statement
;
R_GOTO_STMT:							;0936H
    CALL    L_LINGET					;Convert line number at M to binary in DE. 
L_GOTO_STMT_1:
    CALL    R_REM_STMT				    ;REM statement
    INX     H							;next char
    PUSH    H							;save txt ptr
    LHLD    CURLIN_R					;Currently executing line number
    COMPAR								;Compare Target Line number (DE) and CURLIN_R (HL): HL - DE
    POP     H							;restore txt ptr
; if target line number is > current line number, start search at current line number
    CC      L_FNDLIN_2     				;calif CURLIN_R < Line number: Find line number in DE starting at HL
; else start search from the beginning
    CNC     L_FNDLIN					;calif carry clear: Find line number in DE
    MOV     H,B
    MOV     L,C
    DCX     H
    RC
;
; Generate UL error
;
R_GEN_UL_ERROR:							;094DH
    MVI     E,08H
    JMP     R_GEN_ERR_IN_E				;Generate error in E

; 
; GOSUB to BASIC line due to ON KEY/TIME$/MDM/COM
; 
L_GOSUB_ON_INTR:
    PUSH    H							;Push line # to Stack
    PUSH    H							;Push again to preserve through XTHL
    LHLD    CURLIN_R					;Currently executing line number
    XTHL								;Put Current line number on Stack. HL=new line
    PUSH    B							;save BC
    MVI     A,_GOSUB					;8CH
    PUSH    PSW							;Push GOSUB Token to Stack
    INX     SP							;Remove flags from Stack. Keep only GOSUB token
    XCHG								;HL now has pointer to GOSUB line
    DCX     H							;Decrement to save as currently running line pointer
    SHLD    SAVTXT_R					;Most recent or currenly running line pointer
    INX     H							;Increment back to beginning of line
    JMP     L_NEWSTT_2					;Jump into Execute BASIC program loop
;
; RETURN statement
;
R_RETURN_STMT:							;0966H
    RNZ
    MVI     D,0FFH						;guaranteed no match
    CALL    FNDFOR						;Pop return address for NEXT or RETURN
    CPI     _GOSUB
    JZ      +
    DCX     H							;backup ptr if token == _GOSUB
+	SPHL								;HL to SP: remove any FOR structure
    SHLD    BASSTK_R					;SP used by BASIC to reinitialize the stack
    MVI     E,03H						;code for RG Error
    JNZ     R_GEN_ERR_IN_E				;Generate RG error
    POP     H
    MOV     A,H							;test HL
    ORA     L
    JZ      +
    MOV     A,M
    ANI     01H							;test bit 0
    CNZ     L_UPD_INTR_TBL				;calif bit 0 not set: update System Interrupt Table entry
+	POP     H							;restore text ptr
    SHLD    CURLIN_R					;Currently executing line number
    INX     H							;test for 0FFFFH
    MOV     A,H
    ORA     L
    JNZ     +							;brif text ptr != 0FFFFH
    LDA     PROFLG_R					;test PROFLG_R
    ORA     A
    JNZ     R_POP_GO_BASIC_RDY       	;brif PROFLG_R != 0: Pop stack and vector to BASIC ready
+	LXI     H,L_NEWSTT					;set as continuation function. Restore HL
    XTHL
	SKIP_BYTE_INST						;Sets A to 0AFH
L_DATA_STMT_POPHL:
    POP     H
;
; DATA statement
;
; IN:
;	D		number of expected DATA items
; OUT:
;	HL		text ptr
;
R_DATA_STMT:							;099EH
;Tricked out LXI B,0E3AH, NOP: skip MVI C,0 but also loads C with ':' (3AH)
    DB      01H,3AH						
;
; REM statement
; Also called for ELSE statement
;
; IN:
;	D		number of expected DATA items
;
R_REM_STMT:								;09A0H
    MVI     C,00H						;stop at end of line. TODO LXI B,0
    MVI     B,00H
L_REM1:
    MOV     A,C							;swap B & C					
    MOV     C,B
    MOV     B,A
L_REM2:
    MOV     A,M							;end of BASIC line?
    ORA     A
    RZ									;retif end of line
    CMP     B
    RZ									;retif A == B
    INX     H							;next txt ptr
    CPI     '"'							;22H
    JZ      L_REM1						;brif string
    SUI     8AH							;_IF ??
    JNZ     L_REM2						;brif not _IF, continue scanning
; IF found
    CMP     B							;carry set if A < B
    ADC     D
    MOV     D,A
    JMP     L_REM2						;continue
;
;
L_ASSIGN:								;continuation function from R_LINE_INPUT_FILE
    POP     PSW							;type of last variable used
    ADI		03H							;restore type
    JMP     L_LET_1
;
; LET statement: assignment
;
R_LET_STMT:								;09C3H
    CALL    R_FIND_VAR_ADDR				;Find address of variable at M and store in DE
	SYNCHK	_EQUAL_						;'=' token
    XCHG
    SHLD    LSTVAR_R					;store DE as Address of last variable assigned
    XCHG
    PUSH    D							;save variable address (lvalue)
    LDA     VALTYP_R					;Type of assignment variable
    PUSH    PSW							;save Type of assignment variable
    CALL    L_FRMEVL					;Main BASIC evaluation routine for expression
    POP     PSW							;restore Type of assignment variable
L_LET_1:								;A contains Type of assignment variable
    XTHL								;swap pushed variable address and HL (txt ptr)
L_LET_2:
    MOV     B,A							;Type of assignment variable to B
    LDA     VALTYP_R					;Type of last expression used (or expression)
    CMP     B							;do types match?
    MOV     A,B							;assignment variable type rules
    JZ      +							;brif same
    CALL    L_DO_MATH_VCTR_TBL			;match types
    LDA     VALTYP_R					;Type of assignment variable
+	LXI     D,DFACLO_R				    ;preload FAC1
    CPI     02H							;integer type
    JNZ     +							;brif ! integer type
; assignment is integer type
    LXI     D,IFACLO_R				    ;FAC1 for integers
;DE now has appropriate FAC address
+	PUSH    H							;save lvalue ptr
    CPI     03H							;string type?
    JNZ     L_LET_5						;brif not string type
;
; assignment is string type
;
    LHLD    IFACLO_R					;[FAC1]
    PUSH    H							;save string descriptor
    INX     H							;skip length
	GETDEFROMMNOINC						;string data ptr to DE
    LXI     H,INPBUF_R-1
    COMPAR								;INPBUF_R-1 - DE
    JC      L_LET_3						;brif INPBUF_R-1 < DE
    LHLD    STRGEND_R					;Unused memory pointer
    COMPAR								;STRGEND_R - DE
    POP     D							;pop string descriptor
    JNC     L_LET_4						;brif STRGEND_R >= DE
    LXI     H,STRSTKEND_R
    COMPAR								;Compare string descriptor and STRSTKEND_R: HL - DE
    JC      +							;brif STRSTKEND_R < DE
    LXI     H,TEMPPT_R+1				;0FB6AH String Stack address+1
    COMPAR								;TEMPPT_R+1 - DE
    JC      L_LET_4						;brif TEMPPT_R+1 < DE: String Stack underflow??
+	SKIP_BYTE_INST						;Sets A to 0AFH
L_LET_3:
    POP     D
    CALL    L_FRETMS				;POP string from string stack if same as DE
    XCHG								;swap assigned variable ptr (lvalue) and recent string descriptor
    CALL    L_STR_1
L_LET_4:
    CALL    L_FRETMS				;POP string from string stack if same as DE
    XTHL								;swap string descriptor ptr and lvalue
L_LET_5:
    CALL    R_MOVE_TYP_BYTES_INC		;VALTYP_R sized assignment from (DE) to M
    POP     D							;restore expression (lvalue or string descriptor ptr)
    POP     H							;restore BASIC txt ptr
    RET
;
; ON statement
;
R_ON_STMT:								;0A2FH
    CPI     _ERROR						;94H
    JNZ     R_ON_KEY_STMT				;ON KEY/TIME/COM/MDM GOSUB routine
;
; ON ERROR statement
;
R_ON_ERROR_STMT:						;0A34H
    CHRGET								;Get next non-white char from M
	SYNCHK	_GOTO						;88H
    CALL    L_LINGET				;Convert line number at M to binary in DE
    MOV     A,D							;test result
    ORA     E
    JZ      +							;brif line number == 0
    CALL    L_SCNLIN_2
    MOV     D,B
    MOV     E,C
    POP     H
    JNC     R_GEN_UL_ERROR				;Generate UL error
+	XCHG
    SHLD    ONERR_R						;Address of ON ERROR routine
    XCHG
    RC
    LDA     PRGRUN_R					;BASIC Program Running Flag
    ORA     A
    MOV     A,E
    RZ
    LDA     ERRFLG_R					;Last Error code
    MOV     E,A							;argument to L_GEN_ERR_IN_E_1
    JMP     L_GEN_ERR_IN_E_1
;
; ON KEY/TIME/COM/MDM GOSUB routine
;
R_ON_KEY_STMT:							;0A5BH
    CALL    R_DET_DEVICE_ARG			;Determine device (KEY/TIME/COM/MDM) for ON GOSUB
    JC      R_ON_TIME_STMT				;ON TIME$ handler
    PUSH    B
    CHRGET								;Get next non-white char from M
	SYNCHK	_GOSUB						;8CH
    XRA     A
L_LOOPONKEY:
    POP     B
    PUSH    B
    CMP     C
    JNC     R_GEN_SN_ERROR				;Generate Syntax error
    PUSH    PSW
    CALL    L_LINGET					;Convert line number at M to binary in DE
    MOV     A,D
    ORA     E
    JZ      +
    CALL    L_SCNLIN_2
    MOV     D,B
    MOV     E,C
    POP     H
    JNC     R_GEN_UL_ERROR				;Generate UL error
+	POP     PSW
    POP     B
    PUSH    PSW
    ADD     B
    PUSH    B
    CALL    R_ONCOM_STMT				;ON COM handler
    DCX     H
    CHRGET								;Get next non-white char from M
    POP     B
    POP     D
    RZ
    PUSH    B
    PUSH    D
	SYNCHK	','
    POP     PSW
    INR     A
    JMP     L_LOOPONKEY					;loop
;
; ON TIME$ handler
;
R_ON_TIME_STMT:							;0A94H
    CALL    L_GETBYT					;Evaluate byte expression at M-1
    MOV     A,M							;get token
    MOV     B,A							;save token
    CPI     _GOSUB						;8CH
    JZ      +
	SYNCHK	_GOTO						;88H
    DCX     H							;backup txt ptr
+	MOV     C,E
-	DCR     C
    MOV     A,B							;token
    JZ      R_EXEC_INST_IN_A			;Execute instruction in A), HL points to args
    CALL    L_LINGET_PREINC     		;Convert ASCII number at M+1 to binary
    CPI     ','
    RNZ
    JMP     -
;
; RESUME statement
;
R_RESUME_STMT:							;0AB0H
    LDA     PRGRUN_R					;BASIC Program Running Flag
    ORA     A
    JNZ     +							;brif Basic Program running
    STA     ONERR_R						;Clear ON ERROR routine
    STA     ONERR_R+1
    JMP     R_GEN_RW_ERROR				;Generate RW error ("Resume without error")
+	INR     A
    STA     ERRFLG_R					;Last Error code
    MOV     A,M
    CPI     _NEXT						;82H
    JZ      L_RESNXT
    CALL    L_LINGET					;Convert line number at M to binary in DE
    RNZ									
    MOV     A,D
    ORA     E
    JZ		+
    CALL    L_GOTO_STMT_1
    XRA     A
    STA     PRGRUN_R					;clear BASIC Program Running Flag
    RET

L_RESNXT:
    CHRGET								;Get next non-white char from M
    RNZ
    JMP     L_RESTXT

+	XRA     A
    STA     PRGRUN_R					;Clear BASIC Program Running Flag
    INR     A							;now 1
L_RESTXT:
    LHLD    ERRTXT_R					;Pointer to occurance of error
    XCHG
    LHLD    ERRLIN_R					;Line number of last error
    SHLD    CURLIN_R					;Currently executing line number
    XCHG
    RNZ									;GO TO L_NEWSTT IF JUST "RESUME"
    MOV     A,M
    ORA     A
    JNZ     L_NOTBGL
    INX     H
    INX     H
    INX     H
    INX     H
L_NOTBGL:
	INX     H
    MOV     A,D
    ANA     E
    INR     A
    JNZ     +
    LDA     PROFLG_R
    DCR     A
    JZ      L_STPEND					;brif PROFLG_R == 1
+	XRA     A
    STA     PRGRUN_R					;BASIC Program Running Flag
    JMP     R_DATA_STMT				    ;GET NEXT STMT
;
; ERROR statement
;
R_ERROR_STMT:							;0B0FH
    CALL    L_GETBYT					;Evaluate byte expression at M-1
    RNZ
    ORA     A
    JZ      R_GEN_FC_ERROR				;Generate FC error
    JMP     R_GEN_ERR_IN_E				;Generate error in E
;
; IF statement
;
R_IF_STMT:								;0B1AH
    CALL    L_FRMEVL					;Main BASIC evaluation routine
    MOV     A,M
    CPI     ','
    CZ      L_CHRGTR					;Get next non-white char from M
    CPI     _GOTO						;88H
    JZ      +
	SYNCHK	_THEN						;0CDH
    DCX     H							;backup text ptr
+	PUSH    H							;save text ptr
    CALL    L_VSIGN						;Determine sign of last variable used
    POP     H							;restore text ptr
    JZ      L_IF_STMT_2
L_IF_STMT_1:
    CHRGET								;Get next non-white char from M
    JC      R_GOTO_STMT				    ;GOTO statement
    JMP     L_RUN_BASIC_PGRM_4

L_IF_STMT_2:
    MVI     D,01H						;1 DATA item
-	CALL    R_DATA_STMT				    ;DATA statement
    ORA     A
    RZ
    CHRGET								;Get next non-white char from M
    CPI     _ELSE						;91H
    JNZ     -
    DCR     D
    JNZ     -
    JMP     L_IF_STMT_1
;
; LPRINT statement
;
R_LPRINT_STMT:							;0B4EH
    MVI     A,01H
    STA     PRTFLG_R					;Output device for RST 20H (0=screen)
    JMP     L_PRINT_STMT_1
;
; PRINT statement
;
R_PRINT_STMT:							;0B56H
    MVI     C,02H						;indicated PRINT
    CALL    L_VALIDATE_FILE_1
    CPI     '@'
    CZ      L_PRINT_POS					;set new cursor Position
L_PRINT_STMT_1:
    DCX     H
    CHRGET								;Get next non-white char from M
    CZ      L_PRINT_CRLF
L_PRINT_STMT_2:
    JZ      L_FINPRT
    CPI     _USING						;0C2H
    JZ      R_USING_FUN				    ;USING function
    CPI     _TAB_						;0C0H
    JZ      R_TAB_STMT				    ;TAB statement
    PUSH    H
    CPI     ','
    JZ      L_PRINT_STMT_6
    CPI     ';'
    JZ      L_PRINT_NEXT
    POP     B
    CALL    L_FRMEVL					;Main BASIC evaluation routine
    PUSH    H
    LSTTYP								;Determine type of last var used: C Clr = DBL P Clr = SNGL Z Set = String S: Set = Integer
    JZ      L_PRINT_STMT_5						;brif string
    CALL    R_PRINT_FAC1_ZERO			;Convert binary number in FAC1 to ASCII at MBUFFER_R
    CALL    R_STRLTI_PREDEC_HL			;scan string
    MVI     M,' '
    LHLD    IFACLO_R					;FAC1 for integers
    INR     M
    CALL    L_TST_FCBLAST
    JNZ     L_PRINT_STMT_4				;brif FCBLAST != 0
    LHLD    IFACLO_R					;FAC1 for integers
    LDA     PRTFLG_R					;Output device for RST 20H (0=screen)
    ORA     A
    JZ      +
    LDA     LPTPOS_R					;Line printer head position
    ADD     M
    CPI     0FFH
    JMP     L_PRINT_STMT_3
+	LDA     LINWDT_R					;Active columns count (1-40)
    MOV     B,A
    INR     A
    JZ      L_PRINT_STMT_4
    LDA     CURHPOS_R					;Horiz. position of cursor (0-39)
    ADD     M
    DCR     A
    CMP     B
L_PRINT_STMT_3:
    JC      L_PRINT_STMT_4
    CZ      L_RECORD_CR
    CNZ     L_PRINT_CRLF
L_PRINT_STMT_4:
    CALL    L_PRINT_LST_STR
    ORA     A
L_PRINT_STMT_5:
    CZ      L_PRINT_LST_STR
    POP     H
    JMP     L_PRINT_STMT_1
L_PRINT_STMT_6:
    LXI     B,08H
    LHLD    FCBLAST_R					;FCB ptr for the last file used (2 bytes)
    DAD     B
    CALL    L_TST_FCBLAST
    MOV     A,M							;HL == 8 if !FCBLAST_R. A unused if !FCBLAST_R
    JNZ     L_PRINT_STMT_8
    LDA     PRTFLG_R					;Output device for RST 20H (0=screen)
    ORA     A
    JZ      +							;brif screen output
; PRTFLG_R != 0
    LDA     LPTPOS_R					;Line printer head position
    CPI     238							;0EEH
    JMP     L_PRINT_STMT_7				;carry if LPTPOS_R < 238
; screen output
+	LDA     COLWRAP_R					;comma value for print
    MOV     B,A							;save in B
    LDA     CURHPOS_R					;Horiz. position of cursor (0-39)
    CMP     B							;result in carry if CURHPOS_R < COLWRAP_R
L_PRINT_STMT_7:
    CNC     L_PRINT_CRLF				;calif (LPTPOS_R >= 238) or (CURHPOS_R >= COLWRAP_R)
    JNC     L_PRINT_NEXT
L_PRINT_STMT_8:							;compute modulo 14
    SUI     0EH							;14
    JNC     L_PRINT_STMT_8				;brif A >= 0
    CMA									;complement negative A
    JMP     L_TAB_STMT_2				;print A spaces
;
; TAB statement
;
;	TAB(num)
;
R_TAB_STMT:								;0C01H
    CALL    L_GTBYTC					;Evaluate byte expression at M to E
	SYNCHK	')'
    DCX     H							;backup text ptr
    PUSH    H							;save text ptr
    LXI     B,08H
    LHLD    FCBLAST_R					;FCB ptr for the last file used (2 bytes)
    DAD     B
    CALL    L_TST_FCBLAST
    MOV     A,M							;HL == 8 if !FCBLAST_R. A unused if !FCBLAST_R
    JNZ     L_TAB_STMT_1
    LDA     PRTFLG_R					;Output device for RST 20H (0=screen)
    ORA     A
    JZ      +							;brif PRTFLG_R == 0
    LDA     LPTPOS_R					;Line printer head position
    JMP     L_TAB_STMT_1
+	LDA     CURHPOS_R					;Horiz. position of cursor (0-39)
L_TAB_STMT_1:							;Expects position in A
    CMA									;complement position #
    ADD     E							;num value (mod 256)
    JNC     L_PRINT_NEXT
L_TAB_STMT_2:
    INR     A
    MOV     B,A
    MVI     A,' '
;Send B spaces to screen/printer	
-	OUTCHR
    DCR     B
    JNZ     -
;
; Prepare to process next item to print from PRINT statement
;
L_PRINT_NEXT:
    POP     H							;Stack cleanup
    CHRGET								;Get next non-white char from M
    JMP     L_PRINT_STMT_2						;Jump into PRINT statement to print next item
;
L_FINPRT:							;continuation function
    XRA     A
    STA     PRTFLG_R					;Output device for RST 20H (0=screen)
    PUSH    H							;save txt ptr
    MOV     H,A							;clear FCBLAST_R
    MOV     L,A
    SHLD    FCBLAST_R					;FCB ptr for the last file used (2 bytes)
    POP     H
    RET
;
; LINE statement
;
R_LINE_STMT:							;0C45H
    CPI     _INPUT						;84H
    JNZ     R_LINE_STMT_1				;LINE_1 statement
;
; LINE INPUT statement
;
    CHRGET								;Get next non-white char from M
    CPI     '#'
    JZ      R_LINE_INPUT_FILE			;LINE INPUT FROM FILE NUMBER # statement
    CALL    R_CHK_RUNNING_PGRM    		;Check for running program
    MOV     A,M
    CALL    L_INPUT_STMT_1
    CALL    R_FIND_VAR_ADDR				;Find address of variable at M and store in DE
    CALL    L_CHKSTR
    PUSH    D
    PUSH    H
    CALL    R_INP_DISP_LINE_NO_Q     	;Input and display (no "?") line and store
    POP     D
    POP     B
    JC      L_STPEND
    PUSH    B
    PUSH    D
    MVI     B,00H
    CALL    R_STRLTI_FOR_B				;Search string at M until 0 found
    POP     H
    MVI     A,03H
    JMP     L_LET_1

L_REDO_MSG:
    DB      "?Redo from start",0DH,0AH,00H
;
;
;
L_CHK_REDO:
    LDA     PRT_USING_R
    ORA     A
    JNZ     L_GEN_DATA_SN_ERROR			;brif PRT_USING_R != 0: Generate SN error on DATA statement line
; [PRT_USING_R] == 0
    POP     B
    LXI     H,L_REDO_MSG				;Code Based. 
    CALL    R_PRINT_STRING				;Print buffer at M until NULL or '"'
    LHLD    SAVTXT_R					;Most recent or currenly running line pointer
    RET
;
; INPUT # statement: read for file
;
R_INPUT_FROM_FILE:						;0C99H
    CALL    L_VALIDATE_FILE
    PUSH    H							;save FCB ptr
    LXI     H,INPBUF_R-1
    JMP     L_INPUT_STMT_3
;
; INPUT statement
;
R_INPUT_STMT:							;0CA3H
    CALL    R_CHK_RUNNING_PGRM  		;Check for running program
    MOV     A,M
    CPI     '#'							;input from file #?
    JZ      R_INPUT_FROM_FILE			;INPUT # statement
    CALL    R_CHK_RUNNING_PGRM  		;Check for running program
    MOV     A,M
    LXI     B,L_INPUT_STMT_2			;continuation function
    PUSH    B
L_INPUT_STMT_1:
    CPI     '"'
    MVI     A,00H
    RNZ
    CALL    R_STRLTI
	SYNCHK	';'	
    PUSH    H
    CALL    L_PRINT_LST_STR
    POP     H
    RET
L_INPUT_STMT_2:
    PUSH    H
    CALL    R_INP_DISP_LINE				;Input and display line and store
    POP     B
    JC      L_STPEND
    INX     H
    MOV     A,M
    ORA     A
    DCX     H
    PUSH    B
    JZ      L_DATA_STMT_POPHL
L_INPUT_STMT_3:
    MVI     M,','
    JMP     L_READ_STMT_1
;
; READ statement
;
; IN:
;	A
;
R_READ_STMT:							;0CD9H
    PUSH    H							;save txt ptr
    LHLD    DATAPTR_R					;Address where DATA search will begin next
	SKIP_XRA_A							;ORI 0AFH
L_READ_STMT_1:							;A == 0 entry point
    XRA     A							
    STA     PRT_USING_R					;set [PRT_USING_R]
    XTHL
    JMP     +
L_READ_STMT_2:
	SYNCHK	','
+	CALL    R_FIND_VAR_ADDR				;Find address of variable at M and store in DE
    XTHL
    PUSH    D							;variable address to stack
    MOV     A,M
    CPI     ','
    JZ      L_READ_STMT_3				;brif char == ','
    LDA     PRT_USING_R
    ORA     A
    JNZ     L_READ_STMT_8				;brif PRT_USING_R != 0
    MVI     A,'?'						;3FH
    OUTCHR								;Send character in A to screen/printer
    CALL    R_INP_DISP_LINE				;Input and display line and store
    POP     D
    POP     B
    JC      L_STPEND
    INX     H
    MOV     A,M
    DCX     H
    ORA     A
    PUSH    B
    JZ      L_DATA_STMT_POPHL
    PUSH    D
L_READ_STMT_3:
    CALL    L_TST_FCBLAST
    JNZ     L_READ_STMT_9				;brif FCBLAST != 0
    LSTTYP								;Determine type of last var used: C Clr = DBL P Clr = SNGL Z Set = String S: Set = Integer
    PUSH    PSW
    JNZ     L_READ_STMT_6				;brif not string type
    CHRGET								;Get next non-white char from M
    MOV     D,A
    MOV     B,A
    CPI     '"'
    JZ      L_READ_STMT_4
    LDA     PRT_USING_R
    ORA     A
    MOV     D,A
    JZ      +
    MVI     D,':'
+	MVI     B,','
    DCX     H
L_READ_STMT_4:
    CALL    L_STR_LOOP
L_READ_STMT_5:							;continuation function
    POP     PSW
    ADI		03H
    XCHG
    LXI     H,L_READ_STMT_7				;continuation function
    XTHL
    PUSH    D
    JMP     L_LET_2
; not string type
L_READ_STMT_6:
    CHRGET								;Get next non-white char from M
    LXI     B,L_READ_STMT_5				;continuation function
    PUSH    B
    JMP     R_ASCII_TO_DBL				;Convert ASCII number at M to double precision in FAC1

L_READ_STMT_7:
    DCX     H
    CHRGET								;Get next non-white char from M
    JZ      +
    CPI     ','
    JNZ     L_CHK_REDO
+	XTHL
    DCX     H
    CHRGET								;Get next non-white char from M
    JNZ     L_READ_STMT_2
    POP     D
    LDA     PRT_USING_R
    ORA     A
    XCHG
    JNZ     L_RESTORE_1
    PUSH    D
    CALL    L_TST_FCBLAST
    JNZ     +							;brif FCBLAST != 0
    MOV     A,M
    ORA     A
    LXI     H,L_Extra_MSG				;Code Based. 
    CNZ     R_PRINT_STRING				;Print buffer at M until NULL or '"'
+	POP     H
    JMP     L_FINPRT

L_Extra_MSG:
    DB      "?Extra ignored",0DH,0AH,00H

L_READ_STMT_8:
    CALL    R_DATA_STMT				    ;DATA statement
    ORA     A
    JNZ     +
    INX     H
    MOV     A,M
    INX     H
    ORA     M
    MVI     E,04H
    JZ      R_GEN_ERR_IN_E				;Generate error 4
    INX     H
	GETDEFROMMNOINC
    XCHG
    SHLD    DATALIN_R					;Line number of current data statement
    XCHG
+	CHRGET								;Get next non-white char from M
    CPI     _DATA						;83H
    JNZ     L_READ_STMT_8
    JMP     L_READ_STMT_3

L_FRMEQL:
	SYNCHK	_EQUAL_						;'=' token
    JMP     L_FRMEVL					;Main BASIC evaluation routine

L_FRMPRN:
	SYNCHK	'('
;
; Main BASIC evaluation routine
;
; During evaluation, order of precedence of operators is honored
; by PUSHing function handlers to the stack. Then they are
; unwound to be handled in the proper order.
;
L_FRMEVL:				;0DABH
    DCX     H
;
; Main BASIC_1 evaluation routine
;
L_FRMCHK:						    	;0DACH
    MVI     D,00H						;priority 0
;
; Main BASIC_1 evaluation routine with priority in D
;
L_LPOPER:
    PUSH    D							;save priority
    MVI     C,01H
    CALL    R_GETSTK					;Test for 1 unit free in stack space
    CALL    L_EVAL					    ;Evaluate function at M
; From mbasic 5.2
;RESET OVERFLOW PRINTING BACK TO NORMAL
;	XRA	A								;(SET TO 1 AT FUNDSP TO SUPPRESS
;	STA	FLGOVC							;MULTIPLE OVERFLOW MESSAGES)
L_TSTOP:
    SHLD    TEMP2_R						;store text ptr
L_RETAOP:
    LHLD    TEMP2_R						;restore text ptr
    POP     B							;restore priority
L_NOTSTV:
    MOV     A,M							;next char/token
    SHLD    TEMP3_R						;save src ptr
    CPI     _PLUS_						;token '+'
    RC									;done if A < _PLUS_
    CPI     _SGN
    RNC   								;return if token >= _SGN 
    CPI     _GT_
    JNC     L_COMP_OP					;brif token >= _GT_
; token is range _PLUS_ to _BACKSLASH_ (+, -, *, /, ^, AND, OR, XOR, EQV, IMP, MOD, \)
; rescale the token to 0..11 range
    SUI     _PLUS_						;0D0H
    MOV     E,A							;save rescaled token
    JNZ     +							;brif token was != _PLUS_
    LDA     VALTYP_R					;Type of last expression used
    CPI     03H							;String type?
    MOV     A,E							;restore rescaled token==0
    JZ      L_STR_CONCAT				;string concatenation
;
;	Operands are processed as given below:
;	1. (): Parentheses
;	2. ^: Exponentiation
;	3. +,-: Unary plus and minus (not to be confused with addition and subtraction)
;	4. *,/,\: Multiplication and division
;	5. MOD: Modulo
;	6. +,-: Addition and subtraction
;	7. <,>,=,>=,<=,<>: Comparison
;	8. NOT: Logical negation
;	9. AND: Logical AND
;	10. OR: Logical OR
;	11. XOR: Logical XOR
;	12. EQV: Logical inverse XOR
;	13. IMP: Logical bit selection
;
+	LXI     H,R_MATH_PRIORITY_TBL		;Code Based. table has 12 entries
    MVI     D,00H						;zero extend rescaled token
    DAD     D							;index into table
    MOV     A,B							;input priority
    MOV     D,M							;get priority
    CMP     D
    RNC									;return if input priority >= table priority
    PUSH    B
    LXI     B,L_RETAOP					;continuation function
    PUSH    B
    MOV     A,D							;priority
    CPI     51H
    JC      L_COMP_OP_1					;brif priority < 51H
    ANI     0FEH						;11111110H clear bit 0
    CPI     7AH
    JZ      L_COMP_OP_1					;brif priority == 7AH
;
;orig priorities:	 79H,79H,7CH,7CH,7FH,50H,46H,3CH,32H,28H,7AH,7BH
;D	priorities left: 79H,79H,7CH,7CH,7FH,XXX,XXX,XXX,XXX,XXX,XXX,7BH
;E	token: 			  +   -   *   /   ^	 AND  OR XOR EQV IMP MOD  \
;
L_EVAL_PRI_3:
    LXI     H,IFACLO_R				    ;FAC1 for integers
    LDA     VALTYP_R					;Type of last expression used
    SUI     03H							;STRING?
    JZ      R_GEN_TM_ERROR				;Generate TM error if type STRING
    ORA     A							;test VARTYP-3
    LHLD    IFACLO_R					;FAC1 for integers
    PUSH    H
    JM      +							;brif integer
    LHLD    DFACLO_R					;FAC1
    PUSH    H
    JPO     +
    LHLD    IFACLO_R+4
    PUSH    H
    LHLD    IFACLO_R+2
    PUSH    H
+	ADI		03H							;restore VARTYP
    MOV     C,E							;operator vector index
    MOV     B,A							;VALTYP_R
    PUSH    B
    LXI     B,L_COMP_OP_3				;vector function
;
; PUSH operator vector and continue evaluation
;
L_PUSH_OP_VEC:
    PUSH    B							;insert vector function 
    LHLD    TEMP3_R						;saved text ptr
    JMP     L_LPOPER					;recurse D has priority
;
; Handle '>', '=', '<' operators in expression
; ;
; A: token.
; Process if token >= _GT_ && token < _SGN:
;	_GT_, _EQUAL_, _LT_
;
; Also look for >=, <> and <=
; Turns out that MS-BASIC also accepts =>, >< and =< as relations operators!
;
; IN:
;	A		token
;	B		priority, preserved
; OUT:
;	D		relational operator code (1..6 for >, =, >=, <, <> and <=)
;
L_COMP_OP:
    MVI     D,00H						;clear CPRTYP
-	SUI     _GT_						;0DCH	rescale token to 0..2
    JC      L_COMP_OP_2					;brif OP < _GT_
    CPI     _LT_ - _GT_ +1				;03H
    JNC     L_COMP_OP_2					;brif OP > _LT_
    CPI     01H							;sets Carry if token < _EQUAL_
    RAL									;carry to bit 0
    XRA     D							;A is new CPRTYP
    CMP     D							;old CPRTYP
    MOV     D,A							;update CPRTYP
    JC      R_GEN_SN_ERROR				;brif new CPRTYP < old CPRTYP: Generate Syntax error
    SHLD    TEMP3_R						;save txt ptr
    CHRGET								;Get next non-white char from M
    JMP     -
;
; Also priority (in A) < 51H
;
L_COMP_OP_1:
    PUSH    D							
    CALL    R_CINT_FUN				    ;CINT function
    POP     D
    PUSH    H
    LXI     B,L_LOGIC_VEC				;Load pointer to vector for handling logic functions
    JMP     L_PUSH_OP_VEC				;PUSH operator vector and continue evaluation
;
; IN:
;	B		priority, preserved
;	D		relational operator code (1..6 for >, =, >=, <, <> and <=)
;
L_COMP_OP_2:
    MOV     A,B							;priority
    CPI     64H
    RNC									;retif priority >= 64H  
    PUSH    B							;save priority on the stack
    PUSH    D							;save CPRTYP on the stack
    LXI     D,6405H						;Priority in D, compare MATH vector index in E
    LXI     H,L_EVAL_REL_OP				;vector function
    PUSH    H
    LSTTYP								;Determine type of last var used: C Clr = DBL P Clr = SNGL Z Set = String S: Set = Integer
    JNZ     L_EVAL_PRI_3				;brif !STRING type
; String type
    LHLD    IFACLO_R					;[FAC1]
    PUSH    H							;stack argument for L_STR_CMP()
    LXI     B,L_STR_CMP					;string operator vector function
    JMP     L_PUSH_OP_VEC				;PUSH operator vector and continue evaluation

L_COMP_OP_3:
    POP     B
    MOV     A,C
    STA     DORES_R						;WHETHER CAN OR CAN'T CRUNCH RES'D WORDS
    LDA     VALTYP_R					;Type of last expression used
    CMP     B
    JNZ     +							;brif type mismatch
    CPI     02H							;type INTEGER
    JZ      L_COMP_OP_4
    CPI     04H							;type SNGL PREC
    JZ      L_COMP_OP_12
    JNC     L_COMP_OP_6					;brif A >= 4, i.e. DBL PREC.
+	MOV     D,A
    MOV     A,B
    CPI     08H
    JZ      L_COMP_OP_5
    MOV     A,D
    CPI     08H
    JZ      L_COMP_OP_10
    MOV     A,B
    CPI     04H
    JZ      L_COMP_OP_11
    MOV     A,D
    CPI     03H							;type STRING
    JZ      R_GEN_TM_ERROR				;Generate TM error
    JNC     L_COMP_OP_14						;brif type >= 3
L_COMP_OP_4:
    LXI     H,L_MATH_TBL_3				;Code Based. integer operators
    MVI     B,00H						;zero extend C to BC
    DAD     B							;word index
    DAD     B
    MOV     C,M							;operator function to BC
    INX     H
    MOV     B,M
    POP     D
    LHLD    IFACLO_R					;FAC1 for integers
    PUSH    B							;execute operator function
    RET

L_COMP_OP_5:
    CALL    L_FRCDBL				    ;CDBL function
L_COMP_OP_6:
    CALL    L_CPY_FAC1_TO_2				;Copy FAC1 to FAC2
    POP     H
    SHLD    IFACLO_R+2
    POP     H
    SHLD    IFACLO_R+4
L_COMP_OP_7:
    POP     B
    POP     D
    CALL    R_SNGL_FAC1_EQ_BCDE        	;Load single precision in BCDE to FAC1
L_COMP_OP_8:
    CALL    L_FRCDBL					;CDBL function
    LXI     H,L_MATH_TBL_1				;Code Based. 
L_COMP_OP_9:
    LDA     DORES_R						;WHETHER CAN OR CAN'T CRUNCH RES'D WORDS
    RLC									;times 2
    ADD     L							;add to HL
    MOV     L,A
    ADC     H
    SUB     L							;minus L
    MOV     H,A
    MOV     A,M							;get word at M to HL
    INX     H
    MOV     H,M
    MOV     L,A
    PCHL								;jmp to HL

L_COMP_OP_10:
    MOV     A,B
    PUSH    PSW
    CALL    L_CPY_FAC1_TO_2				;Copy FAC1 to FAC2
    POP     PSW
    STA     VALTYP_R					;Type of last expression used
    CPI     04H							;Single Precision?
    JZ      L_COMP_OP_7
    POP     H
    SHLD    IFACLO_R					;FAC1 for integers
    JMP     L_COMP_OP_8

L_COMP_OP_11:
    CALL    R_CSNG_FUN				  	;CSNG function
L_COMP_OP_12:
    POP     B
    POP     D
-	LXI     H,L_MATH_TBL_2				;Code Based. 
    JMP     L_COMP_OP_9

L_COMP_OP_14:
    POP     H
    CALL    R_PUSH_SNGL_FAC1			;Push single precision FAC1 on stack
    CALL    R_CONV_SINT_HL_SNGL        	;Convert signed integer HL to single precision FAC1
    CALL    R_SNGL_BCDE_EQ_FAC1        	;Load single precision FAC1 to BCDE
    POP     H
    SHLD    DFACLO_R					;FAC1
    POP     H
    SHLD    IFACLO_R					;FAC1 for integers
    JMP     -

;
; Integer Divide FAC1=DE/HL
;
R_INT16_DIV:							;0F0DH
    PUSH    H							;save
    XCHG								;DE => HL
    CALL    R_CONV_SINT_HL_SNGL      	;Convert signed integer HL to single precision FAC1
    POP     H							;restore
    CALL    R_PUSH_SNGL_FAC1			;Push single precision FAC1 on stack
    CALL    R_CONV_SINT_HL_SNGL      	;Convert signed integer HL to single precision FAC1
    JMP     L_STK_SNGL_DIV				;pop SNGL and do R_SNGL_DIV
;
; Evaluate function at M
;
R_EVAL:
L_EVAL:									;0F1CH
    CHRGET								;Get next non-white char from M
    JZ      R_GEN_MO_ERROR				;Generate MO error
    JC      R_ASCII_TO_DBL				;Convert ASCII number at M to double precision in FAC1
    CALL    R_ISLET				    	;Check if A is alpha character.
    JNC     R_ISVAR						;R_EVAL_VAR Evaluate variable. Carry set means numeric.
    CPI     _PLUS_
    JZ      R_EVAL					    ;ignore '+'
    CPI     '.'							;constant starting with '.'
    JZ      R_ASCII_TO_DBL				;Convert ASCII number at M to double precision in FAC1
    CPI     _MINUS_						;token '-'
    JZ      R_DO_MINUS
    CPI     '"'
;IF SO BUILD A DESCRIPTOR IN A TEMPORARY DESCRIPTOR LOCATION AND PUT A POINTER TO THE
;	DESCRIPTOR IN FACLO
    JZ      R_STRLTI
    CPI     _NOT
    JZ      R_NOT_FUN				    ;NOT function [NOTER]
    CPI     _ERR
    JNZ     L_EVAL_1
;
; ERR function
;
R_ERR_FUN:								;0F47H
    CHRGET								;Get next non-white char from M
    LDA     ERRFLG_R					;Last Error code
    PUSH    H
    CALL    L_LD_FAC1_BYTE				;Load byte iin A into FAC1
    POP     H
    RET

L_EVAL_1:
    CPI     _ERL
    JNZ     L_EVAL_2
;
; ERL function
;
R_ERL_FUN:								;0F56H
    CHRGET								;Get next non-white char from M
    PUSH    H
    LHLD    ERRLIN_R					;Line number of last error
    CALL    L_CONV_UNSGND_HL_SNGL		;Convert unsigned integer HL to single precision FAC1
    POP     H
    RET

L_EVAL_2:
    CPI     _TIME_						;TIME$
    JZ      R_TIME_FUN				  	;TIME$ function
    CPI     _DATE_						;DATE$
    JZ      R_DATE_FUN
    CPI     _DAY_						;DAY$
    JZ      R_DAY_FUN				    ;DAY function
    CPI     _MAX
    JZ      R_MAX_FUN				    ;MAX function
    CPI     _HIMEM
    JZ      R_HIMEM_FUN				    ;HIMEM function
    CPI     _VARPTR
    JNZ     L_EVAL_3
;
; VARPTR function
;
R_VARPTR_FUN:							;0F7EH
    CHRGET								;Get next non-white char from M
	SYNCHK	'('
    CPI     '#'
    JNZ     R_VARPTR_VAR_FUN			;VARPTR(variable) function
;
; VARPTR(#file) function
;
R_VARPTR_BUF_FUN:						;0F86H
    CALL    L_GTBYTC					;Evaluate byte expression at M
    PUSH    H							;save text ptr
    CALL    R_GET_FCB_FROM_A			;Get FCB for file in A
    XCHG								;result to DE
    POP     H							;restore text ptr
    JMP     +

;
; VARPTR(variable) function
;
; Get memory address of "variable"
;
R_VARPTR_VAR_FUN:						;0F92H
    CALL    L_FIND_ADDR_5				;Find address of variable at M
+	SYNCHK	')'
    PUSH    H							;save text ptr
    XCHG								;DE to HL
    MOV     A,H
    ORA     L
    JZ      R_GEN_FC_ERROR				;brif 0: Generate FC error
    CALL    L_MAKINT					;Load signed integer in HL to FAC1
    POP     H							;restore text ptr
    RET

L_EVAL_3:
    CPI     _INSTR
    JZ      R_INSTR_FUN				    ;INSTR function
    CPI     _INKEY_
    JZ      R_INKEY_FUN				    ;INKEY$ function
    CPI     _STRING_
    JZ      R_STRING_FUN				;STRING$ function
    CPI     _INPUT
    JZ      R_INPUT_STMT_2				;INPUT_2 statement
    CPI     _CSRLIN
    JZ      R_CSRLIN_FUN				;CSRLIN function
    CPI     _DSKI_
    JZ      R_DSKI_FUN				    ;DSKI$ function
;
; rescale the token
;
    SUI     _SGN						;0DFH
    JNC     L_EVAL_5					;brif token >= 0DFH: SGN to MID$
; token < _SGN
L_EVAL_4:								;evaluate expression in parens
    CALL    L_FRMPRN
	SYNCHK	')'
    RET

R_DO_MINUS:
    MVI     D,7DH						;priority
    CALL    L_LPOPER
    LHLD    TEMP2_R
    PUSH    H
    CALL    L_VNEG
L_POPHL_RET_2:							;duplicate
    POP     H
    RET
;
; Evaluate variable
;
R_ISVAR:
R_EVAL_VAR:								;0FDAH
    CALL    R_FIND_VAR_ADDR				;Find address of variable at M. Result in DE
;
; Return address L_ISVAR_1 is intercepted if variable does not exist yet.
;
L_ISVAR_1:
    PUSH    H
    XCHG								;variable ptr to HL
    SHLD    IFACLO_R					;FAC1 for integers
    LSTTYP								;Determine type of last var used: C Clr = DBL P Clr = SNGL Z Set = String S: Set = Integer
    CNZ     L_CPY_M_TO_FAC1				;Move VALTYP_R bytes from M to FAC1 with increment
    POP     H
    RET
;
; Get char at M and convert to uppercase
;
R_CONV_M_TOUPPER:						;0FE8H
    MOV     A,M
;
;Convert A to uppercase
;
R_CONV_A_TOUPPER:						;0FE9H
    CPI     'a'
    RC
    CPI     'z'+1
    RNC
    ANI     5FH							;01011111 clear bit 5
    RET

L_EVAL_5:
    MVI     B,00H						;preset
    RLC									;A times 2
    MOV     C,A
    PUSH    B
    CHRGET								;Get next non-white char from M
    MOV     A,C
    CPI     39H							;'9'
    JC      L_EVAL_6					;brif char < '9'
    CALL    L_FRMPRN
	SYNCHK	','
    CALL    L_CHKSTR
    XCHG
    LHLD    IFACLO_R					;load HL from FAC1 for integers
    XTHL								;swap [SP] and HL
    PUSH    H							;push [SP] again
    XCHG
    CALL    L_GETBYT					;Evaluate byte expression at M-1
    XCHG
    XTHL
    JMP     L_EVAL_7

L_EVAL_6:
    CALL    L_EVAL_4					;evaluate expression in parens
    XTHL								;swap [SP] and HL
    MOV     A,L
    CPI     0EH
    JC      +							;brif L < 0EH
    CPI     1DH
    JNC     +							;brif L >= 1DH
    LSTTYP								;Determine type of last var used: C Clr = DBL P Clr = SNGL Z Set = String S: Set = Integer
    PUSH    H							;save offset
    CC      L_FRCDBL				    ;calif carry set: CDBL function
    POP     H							;restore offset
+	LXI     D,L_POPHL_RET_2				;continuation function: POP H, RET
    PUSH    D
L_EVAL_7:
    LXI     B,R_FUN_VCTR_TBL			;Code Based. HL must be offset
L_VECT_JMP:
    DAD     B							;byte index.
    MOV     C,M							;get HL from Code Based M. Preserve A
    INX     H
    MOV     H,M
    MOV     L,C
    PCHL								;jmp to HL
;
; ASCII num conversion - find ASCII or tokenized '+' or '-' in A
;
R_ASCII_NUM_CONV:						;1037H
    DCR     D
    CPI     _MINUS_	
    RZ
    CPI     '-'
    RZ
    INR     D
    CPI     '+'
    RZ
    CPI     _PLUS_
    RZ
    DCX     H
    RET
;
; used as continuation function to evaluate a relational operator
; A == 1 or -1 from L_EVAL_CARRY_IN_A()
;
L_EVAL_REL_OP:
    INR     A							;A now 0 or 2. carry set if A was -1
    ADC     A							;normalize to -1,
    POP     B							;get CPRTYP to B
    ANA     B
    ADI		0FFH
    SBB     A
    CALL    L_SGN_EXTEND				;sign extend A to HL and FAC1
    JMP     +							;TODO jmp directly to L_RETAOP()
;
; NOT function
;
R_NOT_FUN:								;1054H
    MVI     D,5AH						;priority
    CALL    L_LPOPER
    CALL    R_CINT_FUN				    ;CINT function
    MOV     A,L
    CMA
    MOV     L,A
    MOV     A,H
    CMA
    MOV     H,A
    SHLD    IFACLO_R					;FAC1 for integers
    POP     B
+	JMP     L_RETAOP
;
; RST 28H routine
; Determine type of last var used
; C: Clear = Double Precision
; P: Clear = Single Precision
; Z: Set = String
; S: Set = Integer
;
; A contains VALTYP_R - 3
;
R_RST_28H:								;1069H
    LDA     VALTYP_R					;Type of last expression used
    CPI     08H							;Compare with Double Precision to set carry (Clear if Dbl)
    DCR     A
    DCR     A							;Decrement type 3 times to set Z, P and S flags
    DCR     A
    RET
;
; vector for handling logic functions
;
L_LOGIC_VEC:
    MOV     A,B
    PUSH    PSW
    CALL    R_CINT_FUN				   	;CINT function
    POP     PSW
    POP     D
    CPI     7AH							;MOD priority
    JZ      L_MOD_PRI
    CPI     7BH							;BACKSLASH priority
    JZ      R_SINT_DIV				    ;Signed integer divide (FAC1=DE/HL)
    LXI     B,L_LD_FAC1_BYTE_1			;continuation function
    PUSH    B
    CPI     46H							;OR priority
    JNZ     L_LOGIC_VEC_1
;
; OR function: A,L = DE | HL
;
;R_OR_FUN:								;108CH
    MOV     A,E
    ORA     L
    MOV     L,A
    MOV     A,H
    ORA     D
    RET

L_LOGIC_VEC_1:
    CPI     50H							;AND priority
    JNZ     L_LOGIC_VEC_2
;
; AND function:  A,L = DE & HL
;
;R_AND_FUN:								;1097H
    MOV     A,E
    ANA     L
    MOV     L,A
    MOV     A,H
    ANA     D
    RET

L_LOGIC_VEC_2:
    CPI     3CH							;XOR priority
    JNZ     L_LOGIC_VEC_3
;
; XOR function:  A,L = DE ^ HL
;
;R_XOR_FUN:								;10A2H
    MOV     A,E
    XRA     L
    MOV     L,A
    MOV     A,H
    XRA     D
    RET

L_LOGIC_VEC_3:
    CPI     32H							;EQV priority
    JNZ     R_IMP_FUN				    ;IMP function
;
; EQV function
;
;	EQV function (~(HL XOR DE))
;
;R_EQV_FUN:								;10ADH
    MOV     A,E							;Move LSB of DE to A
    XRA     L							;XOR with LSB of HL
    CMA									;Compliment the result
    MOV     L,A							;And save in L
    MOV     A,H							;Move MSB of HL to A
    XRA     D							;XOR with D
    CMA									;Compliment that result
    RET
;
; IMP function: Logical bit selection
;
;	IMP function (NOT ((NOT HL) AND DE))
;
R_IMP_FUN:								;10B5H
    MOV     A,L							;Load LSB of HL
    CMA									;Complement HL
    ANA     E							;AND with LSB of DE
    CMA									;Compliment the result
    MOV     L,A							;Save A
    MOV     A,H							;Get MSB of HL
    CMA									;Compliment HL
    ANA     D							;AND with MSB of DE
    CMA									;Compliment the result
    RET
;
; Subtract HL - DE and unsigned convert to SNGL in FAC1
;
; IN:
;	HL, DE		operands
;
L_SUB_DE_FROM_HL:
    MOV     A,L							;HL -= DE
    SUB     E
    MOV     L,A
    MOV     A,H
    SBB     D
    MOV     H,A
    JMP     L_CONV_UNSGND_HL_SNGL		;Convert unsigned integer HL to single precision FAC1
;
; LPOS function
;
R_LPOS_FUN:								;10C8H
    LDA     LPTPOS_R					;Line printer head position
    JMP     L_LD_FAC1_BYTE				;Load byte iin A into FAC1
;
; POS function
;
R_POS_FUN:								;10CEH
    LDA     CURHPOS_R					;Horiz. position of cursor (0-39)
;
; Load byte in A into FAC1
;
L_LD_FAC1_BYTE:							;10D1H
    MOV     L,A
    XRA     A
L_LD_FAC1_BYTE_1:						;also continuation function
    MOV     H,A
    JMP     L_MAKINT					;Load signed integer in HL to FAC1

L_DO_MATH_VCTR_TBL:
    PUSH    H
    ANI     07H							;max offset is 7
    LXI     H,R_MATH_VCTR_TBL			;Code Based. 
    MOV     C,A							;zero extend A to BC
    MVI     B,00H
    DAD     B							;byte index into R_MATH_VCTR_TBL
    CALL    L_VECT_JMP					;jump to vector
    POP     H
    RET
;
; Check for running program
;
R_CHK_RUNNING_PGRM:						;10E6H
    PUSH    H
    LHLD    CURLIN_R					;Currently executing line number
    INX     H
    MOV     A,H							;test HL
    ORA     L
    POP     H
    RNZ
;
; Generate ID error
;
R_GEN_ID_ERROR:							;10EFH
    MVI     E,0CH						;OS error?
    JMP     R_GEN_ERR_IN_E				;Generate error 12.
	
;
; A is 0 based token value 40H (_TAB_)..7FH (_QUOTE_)
; None of these tokens are valid at the beginning of a crunched line,
; except MID$:
;	MID$(str, pos) = "test"
;
L_IS_MIDSTR:
    CPI     _MID_-80H					;7EH
    JNZ     R_GEN_SN_ERROR				;Generate Syntax error
    INX     H							;next 
    JMP     LHSMID
; TODO unreachable code
    JMP     R_GEN_SN_ERROR				;Generate Syntax error
;
; INP function
;
R_INP_FUN:								;1100H
    CALL    L_CONINT
    STA     INCODE_R+1
    CALL    INCODE_R
    JMP     L_LD_FAC1_BYTE				;Load byte iin A into FAC1
;
; OUT statement
;
R_OUT_STMT:								;110CH
    CALL    L_SET_PORT_NUM
    JMP     OUTCODE_R
;
; Evaluate expression at M
;
; OUT:
;	DE		integer result
;	Z		set if result <= 255
;
;
L_GETINT:								;1112H
    CHRGET								;pre-increment
;
; Evaluate expression at M-1
;
; OUT:
;	Z		sign of expression
;	DE		expression value
;
L_GETIN2:								;1113H
    CALL    L_FRMEVL					;Main BASIC evaluation routine
L_INTFR2:
    PUSH    H							;save text ptr
    CALL    R_CINT_FUN				  	;CINT function
    XCHG								;result to DE
    POP     H							;restore text ptr
    MOV     A,D							;test sign
    ORA     A
    RET

L_SET_PORT_NUM:
    CALL    L_GETBYT					;Evaluate byte expression at M-1
    STA     INCODE_R+1					;port number
    STA     OUTCODE_R+1
	SYNCHK	','
    JMP     L_GETBYT					;Evaluate byte expression at M-1
;
; Evaluate expression at M. Must be byte value
;
; OUT:
;	A,E		byte value
;
L_GTBYTC:								;112DH
    CHRGET								;Get next non-white char from M
;
; Evaluate byte expression at M-1
;
; OUT:
;	A, E		byte value
;
L_GETBYT:								;112EH
    CALL    L_FRMEVL					;Main BASIC evaluation routine
L_CONINT:								;CONVERT THE FAC TO AN INTEGER IN DE
    CALL    L_INTFR2					;returns 0 if expression value <= 255
    JNZ     R_GEN_FC_ERROR				;Generate FC error
    DCX     H							;backup text ptr
    CHRGET								;Get next non-white char from M
    MOV     A,E							;RETURN THE RESULT IN [A] AND [E]
    RET
;
; LLIST statement
;
R_LLIST_STMT:							;113BH
    MVI     A,01H
    STA     PRTFLG_R					;Output device for RST 20H (0=screen)
;
; LIST statement
;
; Code shared with R_EDIT_STMT
;
;
R_LIST_STMT:							;1140H
    POP     B							;remove (fake) return address
    CALL    R_EVAL_LIST_ARGS			;Evaluate LIST statement arguments
    PUSH    B							;first line ptr in range
    MOV     H,B							;HL = first line ptr
    MOV     L,C
    SHLD    LASTLST_R					;Address where last BASIC list started
L_LIST_LOOP:
    LXI     H,0FFFFH
    SHLD    CURLIN_R					;set currently executing line number to -1
    POP     H							;result of R_EVAL_LIST_ARGS
    SHLD    NXTLINE_R					;next line ptr
    POP     D
    MOV     C,M							;BC = ptr to next basic line
    INX     H
    MOV     B,M
    INX     H
    MOV     A,B							;test BC
    ORA     C
    JZ      L_LIST_STMT_3				;brif BC == 0
    CALL    L_TST_FCBLAST
    CZ      L_CHK_KEY_CTRL				;calif FCBLAST==0: Test for CTRL-C or CTRL-S
    PUSH    B							;save ptr to next basic line
    MOV     C,M							;BC = Basic line number
    INX     H
    MOV     B,M
    INX     H							;HL now points to Basic txt
    PUSH    B							;save line number
    XTHL								;swap with Basic txt ptr
    XCHG								;line number to DE
    COMPAR								;HL - DE: HL - DE
    POP     B							;Basic txt ptr
    JC      L_LIST_STMT_2				;brif HL < DE: done
    XTHL								;swap Basic txt ptr and ptr to next Basic line
    PUSH    H
    PUSH    B
    XCHG
    SHLD    DOT_R						;Most recent used or entered line number
    CALL    R_PRINT_HL_ON_LCD			;Print binary number in HL at current position
    POP     H							;ptr to Basic txt
    MOV     A,M
    CPI     09H
    JZ      +
    MVI     A,' '
    OUTCHR								;Send character in A to screen/printer
+	CALL    L_EXPND_BASIC_LN			;copy Basic txt line to INPBUF_R
    LXI     H,INPBUF_R					;Keyboard buffer
    CALL    R_BUF_TO_LCD				;Send buffer at M to screen
    CALL    L_PRINT_CRLF
    JMP     L_LIST_LOOP
;
; Finished list Basic Program lines
;
L_LIST_STMT_2:
    POP     B							;clear stack
L_LIST_STMT_3:
    LDA     EDITFLG_R
    ANA     A
    JNZ     L_EDIT_MODE					;brif EDITFLG_R it set
    MVI     A,1AH						;^Z
    OUTCHR								;Send character in A to screen/printer
    JMP     R_GO_BASIC_RDY_OK			;Vector to BASIC ready - print Ok
;
; Send buffer at M to screen
;
R_BUF_TO_LCD:							;11A2H
    MOV     A,M							;get char
    ORA     A							;test
    RZ									;retif end of line
    OUTCHR								;Send character in A to screen/printer
    INX     H							;next char ptr
    JMP     R_BUF_TO_LCD				;Send buffer at M to screen

L_EXPND_BASIC_LN:
    LXI     B,INPBUF_R				    ;Keyboard buffer
    MVI     D,0FFH						;maximum BASIC line length
    XRA     A
    STA     DORES_R						;clear WHETHER CAN OR CAN'T CRUNCH RES'D WORDS
    JMP     L_EXPND_BASIC_LN_2
L_EXPND_BASIC_LN_1:
    INX     B							;next output ptr
    DCR     D							;decrement BASIC line length
    RZ									;retif done
L_EXPND_BASIC_LN_2:
	MOV     A,M							;get txt/token from Basic program
    INX     H							;next
    ORA     A							;test end of line
    STAX    B							;store it in output buffer
    RZ									;retif end of line
    CPI     '"'
    JNZ     +							;brif char != '"'
; char == '"': toggle DORES_R bit 0
    LDA     DORES_R						;WHETHER CAN OR CAN'T CRUNCH RES'D WORDS
    XRI     01H							;00000001
    STA     DORES_R						;WHETHER CAN OR CAN'T CRUNCH RES'D WORDS
    MVI     A,'"'						;reload
+	CPI     ':'
    JNZ     L_EXPND_BASIC_LN_3			;brif char != ':'
; char == ':': clear DORES_R	 bit 1 unless DORES_R bit 7 is set
    LDA     DORES_R						;WHETHER CAN OR CAN'T CRUNCH RES'D WORDS
    RAR
    JC      +
    RAL
    ANI     0FDH						;11111101 clear bit 1
    STA     DORES_R						;WHETHER CAN OR CAN'T CRUNCH RES'D WORDS
+	MVI     A,':'						;reload
L_EXPND_BASIC_LN_3:
    ORA     A
    JP      L_EXPND_BASIC_LN_1			;brif A not a BASIC token
; BASIC token found
    LDA     DORES_R						;WHETHER CAN OR CAN'T CRUNCH RES'D WORDS
    RAR
    JC      L_EXPND_BASIC_LN_1			;brif DORES_R bit 0 is set
    DCX     H							;backup in BASIC txt
    RAR									;test DORES_R bit 2
    RAR
    JNC     L_EXPND_BASIC_LN_9
    MOV     A,M
    CPI     0FFH
    PUSH    H							;save HL, BC
    PUSH    B
;
; Check for comment
;
    LXI     H,L_EXPND_BASIC_LN_4		;use continuation function to save 4 bytes
    PUSH    H
    RNZ									;to L_EXPND_BASIC_LN_4 if A != 0FFH
    DCX     B							;backup in INPBUF_R
    LDAX    B							
    CPI     'M'
    RNZ									;to L_EXPND_BASIC_LN_4 if A != 'M'
    DCX     B							;backup in INPBUF_R
    LDAX    B
    CPI     'E'
    RNZ									;to L_EXPND_BASIC_LN_4 if A != 'E'
    DCX     B							;backup in INPBUF_R
    LDAX    B
    CPI     'R'
    RNZ									;to L_EXPND_BASIC_LN_4 if A != "R'
    DCX     B							;backup in INPBUF_R
    LDAX    B
    CPI     ':'
    RNZ									;to L_EXPND_BASIC_LN_4 if A != ':'
    POP     PSW
    POP     PSW
    POP     H
    INR     D
    INR     D
    INR     D
    INR     D
    JMP     L_EXPND_BASIC_LN_10
L_EXPND_BASIC_LN_4:
    POP     B							;restore HL, BC
    POP     H
    MOV     A,M							;get token from BASIC txt
L_EXPND_BASIC_LN_5:
    INX     H							;next
    JMP     L_EXPND_BASIC_LN_1
	
L_EXPND_BASIC_LN_6:
    LDA     DORES_R						;WHETHER CAN OR CAN'T CRUNCH RES'D WORDS
    ORI     02H							;00000010 Set bit 1 (_DATA)
L_EXPND_BASIC_LN_7:
    STA     DORES_R						;WHETHER CAN OR CAN'T CRUNCH RES'D WORDS
    XRA     A
    RET
L_EXPND_BASIC_LN_8:
    LDA     DORES_R						;WHETHER CAN OR CAN'T CRUNCH RES'D WORDS
    ORI     04H							;00000100 Set bit 2 (_REM)
    JMP     L_EXPND_BASIC_LN_7
L_EXPND_BASIC_LN_9:
    RAL
    JC      L_EXPND_BASIC_LN_5
    MOV     A,M							;get token from BASIC txt
    CPI     _DATA
    CZ      L_EXPND_BASIC_LN_6			;calif A == _DATA
    CPI     _REM
    CZ      L_EXPND_BASIC_LN_8			;calif A == _REM
L_EXPND_BASIC_LN_10:
    MOV     A,M							;reload token from BASIC txt
    INX     H							;next
    CPI     _ELSE
    CZ      L_DEC_BC					;calif A == _ELSE
    SUI     7FH							;DEL rebase token
    PUSH    H							;save ptr to BASIC txt
; find BASIC keyword
    MOV     E,A							;rebased token value
    LXI     H,R_BASIC_KEYWORD_TBL		;Code Based. 
-	MOV     A,M							;get char from code space
    INX     H							;next
    ORA     A							;find beginning of keyword
    JP      -							;brif bit 7 clear
    DCR     E							;decrement rebased token value
    JNZ		-
    ANI     7FH							;01111111 clear bit 7
; copy BASIC keyword to buffer
-	STAX    B							;copy char to INPBUF_R
    INX     B							;next
    DCR     D							;token length
    JZ      L_POP_PSW_RET				;brif 0: pop PSW, ret
    MOV     A,M							;next char from code space
    INX     H							;next
    ORA     A							;find end of keyword
    JP		-							;brif bit 7 clear
    POP     H
    JMP     L_EXPND_BASIC_LN_2
;
; Copy from (DE) to (BE) until DE == [VARTAB_R]
;
; IN:
;	BC		destination ptr
;	HL		src ptr
;
L_COPY_TO_VARTAB:
    XCHG								;argument HL to DE
    LHLD    VARTAB_R					;Start of variable data pointer
-	LDAX    D
    STAX    B
    INX     B
    INX     D
    COMPAR								;Compare DE and [VARTAB_R]: HL - DE: HL - DE
    JNZ     -							;brif not equal
    MOV     H,B							;HL = BC
    MOV     L,C
    SHLD    VARTAB_R					;Start of variable data pointer
    SHLD    ARYTAB_R					;ptr to Start of array table
    SHLD    STRGEND_R					;Unused memory pointer
    RET
;
; PEEK function
;
R_PEEK_FUN:								;1284H
    CALL    L_CVT_TO_SIGNED_INT
    MOV     A,M
    JMP     L_LD_FAC1_BYTE				;Load byte iin A into FAC1
;
; POKE function
;
; POKE addr,byte-value
;
R_POKE_FUN:								;128BH
    CALL    R_EVAL_EXPR_2				;Evaluate expression at M_2: address
    PUSH    D							;save address
	SYNCHK	','
    CALL    L_GETBYT    				;Evaluate byte expression at M-1: byte value into A
    POP     D							;restore address
    STAX    D							;set memory
    RET
;
; Evaluate expression at M_2
;
;	Expect a 16-bit integer
;
; OUT:
;	DE		16-bit integer
;
R_EVAL_EXPR_2:							;1297H
    CALL    L_FRMEVL					;Main BASIC evaluation routine
    PUSH    H							;save text ptr
    CALL    L_CVT_TO_SIGNED_INT			;FAC1 to HL
    XCHG								;result to DE
    POP     H							;restore text ptr
    RET
;
;Convert last expression to integer (-32768 to 32767) or OV
;
L_CVT_TO_SIGNED_INT:
    LXI     B,R_CINT_FUN				;CINT function
    PUSH    B							;insert new return address
    LSTTYP								;Determine type of last var used: C Clr = DBL P Clr = SNGL Z Set = String S: Set = Integer
    RM									;retif INT type
    FSIGN								;Return 1 or -1 in A based on Sign bit of FAC1
    RM									;retif FAC1 negative
    CALL    R_CSNG_FUN					;CSNG function
    LXI     B,3245H						;Load BCDE with Single precision for 32768.0
    LXI     D,8076H
    CALL    R_SNGL_CMP_BCDE_FAC1		;Compare single precision in BCDE with FAC1
    RC
    LXI     B,6545H						;Load BCDE with Single precision for 65536.0
    LXI     D,6053H
    CALL    R_SNGL_CMP_BCDE_FAC1        ;Compare single precision in BCDE with FAC1
    JNC     R_GEN_OV_ERROR				;Generate OV error
    LXI     B,65C5H						;Load BCDE with Single precision for -65536.0
    LXI     D,6053H
    JMP     R_SNGL_ADD_BCDE				;Single precision addition (FAC1=FAC1+BCDE)
;
; Wait for key from keyboard. Special characters only?
;
; OUT:
;	A		key
;	carry	set if no key
;
R_WAIT_KEY:								;12CBH
    PUSH    H
    PUSH    D
    PUSH    B
    CALL    L_WAIT_KEY_1
    JMP     R_POP_ALL_WREGS
;
; Wait for key from keyboard - no reg PUSH
;
L_WAIT_KEY_1:
	RST38H	04H							;intercepted by VT100 code
;
; Process next byte of FKey text to "inject" the keys
;
    LHLD    FNKMAC_R					;Get pointer to FKey text (from FKey table) for selected FKey
    INR     H							;test H for 0
    DCR     H
    JZ      L_INJECT_KEYS				;Jump to process paste buffer injection if no FKey selected
    MOV     B,M							;Get next byte from selected FKey text
    MOV     A,B
    ORA     A
    JZ      L_WAIT_KEY_2				;brif (HL) == 0
    INX     H							;next
    MOV     A,M
    ORA     A
    JNZ     +							;brif (HL) != 0
L_WAIT_KEY_2:
    MOV     H,A							;Load zero into H to indicate FKey no longer active
+	SHLD    FNKMAC_R					;Store pointer to FKey text (from FKey table) for selected FKey
    MOV     A,B
    RET
;
; Process PASTE key from keyboard
;
L_PROCESS_PASTE:
    LDA     FNKMOD_R					;Function key mode/ BIT 7=in TEXT (0x80); BIT 6=in TELCOM (0x40)
    ADD     A							;bit 7 to carry
    RC  								;return if TEXT   
    LXI     H,0
    SHLD    PBUFIDX_R					;initialize Paste Buffer Index
    MVI     A,0DH
    STA     LSTPST_R					;Set last paste character to ENTER
;
; Process next byte from Paste buffer to "inject" the keystrokes
;
L_INJECT_KEYS:							;process paste buffer injection if no FKey selected
    LHLD    PBUFIDX_R					;Paste Buffer Index
    MOV     A,L							;test for 0FFFFH
    ANA     H
    INR     A
    JZ      L_NO_INJECT_KEYS			;brif PBUFIDX_R == 0FFFFH
    PUSH    H							;save PBUFIDX_R
    LDA     LSTPST_R					;Get value of last paste character
    CPI     0DH							;was it ENTER?
    CZ      LNKFIL						;Update line addresses for ALL BASIC programs if it was ENTER
    LHLD    HAYASHI_R+1					;Start of Paste Buffer
    POP     D							;PBUFIDX_R
    DAD     D							;&SCRDIR_R[PBUFIDX_R]
    MOV     A,M
    STA     LSTPST_R					;last Paste Buffer character
    MOV     B,A							;save
    CPI     1AH							;^Z?
    MVI     A,00H						;preload return value
    JZ      L_INSRT_FFFF
    CALL    R_CHK_PENDING_KEYS			;Check keyboard queue for pending characters
    JC      L_INSRT_FFFF				;brif pending character
    INX     H							;next Paste Buffer character
    MOV     A,M
    XCHG								;Paste Buffer ptr to DE
    INX     H							;PBUFIDX_R
    SHLD    PBUFIDX_R					;and save
    CPI     1AH							;^Z?
    MOV     A,B							;previous Paste Buffer character
    STC								;clear Carry
    CMC
    RNZ									;done if != ^Z
L_INSRT_FFFF:
    LXI     H,0FFFFH					;reset Paste Buffer Index
    SHLD    PBUFIDX_R
    RET

L_NO_INJECT_KEYS:
    CALL    R_CHK_KEY_QUEUE				;Check keyboard queue for pending characters
    JNZ     +							;brif char present
    CALL    L_CURSOR_ON					;Turn cursor on if not already during program pause
    MVI     A,0FFH
    STA     PWROFF_R					;Set Power off exit condition switch
-	CALL    R_CHK_KEY_QUEUE				;Check keyboard queue for pending characters
    JZ      -							;loop
    XRA     A
    STA     PWROFF_R					;Clear Power off exit condition switch
    CALL    L_CURSOR_OFF				;Turn cursor back off if it was off before
+	LXI     H,PWRDWN_R					;test Power Down Flag
    MOV     A,M
    ANA     A
    JNZ     L_POWER_OFF					;brif PWRDWN_R != 0
    CALL    R_KICK_PWR_OFF_WDT			;Renew automatic power-off counter
    CALL    R_SCAN_KEYBOARD				;Scan keyboard for special character (CTRL-BREAK ==> CTRL-C)
    RNC									;retif no special key
    SUI     PASTE_KEY					;Test for PASTE key
    JZ      L_PROCESS_PASTE				;brif PASTE_KEY: Process PASTE key (F11 on virtualt)
    JNC     L_RETURN_ZERO				;brif A > PASTE_KEY (0BH): return 0
; A (keyvalue - PASTE_KEY) now negative
    INR     A							;test for SHIFT-PRINT key
    JZ      L_INJECT_KEYS_3				;Jump to process special "Paste" of SHIFT-PRINT key sequence
    INR     A							;Test for PRINT key
    JZ      R_LCOPY_STMT				;LCOPY statement (F10 on virtualt)
    INR     A							;Test for LABEL key
    JZ      R_TOGGLE_LABEL				;Toggle function key label line (F9 on virtualt)
; A = (keyvalue - 0BH + 3) < 0
; F1..F8 = -8..-1
    MOV     E,A							;save negative Function keyvalue
    LDA     FNKMOD_R					;Function key mode/ BIT 7=in TEXT (0x80); BIT 6=in TELCOM (0x40)
    ADD     A							;move bit 6 (TELCOM) to carry
    ADD     A
    MOV     A,E							;restore incremented key value
    RC									;done if TELCOM
    MVI     D,0FFH						;sign extend Function keyvalue to DE
;
; This is calculating the FKey table entry in FNKMAC_R
; FNKSTR_R is an area of 8 keyvalue strings, each 16 bytes long
; A contains function keyvalue -8..-1 (F1..F8)
;
    XCHG								;Function keyvalue to HL				
    DAD     H							;x2
    DAD     H							;x4
    DAD     H							;x8
    DAD     H							;x16
    LXI     D,FNKSTR_R+128				;ptr beyond end of function keyvalue strings
    DAD     D							;HL is negative offset
    LDA     FNKMOD_R					;Function key mode/ BIT 7=in TEXT (0x80); BIT 6=in TELCOM (0x40)
    ANA     A
    JP      L_INJECT_KEYS_2				;brif !TEXT
    INX     H							;HL += 4
    INX     H
    INX     H
    INX     H
L_INJECT_KEYS_2:
	SHLD    FNKMAC_R					;Save pointer to FKey text (from FKey table) for selected FKey
    JMP     L_WAIT_KEY_1				;start returning the function keyvalue string

L_INJECT_KEYS_3:
    LHLD    SHFTPRNT_R
    JMP     L_INJECT_KEYS_2
;
; Toggle function key label line, if enabled
;
R_TOGGLE_LABEL:							;13A5H
    LDA     LINENA_R					;Label line enable flag
    ANA     A
    RZ									;return if label line not enabled
    LDA     LINPROT_R					;Label line protect status
    XRI     0FFH						;flip status
L_SET_LABEL_LINE:
    JZ      R_ERASE_FKEY_DISP			;Erase function key display if now OFF
    JMP     R_DISP_FKEY_LINE			;ON: Display function key line
;
; PWRDWN_R == 0FFH => Power Off
;
; IN:
;	HL points to PWRDWN_R
;
L_POWER_OFF:
    DI 
    MVI     M,00H						;clear Power Down Flag
    LDA     TIMDWN_R					;POWER down time (1/10ths of a minute)
    DCX     H							;Point to power-down count-down
    MOV     M,A							;Update power-down count-down for next power-up
    CALL    R_POWER_DOWN				;Turn off computer
L_RETURN_ZERO:
    XRA     A
    RET

; 
; Turn cursor on if not already during program pause
; 
L_CURSOR_ON:
    LDA     CURSTAT_R					;Cursor status (0 = off)
    STA     OLDCURSTAT_R				;Storage if cursor was on before BASIC CTRL-S
    ANA     A
    RNZ
    CALL    R_TURN_CURSOR_ON			;Turn the cursor on
    JMP     R_SEND_ESC_X				;Send ESC X

; 
; Turn cursor back off after BASIC "un-pause" if it was off before
; 
L_CURSOR_OFF:
    LDA     OLDCURSTAT_R				;Storage if cursor was on before BASIC CTRL-S
    ANA     A
    RNZ
    CALL    R_TURN_CURSOR_OFF			;Turn the cursor off
    JMP     R_SEND_ESC_X				;Send ESC X
;
; Check keyboard queue for pending characters
;
R_CHK_KEY_QUEUE:						;13DBH
    LDA     FNKMAC_R+1					;MSB of FNKMAC_R ptr
    ANA     A
    RNZ									;retif FNKMAC_R+1 != 0
    LDA     PWRDWN_R					;Power Down Flag
    ANA     A
    RNZ									;retif PWRDWN_R != 0
    PUSH    H
    LHLD    PBUFIDX_R					;Paste Buffer Index
    MOV     A,L
    ANA     H
    INR     A
    POP     H
    RNZ									;return if PBUFIDX_R != 0FFFFH    
	RST38H	06H
    JMP     R_CHK_PENDING_KEYS          ;Check keyboard queue for pending characters
;
; Test for CTRL-C or CTRL-S during BASIC Execute
;
L_CHK_KEY_CTRL:
    CALL    R_CHK_BREAK				  	;Check for break or wait (CTRL-S)
    RZ									;No
    CPI     03H							;^C
    JZ      +							;brif TRUE
    CPI     13H							;^S
    RNZ									;NO
    CALL    L_CURSOR_ON					;Turn cursor on if not already during program pause
;$$LOOP:
-	CALL    R_CHK_BREAK				    ;Check for break or wait (CTRL-S)
    CPI     13H							;^S
    JZ      L_CURSOR_OFF						;brif TRUE to restore cursor
    CPI     03H							;^C
    JNZ     -							;$$LOOP brif FALSE
    CALL    L_CURSOR_OFF						;restore cursor
+	XRA     A
    STA     KBCNT_R						;Keyboard buffer count
    JMP     R_STOP_STMT				    ;STOP statement
;
; POWER statement
;
R_POWER_STMT:							;1419H
    SUI     _CONT						;0A4H CONT token
    JZ      R_POWER_CONT_STMT			;POWER CONT statement: disable automatic shutdown
    CPI     _OFF-_CONT					;0CBH-0A4H = 27H: _OFF token
    JNZ     R_POWER_ON_STMT				;POWER ON statement
    CHRGET								;Get next non-white char from M
    JZ      R_POWER_DOWN_NOSTATE		;brif done: Turn off computer
	SYNCHK	','
	SYNCHK	_RESUME						;RESUME token
    JNZ     R_GEN_SN_ERROR				;Generate Syntax error
    JMP     R_POWER_DOWN				;Turn off computer, preserving state
;
; Normal TRAP (low power) interrupt routine
;
R_LOW_PWR_TRAP:							;1431H
    PUSH    PSW
    LDA     PWROFF_R					;Power off exit condition switch
    ANA     A
    MVI     A,01H
    STA     PWROFF_R					;Power off exit condition switch
    JNZ     R_POWER_DOWN_NOSTATE		;brif PWROFF_R != 0
    POP     PSW
;
; Turn off computer - preserve system state to stack
;
R_POWER_DOWN:							;143FH
    DI 
    PUSH    H
    PUSH    D
    PUSH    B
    PUSH    PSW
    LXI     H,0
    DAD     SP							;SP to HL
    SHLD    POWRSP_R					;SP save area for power up/down
    LXI     H,AUTOPWRDWN				;Load Auto PowerDown signature
    SHLD    AUTPWR_R					;Save Auto PowerDown signature
R_POWER_DOWN_NOSTATE:
    DI 
    INPORT	0BAH						;read 8155 PIO Port B
    ORI     10H							;set the PowerDown bit
    OUTPORT	0BAH						;bye bye
    HLT    
;
; POWER CONT statement
;
; IN:
;	A == 0
;
R_POWER_CONT_STMT:						;1459H
    CALL    L_POWER_ON_STMT_1			;clear TIMDWN_R & PWRCNT_R
    STA     PWRDWN_R					;clear Power Down Flag
    CHRGET								;Get next non-white char from M
    RET
;
; POWER ON statement: POWER ON num 10 <= num <= 255
; num == 6 seconds
;
R_POWER_ON_STMT:						;1461H
    CALL    L_GETBYT					;Evaluate byte expression at M-1
    CPI     0AH							;minimum 10
    JC      R_GEN_FC_ERROR				;Generate FC error
L_POWER_ON_STMT_1:
    STA     TIMDWN_R					;POWER down time (1/10ths of a minute)
    STA     PWRCNT_R
    RET
;
; Output character to printer
;
R_OUT_CH_TO_LPT:						;1470H
	RST38H	0AH
    CALL    R_SEND_A_TO_LPT				;Send character in A to the printer
    JNC     +
    XRA     A
    STA     LPT_MOVING_R				;clear
    JMP     R_GEN_IO_ERROR				;Generate I/O error
+	PUSH    PSW
    MVI     A,0FFH
    STA     LPT_MOVING_R				;set
    CALL    R_KICK_PWR_OFF_WDT       	;Renew automatic power-off counter
    POP     PSW
    RET
;
; Start tape and load tape header
;
R_LOAD_CAS_HDR:							;148AH
    CALL    R_CAS_MOTOR_ON				;Turn cassette motor on
    CALL    R_CAS_READ_HEADER			;Read cassette header and sync byte
    RNC
L_CAS_IO_ERROR:
    CALL    R_CAS_MOTOR_OFF				;Turn cassette motor off
;
; Generate I/O error
;
R_GEN_IO_ERROR:							;1494H
    MVI     E,12H
    JMP     R_GEN_ERR_IN_E				;Generate error in E
;
; Turn cassette motor on and write sync header
;
R_DET_CAS_SYNC_HDR:								;1499H
    CALL    R_CAS_MOTOR_ON				;Turn cassette motor on
    LXI     B,0							;wait loop
-	DCX     B							;test BC
    MOV     A,B
    ORA     C
    JNZ     -
    JMP     R_CAS_WRITE_HEADER       	;Write cassette header and sync byte
;
; Turn cassette motor on
;
R_CAS_MOTOR_ON:							;14A8H
    DI 
	SKIP_2INSTS							;skip EI & MVI E,00H
;
; Turn cassette motor off
;
R_CAS_MOTOR_OFF:						;14AAH
    EI     
    MVI     E,00H
    JMP     R_CAS_REMOTE_FUN			;Cassette REMOTE routine - turn motor on or off
;
; Read byte from tape & update checksum
;
R_CAS_READ_BYTE:						;14B0H
    PUSH    D
    PUSH    H
    PUSH    B
    CALL    R_CAS_READ_NO_CHKSUM       	;Read character from cassette w/o checksum
    JC      L_CAS_IO_ERROR
    MOV     A,D
    POP     B
    ADD     C
    MOV     C,A
    MOV     A,D
    POP     H
    POP     D
    RET
;
; Write byte to tape & update checksum
;
R_CAS_WRITE_BYTE:						;14C1H
    PUSH    D
    PUSH    H
    MOV     D,A
    ADD     C
    MOV     C,A
    PUSH    B
    MOV     A,D
    CALL    R_CAS_WRITE_NO_SYNC      	;Write char in A to cassette w/o checksum
    JC      L_CAS_IO_ERROR
    POP     B
    POP     H
    POP     D
    RET
;
; LCD Device control block
;
R_LCD_DCB:								;14D2H
    DW      R_LCD_OPEN, R_LCD_CLOSE_FUN, R_LCD_OUT
;
; LCD and PRT file open routine
;
; IN:
;	E			File Status
;	HL			FCB ptr
;
;	PSW and HL on stack
;
;
R_LCD_OPEN:								;14D8H
    MVI     A,02H						;Output mode
    CMP     E
    JNZ     R_GEN_NM_ERR_FUN			;Generate NM error (Bad Filename)
L_FINALIZE_FCB:
    SHLD    FCBLAST_R					;FCB ptr for the last file used (2 bytes)
    MOV     M,E							;update File Open Mode 
    POP     PSW							;restore function code
    POP     H							;restore txt ptr
    RET
;
; Output to LCD file
;
R_LCD_OUT:								;14E5H
    POP     PSW							;get char to write
    PUSH    PSW
    CALL    R_CHAR_PLOT
L_PWR_POP_ALL:
    CALL    R_KICK_PWR_OFF_WDT       	;Renew automatic power-off counter
;
; Pop AF), BC), DE), HL from stack
;
R_POP_ALL_REGS:							;14EDH
    POP     PSW
R_POP_ALL_WREGS:
    POP     B
    POP     D
    POP     H
    RET
;
; CRT device control block
;
R_CRT_DCB:								 ;14F2H
    DW      R_CRT_OPEN, R_LCD_CLOSE_FUN, R_CRT_OUT

R_CRT_OPEN:
	RST38H	40H
R_CRT_OUT:
	RST38H	44H
;
; RAM device control block
;
R_RAM_DCB:								;14FCH
    DW      R_RAM_OPEN, R_RAM_CLOSE, R_RAM_OUT
    DW      R_RAM_IN, R_RAM_IO
;
; Open RAM file
;
; BC, DE, HL pushed on stack
;
; IN:
;	D		DCB code
;	E		File open Mode (1 input, 2 output, 8 append)
;	HL		FCB ptr
;
R_RAM_OPEN:								;1506H
    PUSH    H
    PUSH    D
    INX     H							;point to Directory Entry			
    INX     H
    PUSH    H							;push ptr to Directory Entry Ptr
    MOV     A,E							;open mode code
    CPI     01H							;input
    JZ      L_RAM_OPEN_MODE1
    CPI     08H							;append mode
    JZ      L_RAM_OPEN_MODE8
; File open Mode 2: output
L_RAM_OPEN_MODE2:
    CALL    R_OPEN_TXT_FILE_OUTPUT		;Open a text file at FILNAM_R. DE is Directory ptr
    JC      L_RAM_EXISTS				;brif File already exists: delete if possible
    PUSH    D							;save DE
    CALL    L_UPD_FOR_LOOPS				;update FOR loops stack chain with offset 1 (^Z)
    POP     D							;restore Directory Entry ptr to DE
;
; set relative position in file.
; Directory Entry ptr in DE
; FCB ptr on stack
;
L_SET_START_OF_FILE:
    LXI     B,0							;start of file
L_SET_END_OF_FILE:						;entry point with BC == file length (append mode)
    POP     H							;restore FCB ptr to HL
    LDAX    D							;File Directory Entry -> File Type
    ANI     02H							;00000010 isolate bit 1
    JNZ     R_GEN_AO_ERR_FUN			;brif != 0: Generate Already Open error
    LDAX    D							;reload File Type
    ORI     02H							;set bit 1: File is open
    STAX    D							;update File Type
    INX     D							;ptr to File Data Ptr
    MOV     M,E							;store in FCB
    INX     H
    MOV     M,D
    INX     H							;advance to offset from Buffer Start
    INX     H
    INX     H
    MVI     M,00H						;set offset to 0
    INX     H							;advance to relative position in file
    MOV     M,C							;set to BC value
    INX     H
    MOV     M,B
    POP     D							;restore Device/Open Mode
    POP     H							;restore FCB
    JMP     L_FINALIZE_FCB				;update FCBLAST_R and clean stack
;
; Jumped to from R_RAM_OPEN. Ptr to Directory Entry Ptr on stack
; Open file mode == 1: input
;
L_RAM_OPEN_MODE1:
    LDA     EDITFLG_R					;test
    ANA     A
    LXI     H,RICKY_R					;Ricky part of directory
    CZ      R_FINDFILE					;calif EDITFLG_R == 0
    JZ      R_GEN_FF_ERR_FUN			;brif not found: Generate FF error
    XCHG
    CALL    R_GET_FILESTAT				;Get ptr to BASIC File Status
    XRA     A							
    MOV     M,A							;set File status to closed
    MOV     L,A							;clear HL
    MOV     H,A
    SHLD    XXSTRT_R					;clear XXSTRT_R
    JMP     L_SET_START_OF_FILE
;
; Jumped to from R_RAM_OPEN. Ptr to Directory Entry Ptr on stack
; Function code == 8: append 
;
L_RAM_OPEN_MODE8:
    POP     H
    POP     D
    MVI     E,02H
    PUSH    D
    PUSH    H
    CALL    LNKFIL						;Fix up the directory start pointers
    CALL    R_FINDFILE
    JZ      L_RAM_OPEN_MODE2			;brif not found. Open new file
    MOV     E,L							;save Directory Entry in DE
    MOV     D,H
    INX     H							;get ptr to File Data in HL
    MOV     A,M
    INX     H
    MOV     H,M
    MOV     L,A
    LXI     B,0FFFFH					;predecrement file length
; compute file count
-	MOV     A,M
    INX     H
    INX     B
    CPI     1AH							;^Z
    JNZ     -
    JMP     L_SET_END_OF_FILE			;BC has file length
;
; Opening a file for output but file already exists
; DE is Directory Ptr
;
L_RAM_EXISTS:
    LDAX    D							;get Filetype
    ANI     02H							;00000010 isolate bit 1. File open for DO files
    JNZ     R_GEN_AO_ERR_FUN			;brif set: Generate Already Open error
    XCHG								;Directory Ptr to HL
    CALL    KILASC						;kill existing text file:  DE & HL are inputs
    JMP     L_RAM_OPEN_MODE2			;continue
;
; Close RAM file
;
; IN:
;	HL		FCB ptr
;
R_RAM_CLOSE:							;158DH
    PUSH    H							;save FCB ptr
    CALL    L_DIRECTORY_CLOSE			;mark directory entry as closed
    POP     H							;restore FCB ptr
    CALL    L_CHK_FCB_DATA				;check offset in File Buffer
    CNZ     L_WRT_FCB_DATA				;write buffer if data present
    CALL    R_GET_FILESTAT				;Get ptr to BASIC File Status
    MVI     M,00H						;set File Status "not open"
    JMP     R_LCD_CLOSE_FUN				;LCD), CRT), and LPT file close routine

L_DIRECTORY_CLOSE:
    INX     H							;ptr to File Directory Entry address
    INX     H
    MOV     A,M							;get File Directory Entry address
    INX     H
    MOV     H,M
    MOV     L,A
    DCX     H							;File Directory Entry type
    MOV     A,M							;clear bit 1
    ANI     0FDH						;11111101
    MOV     M,A
    RET
;
; Output to RAM file
;
R_RAM_OUT:								;15ACH
    POP     PSW
    PUSH    PSW
    LXI     B,L_PWR_POP_ALL				;pop ALL registers function
    PUSH    B
    ANA     A
    RZ									;to Pop ALL
    CPI     1AH							;^Z
    RZ									;to Pop ALL
    CPI     7FH							;DEL
    RZ									;to Pop ALL
    CALL    L_WRITE_TO_DEVICE
    RNZ									;retif buffer not full (offset != 0)
    LXI     B,0100H						;256.
    JMP     L_WRT_FCB_DATA				;write FCB buffer if offset == 0
;
; Input from RAM file
;
; BC, DE, HL pushed on stack.
;	NOTE: registers are not restored in that order
;
; IN:
;	HL		FCB ptr
;
R_RAM_IN:								;15C4H
    XCHG
    CALL    R_GET_FILESTAT				;Get ptr to BASIC File Status
    CALL    L_TSTFILSTAT
    XCHG								;ptr to BASIC File Status to DE
    CALL    L_GET_FILEDATA_PTR			;Returns current offset in A, buffer ptr in HL
    JNZ     L_RAM_IN_1					;brif offset != 0
; current offset == 0. Read new FCB data buffer
    XCHG								;buffer ptr to DE
    LHLD    FCB1_BUF_R					;ptr to buffer first file
    COMPAR								;HL - DE
    PUSH    PSW							;save COMPAR result
    PUSH    D							;save buffer ptr
    CNZ     LNKFIL						;Fix up the directory start pointers
    POP     H							;restore buffer ptr (was DE)
    POP     PSW							;restore COMPAR result
    LXI     B,-(BUFFER_IN_FCB_OFS - DIR_IN_FCB_OFS) ;0FFF9H
    DAD     B							;HL ptr to File Directory Entry ptr
	GETDEFROMMNOINC						;DE = File Directory Entry ptr
    XCHG								;File Directory Entry ptr +1 to HL. FCB ptr to DE
	GETHLFROMM							;get File Data ptr to HL
    JNZ     +							;COMPAR result
    PUSH    D							;save FCB ptr (DIR_IN_FCB_OFS + 1)
    XCHG
    LHLD    XXSTRT_R					;[XXSTRT_R] to DE
    XCHG
    DAD     D							;add [XXSTRT_R] to HL
    POP     D							;restore FCB ptr (DIR_IN_FCB_OFS + 1)
+	XCHG								;FCB ptr (DIR_IN_FCB_OFS + 1) to HL
    INX     H							;HL += 4 => FILPOS_IN_FCB_OFS
    INX     H
    INX     H
    INX     H
    MOV     C,M							;get File Position Offset from M to BC
    INX     H							;to FILPOS_IN_FCB_OFS+1
    MOV     B,M
    INR     M							;increment M: File Position offset += 256
    INX     H							;to &BUFFER_IN_FCB_OFS
    XCHG								;save HL to DE (destination). Old DE is source				
    DAD     B							;index to &BUFFER_IN_FCB_OFS[FILPOS_IN_FCB_OFS]
    MVI     B,00H						;256 count
    CALL    R_MOVE_B_BYTES				;Move B bytes from M to (DE). Updates DE, HL, B==0
    XCHG
    DCR     H							;HL -= 256
    XRA     A
L_RAM_IN_1:
    MOV     C,A							;current offset to BC
    DAD     B							;assume B was 0
    MOV     A,M							;get byte from file
    CPI     1AH							;test for EOF
    STC									;preset clear Carry
    CMC
    JNZ     L_POPDHBREGS				;brif not EOF, carry clear, return file byte
    CALL    R_GET_FILESTAT				;Get ptr to BASIC File Status
    MOV     M,A							;set File Status to 1AH
    STC
    JMP     L_POPDHBREGS				;Pops DE, HL, BC from stack and return
;
; Special RAM file I/O
;
R_RAM_IO:								;161BH
    CALL    R_GET_FILESTAT				;Get ptr to BASIC File Status
    JMP     L_COM_IO_1
;
; write FCB buffer if offset != 0
; IN:
;	B		count
;	HL		ptr to FCB DATA
;
L_WRT_FCB_DATA:
    PUSH    H							;save FCB Data Ptr
    PUSH    B							;save count
    PUSH    H							;save data ptr
    XCHG								;data ptr to DE
    LHLD    FCB1_BUF_R					;ptr to buffer first file
    COMPAR								;Compare data ptr and FCB1_BUF_R: HL - DE
    CNZ     LNKFIL						;Fix up the directory start pointers
    POP     H							;restore data ptr
    DCX     H							;ptr to File Position MSB into HL
    MOV     D,M							;File Position to HL
    DCX     H
    MOV     E,M
    XCHG
    POP     B							;retrieve count
    PUSH    B
    PUSH    H							;save Relative File Position
    DAD     B							;new EOF position
    XCHG								;EOF position to DE, FILPOS_IN_FCB_OFS ptr to HL
    MOV     M,E							;update new EOF position
    INX     H
    MOV     M,D
    LXI     B,0FFFAH					;-6
    DAD     B							;HL ptr to DIR_IN_FCB_OFS
	GETDEFROMMNOINC						;get ptr to File Data Ptr to DE (from Directory Entry)
    LDAX    D							;File Data Ptr to HL
    MOV     L,A
    INX     D
    LDAX    D
    MOV     H,A
    POP     B							;restore Relative File Position
    DAD     B							;Add to File Data Ptr
    POP     B							;restore count
    PUSH    H							;save absolute File Data ptr
    PUSH    B							;save count
    CALL    MAKHOL						;Insert BC spaces at M
    CNC     L_UPD_FOR_LOOPS_1			;update FOR loop stack chain. BC is offset to add
    POP     B							;restore count
    POP     D							;absolute File Data ptr to DE
    POP     H							;restore FCB Data Ptr
    JC      L_WRT_FCB_NOMEM				;brif Out of Memory
    PUSH    H							;save File Data ptr
;copy C bytes from FCB Data to File Data
-	MOV     A,M
    STAX    D
    INX     D
    INX     H
    DCR     C
    JNZ     -
    POP     D							;restore File Data ptr
    LHLD    FCB1_BUF_R					;ptr to buffer first file
    COMPAR								;HL - DE
    RZ
    JMP     LNKFIL						;Fix up the directory start pointers
;
; Out of Memory Condition
;
L_WRT_FCB_NOMEM:
    LXI     B,0FFF7H					;-9
    DAD     B
    MVI     M,00H
    CALL    L_DIRECTORY_CLOSE
    JMP     L_OUTOFMEMORY
;
; Get ptr to BASIC File Status
;
; OUT:
;	HL	ptr to BASIC File Status
;
R_GET_FILESTAT:							;1675H
    PUSH    D							;save
    LHLD    FILNUM_R					;zero extended validated file number
    LXI     D,FILSTATTBL_R				;BASIC File Status
    DAD     D							;index
    POP     D							;restore
    RET
;
; CAS device control block
;
R_CAS_DCB:								       	;167FH
    DW      R_CAS_OPEN, R_CAS_CLOSE, R_CAS_OUT
    DW      R_CAS_IN, R_CAS_IO
;
; Open CAS file
;
; IN:
;	HL
;	E		input or output selection
;
R_CAS_OPEN:								;1689H
    PUSH    H							;save FCB ptr
    PUSH    D							;save open mode
    LXI     B,0006H						;offset 6
    DAD     B							;index
    XRA     A
    MOV     M,A							;clear (HL+6)
    STA     CASFILSTAT_R				;clear CASFILSTAT_R
    MOV     A,E							;function requested
    CPI     DCBIO_FUN					;8
    JZ      R_GEN_NM_ERR_FUN			;brif DCBIO_FUN: Generate NM error
    CPI     01H
    JZ      +							;brif input function
    CALL    R_CAS_OPEN_OUT_DO			;Open CAS for output of TEXT files
-	POP     D							;restore Open Mode
    POP     H							;restore FCB ptr
    JMP     L_FINALIZE_FCB				;update FCBLAST_R and clean stack

+	CALL    R_CAS_OPEN_IN_DO			;Open CAS for input of TEXT files
    JMP     -

;
; Close CAS file
;
R_CAS_CLOSE:							;16ADH
    CALL    L_CHK_FCB_DATA				;check offset in File Buffer
    JZ      +							;brif no data present
; Fill remainder of buffer with ^Z
    PUSH    H							;save FCB data ptr
    DAD     B							;index
-	MVI     M,1AH						;^Z
    INX     H
    INR     C							;increment until overflow
    JNZ     -
    POP     H							;restore FCB data ptr
    CALL    L_WRT_CAS_BLK
+	XRA     A
    STA     CASFILSTAT_R				;clear CASFILSTAT_R
    JMP     R_LCD_CLOSE_FUN				;LCD), CRT), and LPT file close routine
;
; Output to CAS file
;
R_CAS_OUT:								;16C7H
    POP     PSW							;retrieve data byte
    PUSH    PSW
    CALL    L_WRITE_TO_DEVICE
    CZ      L_WRT_CAS_BLK				;calif buffer full
    JMP     L_PWR_POP_ALL				;pop ALL registers function
;
; Input from CAS file
;
; BC, DE, HL pushed on stack
;
;
R_CAS_IN:								;16D2H
    XCHG								;HL to DE
    LXI     H,CASFILSTAT_R
    CALL    L_TSTFILSTAT
    XCHG
    CALL    L_GET_FILEDATA_PTR			;Returns current offset in A
    JNZ     +							;brif current offset != 0
; current offset in buffer is 0: read new data into buffer
    PUSH    H							;save buffer ptr
    CALL    L_FND_CAS_DATA_BLK
    POP     H							;restore buffer ptr
    LXI     B,0							;256 count
-	CALL    R_CAS_READ_BYTE				;Read byte from tape & update checksum
    MOV     M,A							;update buffer
    INX     H							;next
    DCR     B
    JNZ     -							;brif not done reading buffer
    CALL    R_CAS_READ_BYTE				;Read byte from tape & update checksum
    MOV     A,C
    ANA     A
    JNZ     L_CAS_IO_ERROR
; C == 0
    CALL    R_CAS_MOTOR_OFF				;Turn cassette motor off
    DCR     H							;point to start of buffer (-256)
    XRA     A
    MOV     B,A							;clear B
+	MOV     C,A							;BC = current offset in buffer
    DAD     B							;index into buffer ptr
    MOV     A,M							;get data byte
    CPI     1AH							;test for EOF
    STC									;preload clear carry
    CMC
    JNZ     L_POPDHBREGS				;brif not EOF: Pops DE, HL, BC from stack and return
    STA     CASFILSTAT_R				;move EOF into CASFILSTAT_R
    STC									;set carry
    JMP     L_POPDHBREGS				;Pops DE, HL, BC from stack and return

R_CAS_IO:
    LXI     H,CASFILSTAT_R
    JMP     L_COM_IO_1
;
; Write Buffer for a cassette device file
;
; IN:
;	HL		ptr to buffer
;
L_WRT_CAS_BLK:
    PUSH    H							;save buffer ptr
    CALL    L_PREP_DATA_BLK				;prepare cassette sync header
    POP     H							;restore buffer ptr
    LXI     B,0							;256 count to B. C==0
-	MOV     A,M
    CALL    R_CAS_WRITE_BYTE			;Write byte to tape & update checksum
    INX     H
    DCR     B							;count
    JNZ     -							;brif count != 0
    JMP     L_CAS_FIN_BLK				;finish cassette block
;
; check offset in File Buffer
;
; IN:
;	HL		FCB ptr
;
; OUT:
;	HL		Start of 256 byte buffer for data transfer
;	BC		Offset from buffer start for start of next record
;	Z		set if cannot write or [BUFOFS_IN_FCB]==0, meaning no data in buffer
;
L_CHK_FCB_DATA:
    MOV     A,M							;FCB status
    CPI     01H							;is it "Open for Input"
    RZ									;retif true: cannot write
    LXI     B,BUFOFS_IN_FCB_OFS			;Offset from buffer start for start of next record
    DAD     B							;index to offset
    MOV     A,M							;get offset to C
    MOV     C,A							;B == 0
    MVI     M,00H						;clear offset> TODO could do MOV M,B
    JMP     L_FILEDATA_ADV				;advance to Start of 256 byte buffer for data transfer and test A
;
; L_WRITE_TO_DEVICE: Write byte in A to file
;
; IN:
;	A			data byte
;	HL			FCB ptr
;
; OUT:
;	HL			ptr to file buffer ptr
;	Z			set if offset overflowed to 0
;
L_WRITE_TO_DEVICE:
    MOV     E,A							;save A
    LXI     B,BUFOFS_IN_FCB_OFS			;Offset from buffer start for start of next record
    DAD     B							;index
    MOV     A,M							;get current offset
    INR     M							;increment offset. Sets Z flag
    INX     H							;advance to Start of 256 byte buffer for data transfer
    INX     H
    INX     H
    PUSH    H							;save buffer ptr
    MOV     C,A							;current offset to BC
    DAD     B							;index into buffer
    MOV     M,E							;write to file`
    POP     H							;restore buffer ptr
    RET
;
; L_GET_FILEDATA_PTR:
; Get ptr to current position in File Buffer
; increment current offset
;
; IN:
;	HL			FCB ptr
;
; OUT:
;	A			current offset into File Buffer
;	B			0
;	HL			ptr to File Buffer
;	Z			if current offset in 256 File Buffer is 0
;
L_GET_FILEDATA_PTR:
    LXI     B,BUFOFS_IN_FCB_OFS			;Offset from buffer start for start of next record
    DAD     B							;index to offset
    MOV     A,M							;get current offset
    INR     M							;increment offset
L_FILEDATA_ADV:							;shared tail. A	== Current offset into 256 byte buffer
    INX     H							;advance to Start of 256 byte buffer for data transfer
    INX     H
    INX     H
    ANA     A							;test current offset
    RET
;
; LPT device control block
;
R_LPT_DCB:								;1754H
    DW      R_LCD_OPEN, R_LCD_CLOSE_FUN, R_LPT_OUT
;
; Output to LPT file
;
R_LPT_OUT:								;175AH
    POP     PSW
    PUSH    PSW
    CALL    R_PRINT_A_EXPAND			;Print A to printer), expanding tabs if necessary
    JMP     L_PWR_POP_ALL				;pop ALL registers function
;
; COM device control block
;
R_COM_DCB:								;1762H
    DW      R_COM_OPEN, R_COM_CLOSE, R_COM_OUT
    DW      R_COM_IN, R_COM_IO
;
; Open MDM file
;
; IN:
;	carry		clear
;
R_MDM_OPEN:								;176CH
	SKIP_XRA_A							;actually STC
;
; Open COM file. Supports both MDM and Serial port
;
R_COM_OPEN:								;176DH
    STC									;set carry: use RS232 port
    PUSH    PSW							;save carry
    CC      R_DISCONNECT_PHONE       	;Disconnect phone line and disable modem carrier
    POP     PSW							;restore carry
    PUSH    PSW
    PUSH    H							;save FCB ptr
    PUSH    D							;save Open Mode
    LXI     H,FILNAM_R					;Current Filename
    CALL    R_SET_RS232_PARAMS       	;Set RS232 parameters from string at M
    POP     D							;restore Open Mode
    MOV     A,E							;get File Open Mode
    CPI     08H							;append
    JZ      R_GEN_NM_ERR_FUN			;brif append mode: Generate NM error (Bad File Name)
    SUI     01H							;input
    JNZ     +							;brif not input: must be output
; A == 0
    STA     FILSTAT_R					;save File Open Mode
+	POP     H							;restore FCB ptr
    POP     PSW							;restore carry
	if		HWMODEM
    JC      L_FINALIZE_FCB				;brif Serial port: update FCBLAST_R and clean stack.
; E is File Open Mode
    CALL    R_GO_OFFHOOK_WAIT			;Go off-hook and wait for carrier
    JC      R_GEN_IO_ERROR				;Generate I/O error
    MVI     A,02H
    CALL    L_PAUSE						;pause
    JMP     L_FINALIZE_FCB				;update FCBLAST_R and clean stack. E is File Open Mode
	else								;HWMODEM
    JMP     L_FINALIZE_FCB				;update FCBLAST_R and clean stack. E is File Open Mode
	DS		14							;14 bytes FREE CODE SPACE if !HWMODEM
	endif								;HWMODEM
;
; Close COM file
;
R_COM_CLOSE:							;179EH
    CALL    R_UNINIT_RS232_MDM       	;Deactivate RS232 or modem
    XRA     A
    STA     FILSTAT_R					;clear File Status
    JMP     R_LCD_CLOSE_FUN				;LCD), CRT), and LPT file close routine
;
; Output to COM/MDM file
;
R_COM_OUT:								;17A8H
    POP     PSW
    PUSH    PSW
    CALL    R_SEND_A_USING_XON       	;Send character in A to serial port using XON/XOFF
    JMP     L_PWR_POP_ALL				;pop ALL registers function
;
; Input from COM/MDM file
;
; BC, DE, HL pushed on stack
;
; Word registers and ultimate return address on Stack
;
;
R_COM_IN:								;17B0H
    LXI     H,FILSTAT_R
    CALL    L_TSTFILSTAT
    CALL    R_READ_RS232_QUEUE       	;Get a character from RS232 receive queue
    JC      R_GEN_IO_ERROR				;Generate I/O error
    CPI     1AH							;^Z
    STC									;clear Carry
    CMC
    JNZ     L_POPDHBREGS				;brif not ^Z: Pops DE, HL, BC from stack and return
    STA     FILSTAT_R					;store 1AH in File Status
    STC
    JMP     L_POPDHBREGS				;Pops DE, HL, BC from stack and return
;
; Special COM/MDM file I/O
;
; IN:
;	C		Status byte
;
R_COM_IO:								;17CAH
    LXI     H,FILSTAT_R
L_COM_IO_1:
    MOV     M,C
    JMP     L_LINE_IN_6
;
; MDM Device control block
;
R_MDM_DCB:								;17D1H
    DW      R_MDM_OPEN, R_MDM_CLOSE, R_COM_OUT
    DW      R_COM_IN, R_COM_IO
;
; Close MDM file
;
R_MDM_CLOSE:							;17DBH
	if		HWMODEM
    MVI     A,02H
    CALL    L_PAUSE						;pause
    CALL    R_DISCONNECT_PHONE       	;Disconnect phone line and disable modem carrier
	else
	DB		0,0,0,0,0,0,0,0				;8 bytes free if !HWMODEM
	endif
    JMP     R_COM_CLOSE				    ;Close COM file
;
; Set RS232 parameters from string at M
; IN: carry means RS232, else MODEM; no baud rate if MODEM
;
R_SET_RS232_PARAMS:				    	;17E6H
    PUSH    PSW							;save carry
    LXI     B,R_GEN_NM_ERR_FUN			;error exit
    PUSH    B
    JNC		+							;brif modem
    MOV     A,M
    SUI     '1'
    CPI     09H
    RNC									;digit > '9'
    INR     A							;base 1
    MOV     D,A							;save baud rate 1..9
    INX     H
+	MOV     A,M
    SUI     '6'
    CPI     03H
    RNC									;error: digit > '8'
	INR     A							;base 1
    ADD     A							;times 8 ->
    ADD     A							;08H, 10H, 18H
    ADD     A
    MOV     E,A							;save word length in E, bits 3,4
    INX     H
    CALL    R_CONV_M_TOUPPER		  	;Get char at M and convert to uppercase
    CPI     'I'							;49H
    JNZ     L_SET_PARITY				;brif !'I'
    MOV     A,E							;word length
    CPI     18H							;8 bits word length
    RZ									;error: word length == 8 bits + ignore parity
;
; only 08H and 10H possible -> 14H, 1CH: change to 7,8 bits word length plus set 'N' parity.
; AND 08H -> 00H, 08H SHL 3 -> 00H, 40H OR 3FH -> 3FH, 7FH Serial Ignore Parity Mask byte
; 'I' parity changed to 'N' parity with 1 extra data bit. Sender will send an extra parity bit
; but the extra bit will be ignored here. M100 will send an extra bit which should be ignored
; by other side.
;
    ADI		0CH							;00001100
    MOV     E,A							;save word length + no parity: 14H, 1CH
    ANI     08H							;00001000
    ADD     A							;shift left 3 bits
    ADD     A
    ADD     A
    ORI     3FH							;00111111
    JMP     L_STORE_IGNORE_PARITY
; Parity 'O', 'E' or 'N'
L_SET_PARITY:
    CPI     'E'
    MVI     B,02H						;2 indicates 'E' parity
    JZ		+							;$$DONE
    SUI     'N'
    MVI     B,04H						;4 indicates 'N' parity
    JZ		+
    DCR     A							;if parity was 'O', now 0
    RNZ									;error: wrong parity
    MOV     B,A							;0 indicates 'O' parity
+	MOV     A,B							;merge parity (0, 2, 4) with word length (08H, 10H, 18H)
    ORA     E
    MOV     E,A							;save Word Length & Parity encoded byte
    MVI     A,0FFH						;11111111B
L_STORE_IGNORE_PARITY:
    STA     PARMSK_R					;Serial Ignore Parity Mask byte.
										;	Used to remove bits if 'I' parity
    INX     H
    MOV     A,M							;stop bits
    SUI     '1'							;0 means 1 stop bit, 1 means 2 stop bits
    CPI     02H
    RNC									;error: stop bits > 2
	ORA     E							;merge stop bits with Word Length & Parity encoded byte
    MOV     E,A							;save
    INX     H							;points to "Line Status"
    CALL    R_CONV_M_TOUPPER		  	;Get char at M and convert to uppercase
    CPI     'D'
    JZ		+							;brif 'D'
    CPI     'E'
    RNZ									;error: invalid Line Status
    CALL    R_ENABLE_XON_XOFF		  	;Enable XON/OFF when CTRL-S / CTRL-Q sent
    STC   								;set carry so R_CLR_XON_XOFF call is skipped
+	CNC     R_CLR_XON_XOFF
    POP     B							;remove error return
    POP     PSW							;retrieve carry
    PUSH    PSW
    PUSH    D							;save encoded serial parameters
    DCX     H							;backup M to beginning
    DCX     H
    DCX     H
    DCX     H
    LXI     D,SERMOD_R					;Serial initialization string
    MVI     B,05H						;length
    MOV     A,M							;baud rate
    JC		L_SET_RS232_1				;brif carry
    MVI     A,'M'						;Replace baud rate with 'M'
L_SET_RS232_1:							;copy RS232 parameters
    STAX    D
    INX     H
    INX     D
    CALL    R_CONV_M_TOUPPER		  	;Get char at M and convert to uppercase
    DCR     B
    JNZ     L_SET_RS232_1
    XCHG								;move command ptr to DE 
    POP     H							;restore encoded serial parameters
    POP     PSW							;restore carry (RS232 or MODEM)
    PUSH    D							;save command ptr
    CALL    R_INIT_RS232_MDM		  	;Initialize RS232 or modem
    POP     H							;restore command ptr to HL
    RET
;
; Wand device control block
;
R_BCR_DCB:								;1877H
    DW      R_BCR_OPEN, R_BCR_CLOSE, R_GEN_FC_ERROR
    DW      R_BCR_IN, R_BCR_IO

R_BCR_OPEN:
	RST38H	46H
R_BCR_CLOSE:
	RST38H	48H
R_BCR_IN:
	RST38H	4AH
R_BCR_IO:
	RST38H	4CH
;
; EOF function
;
;
R_EOF_FUN:								;1889H
	RST38H	26H
    CALL    R_GET_FCB					;returns File Status in A
    JZ      R_GEN_CF_ERR_FUN			;Generate CF error
    CPI     01H							;File open for Input?
    JNZ     R_GEN_NM_ERR_FUN			;brif FALSE: Generate NM error
    PUSH    H							;save FCB ptr
    CALL    L_EOF_FUN_1					;read char from file
    MOV     C,A							;save char
    SBB     A							;test
    CALL    L_SGN_EXTEND				;sign extend A to HL and FAC1
    POP     H
    INX     H							;HL += DEV_IN_FCB_OFS
    INX     H
    INX     H
    INX     H
    MOV     A,M							;get Device Code
    LXI     H,FILSTAT_R					;preload
    CPI     COM_DEV						;Device Code COM
    JZ      +
    CPI     MDM_DEV						;Device Code MDM
    JZ      +
    CALL    R_GET_FILESTAT				;Get ptr to BASIC File Status
    CPI     RAM_DEV						;Device Code RAM
    JZ      +
    LXI     H,CASFILSTAT_R				;ptr to Cassette File Status
+	MOV     M,C
    RET

L_EOF_FUN_1:
    PUSH    B							;save BC, DE, HL
    PUSH    H
    PUSH    D
    MVI     A,DCBIN_FUN					;DCB In function 
    JMP     L_EXEC_DCB_FUNC
;
; test and clear File Status
;
; BC, DE, HL pushed on stack
;
; IN:
;	HL points to Device File Status
; OUT:
;	Z		set if success
;
L_TSTFILSTAT:
    MOV     A,M							;get File Status
    MVI     M,00H						;clear
    ANA     A							;test File Status
    RZ 									;retif File Status == 0    
    INX     SP							;remove return address
    INX     SP
    CPI     1AH							;was File Status ^Z
    STC									;preset clear carry
    CMC
    JNZ     L_POPDHBREGS				;brif File Status != ^Z: Pops DE, HL, BC from stack and return
; TODO Looks like M still is ^Z
    MOV     M,A							;update File Status
    STC									;set carry
    JMP     L_POPDHBREGS				;Pops DE, HL, BC from stack and return
	
; 
; This routine is walking up the BASIC execution stack and modifying
; the address of the control variable for FOR loop entries.
; Needed when memory before VARTAB_R area is moved
;
; 
L_UPD_FOR_LOOPS:
    LXI     B,0001H						;offset 1
;
; IN:
;	BC		offset to add to the address of the control variable (negative usually)
;
L_UPD_FOR_LOOPS_1:						;entry point with BC preloaded
    LHLD    BASSTK_R					;start of BASIC execution stack
L_UPD_FOR_LOOPS_2:
    MOV     A,M							;get A from stack chain
    ANA     A
    RZ									;retif [stack chain] == 0
    XCHG
    LHLD    STRBUF_R					;BASIC string buffer pointer to DE
    XCHG
    COMPAR								;Compare STRBUF_R and stack chain: HL - DE
    RNC									;retif stack chain >= STRBUF_R
    MOV     A,M							;get marker again
    CPI     _FOR						;81H
    LXI     D,0007H						;preload default length
    JNZ     +							;brif A != _FOR
; _FOR marker found
    INX     H							;next
	GETDEFROMMNOINC						;POINTER TO THE LOOP VARIABLE to DE
    XCHG								;result to HL
    DAD     B							;add offset in BC
    XCHG								;result to DE
    MOV     M,D							;update POINTER TO THE LOOP VARIABLE: MSB
    DCX     H
    MOV     M,E							;LSB
    LXI     D,18H						;length 24 if _FOR marker
+	DAD     D							;next stack chain entry
    JMP     L_UPD_FOR_LOOPS_2			;Loop
;
; TIME$ function
;
R_TIME_FUN:								;1904H
    CHRGET								;Get next non-white char from M
    PUSH    H							;save text ptr
    CALL    L_PREP_8CHAR_STR
    CALL    R_READ_TIME				  	;Read time and store it at M
    JMP     L_STRSTK_ADD				;add Transient String to String Stack
;
; Read time and store it at M
;
R_READ_TIME:							;190FH
    CALL    R_UPDATE_CLK_VALUES      	;Update in-memory (F923H) clock values
    LXI     D,TIMBUF_R+5			    ;Hours (tens)
    CALL    L_CVT_2DIGITS_DE_DEC
    MVI     M,':'						;3AH
    INX     H
    CALL    L_CVT_2DIGITS_DE_DEC
    MVI     M,':'						;3AH
L_READ_TIME_1:
    INX     H
    JMP     L_CVT_2DIGITS_DE_DEC

R_DATE_FUN:
    CHRGET								;Get next non-white char from M
    PUSH    H							;save text ptr
    CALL    L_PREP_8CHAR_STR
    CALL    R_READ_DATE				    ;DATE$ function
    JMP     L_STRSTK_ADD				;add Transient String to String Stack
;
; DATE$ function
;
; IN:
;	HL		destination buffer
;
R_READ_DATE:							;192FH
    CALL    R_UPDATE_CLK_VALUES      	;Update in-memory (TIMBUF_R) clock values
    LXI     D,TIMBUF_R+9			    ;Month (1..12)
    LDAX    D
    CPI     0AH
    MVI     B,'0'						;preload 30H
    JC      +							;;brif month < 10
    MVI     B,'1'						;31H
    SUI     0AH							;rebase
+	MOV     M,B							;leading month digit
    INX     H
    CALL    L_CVT_ONE_DIGIT
    DCX     D
    MVI     M,'/'						;2FH
    INX     H
    CALL    L_CVT_2DIGITS_DE_DEC
    MVI     M,'/'						;2FH
    LXI     D,TIMYR1_R+1				;Year (tens)
    JMP     L_READ_TIME_1
;
; DAY function
;
R_DAY_FUN:								;1955H
    CHRGET								;Get next non-white char from M
    PUSH    H							;save text ptr
    MVI     A,03H
    CALL    L_PREP_ACHAR_STR
    CALL    R_READ_DAY				    ;Read day and store at M
    JMP     L_STRSTK_ADD				;add Transient String to String Stack
;
; Read day and store at M
;
R_READ_DAY:								;1962H
    CALL    R_UPDATE_CLK_VALUES        	;Update in-memory (F923H) clock values
    LDA     TIMBUF_R+8					;Day of the week code (0=Sun), 1=Mon), etc.)
    MOV     C,A							;save
    ADD     A							;*2
    ADD     C							;*3
    MOV     C,A
    MVI     B,00H						;zero extend
    XCHG								;HL to DE 
    LXI     H,L_Weekdays_MSG			;Code Based. 
    DAD     B							;index with day
    MVI     B,03H						;copy 3 bytes
    JMP     R_MOVE_B_BYTES				;Move B bytes from M to (DE)

L_Weekdays_MSG:
    DB      "Sun"
    DB      "Mon"
    DB      "Tue"
    DB      "Wed"
    DB      "Thu"
    DB      "Fri"
    DB      "Sat"
	
L_PREP_8CHAR_STR:
    MVI     A,08H
L_PREP_ACHAR_STR:
    CALL    L_PREP_STR					;Reserve String space and set Transitory String
    LHLD    TRSNSTR_R+1					;Transitory String data ptr
    RET

L_CVT_2DIGITS_DE_DEC:
    CALL    L_CVT_ONE_DIGIT_DE			;twice
;
; convert digit at [DE] to ascii at M
;
L_CVT_ONE_DIGIT_DE:
    LDAX    D							;get char
L_CVT_ONE_DIGIT:
    ORI     30H							;add '0'
    MOV     M,A
    DCX     D
    INX     H
    RET
;
; Update in-memory (F923H) clock values
;
R_UPDATE_CLK_VALUES:				  	;19A0H
    PUSH    H
    LXI     H,TIMBUF_R				  	;Seconds (ones)
;
; doing DI here is silly since L_DIS_INT_75_65() is called in R_GET_CLK_CHIP_REGS()
;
    DI 
    CALL    R_GET_CLK_CHIP_REGS       	;Copy clock chip regs to M
    EI     
    POP     H
    RET
;
; TIME$ statement
;
R_TIME_STMT:							;19ABH
    CPI     _EQUAL_						;0DDH '=' token
    JNZ     R_GET_TIME					;get current time
    CALL    R_GET_TIME_STRING			;Get time string from command line
	
;
; Update clock chip from memory F923H
;
R_UPDATE_CLK_CHIP:						;19B3H
    LXI     H,TIMBUF_R					;Seconds (ones)
;
; doing DI here is silly since L_DIS_INT_75_65() is called in R_PUT_CLK_CHIP_REGS()
;
    DI 
    CALL    R_PUT_CLK_CHIP_REGS      	;Update clock chip regs from M
    EI     
    POP     H
    RET
;
; DATE$ statement
; DATE$="mm/dd/yy"
;
R_DATE_STMT:							;19BDH
    CALL    L_CHK_STR_ASSIGN			;leaves ptr on stack
    JNZ     R_GEN_SN_ERROR				;brif string length != 8: Generate Syntax error
    CALL    L_GETBYT					;Evaluate byte expression at M-1
    DCR     A							;make 0 based
    CPI     12							;0CH
    JNC     R_GEN_SN_ERROR				;Generate Syntax error if month >= 12
    INR     A							;make 1 based again
    LXI     D,TIMBUF_R+9				;&Month (1-12)
    STAX    D							;update
	SYNCHK	'/'
    DCX     D							;skip TIMBUF_R+8
    CALL    R_CVT_DIGIT_PREDEC_DE		;Day (tens)
    CPI     04H
    JNC     R_GEN_SN_ERROR				;Generate Syntax error if high digit day >= 4
    CALL    R_CVT_DIGIT_PREDEC_DE		;Day (ones)
	SYNCHK	'/'
    LXI     D,TIMYR1_R+2
    CALL    R_CVT_DIGIT_PREDEC_DE		;TIMYR1_R+1 Year (tens)
    CALL    R_CVT_DIGIT_PREDEC_DE		;TIMYR1_R Year(ones)
    XRA     A
    STA     TIMMON_R					;new date: reset TIMMON_R
    JMP     R_UPDATE_CLK_CHIP			;Update clock chip from memory TIMBUF_R
;
; DAY$ statement
; DAY$="day" where "day" is 3 letter weekdays
;
R_DAY_STMT:								;19F1H
    CALL    L_CHK_STR_ASSIGN			;check for '=' and get string ptr
    CPI     03H							;length of string
    JNZ     R_GEN_SN_ERROR				;Generate Syntax error
    LXI     D,L_Weekdays_MSG			;Code Based.
    MVI     C,07H						;7 days in a week
L_DAY_STMT_1:
    PUSH    H							;save string ptr
    MVI     B,03H						;length of each weekday
-	LDAX    D							;get weekday character
    PUSH    D							;save weekdays ptr
    CALL    R_CONV_A_TOUPPER			;Convert weekday char to uppercase
    MOV     E,A							;save it
    CALL    R_CONV_M_TOUPPER			;Get day$ string char and convert to uppercase
    CMP     E							;weekday char
    POP     D							;restore weekdays ptr
    JNZ     L_DAY_STMT_2				;brif no match: skip this weekday string
    INX     D							;next weekday char ptr
    INX     H							;next string ptr
    DCR     B							;length
    JNZ     -							;brif more characters to compare
;found a match
    POP     H							;restore string ptr
    MVI     A,07H						;compute Day code
    SUB     C							;weekday loop counter
    STA     TIMBUF_R+8					;Day code (0=Sun), 1=Mon), etc.)
    JMP     R_UPDATE_CLK_CHIP			;Update clock chip from memory F923H
; skip current weekday string
L_DAY_STMT_2:
    INX     D							;skip remainder of current day
    DCR     B
    JNZ     L_DAY_STMT_2
    POP     H							;restore string ptr
    DCR     C							;weekday loop counter
    JNZ     L_DAY_STMT_1				;brif more days
    JMP     R_GEN_SN_ERROR				;no match. Generate Syntax error
;
; These 2 routines leave a string ptr on the Stack
;
L_CHK_STR_ASSIGN:
	SYNCHK	_EQUAL_						;'=' token
L_CHK_STR_CLK:
    CALL    L_FRMEVL					;Main BASIC evaluation routine
    XTHL								;save HL above return address
    PUSH    H
    CALL    R_UPDATE_CLK_VALUES      	;Update in-memory (TIMBUF_R) clock values
    CALL    L_FRESTR					;FREE UP TEMP & CHECK STRING
    MOV     A,M							;String length to A
    INX     H							;next
	MOV     E,M							;LSB of string ptr
	INX     H
	MOV     H,M							;MSB of string ptr
    MOV     L,E							;string ptr to HL
    CPI     08H							;compare string length
    RET
;
; Get time string from command line
;
R_GET_TIME_STRING:						;1A42H
    CALL    L_CHK_STR_ASSIGN			;leaves ptr on stack
    JNZ     R_GEN_SN_ERROR				;brif string length != 8: Generate Syntax error
    XCHG								;HL to DE
    POP     H							;pushed ptr to HL
    XTHL								;save HL above return address
    PUSH    H
    XCHG
    LXI     D,TIMBUF_R+6				;Date (ones)
    CALL    R_CVT_DIGIT_PREDEC_DE
    CPI     03H							;hours must be < 3
    JNC     R_GEN_SN_ERROR				;brif high hours digit >= 3: Generate Syntax error
    CALL    R_CVT_DIGIT_PREDEC_DE		;get low hours digit
	SYNCHK	':'							;3AH
    CALL    L_GET_TIME_STRING_1			;get minutes
	SYNCHK	':'							;3AH
; get seconds
L_GET_TIME_STRING_1:
    CALL    R_CVT_DIGIT_PREDEC_DE
    CPI     06H
    JNC     R_GEN_SN_ERROR				;brif A >= 6: Generate Syntax error
;
; convert ascii digit at M and store in (DE)
;
R_CVT_DIGIT_PREDEC_DE:
    DCX     D							;backup ptr
    MOV     A,M							;get digit
    INX     H							;next digit
    SUI     '0'							;convert to binary
    CPI     10							;0AH
    JNC     R_GEN_SN_ERROR				;Generate Syntax error if A >= 10
    ANI     0FH							;isolate low nibble. TODO Silly since A < 10
    STAX    D
    RET
;
; IPL statement
;
R_IPL_STMT:								;1A78H
    JZ      R_ERASE_IPL_PRGM			;Erase current IPL program if no argument
    CALL    L_CHK_STR_CLK				;get string, update clock. string ptr on stack
    ANA     A							;check string length
    JZ      +							;POP HL and Erase current IPL program
    CPI     0AH
    JNC     R_GEN_FC_ERROR				;Generate FC error if >= 10 characters
    MOV     B,A							;filename length
    XCHG								;filename ptr to DE
    LXI     H,IPLNAM_R				    ;Start of IPL filename
    CALL    R_MOVE_B_BYTES_INC       	;Move B bytes from (DE) to M with increment
    MVI     M,0DH						;end if CR
    INX     H
    MOV     M,B							;terminate
    POP     H							;remove string ptr
    RET

+	POP     H							;remove string ptr
;
; Erase current IPL program
;
; OUT:
;	A == 0
;
R_ERASE_IPL_PRGM:						;1A96H
    XRA     A
    STA     IPLNAM_R					;IPL filename
    STA     IPLNAM_R+1
    RET
;
; COM and MDM statements
;
R_COM_MDM_STMT:							;1A9EH
    PUSH    H
    LXI     H,SYSINT_R				  	;On Com flag
    JMP     +

R_GET_TIME:
    PUSH    H
    LXI     H,SYSINT_R+3				;On Time flag
+	CALL    L_DET_INT_ARG				;Determine argument (ON/OFF/STOP) for TIME$ statement
L_GET_TIME_1:
	POP     H
    POP     PSW
    CHRGET								;Get next non-white char from M
    JMP     L_NEWSTT_1
;
; KEY() statement
;	KEY num,"value"
;	Assigns "value" to the given function key "num" (1-8).
;	Pressing the matching function key will pretend to type "value" on the keyboard.
;	Note: To reset the keys to their default, run these two instructions:
;	CALL 23164,0,23366	CALL R_SET_FKEYS,A=0,HL=R_BASIC_FKEYS_TBL
;	CALL 27795			CALL R_SET_BASIC_FKEYS
;
R_KEY_FUN:								;1AB2H
    CALL    L_GETBYT					;Evaluate byte expression at M-1. Result in A & E
    DCR     A							;rebase to 0..7
    CPI     08H
    JNC     R_GEN_FC_ERROR				;brif A >= 8: Generate FC error
    MOV     A,M							;get next token
    PUSH    H							;save src ptr
    CALL    L_KEY_STMT					;needs E
    JMP		L_GET_TIME_1
;
; KEY STOP/ON/OFF statements
;
; set status for all function keys
;
; IN:
;	A ON/OFF/STOP token
;
R_KEY_ON_OFF_STMT:						;1AC3H
    PUSH    H
    MVI     E,08H						;for all function keys
-	PUSH    D
    PUSH    PSW
    CALL    L_KEY_STMT					;uses E
    POP     PSW
    POP     D
    DCR     E
    JNZ		-
    JMP     L_GET_TIME_1
;
; Process KEY() statement
;
; IN:
;	A ON/OFF/STOP token
;	E key number base 1
; OUT:
;	HL?
;
L_KEY_STMT:
    MVI     D,00H
    LXI     H,FKEYSTAT_R-1				;0F62FH Load pointer to KEY ON enabled table - 2
    DAD     D
    PUSH    H							;save ptr to FKEYSTAT_R
    LXI     H,SYSINT_R+3				;&Basic Interrupt table[1]
    DAD     D							;add 3 * DE
    DAD     D
    DAD     D
    CALL    L_DET_INT_ARG				;Determine argument (ON/OFF/STOP) for TIME$ statement
    MOV     A,M
    ANI     01H							;isolate bit 0
    POP     H							;restore ptr to FKEYSTAT_R
    MOV     M,A							;update KEY ON enabled table
    RET
;
; Determine argument (ON/OFF/STOP) for any Interrupt statement
;
; IN:
;	A ON/OFF/STOP token
;	HL	Interrupt Table entry to update
;
L_DET_INT_ARG:							;1AEAH
    CPI     _ON
    JZ      R_INT_ON_STMT				;TIME$ ON statement
    CPI     _OFF
    JZ      R_TIME_OFF_STMT				;TIME$ OFF statement
    CPI     _STOP
    JZ      R_INT_STOP_STMT				;TIME$ STOP statement
    JMP     R_GEN_SN_ERROR				;Generate Syntax error
;
; Determine device (KEY/TIME/COM/MDM) for ON GOSUB
;
R_DET_DEVICE_ARG:						;1AFCH
    CPI     _COM
    LXI     B,0001H
    RZ
    CPI     _MDM
    RZ
    CPI     _KEY
    LXI     B,0208H
    RZ
    CPI     _TIME_
    STC									;set error condition
    RNZ
;
; ON TIME$ statement
;
R_ONTIME_STMT:							;1B0FH
    INX     H
    CALL    R_GET_TIME_STRING			;Get time string from command line
    LXI     H,TIMINT_R				    ;Time for ON TIME interrupt (SSHHMM or SSMMHH)
    MVI     B,06H
    CALL    R_MOVE_B_BYTES_INC			;Move B bytes from (DE) to M with increment
    POP     H
    DCX     H
    LXI     B,0101H
    ANA     A
    RET
;
; ON COM handler
;
R_ONCOM_STMT:							;1B22H
    PUSH    H
    MOV     B,A
    ADD     A
    ADD     B
    MOV     L,A
    MVI     H,00H
    LXI     B,SYSINT_R+1				;0F945H On Com routine address
    DAD     B
    MOV     M,E
    INX     H
    MOV     M,D
    POP     H
    RET
;
; RST 7.5 -- Timer background task
;
R_TIMER_ISR:							;1B32H
    CALL    SYSHK_R
    PUSH    H
    PUSH    D
    PUSH    B
    PUSH    PSW
    MVI     A,0DH						;00001101B. DO NOT Reset to 0 RST7.5 flip-flop.
    SIM    
    EI									;Allow other interrupts again
    LXI     H,TIMCNT_R					;2Hz count-down value
    DCR     M
    JNZ     L_RST7_5_2						;brif != 0. Could jump directly to L_BLINK_CURSOR_0
; 250 mSecs mark
    MVI     M,125						;reset 2Hz count-down value
    INX     H							;TIMCN2_R Counter (12 to 1)
    DCR     M
    JNZ     +							;brif != 0
; 12 * 250 mSecs = 3 seconds mark
    MVI     M,12						;reset Counter (12 to 1)
    INX     H							;PWRCNT_R Power down countdown value
    PUSH    H							;save ptr to PWRCNT_R
    LHLD    CURLIN_R					;Currently executing line number
    INX     H							;test CURLIN_R for 0FFFFH
    MOV     A,H
    ORA     L
    POP     H							;restore ptr to PWRCNT_R
    CNZ     R_KICK_PWR_OFF_WDT			;calif CURLIN_R != 0FFFFH: Renew automatic power-off counter
    MOV     A,M							;get PWRCNT_R
    ANA     A
    JZ		+							;brif PWRCNT_R == 0
    DCR     M							;update PWRCNT_R
    JNZ		+							;brif PWRCNT_R != 0
    INX     H							;ptr to PWRDWN_R
    MVI     M,0FFH						;set Power Down Flag
;
; every 250 mSecs. TODO calling R_GET_CLK_CHIP_REGS this often seems too frequent
;
+	LXI     H,CLKCHP_R				    ;ptr to 10 bytes Clock Chip Buffer
    PUSH    H							;save ptr
    CALL    R_GET_CLK_CHIP_REGS        	;Copy clock chip regs to M
    POP     D							;restore ptr to Seconds (ones)
    LXI     H,TIMINT_R				    ;Time for ON TIME interrupt (SSHHMM or SSMMHH)
    MVI     B,06H						;size == 6 bytes
-	LDAX    D							;compare Clk_Chip Time with ON TIME
    SUB     M
    JNZ		+							;brif different: store 0 in ONTIMETRIGD_R
    INX     D							;next
    INX     H
    DCR     B							;loop counter
    JNZ     -
	;DE now points to Unit of Days. HL now points to ONTIMETRIGD_R. A == 0
	; Clk_Chip Time and ON TIME are identical
    ORA     M							;test ONTIMETRIGD_R
    JNZ     L_RST7_5_1					;brif ONTIMETRIGD_R != 0 (already triggered)
    LXI     H,SYSINT_R+3				;On Time flag
    CALL    R_TRIG_INTR				    ;Trigger interrupt.  HL points to interrupt table
; store 0AFH in ONTIMETRIGD_R
	SKIP_BYTE_INST						;Sets A to 0AFH
;:								;store 0 in ONTIMETRIGD_R
+	XRA     A
    STA     ONTIMETRIGD_R				;store 0 or 0AFH
L_RST7_5_1:
    LDA     CLKCHP_R+9					;Month Clock Chip Buffer.
    LXI     H,TIMMON_R
    CMP     M
    MOV     M,A							;update TIMMON_R with current month
    JNC     +							;brif [clock chip month] >= [current month]
;
; clock chip month < current month. Must have overflowed
; Update Year
;
    LXI     H,TIMYR1_R				    ;Year (ones)
    INR     M							;increment [TIMYR1_R]
    MOV     A,M							;get [TIMYR1_R]
    SUI     10							;0AH
    JNZ     +							;brif [TIMYR1_R] != 10
    MOV     M,A							;reset [TIMYR1_R] to 0
    INX     H							;to TIMYR1_R+1 Year (tens)
    INR     M							;update (tens)
    MOV     A,M							;get [TIMYR1_R+1]
    SUI     10							;0AH
    JNZ     +							;brif [TIMYR1_R+1] != 10
    MOV     M,A							;reset [TIMYR1_R+1] to 0 (99 -> 00)
+	CALL    R_CHK_XTRNL_CNTRLER      	;Check for optional external controller
L_RST7_5_2:
    JMP     L_BLINK_CURSOR_0			;Continuation of RST 7.5 Background hook
;
; Renew automatic power-off counter
;
R_KICK_PWR_OFF_WDT:						;1BB1H
    LDA     TIMDWN_R					;POWER down time (1/10ths of a minute)
    STA     PWRCNT_R
    RET
;
; KEY statement
;
R_KEY_STMT:								;1BB8H
    CPI     _LIST						;0A5H
    JNZ     L_KEY_NOLIST
;
; KEY LIST statement
;
R_KEY_LIST_STMT:						;1BBDH
    CHRGET								;Get next non-white char from M
    PUSH    H
    LXI     H,FNKSTR_R				    ;Function key definition area
    MVI     C,04H
-	CALL    L_KEY_LIST_STMT_1			;2 keys per line
    CALL    L_KEY_LIST_STMT_1
    CALL    R_SEND_CRLF				    ;Send CRLF to screen or printer
    DCR     C
    JNZ     -
    POP     H
    RET
;
; IN:
;	HL		ptr to key text
;
; OUT
;	HL		ptr to next key text
;
L_KEY_LIST_STMT_1:
    MVI     B,16						;10H
    CALL    R_SEND_CHARS_TO_LCD      	;Send 16 characters from M to the screen. Returns ' ' in A
    MVI     B,03H
-	OUTCHR								;Send ' ' to screen/printer
    DCR     B
    JNZ     -
    RET
;
; Send B characters from M to the screen
;
; OUT
;	B		0
;
R_SEND_CHARS_TO_LCD:				    ;1BE0H
    MOV     A,M
    CPI     7FH
    JZ		+							;brif A == 7FH
    CPI     ' '
    JNC     L_SEND_CHARS_TO_LCD_1		;brif A printable
+	MVI     A,' '
L_SEND_CHARS_TO_LCD_1:
    OUTCHR	  							;Send character in A to screen/printer
    INX     H
    DCR     B
    JNZ     R_SEND_CHARS_TO_LCD			;Send characters from M to the screen
    MVI     A,' '						;Return ' '
    RET
;
; KEY ON/OFF/STOP
; KEY (num) ON/OFF/STOP
; KEY num,"string"
;
L_KEY_NOLIST:
    CPI     '('
    JZ      R_KEY_FUN				  	;KEY() statement
    CPI     _ON							;ON
    JZ      R_KEY_ON_OFF_STMT			;KEY STOP/ON/OFF statements
    CPI     _OFF						;OFF
    JZ      R_KEY_ON_OFF_STMT			;KEY STOP/ON/OFF statements
    CPI     _STOP						;STOP
    JZ      R_KEY_ON_OFF_STMT			;KEY STOP/ON/OFF statements
    CALL    L_GETBYT					;Evaluate byte expression at M-1
    DCR     A							;rebasse to 0..7
    CPI     08H
    JNC     R_GEN_FC_ERROR				;brif A >= 8: Generate FC error
    XCHG								;src ptr to DE
    MOV     L,A							;zero extend A to HL
    MVI     H,00H
    DAD     H							;16 bytes per entry
    DAD     H
    DAD     H
    DAD     H
    LXI     B,FNKSTR_R				  	;Function key definition area
    DAD     B							;index
    PUSH    H							;save function key ptr
    XCHG								;restore src ptr
	SYNCHK	','
    CALL    L_FRMEVL					;Main BASIC evaluation routine
    PUSH    H							;save src ptr
    CALL    L_FRESTR					;FREE UP TEMP & CHECK STRING
    MOV     B,M							;string length to B
    INX     H
	GETDEFROMMNOINC						;string data ptr to DE
    POP     H							;restore src ptr
    XTHL								;src ptr to stack. function key table ptr to HL
    MVI     C,0FH						;loop control
    MOV     A,B							;string length
    ANA     A
    JZ      L_KEY_NOLIST_1				;brif no string
-	LDAX    D							;get string char
    ANA     A							;test for NULL
    JZ      R_GEN_FC_ERROR				;Generate FC error
    MOV     M,A							;update function key table
    INX     D							;next string
    INX     H							;next table ptr
    DCR     C							;max entry size
    JZ      +							;brif reached: done
    DCR     B							;string length
    JNZ		-							;brif not done
L_KEY_NOLIST_1:							;B is now 0
    MOV     M,B							;terminate function key table entry
    INX     H							;next
    DCR     C							;more space?
    JNZ     L_KEY_NOLIST_1				;brif more space
+	MOV     M,C							;HL ptr beyond end of function key table entry
    CALL    R_DISP_FKEYS				;Display function keys on 8th line
    CALL    R_SET_BASIC_FKEYS       	;Copy BASIC Function key table to key definition area
    POP     H
    RET
;
; PSET statement
;
R_PSET_STMT:							;1C57H
    CALL    R_TOKENIZE_XY				;Get (X),Y) coordinate from tokenized string at M in DE, A is plot value
L_PSET_STMT_1:
    RRC									;bit 0 to carry
    PUSH    H
    PUSH    PSW
    CC      R_PLOT_POINT				;Plot (set) point (D),E) on the LCD
    POP     PSW
    CNC     R_CLEAR_POINT				;Clear (reset) point (D),E) on the LCD
    POP     H
    RET
;
; PRESET statement
;
R_PRESET_STMT:							;1C66H
    CALL    R_TOKENIZE_XY				;Get (X),Y) coordinate from tokenized string at M in DE,A is plot value
    CMA
    JMP     L_PSET_STMT_1
;
; LINE_1 statement
;
R_LINE_STMT_1:							;1C6DH
    CPI     _MINUS_						;token '-'
    XCHG
    LHLD    XPLOT_R						;X coord of last point plotted
    XCHG
    CNZ     R_TOKENIZE_XY				;Get (X),Y) coordinate from tokenized string at M in DE
    PUSH    D							;save first coordinate pair
	SYNCHK	_MINUS_						;token '-'
    CALL    R_TOKENIZE_XY				;Get (X),Y) coordinate from tokenized string at M in DE
    PUSH    D							;save second coordinate pair
    LXI     D,R_PLOT_POINT				;default plot function			
    JZ      L_LINE_STMT_1_1
    PUSH    D							;save default plot function
	SYNCHK	','
    CALL    L_GETBYT					;Evaluate byte expression at M-1
    POP     D							;restore default plot function
    RRC									;get odd-even bit 0 in carry
    JC      +							;set a point
    LXI     D,R_CLEAR_POINT				;change to clear plot function
;:								;DE has plot function
+	DCX     H
    CHRGET								;Get next non-white char from M
L_LINE_STMT_1_1:
    XCHG
    SHLD    LSTCAL_R					;store plot function here
    XCHG
    JZ      L_DRAW_BOX_1				;brif no more chars
	SYNCHK	','
	SYNCHK	'B'
    JZ      R_DRAW_BOX				    ;Draw an unfilled box on LCD. Coords are on stack
	SYNCHK	'F'
    POP     D							;get second coordinate pair to DE
;
; Draw a filled box on LCD. Coords are on stack
;
; IN:
;	[LSTCAL_R]	plot function
;	[SP+0]		first coordinate pair
;	DE			second coordinate pair
;
R_DRAW_FBOX:							;1CA6H
    XTHL								;swap first coordinate pair and text ptr
; HL is now first coordinate pair (x1, y1). DE is (x2, y2)
    MOV     A,E							;Delta = y2-y1
    SUB     L
    JNC		+							;brif y2 >= y1
    CMA									;negate Delta
    INR     A
    MOV     L,E							;new y1
; A is line count
+	MOV     B,A							;Delta to B: line count
    INR     B							;pre-increment
-	MOV     E,L							;D = x2, E = y
    CALL    L_DRAW_LINE					;HL is x1, y. DE = x2, y
    INR     L							;next y
    DCR     B							;decrement line count
    JNZ     -
    POP     H							;restore text ptr
    RET
;
; Draw an unfilled box on LCD. Coords are on stack
; IN:
;	[LSTCAL_R]	plot function
;	[SP+0]		second coordinate pair
;	[SP+2]		second coordinate pair
;
R_DRAW_BOX:								;1CBCH
    POP     D							;second coordinate pair
    XTHL								;swap text ptr and first coordinate pair
    PUSH    D							;save second coordinate pair
    MOV     E,L
    CALL    L_DRAW_LINE					;draw line
    POP     D							;retrieve second coordinate pair
    PUSH    D
    MOV     D,H
    CALL    L_DRAW_LINE					;draw line
    POP     D							;restore second coordinate pair
    PUSH    H							;save first coordinate pair
    MOV     H,D
    CALL    L_DRAW_LINE					;draw line
    POP     H							;restore first coordinate pair
    MOV     L,E
	SKIP_2BYTES_INST_BC					;skip POP D & XTHL
L_DRAW_BOX_1:
    POP     D
    XTHL
    CALL    L_DRAW_LINE					;draw line
    POP     H							;restore text ptr
    RET
;
; Bresenham line drawing function
;
; IN:
;	HL		x1,y1
;	DE		x2,y2
;
L_DRAW_LINE:
    PUSH    H							;save all registers
    PUSH    D
    PUSH    B
    MOV     A,L							;y1-y2
    SUB     E
    JNC     +
    XCHG								;swap coordinates
    CMA									;negate row count
    INR     A
+	MOV     B,A							;positive row count
    MVI     C,14H						;opcode
    MOV     A,H							;x1-x2
    SUB     D
    JNC     +
    CMA									;negate column count
    INR     A
    INR     C
; A is positive column count
+	CMP     B
    JC      +							;brif column count < row count
    MOV     H,A
    MOV     L,B
    MVI     A,1CH						;INR E opcode
    JMP     L_DRAW_LINE_1
+	MOV     L,A
    MOV     H,B
    MOV     A,C
    MVI     C,1CH						;INR E opcode
;
; A contains Increment Opcode, C contains Decrement Opcode
;
L_DRAW_LINE_1:
    STA     INRCODE_R					;RAM based instruction
    MOV     A,C
    STA     DCRCODE_R
    MOV     B,H
    INR     B
    MOV     A,H
    ANA     A
    RAR
    MOV     C,A
L_DRAW_LINE_2:
    PUSH    H							;save all registers
    PUSH    D
    PUSH    B
    CALL    LSTCAL_R-1					;call pixel function. DE has coordinate pair
    POP     B							;restore all registers
    POP     D
    POP     H
    CALL    DCRCODE_R
    MOV     A,C
    ADD     L
    MOV     C,A
    JC      +
    CMP     H
    JC      L_DRAW_LINE_3
+	SUB     H
    MOV     C,A
    CALL    INRCODE_R
L_DRAW_LINE_3:
    DCR     B
    JNZ     L_DRAW_LINE_2						;brif B != 0
    JMP     R_POP_ALL_WREGS				;restore all registers and return
;
; Get (X,Y) pixel coordinate from tokenized string at M
;
; OUT:
;	A		plot value (default is 1)
;	DE		(x,y)
;
R_TOKENIZE_XY:							;1D2EH
	SYNCHK	'('
    CALL    L_GETBYT					;Evaluate byte expression at M-1: X in A,E
    CPI     MAXPIXCOLUMN				;240
    JNC     R_GEN_FC_ERROR				;brif X >= MAXPIXCOLUMN: Generate FC error
    PUSH    PSW							;save X
	SYNCHK	','
    CALL    L_GETBYT					;Evaluate byte expression at M-1: Y in A,E
    CPI     MAXPIXROW					;64
    JNC     R_GEN_FC_ERROR				;brif Y >= MAXPIXROW: Generate FC error
    POP     PSW							;restore X
    MOV     D,A							;move X to D. DE is now (x,y)
    XCHG
    SHLD    XPLOT_R						;move DE to X coord of last point plotted
    XCHG
    MOV     A,M							;next char
    CPI     ')'
    JNZ     +							;brif not ')'
    CHRGET								;Get next non-white char from M
    MVI     A,01H						;default plot ON
    RET
+	PUSH    D							;save DE
	SYNCHK	','
    CALL    L_GETBYT					;Evaluate byte expression at M-1: value in A,E
	SYNCHK	')'
    MOV     A,E							;plot value
    POP     D							;restore DE
    RET
;
; print at display position
;
L_PRINT_POS:
    CALL    L_GETINT					;Evaluate expression at M: Display Position to DE
	SYNCHK	','
    PUSH    H							;save text ptr
    XCHG								;Display Position to HL. s.b. < 320
    LDA     LINWDT_R					;Active columns count (1-40)
    CMA									;negate
    INR     A
    MOV     C,A							;sign extend negative column count to BC
    MVI     B,0FFH
    MOV     E,B							;set E to -1: line count
-	INR     E							;increment line count
    MOV     D,L							;save remainder of Display Position
    DAD     B							;subtract column count from Display Position
    JC		-							;brif HL > 0
    LDA     LINWDT_R					;Active columns count (1-40)
    INR     D							;increment remainder
    CMP     D							;compare columns count with remainder
    JC      R_GEN_FC_ERROR				;brif columns count: Generate FC error
    LDA     LINCNT_R					;Console height
    INR     E							;increment line count
    CMP     E							;LINCNT_R-line count
    JC      R_GEN_FC_ERROR				;brif : Generate FC error
    XCHG								;DE to HL
    CALL    R_SET_CURSOR_POS			;Set the current cursor position
    MOV     A,H							;update new horizontal cursor position.
    DCR     A
    STA     CURHPOS_R					;Horiz. position of cursor (0-39)
    POP     H							;restore text ptr
    RET
;
; CSRLIN function
;
R_CSRLIN_FUN:							;1D90H
    PUSH    H
    LDA     CSRY_R						;Cursor row (1-8)
    DCR     A
L_CSRLIN_FUN_1:
    CALL    L_SGN_EXTEND				;sign extend A to HL and FAC1
    POP     H
    CHRGET								;Get next non-white char from M
    RET
;
; MAX function
;	MAXFILES or MAXRAM
;
R_MAX_FUN:								;1D9BH
    CHRGET								;Get next non-white char from M
    CPI     _FILES						;FILES token
    JZ      R_MAXFILES_FUN				;MAXFILES function
	SYNCHK	'R'
	SYNCHK	'A'
	SYNCHK	'M'
;
; MAXRAM function
;
R_MAXRAM_FUN:							;1DA7H
    PUSH    H							;save txt ptr
	RST38H	02H
    LXI     H,SYSRAM_R					;Address of RAM used by ROM
R_MAXRAM_FUN2:							;used by vt100.asm
    CALL    L_CONV_UNSGND_HL_SNGL		;Convert unsigned integer HL to single precision FAC1
    POP     H							;restore txt ptr
    RET
;
; MAXFILES function
;
; MAXFILES or MAXFILES=num
;
R_MAXFILES_FUN:							;1DB2H
    PUSH    H							;save text ptr
    LDA     MAXFILES_R					;Maxfiles
    JMP     L_CSRLIN_FUN_1
;
; HIMEM function
;
R_HIMEM_FUN:							;1DB9H
    PUSH    H							;save txt ptr
    LHLD    HIMEM_R						;HIMEM
    CALL    L_CONV_UNSGND_HL_SNGL		;Convert unsigned integer HL to single precision FAC1
    POP     H							;restore txt ptr
    CHRGET								;Get next non-white char from M
    RET
;
; WIDTH statement
;
R_WIDTH_STMT:							;1DC3H
	RST38H	3AH
;
; SOUND statement
;
R_SOUND_STMT:							;1DC5H
    CPI     _ON							;ON
    JZ      R_SOUND_ON_STMT				;SOUND ON statement
    CPI     _OFF 						;OFF
    JZ      R_SOUND_OFF_STMT			;SOUND OFF statement
    CALL    R_EVAL_EXPR_2				;Evaluate expression at M_2
    MOV     A,D
    ANI     0C0H						;11000000B
    JNZ     R_GEN_FC_ERROR				;Generate FC error
    PUSH    D
	SYNCHK	','
    CALL    L_GETBYT					;Evaluate byte expression at M-1
    ANA     A
    MOV     B,A
    POP     D
    JNZ     R_GEN_TONE				  	;Produce a tone of DE freq and B duration
    RET
;
; SOUND OFF statement
;
R_SOUND_OFF_STMT:						;1DE5H
	SKIP_BYTE_INST						;Sets A to 0AFH
;
; SOUND ON statement
;
R_SOUND_ON_STMT:						;1DE6H
    XRA     A
    STA     SNDFLG_R					;Sound flag
    CHRGET								;Get next non-white char from M
    RET
;
; MOTOR statement
;
R_MOTOR_STMT:							;1DECH
    SUI     _OFF 						;OFF
    JZ      R_MOTOR_OFF_STMT			;MOTOR OFF statement
;
; MOTOR ON statement
;
R_MOTOR_ON_STMT:						;1DF1H
	SYNCHK	_ON							;97H
    DCX     H
    MOV     A,H
;
; MOTOR OFF statement
;
R_MOTOR_OFF_STMT:						;1DF5H
    MOV     E,A
    CHRGET								;Get next non-white char from M
    JMP     R_CAS_REMOTE_FUN			;Cassette REMOTE routine - turn motor on or off
;
; CALL statement
;
R_CALL_STMT:							;1DFAH
    CALL    R_EVAL_EXPR_2				;Evaluate expression at M_2
    XCHG
    SHLD    LSTCAL_R					;Address last called
    XCHG
    DCX     H
    CHRGET								;Get next non-white char from M
    JZ      L_CALL_STMT_1
	SYNCHK	','
    CPI     ','
    JZ		+
    CALL    L_GETBYT					;Evaluate byte expression at M-1
    JZ      L_CALL_STMT_1
+	PUSH    PSW
	SYNCHK	','
    CALL    R_EVAL_EXPR_2				;Evaluate expression at M_2
    POP     PSW
L_CALL_STMT_1:
    PUSH    H
    XCHG
    CALL    LSTCAL_R-1					;0F660H contains JMP to Address last called
    POP     H
    RET
;
; SCREEN statement
;  SCREEN [0/1][,0/1]
;	at least one operand required
; VT100:
;	potentially SCREEN 2
; IN:
;	A		first char after SCREEN
;
R_SCREEN_STMT:							;1E22H
    CPI     ','
    LDA     CONDEV_R					;New Console device flag
    CNZ     L_GETBYT					;Evaluate byte expression at M-1
    CALL    L_SCREEN_STMT_1				;process first 0/1 operand
    DCX     H							;backup
    CHRGET								;Get next non-white char from M
    RZ									;retif done
	SYNCHK	','
    CALL    L_GETBYT					;Evaluate byte expression at M-1
    PUSH    H
    ANA     A							;test for 0 or 1
    CALL    L_SET_LABEL_LINE			;Z is argument
    POP     H
    RET
;
; ======================================================
; Process SCREEN statement including calling SCREEN RST7 Hook
; A has New Console Device flag
; IN:
;	A		New Console device code (0, 1 or 2)
; ======================================================
;
L_SCREEN_STMT_1:
    PUSH    H							;Preserve HL on stack
    STA     CONDEV_R					;Set new Console device flag (0, 1 or 2)
    ANA     A							;test it
    LXI     D,2808H						;preload 40 columns by 8 rows: console size
    LHLD    LCDCSY_R					;Cursor row (1-8) + cursor column (1..40)
    MVI     A,14						;Value of last column before wrap for PRINT ,
    JZ      +							;Jump over RST7 if not New Console Device
; CONDEV_R != 0
    XRA     A
    STA     CONDEV_R					;Clear New Console device flag
	RST38H	3EH							;intercepted by DVI/VT100. 
+	SHLD    CSRY_R						;Update cursor row (1-8) + column (1-40)
    XCHG								;DE has active ROWS,COLS (for LCD or DVI)
    SHLD    LINCNT_R					;Console height + Console width
    STA     COLWRAP_R					;Store value of column wrap for PRINT , (14 or 56 if 80 COL mode)
    POP     H							;Restore HL from stack
    RET
;
; LCOPY statement
;
R_LCOPY_STMT:						   	;1E5EH
    PUSH    H
    CALL    L_LPT_NEWLINE				;send CR to printer
    LXI     H,LCD_R				       	;Start of LCD character buffer
    MVI     E,08H						;max Row
L_LCOPY_STMT_1:
    MVI     D,40						;max column (28H)
-	MOV     A,M
    CALL    R_OUT_CH_TO_LPT				;Output character to printer
    INX     H
    DCR     D
    JNZ		-							;column loop
    CALL    L_LPT_NEWLINE				;send CR to printer
    DCR     E
    JNZ     L_LCOPY_STMT_1				;row loop
    POP     H
    RET

L_RAMFILE:
    PUSH    H
    CALL    LNKFIL						;Fix up the directory start pointers
    LHLD    FILNAM_R+6					;Get Filename extension
    LXI     D,2020H						;"  "
    COMPAR								;Compare extension with "  ": HL - DE
    PUSH    PSW
    JZ      +
    LXI     D,4142H						;"BA"
    COMPAR								;Compare extension with "BA": HL - DE
    JNZ     L_RAMFILE_1
+	CALL    L_SET_EXT_BA				;set "BA" extension and find file
    JZ      L_RAMFILE_1
    POP     PSW							;stack cleanup
    POP     B
    POP     PSW							;new Z flag
    JZ      R_GEN_FC_ERROR				;Generate FC error
    MVI     A,00H						;save flags
    PUSH    PSW
    PUSH    B
    SHLD    RAMDIRPTR_R
    XCHG
    SHLD    TXTTAB_R					;Start of BASIC program pointer
    CALL    R_UPDATE_LINE_ADDR       	;Update line addresses for current BASIC program
    POP     H							;text ptr
    MOV     A,M							;next char
    CPI     ','
    JNZ     +
    CHRGET								;Get next non-white char from M
	SYNCHK	'R'
    POP     PSW
    MVI     A,80H
    STC
    PUSH    PSW
+	POP     PSW
    STA     OPNFIL_R
    JC      R_INIT_BASIC_VARS			;Initialize BASIC Variables for new execution
    CALL    R_INIT_BASIC_VARS			;Initialize BASIC Variables for new execution
    JMP     R_GO_BASIC_RDY_OK			;Vector to BASIC ready - print Ok

L_RAMFILE_1:
    POP     PSW
    POP     H
    MVI     D,RAM_DEV					;0F8H 
    JNZ     L_MERGE_1
    PUSH    H
    LXI     H,2020H						;"  "
    SHLD    FILNAM_R+6					;set Filename extension to blank
    POP     H
    JMP     L_MERGE_1
;
; BASIC SAVE "file"[,A]
;
L_SAVE_RAM:
    PUSH    H							;save txt ptr
    LHLD    FILNAM_R+6					;HL = Filename extension chars
    LXI     D,4F44H						;"DO"
    COMPAR								;HL - DE
    MVI     B,00H						;preload DO extension code
    JZ		+							;brif if extension == "DO"
    LXI     D,4142H						;"BA"
    COMPAR								;HL - DE
    MVI     B,01H						;preload BA extension code
    JZ		+							;brif extension == "BA"
    LXI     D,2020H						;"  "
    COMPAR								;HL - DE
    MVI     B,02H						;no extension code
    JNZ     R_GEN_NM_ERR_FUN			;Generate NM error
; B holds 0 (DO), 1 (BA) or 2 ("  ").
+	POP     H							;restore txt ptr
    PUSH    B							;save extension code
    DCX     H							;pre-decrement
    CHRGET								;Get next non-white char from M
    JZ      L_SAVE_RAM_1				;brif done
	SYNCHK	','
	SYNCHK	'A'
    POP     B							;reload extension code
    DCR     B
    JZ      R_GEN_NM_ERR_FUN			;brif not BASIC: Generate NM error (Bad Filename)
-	XRA     A
    LXI     D,0F802H					;E == Marker 2: Open for Output. D == RAM_DEV
    PUSH    PSW
    JMP     L_SAVE_ASC
L_SAVE_RAM_1:
    POP     B
    DCR     B
    JM      -
    CALL    L_IS_SUZUKI_DIR
    JNZ     R_GEN_FC_ERROR				;brif != 0: Generate FC error
    CALL    L_SET_EXT_BA				;set "BA" extension and find file
    CNZ     R_KILL_BA_FILE_2
    CALL    LNKFIL						;Fix up the directory start pointers
    CALL    L_FindFreeDirEntry
    SHLD    RAMDIRPTR_R					;store available directory entry ptr
    MVI     A,80H
    XCHG
    LHLD    TXTTAB_R					;Start of BASIC program pointer
    XCHG								;DE = Start of BASIC program pointer
    CALL    R_SAVE_TO_DIRECTORY			;Save new entry to Directory
    CALL    L_SET_MEM_TABLES
    JMP     R_GO_BASIC_RDY_OK			;Vector to BASIC ready - print Ok
;
; FILES statement
;
R_FILES_STMT:							;1F3AH
    PUSH    H
    CALL    R_DISPLAY_DIR				;Display Directory
    POP     H
    JMP     R_LCD_NEW_LINE				;Move LCD to blank line (send CRLF if needed)
;
; Display Directory while in BASIC
;
R_DISPLAY_DIR:							;1F42H
    LXI     H,RAMDIR_R-RAMDIRLEN		;Load address of RAM Directory (-1 entry, or 11 bytes)
L_DISPLAY_DIR_1:
    MVI     C,03H						;3 or 6 files per line
    LDA     LINWDT_R					;Active columns count (1-40)
    CPI     28H
    JZ      L_DISPLAY_DIR_2
    MVI     C,06H
L_DISPLAY_DIR_2:
	CALL    L_FindNextDirEntry			;Find Non-Empty directory entry
    RZ									;end of directory
    ANI     _DIR_INROM|_DIR_INVIS		;00011000B 18H
    JNZ     L_DISPLAY_DIR_2				;skip if file in ROM or INVISIBLE
    PUSH    H							;save directory ptr
    INX     H							;get Filestart ptr to DE
	GETDEFROMM
    PUSH    D							;save Filestart ptr
    MVI     B,06H						;Filename length (base part)
-	MOV     A,M
    OUTCHR								;Send character in A to screen/printer
    INX     H							;next char
    DCR     B
    JNZ		-							;loop if not done
    MVI     A,'.'						
    OUTCHR								;Send character in A to screen/printer
    MOV     A,M							;first extension char
    OUTCHR						    	;Send character in A to screen/printer
    INX     H
    MOV     A,M							;second extension char
    OUTCHR								;Send character in A to screen/printer
    POP     D							;reload Filestart ptr
    LHLD    TXTTAB_R					;Start of BASIC program pointer
    COMPAR								;HL - DE
    MVI     A,'*'						;2AH preload
    MVI     B,' '
    JZ		+							;brif Filestart ptr is BASIC program pointer
    MOV     A,B							;use ' ' is FALSE
+	OUTCHR								;Send character in A to screen/printer
    MOV     A,B
    OUTCHR								;Send character in A to screen/printer
    OUTCHR								;Send character in A to screen/printer
    POP     H							;reload directory ptr
    DCR     C							;max number of files per line
    JNZ     L_DISPLAY_DIR_2						;brif not max
    CALL    R_SEND_CRLF				    ;Send CRLF to screen or printer
    CALL    L_CHK_KEY_CTRL				;Test for CTRL-C or CTRL-S
    JMP     L_DISPLAY_DIR_1						;continue
;
; KILL statement
;
;
R_KILL_STMT:							;1F91H
    CALL    L_DEV_FILNAM				;process a filename. Returns device code in D
    DCX     H							;backup text ptr
    CHRGET								;Get next non-white char from M
    JNZ     R_GEN_SN_ERROR				;Generate Syntax error if more chars
    MOV     A,D							;device code
    CPI     RAM_DEV						;0F8H
    JZ      +							;brif RAM device
	RST38H	58H
+	PUSH    H							;save text ptr
    XRA     A
    STA     OPNFIL_R
    CALL    R_CLSALL					;Close Files
    CALL    LNKFIL						;Fix up the directory start pointers
    CALL    L_FND_DIR_ENTRY				;find directory entry for FILNAM_R
    JZ      R_GEN_FF_ERR_FUN			;brif not found: Generate FF error
; DE == Filestart ptr
    MOV     B,A							;save file type
    ANI     _DIR_COFILE					;20H isolate bit 5
    JNZ     L_KILL_CO_FILE_2			;kill a CO file if bit 5 set. text ptr on stack
    MOV     A,B							;restore file type
    ANI     _DIR_DOFILE					;40H isolate bit 6
    JZ      R_KILL_BA_FILE				;brif bit 6 clear: BASIC file
	SKIP_BYTE_INST						;HL already pushed
;
; Kill a text file
;
; IN:
;	HL ptr to Directory Entry
;	DE ptr to file data
;
KILASC:
    PUSH    H							;save Directory Entry ptr
    LXI     B,0							;clear file size
    MOV     M,C							;clear File type
; determine file size by finding EOF
    MOV     L,E							;store ptr to file data in HL
    MOV     H,D
-	LDAX    D							;get byte from file
    INX     D							;next
    INX     B							;file count
    CPI     1AH							;EOF
    JNZ     -
    CALL    MASDEL						;Delete BC bytes at M (start of file data). BC negated on exit.
;
; Update FOR loop chain with BC offset, fix up directory start pointers
; HL pushed
; IN:
;	BC		offset to add
;
KILASC_TAIL:
    CALL    L_UPD_FOR_LOOPS_1			;update FOR loop stack chain. BC is (negative) offset to add
    CALL    LNKFIL						;Fix up the directory start pointers
    POP     H							;restore Directory ptr or txt ptr
    RET
;
; Kill a CO file
;
; IN:
;	DE			ptr to File Data
;	HL
;
R_KILL_CO_FILE:
    PUSH    H
L_KILL_CO_FILE_2:
    MVI     M,00H
    LHLD    COSTRT_R					;CO files pointer
    PUSH    H							;save it. restore in KILASC_TAIL()
    XCHG								;DE to HL
    PUSH    H							;save ptr to file data (header + co file)
    INX     H							;advance to file size
    INX     H
    MOV     C,M							;BC = file size
    INX     H
    MOV     B,M
    LXI     H,0006H						;CO file header size
    DAD     B							;add file header size
    MOV     B,H							;result to BC
    MOV     C,L
    POP     H							;ptr to file data
    CALL    MASDEL						;Delete BC characters at M. BC negated on exit
    POP     H							;Directory entry ptr
    SHLD    COSTRT_R					;Update CO files pointer
    JMP     KILASC_TAIL					;exit with HL pushed
;
; Clear selection
;
L_CLR_SELECTION:
    CALL    LNKFIL						;Fix up the directory start pointers
    LHLD    RICKY_R+1					;File data ptr to DE
    XCHG
    LXI     H,RICKY_R					;Ricky part of directory to HL
    JMP     KILASC						;kill text file: DE & HL are inputs
;
; IN:
;
;	DE		Filestart ptr
;
R_KILL_BA_FILE:
    PUSH    H
    LHLD    TXTTAB_R					;Start of BASIC program pointer
    COMPAR								;HL - DE
    POP     H
    JZ      R_GEN_FC_ERROR				;Generate FC error if current program
    CALL    R_KILL_BA_FILE_2
    CALL    R_INIT_BASIC_VARS_2
    JMP     R_GO_BASIC_RDY_OK			;Vector to BASIC ready - print Ok
;
;  kill a BA file
;
; IN:
;	HL		ptr to Directory Entry
;	DE		Filestart ptr
;
R_KILL_BA_FILE_2:
    MVI     M,00H						;clear File type
    LHLD    TXTTAB_R					;Start of BASIC program pointer
    COMPAR								;HL - DE
    PUSH    PSW							;save result
    PUSH    D							;save Filestart ptr/BASIC program line ptr
    CALL    R_CHEAD						;Fixup all links. Find end of BASIC program.
; HL now points to 0000 next pointer
    POP     D							;restore Filestart ptr
    INX     H
    CALL    L_DEL_BYTES					;Delete Bytes between HL and DE
    PUSH    B							;save negated delete count
    CALL    LNKFIL					;Fix up the directory start pointers
    POP     B							;restore negated delete count
    POP     PSW							;COMPAR result
    RZ									;return if DE == HL at COMPAR
    RC
    LHLD    TXTTAB_R					;Start of BASIC program pointer
    DAD     B
    SHLD    TXTTAB_R					;Start of BASIC program pointer
    RET
;
; NAME statement (rename a RAM file)
; NAME FILE1 AS FILE2
;
R_NAME_STMT:							;2037H
    CALL    L_DEV_FILNAM				;process a filename to FILNAM_R.  Returns device code in D
    PUSH    D							;save FILE1 file type
    CALL    L_SWAPFILENAMES				;move FILNAM_R to FILNM2_R
	SYNCHK	'A'							;41H
	SYNCHK	'S'							;53H
    CALL    L_DEV_FILNAM				;process a filename to FILNAM_R.  Returns file type in D
    MOV     A,D							;FILE2 file type
    POP     D							;restore FILE1 file type
    CMP     D
    JNZ     R_GEN_FC_ERROR				;brif file types differ: Generate FC error
    CPI     RAM_DEV						;0F8H
    JZ      +							;brif file type == 0F8H
	RST38H	5AH
+	PUSH    H							;save Basic program ptr
    CALL    L_FND_DIR_ENTRY				;find directory entry for FILE2
    JNZ     R_GEN_FC_ERROR				;brif found: Generate FC error
    CALL    L_SWAPFILENAMES				;swap FILNAM_R and FILNM2_R
    CALL    L_FND_DIR_ENTRY				;find directory entry for FILE1
    JZ      R_GEN_FF_ERR_FUN			;brif not found: Generate FF error
    PUSH    H							;save directory entry
    LHLD    FILNAM_R+6					;Filename extension FILE1
    XCHG
    LHLD    FILNM2_R+6					;Filename extension FILE2
    COMPAR								;HL - DE
    JNZ     R_GEN_FC_ERROR			 	;Generate FC error
    POP     H							;restore directory entry
    CALL    L_SWAPFILENAMES				;swap FILNAM_R and FILNM2_R
    INX     H							;skip File type, ptr
    INX     H
    INX     H
    CALL    L_COPY_FILNAM
    POP     H							;restore Basic program ptr
    RET
;
; process a filename. Return device code
;
; OUT:
;	D		file type/device code
;
L_DEV_FILNAM:
    CALL    L_EVAL_FILNAM				;Evaluate arguments to RUN/OPEN/SAVE commands
    RNZ									;retif Device was specified
    MVI     D,RAM_DEV					;default file type/device code
    RET

L_IS_SUZUKI_DIR:
    LHLD    RAMDIRPTR_R
    LXI     D,SUZUKI_R					;Suzuki Directory Entry
    COMPAR								;HL - DE
    RET
;
; set CO extension and find file
;
L_SET_EXT_CO:
    LXI     B,434FH						;"CO"
    JMP     L_SET_EXT_FROM_BC
;
; R_FINDFILE
;	Find Directory Entry for 
;
; First Test for "  " or "DO" extension
;
R_FINDFILE:
    LHLD    FILNAM_R+6					;Filename extension
    LXI     D,2020H						;"  "
    COMPAR								;HL - DE
    JZ		+							;brif extension == "  "
    LXI     D,4F44H						;"DO"
    COMPAR								;HL - DE
    JNZ     R_GEN_NM_ERR_FUN			; Generate NM error if extension != "DO"
+	LXI     B,444FH						;"DO" extension
	JMP     L_SET_EXT_FROM_BC
;
; set extension to "BA" and find file
;
L_SET_EXT_BA:
    LXI     B,4241H						;"BA" extension
;
; set extension from BC and find file
;
L_SET_EXT_FROM_BC:
    LXI     H,FILNAM_R+6				;Filename extension
    MOV     M,B							;update
    INX     H
    MOV     M,C
;
; L_FND_DIR_ENTRY for FILNAM_R
;
; OUT:
;	Z		Entry not found
;	A		File type
;	DE		Filestart ptr
;	HL		Directory Entry
;
L_FND_DIR_ENTRY:
    LXI     H,RAMDIR_R-RAMDIRLEN		;Load address of RAM Directory (-1 entry, or 11 bytes)
	SKIP_BYTE_INST						;Sets A to 0AFH
L_FND_DIR_ENTRY_1:
    POP     H							;Previously found Non-Empty directory entry
    CALL    L_FindNextDirEntry			;Find next Non-Empty directory entry
    RZ									;end of directory
    PUSH    H							;save ptr for next iteration
    INX     H							;skip Filestart ptr
    INX     H
    LXI     D,FILNAM_R-1
    MVI     B,08H
;compare filenames
-	INX     D							;next filename to find
	INX     H							;next directory entry
    LDAX    D							;compare characters
    CMP     M
    JNZ     L_FND_DIR_ENTRY_1			;brif different: next entry
    DCR     B							;count
    JNZ     -							;loop if not done
; filenames match
    POP     H							;pop Directory Entry ptr
    MOV     A,M							;Filetype
    INX     H							;to Filestart ptr
	GETDEFROMMNOINC						;Filestart ptr to DE
    DCX     H							;back to directory entry
    DCX     H
    ANA     A							;test Filetype
    RET
; ====================================================
; Find Non-Empty directory entry
; IN:
;	HL points to previous Entry
; OUT:
;
;	new entry ptr in HL, type in A
;	Z if end of directory
; saves BC
; ====================================================
L_FindNextDirEntry:
    PUSH    B
    LXI     B,RAMDIRLEN					;000BH
    DAD     B							;next entry
    POP     B
    MOV     A,M
    CPI     0FFH						;end of directory?
    RZ									;return if TRUE
    ANA     A
    JP      L_FindNextDirEntry			;loop if A >= 0 (bit 7 clear)
    RET
;
; Find a bit 7 clear directory Entry: File killed, meaning entry available.
;
; OUT:
;	HL points to directory entry
;
L_FindFreeDirEntry:
    LDA     EDITFLG_R
    ANA     A
    LXI     H,RICKY_R					;Ricky part of directory, 1 entry before User Part
    RNZ									;return if editting
    LXI     H,USRRAM_R-RAMDIRLEN		;Same value as RICKY_R! Preload
    LXI     B,RAMDIRLEN					;000BH
-	DAD     B							;next entry
    MOV     A,M							;file type
    CPI     0FFH						;end of directory?
    JZ      R_GEN_FL_ERR_FUN			;Generate FL error if TRUE
    ADD     A							;double
    JC		-							;loop if bit 7 was set (entry not available)
    RET
;
; NEW statement
;
R_NEW_STMT:								;20FEH
    RNZ									;MAKE SURE THERE IS A TERMINATOR
; A == 0
SCRTCH:
    CALL    L_IS_SUZUKI_DIR
    CNZ     LNKFIL						;Fix up the directory start pointers
    LXI     H,SUZUKI_R					;Suzuki Directory Entry
    SHLD    RAMDIRPTR_R
    LHLD    SUZUKI_R+1					;BASIC program not saved pointer
    SHLD    TXTTAB_R					;Start of BASIC program pointer
    XRA     A
    MOV     M,A
    INX     H
    MOV     M,A
    INX     H
    XCHG
    LHLD    DOSTRT_R					;DO files pointer
    CALL    L_DEL_BYTES					;Delete Bytes between HL and DE
    LHLD    XXSTRT_R					;update XXSTRT_R
    DAD     B
    SHLD    XXSTRT_R
    LXI     H,0FFFFH					;TODO call L_INSRT_FFFF
    SHLD    PBUFIDX_R					;reset Paste Buffer Index
    JMP     R_INIT_BASIC_VARS			;Initialize BASIC Variables for new execution
;
L_DEL_LINES:
    LHLD    LASTLST_R					;Address where last BASIC list started
    XCHG								;lower address to DE
    LHLD    NXTLINE_R					;higher address
;
; Delete Bytes between HL and DE
;
L_DEL_BYTES:
    MOV     A,L							;BC = HL - DE
    SUB     E
    MOV     C,A
    MOV     A,H
    SBB     D
    MOV     B,A
    XCHG								;Put lower address in HL for the delete
    CALL    MASDEL 						;Delete BC characters at M. BC negated on exit.
    LHLD    DOSTRT_R					;DO files pointer
    DAD     B							;Update DO files pointer by negative delete length
    SHLD    DOSTRT_R					;DO files pointer
    RET
;
; Fix up the directory start pointers
;
; This routine fixes up all pointers from directory table entries 
; to the start of the associated file. To avoid overhead of 
; constantly updating these pointers, many operations defer
; calling LNKFIL to the end of the operation. It is the
; programmer's responsibility to ensure that LNKFIL is called
; when required. For instance, when a file is deleted, all link 
; pointers should be fixed up before performing further I/O.
;
; Mark the all valid directory flag (turn 0 bit of all valid directory flag)
; Get the lowest file address
; Get the lowest link pointer in the valid file's directory
; Save the link pointer
; Search the lowest link pointer in the marked files in directory area
; Save the saved link pointer at this marked filesm link pointer field
; Clear the mark from the directory flag of that file (turn off bit 0)
; Get next lowest file address from the bottom of RAM
; Go back to step 5 unless the mark been removed from all directory flags?
; Return
;
; When the top address of the next file is searched, the pointers
; ASCTAB and BINTAB are useful to know what kind of file is currently being searched.
;
LNKFIL:									;2146H
    XRA     A							;preload BASIC file type (BA=0)
    STA     FILTYP_R					
    LHLD    LOMEM_R						;Lowest RAM address used by system
    INX     H
; HL is "Min address"
LNKFIL_LOOP:
    PUSH    H							;save "Min address" 
    LXI     H,RAMDIR_R+4*RAMDIRLEN		;skip ROM entries
    LXI     D,0FFFFH					;end of memory
-	CALL    L_FindNextDirEntry			;Find Non-Empty directory entry
    JZ      LNKFIL_2					;end of directory
    RRC									;bit 0 of type to carry
;Jump to get next entry if LSBit of file type is set - skip these.
    JC      -							;brif bit 0 was set
    PUSH    H							;save ptr to Directory Entry
    INX     H							;skip File Type
	GETHLFROMM							;get File Data ptr to HL
    COMPAR								;HL - DE
    POP     H							;restore ptr to Directory Entry
    JNC     -							;brif HL >= DE
    MOV     B,H							;Save address of file with lowest address in BC
    MOV     C,L
    INX     H
	GETDEFROMMNOINC						;get File Data ptr to DE (again)
    DCX     H							;backup ptr to Directory Entry
    DCX     H
    JMP     -
; 
; Catalog entry with the lowest File RAM address found.
; Mark the LSBit of that file's directory entry type byte.
; 
LNKFIL_2:
    MOV     A,E							;test DE for 0FFFFH
    ANA     D
    INR     A
    POP     D							;restore "Min address" address
;If FFFFH, Clear LSBit of File Type byte for all Directory entries.
    JZ      LNKFIL_3									
    MOV     H,B							;saved Directory Entry Ptr to HL
    MOV     L,C
    MOV     A,M							;get File Type
    ORI     01H							;set bit 0: File Data ptr updated
    MOV     M,A							;update
; Update File Data ptr for this Directory Entry with "Min address" address
    INX     H
    MOV     M,E
    INX     H
    MOV     M,D
    XCHG								;"Min address" address to HL
    CALL    L_FIND_EOF
    JMP     LNKFIL_LOOP						;scan again
;
; clear bit 0 of type for every directory entry
;
LNKFIL_3:
    LXI     H,RAMDIR_R-RAMDIRLEN		;Load address of RAM Directory (-1 entry, or 11 bytes)
-	CALL    L_FindNextDirEntry			;Find Non-Empty directory entry
    RZ									;end of directory
    ANI     0FEH						;clear bit 0 of type
    MOV     M,A							;update
    JMP     -
; 
; Advance HL past end of current file based on type
;
; IN:
;	HL		File Data Ptr
; OUT:
;	HL		ptr past EOF
; 
L_FIND_EOF:
    LDA     FILTYP_R					
    DCR     A
    JM      L_BA_EOF					;Jump if BA (BA=0)
    JZ      L_DO_EOF					;Jump if DO (DO=1)
; 
; Advance HL past end of CO file
; 
    INX     H							;Skip load address of CO file
    INX     H
	GETDEFROMM							;Get length of CO file
    INX     H							;Skip entry of CO file
    INX     H							;Increment again to get past end of file
    DAD     D							;Offset to end of file by adding length
    RET
; 
; Advance HL past end of DO file
; 
L_DO_EOF:
    MVI     A,1AH						;Find end of file
-	CMP     M
    INX     H
    JNZ     -
    XCHG
    LHLD    COSTRT_R					;CO files pointer to DE
    XCHG
    COMPAR								;Compare CO files pointer and ptr past EOF: HL - DE
    RNZ									;retif not the same
    MVI     A,02H						;At end of DO. Change type to CO
    STA     FILTYP_R					;and save it
    RET
; 
; Update line addresses for BA and advance HL to end of file
; 
L_BA_EOF:
    XCHG								;BASIC program line ptr to DE
    CALL    R_CHEAD						;Fix Basic Lines structure, find EOF
    INX     H
    XCHG
    LHLD    DOSTRT_R					;DO files pointer to DE
    XCHG
    COMPAR								;Compare DO files pointer and end of Basic program ptr: HL - DE
    RNZ									;retif not the same
    MVI     A,01H						;Indicate we are now in DO file space
    STA     FILTYP_R					;and save it		
    RET

L_SET_MEM_TABLES:
    LHLD    VARTAB_R					;Start of variable data pointer
    SHLD    ARYTAB_R					;ptr to Start of array table
    SHLD    STRGEND_R					;Unused memory pointer
    LHLD    DOSTRT_R					;DO files pointer
    DCX     H
    SHLD    SUZUKI_R+1					;BASIC program not saved pointer
    INX     H
    LXI     B,0002H
    XCHG
    CALL    L_MOV_DATA					;Move all files / variables after this file
    XRA     A
    MOV     M,A
    INX     H
    MOV     M,A
    LHLD    DOSTRT_R					;DO files pointer
    DAD     B
    SHLD    DOSTRT_R					;DO files pointer
    JMP     LNKFIL						;Fix up the directory start pointers
;
; Count length of string at M
;
; OUT:
;	E		string length
;
R_STRLEN:								;21FAH
    PUSH    H							;save string ptr
    MVI     E,0FFH						;pre-decrement
-	INR     E
    MOV     A,M
    INX     H
    ANA     A
    JNZ     -
    POP     H							;restore string ptr
    RET
;
; Get .DO filename and locate in RAM directory
;
R_GET_FIND_DO_FILE:						;2206H
    CALL    R_STRLEN				    ;Count length of string at M
    CALL    L_PSH_HL_EVAL_FILNAM		;push HL and eval Filename
    JNZ     R_GEN_SN_ERROR				;Generate Syntax error
;
; Open a text file at FILNAM_R for OUTPUT
;
; OUT:
;	DE
;	carry		Set if file already exists
;
R_MAKTXT:
R_OPEN_TXT_FILE_OUTPUT:					;220FH
    CALL    LNKFIL						;Fix up the directory start pointers
    CALL    R_FINDFILE
    XCHG								;Directory ptr to DE
    STC									;set carry
    RNZ									;retif File exists
    CALL    L_FindFreeDirEntry
    PUSH    H							;save ptr to free directory entry
    LHLD    DOSTRT_R					;DO files pointer
    PUSH    H							;save
    MVI     A,1AH						;^Z
    CALL    R_INSERT_A_INTO_FILE		;Insert A into text file at M
    JC      L_OUTOFMEMORY
    POP     D							;DO files pointer		
    POP     H							;ptr to free directory entry
    PUSH    H							;save again
    PUSH    D
    MVI     A,0C0H						;filetype 11000000: busy|DO file
    DCX     D
    CALL    R_SAVE_TO_DIRECTORY			;Save new entry to Directory
    CALL    LNKFIL						;Fix up the directory start pointers
    POP     H
    POP     D
    ANA     A
    RET
;
; Save new entry to Directory
;
; IN:
;	HL		Directory Entry Pointer
;	A		File type
;	DE		File start address
;
R_SAVE_TO_DIRECTORY:					;2239H
    PUSH    D
    MOV     M,A							;store A, DE to M
    INX     H
    MOV     M,E
    INX     H
    MOV     M,D
    INX     H
	SKIP_BYTE_INST						;Sets A to 0AFH
L_COPY_FILNAM:							;HL Directory Entry Pointer
    PUSH    D
    LXI     D,FILNAM_R					;Current Filename
    MVI     B,08H						;Filename length incl. extension
    CALL    R_MOVE_B_BYTES_INC       	;Move B bytes from (DE) to M with increment
    POP     D
    RET

L_SWAPFILENAMES:
    PUSH    H
    MVI     B,09H
    LXI     D,FILNAM_R				   	;Current Filename
    LXI     H,FILNM2_R				    ;Filename of last program loaded from tape
-	MOV     C,M
    LDAX    D
    MOV     M,A
    MOV     A,C
    STAX    D
    INX     D
    INX     H
    DCR     B
    JNZ     -
    POP     H
    RET
;
; Clear Paste Buffer
;
L_CLR_PASTE_BUF:
    CALL    LNKFIL						;Fix up the directory start pointers
    LXI     H,0FFFFH					;TODO call L_INSRT_FFFF
    SHLD    PBUFIDX_R					;set Paste Buffer Index
    MOV     B,H							;set BC to 0FFFFH preinc value
    MOV     C,L
    LHLD    HAYASHI_R+1					;Start of Paste Buffer
    PUSH    H							;save Start of Paste Buffer
    MVI     A,1AH						;^Z
-	CMP     M							;locate ^Z
    INX     B							;count
    INX     H							;next
    JNZ     -
    POP     H							;reload Start of Paste Buffer
    CALL    MASDEL						;Delete BC characters at M. BC negated on exit.
    JMP     LNKFIL						;Fix up the directory start pointers
;
; CSAVE statement
;
; CSAVE "filename"[,A]
; CSAVEM "filename",start,end[,entry]
; 
;
R_CSAVE_STMT:							;2280H
    CPI     'M'							;4DH
    JZ      R_CSAVEM_STMT				;CSAVEM statement CO file
    CALL    L_CLOAD_ARGS_2				;Filename required
L_CSAVE_BAS:
    DCX     H							;backup txt ptr
    CHRGET								;Get next non-white char from M
    JZ      L_CSAVE_CRUNCHED			;brif done
	SYNCHK	','
	SYNCHK	'A'
    MVI     E,02H						;set File Mode to output. D must be device type
    ANA     A							;set flags
    PUSH    PSW
    JMP     L_SAVE_ASC

L_CSAVE_CRUNCHED:
    CALL    R_UPDATE_LINE_ADDR         	;Update line addresses for current BASIC program
    XCHG								;to DE
    LHLD    TXTTAB_R					;Start of BASIC program pointer
    MOV     A,E							;HL = DE - HL
    SUB     L
    MOV     L,A
    MOV     A,D
    SBB     H
    MOV     H,A
    DCX     H
    MOV     A,H							;test HL
    ORA     L
    JZ      R_POP_GO_BASIC_RDY         	;if HL == 0 => Pop stack and vector to BASIC ready
    SHLD    LASTLEN_R					;Length of last program loaded/saved
    PUSH    H
    CALL    R_CAS_OPEN_OUT_BA			;Open CAS for output of BASIC files
    CALL    L_PREP_DATA_BLK				;prepare cassette sync header
    POP     D
    LHLD    TXTTAB_R					;Start of BASIC program pointer
;
; Save buffer at M to tape
;
R_CAS_WRITE_BUF:						;22B9H
    MVI     C,00H						;new checksum
-	MOV     A,M
    CALL    R_CAS_WRITE_BYTE			;Write byte to tape & update checksum
    INX     H
    DCX     D
    MOV     A,D
    ORA     E
    JNZ     -
    CALL    L_CAS_FIN_BLK				;finish cassette block
    JMP     R_POP_GO_BASIC_RDY       	;Pop stack and vector to BASIC ready
;
; SAVEM statement
;
; SAVEM "filespec", start, end [,entry] 
;
R_SAVEM_STMT:							;22CCH
    CHRGET								;Get next non-white char from M
    CALL    L_DEV_FILNAM				;process a filename. Returns device code in D
    MOV     A,D							;device code
    CPI     CAS_DEV						;0FDH
    JZ      L_CSAVE_2					;brif file type == CAS_DEV to CSAVEM
    CPI     RAM_DEV						;0F8H	device code
    JZ      L_SAVEM_RAMFILE				;brif file type == RAM_DEV
	RST38H	5CH
;
; CSAVEM statement
;
; CSAVEM "filespec", start, end [,entry] 
;
R_CSAVEM_STMT:							;22DDH
    CHRGET								;Get next non-white char from M
    CALL    L_CLOAD_ARGS_2				;Filename required
L_CSAVE_2:
    CALL    R_PROC_SAVEM_ARGS			;Process SAVEM Arguments to LOADADR_R, LASTLEN_R and LASTSTRT_R
    CALL    R_CAS_OPEN_OUT_CO			;Open CAS for output of CO files
    CALL    L_PREP_DATA_BLK				;prepare cassette sync header
    LHLD    LASTLEN_R					;Length of last program loaded/saved
    XCHG								;to DE
    LHLD    LOADADR_R					;'Load address' of current program
    JMP     R_CAS_WRITE_BUF				;Save buffer at M to tape
;
; SAVEM to RAM file
;
L_SAVEM_RAMFILE:
    CALL    R_PROC_SAVEM_ARGS			;Process SAVEM Arguments to LOADADR_R,
										;	LASTLEN_R and LASTSTRT_R
    CALL    LNKFIL						;Fix up the directory start pointers
    CALL    L_SET_EXT_CO				;set CO extension and find file
    CNZ     R_KILL_CO_FILE				;calif file already exist: delete file. HL & DE args
    CALL    L_FindFreeDirEntry
    PUSH    H							;save available directory entry ptr
    LHLD    COSTRT_R					;CO files pointer
    PUSH    H							;save CO files pointer
    LHLD    LASTLEN_R					;Length of last program loaded/saved
    MOV     A,H							;test HL
    ORA     L
    JZ      L_OUTOFMEMORY				;brif LASTLEN_R == 0
    PUSH    H							;save LASTLEN_R
    LXI     B,0006H						;size of file header
    DAD     B							;HL = LASTLEN_R + 6
    MOV     B,H							;BC = HL
    MOV     C,L
    LHLD    VARTAB_R					;Start of variable data pointer
    SHLD    LSTVAR_R					;Address of last variable assigned
    CNC     MAKHOL						;Insert BC spaces at M (create hole)
    JC      L_OUTOFMEMORY				;brif if no space
    XCHG								;hole ptr to DE
    LXI     H,LOADADR_R				    ;'Load address' of current program
    CALL    R_MOVE_6_BYTES				;header from M to (DE)
    LHLD    LOADADR_R					;'Load address' of current program: source
    POP     B							;LASTLEN_R
    CALL    R_MOVE_BC_BYTES_INC         ;Move BC bytes from M to (DE) with increment
    POP     H							;restore CO files pointer
    SHLD    COSTRT_R					;CO files pointer
    POP     H							;restore available directory entry ptr
    MVI     A,0A0H						;file type
    XCHG
    LHLD    LSTVAR_R					;DE = file start address
    XCHG
    CALL    R_SAVE_TO_DIRECTORY			;Save new entry to Directory
    CALL    LNKFIL					;Fix up the directory start pointers
    JMP     R_GO_BASIC_RDY_OK			;Vector to BASIC ready - print Ok
;
; Process SAVEM Arguments
;
; ,start, end [,entry]
;
; Store args in LOADADR_R, LASTLEN_R and LASTSTRT_R
;
R_PROC_SAVEM_ARGS:						;2346H
    CALL    L_GET_ADDRESS				;get start address to DE
    PUSH    D							;save
    CALL    L_GET_ADDRESS				;get end address to DE
    PUSH    D							;save
    DCX     H
    CHRGET								;Get next non-white char from M
    LXI     D,0							;preset entry address
    CNZ     L_GET_ADDRESS				;if chars, get entry address to DE
    DCX     H
    CHRGET								;Get next non-white char from M
    JNZ     R_GEN_SN_ERROR				;if more characters, Generate Syntax error
    XCHG								;entry address to HL
    SHLD    LASTSTRT_R					;store entry address
    POP     D							;end address
    POP     H							;start address
    SHLD    LOADADR_R					;save 'Load address'
    MOV     A,E							;compute length = end address - start address + 1
    SUB     L
    MOV     L,A
    MOV     A,D
    SBB     H
    MOV     H,A
    JC      R_GEN_FC_ERROR				;if negative length, Generate FC error
    INX     H
    SHLD    LASTLEN_R					;Length of last program loaded/saved
    RET

L_GET_ADDRESS:
	SYNCHK	','
    JMP     R_EVAL_EXPR_2				;Evaluate expression at M_2, return to caller
;
; CLOAD statement
;
R_CLOAD_STMT:							;2377H
    CPI     'M'							;4DH
    JZ      R_CLOADM_STMT				;CLOADM statement
    CPI     _PRINT						;? token
    JZ      L_CLOAD_VERIFY
    CALL    L_CLOAD_ARGS				;Evaluate arguments to CLOAD/CLOADM & Clear current BASIC program
    ORI     0FFH						;set A to 0FFH, set flags
    PUSH    PSW
L_CLOAD_STMT_1:
    POP     PSW							;retrieve mode
    PUSH    PSW
    JNZ     +							;brif called from R_CLOAD_STMT
    DCX     H
    CHRGET								;Get next non-white char from M
    JNZ     R_GEN_FC_ERROR				;Generate FC error
+	DCX     H
    CHRGET								;Get next non-white char from M
    MVI     A,00H
    STC									;clear carry
    CMC
    JZ      +							;brif CHRGET returned 0
	SYNCHK	','
	SYNCHK	'R'							;run program after loading
    JNZ     R_GEN_SN_ERROR				;Generate Syntax error
    POP     PSW							;retrieve mode
    STC									;set carry to indicate run program after loading
    PUSH    PSW							;save mode
    MVI     A,80H
+	PUSH    PSW
    STA     OPNFIL_R
L_CLOAD_STMT_3:
    CALL    R_CAS_OPEN_IN				;
    CPI     0D3H						;BA marker
    JZ      +
    CPI     9CH							;DO marker
    JZ      L_CLOAD_DO_FILE
L_CLOAD_STMT_4:
    CALL    L_CAS_PRINT_SKIP			;Print program on tape being skipped
    JMP     L_CLOAD_STMT_3				;continue
;
; BASIC File
;
+	POP     B
    POP     PSW
    PUSH    PSW
    PUSH    B
    JZ      L_CLOAD_STMT_4
    POP     PSW
    POP     PSW
    SBB     A
    STA     EXCFLG_R
    CALL    L_CAS_PRINT_FOUND			;print name of program found
    CALL    SCRTCH						;do NEW
    LHLD    LASTLEN_R					;Length of last program loaded/saved
    PUSH    H							;length to read
    MOV     B,H
    MOV     C,L
    LHLD    TXTTAB_R					;Start of BASIC program pointer
    PUSH    H							;buffer ptr to store
    CALL    MAKHOL						;Insert BC spaces at M
    JC      L_OUTOFMEMORY
    LXI     H,R_CLOAD_ONERR
    SHLD    ACTONERR_R					;active ON ERROR handler vector
    LHLD    DOSTRT_R					;DO files pointer
    DAD     B							;add length of hole
    SHLD    DOSTRT_R					;update DO files pointer
    CALL    L_FND_CAS_DATA_BLK
    POP     H							;buffer ptr to store
    POP     D							;length to read
    CALL    R_CAS_READ_REC				;Load record from tape and store at M
    JNZ     R_CLOAD_ONERR				;On-error return handler for CLOAD statement
    MOV     L,A
    MOV     H,A
    SHLD    ACTONERR_R					;active ON ERROR handler vector
    CALL    R_CAS_MOTOR_OFF				;Turn cassette motor off
    CALL    R_LCD_NEW_LINE				;Move LCD to blank line (send CRLF if needed)
    CALL    R_UPDATE_LINE_ADDR         	;Update line addresses for current BASIC program
    CALL    R_INIT_BASIC_VARS			;Initialize BASIC Variables for new execution
    LDA     EXCFLG_R
    ANA     A
    JNZ     L_NEWSTT					;Execute BASIC program
    JMP     R_GO_BASIC_RDY_OK			;Vector to BASIC ready - print Ok
;
; Load record from tape and store at M, length DE
;
R_CAS_READ_REC:							;2413H
    MVI     C,00H
-	CALL    R_CAS_READ_BYTE				;Read byte from tape & update checksum
    MOV     M,A							;store
    INX     H							;next
    DCX     D							;count
    MOV     A,D
    ORA     E
    JNZ     -							;loop
    CALL    R_CAS_READ_BYTE				;Read byte from tape & update checksum
    MOV     A,C
    ANA     A
    RET
;
; On-error return handler for CLOAD statement
;
R_CLOAD_ONERR:							;2426H
    CALL    SCRTCH
    LXI     H,0
    SHLD    ACTONERR_R					;active ON ERROR handler vector
    JMP     L_CAS_IO_ERROR
;
; DO marker found.
; 2 times PSW on stack
;
L_CLOAD_DO_FILE:
    CALL    L_CAS_PRINT_FOUND			;Print selected program/file "Found" on tape
    CALL    R_LCD_NEW_LINE				;Move LCD to blank line (send CRLF if needed)
    LHLD    FCBTBL_R					;File number description table pointer
	GETHLFROMM							;get first ptr to HL
    SHLD    FCBLAST_R					;FCB ptr for the last file used (2 bytes)
    MVI     M,01H						;set "open for input"
    INX     H							;+4 to File device
    INX     H
    INX     H 
    INX     H
    MVI     M,CAS_DEV					;0FDH device code
    INX     H							;+6
    INX     H
    XRA     A							;clear Offset from buffer start
    MOV     M,A
    INX     H							;+7 (FILPOS_IN_FCB_OFS)
    MOV     M,A							;clear LSB of Relative position of next block
    STA     CASFILSTAT_R				;clear
    JMP     L_MERGE_3
;
; CLOAD VERIFY
;
L_CLOAD_VERIFY:
    CALL    L_CLOAD_ARGS_1
    PUSH    H
    CALL    R_CAS_OPEN_IN_BA			;Open CAS for input of BASIC files
    CALL    L_FND_CAS_DATA_BLK
    LHLD    LASTLEN_R					;Length of last program loaded/saved
    XCHG
    LHLD    TXTTAB_R					;Start of BASIC program pointer
    CALL    L_CMP_CAS_DATA
    JNZ     R_GEN_VERIFY_FAIL_ERR     	;Generate Verify Failed error
    MOV     A,M
    INX     H
    ORA     M
    JNZ     R_GEN_VERIFY_FAIL_ERR     	;Generate Verify Failed error
-	CALL    R_CAS_MOTOR_OFF				;Turn cassette motor off
    POP     H
    RET
;
; Generate Verify Failed error
;
R_GEN_VERIFY_FAIL_ERR:				    ;2478H
    LXI     H,L_VERIFY_ERR				;Code Based. 
    CALL    R_PRINT_STRING_2			;Print_2 buffer at M until NULL or '"'
    JMP     -

L_VERIFY_ERR:
    DB      "Verify failed",0DH,0AH,00H
;
; LOADM and RUNM statement
;
; Load or Run a Machine Language program
;
; IN:
;	marker on top of stack
;
R_LOADM_STMT:							;2491H
    CHRGET								;Get next non-white char from M
    POP     PSW							;get marker
    PUSH    PSW							;save marker again
    JZ      R_GEN_FC_ERROR				;Generate FC error
    CALL    L_DEV_FILNAM				;process a filename.  Returns device code in D
    MOV     A,D							;get Device Code
    CPI     CAS_DEV						;0FDH
    JZ      L_CLOADM_2
    CPI     RAM_DEV						;0F8H
    JZ      L_LOADM_RAM
	RST38H	5EH
;
; LOADM "file" with no Device Specification (like CAS: or RAM:)
; Treat as cassette load but allow PRINT???
;
;
; CLOADM statement
; also CLOADM?
;
R_CLOADM_STMT:							;24A7H
    CHRGET								;Get next non-white char from M
    CPI     _PRINT						;? token
    JZ      L_CMP_CAS_PROG
    CALL    L_CLOAD_ARGS				;Evaluate arguments to CLOAD/CLOADM & Clear current BASIC program
    ORI     0FFH						;set A == 0FFH
    PUSH    PSW							;marker
L_CLOADM_2:
    DCX     H							;backup text ptr
    CHRGET								;Get next non-white char from M
    JNZ     R_GEN_SN_ERROR				;brif not end_of_line: Generate Syntax error
    PUSH    H
    CALL    R_CAS_OPEN_IN_CO			;Open CAS for input of CO files
    LHLD    LASTSTRT_R					;Start of last program
    MOV     A,H							;test it
    ORA     L
    JNZ     +							;brif LASTSTRT_R != NULL
    POP     H							;retrieve LASTSTRT_R
    POP     PSW							;marker
    PUSH    PSW
    PUSH    H
    JC      R_GEN_FC_ERROR				;Generate FC error
+	CALL    L_PRNT_HDR_CMP_HIMEM		;print .CO file header and check memory
    JC      L_OUTOFMEMORY				;brif 'Load address' < HIMEM
    CALL    L_FND_CAS_DATA_BLK
    LHLD    LASTLEN_R					;Length of last program loaded/saved
    XCHG
    LHLD    LOADADR_R					;'Load address' of current program
    CALL    R_CAS_READ_REC				;Load program from tape and store at M
    JNZ     L_CAS_IO_ERROR
    CALL    R_CAS_MOTOR_OFF				;Turn cassette motor off
    JMP     L_LOADM_END					;clean-up stack
;
; LOADM or RUNM a RAM file
;
L_LOADM_RAM:
    PUSH    H
    CALL    LNKFIL						;Fix up the directory start pointers
    CALL    L_SET_EXT_CO				;set CO extension and find file
    JZ      R_GEN_FF_ERR_FUN			;Generate FF error if no file
    XCHG
    CALL    R_LOAD_CO_HEADER			;Copy .CO 6-byte header to Current Program Area
    PUSH    H
    LHLD    LASTSTRT_R					;Start of last program
    MOV     A,H							;test HL
    ORA     L
    JNZ     +							;brif HL != 0
    POP     D							;reload + push again
    POP     H
    POP     PSW
    PUSH    PSW
    PUSH    H
    PUSH    D
    JC      R_GEN_FC_ERROR				;Generate FC error
+	CALL    L_PRNT_HDR_CMP_HIMEM		;print .CO file header and check memory
    JC      L_OUTOFMEMORY				;brif 'Load address' < HIMEM
    LHLD    LASTLEN_R					;Length of last program loaded/saved
    MOV     B,H
    MOV     C,L
    LHLD    LOADADR_R					;'Load address' of current program
    XCHG
    POP     H
    CALL    R_MOVE_BC_BYTES_INC        	;Move BC bytes from M to (DE) with increment
L_LOADM_END:
    POP     H
    POP     PSW
    JNC     R_INIT_BASIC_VARS_2
    CALL    R_INIT_BASIC_VARS_2
    LHLD    LASTSTRT_R					;Start of last program
    SHLD    LSTCAL_R					;Address last called
    CALL    LSTCAL_R-1					;0F660H contains JMP to Address last called
    LHLD    LSTVAR_R					;Address of last variable assigned
    JMP     L_NEWSTT					;Execute BASIC program

L_PRNT_HDR_CMP_HIMEM:
    CALL    L_PRINT_CO_INFO
R_CMP_HIMEM:
    LHLD    HIMEM_R						;HIMEM
    XCHG
    LHLD    LOADADR_R					;'Load address' of current program
    COMPAR								;Compare HIMEM (DE) and 'Load address' (HL): HL - DE
    RET
;
; Copy .CO 6-byte header to Current Program Area
;
R_LOAD_CO_HEADER:						;253DH
    LXI     D,LOADADR_R				  	;'Load address' of current program
R_MOVE_6_BYTES:
    MVI     B,06H
;
;Move B bytes from M to (DE)
; Could use XCHG call R_MOVE_B_BYTES_INC XCHG
; Updates DE, HL.
;
; OUT:
;	B		0
;
R_MOVE_B_BYTES:							;2542H
    MOV     A,M
    STAX    D
    INX     H
    INX     D
    DCR     B
    JNZ     R_MOVE_B_BYTES				;Move B bytes from M to (DE)
    RET
;
; Launch .CO files from MENU
;
; Allows VT100 initializer to be loaded without CLEAR statement
;
; TODO: allow Position Independent .CO file to be run from RAM file directly
;
;
R_EXEC_CO_FILE:							;254BH
    CALL    R_LOAD_CO_HEADER			;Copy .CO 6-byte header to Current Program Area
    PUSH    H
	call	R_CMP_HIMEM
    JC      L_BELOW_HIMEM				;brif 'Load address' < HIMEM
    XCHG
    LHLD    LASTLEN_R					;Length of last program loaded/saved
    MOV     B,H
    MOV     C,L
    POP     H
    CALL    R_MOVE_BC_BYTES_INC        	;Move BC bytes from M to (DE) with increment
    LHLD    LASTSTRT_R					;Start of last program
    MOV     A,H
    ORA     L
    SHLD    LSTCAL_R					;Address last called
    CNZ     LSTCAL_R-1					;0F660H contains JMP to Address last called
    JMP     R_MENU_ENTRY				;MENU Program

L_BELOW_HIMEM:
    CALL    R_BEEP_STMT				  	;BEEP statement
    JMP     R_MENU_ENTRY				;MENU Program

L_CMP_CAS_PROG:
    CHRGET								;Get next non-white char from M
    CALL    L_CLOAD_ARGS				;Evaluate arguments to CLOAD/CLOADM & Clear current BASIC program
    PUSH    H							;save txt ptr
    CALL    R_CAS_OPEN_IN_CO			;Open CAS for input of CO files
    CALL    L_FND_CAS_DATA_BLK
    LHLD    LASTLEN_R					;Length of last program loaded/saved to DE
    XCHG
    LHLD    LOADADR_R					;'Load address' of current program
    CALL    L_CMP_CAS_DATA
    JNZ     R_GEN_VERIFY_FAIL_ERR     	;Generate Verify Failed error
    CALL    R_CAS_MOTOR_OFF				;Turn cassette motor off
    POP     H							;restore txt ptr
    RET

L_CMP_CAS_DATA:
    MVI     C,00H
-	CALL    R_CAS_READ_BYTE				;Read byte from tape & update checksum
    CMP     M
    RNZ
    INX     H							;next data
    DCX     D							;count
    MOV     A,D							;test DE
    ORA     E
    JNZ		-							;brif DE != 0
    CALL    R_CAS_READ_BYTE				;Read byte from tape & update checksum
    MOV     A,C
    ANA     A
    RET

; 
; Print .CO information to LCD (start address, etc.)
; 
L_PRINT_CO_INFO:
    LHLD    CURLIN_R					;Currently executing line number
    INX     H							;test for 0FFFFH
    MOV     A,H							;test HL
    ORA     L
    RNZ									;return if CURLIN_R  != 0FFFFH
    LHLD    LOADADR_R					;'Load address' of current program
    PUSH    H							;save Load address
    XCHG								;to DE
    LXI     H,L_Top_MSG					;Code Based. 
    CALL    L_PRINT_PROPS
    LHLD    LASTLEN_R					;Length of last program loaded/saved
    DCX     H							;Adjust for last position
    POP     D							;restore Load address
    DAD     D							;compute End address
    XCHG								;to DE
    LXI     H,L_End_MSG					;Code Based. 
    CALL    L_PRINT_PROPS
    LHLD    LASTSTRT_R					;Start of last program
    MOV     A,H							;test HL
    ORA     L
    RZ									;return if HL == 0
    XCHG								;to DE
    LXI     H,L_Exe_MSG					;Code Based. 
; DE contains address to print
L_PRINT_PROPS:
    PUSH    D
    CALL    R_PRINT_STRING_2			;Print_2 buffer at M until NULL or '"'
    POP     H
    JMP     R_PRINT_HL_ON_LCD			;Print binary number in HL at current position

L_Top_MSG:
    DB      "Top: ",00H

L_End_MSG:
    DB      "End: ",00H

L_Exe_MSG:
    DB      "Exe: ",00H
;
; Evaluate arguments to CLOAD/CLOADM & Clear current BASIC program
;
L_CLOAD_ARGS:
    DCX     H							;backup txt ptr
L_CLOAD_ARGS_1:
    CHRGET								;Get next non-white char from M
    JNZ     L_CLOAD_ARGS_2				;brif possible filename
; no filename. Set FILNAM_R to blanks
    MVI     B,06H
    LXI     D,FILNAM_R				    ;Current Filename
    MVI     A,' '
-	STAX    D
    INX     D
    DCR     B
    JNZ     -							;brif not done
    JMP     L_CLOAD_ARGS_3

L_CLOAD_ARGS_2:
    CALL    L_EVAL_FILNAM				;Evaluate arguments to RUN/OPEN/SAVE commands
    JNZ     +							;brif Device was specified
L_CLOAD_ARGS_3:
    MVI     D,CAS_DEV					;0FDH set device code
+	MOV     A,D
    CPI     CAS_DEV						;0FDH
    JNZ     R_GEN_FC_ERROR				;Generate FC error if not cassette
    RET
;
; Open CAS for output of BASIC files
;
R_CAS_OPEN_OUT_BA:						;260BH
    MVI     A,0D3H
	SKIP_2BYTES_INST_BC
;
; Open CAS for output of TEXT files
; 1 byte 09CH marker
; rest as R_CAS_OPEN_OUT_CO
;
R_CAS_OPEN_OUT_DO:						;260EH
    MVI     A,9CH						;DO file marker
	SKIP_2BYTES_INST_BC
;
; Open CAS for output of CO files
;
; 1 byte 0D0H marker
; 6 byte filename
; 10 byte header (load data)
; 1 byte checksum
; 20 bytes 0 padding
;
R_CAS_OPEN_OUT_CO:						;2611H
    MVI     A,0D0H						;CO file marker
    PUSH    PSW							;save file marker
    CALL    R_DET_CAS_SYNC_HDR       	;Turn cassette motor on and detect sync header
    POP     PSW							;restore file marker
    CALL    R_CAS_WRITE_BYTE			;Write file marker to tape & update checksum
    MVI     C,00H						;clear checksum
; first loop
    LXI     H,FILNAM_R				  	;Current Filename
    LXI     D,0602H						;D == 6 filename chars E == 2 loops
-	MOV     A,M
    CALL    R_CAS_WRITE_BYTE			;Write byte to tape & update checksum
    INX     H
    DCR     D
    JNZ     -
; second loop
    LXI     H,LOADADR_R				  	;'Load address' of current program
    MVI     D,0AH						;10 bytes load address
    DCR     E
    JNZ     -
; finish cassette block
L_CAS_FIN_BLK:							;C is argument for this entry point
    MOV     A,C							;checksum
    CMA									;two's complement
    INR     A
    CALL    R_CAS_WRITE_BYTE			;Write checksum to tape
    MVI     B,20						;14H padding
-	XRA     A
    CALL    R_CAS_WRITE_BYTE			;Write byte to tape & update checksum
    DCR     B
    JNZ     -
    JMP     R_CAS_MOTOR_OFF				;Turn cassette motor off & return

L_PREP_DATA_BLK:						;prepare cassette sync header
    CALL    R_DET_CAS_SYNC_HDR       	;Turn cassette motor on and detect sync header
    MVI     A,8DH						;Data Block marker
    JMP     R_CAS_WRITE_BYTE			;Write byte to tape & update checksum
;
; Open CAS for input of BASIC files
;
R_CAS_OPEN_IN_BA:						;2650H
    MVI     B,0D3H						;BA marker
	SKIP_2BYTES_INST_DE
;
; Open CAS for input of TEXT files
;
R_CAS_OPEN_IN_DO:						;2653H
    MVI     B,9CH						;DO marker
	SKIP_2BYTES_INST_DE
;
; Open CAS for input of CO files
;
R_CAS_OPEN_IN_CO:						;2656H
    MVI     B,0D0H						;CO marker
-	PUSH    B
    CALL    R_CAS_OPEN_IN				;. Returns marker found
    POP     B
    CMP     B							;compare file type
    JZ      L_CAS_PRINT_FOUND			;brif file types match
    CALL    L_CAS_PRINT_SKIP			;Print program on tape being skipped
    JMP     -

R_CAS_OPEN_IN:
    CALL    R_LOAD_CAS_HDR				;Start tape and load tape header
    CALL    R_CAS_READ_BYTE				;Read byte from tape & update checksum
    CPI     0D3H						;BA marker
    JZ      +
    CPI     9CH							;DO marker
    JZ      +
    CPI     0D0H						;CO marker
    JNZ     R_CAS_OPEN_IN				;
; BA, DO or CO file type found
+	PUSH    PSW
    LXI     H,FILNM2_R				    ;Filename of last program loaded from tape
    LXI     D,0602H						;D = first loop count 6, E = loop count 2
    MVI     C,00H
-	CALL    R_CAS_READ_BYTE				;Read byte from tape & update checksum
    MOV     M,A							;store in FILNM2_R
    INX     H
    DCR     D							;decrement
    JNZ     -
    LXI     H,LOADADR_R				  	;'Load address' of current program
    MVI     D,0AH						;count 10 in second loop
    DCR     E							;loop count
    JNZ     -
    CALL    R_CAS_READ_BYTE				;Read byte from tape & update checksum
    MOV     A,C
    ANA     A
    JNZ     L_CAS_OPEN_2
    CALL    R_CAS_MOTOR_OFF				;Turn cassette motor off
    LXI     H,FILNAM_R				    ;Current Filename
    MVI     B,06H						;loop count
    MVI     A,' '
-	CMP     M
    JNZ     +							;brif no match
    INX     H
    DCR     B
    JNZ     -
    JMP     L_CAS_OPEN_1				;TODO POP PSW, RET shorter

+	LXI     D,FILNAM_R				    ;Current Filename
    LXI     H,FILNM2_R				    ;Filename of last program loaded from tape
    MVI     B,06H
-	LDAX    D
    CMP     M
    JNZ		+							;brif no match
    INX     D
    INX     H
    DCR     B
    JNZ     -
L_CAS_OPEN_1:
    POP     PSW
    RET

+	CALL    L_CAS_PRINT_SKIP			;Print program on tape being skipped
L_CAS_OPEN_2:
    POP     PSW
    JMP     R_CAS_OPEN_IN				;

L_FND_CAS_DATA_BLK:
    CALL    R_LOAD_CAS_HDR				;Start tape and load tape header
    CALL    R_CAS_READ_BYTE				;Read byte from tape & update checksum
    CPI     8DH							;Data Block marker
    JNZ     L_CAS_IO_ERROR
    RET

L_CAS_PRINT_SKIP:						;Print program on tape being skipped
    LXI     D,L_CAS_SKIP_TXT			;Code Based. 
    JMP     L_CAS_PRINT_TXT				;no trick?

L_CAS_PRINT_FOUND:
    LXI     D,L_CAS_FOUND_TXT			;Code Based. 
L_CAS_PRINT_TXT:
    LHLD    CURLIN_R					;Currently executing line number
    INX     H
    MOV     A,H
    ORA     L
    RNZ
    XCHG
    CALL    R_PRINT_STRING_2			;Print_2 buffer at M until NULL or '"'
    XRA     A
    STA     FILNM2_R+6					;extension
    LXI     H,FILNM2_R				  	;Filename of last program loaded from tape
    CALL    R_PRINT_STRING				;Print buffer at M until NULL or '"'
    JMP     R_ERASE_TO_EOL				;Erase from cursor to end of line

L_CAS_FOUND_TXT:
    DB      "Found:",00H

L_CAS_SKIP_TXT:
    DB      "Skip :",00H
	
;
;BASIC expression evaluation operator vector for String Compare
;
; String ptr on stack
;
L_STR_CMP:
    CALL    L_FRESTR					;Get pointer to most recently used string (Len + address): string 1
    MOV     A,M							;string length
    INX     H
    MOV     C,M							;string data ptr to BC
    INX     H
    MOV     B,M
    POP     D							;string ptr to DE: string 2
    PUSH    B							;string data ptr
    PUSH    PSW							;string length
    CALL    L_FRETMP					;Get pointer to stack string (Len + address). POP based on DE
    POP     PSW
    MOV     D,A
    MOV     E,M
    INX     H
    MOV     C,M
    INX     H
    MOV     B,M
    POP     H
-	MOV     A,E							;test DE for 0
    ORA     D
    RZ
    MOV     A,D
    SUI     01H							;sets carry
    RC
    XRA     A							;preset A to 0
    CMP     E
    INR     A
    RNC
    DCR     D
    DCR     E
    LDAX    B
    INX     B
    CMP     M
    INX     H
    JZ		-							;brif same
    CMC									;complement carry
    JMP     L_EVAL_CARRY_IN_A
;
; STR$ function
;	STR$(num)
;
R_STR_FUN:								;273AH
    CALL    R_PRINT_FAC1_ZERO			;Convert binary number in FAC1 to ASCII at MBUFFER_R
    CALL    R_STRLTI_PREDEC_HL			;find end of string
    CALL    L_FREFAC
    LXI     B,L_CHR_2					;continuation function
    PUSH    B
L_STR_1:
    MOV     A,M							;string length
    INX     H							;increment string ptr
    PUSH    H							;save string descriptor ptr
    CALL    L_RESERVE_STRBUF			;Reserve space in BASIC string buffer. Returns ptr in DE
    POP     H							;restore string descriptor ptr
    MOV     C,M							;get string value ptr to BC
    INX     H
    MOV     B,M
    CALL    L_SET_TRSNSTR				;Save A and DE to transient string storage
    PUSH    H							;save ptr to transient string storage
    MOV     L,A
    CALL    R_MOVE_L_BYTES				;move L bytes from BC to DE
    POP     D							;restore ptr to transient string storage
    RET									;to continuation function

L_PREP_STR_LEN1:
    MVI     A,01H
L_PREP_STR:
    CALL    L_RESERVE_STRBUF			;Reserve space in BASIC string buffer. Returns ptr in DE
;
; Move String Descriptor in A, DE to TRSNSTR_R
;
; IN:
;	A, DE
; OUT:
;	A		Length
;	HL		TRSNSTR_R
;
L_SET_TRSNSTR:							;Save A and DE to transient string storage
    LXI     H,TRSNSTR_R					;transient string storage
    PUSH    H							;save it
    MOV     M,A							;string length
    INX     H
    MOV     M,E							;string data
    INX     H
    MOV     M,D
    POP     H							;HL == TRSNSTR_R
    RET
;
; Search string at M until DBL QUOTE found
;
R_STRLTI_PREDEC_HL:
    DCX     H							;Pre Decrement HL
R_STRLTI:								;look for end of string
    MVI     B,'"'						;22H
;
; Search string at M until CHAR in B found
;
R_STRLTI_FOR_B:
    MOV     D,B
;
; Search string at M until CHAR in B or D found and push to String Stack
;
L_STR_LOOP:
    PUSH    H							;save string ptr
    MVI     C,0FFH						;preset to -1
-	INX     H
    MOV     A,M							;get next char
    INR     C							;count - 1
    ORA     A
    JZ      +							;brif end of line
    CMP     D
    JZ      +							;brif D found
    CMP     B
    JNZ     -							;loop back if B not found
; A == 0 or A == D or A == B
+	CPI     '"'
    CZ      L_CHRGTR					;Get next non-white char from M
    XTHL								;text ptr to stack. string ptr to HL
    INX     H							;skip '"'
    XCHG
    MOV     A,C							;string length
    CALL    L_SET_TRSNSTR				;Save A and DE to transient string storage
;
; Store transient string ptr to integer FAC and add to String Stack.
;
; text ptr on stack.	
;
L_STRSTK_ADD:
    LXI     D,TRSNSTR_R					;transient string storage
    MVI     A,0D5H						;TODO A unused?
    LHLD    TEMPPT_R					;current String Stack ptr (points to next free entry)
    SHLD    IFACLO_R					;FAC1 for integers
    MVI     A,03H						;type STRING
    STA     VALTYP_R					;Type of last expression used
    CALL    R_MOVE_TYP_BYTES_INC		;3 bytes from (DE) to M. DE & HL incremented by 3
; HL is new TEMPPT_R 
; TODO DE already is TEMPST_R+33 since TRSNSTR_R+3 == TEMPST_R+33
    LXI     D,TEMPST_R+33				;0FB8CH: String Stack Area upper limit
    COMPAR								;Compare HL and TRSNSTR_R+3: HL - DE
    SHLD    TEMPPT_R					;set new String Stack ptr
    POP     H							;restore text ptr
    MOV     A,M							;get next char
    RNZ									;COMPAR result
    LXI     D,0010H						;String Stack Overflow if TRSNSTR_R+3 reached
    JMP     R_GEN_ERR_IN_E				;Generate error 16

R_PRINT_STRING_PREINC_HL:
    INX     H
;
; Print buffer at M until NULL or '"'
;
R_PRINT_STRING:							;27B1H
    CALL    R_STRLTI_PREDEC_HL
L_PRINT_LST_STR:
    CALL    L_FREFAC
    CALL    L_LOAD_STR_M				;load D & BC
    INR     D							;pre-increment length
-	DCR     D							;length
    RZ    								;retif 0 
    LDAX    B							;get string char
    OUTCHR								;Send character in A to screen/printer
    CPI     0DH							;CR
    CZ      L_RECORD_CR
    INX     B
    JMP     -
;
; Reserve space in BASIC string buffer
;
; STRBUF_R holds a pointer to the start of the String Buffer Area
; MEMSIZ_R holds a pointer to the end of the String Buffer Area
; String buffer area grows from top to bottom
; FRETOP_R holds a pointer to the free area of the String Buffer Area
;
; IN:
;	A		string length
;
; OUT:
;	DE		ptr to reserved string space
;
L_GETSPA:
L_RESERVE_STRBUF:
    ORA     A							;set flags for string length
	SKIP_BYTE_INST_C					;skip POP PSW
L_TRYGI2:								;used as continuation function w/ PSW pushed
    POP     PSW
    PUSH    PSW							;save length and flags
    LHLD    STRBUF_R					;ptr to start of BASIC string buffer to DE
    XCHG
    LHLD    FRETOP_R					;Pointer to free area in BASIC string buffer to HL
    CMA  								;negate length 
    MOV     C,A							;sign extend to BC
    MVI     B,0FFH
    DAD     B							;subtract length+1 from FRETOP_R
    INX     H							;correct for +1
    COMPAR								;Compare new FRETOP_R with buffer start: HL - DE
    JC      L_GARBAG					;brif buffer overflow
    SHLD    FRETOP_R					;update Pointer to current location in BASIC string buffer
    INX     H							;ptr to string value ptr
    XCHG								;BASIC string buffer pointer back to HL
L_POP_PSW_RET:							;tail merge entry
    POP     PSW							;remove length and flags
    RET
;
; no space for requested string length in BASIC string buffer area
; do garbage collection
;
L_GARBAG:
	POP     PSW							;get length and flags back
    LXI     D,000EH
    JZ      R_GEN_ERR_IN_E				;brif length == 0: Generate out of string space error
    CMP     A
    PUSH    PSW
    LXI     B,L_TRYGI2					;continuation function
    PUSH    B
L_GARBA2:
    LHLD    MEMSIZ_R					;File buffer area pointer. Also end of dynamic Strings Buffer
L_FNDVAR:
    SHLD    FRETOP_R					;reset free ptr in BASIC string buffer
    LXI     H,0							;0 on stack
    PUSH    H
    LHLD    STRGEND_R  					;Unused memory pointer
    PUSH    H
    LXI     H,TEMPST_R					;String Temp Area
L_TVAR:									;used as continuation function
    XCHG
    LHLD    TEMPPT_R					;DE = String Stack ptr
    XCHG
    COMPAR								;Compare TEMPPT_R with init value: HL - DE
    LXI     B,L_TVAR					;continuation function
    JNZ     L_DVAR2						;DO TEMP VAR GARBAGE COLLECT
; String Temps empty
    LXI     H,PRMPRV_R					;SETUP ITERATION FOR PARAMETER BLOCKS
    SHLD    TEMP9_R
    LHLD    ARYTAB_R					;GET STOPPING POINT IN HL
    SHLD    ARYTA2_R					;STORE IN STOP LOCATION
    LHLD    VARTAB_R					;GET STARTING POINT IN HL
L_SVAR:
    XCHG
    LHLD    ARYTA2_R					;GET STOPPING LOCATION
    XCHG
    COMPAR								;SEE IF AT END OF SIMPS
    JZ      L_ARYVAR					;brif equal
    MOV     A,M							;GET VALTYP
    INX     H							;BUMP POINTER TWICE
    INX     H
    INX     H							;POINT AT THE VALUE
;
; From mbasic 5.2
;	PUSH	PSW							;SAVE VALTYP
;	CALL	L_IADAHL					;AND SKIP OVER EXTRA CHARACTERS AND COUNT
;	POP	PSW
;
    CPI     03H
    JNZ     +
    CALL    L_DVARS						;COLLECT IT
    XRA     A
+	MOV     E,A							;zero extend A to DE
    MVI     D,00H
    DAD     D							;add to HL
    JMP     L_SVAR						;loop

L_ARYVAR:
    LHLD    TEMP9_R						;ptr
	GETDEFROMMNOINC						;*ptr
    MOV     A,D							;test DE
    ORA     E
    LHLD    ARYTAB_R					;ptr to Start of array table
    JZ      L_ARYVA4					;brif DE == 0: GARBAGE COLLECT ARRAYS
    XCHG
    SHLD    TEMP9_R
    INX     H							;SKIP CHAIN POINTER
    INX     H
	GETDEFROMM							;PICK UP THE LENGTH
    XCHG								;SET DE= ACTUAL END ADDRESS BY ADDING BASE TO LENGTH
    DAD     D
    SHLD    ARYTA2_R					;SET UP STOP LOCATION
    XCHG
    JMP     L_SVAR
;
; loop back point from below
;
L_ARYVA2:
    POP     B							;cleanup stack
;
; IN:
;	HL
;
L_ARYVA4:
    XCHG								;SAVE ARYVAR IN DE
    LHLD    STRGEND_R					;GET END OF ARRAYS (Unused memory pointer)
    XCHG
    COMPAR								;Compare Unused memory pointer and HL: HL - DE
    JZ      L_GRBPAS					;brif equal
    MOV     A,M							;GET THE VALUE TYPE INTO A
; Code differs from mbasic 5.2
    INX     H
    CALL    R_SNGL_DECB_EQ_M			;Reverse load single precision at M to DEBC
; end of code difference
    PUSH    H							;SAVE POINTER TO DIMS
    DAD     B							;ADD TO CURRENT POINTER POSITION
    CPI     03H							;SEE IF ITS A STRING
    JNZ     L_ARYVA2					;loop back
    SHLD    TEMP8_R						;SAVE END OF ARRAY
    POP     H							;GET BACK CURRENT POSITION
    MOV     C,M							;PICK UP NUMBER OF DIMS
    MVI     B,00H
    DAD     B							;GO PAST DIMS BY ADDING ON TWICE #DIMS (2 BYTE GUYS)
    DAD     B
    INX     H							;ONE MORE TO ACCOUNT FOR #DIMS
L_ARYSTR:								;used as continuation function
    XCHG								;SAVE CURRENT POSIT IN [D,E]
    LHLD    TEMP8_R						;GET END OF ARRAY
    XCHG								;FIX HL BACK TO CURRENT
    COMPAR								;HL - DE
    JZ      L_ARYVA4						;brif equal
    LXI     B,L_ARYSTR					;ADDR OF WHERE TO RETURN TO
L_DVAR2:
    PUSH    B							;GOES ON STACK
L_DVARS:
    XRA     A							;test length
    ORA     M							;SEE IF ITS THE NULL STRING
    INX     H
	GETDEFROMM							;DE=POINTER AT THE VALUE
    RZ									;NULL STRING, RETURN
    MOV     B,H							;save HL
    MOV     C,L
    LHLD    FRETOP_R					;Pointer to current location in BASIC string buffer
    COMPAR								;HL - DE
    MOV     H,B							;restore HL
    MOV     L,C
    RC									;IF NOT, NO NEED TO MESS WITH IT FURTHUR
    POP     H							;GET RETURN ADDRESS OFF STACK
    XTHL								;GET MAX SEEN SO FAR & SAVE RETURN ADDRESS
    COMPAR								;Compare DE and HL reversed: HL - DE
    XTHL								;SAVE MAX SEEN & GET RETURN ADDRESS OFF STACK
    PUSH    H							;SAVE RETURN ADDRESS BACK
    MOV     H,B							;HL = BC
    MOV     L,C
    RNC									;IF NOT, LETS LOOK AT NEXT VAR
    POP     B							;GET RETURN ADDR OFF STACK
    POP     PSW							;POP OFF MAX SEEN AND VARIABLE POINTER
    POP     PSW
    PUSH    H							;SAVE NEW VARIABLE POINTER
    PUSH    D							;AND NEW MAX POINTER
    PUSH    B							;SAVE RETURN ADDRESS BACK
    RET									;AND RETURN
;
; HERE WHEN MADE ONE COMPLETE PASS THRU STRING VARS
;
L_GRBPAS:
    POP     D							;POP OFF MAX POINTER
    POP     H							;AND GET VARIABLE POINTER
    MOV     A,H							;test HL
    ORA     L							;SEE IF ZERO POINTER
    RZ									;IF END OF COLLECTION, THEN MAYBE RETURN TO GETSPA
    DCX     H							;CURRENTLY JUST PAST THE DESCRIPTOR
    MOV     B,M							;get BC from M
    DCX     H
    MOV     C,M							;BC=POINTER AT STRING DATA
    PUSH    H							;SAVE THIS LOCATION SO THE POINTER
										;CAN BE UPDATED AFTER THE STRING IS MOVED
    DCX     H
    MOV     L,M							;L=STRING LENGTH
    MVI     H,00H
    DAD     B							;HL=POINTER BEYOND STRING
    MOV     D,B							;copy BC to DE
    MOV     E,C							;DE=ORIGINAL POINTER
    DCX     H							;DON'T MOVE ONE BEYOND STRING
    MOV     B,H							;GET TOP OF STRING IN BC
    MOV     C,L
    LHLD    FRETOP_R					;GET TOP OF FREE SPACE
    CALL    L_CPY_BC_TO_HL				;L_BLTUC MOVE STRING
    POP     H							;GET BACK POINTER TO DESC.
    MOV     M,C							;SAVE FIXED ADDR
    INX     H							;MOVE POINTER
    MOV     M,B							;HIGH PART
    MOV     H,B							;HL=NEW POINTER
    MOV     L,C
    DCX     H							;FIX UP FRETOP
    JMP     L_FNDVAR					;AND TRY TO FIND HIGH AGAIN
;
;string concatenation
;
L_STR_CONCAT:
    PUSH    B
    PUSH    H
    LHLD    IFACLO_R					;FAC1 for integers
    XTHL
    CALL    L_EVAL						;Evaluate function at M
    XTHL
    CALL    L_CHKSTR
    MOV     A,M
    PUSH    H							;ptr to str1
    LHLD    IFACLO_R					;FAC1 for integers
    PUSH    H							;ptr to str2
    ADD     M							;new string length
    LXI     D,000FH
    JC      R_GEN_ERR_IN_E				;Generate error 15. if overflow
    CALL    L_PREP_STR					;Reserve String space and set Transitory String
    POP     D
    CALL    L_FRETMP					;Get pointer to stack string (Len + address). POP based on DE
    XTHL
    CALL    L_FRETM2
    PUSH    H							;ptr to string
    LHLD    TRSNSTR_R+1					;TRSNSTR_R+1 to DE
    XCHG
    CALL    L_StrCpy			       	;Memory copy using args pointed to by ptr on stack
    CALL    L_StrCpy			       	;Memory copy using args pointed to by ptr on stack
    LXI     H,L_TSTOP					;continuation function
    XTHL								;eval entry point to stack. value on stack (textptr?) to HL
    PUSH    H							;text ptr
    JMP     L_STRSTK_ADD				;add Transient String to String Stack
;
; Memory copy using args pointed to by ptr on stack
;
; IN:
;	DE		target memory ptr;
;
;	on stack: ptr to source string
;
L_StrCpy:								;2904H
    POP     H							;return address
    XTHL								;previously pushed ptr to HL, return address to stack
    MOV     A,M							;length
    INX     H
    MOV     C,M							;string data ptr to BC
    INX     H
    MOV     B,M
    MOV     L,A							;store length
;
;Move L bytes from (BC) to (DE)
;
;
; IN:
;	L		String Length
;	BC		source
;	DE		destination
;
R_MOVE_L_BYTES:
    INR     L							;pre-inc length
-	DCR     L							;decrement length
    RZ									;retif length now 0
    LDAX    B							;char from string
    STAX    D
    INX     B
    INX     D
    JMP     -
;
; FRETMP IS PASSED A POINTER TO A STRING DESCRIPTOR IN DE
; THIS VALUE IS RETURNED IN HL. ALL THE OTHER REGISTERS ARE MODIFIED.
; A CHECK TO IS MADE TO SEE IF THE STRING DESCRIPTOR DE POINTS
; TO IS THE LAST TEMPORARY DESCRIPTOR ALLOCATED BY PUTNEW.
; IF SO, THE TEMPORARY IS FREED UP BY THE UPDATING OF TEMPPT.
; IF A TEMPORARY IS FREED UP, A FURTHER CHECK IS MADE TO SEE IF THE
; STRING DATA THAT THAT STRING TEMPORARY POINTED TO IS THE
; THE LOWEST PART OF STRING SPACE IN USE.
; IF SO, FRETMP IS UPDATED TO REFLECT THE FACT THAT THAT SPACE IS NO
; LONGER IN USE.
;
; Get pointer to most recently used string (Len + address)
; This may be pointed to by FAC1 or may from from the string stack
; 
L_FRESTR:								;FREE UP TEMP & CHECK STRING
    CALL    L_CHKSTR
L_FREFAC:
    LHLD    IFACLO_R					;[FAC1]
L_FRETM2:
    XCHG								;to DE
; 
; Get pointer to stack string (Len + address). POP based on DE
; This may point to FAC1 or may be from the string stack
; 
L_FRETMP:
    CALL    L_FRETMS					;POP string from string stack if same as DE
    XCHG								;HL = [FAC1]
    RNZ									;Return if last pushed string descriptor not same as DE
; L_FRETMS returned string data ptr on top of stack in BC. String descriptor was removed from String Stack
    PUSH    D							;Save address of "POPed" string to stack
    MOV     D,B							;move string data ptr to DE
    MOV     E,C
    DCX     D
    MOV     C,M							;string length
    LHLD    FRETOP_R					;Pointer to current location in BASIC string buffer
    COMPAR								;[FRETOP_R] - DE
    JNZ     +							;brif not identical
;A== 0 if COMPAR returns Z
    MOV     B,A							;zero extend C to BC
    DAD     B
    SHLD    FRETOP_R					;update current location in BASIC string buffer
+	POP     H
    RET
; 
; POP string from string stack if same as String Descriptor in DE
; TEMPST_R grows up. TEMPPT_R points to first free entry
; each entry is 3 bytes. Max 10 entries.
;
; IN:
;	DE		Target String Descriptor
;
; OUT:
;	Z		Clr if stack empty
;	BC		string data ptr on top of stack
;	HL		ptr to most recently pushed string descriptor
; 
L_FRETMS:
    LHLD    TEMPPT_R					;String Stack address (first free)
; HL points past last pushed string descriptor
    DCX     H							;Pre-decrement to get MSB of string address
    MOV     B,M							;Get MSB string data ptr of top entry
    DCX     H							;Decrement to LSB of string address
    MOV     C,M							;Get LSB string data ptr of top entry
    DCX     H							;Decrement again to point to string length of top entry
    COMPAR								;[TEMPPT_R] - 3 - DE
    RNZ									;Don't update string stack ptr if not same as target String Descriptor
    SHLD    TEMPPT_R					;update String Stack ptr
    RET									;return with Z set
;
; LEN function
;
R_LEN_FUN:								;2943H
    LXI     B,L_LD_FAC1_BYTE			;insert continuation function
    PUSH    B
L_GET_STR:
    CALL    L_FRESTR					;FREE UP TEMP & CHECK STRING
    XRA     A
    MOV     D,A							;clear D
    MOV     A,M							;get length
    ORA     A							;set flags
    RET
;
; ASC function
;
; int = ASC(STRING)
;
R_ASC_FUN:								;294FH
    LXI     B,L_LD_FAC1_BYTE				;insert continuation function
    PUSH    B
L_GET_FIRST_CHAR:
    CALL    L_GET_STR					;get string. Returns length in A
    JZ      R_GEN_FC_ERROR				;Generate FC error if empty string
    INX     H							;get ptr to string data in DE
	GETDEFROMMNOINC
    LDAX    D							;load first char
    RET
;
; CHR$ function
;
; txt ptr on stack
;
R_CHR_FUN:								;295FH
    CALL    L_PREP_STR_LEN1
    CALL    L_CONINT					;result in E
L_CHR_1:
    LHLD    TRSNSTR_R+1					;Transitory String data ptr
    MOV     M,E							;store char value
L_CHR_2:
    POP     B							;remove return address
    JMP     L_STRSTK_ADD
;
; STRING$ function
;
; STRING$(length, char): Creates a string of length "length" made up exclusively of "char"
;	char can be a string or a number
;
R_STRING_FUN:							;296DH
    CHRGET								;Get next non-white char from M
	SYNCHK	'('
    CALL    L_GETBYT					;Evaluate byte expression at M-1: length to E
    PUSH    D							;save length
	SYNCHK	','
    CALL    L_FRMEVL					;Main BASIC evaluation routine: char
	SYNCHK	')'
    XTHL								;txt ptr to stack Length to HL
    PUSH    H							;save length
    LSTTYP								;Determine type of last var used: C Clr = DBL P Clr = SNGL Z Set = String S: Set = Integer
    JZ      +							;brif STRING type
    CALL    L_CONINT					;evaluate char as an ascii code to A
    JMP     L_STRING_1

+	CALL    L_GET_FIRST_CHAR			;get first char of string to A
L_STRING_1:
    POP     D							;restore length
    CALL    L_FILL_STR
;
; SPACE$ function
;	SPACE$(num):  Returns a string of length "num" that's entirely made up of spaces.
;
R_SPACE_FUN:							;298EH
    CALL    L_CONINT					;evaluate num to E
    MVI     A,' '
L_FILL_STR:
    PUSH    PSW							;save ' ' or char from STRING$
    MOV     A,E							;length
    CALL    L_PREP_STR					;Reserve String space and set Transitory String
    MOV     B,A							;length to B
    POP     PSW							;restore char
    INR     B							;test B
    DCR     B
    JZ      L_CHR_2						;brif B == 0
    LHLD    TRSNSTR_R+1					;Transitory String data ptr to HL
; fill Transitory String with char in A
-	MOV     M,A							;store space
    INX     H							;next
    DCR     B							;count
    JNZ     -
    JMP     L_CHR_2						;remove return address and jmp to L_STRSTK_ADD
;
; LEFT$ function
;	 LEFT$(str,count): Returns the leftmost "count" characters from "str"
;
R_LEFT_FUN:								;29ABH
    CALL    L_PROCESS_STR_ARG1			;process (str,count)
    XRA     A
L_LEFT_STR_1:
    XTHL
    MOV     C,A
	SKIP_BYTE_INST						;Sets A to 0AFH
L_LEFT_STR_2:
    PUSH    H
L_LEFT_STR_3:							;continuation function
    PUSH    H
    MOV     A,M
    CMP     B
    JC      +							;brif M < B
    MOV     A,B							;set minimum B bytes
	SKIP_2BYTES_INST_DE
+	MVI     C,00H
    PUSH    B
    CALL    L_RESERVE_STRBUF			;Reserve space in BASIC string buffer. Returns ptr in DE
    POP     B
    POP     H
    PUSH    H
    INX     H
    MOV     B,M
    INX     H
    MOV     H,M
    MOV     L,B
    MVI     B,00H
    DAD     B
    MOV     B,H							;Src ptr to BC
    MOV     C,L
    CALL    L_SET_TRSNSTR				;Save A and DE to transient string storage
    MOV     L,A							;length
    CALL    R_MOVE_L_BYTES				;move L bytes from BC to DE
    POP     D
    CALL    L_FRETMP					;Get pointer to stack string (Len + address). POP based on DE
    JMP     L_STRSTK_ADD
;
; RIGHT$ function
;	RIGHT$(str,count): Returns the "count" rightmost characters of "str"
;
R_RIGHT_FUN:							;29DCH
    CALL    L_PROCESS_STR_ARG1			;process (str,count)
    POP     D
    PUSH    D
    LDAX    D
    SUB     B
    JMP     L_LEFT_STR_1				;join R_LEFT_FUN
;
; MID$ function in expression
;	MID$(str,pos)
;	MID$(str,pos,length)
;
; Returns "length" characters of "str" beginning at "pos".
; Reads to the end of the string if "length" is not supplied.
;
; See also LHSMID()
;
R_MID_FUN:								;29E6H
    XCHG
    MOV     A,M
    CALL    L_PROCESS_STR_ARG2
    INR     B							;test B
    DCR     B
    JZ      R_GEN_FC_ERROR				;brif B == 0: Generate FC error
    PUSH    B
    CALL    L_GET_OPT_LEN				;get an optional length argument
    POP     PSW
    XTHL
    LXI     B,L_LEFT_STR_3				;continuation function
    PUSH    B
    DCR     A
    CMP     M
    MVI     B,00H
    RNC
    MOV     C,A
    MOV     A,M
    SUB     C
    CMP     E
    MOV     B,A
    RC
    MOV     B,E
    RET
;
; VAL function
;
;	Format: VAL(str)
;
R_VAL_FUN:								;2A07H
    CALL    L_GET_STR					;get string. Returns length in A
    JZ      L_LD_FAC1_BYTE			  	;brif empty string: Load 0 (A) into FAC1
    MOV     E,A							;length. 
    INX     H
	GETHLFROMM							;get string data ptr to HL
    PUSH    H							;save string data ptr
    DAD     D							;index to ptr past string data. TODO Assumes D==0
    MOV     B,M
;
; we temporarily modify memory past string data
; record it in case an error occurs
;
    SHLD    VALSTRPTR_R					;save ptr past string data
    MOV     A,B							;value of memory past string data
    STA     VALSTRDAT_R					;store 
    MOV     M,D							;zero terminate string
    XTHL								;end of string ptr to stack. String data ptr to HL
    PUSH    B							;save BC (value of memory past string data)
    DCX     H							;pre-decrement
    CHRGET								;Get next non-white char from M
    CALL    R_ASCII_TO_DBL				;Convert ASCII number at M to double precision in FAC1
    LXI     H,0
    SHLD    VALSTRPTR_R					;clear ptr past string data
    POP     B							;restore BC
    POP     H							;restore string data ptr
    MOV     M,B							;restore original value to location past string data
    RET
;
; process (str,count)
;
; OUT:
;	B
;
L_PROCESS_STR_ARG1:
    XCHG
	SYNCHK	')'	
L_PROCESS_STR_ARG2:
    POP     B
    POP     D
    PUSH    B
    MOV     B,E
    RET
;
; INSTR function
;	INSTR(source,search)
;	INSTR(start,source,search)
;
; THIS IS THE INSTR FUNCTION. IT TAKES ONE OF TWO
; FORMS: INSTR(I%,S1$,S2$) OR INSTR(S1$,S2$)
; IN THE FIRST FORM THE STRING S1$ IS SEARCHED FOR THE
; CHARACTER S2$ STARTING AT CHARACTER POSITION I%.
; THE SECOND FORM IS IDENTICAL, EXCEPT THAT THE SEARCH
; STARTS AT POSITION 1. INSTR RETURNS THE CHARACTER
; POSITION OF THE FIRST OCCURANCE OF S2$ IN S1$.
; IF S1$ IS NULL, 0 IS RETURNED. IF S2$ IS NULL, THEN
; I% IS RETURNED, UNLESS I% .GT. LEN(S1$) IN WHICH
; CASE 0 IS RETURNED.
;
R_INSTR_FUN:							;2A37H
    CHRGET								;Get next non-white char from M
    CALL    L_FRMPRN					;EVALUATE FIRST ARG
    LSTTYP								;Determine type of last var used: C Clr = DBL P Clr = SNGL Z Set = String S: Set = Integer
    MVI     A,01H						;set default start position on stack
    PUSH    PSW
    JZ      +							;brif first argument is string
    POP     PSW							;remove default start position from stack
    CALL    L_CONINT					;FORCE ARG1 (I%) TO BE INTEGER
    ORA     A
    JZ      R_GEN_FC_ERROR				;brif start == 0: Generate FC error
    PUSH    PSW							;start position on stack
	SYNCHK	','							;EAT THE COMMA
    CALL    L_FRMEVL					;EAT FIRST STRING ARG
    CALL    L_CHKSTR					;BLOW UP IF NOT STRING
+	SYNCHK	','							;EAT COMMA AFTER ARG
    PUSH    H							;save txt ptr
    LHLD    IFACLO_R					;GET DESCRIPTOR POINTER
    XTHL								;PUT ON STACK & GET BACK TEXT PTR
    CALL    L_FRMEVL					;GET LAST ARG
	SYNCHK	')'							;EAT RIGHT PAREN
    PUSH    H							;save txt ptr
    CALL    L_FRESTR					;FREE UP TEMP & CHECK STRING
    XCHG								;SAVE 2ND DESC. POINTER IN DE
    POP     B							;saved txt ptr to BC (temp)
    POP     H							;DESC. POINTER FOR S1$
    POP     PSW							;offset
    PUSH    B							;PUT TEXT POINTER ON BOTTOM
    LXI     B,L_POP_HL					;"POP H & return" continuation function
    PUSH    B							;set continuation function L_POP_HL
    LXI     B,L_LD_FAC1_BYTE			;continuation function
    PUSH    B							;set continuation function L_LD_FAC1_BYTE
    PUSH    PSW							;save offset again
    PUSH    D							;SAVE DESC. OF S2$
    CALL    L_FRETM2					;FREE UP S1 DESC.
    POP     D							;RESTORE DESC. S2
    POP     PSW							;restore offset
    MOV     B,A							;SAVE UNMODIFIED OFFSET
    DCR     A							;rebase
    MOV     C,A							;move to C
    CMP     M							;IS IT BEYOND LENGTH OF S1?
    MVI     A,00H						;preset return value (no flags affected)
    RNC									;retif A >= M: start position beyond length. Load A into FAC1, POP H & return
    LDAX    D							;GET LENGTH OF S2$
    ORA     A							;NULL string
    MOV     A,B							;GET OFFSET BACK
    RZ									;IF S2 NULL, RETURN OFFSET: load A into FAC1, POP H & return
; HL points to source string descriptor
    MOV     A,M							;GET LENGTH OF S1$
    INX     H							;next ptr in string
    MOV     B,M							;get string data ptr to HL
    INX     H
    MOV     H,M
    MOV     L,B
    MVI     B,00H						;zero extend C (0 based starting position) to BC
    DAD     B							;ptr to start in source string
    SUB     C							;MAKE LENGTH OF STRING S1$ RIGHT
    MOV     B,A							;SAVE LENGTH OF 1ST STRING IN B
    PUSH    B							;SAVE COUNTER, OFFSET
    PUSH    D							;PUT 2ND DESC (S2$) ON STACK
    XTHL								;GET 2ND DESC. POINTER
    MOV     C,M							;SET UP LENGTH
    INX     H							;BUMP POINTER
	GETDEFROMMNOINC						;get address
    POP     H							;RESTORE POINTER FOR 1ST STRING
L_INSTR_SEARCH:
    PUSH    H							;SAVE POSITION IN SEARCH STRING
    PUSH    D							;SAVE START OF SUBSTRING
    PUSH    B							;SAVE WHERE WE STARTED SEARCH
;
; compare search string with source string, adjusted for start
;
-	LDAX    D							;GET CHAR FROM SUBSTRING
    CMP     M							;= CHAR POINTER TO BY HL
    JNZ     L_INSTR_NOMATCH				;brif characters ate not equal
    INX     D							;BUMP COMPARE POINTER
    DCR     C							;END OF SEARCH STRING?
    JZ      L_INSTR_MATCH				;brif C == 0: Found it
    INX     H							;BUMP POINTER INTO STRING BEING SEARCHED
    DCR     B							;DECREMENT LENGTH OF SEARCH STRING
    JNZ     -							;brif B != 0
;
; no match
;
    POP     D							;GET RID OF POINTERS
    POP     D							;GET RID OF GARB
    POP     B							;idem
L_INSTR_TAIL:							;tail merge for no gain
    POP     D
    XRA     A							;return value
    RET									;Load A into FAC1, POP H & return 

L_INSTR_MATCH:
	POP     H							;GET RID OF GARB
    POP     D							;GET RID OF EXCESS STACK
    POP     D							;idem
    POP     B							;GET COUNTER, OFFSET
    MOV     A,B							;GET ORIGINAL SOURCE COUNTER
    SUB     H							;SUBTRACT FINAL COUNTER
    ADD     C							;ADD ORIGINAL OFFSET (N1%)
    INR     A							;result needs to be 1 based.
    RET									;Load A into FAC1, POP H & return 
;
; string characters didn't match
;
L_INSTR_NOMATCH:
    POP     B							;restore all registers
    POP     D							;POINT TO START OF SUBSTRING
    POP     H							;GET BACK WHERE WE STARTED TO COMPARE
    INX     H							;AND POINT TO NEXT CHAR
    DCR     B							;DECR. # CHAR LEFT IN SOURCE STRING
    JNZ     L_INSTR_SEARCH				;search some more
    JMP     L_INSTR_TAIL				;tail merge for no gain
;
; MID$(str, pos) = value
;	MID$(str,pos)=value
;	MID$(str,pos,length)=value
;
; Overwrites the substring defined by pos with "value".
; This mode always ignores "length" and simply overwrites as many
; characters as "value" is long. "str" is never extended.
; If "value" is too long, it's truncated to fit.
;
LHSMID:
	SYNCHK	'('							;28H
    CALL    R_FIND_VAR_ADDR				;address of str to DE
    CALL    L_CHKSTR
    PUSH    H							;text ptr
    PUSH    D							;address of string
    XCHG								;address of string to HL
    INX     H							;skip length
	GETDEFROMMNOINC						;string value ptr to DE
    LHLD    STRGEND_R					;Get Unused memory pointer
    COMPAR								;HL - DE
    JC      +							;brif STRGEND_R < String value ptr
    LHLD    TXTTAB_R					;Start of BASIC program pointer
    COMPAR								;HL - DE
    JNC     +							;brif TXTTAB_R < String value ptr
    POP     H							;retrieve text ptr
    PUSH    H
    CALL    L_STR_1
    POP     H							;retrieve text ptr
    PUSH    H
    CALL    R_MOVE_TYP_BYTES_INC		;from (DE) to M
+	POP     H							
    XTHL
	SYNCHK	','
    CALL    L_GETBYT					;Evaluate byte expression at M-1
    ORA     A
    JZ      R_GEN_FC_ERROR				;Generate FC error
    PUSH    PSW
    MOV     A,M
    CALL    L_GET_OPT_LEN				;get an optional length argument
    PUSH    D
    CALL    L_FRMEQL					;check for '=' and evaluate next expression
    PUSH    H
    CALL    L_FRESTR					;FREE UP TEMP & CHECK STRING
    XCHG
    POP     H
    POP     B
    POP     PSW
    MOV     B,A
    XTHL
    PUSH    H
    LXI     H,L_POP_HL					;POP H & return continuation function
    XTHL
    MOV     A,C
    ORA     A
    RZ
    MOV     A,M
    SUB     B
    JC      R_GEN_FC_ERROR				;Generate FC error
    INR     A
    CMP     C
    JC      +
    MOV     A,C
+	MOV     C,B
    DCR     C
    MVI     B,00H
    PUSH    D
    INX     H
    MOV     E,M
    INX     H
    MOV     H,M
    MOV     L,E
    DAD     B
    MOV     B,A
    POP     D
    XCHG
    MOV     C,M
    INX     H
	GETHLFROMM							;get ptr to HL
    XCHG
    MOV     A,C
    ORA     A
    RZ
-	LDAX    D
    MOV     M,A
    INX     D
    INX     H
    DCR     C
    RZ
    DCR     B
    JNZ     -
    RET
;
; get an optional length argument
;
; OUT:
;	E		Length. -1 if not present
;
L_GET_OPT_LEN:
    MVI     E,0FFH						;preset
    CPI     ')'
    JZ      +
	SYNCHK	','
    CALL    L_GETBYT    				;Evaluate byte expression at M-1
+	SYNCHK	')'	
    RET
;
; FRE function
;
;
R_FRE_FUN:								;2B4CH
    LHLD    STRGEND_R					;Unused memory pointer to DE
    XCHG
    LXI     H,0
    DAD     SP							;current SP to HL
;If not string, Subtract SP - [STRGEND_R] and unsigned convert to SNGL in FAC1
    LSTTYP								;Determine type of last var used: C Clr = DBL P Clr = SNGL Z Set = String S: Set = Integer
    JNZ     L_SUB_DE_FROM_HL			;brif !string type: return SP - [STRGEND_R]	
; last variable was a string
    CALL    L_FREFAC
    CALL    L_GARBA2
    XCHG
    LHLD    STRBUF_R					;BASIC string buffer pointer to DE
    XCHG
    LHLD    FRETOP_R					;Pointer to current location in BASIC string buffer
    JMP     L_SUB_DE_FROM_HL			;Subtract HL - DE and unsigned convert to SNGL in FAC1
;
; Double precision subtract (FAC1=FAC1-FAC2)
;
R_DBL_SUB:								;2B69H
    LXI     H,DFACLO2_R				    ;Start of FAC2
    MOV     A,M							;get FAC2 exponent
    ORA     A
    RZ									;retif FAC2 == 0
    XRI     80H							;flip sign bit
    MOV     M,A
    JMP     R_DBL_ADD_1
;
; Double precision addition (FAC1=FAC1+M)
;
R_DBL_ADD_M:
    CALL    R_LOAD_FAC2_FROM_M       	;Move M to FAC2 using precision at (VALTYP_R)
;
; Double precision addition (FAC1=FAC1+FAC2)
;
R_DBL_ADD:								;2B78H
    LXI     H,DFACLO2_R				    ;Start of FAC2
    MOV     A,M							;get FAC2 exponent
    ORA     A
    RZ									;retif FAC2 == 0
R_DBL_ADD_1:
    ANI     7FH							;clear sign bit FAC2
    MOV     B,A							;save in B
    LXI     D,DFACLO_R				    ;FAC1
    LDAX    D							;get FAC1 exponent
    ORA     A
    JZ      L_CPY_FAC2_TO_1				;brif FAC1 == 0: FAC2 is result of addition
    ANI     7FH							;clear sign bit FAC1
    SUB     B
    JNC     R_DBL_ADD_2					;brif FAC1 exponent >= FAC2 exponent
;
; FAC1 exponent < FAC2 exponent: swap FAC1 and FAC2
;
    CMA									;negate exponent delta
    INR     A
    PUSH    PSW							;save exponent delta
    PUSH    H							;save FAC2 ptr
    MVI     B,08H						;8 digits
-	LDAX    D							;swap [DE] & M using C
    MOV     C,M
    MOV     M,A							
    MOV     A,C
    STAX    D							
    INX     D							;update ptrs
    INX     H
    DCR     B							;decrement digit count
    JNZ     -							;brif more digits
    POP     H							;restore FAC2 ptr
    POP     PSW							;restore exponent delta
R_DBL_ADD_2:
    CPI     10H							;compare exponent delta with 16
    RNC									;retif exponent delta >= 16
    PUSH    PSW							;save exponent delta
    XRA     A
    STA     DFACLO_R+8					;Point to extended precision portion of FAC1
    STA     DFACLO2_R+8
    LXI     H,DFACLO2_R+1				;point to FAC2 mantissa TODO could do INX H
    POP     PSW							;restore exponent delta
    CALL    L_SHIFT_BCD					;Shift FAC2 BCD digits based on exponent delta
    LXI     H,DFACLO2_R					;Start of FAC2
    LDA     DFACLO_R					;exponent FAC1 
    XRA     M							;check sign bits
    JM      L_SUB_BCD_FAC1				;brif sign bit set: FAC1 and FAC2 have opposite signs
    LDA     DFACLO2_R+8
    STA     DFACLO_R+8					;Point to extended precision portion of FAC1
    CALL    R_BCD_ADD					;Add FAC2 to FAC1
    JNC     L_ROUND_FAC1				;Round FAC1 using extended precision portion at end of FAC1
    XCHG
    MOV     A,M
    INR     M
    XRA     M
    JM      R_GEN_OV_ERROR				;Generate OV error
    CALL    L_ROTATER_FAC1				;Rotate FAC1 BCD digits right
    MOV     A,M
    ORI     10H							;set bit 4
    MOV     M,A
    JMP     L_ROUND_FAC1				;Round FAC1 using extended precision portion at end of FAC1
; 
; FAC1 and FAC2 have opposite signs. Add using Ten's complement of FAC2
; Normalize FAC1 such that the 1st BCD digit isn't zero
; 
L_SUB_BCD_FAC1:
    CALL    L_TEN_COMPLEMENT			;Part of Normalize FAC1 routine.
L_NORM_BCD_FAC1_1:
    LXI     H,DFACLO_R+1				;Point to BCD portion of FAC1
    LXI     B,0800H						;Prepare to process 8 bytes, C = 0 = BCD Shift distance
-	MOV     A,M							;Test next 2 digits from FAC1
    ORA     A							;Test for digits "00"
    JNZ     +							;brif not "00"
    INX     H							;Increment to next 2 digits in FAC1 - Skip this byte
    DCR     C							;Decrement Digit counter
    DCR     C							;Decrement Digit counter
    DCR     B							;Decrement byte counter
    JNZ     -							;brif not all bytes processed
; all 8 BCD digit pairs were 0
    JMP     L_SET_FAC_ZERO				;Initialize FAC1 to zero
	
; 
; First non "00" BCD digit found. Test MSB for zero & adjust
; 
+	ANI     0F0H						;Mask off the lower digit to see if BCD shift needed (4-bit shift)
    JNZ     +							;Jump ahead if not zero MSB of this byte isn't zero
    PUSH    H							;Save pointer to current location in FAC1
    CALL    L_ROTATEL_FAC1				;Rotate FAC1 1 BCD digit left to normalize starting at HL for B bytes
    POP     H							;Restore current pointer into FAC1
    DCR     C                           ;Decrement the digit counter
+	MVI     A,08H         				;Prepare to calculate number of bytes with "00" that were skipped              
    SUB     B                           ;Subtract 8 from the byte counter to test if first set of digits
    JZ      L_SET_DEC_PNT               ;Skip copying bytes to FAC1 if no bytes	to copy (already normalized)
    PUSH    PSW                         ;Preserve count of bytes skipped on stack
    PUSH    B                           ;Preserve BC on stack
    MOV     C,B                         ;Move number of bytes to copy to C
    LXI     D,DFACLO_R+1				;Point to BCD portion of FAC1
    CALL    R_MOVE_C_BYTES_UP			;Move C bytes from M to (DE) going UP
    POP     B							;Restore byte counter from stack
    POP     PSW                         ;Restore A from stack
    MOV     B,A                         ;Move count of bytes skipped to B to use as a count to zero out the end
    XRA     A                           ;Prepare to zero out B bytes from end of FAC1 that were shifted left
-	STAX    D                           ;Zero out next LSB from BCD
    INX     D                           ;Increment to next lower BCD value in FAC1
    DCR     B                           ;Decrement the counter
    JNZ     -							;Loop until all bytes zeroed
; 
; BCD portion of FAC1 normalized. Update Decimal point location and round
; 
L_SET_DEC_PNT:
    MOV     A,C							;Get digit count from normalize
    ORA     A							;Test if no bytes copied from normalize (don't need to adjust decimal point)
    JZ      L_ROUND_FAC1				;Jump to round if BCD value was not shifted / normalized
    LXI     H,DFACLO_R				 	;FAC1
    MOV     B,M							;Get current sign / decimal point location
    ADD     M							;Add number of BCD digits shifted to calcu
    MOV     M,A                         ;Save new decimal point location
    XRA     B                           ;Test for overflow in shift (too small)
    JM      R_GEN_OV_ERROR				;Generate OV error if 1e-66 or less
    RZ                          		;Return if FAC1 is zero -- no need to round
; 
; Round FAC1 using extended precision portion at end of FAC1
; 
L_ROUND_FAC1:
    LXI     H,DFACLO_R+8				;Point to extended precision portion of FAC1
    MVI     B,07H						;Prepare to perform rounding operation on 7 byte of BCD
L_ROUND_FAC1_1:
    MOV     A,M							;Get "fraction portion" of FAC1
    CPI     50H							;Test for value 0.50 decimal (this is BCD)
    RC									;Return if less than 0.50 - no rounding needed
    DCX     H							;Decrement to next higher BCD pair
    XRA     A							;Clear A to perform ADD of 1 to FAC1 (to perform round up)
    STC									;Set the carry (this is our "1")
-	ADC     M							;Add Zero with carry to the next BCD pair
    DAA                             	;Decimal adjust for BCD calculations
    MOV     M,A                         ;Save this byte of BCD data
    RNC                             	;Return if no more carry to additional bytes
    DCX     H                           ;Decrement to next higher BCD pair
    DCR     B                           ;Decrement byte count
    JNZ     -							;Loop until all bytes rounded (or no carry)
    MOV     A,M                         ;We rounded to the last byte and had Carry. Must shift decimal point.
    INR     M                           ;Increment the decimal point position to account for carry
    XRA     M                           ;Test for overflow during rounding
    JM      R_GEN_OV_ERROR				;Generate OV error
    INX     H							;Increment to 1st BCD pair to change from .99 to 1.00
    MVI     M,10H						;Change value to 1.0 since our "carry" was really a decimal point shift
    RET

; 
; Add FAC2 to FAC1
; 
R_BCD_ADD:
    LXI     H,DFACLO2_R+7				;Point to end of FAC2
    LXI     D,DFACLO_R+7				;Point to end of FAC1
    MVI     B,07H
;
; Add the BCD num in M to the one in (DE)
;
R_BCD_ADD_M_TO_DE:
    XRA     A							;Clear carry for 1st ADD
; 
; Add next bytes of FAC2 to FAC1
; 
-	LDAX    D							;Load first byte into A
    ADC     M							;ADD with carry the next byte from M
    DAA									;preserve Carry until next ADC
    STAX    D							;Store sum at (DE)
    DCX     D							;Decrement to next higher position of DE
    DCX     H							;Decrement to next higher position of HL
    DCR     B							;Decrement byte counter
    JNZ     -							;Keep looping until byte count = 0
    RET
	
; 
; FAC1 and FAC2 have opposite signs.
; Take Ten's Complement of FAC2 and add it to FAC1
; 
L_TEN_COMPLEMENT:
    LXI     H,DFACLO2_R+8				;Point to extended precision portion of FAC2
    MOV     A,M							;Get extended precision portion to test for rounding
    CPI     50H							;Compare with 50 BCD (represent 0.50)
    JNZ     +							;brif extended precision portion of FAC2 != 0.50
    INR     M							;Increment extended precision portion of FAC2 to 51
+	LXI     D,DFACLO_R+8				;Point to extended precision portion of FAC1
    MVI     B,08H						;Prepare to compute ten's complement of FAC2
    STC									;Set carry to initiate no-borrow
-	MVI     A,99H						;Load 99 BCD into A
    ACI     00H							;Add carry
    SUB     M							;Subtract extended precision portion of FAC2 from 99 BCD
    MOV     C,A							;Save difference in C
    LDAX    D							;Load next byte from FAC1
    ADD     C							;Add difference of 99-FAC2
    DAA									;Decimal adjust for BCD value
    STAX    D							;Store in FAC1 (FAC1 = FAC1 + (999999999 - FAC2))
    DCX     D							;Decrement to next higher BCD pair for FAC1
    DCX     H							;Decrement to next higher BCD pair for FAC2
    DCR     B							;Decrement byte count
    JNZ     -							;Keep looping until count = 0
    RC									;Return if no borrow
; borrow happened so negate FAC1 using Ten's Complement
    XCHG
    MOV     A,M							;get exponent
    XRI     80H							;flip sign bit
    MOV     M,A							;update exponent
    LXI     H,DFACLO_R+8				;Point to extended precision portion of FAC1
    MVI     B,08H						;BCD count
    XRA     A							;clear carry
-	MVI     A,9AH
    SBB     M
    ACI     00H
    DAA									;Decimal adjust
    CMC									;complement carry
    MOV     M,A							;update memory
    DCX     H							;next
    DCR     B							;count
    JNZ     -
    RET
; 
; Rotate FAC1 1 BCD digit left to normalize starting at HL for B bytes
; 
L_ROTATEL_FAC1:
    LXI     H,DFACLO_R+8				;Point to end of FAC1 (+1 to rotate in a "0")
; 
; Rotate M 1 BCD digit left to normalize starting at HL for B bytes
; 
L_ROTATEL_M:
    PUSH    B							;Preserve byte & digit count on stack
    MOV     D,B							;save inner loop counter in D
    MVI     C,04H						;outer loop counter
L_ROTATE_LEFT_1:
    PUSH    H							;save M ptr
    ORA     A							;clear carry
-	MOV     A,M							;rotate M left
    RAL
    MOV     M,A
    DCX     H							;backup ptr
    DCR     B							;decrement counter
    JNZ     -
    MOV     B,D							;reset inner loop counter
    POP     H							;restore M ptr
    DCR     C							;decrement counter
    JNZ     L_ROTATE_LEFT_1
    POP     B							;restore byte & digit count 
    RET
;
; Shift BCD digits of DBL BCD number pointed to by HL
;
; IN:
;	A		exponent delta between FAC1 and FAC2
;	HL		FAC2 mantissa ptr
;
L_SHIFT_BCD:
    ORA     A							;clear carry
    RAR									;bit 0 to carry. bit 7 now 0
; A is now exponent delta /2
    PUSH    PSW							;first save
    ORA     A							;test A
    JZ      L_POP_ROTATER_M				;brif no more exponent delta.
    PUSH    PSW							;second save
    CMA									;negate exponent delta /2 
    INR     A
    MOV     C,A							;sign extend to BC
    MVI     B,0FFH
    LXI     D,0007H						;make HL point to last mantissa position
    DAD     D
    MOV     D,H							;DE points to last mantissa position
    MOV     E,L
    DAD     B							;HL points to delta mantissa position
    MVI     A,08H						;compute # of BCD digits to move
    ADD     C
    MOV     C,A							;result to C
    PUSH    B							;save BC
    CALL    R_MOVE_C_BYTES_DEC			;Move C bytes from M to (DE) going down
    POP     B							;restore BC
    POP     PSW							;last pushed A
    INX     H							;update ptrs
    INX     D
    PUSH    D							;save DE
    MOV     B,A
    XRA     A							;clear moved BCD digits
-	MOV     M,A
    INX     H
    DCR     B
    JNZ     -
    POP     H							;load HL from saved DE
    POP     PSW							;first pushed A
    RNC									;retif no carry: done
    MOV     A,C
; 
; Rotate M 1 BCD digit right to normalize starting at HL for A bytes
; 
L_ROTATE_RIGHT:
    PUSH    B							;save BC
    PUSH    D							;save DE
    MOV     D,A							;store inner loop counter in D
    MVI     C,04H						;outer loop counter
L_ROTATE_RIGHT_1:
    MOV     B,D							;inner loop counter
    PUSH    H							;save HL
    ORA     A							;clear carry
-	MOV     A,M							;rotate M right
    RAR
    MOV     M,A
    INX     H							;next
    DCR     B							;decrement counter
    JNZ     -
    POP     H							;restore HL
    DCR     C							;decrement counter
    JNZ     L_ROTATE_RIGHT_1
    POP     D							;restore DE
    POP     B							;restore BC
    RET

; 
; Rotate FAC1 1 BCD digit right to normalize starting at HL for 8 bytes
; 
L_ROTATER_FAC1:
    LXI     H,DFACLO_R+1				;Point to BCD portion of FAC1
L_ROTATER_M:
    MVI     A,08H
    JMP     L_ROTATE_RIGHT

L_POP_ROTATER_M:
    POP     PSW
    RNC
    JMP     L_ROTATER_M					;rotate right M 8 BCD digits
;
; Double precision multiply (FAC1=FAC1*FAC2)
;
R_DBL_MULT:								;2CFFH
    FSIGN								;Return 1 or -1 in A based on Sign bit of FAC1
    RZ									;retif FAC1 == 0.0
    LDA     DFACLO2_R					;Start of FAC2
    ORA     A
    JZ      L_SET_FAC_ZERO				;brif FAC2 == 0: Initialize FAC1 for SGL & DBL precision to zero
    MOV     B,A							;FAC2 exponent
    LXI     H,DFACLO_R				    ;FAC1
    XRA     M							;xor both exponents
    ANI     80H							;isolate sign bit
    MOV     C,A							;save sign bit or result
    MOV     A,B
    ANI     7FH
    MOV     B,A
    MOV     A,M
    ANI     7FH
    ADD     B
    MOV     B,A
    MVI     M,00H
    ANI     0C0H
    RZ
    CPI     0C0H
    JNZ     +
    JMP     R_GEN_OV_ERROR				;Generate OV error
	
; 
; Multiply BCD portion of FAC1*FAC2
; 
+	MOV     A,B							;Reload the sum of the decimal points
    ADI		40H							;Add 40H to it (the "zero" point)
    ANI     7FH							;Mask off the upper bit (where sign bit goes)
    RZ									;retif the product generates zero
    ORA     C							;OR in the sign of the product
    DCX     H							;Decrement HL to save decimal point & sign temporarily
    MOV     M,A							;Save decimal & sign
    LXI     D,BCDTMP8_R					;Temp BCD value for computation
    LXI     B,08H						;Prepare to copy 8 bytes of BCD
    LXI     H,DFACLO_R+7				;Point to end of FAC1
    PUSH    D							;save ptr to BCDTMP8_R
    CALL    R_MOVE_C_BYTES_DEC			;Move C bytes from M to (DE) going down: Copy FAC1 to BCDTMP8_R
    INX     H							;Increment to beginning of FAC1
    XRA     A							;Clear A
    MVI     B,08H						;Prepare to clear 8 bytes of FAC1
-	MOV     M,A							;Zero out next byte of FAC1
    INX     H							;next
    DCR     B							;counter
    JNZ     -							;brif not done
    POP     D							;restore ptr to BCDTMP8_R
    LXI     B,L_SET_SIGN_NORM			;Load continuation function to retrieve saved Decimal/sign byte and normalize FAC1
    PUSH    B							;new return address
;
; Multiply BCD at (HL) times BCD at (DE)
; DE must be ptr to BCDTMP8_R
;
L_MULTBCD_DE_HL:
    CALL    L_BCDx248					;Multiply BCD at (DE) x2, x4 and x8 into BCD_TEMP7, BCD_TEMP6, BCD_TEMP5. Uses HL
    PUSH    H							;Push address of BCD_TEMP4 to stack
    LXI     B,08H						;B=0 C=8
    XCHG								;BCD_TEMP4 to DE. BCD_TEMP5 to HL
    CALL    R_MOVE_C_BYTES_DEC			;Move 8 bytes from M (BCD_TEMP5) to (DE BCD_TEMP4) going down
    XCHG								;BCD_TEMP4 to DE
    LXI     H,BCDTMP7_R					;Point to BCD_TEMP7 (x2)
    MVI     B,08H						;Prepare to add 8 bytes of BCD (Add BCD_TEMP3 to BCD_TEMP7)
    CALL    R_BCD_ADD_M_TO_DE			;Add BCD value at (HL) to the one at (DE) -- BCD_TEMP4 = x8 + x2 = x10
    POP     D							;POP address of BCD_TEMP4 from stack
; DE is BCD_TEMP4 here
    CALL    L_BCDx248					;Multiply BCD_TEMP4 (x10) times 2, 4 and 8 into BCD_TEMP3, BCD_TEMP2, BCD_TEMP1
    MVI     C,07H						;Prepare to multiply 7 bytes of BCD from FAC2?
    LXI     D,DFACLO2_R+7				;Point to end of FAC2
-	LDAX    D							;Load next BCD pair from FAC2
    ORA     A							;Test if byte pair is "00"
    JNZ     L_MULTBCD_1						;Jump to start multiply when first non "00" BCD found
    DCX     D							;Decrement to next higher BCD pair
    DCR     C							;Decrement byte counter (no need to test for zero - we won't be here if FAC2=0.0000)
    JMP		-							;Jump to test next byte of FAC2
;
; First non "00" BCD in FAC2 found. Perform multiply?
;
L_MULTBCD_1:
    LDAX    D							;Load next byte of BCD from FAC2
    DCX     D							;Decrement to next higher BCD pair in FAC2
    PUSH    D							;Save address of BCD pair being processed in FAC2 to stack
    LXI     H,BCDTMP1_R					;Point to BCD_TEMP1 (this is FAC1 x 80)
L_MULTBCD_2:
    ADD     A							;Multiply BCD from FAC2 x 2
    JC      +							;Add BCD value at (HL) to FAC1
    JZ      L_DIV_EXTFAC1_BY_100		;If zero (overflow to 100H), then jump to divide by 100
-	LXI     D,08H						;Prepare to point to next BCD_TEMPx value
    DAD     D							;Advance HL to next BCD_TEMPx value
    JMP     L_MULTBCD_2					;Jump to test if this BCD_TEMPx value should be added to FAC1
; 
; Add BCD value at (HL) to FAC1
; 
+	PUSH    PSW							;save A
    MVI     B,08H						;BCD count
    LXI     D,DFACLO_R+7				;Point to end of FAC1
    PUSH    H							;save HL
    CALL    R_BCD_ADD_M_TO_DE			;Add BCD value at (HL) to the one at FAC1
    POP     H							;restore HL
    POP     PSW							;restore A
    JMP     -							;Jump to test if next BCD_TEMPx value should be added to FAC1
;
; Divide extended precision FAC1 by 100 and test for end of multiply
;
L_DIV_EXTFAC1_BY_100:
    MVI     B,0FH						;Prepare to shift 15 bytes (extended precision) of FAC1
    LXI     D,DFACLO_R+14				;Start 1 byte from end of FAC1 (extended precision)
    LXI     H,DFACLO_R+15				;Move to last byte of FAC1 (this is /100 because of BCD)
    CALL    R_MOVE_B_BYTES_DEC 			;Move B bytes from (DE) to M with decrement
    MVI     M,00H						;Set the 1st byte (sign / decimal point) to zero
    POP     D							;Restore pointer to current BCD pair in FAC2
    DCR     C							;Decrement BCD count for FAC2
    JNZ     L_MULTBCD_1					;Jump to process next byte
    RET									;Return to our hook (below) to retrieve the Decimal/sign & normalize
;
; retrieve saved Decimal/sign byte and normalize FAC1
;
L_SET_SIGN_NORM:
    DCX     H
    MOV     A,M
    INX     H
    MOV     M,A
    JMP     L_NORM_BCD_FAC1_1
;
; BCD numbers are processed right to left.
; each BCD number is 8 bytes (16 decimal digits)
; Multiply BCD at (DE) x2, x4 and x8 into 3 BCD values before (DE)
; Achieved by adding BCD to itself (x2), then adding new BCD to itself (x4)
; then adding newest BCD to itself (x8).
; e.g. DE points to BCDTMP8_R, store products in BCDTMP7_R (x2), BCDTMP6_R (x4),
; BCDTMP5_R (x8), then returns address of BCD_TEMP4 in HL (lowest digit is at the end)
; DE points to BCD_TEMP5 (HL+8)
;
L_BCDx248:
    LXI     H,0FFF8H					;Load -8 into HL
    DAD     D							;HL=DE-8 -- Point to next lower temp BCD value
    MVI     C,03H						;Prepare to process 3 floating point values
L_BCDx248_1:
    MVI     B,08H						;Load byte counter for 1 floating point value
    ORA     A							;clear carry
-	LDAX    D
    ADC     A
    DAA									;preserve Carry until next ADC
    MOV     M,A
    DCX     H							;destination
    DCX     D							;source
    DCR     B
    JNZ     -
    DCR     C
    JNZ     L_BCDx248_1
    RET
;
; Double precision divide (FAC1=FAC1/FAC2)
;
R_DBL_DIV:								;2DC7H
    LDA     DFACLO2_R					;Start of FAC2
    ORA     A
    JZ      R_GEN_D0_ERROR				;Generate /0 error
    MOV     B,A
    LXI     H,DFACLO_R				    ;FAC1
    MOV     A,M
    ORA     A
    JZ      L_SET_FAC_ZERO				;Initialize FAC1 for SGL & DBL precision to zero
    XRA     B
    ANI     80H
    MOV     C,A
    MOV     A,B
    ANI     7FH
    MOV     B,A
    MOV     A,M
    ANI     7FH
    SUB     B
    MOV     B,A
    RAR
    XRA     B
    ANI     40H
    MVI     M,00H
    JZ      L_DBL_DIV_1
    MOV     A,B
    ANI     80H
    RNZ
-	JMP     R_GEN_OV_ERROR				;Generate OV error

L_DBL_DIV_1:
    MOV     A,B
    ADI		41H
    ANI     7FH
    MOV     M,A
    JZ      -
    ORA     C
    MVI     M,00H
    DCX     H
    MOV     M,A
    LXI     D,DFACLO_R+7				;Point to end of FAC1
    LXI     H,DFACLO2_R+7				;Point to end of FAC2
    MVI     B,07H
-	MOV     A,M
    ORA     A							;Test if byte pair is "00"
    JNZ     +
    DCX     D
    DCX     H
    DCR     B
    JNZ     -
+	SHLD    FPTMP5_R
    XCHG
    SHLD    FPTMP4_R
    MOV     A,B
    STA     FPTMP6_R
    LXI     H,FPTMP2_R				    ;Floating Point Temp 2
L_DBL_DIV_3:
    MVI     B,0FH
L_DBL_DIV_4:
    PUSH    H
    PUSH    B
    LHLD    FPTMP5_R
    XCHG
    LHLD    FPTMP4_R
    LDA     FPTMP6_R
    MVI     C,0FFH
L_DBL_DIV_5:
    STC
    INR     C
    MOV     B,A
    PUSH    H
    PUSH    D
-	MVI     A,99H
    ACI     00H
    XCHG
    SUB     M
    XCHG
    ADD     M
    DAA
    MOV     M,A
    DCX     H
    DCX     D
    DCR     B
    JNZ     -
    MOV     A,M
    CMC
    SBI     00H
    MOV     M,A
    POP     D
    POP     H
    LDA     FPTMP6_R
    JNC     L_DBL_DIV_5
    MOV     B,A
    XCHG
    CALL    R_BCD_ADD_M_TO_DE
    JNC     +
    XCHG
    INR     M
+	MOV     A,C
    POP     B
    MOV     C,A
    PUSH    B
    MOV     A,B
    ORA     A							;clear carry
    RAR
    MOV     B,A
    INR     B
    MOV     E,B
    MVI     D,00H
    LXI     H,FPTMP7_R
    DAD     D
    CALL    L_ROTATEL_M					;Rotate M 1 BCD digit left for B bytes
    POP     B
    POP     H
    MOV     A,B
    INR     C
    DCR     C
    JNZ     L_DBL_DIV_8
    CPI     0FH
    JZ      L_DBL_DIV_7
    RRC
    RLC    
    JNC     L_DBL_DIV_8
    PUSH    B
    PUSH    H
    LXI     H,DFACLO_R				    ;FAC1
    MVI     B,08H
-	MOV     A,M
    ORA     A
    JNZ     L_DBL_DIV_6
    INX     H
    DCR     B
    JNZ     -
    POP     H
    POP     B
    MOV     A,B
    ORA     A							;clear carry
    RAR
    INR     A
    MOV     B,A
    XRA     A
-	MOV     M,A
    INX     H
    DCR     B
    JNZ     -
    JMP     L_DBL_DIV_10

L_DBL_DIV_6:
    POP     H
    POP     B
    MOV     A,B
    JMP     L_DBL_DIV_8

L_DBL_DIV_7:
    LDA     FPTMP7_R
    MOV     E,A
    DCR     A
    STA     FPTMP7_R
    XRA     E
    JP      L_DBL_DIV_3
    JMP     L_SET_FAC_ZERO				;Initialize FAC1 for SGL & DBL precision to zero
; A contains index in BCD digits number
L_DBL_DIV_8:
    RAR									;bit 0 (odd or even) to carry
    MOV     A,C							;restore A
    JC      +							;brif odd digit
    ORA     M
    MOV     M,A
    INX     H
    JMP     L_DBL_DIV_9
; move upper nibble into lower nibble
+	ADD     A							;x2
    ADD     A							;x4
    ADD     A							;x8
    ADD     A							;x16
    MOV     M,A
L_DBL_DIV_9:
    DCR     B
    JNZ     L_DBL_DIV_4
L_DBL_DIV_10:
    LXI     H,DFACLO_R+8				;Point to extended precision portion of FAC1
    LXI     D,BCDTMP8_R
    MVI     B,08H
    CALL    R_MOVE_B_BYTES_DEC       	;Move B bytes from (DE) to M with decrement
    JMP     L_SET_SIGN_NORM				;retrieve saved Decimal/sign byte and normalize FAC1
	
;
;Move C bytes from M to (DE) going UP
;
R_MOVE_C_BYTES_UP:
    MOV     A,M
    STAX    D
    INX     H
    INX     D
    DCR     C
    JNZ     R_MOVE_C_BYTES_UP
    RET
	
;
;Move C bytes from M to (DE) going DOWN
;
R_MOVE_C_BYTES_DEC:						;2EE6H
    MOV     A,M
    STAX    D
    DCX     H
    DCX     D
    DCR     C
    JNZ     R_MOVE_C_BYTES_DEC			;Move C bytes from M to (DE)
    RET
;
; COS function
;
R_COS_FUN:								;2EEFH
    LXI     H,R_FP_NUMBERS_11			;Code Based. 
    CALL    R_MULT_M_FAC2				;Double precision math (FAC1=M * FAC2))
    LDA     DFACLO_R					;FAC1
    ANI     7FH
    STA     DFACLO_R					;FAC1
    LXI     H,R_DL_PNT25				;0.25 DBL constant
    CALL    R_SUB_M_FAC1
    CALL    L_NEG						;Negate FAC1
    JMP     L_SIN_1						;join SIN code
;
; SIN function
;
R_SIN_FUN:								;2F09H
    LXI     H,R_FP_NUMBERS_11			;Code Based. 
    CALL    R_MULT_M_FAC2				;Double precision math (FAC1=M * FAC2))
L_SIN_1:
    LDA     DFACLO_R					;FAC1
    ORA     A
    CM      L_NEG_NEG					;Take NEG(FAC1) and push return address to NEG(FAC1)
    CALL    R_PUSH_FAC1				    ;Push FAC1 on stack
    CALL    R_INT_FUN				    ;INT function
    CALL    R_FAC2_EQ_FAC1				;Move FAC1 to FAC2
    CALL    R_POP_FAC1				    ;Pop FAC1 from stack
    CALL    R_DBL_SUB				    ;Double precision subtract (FAC1=FAC1-FAC2)
    LDA     DFACLO_R					;FAC1
    CPI     40H
    JC      L_SIN_2
    LDA     DFACLO_R+1					;Point to BCD portion of FAC1
    CPI     25H
    JC      L_SIN_2
    CPI     75H
    JNC     +
    CALL    R_FAC2_EQ_FAC1				;Move FAC1 to FAC2
    LXI     H,R_DBL_PNT5				;Code Based. 0.500000000000
    CALL    R_FAC1_EQ_FP				;Move floating point number M to FAC1
    CALL    R_DBL_SUB				    ;Double precision subtract (FAC1=FAC1-FAC2)
    JMP     L_SIN_2

+	LXI     H,R_DBL_ONE					;Code Based. 1.0
    CALL    R_FAC2_EQ_FP				;Move floating point number M to FAC2
    CALL    R_DBL_SUB				    ;Double precision subtract (FAC1=FAC1-FAC2)
L_SIN_2:
    LXI     H,R_SIN_MATH_TBL			;Code Based. 
    JMP     R_MULT_FAC1_PWR2_TBL		;FAC1 = FAC1 * (FAC1^2 * table based math)
;
; TAN function
; TAN(X)=SIN(X)/COS(X)
;
R_TAN_FUN:								;2F58H
    CALL    R_PUSH_FAC1				    ;Push FAC1 on stack
    CALL    R_COS_FUN				    ;COS function
    CALL    L_SWP_FAC_SP
    CALL    R_SIN_FUN				    ;SIN function
    CALL    R_POP_FAC2				    ;Pop FAC2 from stack
    LDA     DFACLO2_R					;Start of FAC2
    ORA     A
    JNZ     R_DBL_DIV				    ;Double precision divide (FAC1=FAC1/FAC2)
    JMP     R_GEN_OV_ERROR				;Generate OV error
;
; ATN function
;
R_ATN_FUN:								;2F71H
    LDA     DFACLO_R					;get exponent from FAC1
    ORA     A
    RZ									;retif number == 0
    CM      L_NEG_NEG					;Take NEG(FAC1) and push return address to NEG(FAC1)
    CPI     41H
    JC      L_ATN_1						;brif A < 41H
    CALL    R_FAC2_EQ_FAC1				;Move FAC1 to FAC2
    LXI     H,R_DBL_ONE					;Code Based. 1.0
    CALL    R_FAC1_EQ_FP				;Move floating point number M to FAC1
    CALL    R_DBL_DIV				    ;Double precision divide (FAC1=FAC1/FAC2)
    CALL    L_ATN_1
    CALL    R_FAC2_EQ_FAC1				;Move FAC1 to FAC2
    LXI     H,R_FP_NUMBERS_7			;Code Based. 
    CALL    R_FAC1_EQ_FP				;Move floating point number M to FAC1
    JMP     R_DBL_SUB				    ;Double precision subtract (FAC1=FAC1-FAC2)

; 
; Perform series approximation for ATN
; 
L_ATN_1:
    LXI     H,R_FP_NUMBERS_8			;Code Based. 
    CALL    R_CMP_FAC1_M
    JM      L_ATN_TBL
    CALL    R_PUSH_FAC1				    ;Push FAC1 on stack
    LXI     H,R_FP_NUMBERS_9			;Code Based. 
    CALL    R_ADD_M_FAC1
    CALL    L_SWP_FAC_SP
    LXI     H,R_FP_NUMBERS_9			;Code Based. 
    CALL    R_MULT_M_FAC2				;Double precision math (FAC1=M * FAC2))
    LXI     H,R_DBL_ONE					;Code Based. 1.0
    CALL    R_SUB_M_FAC1
    CALL    R_POP_FAC2				    ;Pop FAC2 from stack
    CALL    R_DBL_DIV				    ;Double precision divide (FAC1=FAC1/FAC2)
    CALL    L_ATN_TBL
    LXI     H,R_FP_NUMBERS_10			;Code Based. 
    JMP     R_ADD_M_FAC1
	
; 
; Do table based math for ATN
; 
L_ATN_TBL:
    LXI     H,R_ATN_MATH_TBL			;Code Based. 
    JMP     R_MULT_FAC1_PWR2_TBL		;FAC1 = FAC1 * (FAC1^2 * table based math)
;
; LOG function
;
R_LOG_FUN:								;2FCFH
    FSIGN								;Return 1 or -1 in A based on Sign bit of FAC1
    JM      R_GEN_FC_ERROR				;brif FAC1 is negative: Generate FC error
    JZ      R_GEN_FC_ERROR				;brif FAC1 is 0.0: Generate FC error
    LXI     H,DFACLO_R				    ;FAC1
    MOV     A,M							;get FAC1 exponent
    PUSH    PSW							;save it
    MVI     M,41H						;set exponent
    LXI     H,R_FP_NUMBERS_4			;Code Based. 3.1622776601684
    CALL    R_CMP_FAC1_M
    JM      +
    POP     PSW
    INR     A
    PUSH    PSW
    LXI     H,DFACLO_R				    ;FAC1
    DCR     M
+	POP     PSW
    STA     TEMP3_R
    CALL    R_PUSH_FAC1				    ;Push FAC1 on stack
    LXI     H,R_DBL_ONE					;Code Based. 1.0
    CALL    R_ADD_M_FAC1
    CALL    L_SWP_FAC_SP
    LXI     H,R_DBL_ONE					;Code Based. 1.0
    CALL    R_SUB_M_FAC1
    CALL    R_POP_FAC2				    ;Pop FAC2 from stack
    CALL    R_DBL_DIV				    ;Double precision divide (FAC1=FAC1/FAC2)
    CALL    R_PUSH_FAC1				    ;Push FAC1 on stack
    CALL    R_DBL_SQR				    ;Double precision Square (FAC1=SQR(FAC1))
    CALL    R_PUSH_FAC1				    ;Push FAC1 on stack
    CALL    R_PUSH_FAC1				    ;Push FAC1 on stack
    LXI     H,R_LOG_MATH_TBL_1			;Code Based. 
    CALL    R_TBL_BASED_MATH			;Table based math (FAC1=(((FAC1*M)+(M+1))*(M+2)+(M+3)...
    CALL    L_SWP_FAC_SP
    LXI     H,R_LOG_MATH_TBL			;Code Based. 
    CALL    R_TBL_BASED_MATH			;Table based math (FAC1=(((FAC1*M)+(M+1))*(M+2)+(M+3)...
    CALL    R_POP_FAC2				    ;Pop FAC2 from stack
    CALL    R_DBL_DIV				    ;Double precision divide (FAC1=FAC1/FAC2)
    CALL    R_POP_FAC2				    ;Pop FAC2 from stack
    CALL    R_DBL_MULT				    ;Double precision multiply (FAC1=FAC1*FAC2)
    LXI     H,R_FP_NUMBERS_5			;Code Based. 
    CALL    R_ADD_M_FAC1
    CALL    R_POP_FAC2				    ;Pop FAC2 from stack
    CALL    R_DBL_MULT				    ;Double precision multiply (FAC1=FAC1*FAC2)
    CALL    R_PUSH_FAC1				    ;Push FAC1 on stack
    LDA     TEMP3_R
    SUI     41H
    MOV     L,A
    ADD     A
    SBB     A
    MOV     H,A
    CALL    R_CONV_SINT_HL_SNGL      	;Convert signed integer HL to single precision FAC1
    CALL    L_CONDS
    CALL    R_POP_FAC2				    ;Pop FAC2 from stack
    CALL    R_DBL_ADD				    ;Double precision addition (FAC1=FAC1+FAC2)
    LXI     H,R_FP_NUMBERS_6			;Code Based. 
    JMP     R_MULT_M_FAC2				;Double precision math (FAC1=M * FAC2))
;
; SQR function
;
R_SQR_FUN:								;305AH
    FSIGN								;Return 1 or -1 in A based on Sign bit of FAC1
    RZ
    JM      R_GEN_FC_ERROR				;Generate FC error
    CALL    R_FAC2_EQ_FAC1				;Move FAC1 to FAC2
    LDA     DFACLO_R					;FAC1
    ORA     A							;clear carry
    RAR
    ACI     20H
    STA     DFACLO2_R					;Start of FAC2
    LDA     DFACLO_R+1					;Point to BCD portion of FAC1
    ORA     A							;clear carry
    RRC
    ORA     A							;clear carry
    RRC
    ANI     33H
    ADI		10H
    STA     DFACLO2_R+1
    MVI     A,07H
-	STA     TEMP3_R
    CALL    R_PUSH_FAC1				   	;Push FAC1 on stack
    CALL    R_PUSH_FAC2				    ;Push FAC2 on stack
    CALL    R_DBL_DIV				    ;Double precision divide (FAC1=FAC1/FAC2)
    CALL    R_POP_FAC2				    ;Pop FAC2 from stack
    CALL    R_DBL_ADD				    ;Double precision addition (FAC1=FAC1+FAC2)
    LXI     H,R_DBL_PNT5				;Code Based. 0.500000000000
    CALL    R_MULT_M_FAC2				;Double precision math (FAC1=M * FAC2))
    CALL    R_FAC2_EQ_FAC1				;Move FAC1 to FAC2
    CALL    R_POP_FAC1				    ;Pop FAC1 from stack
    LDA     TEMP3_R
    DCR     A
    JNZ     -
    JMP     R_FAC1_EQ_FAC2				;Move FAC2 to FAC1
;
; EXP function
;
R_EXP_FUN:								;30A4H
    LXI     H,R_FP_NUMBERS+24			;Code Based. 
    CALL    R_MULT_M_FAC2				;Double precision math (FAC1=M * FAC2))
    CALL    R_PUSH_FAC1				    ;Push FAC1 on stack
    CALL    R_CINT_FUN				    ;CINT function
    MOV     A,L
    RAL
    SBB     A
    CMP     H
    JZ      L_EXP_1
    MOV     A,H
    ORA     A
    JP      +							;TODO jump directly to R_GEN_OV_ERROR
    CALL    L_VALDBL
    CALL    R_POP_FAC1				    ;Pop FAC1 from stack
    LXI     H,R_DBL_ZERO				;Code Based. 
    JMP     R_FAC1_EQ_FP				;Move floating point number M to FAC1

+	JMP     R_GEN_OV_ERROR				;Generate OV error

L_EXP_1:
    SHLD    TEMP3_R
    CALL    L_FRCDBL				    ;CDBL function
    CALL    R_FAC2_EQ_FAC1				;Move FAC1 to FAC2
    CALL    R_POP_FAC1				    ;Pop FAC1 from stack
    CALL    R_DBL_SUB				    ;Double precision subtract (FAC1=FAC1-FAC2)
    LXI     H,R_DBL_PNT5				;Code Based. 0.500000000000
    CALL    R_CMP_FAC1_M
    PUSH    PSW
    JZ      +
    JC      +
    LXI     H,R_DBL_PNT5				;Code Based. 0.500000000000
    CALL    R_SUB_M_FAC1
+	CALL    R_PUSH_FAC1				    ;Push FAC1 on stack
    LXI     H,R_EXP_MATH_TBL_1			;Code Based. 
    CALL    R_MULT_FAC1_PWR2_TBL		;FAC1 = FAC1 * (FAC1^2 * table based math)
    CALL    L_SWP_FAC_SP
    LXI     H,R_EXP_MATH_TBL			;Code Based. 
    CALL    R_SQR_FAC1_MULT_TBL      	;Square FAC1 & do table based math
    CALL    R_POP_FAC2				    ;Pop FAC2 from stack
    CALL    R_PUSH_FAC2				    ;Push FAC2 on stack
    CALL    R_PUSH_FAC1				    ;Push FAC1 on stack
    CALL    R_DBL_SUB				    ;Double precision subtract (FAC1=FAC1-FAC2)
    LXI     H,FPTMP2_R					;Floating Point Temp 2
    CALL    R_MOVE_FAC1_TO_M			;Move FAC1 to M
    CALL    R_POP_FAC2				    ;Pop FAC2 from stack
    CALL    R_POP_FAC1				    ;Pop FAC1 from stack
    CALL    R_DBL_ADD				    ;Double precision addition (FAC1=FAC1+FAC2)
    LXI     H,FPTMP2_R				    ;Floating Point Temp 2
    CALL    R_FAC2_EQ_FP				;Move floating point number M to FAC2
    CALL    R_DBL_DIV				    ;Double precision divide (FAC1=FAC1/FAC2)
    POP     PSW
    JC      +
    JZ      +
    LXI     H,R_FP_NUMBERS_4			;Code Based. 3.1622776601684
    CALL    R_MULT_M_FAC2				;Double precision math (FAC1=M * FAC2))
+	LDA     TEMP3_R
    LXI     H,DFACLO_R				    ;FAC1
    MOV     C,M
    ADD     M
    MOV     M,A
    XRA     C
    RP     
    JMP     R_GEN_OV_ERROR				;Generate OV error
;
; RND function
;
R_RND_FUN:								;313EH
    FSIGN								;Return 1 or -1 in A based on Sign bit of FAC1
    LXI     H,FPRND_R				    ;ptr to Floating Point Random
    JZ      +							;brif FAC1 == 0.0: return last value
    CM      R_MOVE_FAC1_TO_M			;If argument is negative, seed FP_RND (Move FAC1 to M)
    LXI     H,FPTMP2_R				    ;Floating Point Temp 2
    LXI     D,FPRND_R				    ;ptr to Floating Point Random
    CALL    R_MOVE_8_BYTES_INC			;Move Floating point at (DE) to M
    LXI     H,R_FP_NUMBERS+8			;Code Based. 
    CALL    R_FAC2_EQ_FP				;Move floating point number M to FAC2 
    LXI     H,R_FP_NUMBERS				;Code Based. 
    CALL    R_FAC1_EQ_FP				;Move floating point number M to FAC1
    LXI     D,BCDTMP8_R					;Load pointer to BCDTMP8_R
    CALL    L_MULTBCD_DE_HL				;Multiply BCD at BCDTMP8_R times FAC2
    LXI     D,DFACLO_R+8				;Point to extended precision portion of FAC1
    LXI     H,FPRND_R+1					;0FC7AH Point to BCD portion of Floating point number
	MVI		B,7							;Prepare to move BCD portion of floating point
    CALL    R_MOVE_B_BYTES_INC			;Move 7 bytes from (DE) to M with increment
    LXI     H,FPRND_R				    ;ptr to Floating Point Random
    MVI     M,00H						;Make RND seed exponent "e-65"
; 
; Return value from RND generator (FP_RND) in FAC1
; 
+	CALL    R_FAC1_EQ_FP				;Move floating point number M to FAC1
    LXI     H,DFACLO_R				    ;ptr to FAC1
    MVI     M,40H						;Make RND number a sane value < 1 (vs 1.332e-65, etc)
    XRA     A							;clr A
    STA     DFACLO_R+8					;Zero out 1st byte of extended precision portion of FAC1
    JMP     L_NORM_BCD_FAC1_1
;
; Initialize FPRND_R for new program
;
R_INIT_TEMP3:							;3182H
    LXI     D,R_FP_NUMBERS+16			;Code Based. 
    LXI     H,FPRND_R				    ;ptr to Floating Point Random
    JMP     R_MOVE_8_BYTES_INC

; 
; Seed FPRND_R with signed integer HL -- TODO unreachable code
; 
    CALL    R_CONV_SINT_HL_SNGL         ;Convert signed integer HL to single precision FAC1
    LXI     H,FPRND_R				    ;ptr to Floating Point Random
    JMP     R_MOVE_FAC1_TO_M			;Move FAC1 to M

; 
; Double precision add FP at (HL) to FAC1
; 
R_ADD_M_FAC1:
    CALL    R_FAC2_EQ_FP				;Move floating point number M to FAC2
    JMP     R_DBL_ADD				    ;Double precision addition (FAC1=FAC1+FAC2)

; 
; Double precision subtract FP at (HL) from FAC1
; 
R_SUB_M_FAC1:
    CALL    R_FAC2_EQ_FP				;Move floating point number M to FAC2
    JMP     R_DBL_SUB				    ;Double precision subtract (FAC1=FAC1-FAC2)
;
; Double precision Square (FAC1=SQR(FAC1))
;
R_DBL_SQR:								;31A0H
    LXI     H,DFACLO_R					;FAC1
;
; Double precision math (FAC1=M * FAC2))
;
R_MULT_M_FAC2:							;31A3H
    CALL    R_FAC2_EQ_FP				;Move floating point number M to FAC2
    JMP     R_DBL_MULT				    ;Double precision multiply (FAC1=FAC1*FAC2)

; 
; Double precision math (FAC1=M / FAC2)) -- TODO unreachable
; 
    CALL    R_FAC2_EQ_FP				;Move floating point number M to FAC2
    JMP     R_DBL_DIV				    ;Double precision divide (FAC1=FAC1/FAC2)

; 
; Double precision compare FAC1 with floating point at HL
; 
R_CMP_FAC1_M:
    CALL    R_FAC2_EQ_FP				;Move floating point number M to FAC2
    JMP     L_CMP_DBL_FAC1_2			;Double precision compare FAC1 with FAC2
;
;Move FAC1 to FAC2
;
R_FAC2_EQ_FAC1:							;31B5H
    LXI     H,DFACLO_R					;FAC1
;
;Move floating point number M to FAC2
;
R_FAC2_EQ_FP:							;31B8H
    LXI     D,DFACLO2_R					;Start of FAC2
; 
; Move floating point number at (HL) to the one at (DE)
; 
L_MOVE_8_BYTES_HL_DE:
    XCHG
    CALL    R_MOVE_8_BYTES_INC
    XCHG
    RET
;
;Move FAC2 to FAC1
;
R_FAC1_EQ_FAC2:							;31C1H
    LXI     H,DFACLO2_R					;Start of FAC2
;
;Move floating point number M to FAC1
;
R_FAC1_EQ_FP:							;31C4H
    LXI     D,DFACLO_R					;FAC1
    JMP     L_MOVE_8_BYTES_HL_DE
;
; Move FAC1 to M
;
R_MOVE_FAC1_TO_M:						;31CAH
    LXI     D,DFACLO_R					;FAC1
R_MOVE_8_BYTES_INC:
    MVI     B,08H
    JMP     R_MOVE_B_BYTES_INC			;Move B bytes from (DE) to M with increment

; 
; Swap FAC1 with Floating Point number on stack
; 
L_SWP_FAC_SP:
    POP     H							;return address
    SHLD    FPTMP1_R					;save it
    CALL    R_POP_FAC2				    ;Pop FAC2 from stack
    CALL    R_PUSH_FAC1				    ;Push FAC1 on stack
    CALL    R_FAC1_EQ_FAC2				;Move FAC2 to FAC1
    LHLD    FPTMP1_R				    ;retrieve return address
    PCHL   

; 
; Take NEG(FAC1) and push return address to NEG(FAC1)
; 
L_NEG_NEG:
    CALL    L_NEG						;Negate FAC1
    LXI     H,L_NEG
    XTHL								;swap L_NEG and return address
    PCHL								;return
;
; Square FAC1 & do table based math
;
R_SQR_FAC1_MULT_TBL:					;31EBH
    SHLD    FPTMP1_R				    ;Floating Point Temp 1
    CALL    R_DBL_SQR				    ;Double precision Square (FAC1=SQR(FAC1))
    LHLD    FPTMP1_R				    ;Floating Point Temp 1
    JMP     R_TBL_BASED_MATH			;Table based math (FAC1=(((FAC1*M)+(M+1))*(M+2)+(M+3)...

; 
; FAC1 = FAC1 * (FAC1^2 * table based math)
;
; IN:
;	HL		table ptr (Code Based.)
; 
R_MULT_FAC1_PWR2_TBL:
    SHLD    FPTMP1_R				    ;Floating Point Temp 1
    CALL    R_PUSH_FAC1				    ;Push FAC1 on stack
    LHLD    FPTMP1_R				    ;Floating Point Temp 1
    CALL    R_SQR_FAC1_MULT_TBL         ;Square FAC1 & do table based math
    CALL    R_POP_FAC2				    ;Pop FAC2 from stack
    JMP     R_DBL_MULT				    ;Double precision multiply (FAC1=FAC1*FAC2)
;
; Table based math (FAC1=(((FAC1*M)+(M+1))*(M+2)+(M+3)...
;
R_TBL_BASED_MATH:						;3209H
    MOV     A,M							;number of entries in table
    PUSH    PSW							;save it
    INX     H							;bump ptr
    PUSH    H							;save table ptr
    LXI     H,FPTMP1_R				    ;Floating Point Temp 1
    CALL    R_MOVE_FAC1_TO_M			;Move FAC1 to M
    POP     H							;restore table ptr
    CALL    R_FAC1_EQ_FP				;Move floating point number M to FAC1
-	POP     PSW							;restore number of entries in table
    DCR     A
    RZ
    PUSH    PSW							;update number of entries in table
    PUSH    H							;save table ptr
    LXI		H,FPTMP1_R
    CALL    R_MULT_M_FAC2				;Double precision math (FAC1=M * FAC2))
    POP     H							;restore table ptr
    CALL    R_FAC2_EQ_FP				;Move floating point number M to FAC2
    PUSH    H
    CALL    R_DBL_ADD				    ;Double precision addition (FAC1=FAC1+FAC2)
    POP     H
    JMP     -							;loop
;
; Push FAC2 on stack
;
R_PUSH_FAC2:							;322EH
    LXI     H,DFACLO2_R+7				;Point to end of FAC2
    JMP     L_PUSH_FAC1_1
;
; Push FAC1 on stack
;
R_PUSH_FAC1:							;3234H
    LXI     H,DFACLO_R+7				;Point to end of FAC1
L_PUSH_FAC1_1:
    MVI     A,04H						;push 4 words from M to Stack
    POP     D							;get return address
-	MOV     B,M
    DCX     H
    MOV     C,M
    DCX     H
    PUSH    B
    DCR     A
    JNZ     -
    XCHG								;return address to HL
	PCHL								;jump to return address

;
; Pop FAC2 from stack
;
R_POP_FAC2:								;3245H
    LXI     H,DFACLO2_R					;Start of FAC2
    JMP     R_POP_FAC1_2
;
; Pop FAC1 from stack
;
R_POP_FAC1:								;324BH
    LXI     H,DFACLO_R					;FAC1
R_POP_FAC1_2:
    MVI     A,04H						;pop 4 words from Stack to M
    POP     D							;return address
-	POP     B							;next word
    MOV     M,C
    INX     H
    MOV     M,B
    INX     H
    DCR     A							;count
    JNZ     -
    XCHG								;return address to HL
	PCHL								;jump to return address
;
; Floating point numbers for math operations
; Keep these 4 numbers together
;
R_FP_NUMBERS:							;325CH
    DB      00H,14H,38H,98H,20H,42H,08H,21H	;1.4389820420821e-65 - RND
    DB      00H,21H,13H,24H,86H,54H,05H,19H	;2.1132486540519e-65
    DB      00H,40H,64H,96H,51H,37H,23H,58H	;4.0649651372358e-65 - BASIC initialize
    DB      40H,43H,42H,94H,48H,19H,03H,24H	;0.43429448190324 - EXP
;
; Floating point num-shares 6 bytes from next number
;
R_DBL_PNT5:				    			;327CH
    DB      40H,50H						;0.500000000000 - SIN, SQR, EXP
;
; Floating point numbers_1 for math operations 
;
R_DBL_ZERO:								;327EH
    DB      00H,00H,00H,00H,00H,00H,00H,00H	;0.0000000000000 - Various
R_DBL_ONE:
    DB      41H,10H,00H,00H,00H,00H,00H,00H	;1.0000000000000 - Various
R_DL_PNT25:
    DB      40H,25H,00H,00H,00H,00H,00H,00H	;0.2500000000000 - COS
R_FP_NUMBERS_4:
    DB      41H,31H,62H,27H,76H,60H,16H,84H	;3.1622776601684 - LOG & EXP
R_FP_NUMBERS_5:
    DB      40H,86H,85H,88H,96H,38H,06H,50H	;0.86858896380650 - LOG
R_FP_NUMBERS_6:
    DB      41H,23H,02H,58H,50H,92H,99H,40H	;2.3025850929940 - LOG
R_FP_NUMBERS_7:
    DB      41H,15H,70H,79H,63H,26H,79H,49H	;1.5707963267949 - ATN
R_FP_NUMBERS_8:
    DB      40H,26H,79H,49H,19H,24H,31H,12H	;0.26794919243112 - ATN
R_FP_NUMBERS_9:
    DB      41H,17H,32H,05H,08H,07H,56H,89H	;1.7320508075689 - ATN
R_FP_NUMBERS_10:
    DB      40H,52H,35H,98H,77H,55H,98H,30H	;0.52359877559830 - ATN
R_FP_NUMBERS_11:
    DB      40H,15H,91H,54H,94H,30H,91H,90H	;0.15915494309190 - SIN & COS
;
; Count of Floating point numbers to follow for EXP
;
R_EXP_MATH_TBL:							;32D6H
    DB      04H
	DB		41H,10H,00H,00H,00H,00H,00H,00H
    DB      43H,15H,93H,74H,15H,23H,60H,31H
    DB      44H,27H,09H,31H,69H,40H,85H,16H
    DB      44H,44H,97H,63H,35H,57H,40H,58H
;
; Count of Floating point numbers to follow for EXP_1
;
R_EXP_MATH_TBL_1:						;32F7H
    DB      03H
    DB      42H,18H,31H,23H,60H,15H,92H,75H
    DB      43H,83H,14H,06H,72H,12H,93H,71H
    DB      44H,51H,78H,09H,19H,91H,51H,62H
;
; Count of Floating point numbers to follow for LOG
;
R_LOG_MATH_TBL:							;3310H
    DB      04H
    DB      0C0H,71H,43H,33H,82H,15H,32H,26H
    DB      41H,62H,50H,36H,51H,12H,79H,08H
    DB      0C2H,13H,68H,23H,70H,24H,15H,03H
    DB      41H,85H,16H,73H,19H,87H,23H,89H
;
; Count of Floating point numbers to follow for LOG_1
;
R_LOG_MATH_TBL_1:						;3331H
    DB      05H
    DB      41H,10H,00H,00H,00H,00H,00H,00H
    DB      0C2H,13H,21H,04H,78H,35H,01H,56H
    DB      42H,47H,92H,52H,56H,04H,38H,73H
    DB      0C2H,64H,90H,66H,82H,74H,09H,43H
    DB      42H,29H,41H,57H,50H,17H,23H,23H
;
; Count of Floating point numbers to follow for SIN
;
R_SIN_MATH_TBL:							;335AH
    DB      08H
    DB      0C0H,69H,21H,56H,92H,29H,18H,09H
    DB      41H,38H,17H,28H,86H,38H,57H,71H
    DB      0C2H,15H,09H,44H,99H,47H,48H,01H
    DB      42H,42H,05H,86H,89H,66H,73H,55H
    DB      0C2H,76H,70H,58H,59H,68H,32H,91H
    DB      42H,81H,60H,52H,49H,27H,55H,13H
    DB      0C2H,41H,34H,17H,02H,24H,03H,98H
    DB      41H,62H,83H,18H,53H,07H,17H,96H
;
; Count of Floating point numbers to follow for ATN
;
R_ATN_MATH_TBL:							;339BH
    DB      08H
    DB      0BFH,52H,08H,69H,39H,04H,00H,00H
    DB      3FH,75H,30H,71H,49H,13H,48H,00H
    DB      0BFH,90H,81H,34H,32H,24H,70H,50H
    DB      40H,11H,11H,07H,94H,18H,40H,29H
    DB      0C0H,14H,28H,56H,08H,55H,48H,84H
    DB      40H,19H,99H,99H,99H,94H,89H,67H
    DB      0C0H,33H,33H,33H,33H,33H,31H,60H
    DB      41H,10H,00H,00H,00H,00H,00H,00H
;
; RST 30H routine - Get sign of SGL or DBL precision
;
R_RST_30H_FUN:							;33DCH
    LDA     DFACLO_R					;FAC1
    ORA     A
    RZ									;retif FAC1 == 0: return 0
; TODO why reload DFACLO_R?
    LDA     DFACLO_R					;FAC1
    JMP     L_EVAL_SIGN_IN_A
;
; Return 1 or -1 in A based on Inverse of Sign bit in A
;
L_EVAL_INV_SIGN_IN_A:
    CMA
;
; Return 1 or -1 in A based on Sign bit in A
;
L_EVAL_SIGN_IN_A:
    RAL									;sign bit to carry
;
; Return 1 or -1 in A based on Carry flag
;	
L_EVAL_CARRY_IN_A:
    SBB     A
    RNZ									;retif -1
    INR     A							;was 0, now +1
    RET   
	
;
; Initialize FAC1 for SGL & DBL precision to zero
;
L_SET_FAC_ZERO:
    XRA     A
    STA     DFACLO_R					;FAC1
    RET
;
; ABS function
;
R_ABS_FUN:								;33F2H
    CALL    L_VSIGN						;Determine sign of last variable used numner
    RP									;Return if already positive
;
;NEGATE ANY TYPE VALUE IN THE FAC
;
L_VNEG:
    LSTTYP								;Determine type of last var used: C Clr = DBL P Clr = SNGL Z Set = String S: Set = Integer
    JM      L_INEG						;If integer, jump to ABS function for integer FAC1
    JZ      R_GEN_TM_ERROR				;Generate TM error if last var was string
;
; NEGATE NUMBER IN THE FAC
; ALTERS A,H,L
; NOTE: THE NUMBER MUST BE PACKED
;
L_NEG:									;Negate FAC1
    LXI     H,DFACLO_R				    ;FAC1
    MOV     A,M							;Get sign / decimal point byte
    ORA     A							;Test if FAC1 is zero
    RZ									;retif 0
    XRI     80H							;Invert the sign bit - make positive
    MOV     M,A							;Save inverted sign bit to FAC1
    RET
;
; SGN function
;
R_SGN_FUN:								;3407H
    CALL    L_VSIGN						;Determine sign of last variable used
L_CONIA:
L_SGN_EXTEND:							;sign extend A to HL
    MOV     L,A
    RAL
    SBB     A
    MOV     H,A
    JMP     L_MAKINT					;Load signed integer in HL to FAC1

; 
; Determine sign of last variable used
; 
L_VSIGN:
    LSTTYP								;Determine type of last var used: C Clr = DBL P Clr = SNGL Z Set = String S: Set = Integer
    JZ      R_GEN_TM_ERROR				;Generate TM error if STRING
    JP      R_RST_30H_FUN				;Get sign of SGL or DBL precision
    LHLD    IFACLO_R					;FAC1 for integers
L_EVAL_HL:
    MOV     A,H
    ORA     L
    RZ
    MOV     A,H
    JMP     L_EVAL_SIGN_IN_A			;eval sign in A
;
; Push single precision FAC1 on stack
;
R_PUSH_SNGL_FAC1:						;3422H
    XCHG
    LHLD    IFACLO_R					;FAC1 for integers
    XTHL								;swap HL and return address
    PUSH    H							;push return address
    LHLD    DFACLO_R					;FAC1
    XTHL								;swap HL and return address
    PUSH    H							;push return address
    XCHG
    RET
;
; Load single precision at M to FAC1
;
R_SNGL_FAC1_EQ_M:						;342FH
    CALL    R_SNGL_DECB_EQ_M			;Reverse load single precision at M to DEBC
;
; Load single precision in BCDE to FAC1
;
R_SNGL_FAC1_EQ_BCDE:				    ;3432H
    XCHG								;DE to HL
    SHLD    IFACLO_R					;FAC1 for integers
    MOV     H,B							;BC to HL
    MOV     L,C
    SHLD    DFACLO_R					;FAC1
    XCHG
    RET
;
; Load single precision FAC1 to BCDE
;
R_SNGL_BCDE_EQ_FAC1:					;343DH
    LHLD    IFACLO_R					;FAC1 for integers
    XCHG
    LHLD    DFACLO_R					;FAC1
    MOV     C,L
    MOV     B,H
    RET
;
; Load single precision at M to BCDE
;
R_SNGL_BCDE_EQ_M:						;3447H
    MOV     C,M
    INX     H
    MOV     B,M
    INX     H
	GETDEFROMM
    RET
;
; Reverse load single precision at M to DEBC
;
; Actual load order is EDCB
;
; OUT:
;	HL		updated
;
R_SNGL_DECB_EQ_M:						;3450H
    MOV     E,M
    INX     H
;
; load 3 bytes at M to D and BC
;
L_LOAD_STR_M:
    MOV     D,M							;length
    INX     H
    MOV     C,M							;str value ptr to BC
    INX     H
    MOV     B,M
L_INCHL:								;Increment HL and return
    INX     H
    RET
;
;Move single precision FAC1 to M
;
R_SNGL_M_EQ_FAC1:						;3459H
    LXI     D,DFACLO_R				    ;FAC1
    MVI     B,04H
    JMP     R_MOVE_B_BYTES_INC       	;Move B bytes from (DE) to M with increment
;
;Move M to FAC2 using precision at VALTYP_R
;
; OUT:
;	B		0
;
R_LOAD_FAC2_FROM_M:						;3461H
    LXI     D,DFACLO2_R					;Start of FAC2
;
;Move VALTYP_R bytes from M to (DE) with increment.
;
R_MOVE_TYP_BYTES_INC_M_TO_DE:
    XCHG
;
;Move VALTYP_R bytes from (DE) to M with increment.
; Returns 0 in B
;
R_MOVE_TYP_BYTES_INC:
    LDA     VALTYP_R					;Type of last expression used
    MOV     B,A							;use Type value as length
;
;Move B bytes from (DE) to M with increment.
; Returns 0 in B
;
R_MOVE_B_BYTES_INC:						;3469H
    LDAX    D
    MOV     M,A
    INX     D
    INX     H
    DCR     B
    JNZ     R_MOVE_B_BYTES_INC       	;Move B bytes from (DE) to M with increment
    RET
;
;Move B bytes from (DE) to M with decrement
;
R_MOVE_B_BYTES_DEC:						;3472H
    LDAX    D
    MOV     M,A
    DCX     D
    DCX     H
    DCR     B
    JNZ     R_MOVE_B_BYTES_DEC       	;Move B bytes from (DE) to M with decrement
    RET

L_CPY_FAC2_TO_1:						;Move VALTYP_R bytes from FAC2 to FAC1 with increment
    LXI     H,DFACLO2_R					;Start of FAC2
L_CPY_M_TO_FAC1:						;Move VALTYP_R bytes from M to FAC1 with increment
    LXI     D,R_MOVE_TYP_BYTES_INC_M_TO_DE ;Move VALTYP_R bytes from M to (DE) with increment.
    JMP     L_CPY_FAC1

; 
; Copy FAC1 to FAC2
; 
L_CPY_FAC1_TO_2:
    LXI     H,DFACLO2_R					;Start of FAC2
; Copy FAC1 to M
L_CPY_FAC1_TO_M:
    LXI     D,R_MOVE_TYP_BYTES_INC		;continuation function: from (DE) to M
; Copy M to FAC1
L_CPY_FAC1:
    PUSH    D							;set continuation address
    LXI     D,DFACLO_R					;preload FAC1
    LDA     VALTYP_R					;Type of last expression used
    CPI     02H							;INT type
    RNZ									;execute continuation routine if NOT INT 
    LXI     D,IFACLO_R					;FAC1 for integers
    RET									;execute continuation routine 
;
; Compare single precision in BCDE with FAC1
;
R_SNGL_CMP_BCDE_FAC1:				    ;3498H
    MOV     A,C
    ORA     A
    JZ      R_RST_30H_FUN				;Get sign of SGL or DBL precision
    LXI     H,L_EVAL_INV_SIGN_IN_A		;Return 1 or -1 in A based on Inverse of Sign bit in A
    PUSH    H
    FSIGN								;Return 1 or -1 in A based on Sign bit of FAC1
    MOV     A,C
    RZ									;retif FAC1 == 0.0
    LXI     H,DFACLO_R				    ;FAC1
    XRA     M
    MOV     A,C
    RM
    CALL    R_SNGL_CMP_BCDE_M			;Compare single precision in BCDE with M
    RAR
    XRA     C
    RET
;
; Compare single precision in BCDE with M
;
R_SNGL_CMP_BCDE_M:						;34B0H
    MOV     A,C
    CMP     M
    RNZ
    INX     H
    MOV     A,B
    CMP     M
    RNZ
    INX     H
    MOV     A,E
    CMP     M
    RNZ
    INX     H
    MOV     A,D
    SUB     M
    RNZ
    POP     H
    POP     H
    RET
;
; Compare signed integer in DE with that in HL
;
R_SINT_CMP:								;34C2H
    MOV     A,D
    XRA     H
    MOV     A,H
    JM      L_EVAL_SIGN_IN_A
    CMP     D
    JNZ     +
    MOV     A,L
    SUB     E
    RZ
+	JMP     L_EVAL_CARRY_IN_A

; 
; Double precision compare FAC1 with FAC2
; 
L_CMP_DBL_FAC1_2:
    LXI     D,DFACLO2_R				    ;Start of FAC2
    LDAX    D							;Get Sign and Decimal point location for FAC2
    ORA     A
    JZ      R_RST_30H_FUN				;If FAC2 is zero, jump to return sign of FAC1 as the answer
    LXI     H,L_EVAL_INV_SIGN_IN_A		;Return 1 or -1 in A based on Inverse of Sign bit in A
    PUSH    H							;continuation function
    FSIGN								;Return 1 or -1 in A based on Sign bit of FAC1
    LDAX    D							;Get Sign and Decimal point location for FAC2
    MOV     C,A							;Save sign of FAC2 in C
    RZ									;If FAC1 is zero, goto continuation function
    LXI     H,DFACLO_R				    ;FAC1
    XRA     M							;XOR sign bit of FAC1 and FAC2 to determine if they are equal
    MOV     A,C							;Restore sign of FAC2 to A
    RM									;Return to calculate 1 or -1 based on sign of FAC2 if sign of FAC1 != FAC2
    MVI     B,08H						;Prepare to compare 8 bytes of floating point
-	LDAX    D							;Get next byte from FAC2
    SUB     M							;Subtract next byte from FAC1
    JNZ     +							;If not equal, jump to determine which is bigger
    INX     D
    INX     H
    DCR     B							;Decrement byte counter
    JNZ     -
    POP     B							;POP continuation function	... they are equal and A already has zero
    RET
; 
; FAC1 and FAC2 not equal. Get carry & XOR with sign of FAC2 to determine which is bigger
; 
+	RAR									;Get carry from last subtract
    XRA     C							;XOR with sign of FAC1 & FAC2
    RET
;
; Compare double precision FAC1 with FAC2
;
R_CMP_FAC1_FAC2:						;34FAH
    CALL    L_CMP_DBL_FAC1_2			;Double precision compare FAC1 with FAC2
    JNZ     L_EVAL_INV_SIGN_IN_A		;Return 1 or -1 in A based on Inverse of Sign bit in A
    RET
;
; CINT function
;
R_CINT_FUN:								;3501H
    LSTTYP								;Determine type of last var used: C Clr = DBL P Clr = SNGL Z Set = String S: Set = Integer:
    LHLD    IFACLO_R					;FAC1 for integers
    RM									;Sign set: INT type
    JZ      R_GEN_TM_ERROR				;Generate TM error if String
    CALL    L_CVT_FP_TO_INT				;convert FAC1 to integer in DE
    JC      R_GEN_OV_ERROR				;Generate OV error
    XCHG								;result to HL
;
; Load signed integer in HL to FAC1
;
L_MAKINT:								;3510H
    SHLD    IFACLO_R					;store in FAC1 for integers
L_VALINT:
    MVI     A,02H						;Load code for INT type variable
; 
; Save type of last variable from A
; 
L_CONISD:
    STA     VALTYP_R					;Type of last expression used
    RET

; 
; Test if FAC1 has 32768 in it.
; If TRUE, convert to INT
; 
L_TST_FAC1_8000H:
    LXI     B,32C5H
	LXI		D,8076H
    CALL    R_SNGL_CMP_BCDE_FAC1     	;Compare single precision in BCDE with FAC1
    RNZ
    LXI     H,8000H
L_POPD_MAKINT:
    POP     D
    JMP     L_MAKINT					;Load signed integer in HL to FAC1
;
; CSNG function
;
R_CSNG_FUN:								;352AH
    LSTTYP								;Determine type of last var used: C Clr = DBL P Clr = SNGL Z Set = String S: Set = Integer
    RPO    
    JM      L_CONSI						;Convert signed integer in FAC1 to single precision
    JZ      R_GEN_TM_ERROR				;Generate TM error
    CALL    L_VALSNG					;set single precision variable type
    CALL    L_SET_NUM_BCD_DIGITS		;Sets registers B (BCD precision count) & HL based on precision
    INX     H
    MOV     A,B							;count
    ORA     A							;clear carry
    RAR									;divide by 2
    MOV     B,A							;# of digits
    JMP     L_ROUND_FAC1_1
;
;Convert signed integer in FAC1 to single precision
;
L_CONSI:						;3540H
    LHLD    IFACLO_R					;FAC1 for integers
;
;Convert signed integer HL to single precision FAC1
;
R_CONV_SINT_HL_SNGL:				    ;3543H
    MOV     A,H							;bit 7 is sign of HL
; entry pnt for unsigned integer HL to single precision FAC1 if A == 0
L_CONV_HL_SNGL:							;Convert integer HL to single precision FAC1.									
    ORA     A							;Sign depends on A
    PUSH    PSW
    CM      L_INEGHL					;negate HL and Load signed integer in HL to FAC1
    CALL    L_VALSNG					;set SNGL variable type
    XCHG								;integer to DE
    LXI     H,0							;preset FAC1 to 0
    SHLD    DFACLO_R					;FAC1
    SHLD    DFACLO_R+2
    MOV     A,D							;test integer
    ORA     E
    JZ      L_POP_PSW_RET				;brif DE == 0: pop PSW, ret
    LXI     B,0500H						;5 entries in L_EXP_TBL
    LXI     H,DFACLO_R+1				;Point to mantissa portion of FAC1
    PUSH    H
    LXI     H,L_EXP_TBL					;Code Based. Table to determine base 10 exponent
; compute exponent
L_CONV_HL_SNGL_1:
    MVI     A,0FFH
    PUSH    D
	GETDEFROMM
    XTHL
    PUSH    B
-	MOV     B,H
    MOV     C,L
    DAD     D
    INR     A
    JC      -							;carry from DAD D
    MOV     H,B
    MOV     L,C
    POP     B
    POP     D
    XCHG
    INR     C
    DCR     C
    JNZ     +
    ORA     A
    JZ      L_CONV_HL_SNGL_3
    PUSH    PSW
    MVI     A,40H						;exponent bias
    ADD     B
    STA     DFACLO_R					;FAC1
    POP     PSW
+	INR     C
    XTHL
    PUSH    PSW
    MOV     A,C							;digit number
    RAR									;bit 0 (odd or even) to carry
    JNC     +							;brif even digit number
; set odd digit BCD number
    POP     PSW
    ADD     A							;to upper nibble
    ADD     A
    ADD     A
    ADD     A
    MOV     M,A
    JMP     L_CONV_HL_SNGL_2
; merge even digit BCD value
+	POP     PSW
    ORA     M
    MOV     M,A
    INX     H
L_CONV_HL_SNGL_2:
    XTHL
L_CONV_HL_SNGL_3:
    MOV     A,D
    ORA     E
    JZ      +
    DCR     B
    JNZ     L_CONV_HL_SNGL_1
+	POP     H
    POP     PSW
    RP     
    JMP     L_NEG						;Negate FAC1

L_EXP_TBL:
	DW		-10000, -1000, -100, -10, -1
;
; CDBL function:
;	 Format: CDBL(expr)
;
; FORCE THE FAC TO BE A DOUBLE PRECISION NUMBER
;
L_FRCDBL:	
    LSTTYP								;Determine type of last var used: C Clr = DBL P Clr = SNGL Z Set = String S: Set = Integer
    RNC									;retif already DBL
    JZ      R_GEN_TM_ERROR				;brif string: Generate TM error
    CM      L_CONSI						;calif INT: Convert signed integer in FAC1 to single precision
L_CONDS:
    LXI     H,0
    SHLD    IFACLO_R+2
    SHLD    IFACLO_R+4
    MOV     A,H
    STA     DFACLO_R+8					;Point to extended precision portion of FAC1
L_VALDBL:
    MVI     A,08H
    JMP     +							;Use SKIP 2 bytes macro mbasic 5.2

L_VALSNG:								;set single precision variable type
    MVI     A,04H 						;Load code for Single Precision variable type
+	JMP     L_CONISD
;
;FORCE THE FAC TO BE A STRING. ALTERS A ONLY
;
L_CHKSTR:
    LSTTYP							   	;Determine type of last var used: C Clr = DBL P Clr = SNGL Z Set = String S: Set = Integer
    RZ
    JMP     R_GEN_TM_ERROR				;Generate TM error
;
;Convert SNGL or DBL in FAC1 to INT
;
; OUT:
;	DE		integer value
;	carry	set if Overflow
;
L_CVT_FP_TO_INT:
    LXI     H,L_SETCARRY				;continuation function
    PUSH    H
    LXI     H,DFACLO_R				    ;ptr to FAC1
    MOV     A,M							;get exponent
    ANI     7FH							;clear sign bit
    CPI     46H
    RNC									;retif exponent >= 46H: set carry because result too big
    SUI     41H							;rescale
    JNC     L_CVT_FP_TO_INT_0			;brif exponent >= 41H
; exponent < 41H: number < 1. Return 0
    ORA     A							;clear carry
    POP     D							;remove continuation function
    LXI     D,0							;return value
    RET
;
;Convert vetted SNGL or DBL to INT.
;	Continuation function PUSHED
;	HL ptr to FAC1
;
L_CVT_FP_TO_INT_0:
    INR     A							;increment exponent
    MOV     B,A							;exponent to B
    LXI     D,0							;result value
    MOV     C,D							;clear BCD nibble flag. 
    INX     H							;ptr to mantissa
;
; BCD arithmetic
;
L_CVT_FP_TO_INT_1:
    MOV     A,C							;get BCD nibble flag
    INR     C							;increment BCD nibble flag
    RAR									;odd/even to carry
    MOV     A,M							;get next 2 BCD digits
    JC      L_CVT_FP_TO_INT_2			;brif BCD nibble flag is odd
    RAR									;move upper BCD digit to lower nibble
    RAR
    RAR
    RAR
    JMP     +
L_CVT_FP_TO_INT_2:
    INX     H							;pnt to next 2 BCD digits
+	ANI     0FH							;isolate BCD digit
    SHLD    FPTMP4_R
    MOV     H,D							;multiply HL by 10
    MOV     L,E
    DAD     H							;x2
    RC									;overflow result
    DAD     H							;x4
    RC									;overflow result
    DAD     D							;x5
    RC									;overflow result
    DAD     H							;x10
    RC									;overflow result
    MOV     E,A							;sign extend current BCD digit to DE
    MVI     D,00H
    DAD     D							;add to result
    RC									;overflow result
    XCHG								;result to DE
    LHLD    FPTMP4_R					;restore HL
    DCR     B							;exponent
    JNZ     L_CVT_FP_TO_INT_1			;brif not done
    LXI     H,8000H
    COMPAR								;Compare result and 8000H: HL - DE
    LDA     DFACLO_R					;FAC1
    RC									;brif 8000H < DE
    JZ      +							;brif DE == 8000H
    POP     H
    ORA     A
    RP     
    XCHG								;result to HL
    CALL    L_INEGHL					;negate HL and Load signed integer in HL to FAC1
    XCHG								;result from HL to DE
    ORA     A							;clear carry
    RET
+	ORA     A
    RP     
    POP     H
    RET

L_SETCARRY:
    STC
    RET

L_DEC_BC:
    DCX     B
    RET
;
; FIX function
;
R_FIX_FUN:								;3645H
    LSTTYP								;Determine type of last var used: C Clr = DBL P Clr = SNGL Z Set = String S: Set = Integer
    RM
    FSIGN								;Return 1 or -1 in A based on Sign bit of FAC1
    JP      R_INT_FUN				    ;brif positive: INT function
    CALL    L_NEG						;Negate FAC1
    CALL    R_INT_FUN				    ;INT function
    JMP     L_VNEG
;
; INT function
;
R_INT_FUN:								;3654H
    LSTTYP								;Determine type of last var used: C Clr = DBL P Clr = SNGL Z Set = String S: Set = Integer
    RM
    LXI     H,DFACLO_R+8				;Point to extended precision portion of FAC1
    MVI     C,0EH						;preload 14 BCD digits
    JNC     +							;brif DBL type
    JZ      R_GEN_TM_ERROR				;brif STRING type: Generate TM error
    LXI     H,IFACLO_R+2				;SNGL
    MVI     C,06H						;6 BCD digits
+	LDA     DFACLO_R					;exponent of FAC1
    ORA     A							;test
    JM      L_RET_NEGINT				;brif negative
;
; return a positive Integer
;
    ANI     7FH							;clear sign bit
    SUI     41H							;rescale exponent
    JC      L_SET_FAC_ZERO				;brif exponent < 41H (<0):
										;	Initialize FAC1 for SGL & DBL precision to zero
    INR     A
    SUB     C
    RNC
    CMA
    INR     A
    MOV     B,A							;loop count
-	DCX     H							;next 2 BCD digits 
    MOV     A,M
    ANI     0F0H						;isolate upper nibble
    MOV     M,A
    DCR     B							;count
    RZ									;retif done
    XRA     A							;clear M
    MOV     M,A
    DCR     B							;count
    JNZ     -
    RET
;
;
; return a negative Integer
;
; IN:
;	A	negative exponent
;	C
;
L_RET_NEGINT:
    ANI     7FH							;clear sign bit
    SUI     41H							;rescale
    JNC     +							;brif exponent >= 41H
    LXI     H,0FFFFH					;return -1
    JMP     L_MAKINT					;Load signed integer in HL to FAC1
;
; return a negative integer
;
+	INR     A
    SUB     C
    RNC									;retif A >= C 
    CMA									;negate A
    INR     A
    MOV     B,A							;result to B
    MVI     E,00H						;counter
L_RET_NEGINT_1:
    DCX     H
    MOV     A,M
    MOV     D,A							;save it
    ANI     0F0H						;11110000 Clear lower nibble
    MOV     M,A
    CMP     D							;same as before?
    JZ      +
    INR     E							;increment counter
+	DCR     B
    JZ      L_RET_NEGINT_2
    XRA     A
    MOV     M,A
    CMP     D
    JZ      +
    INR     E
+	DCR     B
    JNZ     L_RET_NEGINT_1
L_RET_NEGINT_2:
    INR     E							;test E
    DCR     E
    RZ									;retif E == 0FFH
    MOV     A,C							;type BCD length
    CPI     06H
    LXI     B,10C1H						;SNGL constant 1.0 to BCDE
    LXI     D,0
    JZ      R_SNGL_ADD_BCDE				;Single precision addition (FAC1=FAC1+BCDE)
; DBL addition
; TODO consider copying 8 bytes from R_DBL_ONE to DFACLO2_R using R_FAC2_EQ_FP()
    XCHG								;HL now 0
    SHLD    DFACLO2_R+6					;0FC6FH
    SHLD    DFACLO2_R+4					;0FC6DH
    SHLD    DFACLO2_R+2					;0FC6BH
    MOV     H,B							;HL now 10C1H	
    MOV     L,C
    SHLD    DFACLO2_R					;Start of FAC2
    JMP     R_DBL_ADD				    ;Double precision addition (FAC1=FAC1+FAC2)
;
; INT multiply
;
; IN:
;	BC
;	DE
;
; OUT:
;	DE
;
L_INT16_MUL:
    PUSH    H							;save HL
    LXI     H,0
    MOV     A,B
    ORA     C
    JZ      L_INT16_MUL_0				;brif BC == 0
    MVI     A,10H						;loop counter
-	DAD     H							;double HL
    JC      L_GEN_ERR_9					;brif overflow: Generate error 9
    XCHG
    DAD     H							;double DE
    XCHG
    JNC     +							;brif NO overflow
    DAD     B							;HL += BC
    JC      L_GEN_ERR_9					;brif overflow: Generate error 9
+	DCR     A							;loop counter
    JNZ     -							;brif loop counter != 0
L_INT16_MUL_0:
    XCHG								;result to DE
    POP     H							;restore HL
    RET
;
; Signed integer subtraction (FAC1=HL-DE)
;
R_SINT_SUB:
    MOV     A,H							;determine sign of HL
    RAL
    SBB     A
    MOV     B,A
    CALL    L_INEGHL					;negate HL and Load signed integer in HL to FAC1
    MOV     A,C
    SBB     B
    JMP     L_SINT_ADD_1				;join R_SINT_ADD
;
; Signed integer addition (FAC1=HL+DE)
;
R_SINT_ADD:								;3704H
    MOV     A,H							;determine sign of HL
    RAL
    SBB     A
L_SINT_ADD_1:
    MOV     B,A
    PUSH    H
    MOV     A,D							;determine sign of DE
    RAL
    SBB     A
    DAD     D
    ADC     B
    RRC
    XRA     H
    JP      L_POPD_MAKINT				;POP DE and Load signed integer in HL to FAC1
    PUSH    B
    XCHG
    CALL    R_CONV_SINT_HL_SNGL      	;Convert signed integer HL to single precision FAC1
    POP     PSW
    POP     H
    CALL    R_PUSH_SNGL_FAC1			;Push single precision FAC1 on stack
    CALL    R_CONV_SINT_HL_SNGL      	;Convert signed integer HL to single precision FAC1
    POP     B
    POP     D
    JMP     R_SNGL_ADD_BCDE				;Single precision addition (FAC1=FAC1+BCDE)
;
; Signed integer muliply (FAC1=HL*DE)
;
R_SINT_MULT:							;3725H
    MOV     A,H
    ORA     L
    JZ      L_MAKINT					;Load signed integer in HL to FAC1
    PUSH    H
    PUSH    D
    CALL    L_ABS_DE_HL					;FIX UP THE SIGNS
    PUSH    B							;save HL or DE was negative indicator
    MOV     B,H							;BC = HL
    MOV     C,L
    LXI     H,0							;starting value
    MVI     A,10H						;loop counter
L_SINT_MULT_1:
    DAD     H
    JC      L_SINT_MULT_3				;brif overflow
    XCHG
    DAD     H
    XCHG
    JNC     +
    DAD     B
    JC      L_SINT_MULT_3
+	DCR     A							;decrement loop counter
    JNZ     L_SINT_MULT_1				;brif not done
    POP     B
    POP     D
L_SINT_MULT_2:
    MOV     A,H
    ORA     A
    JM      +
    POP     D
    MOV     A,B							;negative indicator to A
    JMP     L_INEGA						;negate HL is A < 0

+	XRI     80H
    ORA     L
    JZ      L_SINT_MULT_4
    XCHG
    JMP     +

L_SINT_MULT_3:
    POP     B
    POP     H
+	CALL    R_CONV_SINT_HL_SNGL      	;Convert signed integer HL to single precision FAC1
    POP     H
    CALL    R_PUSH_SNGL_FAC1			;Push single precision FAC1 on stack
    CALL    R_CONV_SINT_HL_SNGL      	;Convert signed integer HL to single precision FAC1
    POP     B
    POP     D
    JMP     R_SNGL_MULT_BCDE			;Single precision multiply (FAC1=FAC1*BCDE)

L_SINT_MULT_4:
    MOV     A,B
    ORA     A
    POP     B
    JM      L_MAKINT					;Load signed integer in HL to FAC1
    PUSH    D
    CALL    R_CONV_SINT_HL_SNGL      	;Convert signed integer HL to single precision FAC1
    POP     D
    JMP     L_NEG						;Negate FAC1
;
; Signed integer divide (FAC1=DE/HL). See also R_INT16_DIV
;
R_SINT_DIV:								;377EH
    MOV     A,H
    ORA     L
    JZ      R_GEN_D0_ERROR				;Generate /0 error
	CALL    L_ABS_DE_HL					;FIX UP THE SIGNS
    PUSH    B							;save HL or DE was negative indicator
    XCHG
    CALL    L_INEGHL					;negate HL and Load signed integer in HL to FAC1
    MOV     B,H
    MOV     C,L
    LXI     H,0
    MVI     A,11H						;loop counter + 1
    PUSH    PSW							;store on stack	
    ORA     A							;clear carry
    JMP     L_DIVLOOP_1
L_DIVLOOP:
    PUSH    PSW							;store loop counter on stack
    PUSH    H
    DAD     B
    JNC     +
    POP     PSW
    STC									;set carry if HL + BC overflow
    JMP     L_DIVLOOP_1
+	POP     H
L_DIVLOOP_1:					
    MOV     A,E							;E << 1
    RAL
    MOV     E,A
    MOV     A,D							;D << 1
    RAL
    MOV     D,A
    MOV     A,L							;L << 1
    RAL
    MOV     L,A
    MOV     A,H							;H << 1
    RAL
    MOV     H,A
    POP     PSW							;get loop counter
    DCR     A							;decrement
    JNZ     L_DIVLOOP					;brif not 0
    XCHG
    POP     B
    PUSH    D
    JMP     L_SINT_MULT_2
;
; Check signs of DE and HL. Take ABS value of DE and HL
;
; OUT:
;	B		Bit 7 set if either HL or DE is negative
;
;GET READY TO MULTIPLY OR DIVIDE (mbasic 5.2)
;
L_IMULDV:
L_ABS_DE_HL:
    MOV     A,H							;get MSB of HL
    XRA     D							;XOR with MSB of DE
    MOV     B,A							;save result in B
    CALL    L_INEGH						;do this twice: once for HL, once for DE
    XCHG
L_INEGH:
    MOV     A,H
L_INEGA:								;negate HL is A < 0
    ORA     A
    JP      L_MAKINT					;brif A >= 0: Load signed integer in HL to FAC1
;
; negate HL and Load signed integer in HL to FAC1
;
; OUT:
;	C		0
;
L_INEGHL:
    XRA     A
    MOV     C,A
    SUB     L							;L = 0 - L
    MOV     L,A
    MOV     A,C							;H = 0 - H
    SBB     H
    MOV     H,A
    JMP     L_MAKINT					;Load signed integer in HL to FAC1

; 
; INTEGER NEGATION
; 
L_INEG:
    LHLD    IFACLO_R					;GET THE INTEGER
    CALL    L_INEGHL					;negate HL and Load signed integer in HL to FAC1
    MOV     A,H
    XRI     80H							;CHECK FOR SPECIAL CASE OF 32768
    ORA     L
    RNZ									;IT DID NOT OCCUR, EVERYTHING IS FINE
; Code differs from mbasic 5.2
; 
;Convert unsigned HL to single precision in FAC1
; 	
L_CONV_UNSGND_HL_SNGL:
    XRA     A
    JMP     L_CONV_HL_SNGL				;Jump into Convert Signed to single precision in FAC1
;
; MOD priority
;
L_MOD_PRI:
    PUSH    D
    CALL    R_SINT_DIV				    ;Signed integer divide (FAC1=DE/HL)
    XRA     A							;TURNOFF THE CARRY AND TRANFER
    ADD     D							;THE REMAINDER*2 WHICH IS IN DE
    RAR									;TO HL DIVIDING BY TWO
    MOV     H,A
    MOV     A,E
    RAR
    MOV     L,A							;***WHG01*** FIX TO MOD OPERATOR
    CALL    L_VALINT 					;SET VALTYP TO "INTEGER" IN CASE RESULT OF THE DIVISION WAS 32768
    POP     PSW							;GET THE SIGN OF THE REMAINDER BACK
    JMP     L_INEGA			 			;NEGATE THE REMAINDER IF NECESSARY
;
; TODO unreachable
;
    CALL    R_SNGL_DECB_EQ_M			; Reverse load single precision at M to DEBC
;
; Single precision addition (FAC1=FAC1+BCDE)
;
R_SNGL_ADD_BCDE:						;37F4H
    CALL    R_SNGL_LOAD				    ;Single precision load (FAC2=BCDE)
;
; Single precision addition (FAC1=FAC1+FAC2)
;
R_SNGL_ADD_FAC2:						;37F7H
    CALL    L_CONDS
    JMP     R_DBL_ADD				    ;Double precision addition (FAC1=FAC1+FAC2)
;
; Single precision subtract (FAC1=FAC1-BCDE)
;
R_SNGL_SUB:								;37FDH
    CALL    L_NEG						;Negate FAC1
    JMP     R_SNGL_ADD_BCDE				;Single precision addition (FAC1=FAC1+BCDE)
;
; Single precision multiply (FAC1=FAC1*BCDE)
;
R_SNGL_MULT_BCDE:						;3803H
    CALL    R_SNGL_LOAD				    ;Single precision load (FAC2=BCDE)
;
; Single precision multiply (FAC1=FAC2*FAC2)
;
R_SNGL_MULT_FAC2:						;3806H
    CALL    L_CONDS
    JMP     R_DBL_MULT				    ;Double precision multiply (FAC1=FAC1*FAC2)

L_STK_SNGL_DIV:
    POP     B							;pop SNGL to BCDE
    POP     D
;
; Single precision divide (FAC1=BCDE/FAC1)
;
R_SNGL_DIV:								;380EH
    LHLD    IFACLO_R					;FAC1 for integers
    XCHG
    SHLD    IFACLO_R					;FAC1 for integers
    PUSH    B
    LHLD    DFACLO_R					;FAC1
    XTHL
    SHLD    DFACLO_R					;FAC1
    POP     B
    CALL    R_SNGL_LOAD				    ;Single precision load (FAC2=BCDE)
    CALL    L_CONDS
    JMP     R_DBL_DIV				    ;Double precision divide (FAC1=FAC1/FAC2)
;
; Single precision load (FAC2=BCDE)
;
R_SNGL_LOAD:							;3827H
    XCHG
    SHLD    IFACLO2_R					;FAC2 for integers
    MOV     H,B
    MOV     L,C
    SHLD    DFACLO2_R					;Start of FAC2
    LXI     H,0
    SHLD    0FC6DH
    SHLD    0FC6FH
    RET

L_DCR_A:
    DCR     A
    RET

L_DCX_H:
    DCX     H
    RET
;
; POP H & return continuation function
;
L_POP_HL:
    POP     H
    RET
;
;Convert ASCII number at M to double precision in FAC1
;
R_ASCII_TO_DBL:							;3840H
    XCHG
    LXI     B,00FFH
    MOV     H,B
    MOV     L,B
    CALL    L_MAKINT					;Load signed integer in HL to FAC1
    XCHG
    MOV     A,M
    CPI     2DH
    PUSH    PSW
    JZ      L_ASCII_TO_DBL_1
    CPI     2BH
    JZ      L_ASCII_TO_DBL_1
    DCX     H
L_ASCII_TO_DBL_1:
    CHRGET								;Get next non-white char from M
    JC      R_ASCII_CONV_HELPER2     	;Convert ASCII number that starts with a Digit
    CPI     '.'
    JZ      R_ASCII_FND_DOT				;Found '.' in ASCII number
    CPI     'e'							;65H
    JZ      R_ASCII_FND_e				;Found 'e' in ASCII number
    CPI     'E'
;
; Found 'e' in ASCII number
;
R_ASCII_FND_e:							;3867H
    JNZ     R_ASCII_FND_CapE			; Found 'E' in ASCII number
    PUSH    H
    CHRGET								;Get next non-white char from M
    CPI     'l'							;6CH
    JZ      +
    CPI     'L'							;4CH
    JZ      +
    CPI     'q'							;71H
    JZ      +
    CPI     'Q'							;51H
+	POP     H
    JZ      +							;brif 'l', 'L', 'q', 'Q'
    LSTTYP								;Determine type of last var used: C Clr = DBL P Clr = SNGL Z Set = String S: Set = Integer
    JNC     L_ASCII_FND_d				;brif !DBL
    XRA     A
    JMP     L_ASCII_FND_1
+	MOV     A,M
;
; Found 'E' in ASCII number
;
R_ASCII_FND_CapE:						;388AH
    CPI     '%'							;25H
    JZ      R_ASCII_FND_PERC			; Found '%' in ASCII number
    CPI     '#'							;23H
    JZ      R_ASCII_FND_HASH			;Found '#' in ASCII number
    CPI     '!'							;21H
    JZ      R_ASCII_FND_BANG			;Found '!' in ASCII number
    CPI     'd'							;64H
    JZ      L_ASCII_FND_d
    CPI     'D'
    JNZ     R_ASCII_NOTFND
L_ASCII_FND_d:
    ORA     A
L_ASCII_FND_1:
    CALL    R_ASCII_CONV_HELPER      	;Deal with single & double precision ASCII conversions
    CHRGET								;Get next non-white char from M
    PUSH    D
    MVI     D,00H
    CALL    R_ASCII_NUM_CONV			;ASCII num conversion - find ASCII or tokenized '+' or '-' in A
    MOV     C,D
    POP     D
-	CHRGET								;Get next non-white char from M
    JNC     L_ASCII_FND_2
    MOV     A,E
    CPI     0CH
    JNC     +
    RLC    
    RLC    
    ADD     E
    RLC    
    ADD     M
    SUI     30H
    MOV     E,A
    JMP     -
+	MVI     E,80H
    JMP     -
L_ASCII_FND_2:
    INR     C
    JNZ     R_ASCII_NOTFND
    XRA     A
    SUB     E
    MOV     E,A
R_ASCII_NOTFND:
    LSTTYP								;Determine type of last var used: C Clr = DBL P Clr = SNGL Z Set = String S: Set = Integer
    JM      +							;brif integer
    LDA     DFACLO_R					;FAC1
    ORA     A
    JZ      +
    MOV     A,D
    SUB     B
    ADD     E
    ADI		40H
    STA     DFACLO_R					;FAC1
    ORA     A
    CM      L_OV_ERROR					;TODO call R_GEN_OV_ERROR directly
+	POP     PSW
    PUSH    H
    CZ      L_VNEG
    LSTTYP								;Determine type of last var used: C Clr = DBL P Clr = SNGL Z Set = String S: Set = Integer
    JNC     +
    POP     H
    RPE    
    PUSH    H
    LXI     H,L_POP_HL					;POP H & return continuation function
    PUSH    H
    CALL    L_TST_FAC1_8000H
    RET

+	CALL    L_ROUND_FAC1				;Round FAC1 using extended precision portion at end of FAC1
    POP     H
    RET

L_OV_ERROR:
    JMP     R_GEN_OV_ERROR				;Generate OV error
;
; Found '.' in ASCII number
;
R_ASCII_FND_DOT:						;3904H
    LSTTYP								;Determine type of last var used: C Clr = DBL P Clr = SNGL Z Set = String S: Set = Integer
    INR     C
    JNZ     R_ASCII_NOTFND
    JNC     +
    CALL    R_ASCII_CONV_HELPER      	;Deal with single & double precision ASCII conversions
    LDA     DFACLO_R					;FAC1
    ORA     A
    JNZ     +
    MOV     D,A
+	JMP     L_ASCII_TO_DBL_1
;
; Found '%' in ASCII number
;
R_ASCII_FND_PERC:						;391AH
    CHRGET								;Get next non-white char from M
    POP     PSW
    PUSH    H							;save txt ptr
	SKIP_2BYTES_INST_HL
    MVI     A,38H						;TODO unreachable instruction
    PUSH    H
    LXI     H,R_CINT_FUN
    PUSH    H
    PUSH    PSW
    JMP     R_ASCII_NOTFND
;
; Found '#' in ASCII number
;
R_ASCII_FND_HASH:						;3929H
    ORA     A
R_ASCII_FND_BANG:
    CALL    R_ASCII_CONV_HELPER      	;Deal with single & double precision ASCII conversions
    CHRGET								;Get next non-white char from M
    JMP     R_ASCII_NOTFND
;
; Deal with single & double precision ASCII conversions
;
R_ASCII_CONV_HELPER:				    ;3931H
    PUSH    H
    PUSH    D
    PUSH    B
    PUSH    PSW
    CZ      R_CSNG_FUN				    ;CSNG function
    POP     PSW
    CNZ     L_FRCDBL				    ;CDBL function
    POP     B
    POP     D
    POP     H
    RET
;
;Convert ASCII number that starts with a Digit
;
R_ASCII_CONV_HELPER2:				    ;3940H
    SUI     '0'
    JNZ     +
    ORA     C
    JZ      +
    ANA     D
    JZ      L_ASCII_TO_DBL_1
+	INR     D
    MOV     A,D
    CPI     07H
    JNZ     +
    ORA     A
    CALL    R_ASCII_CONV_HELPER      	;Deal with single & double precision ASCII conversions
+	PUSH    D
    MOV     A,B
    ADD     C
    INR     A
    MOV     B,A
    PUSH    B
    PUSH    H
    MOV     A,M
    SUI     30H
    PUSH    PSW
    LSTTYP								;Determine type of last var used: C Clr = DBL P Clr = SNGL Z Set = String S: Set = Integer
    JP      L_ASC_CONV_3
    LHLD    IFACLO_R					;FAC1 for integers
    LXI     D,0CCDH						;probably constant 0CCDH (3277.)
    COMPAR								;HL - DE
    JNC     L_ASC_CONV_2
    MOV     D,H
    MOV     E,L
    DAD     H
    DAD     H
    DAD     D
    DAD     H
    POP     PSW
    MOV     C,A
    DAD     B
    MOV     A,H
    ORA     A
    JM      +
    SHLD    IFACLO_R					;FAC1 for integers
L_ASC_CONV_1:
    POP     H
    POP     B
    POP     D
    JMP     L_ASCII_TO_DBL_1

+	MOV     A,C
    PUSH    PSW
L_ASC_CONV_2:
    CALL    L_CONSI						;Convert signed integer in FAC1 to single precision
L_ASC_CONV_3:
    POP     PSW
    POP     H
    POP     B
    POP     D
    JNZ     +
    LDA     DFACLO_R					;FAC1
    ORA     A
    MVI     A,00H
    JNZ     +
    MOV     D,A
    JMP     L_ASCII_TO_DBL_1
+	PUSH    D
    PUSH    B
    PUSH    H
    PUSH    PSW
    LXI     H,DFACLO_R				    ;FAC1
    MVI     M,01H
    MOV     A,D
    CPI     10H
    JC      +
    POP     PSW
    JMP     L_ASC_CONV_1
+	INR     A
    ORA     A							;clear carry
    RAR
    MVI     B,00H
    MOV     C,A
    DAD     B
    POP     PSW
    MOV     C,A							;save A
    MOV     A,D							;get bcd index
    RAR									;bit 0 (odd or even) to carry
    MOV     A,C							;restore A
    JNC     +							;brif odd
; move upper nibble into lower nibble
    ADD     A							;x2
    ADD     A							;x4
    ADD     A							;x8
    ADD     A							;x16
+	ORA     M
    MOV     M,A
    JMP     L_ASC_CONV_1
;
; Finish printing BASIC ERROR message " in " line #
;
R_PRNT_BASIC_ERR_TERM:				    ;39CCH
    PUSH    H
    LXI     H,R_IN_MSG					;Code Based. 
    CALL    R_PRINT_STRING				;Print buffer at M until NULL or '"'
    POP     H
;
; Print binary number in HL at current position
;
R_PRINT_HL_ON_LCD:						;39D4H
    LXI     B,R_PRINT_STRING_PREINC_HL
    PUSH    B
    CALL    L_MAKINT					;Load signed integer in HL to FAC1
    XRA     A
    STA     TEMP3_R
    LXI     H,MBUFFER_R
    MVI     M,' '
    ORA     M
    JMP     L_PRINT_FAC1_FMT_1
;
;Convert binary number in FAC1 to ASCII at MBUFFER_R
;
R_PRINT_FAC1_ZERO:						;39E8H
    XRA     A
R_PRINT_FAC1:
    CALL    R_FAC1_EQ_ZERO				;Initialize FAC1 with 0.0 if it has no value
										;sets HL to MBUFFER_R
;
;Convert number in FAC1 to ASCII at M with format
;
R_PRINT_FAC1_FORMAT:				    ;39ECH
    ANI     08H
    JZ      +
    MVI     M,'+'						;2BH
+	XCHG
    CALL    L_VSIGN						;Determine sign of last variable used
    XCHG
    JP      L_PRINT_FAC1_FMT_1
    MVI     M,'-'						;2DH
    PUSH    B
    PUSH    H
    CALL    L_VNEG
    POP     H
    POP     B
    ORA     H
L_PRINT_FAC1_FMT_1:
    INX     H
    MVI     M,'0'
    LDA     TEMP3_R
    MOV     D,A
    RAL
    LDA     VALTYP_R					;Type of last expression used
    JC      L_PRINT_FAC1_FMT_9
    JZ      L_PRINT_FAC1_FMT_7
    CPI     04H
    JNC     L_PRINT_FAC1_FMT_5
    LXI     B,0
    CALL    L_PRINT_FAC					;BC must be loaded
L_PRINT_FAC1_FMT_2:
    LXI     H,MBUFFER_R
    MOV     B,M
    MVI     C,' '
    LDA     TEMP3_R
    MOV     E,A
    ANI     20H
    JZ      L_PRINT_FAC1_FMT_3
    MOV     A,B
    CMP     C
    MVI     C,'*'
    JNZ     L_PRINT_FAC1_FMT_3
    MOV     A,E
    ANI     04H
    JNZ     L_PRINT_FAC1_FMT_3
    MOV     B,C
L_PRINT_FAC1_FMT_3:
    MOV     M,C
    CHRGET								;Get next non-white char from M
    JZ      L_PRINT_FAC1_FMT_4
    CPI     'E'
    JZ      L_PRINT_FAC1_FMT_4
    CPI     'D'
    JZ      L_PRINT_FAC1_FMT_4
    CPI     '0'
    JZ      L_PRINT_FAC1_FMT_3
    CPI     ','
    JZ      L_PRINT_FAC1_FMT_3
    CPI     '.'
    JNZ     +
L_PRINT_FAC1_FMT_4:
    DCX     H
    MVI     M,'0'
+	MOV     A,E
    ANI     10H
    JZ      +
    DCX     H
    MVI     M,'$'
+	MOV     A,E
    ANI     04H
    RNZ
    DCX     H
    MOV     M,B
    RET

L_PRINT_FAC1_FMT_5:
    PUSH    H
    CALL    L_SET_NUM_BCD_DIGITS		;Sets registers B (BCD precision count) & HL based on precision
    MOV     D,B
    INR     D
    LXI     B,0300H
    LDA     DFACLO_R					;FAC1
    SUI     3FH
    JC      +
    INR     D
    CMP     D
    JNC     +
    INR     A
    MOV     B,A
    MVI     A,02H
+	SUI     02H
    POP     H
    PUSH    PSW
    CALL    L_FOUTAN
    MVI     M,'0'
    CZ      L_INCHL						;Increment HL
    CALL    L_PRINT_BCDS
-	DCX     H
    MOV     A,M
    CPI     '0'
    JZ      -
    CPI     '.'
    CNZ     L_INCHL						;Increment HL
    POP     PSW
    JZ      L_PRINT_FAC1_FMT_8
L_PRINT_FAC1_FMT_6:
    MVI     M,'E'						;45H
    INX     H
    MVI     M,'+'						;2BH
    JP      +
    MVI     M,'-'						;2DH
    CMA									;complement A
    INR     A
+	MVI     B,'0'-1						;2FH
-	INR     B
    SUI     0AH
    JNC     -							;brif A >= 10.
    ADI		':'							;3AH
    INX     H
    MOV     M,B
    INX     H
    MOV     M,A
L_PRINT_FAC1_FMT_7:
    INX     H
L_PRINT_FAC1_FMT_8:
    MVI     M,00H
    XCHG
    LXI     H,MBUFFER_R
    RET

L_PRINT_FAC1_FMT_9:
    INX     H
    PUSH    B
    CPI     04H
    MOV     A,D
    JNC     L_PRINT_FAC1_FMT_15
    RAR
    JC      L_PRINT_FAC1_FMT_17
    LXI     B,0603H						;constant used in L_FOUTED
    CALL    L_FOUICC					;may clear C
    POP     D
    MOV     A,D
    SUI     05H							;D - 5
    CP      L_ADD_ZEROS					;add A zeros, unformatted
    CALL    L_PRINT_FAC					;calls L_FOUTED. BC must be loaded
L_PRINT_FAC1_FMT_10:
    MOV     A,E
    ORA     A
    CZ      L_DCX_H
    DCR     A
    CP      L_ADD_ZEROS					;add A zeros, unformatted
L_PRINT_FAC1_FMT_11:
    PUSH    H
    CALL    L_PRINT_FAC1_FMT_2
    POP     H
    JZ      +
    MOV     M,B
    INX     H
+	MVI     M,00H
    LXI     H,FPTMP1_R					;Floating Point Temp 1
-	INX     H
L_PRINT_FAC1_FMT_12:
    LDA     TEMP2_R
    SUB     L
    SUB     D
    RZ
    MOV     A,M
    CPI     ' '
    JZ      -
    CPI     '*'
    JZ      -
    DCX     H
    PUSH    H
L_PRINT_FAC1_FMT_13:					;continuation function
    PUSH    PSW
    LXI     B,L_PRINT_FAC1_FMT_13
    PUSH    B
    CHRGET								;Get next non-white char from M
    CPI     2DH
    RZ
    CPI     2BH
    RZ
    CPI     '$'
    RZ
    POP     B
    CPI     30H
    JNZ     L_PRINT_FAC1_FMT_14
    INX     H
    CHRGET								;Get next non-white char from M
    JNC     L_PRINT_FAC1_FMT_14
    DCX     H
    JMP     +

-	DCX     H
    MOV     M,A
+	POP     PSW
    JZ      -
    POP     B
    JMP     L_PRINT_FAC1_FMT_12

L_PRINT_FAC1_FMT_14:
    POP     PSW
    JZ      L_PRINT_FAC1_FMT_14
    POP     H
    MVI     M,'%'						;25H
    RET

L_PRINT_FAC1_FMT_15:
    PUSH    H
    RAR
    JC      L_PRINT_FAC1_FMT_18
    CALL    L_SET_NUM_BCD_DIGITS		;Sets registers B (BCD precision count) & HL based on precision
    MOV     D,B
    LDA     DFACLO_R					;FAC1 exponent
    SUI     4FH
    JC      +							;brif DFACLO_R < 4FH
    POP     H
    POP     B
    CALL    R_PRINT_FAC1_ZERO			;Convert number in FAC1 to ASCII at MBUFFER_R
    LXI     H,FPTMP1_R					;Floating Point Temp 1
    MVI     M,'%'						;25H
    RET
+	FSIGN								;Return 1 or -1 in A based on Sign bit of FAC1
    CNZ     L_UNBIAS_EXP				;calif FAC1 != 0.0
    POP     H
    POP     B
    JM      +
    PUSH    B
    MOV     E,A
    MOV     A,B
    SUB     D
    SUB     E
    CP      L_ADD_ZEROS					;add A zeros, unformatted
    CALL    L_FOUTCD
    CALL    L_PRINT_BCDS
    ORA     E
    CNZ     L_ADD_ZEROS_FMT_1
    ORA     E
    CNZ     L_FOUTED					;add formatting. BC must be loaded
    POP     D
    JMP     L_PRINT_FAC1_FMT_10

+	MOV     E,A
    MOV     A,C
    ORA     A
    CNZ     L_DCR_A
    ADD     E
    JM      +
    XRA     A
+	PUSH    B
    PUSH    PSW
    CM      L_FND_BCD_POS				;calif A is negative
    POP     B
    MOV     A,E
    SUB     B
    POP     B
    MOV     E,A
    ADD     D
    MOV     A,B
    JM      +
    SUB     D
    SUB     E
    CP      L_ADD_ZEROS					;add A zeros, unformatted
    PUSH    B
    CALL    L_FOUTCD
    JMP     L_PRINT_FAC1_FMT_16

+	CALL    L_ADD_ZEROS					;add A zeros, unformatted
    MOV     A,C
    CALL    L_FOUTDP
    MOV     C,A
    XRA     A
    SUB     D
    SUB     E
    CALL    L_ADD_ZEROS					;add A zeros, unformatted
    PUSH    B
    MOV     B,A
    MOV     C,A
L_PRINT_FAC1_FMT_16:
    CALL    L_PRINT_BCDS
    POP     B
    ORA     C
    JNZ     +
    LHLD    TEMP2_R
+	ADD     E
    DCR     A
    CP      L_ADD_ZEROS					;add A zeros, unformatted
    MOV     D,B
    JMP     L_PRINT_FAC1_FMT_11

L_PRINT_FAC1_FMT_17:
    PUSH    H
    PUSH    D
    CALL    L_CONSI						;Convert signed integer in FAC1 to single precision
    POP     D
L_PRINT_FAC1_FMT_18:
    CALL    L_SET_NUM_BCD_DIGITS		;Sets registers B (BCD precision count) & HL based on precision
    MOV     E,B
    FSIGN								;Return 1 or -1 in A based on Sign bit of FAC1
    PUSH    PSW							;save result
    CNZ     L_UNBIAS_EXP				;calif FAC1 != 0.0
    POP     PSW
    POP     H
    POP     B
    PUSH    PSW
    MOV     A,C
    ORA     A
    PUSH    PSW
    CNZ     L_DCR_A
    ADD     B
    MOV     C,A
    MOV     A,D
    ANI     04H
    CPI     01H
    SBB     A
    MOV     D,A
    ADD     C
    MOV     C,A
    SUB     E
    PUSH    PSW
    JP      +
    CALL    L_FND_BCD_POS				;calif A is negative
    JNZ     +
    PUSH    H							;save HL
    CALL    L_ROTATER_FAC1				;Rotate FAC1 BCD digits right
    LXI     H,DFACLO_R				    ;FAC1
    INR     M							;increment exponent
    POP     H							;restore HL
+	POP     PSW
    PUSH    B
    PUSH    PSW
    JM      +
    XRA     A
+	CMA
    INR     A
    ADD     B
    INR     A
    ADD     D
    MOV     B,A							;char count
    MVI     C,00H						;thousands count
    CZ      L_FOUTAN
    CALL    L_PRINT_BCDS
    POP     PSW
    CP      L_ADD_ZEROS_FMT				;add flagged A zeros
    CALL    L_FOUTED					;add formatting. BC must be loaded
    POP     B
    POP     PSW
    JNZ     +
    CALL    L_DCX_H
    MOV     A,M
    CPI     '.'
    CNZ     L_INCHL						;Increment HL
    SHLD    TEMP2_R
+	POP     PSW
    LDA     DFACLO_R					;FAC1
    JZ      +
    ADD     E
    SUB     B
    SUB     D
+	PUSH    B
    CALL    L_PRINT_FAC1_FMT_6
    XCHG
    POP     D
    JMP     L_PRINT_FAC1_FMT_11
;
;
L_ADD_ZEROS:							;add A zeros, unformatted
    ORA     A
-	RZ
    DCR     A
    MVI     M,'0'
    INX     H
    JMP     -

L_ADD_ZEROS_FMT:						;add flagged A zeros
    JNZ     L_ADD_ZEROS_FMT_1
-	RZ									;done
    CALL    L_FOUTED					;add formatting. BC must be loaded
L_ADD_ZEROS_FMT_1:
    MVI     M,'0'
    INX     H
    DCR     A							;set flag
    JMP		-
;
; IN:
;	DE		
;
;HERE TO PUT A POSSIBLE COMMA COUNT IN C, AND ZERO C IF WE ARE NOT
;USING THE COMMA SPECIFICATION
;
L_FOUTCD:
    MOV     A,E							;D+E
    ADD     D
    INR     A							;+1
    MOV     B,A							;D+E+1
    INR     A							;+1
; modulo 3
-	SUI     3
    JNC		-
    ADI		5							;ADD 3 BACK IN AND ADD 2 MORE FOR SCALING
; plus 5
    MOV     C,A							;((D+E+2) mod 3) + 5
L_FOUICC:
    LDA     TEMP3_R						;GET THE FORMAT SPECS
    ANI     40H							;LOOK AT THE COMMA BIT
    RNZ									;WE ARE USING COMMAS, JUST RETURN
    MOV     C,A							;WE AREN'T, ZERO THE COMMA COUNT
    RET
;
;HERE TO PUT DECIMAL POINTS AND COMMAS IN THEIR CORRECT PLACES
;THIS SUBROUTINE SHOULD BE CALLED BEFORE THE NEXT DIGIT IS PUT IN THE
;BUFFER.  B=THE DECIMAL POINT COUNT, C=THE COMMA COUNT
;THE COUNTS TELL HOW MANY MORE DIGITS HAVE TO GO IN BEFORE THE COMMA
;OR DECIMAL POINT GO IN.  THE COMMA OR DECIMAL POINT THEN GOES BEFORE 
;THE LAST DIGIT IN THE COUNT.  FOR EXAMPLE, IF THE DECIMAL POINT SHOULD
;COME AFTER THE FIRST DIGIT, THE DECIMAL POINT COUNT SHOULD BE 2.
;SAVE FOR LATER
;
L_FOUTAN:
    DCR     B							;char count
    JP      L_FOUTE1					;brif >= 0
; B is negative. Print -B zeros
    SHLD    TEMP2_R						;ptr to last comma printed
    MVI     M,'.'					
-	INX     H
    MVI     M,'0'
    INR     B
    MOV     C,B							;C will be -1 on exit
    JNZ     -
    INX     H
    RET
;
; IN:
;	B		period count
;	C		comma count
;	HL		output buffer ptr
;
L_FOUTED:								;add formatting.
    DCR     B							;char count
L_FOUTE1:
    JNZ     L_PRNT_COMMA				;brif B != 0
L_FOUTDP:								;print '.'
    MVI     M,'.'					
    SHLD    TEMP2_R					;ptr to last period printed
    INX     H							;next
    MOV     C,B							;now zero
    RET

L_PRNT_COMMA:							;print ',' every third digit
    DCR     C
    RNZ
    MVI     M,','
    INX     H							;next
    MVI     C,03H						;reset
    RET

L_PRINT_BCDS:
    PUSH    D
    PUSH    H
    PUSH    B
    CALL    L_SET_NUM_BCD_DIGITS		;Sets registers B (BCD precision count) & HL based on precision
    MOV     A,B
    POP     B
    POP     H
    LXI     D,DFACLO_R+1				;Point to BCD portion of FAC1
    STC
L_PRINT_BCDS_1:
    PUSH    PSW
    CALL    L_FOUTED					;add formatting. BC must be loaded			
    LDAX    D
    JNC     L_PRINT_BCDS_2
    RAR									;move upper nibble to lower nibble
    RAR
    RAR
    RAR
    JMP     +
L_PRINT_BCDS_2:
    INX     D
+	ANI     0FH							;isolate lower nibble
    ADI		'0'
    MOV     M,A
    INX     H
    POP     PSW
    DCR     A
    CMC									;complement carry
    JNZ     L_PRINT_BCDS_1
    JMP     L_PRINT_FAC_2
;
; BC must be loaded with format DATA
; HL	output buffer ptr
;
L_PRINT_FAC:
    PUSH    D							;save DE
    LXI     D,L_DEC_RANGES				;Code Based. table
    MVI     A,05H						;loop 5 times
L_PRINT_FAC_1:
    CALL    L_FOUTED					;add formatting. BC must be loaded
    PUSH    B							;save BC
    PUSH    PSW							;save loop counter
    PUSH    H							;save HL
    XCHG								;L_DEC_RANGES ptr to HL
    MOV     C,M							;load range limit from M
    INX     H
    MOV     B,M
    PUSH    B							;save range limit
    INX     H
    XTHL								;swap range limit and L_DEC_RANGES ptr
    XCHG								;range limit to DE
    LHLD    IFACLO_R					;FAC1 for integers
    MVI     B,'0'-1						;2FH predecrement B
-	INR     B
    MOV     A,L							;int value -= range limit
    SUB     E
    MOV     L,A
    MOV     A,H
    SBB     D
    MOV     H,A
    JNC     -							;brif int value >= 0
    DAD     D							;undo last subtraction
    SHLD    IFACLO_R					;FAC1 for integers
    POP     D
    POP     H
    MOV     M,B							;update output buffer
    INX     H
    POP     PSW							;restore loop counter
    POP     B							;restore BC
    DCR     A
    JNZ     L_PRINT_FAC_1						;brif A != 0: continue
L_PRINT_FAC_2:
    CALL    L_FOUTED					;add formatting. BC must be loaded
    MOV     M,A
    POP     D							;restore DE
    RET
;
; see also L_EXP_TBL
;
L_DEC_RANGES:
	DW		10000, 1000, 100, 10, 1
;
; Sets registers B & HL based on precision
;
; OUT:
;	B		precision count (#BCD digits)
;	HL		end of FAC
;
L_SET_NUM_BCD_DIGITS:
    LSTTYP								;Determine type of last var used: C Clr = DBL P Clr = SNGL Z Set = String S: Set = Integer
    LXI     H,DFACLO_R+7				;Point to end of FAC1 for Double Precision
    MVI     B,0EH						;preset Double Precision BCD count
    RNC									;retif Double Precision
    LXI     H,DFACLO_R+3				;0FC1BH
    MVI     B,06H						;set Single Precision BCD count
    RET
;
; Initialize FAC1 with 0.0 if it has no value
; Also sets HL to MBUFFER_R
;
R_FAC1_EQ_ZERO:							;3D11H
    STA     TEMP3_R
    PUSH    PSW
    PUSH    B
    PUSH    D
    CALL    L_FRCDBL				    ;CDBL function
    LXI     H,R_DBL_ZERO				;Code Based. 
    LDA     DFACLO_R					;exponent of FAC1
    ANA     A							;test it
    CZ      R_FAC1_EQ_FP				;Move floating point number M to FAC1
    POP     D
    POP     B
    POP     PSW
    LXI     H,MBUFFER_R
    MVI     M,' '
    RET
;
; IN:
;	A negative number
;
; OUT:
;	A
;
L_FND_BCD_POS:
    PUSH    H							;save WREGS
    PUSH    D
    PUSH    B
    PUSH    PSW							;save A
    CMA									;negate A
    INR     A
    MOV     E,A							;loop counter
    MVI     A,01H						;preload return value
    JZ      +							;brif A was 0: done
    CALL    L_SET_NUM_BCD_DIGITS		;Sets registers B (BCD precision count) & HL based on precision
    PUSH    H							;save ptr to FAC1 extended precision
-	CALL    L_ROTATER_FAC1				;Rotate FAC1 BCD digits right
    DCR     E
    JNZ     -
    POP     H							;restore ptr to FAC1 extended precision
    INX     H
    MOV     A,B							;extended precision counter
    RRC									;divide by 2
    MOV     B,A							;# of digits
    CALL    L_ROUND_FAC1_1
    CALL    L_FIND_NONZERO_BCD			;find non-zero BCD digit
+	POP     B							;saved arg A to B
    ADD     B
    POP     B							;restore WREGS
    POP     D
    POP     H
    RET

L_UNBIAS_EXP:
    PUSH    B							;save BC, HL
    PUSH    H
    CALL    L_SET_NUM_BCD_DIGITS		;Sets registers B (BCD precision count) & HL based on precision
    LDA     DFACLO_R					;FAC1 exponent
    SUI     40H							;exponent bias
    SUB     B							;BCD precision count
    STA     DFACLO_R					;FAC1
    POP     H							;restore HL, BC
    POP     B
    ORA     A
    RET
;
; find non-zero BCD digit
;
; OUT:
;	A	non-zero BCD digit index
; 
L_FIND_NONZERO_BCD:
    PUSH    B							;save BC
    CALL    L_SET_NUM_BCD_DIGITS		;Sets registers B (BCD precision count) & HL based on precision
; HL points to end of FAC
-	MOV     A,M							;isolate BCD digit
    ANI     0FH
    JNZ     +							;brif lower nibble BCD digit != 0
    DCR     B							;decrement BCD digit counter
    MOV     A,M							;get 2 BCD digits
    ORA     A							;test upper nibble BCD digit (lower is 0)
    JNZ     +							;brif upper nibble BCD digit != 0
    DCX     H							;continue to end of BCD mantissa
    DCR     B							;decrement BCD digit counter
    JNZ     -							;brif not done
+	MOV     A,B							;resulting BCD digit index
    POP     B							;restore BC
    RET
;
; Single precision exponential function
;
R_SNGL_EXP:								;3D7FH
    CALL    R_SNGL_LOAD				    ;Single precision load (FAC2=BCDE)
    CALL    L_CONDS
    CALL    R_PUSH_FAC2				    ;Push FAC2 on stack
    CALL    L_SWP_FAC_SP
    CALL    R_POP_FAC2				    ;Pop FAC2 from stack
;
; Double precision exponential function
;
R_DBL_EXP:								;3D8EH
    LDA     DFACLO2_R					;Start of FAC2
    ORA     A							;test exponent FAC2
    JZ      L_ONE_TO_FAC1				;brif FAC2 == 0. X pwr 0 = 1
    MOV     H,A
    LDA     DFACLO_R					;FAC1
    ORA     A							;test exponent FAC1
    JZ      L_INT_EXP_1					;brif FAC1 == 0 
    CALL    R_PUSH_FAC1				    ;Push FAC1 on stack
    CALL    L_CMP_INT_FAC1
    JC      L_DBL_EXP_1
    XCHG
    SHLD    TEMP8_R
    CALL    L_VALDBL
    CALL    R_POP_FAC2				   	;Pop FAC2 from stack
    CALL    L_CMP_INT_FAC1
    CALL    L_VALDBL
    LHLD    TEMP8_R
    JNC     L_INT_EXP_2
    LDA     DFACLO2_R					;Start of FAC2
    PUSH    PSW
    PUSH    H
    CALL    R_FAC1_EQ_FAC2				;Move FAC2 to FAC1
    LXI     H,FPTMP1_R					;Floating Point Temp 1
    CALL    R_MOVE_FAC1_TO_M			;Move FAC1 to M
    LXI     H,R_DBL_ONE					;Code Based. 1.0
    CALL    R_FAC1_EQ_FP				;Move floating point number M to FAC1
    POP     H
    MOV     A,H
    ORA     A
    PUSH    PSW
    JP      +
    XRA     A
    MOV     C,A
    SUB     L
    MOV     L,A
    MOV     A,C
    SBB     H
    MOV     H,A
+	PUSH    H
    JMP     L_INT_EXP_4

L_DBL_EXP_1:
    CALL    L_VALDBL
    CALL    R_FAC1_EQ_FAC2				;Move FAC2 to FAC1
    CALL    L_SWP_FAC_SP
    CALL    R_LOG_FUN				    ;LOG function
    CALL    R_POP_FAC2				    ;Pop FAC2 from stack
    CALL    R_DBL_MULT				    ;Double precision multiply (FAC1=FAC1*FAC2)
    JMP     R_EXP_FUN				    ;EXP function
;
; Integer exponential function
;
; X(DE) pwr HL
;
R_INT_EXP:								;3DF7H
    MOV     A,H							;test power
    ORA     L
    JNZ     +							;brif HL != 0
; power == 0, return X pwr 0 == 1
L_ONE_TO_FAC1:
    LXI     H,0001H						;load 1 to FAC1
    JMP     L_HL_TO_FAC1
+	MOV     A,D							;test X
    ORA     E
    JNZ     L_INT_EXP_2					;brif X != 0
; X == 0
L_INT_EXP_1:
    MOV     A,H							;exponent FAC1
    RAL									;test sign bit
    JNC     L_ZERO_TO_FAC1				;brif positive: return 0
    JMP     R_GEN_D0_ERROR				;Generate /0 error

L_ZERO_TO_FAC1:
    LXI     H,0
L_HL_TO_FAC1:
    JMP     L_MAKINT					;Load signed integer in HL to FAC1

L_INT_EXP_2:
    SHLD    TEMP8_R
    PUSH    D
    MOV     A,H
    ORA     A
    PUSH    PSW
    CM      L_INEGHL					;negate HL and Load signed integer in HL to FAC1
    MOV     B,H
    MOV     C,L
    LXI     H,0001H
L_INT_EXP_3:
    ORA     A							;clear carry
    MOV     A,B
    RAR
    MOV     B,A
    MOV     A,C
    RAR
    MOV     C,A
    JNC     +
    CALL    L_INT_EXP_9
    JNZ     L_INT_EXP_6
+	MOV     A,B
    ORA     C
    JZ      L_INT_EXP_7
    PUSH    H
    MOV     H,D
    MOV     L,E
    CALL    L_INT_EXP_9
    XCHG
    POP     H
    JZ      L_INT_EXP_3
    PUSH    B
    PUSH    H
    LXI     H,FPTMP1_R					;Floating Point Temp 1
    CALL    R_MOVE_FAC1_TO_M			;Move FAC1 to M
    POP     H
    CALL    R_CONV_SINT_HL_SNGL      	;Convert signed integer HL to single precision FAC1
    CALL    L_CONDS
L_INT_EXP_4:
    POP     B
    MOV     A,B
    ORA     A							;clear carry
    RAR
    MOV     B,A
    MOV     A,C
    RAR
    MOV     C,A
    JNC     L_INT_EXP_5
    PUSH    B
    LXI     H,FPTMP1_R					;Floating Point Temp 1
    CALL    R_MULT_M_FAC2				;Double precision math (FAC1=M * FAC2))
    POP     B
L_INT_EXP_5:
    MOV     A,B
    ORA     C
    JZ      L_INT_EXP_7
    PUSH    B
    CALL    R_PUSH_FAC1				    ;Push FAC1 on stack
    LXI     H,FPTMP1_R					;Floating Point Temp 1
    PUSH    H
    CALL    R_FAC1_EQ_FP				;Move floating point number M to FAC1
    POP     H
    PUSH    H
    CALL    R_MULT_M_FAC2				;Double precision math (FAC1=M * FAC2))
    POP     H
    CALL    R_MOVE_FAC1_TO_M			;Move FAC1 to M
    CALL    R_POP_FAC1				    ;Pop FAC1 from stack
    JMP     L_INT_EXP_4

L_INT_EXP_6:
    PUSH    B
    PUSH    D
    CALL    L_CONV_DBL_TO_FAC2			;Convert to DBL and move to FAC2
    POP     H
    CALL    R_CONV_SINT_HL_SNGL      	;Convert signed integer HL to single precision FAC1
    CALL    L_CONDS
    LXI     H,FPTMP1_R					;Floating Point Temp 1
    CALL    R_MOVE_FAC1_TO_M			;Move FAC1 to M
    CALL    R_FAC1_EQ_FAC2				;Move FAC2 to FAC1
    POP     B
    JMP     L_INT_EXP_5

L_INT_EXP_7:
    POP     PSW
    POP     B
    RP     
    LDA     VALTYP_R					;Type of last expression used
    CPI     02H
    JNZ     +
    PUSH    B
    CALL    R_CONV_SINT_HL_SNGL      	;Convert signed integer HL to single precision FAC1
    CALL    L_CONDS
    POP     B
+	LDA     DFACLO_R					;FAC1
    ORA     A
    JNZ     L_INT_EXP_8
    LHLD    TEMP8_R
    ORA     H
    RP     
    MOV     A,L
    RRC
    ANA     B
    JMP     R_GEN_OV_ERROR				;Generate OV error

L_INT_EXP_8:
    CALL    R_FAC2_EQ_FAC1				;Move FAC1 to FAC2
    LXI     H,R_DBL_ONE					;Code Based. 1.0
    CALL    R_FAC1_EQ_FP				;Move floating point number M to FAC1
    JMP     R_DBL_DIV				    ;Double precision divide (FAC1=FAC1/FAC2)

L_INT_EXP_9:
    PUSH    B
    PUSH    D
    CALL    R_SINT_MULT				    ;Signed integer muliply (FAC1=HL*DE)
    LDA     VALTYP_R					;Type of last expression used
    CPI     02H
    POP     D
    POP     B
    RET

L_CMP_INT_FAC1:
    CALL    R_FAC1_EQ_FAC2				;Move FAC2 to FAC1
    CALL    R_PUSH_FAC2				    ;Push FAC2 on stack
    CALL    R_INT_FUN				    ;INT function
    CALL    R_POP_FAC2				    ;Pop FAC2 from stack
    CALL    L_CMP_DBL_FAC1_2			;Double precision compare FAC1 with FAC2
    STC									;preset carry return
    RNZ
    JMP     L_CVT_FP_TO_INT
;
; check stack space
; Copy data from BC to HL down until BC == DE
;
L_CPY_BC_TO_HL_CHK:
    CALL    R_GETSTK2					;Test HL against stack space for collision
L_BLTUC:
L_CPY_BC_TO_HL:
    PUSH    B							;swap BC and HL
    XTHL
    POP     B
-	COMPAR								;HL - DE
    MOV     A,M							;get char from M
    STAX    B							;store at BC ptr
    RZ									;retif DE == HL
    DCX     B
    DCX     H
    JMP     -
;
; Test for C 2-byte units free in stack space
;
R_GETSTK:
    PUSH    H							;save HL
    LHLD    STRGEND_R					;Unused memory pointer
    MVI     B,00H						;zero extend C to BC
    DAD     B							;add units twice to get bytes
    DAD     B
	SKIP_BYTE_INST						;Sets A to 0AFH. HL already pushed
; 
; Test HL against stack space for collision
; 
R_GETSTK2:
    PUSH    H
    MVI     A,88H						;subtract HL from 0FF88H (-78H), result in HL
    SUB     L
    MOV     L,A
    MVI     A,0FFH
    SBB     H
    MOV     H,A
    JC      L_OUTOFMEMORY				;brif HL > 0FF88H
    DAD     SP							;add delta to SP, result in carry
    POP     H							;restore HL
    RC
L_OUTOFMEMORY:
    CALL    R_UPDATE_LINE_ADDR       	;Update line addresses for current BASIC program
    LHLD    STRBUF_R					;BASIC string buffer pointer
    DCX     H
    DCX     H
    SHLD    BASSTK_R					;SP used by BASIC to reinitialize the stack
    LXI     D,0007H						;"OUT OF MEMORY"
    JMP     R_GEN_ERR_IN_E				;Generate error 7
;
; Initialize BASIC Variables for new execution
;
R_INIT_BASIC_VARS:						;3F28H
    LHLD    TXTTAB_R					;Start of BASIC program pointer
    DCX     H
R_INIT_BASIC_VARS_2:
    SHLD    LSTVAR_R					;Address of last variable assigned
R_INIT_BASIC_VARS_3:
    CALL    R_CLEAR_COM_INT_DEF         ;Clear all COM), TIME), and KEY interrupt definitions
;
; initialize DEFINT table
;
    MVI     B,1AH					    ;26 letters
    LXI     H,DEFTBL_R				   	;DEF definition table
-	MVI     M,08H						;default to double precision
    INX     H
    DCR     B
    JNZ     -
    CALL    R_INIT_TEMP3				;Initialize FP_TEMP3 for new program
    XRA     A
    STA     PRGRUN_R					;BASIC Program Running Flag
    MOV     L,A
    MOV     H,A
    SHLD    ONERR_R						;Address of ON ERROR routine
    SHLD    OLDTXT_R					;Address where program stopped on last break), END), or STOP
    LHLD    MEMSIZ_R					;File buffer area pointer.  Also end of Strings Buffer Area.
    SHLD    FRETOP_R					;Pointer to current location in BASIC string buffer
    CALL    R_RESTORE_STMT				;RESTORE statement
    LHLD    VARTAB_R				    ;Start of variable data pointer
    SHLD    ARYTAB_R				    ;ptr to Start of array table
    SHLD    STRGEND_R				    ;Unused memory pointer
    CALL    R_CLSALL					;Close Files
    LDA     OPNFIL_R
    ANI     01H							;00000001
    JNZ     L_INIT_BASIC				;brif bit 0 set: Initialize BASIC for new execution
    STA     OPNFIL_R					;clear OPNFIL_R
; 
; Initialize BASIC for new execution
; 
L_INIT_BASIC:
    POP     B							;Code address
    LHLD    STRBUF_R					;BASIC string buffer pointer
    DCX     H							;leave 2 bytes
    DCX     H
    SHLD    BASSTK_R					;SP used by BASIC to reinitialize the stack
    INX     H							;back to [STRBUF_R]
    INX     H
L_INIT_BASIC_0:						 	;BC contains a code address
    SPHL								;set stack pointer
    LXI     H,TEMPST_R
    SHLD    TEMPPT_R					;initialize String Stack ptr
    CALL    R_SET_OUT_DEV_LCD			;Reinitialize output back to LCD
    CALL    L_FINPRT
;clear all these variables
    XRA     A
    MOV     H,A							;set A & HL to 0
    MOV     L,A
    SHLD    UNUSED6_R					;only reference to this location
    STA     UNUSED2_R					;only reference to this location
    SHLD    UNUSED3_R					;only reference to this location
    SHLD    UNUSED1_R					;only reference to this location
    SHLD    0FBD4H
    STA     SUBFLG_R					;clear DON'T RECOGNIZE SUBSCRIPTED VARIABLES flag
    PUSH    H							;push 0
    PUSH    B							;return address to stack
L_INIT_BASIC_1:
    LHLD    LSTVAR_R					;load Address of last variable assigned
    RET
;
; TIME$ ON statement
; Actually Interrupt ON processing
;
; IN:
;	HL	System Interrupt Table entry to update
;
R_INT_ON_STMT:							;3FA0H
    DI 
    MOV     A,M
    ANI     04H							;00000100 isolate bit 2
    ORI     01H							;00000001 set bit 0
    CMP     M							;compare
    MOV     M,A							;update
    JZ      +							;brif same; no change
    ANI     04H							;00000100
    JNZ     R_INC_PNDINT				;Increment the pending interrupt count if bit 2 set
+	EI     
    RET
;
; TIME$ OFF statement
; Actually Interrupt OFF processing
;
; IN:
;	HL	System Interrupt Table entry to update
;
R_TIME_OFF_STMT:						;3FB2H
    DI 
    MOV     A,M							;get current value
    MVI     M,00H						;clear
    JMP     L_INT_STOP_STMT_1
;
; TIME$ STOP statement
; Actually Interrupt STOP processing
;
; IN:
;	HL	System Interrupt Table entry to update
;
R_INT_STOP_STMT:						;3FB9H
    DI 
    MOV     A,M
    PUSH    PSW
    ORI     02H							;00000010
    MOV     M,A							;update table
    POP     PSW
L_INT_STOP_STMT_1:
    XRI     05H							;Validate the interrupt should be counted
    JZ      R_DEC_PNDINT
    EI     
    RET
	
;
;
; IN:
;	HL	System Interrupt Table entry to update
;
L_UPD_INTR_TBL:
    DI 
    MOV     A,M
    ANI     05H							;00000101B isolate bits 0,2
    CMP     M
    MOV     M,A							;update table
    JNZ     L_TRIG_INTR_1
    EI     
    RET
;
; Trigger interrupt.
;
; IN:
;	HL points to interrupt table
;
R_TRIG_INTR:							;3FD2H
    DI 
    MOV     A,M
    ANI     01H							;isolate bit 0
    JZ      +							;brif bit 0 clear
    MOV     A,M
    ORI     04H							;set bit 2 in A
    CMP     M
    JZ		+							;brif bit 2 was set
    MOV     M,A							;set bit 2 in M
L_TRIG_INTR_1:
;	Validate the interrupt should be counted
    XRI     05H							;00000101B. Z set if A == 05H
    JZ      R_INC_PNDINT				;Increment the pending interrupt count
+	EI
    RET
;
; Increment the pending interrupt count
;
; TODO If HL can be changed => LXI H,PNDINT_R INR M
;
R_INC_PNDINT:
    LDA     PNDINT_R
    INR     A
    STA     PNDINT_R
    EI     
    RET
;
; Clear interrupt.  HL points to interrupt table
;
R_CLEAR_INTR:							;3FF1H
    DI 
    MOV     A,M
    ANI     03H							;00000011B
    CMP     M
    MOV     M,A							;update
    JNZ     R_DEC_PNDINT
L_ENA_INTR:
    EI     
    RET

R_DEC_PNDINT:
    LDA     PNDINT_R
    SUI     01H							;need carry so no decrement
    JC      L_ENA_INTR					;brif A < 1: EI & RET
    STA     PNDINT_R
    EI     
    RET
;
; Clear all COM), TIME), and KEY interrupt definitions
; SYSINT_R has 10 entries, each 3 bytes
;
R_CLEAR_COM_INT_DEF:				  	;4009H
    LXI     H,SYSINT_R				  	;Basic Interrupt Table
    MVI     B,10						;length
    XRA     A
-	MOV     M,A							;each entry is 3 bytes
    INX     H
    MOV     M,A
    INX     H
    MOV     M,A
    INX     H
    DCR     B
    JNZ     -							;loop
    LXI     H,FKEYSTAT_R				;Function key status table (1 = on)
    MVI     B,08H						;length. A == 0
-	MOV     M,A							;clear
    INX     H
    DCR     B
    JNZ     -							;loop
    STA     PNDINT_R					;clear PNDINT_R
    RET

; 
; Process ON KEY/TIME$/COM/MDM interrupts from BASIC
; May not return
; 
L_PROCESS_ON_INT:						;Entry with B set to 2
    MVI     B,02H						;Mark entry from ON COM
	SKIP_2BYTES_INST_DE
L_PROCESS_ON_INT_1:						;Entry with B set to 1
    MVI     B,01H						;Mark entry from ON KEY/TIME$
    LDA     PRGRUN_R					;BASIC Program Running Flag
    ORA     A
    RNZ									;retif PRGRUN_R != 0
    PUSH    H							;save HL for a long time
    LHLD    CURLIN_R					;Currently executing line number
    MOV     A,H							;test for 0FFFFH
    ANA     L
    INR     A
    JZ      L_PROCESS_ON_INT_3			;brif CURLIN_R == 0FFFFH
    DCR     B							;Test for entry from ON COM
    JNZ     L_ON_COM_INTR				;brif TRUE. HL on stack
    LXI     H,SYSINT_R+3				;On Time flag
    MVI     B,09H						;Loop for 9 ON-TIME, ON-KEY, etc. interrupts
-	MOV     A,M
    CPI     05H
    JZ      L_ON_XXX_INTR				;brif Interrupt triggered by this event F1, F2, TIME$, etc.
										;	HL on stack
L_PROCESS_ON_INT_2:
    INX     H							;Skip ON-XXX flag
    INX     H							;Skip ON-XXX line number
    INX     H
    DCR     B							;Decrement number of ON-XXX events checked
    JNZ     -							;brif != 0
;
; Done checking interrupt table
;
L_PROCESS_ON_INT_3:
    POP     H
    RET

; 
; Process a triggered ON-XXX interrupt (F1, F2, ..., Time$)
; HL on stack
; 
L_ON_XXX_INTR:
    PUSH    B							;Save the ON-XXX index number
    INX     H
	GETDEFROMMNOINC
    DCX     H							;Restore HL back to ON-XXX flag
    DCX     H
    MOV     A,D							;test if the ON-XXX line == 0
    ORA     E
    POP     B							;restore the ON-XXX index number
    JZ      L_PROCESS_ON_INT_2			;brif ON-XXX line == 0: no action
    PUSH    D							;save ON-XXX line
    PUSH    H							;save HL
    CALL    R_CLEAR_INTR				;Clear interrupt.  HL points to interrupt table
    CALL    R_INT_STOP_STMT				;TIME$ STOP statement
    MVI     C,03H
    CALL    R_GETSTK					;Test for 3 bytes free in stack space
    POP     B							;discard saved HL
    POP     D							;restore ON-XXX line
    POP     H							;restore earlier HL
    POP     PSW							;discard return address
    JMP     L_GOSUB_ON_INTR				;GOSUB to BASIC line due to ON KEY/TIME$/MDM/COM
	
; 
; Process ON COM interrupt
; HL on stack
; 
L_ON_COM_INTR:
    LXI     H,SYSINT_R				    ;On Com flag
    MOV     A,M							;Get COM flag
    DCR     A
    JZ      L_ON_XXX_INTR				;If 1, jump to process interrupt
    POP     H
    RET
;
; RESTORE statement
;
R_RESTORE_STMT:							;407FH
    XCHG
    LHLD    TXTTAB_R					;Start of BASIC program pointer
    JZ      +
    XCHG
    CALL    L_LINGET					;Convert line number at M to binary in DE
    PUSH    H
    CALL    L_FNDLIN					;Find line number in DE
    MOV     H,B
    MOV     L,C
    POP     D
    JNC     R_GEN_UL_ERROR				;Generate UL error
+	DCX     H
L_RESTORE_1:
    SHLD    DATAPTR_R					;Address where DATA search will begin next
    XCHG
    RET
;
; STOP statement
;
R_STOP_STMT:							;409AH
    RNZ 								;MAKE SURE "STOP" STATEMENTS HAVE A TERMINATOR   
    INR     A							;this sets A == 1
    JMP     L_CONSTP
;
; END statement
; A == [HL]
; L_NEWSTT ADDRESS on the stack
;
R_END_STMT:								;409FH
    RNZ									;MAKE SURE "END" STATEMENTS HAVE A TERMINATOR
    XRA     A							;TODO A probably already 0
    STA     PRGRUN_R					;clear BASIC Program Running Flag
    PUSH    PSW
    CZ      R_CLSALL					;A always 0. Close Files
    POP     PSW							;TODO cheaper to clear A again
L_CONSTP:								;A==0 if END. A==1 if STOP
    SHLD    SAVTXT_R					;Most recent or currenly running line pointer (SAVTXT: SAVE FOR "CONTINUE")
    LXI     H,TEMPST_R					;(TEMPST)
    SHLD    TEMPPT_R					;reset String Stack ptr (TEMPPT)
	SKIP_2BYTES_INST_HL					;skip ORI 0FFH instruction. A==0 or 1
L_STPEND:
    ORI     0FFH						;SET NON-ZERO TO FORCE PRINTING OF BREAK MESSAGE
    POP     B							;POP OFF L_NEWSTT ADDRESS
L_ENDCON:
    LHLD    CURLIN_R					;Currently executing line number
    PUSH    H							;SAVE LINE TO PRINT
    PUSH    PSW							;SAVE THE MESSAGE FLAG ZERO MEANS DON'T PRINT "BREAK"
    MOV     A,L							;See IF IT WAS DIRECT 
    ANA     H
    INR     A
    JZ      L_DIRIS						;IF NOT SET UP FOR CONTINUE
    SHLD    OLDLIN_R					;Line where break), END), or STOP occurred. ;SAVE OLD LINE #
    LHLD    SAVTXT_R					;Most recent or currenly running line pointer ;GET POINTER TO START OF STATEMENT
    SHLD    OLDTXT_R					;Address where program stopped on last break), END), or STOP ;SAVE IT
L_DIRIS:
    CALL    R_SET_OUT_DEV_LCD			;Reinitialize output back to LCD FINLPT?
    CALL    R_LCD_NEW_LINE				;Move LCD to blank line (send CRLF if needed)
										;	CRDONZ: PRINT CR IF TTYPOS .NE. 0
    POP     PSW							;GET BACK ^C FLAG
 
;	LXI	H,BRKTXT		;"BREAK"
;	JNZ	ERRFIN			;CALL STROUT AND FALL INTO READY
;	JMP	STPRDY			;POP OFF LINE NUMBER & FALL INTO READY

	LXI     H,R_BREAK_MSG				;Code Based. 
    JNZ     L_ERRFIN
    JMP     R_POP_GO_BASIC_RDY       	;Pop stack and vector to BASIC ready
;
; CONT sttement
;
R_CONT_STMT:							;40DAH
    LHLD    OLDTXT_R					;Address where program stopped on last break), END), or STOP

;	MOV	A,H								;"STOP","END",TYPING CRLF
;	ORA	L								;TO "INPUT" AND ^C SETUP OLDTXT

    MOV     A,H
    ORA     L
    LXI     D,0011H						;"CAN'T CONTINUE"
    JZ      R_GEN_ERR_IN_E				;Generate error 11H
    XCHG								;save HL in DE
    LHLD    OLDLIN_R					;Line where break), END), or STOP occurred
    SHLD    CURLIN_R					;SET UP OLD LINE # AS CURRENT LINE #
    XCHG								;restore HL
    RET
;
; TODO Unreachable
;
    JMP     R_GEN_FC_ERROR				;Generate FC error
;
; Check if M is alpha character
;
R_ISLET_M:								     	;40F1H
    MOV     A,M
;
; Check if A is alpha character
;
; OUT:
;	carry	set if not alpha
;
R_ISLET:
    CPI     'A'							;41H
    RC
    CPI     'Z'+1						;5BH
    CMC
    RET
;
; CLEAR statement
;
; CLEAR [num1][,num2]
; num1 is string space
; num2 is HIMEM start
;
R_CLEAR_STMT:							;40F9H
    PUSH    H							;save txt ptr
    CALL    L_CLR_PASTE_BUF
    POP     H							;restore txt ptr
    DCX     H							;backup
    CHRGET								;Get next non-white char from M
    JZ      R_INIT_BASIC_VARS_2			;brif done with command
	RST38H	00H
    CALL    L_EVAL_POS_EXPR				;Eval positive expression at M-1: string space. result in DE
    DCX     H
    CHRGET								;Get next non-white char from M
    PUSH    H							;save txt ptr
    LHLD    HIMEM_R						;HIMEM
    MOV     B,H							;BC = HIMEM
    MOV     C,L
    LHLD    MEMSIZ_R					;File buffer area pointer. Also end of Strings Buffer Area.
    JZ      L_CLEAR_2					;brif done with command
    POP     H							;restore txt ptr
	SYNCHK	','							;','					;2CH
    PUSH    D							;save
    CALL    R_EVAL_EXPR_2				;Evaluate expression at M_2
    DCX     H							;backup
    CHRGET								;Get next non-white char from M
    JNZ     R_GEN_SN_ERROR				;Generate Syntax error if not done with command
    XTHL
    XCHG
    MOV     A,H
    ANA     A
    JP      R_GEN_FC_ERROR				;Generate FC error if new HIMEM <8000H
    PUSH    D							;save DE
    LXI     D,SYSRAM_R+1				;0F5F1H Maximum new HIMEM allowed
    COMPAR								;HL - DE
    JNC     R_GEN_FC_ERROR				;Generate FC error if new HIMEM >= SYSRAM_R+1
    POP     D							;restore DE
    PUSH    H							;save new HIMEM
    LXI     B,0FEF5H					;-267
    LDA     MAXFILES_R					;Maxfiles
-	DAD     B							;subtract 267 from new HIMEM
    DCR     A							;loop counter
    JP		-
    POP     B							;BC = new HIMEM
    DCX     H
;
; BC = new HIMEM
; DE = new String Space
; HL = new File buffer area pointer
;
L_CLEAR_2:
    MOV     A,L							;DE=HL-DE
    SUB     E
    MOV     E,A
    MOV     A,H
    SBB     D
    MOV     D,A
    JC      L_OUTOFMEMORY				;brif HL < DE
; DE is new String Space ptr
    PUSH    H							;save HL
    LHLD    VARTAB_R					;Start of variable data pointer
    PUSH    B							;save BC
    LXI     B,00A0H						;160
    DAD     B							;HL += 160
    POP     B							;restore BC
    COMPAR								;HL - DE
    JNC     L_OUTOFMEMORY
    XCHG								;new string space ptr to HL
    SHLD    STRBUF_R					;update BASIC string buffer pointer
    MOV     H,B							;HL = BC
    MOV     L,C
    SHLD    HIMEM_R						;update HIMEM
    POP     H							;restore HL
    SHLD    MEMSIZ_R					;File buffer area pointer. Also end of Strings Buffer Area.
    POP     H
    CALL    R_INIT_BASIC_VARS_2
    LDA     MAXFILES_R					;Maxfiles
    CALL    L_UPD_FILEBUFS
    LHLD    LSTVAR_R					;Address of last variable assigned
    JMP     L_NEWSTT					;Execute BASIC program
;
; NEXT statement
;
; IN:
;	Z		set if end of line found
;
R_NEXT_STMT:							;4174H
    LXI     D,0							;preset if no NEXT variable
L_NEXT_STMT_1:
    CNZ     R_FIND_VAR_ADDR				;Find address of variable at M
    SHLD    LSTVAR_R					;Address of last variable assigned
    CALL    FNDFOR						;Pop return address for NEXT or RETURN
    JNZ     R_GEN_NF_ERROR				;brif Z not set: Generate NF error
    SPHL								;set SP to virtual stack ptr: remove FOR structure
    PUSH    D							;save variable ptr
    MOV     A,M
    PUSH    PSW
    INX     H
    PUSH    D
    MOV     A,M							;get TYPE or STEP sign
    INX     H
    ORA     A
    JM      L_NEXT_STMT_2				;brif tested A==0FFH
    DCR     A
    JNZ     +							;brif tested A == 0
    LXI     B,08H
    DAD     B
+	ADI		04H							;fix type
    STA     VALTYP_R					;Type of last expression used
    CALL    L_CPY_M_TO_FAC1				;Move VALTYP_R bytes from M to FAC1 with increment
    XCHG
    XTHL
    PUSH    H
    LSTTYP								;Determine type of last var used: C Clr = DBL P Clr = SNGL Z Set = String S: Set = Integer
    JNC     L_NEXT_STMT_4				;brif carry clear: DBL type
    CALL    R_SNGL_BCDE_EQ_M			;Load single precision at M to BCDE
    CALL    R_SNGL_ADD_BCDE				;Single precision addition (FAC1=FAC1+BCDE)
    POP     H
    CALL    R_SNGL_M_EQ_FAC1			;Move single precision FAC1 to M
    POP     H
    CALL    R_SNGL_DECB_EQ_M			;Reverse load single precision at M to DEBC
    PUSH    H
    CALL    R_SNGL_CMP_BCDE_FAC1     	;Compare single precision in BCDE with FAC1
    JMP     L_NEXT_STMT_3
;
; integer type FOR loop
;
L_NEXT_STMT_2:
    LXI     B,000CH						;add 12 to HL
    DAD     B
    MOV     C,M							;get BC from M
    INX     H
    MOV     B,M
    INX     H
    XTHL
	GETDEFROMMNOINC						;step value
    PUSH    H
    MOV     L,C							
    MOV     H,B
    CALL    R_SINT_ADD					;Signed integer addition (FAC1=HL+DE)
    LDA     VALTYP_R					;Type of last expression used
    CPI     02H
    JNZ     R_GEN_OV_ERROR				;brif type != INT Generate OV error
    XCHG								;result of addition to DE
    POP     H							;restore FOR loop structure ptr
    MOV     M,D							;store DE at M: update loop variable
    DCX     H
    MOV     M,E
    POP     H							;restore HL
    PUSH    D							;save DE
	GETDEFROMM							;get DE from M: upper FOR loop value
    XTHL								;swap HL with pushed DE
    CALL    R_SINT_CMP				   	;Compare signed integer in DE with that in HL
L_NEXT_STMT_3:
    POP     H
    POP     B
    SUB     B
    CALL    R_SNGL_DECB_EQ_M			;Reverse load single precision at M to DEBC
    JZ      L_NEXT_STMT_5				;brif end of FOR loop reached
    XCHG								;FOR loop line number to HL
    SHLD    CURLIN_R					;Currently executing line number
    MOV     L,C
    MOV     H,B
    JMP     L_PUSH_FOR						;push _FOR on stack
;
; DBL Type
;
L_NEXT_STMT_4:
    CALL    R_DBL_ADD_M					;Double precision addition (FAC1=FAC1+M)
    POP     H
    CALL    L_CPY_FAC1_TO_M				;copy from FAC1 to M
    POP     H
    CALL    R_LOAD_FAC2_FROM_M       	;Move M to FAC2 using precision at VALTYP_R
    PUSH    D
    CALL    L_CMP_DBL_FAC1_2			;Double precision compare FAC1 with FAC2
    JMP     L_NEXT_STMT_3
;
; End of FOR loop reached
;
L_NEXT_STMT_5:
    SPHL								;remove FOR loop structure from stack
    SHLD    BASSTK_R					;SP used by BASIC to reinitialize the stack
    XCHG								;to DE
    LHLD    LSTVAR_R					;Address of last variable assigned. TODO text ptr
    MOV     A,M							;get next char
    CPI     ','
    JNZ     L_NEWSTT					;Execute BASIC program
    CHRGET								;Get next non-white char from M
    CALL    L_NEXT_STMT_1				;process for FOR loop variables. Leave 2 bytes on stack.
;
; Test if FCBLAST_R == 0
;
; OUT:
;	Z		set if FCBLAST_R == 0
;
L_TST_FCBLAST:
    PUSH    H
    LHLD    FCBLAST_R					;FCB ptr for the last file used (2 bytes)
    MOV     A,H
    ORA     L
    POP     H
    RET
;
; Send CRLF to screen or printer
;
R_SEND_CRLF:							;4222H
    MVI     A,0DH
    OUTCHR								;Send character in A to screen/printer
;
; Send LF to screen or printer
;
;R_SEND_LF:								;4225H
    MVI     A,0AH
    OUTCHR								;Send character in A to screen/printer
    RET
;
; BEEP statement
;
R_BEEP_STMT:							;4229H
    MVI     A,07H
    OUTCHR								;Send character in A to screen/printer
    RET
;
; Home cursor
;
R_HOME_CURSOR:							;422DH
    MVI     A,0BH
    OUTCHR								;Send character in A to screen/printer
    RET
;
; Clear Screen
;
R_CLS_STMT:								;4231H
    MVI     A,0CH
    OUTCHR								;Send character in A to screen/printer
    RET
;
; Protect line 8.
;
R_PROTECT_LABEL:						;4235H
    MVI     A,'T'						;54H
    JMP     R_SEND_ESC_SEQ				;Send escape sequence
;
; Unprotect line 8.
;
R_UNPROT_LABEL:							;423AH
    MVI     A,'U'						;55H
    JMP     R_SEND_ESC_SEQ				;Send escape sequence
;
; Stop automatic scrolling
;
R_STOP_AUTO_SCROLL:						;423FH
    MVI     A,'V'						;56H
    JMP     R_SEND_ESC_SEQ				;Send escape sequence
;
; Resume automatic scrolling
;
R_RESUME_AUTO_SCROLL:				    ;4244H
    MVI     A,'W'						;57H
    JMP     R_SEND_ESC_SEQ				;Send escape sequence
;
; Turn the cursor on
;
R_TURN_CURSOR_ON:						;4249H
    MVI     A,'P'						;50H
    JMP     R_SEND_ESC_SEQ				;Send escape sequence
;
; Turn the cursor off
;
R_TURN_CURSOR_OFF:						;424EH
    MVI     A,'Q'						;51H
    JMP     R_SEND_ESC_SEQ				;Send escape sequence
;
; Delete current line on screen
;
R_DEL_CUR_LINE:							;4253H
    MVI     A,'M'						;4DH
    JMP     R_SEND_ESC_SEQ				;Send escape sequence
;
; Insert line a current line
;
R_INSERT_LINE:							;4258H
    MVI     A,'L'						;4CH
    JMP     R_SEND_ESC_SEQ				;Send escape sequence
;
; Erase from cursor to end of line
;
R_ERASE_TO_EOL:							;425DH
    MVI     A,'K'						;4BH
    JMP     R_SEND_ESC_SEQ				;Send escape sequence
;
; Send ESC X
;
R_SEND_ESC_X:							;4262H
    MVI     A,'X'						;58H
    JMP     R_SEND_ESC_SEQ				;Send escape sequence
;
; Test if A & M are both 0
; if so, return else R_INV_CHAR_ENABLE
;
L_COND_INV_CHAR:
    ORA     M
    RZ
;
; Start inverse character mode
;
R_INV_CHAR_ENABLE:						;4269H
    MVI     A,'p'						;70H
    JMP     R_SEND_ESC_SEQ				;Send escape sequence
;
; Cancel inverse character mode
;
R_INV_CHAR_DISABLE:						;426EH
    MVI     A,'q'						;71H
;
; Send escape sequence
;
R_SEND_ESC_SEQ:							;4270H
    PUSH    PSW
    MVI     A,1BH						;ESC
    OUTCHR								;Send character in A to screen/printer
    POP     PSW
    OUTCHR								;Send character in A to screen/printer
    RET
;
; Send cursor to lower left of CRT: : max row, col 1
;
R_CURSOR_TO_LOW_LEFT:				    ;4277H
    LHLD    LINCNT_R					;Console height + Console width
    MVI     H,01H
;
; Set the current cursor position
;
R_SET_CURSOR_POS:						;427CH
    MVI     A,'Y'						;59H
    CALL    R_SEND_ESC_SEQ				;Send escape sequence
    MOV     A,L
    ADI		1FH							;31
    OUTCHR								;Send character in A to screen/printer
    MOV     A,H
    ADI		1FH							;31
    OUTCHR								;Send character in A to screen/printer
    RET
;
; Erase function key display
;
R_ERASE_FKEY_DISP:						;428AH
    LDA     LINPROT_R					;Label line protect status
    ANA     A
    RZ
    CALL    R_UNPROT_LABEL				;Unprotect line 8.  An ESC U is printed
    LHLD    CSRY_R						;Cursor row (1-8) + column (1-40)
    PUSH    H
    CALL    R_CURSOR_TO_LOW_LEFT     	;Send cursor to lower left of CRT
    CALL    R_ERASE_TO_EOL			 	;Erase from cursor to end of line
    POP     H
    CALL    R_SET_CURSOR_POS			;Set the current cursor position
    CALL    R_SEND_ESC_X				;Send ESC X
    XRA     A
    RET
;
; Set and display function keys (M has key table)
;
R_SET_DISP_FKEY:						;42A5H
    CALL    R_SET_FKEYS				    ;Set new function key table
;
; Display function key line
;
R_DISP_FKEY_LINE:						;42A8H
    LHLD    CSRY_R						;Cursor row (1-8) + column (1-40)
    LDA     LINCNT_R					;Console height
    CMP     L							;compare w/ Cursor row
    JNZ     +							;brif not same
; on last row: make room for Function Keys
    PUSH    H							;save cursor position
    CALL    L_SCROLL_LCD				;move all lines up 1 position
    MVI     L,01H						;cursor row 1
    CALL    R_SET_CURSOR_POS			;Set the current cursor position
    CALL    R_DEL_CUR_LINE				;Delete row 1 on screen
    POP     H							;restore cursor position
    DCR     L							;cursor row --
+	PUSH    H							;save cursor position
    CALL    R_UNPROT_LABEL				;Unprotect line 8 using ESC U.
    CALL    R_CURSOR_TO_LOW_LEFT       	;Send cursor to lower left of CRT: last row, column 1
    LXI     H,FNKSTR_R				  	;Function key definition area ptr
    MVI     E,08H						;loop 8 times
    LDA     REVFLG_R					;Reverse video switch
    PUSH    PSW							;save REVFLG_R
    CALL    R_INV_CHAR_DISABLE         	;Cancel inverse character mode
L_FKEY_LOOP:							;E = loop counter
    LDA     LINWDT_R					;Active columns count (1-40)
    CPI     MAXCHRCOLUMN				;40
    LXI     B,040CH						;preload B: # of chars. C: keysize in FNKSTR_R
    JZ      +							;brif LINWDT_R == 40
;
; LINWDT_R is 80 if VT100/DVI
;
    LXI     B,0907H						;new data: 9 chars per key to show, keysize is 7
+	PUSH    H							;save updated Function key definition area ptr
;
; conditionally enable inverse video
; A: if loop counter E == 6 && [SER_UPDWN_R+1] == 0
; B: if loop counter E == 7 && [SER_UPDWN_R] == 0
;
    LXI     H,SER_UPDWN_R+1
    MOV     A,E							;loop counter
    SUI     06H
    JZ      +							;brif loop counter == 6. A == 0
    DCR     A							;A now E - 1
    DCX     H							;HL points to SER_UPDWN_R
+	CZ      L_COND_INV_CHAR				;conditionally enable inverse video: if (A | M) == 0
    POP     H							;restore Function key definition area ptr
    CALL    R_SEND_CHARS_TO_LCD      	;Send B characters from M to the screen. Clears B on exit.
    DAD     B							;update ptr into Function key definition area
    CALL    R_INV_CHAR_DISABLE       	;Cancel inverse character mode
    DCR     E							;loop counter
    CNZ     R_PRINT_SPACE				;Send a space to screen/printer
    JNZ     L_FKEY_LOOP					;brif loop counter != 0
    CALL    R_ERASE_TO_EOL				;Erase from cursor to end of line
    CALL    R_PROTECT_LABEL				;Protect line 8 using ESC T.
    POP     PSW							;restore REVFLG_R
    ANA     A
    CNZ     R_INV_CHAR_ENABLE			;calif REVFLG_R != 0: Start inverse character mode
    POP     H							;restore cursor position
    CALL    R_SET_CURSOR_POS			;Set the current cursor position (H=Row,L=Col)
    CALL    R_SEND_ESC_X				;Send ESC X
    XRA     A
    RET
;
; Print A to the screen
;
R_PRINT_A_TO_LCD:						;4313H
    PUSH    H
    PUSH    D
    PUSH    B
    PUSH    PSW
	RST38H	08H							;intercepted to hk_rst4 in VT100
    CALL    R_CHAR_PLOT
    JMP     R_POP_ALL_REGS				;Pop AF), BC), DE), HL from stack
;
; Print A to the screen after all registers saved on stack
;
R_CHAR_PLOT:
    MOV     C,A
    XRA     A
    STA     POPPSW_R					;clear POPPSW_R
    LDA     CONDEV_R					;New Console device flag
    ANA     A							;test
    JNZ     L_INIT_DVI					;Initialize LCD/DVI 
    CALL    R_CHAR_PLOT_4				;Character plotting level 4. Turn off background task & call level 5
    LHLD    CSRY_R						;Cursor row (1-8) + column (1-40)
    SHLD    LCDCSY_R					;Cursor row (1-8) + column
    RET
;
; Character plotting level 4. Turn off background task & call level 5
;
R_CHAR_PLOT_4:							;4335H
    CALL    L_BLINK_LCD					;Turn off background task, blink & reinitialize cursor blink time
    CALL    R_CHAR_PLOT_5				;Character plotting level 5. Handle ESC sequences & call level 6
L_CHAR_PLOT_4_1:
    LHLD    CSRY_R						;Cursor row (1-8) & Column (1-40) to DE
    XCHG
    CALL    L_SET_LCTEYX				;Rebase LCD column # & row #
    LDA     CURSTAT_R					;Cursor status (0 = off)
    ANA     A
    RZ									;retif A == 0
	JMP		L_INIT_CRS_BLINK			;Initialize Cursor Blink to start blinking
;
; Initialize New Screen for LCD/DVI RST 7 hook
; Initialize LCD/DVI - called from level 3 character print
;
L_INIT_DVI:
	RST38H	3CH
;
; Character plotting level 5. Handle ESC sequences & call level 6
;
R_CHAR_PLOT_5:							;434CH
    LXI     H,ESCRST20_R				;ESC mode flag for OUTCHR (RST 20H)
    MOV     A,M							;test it
    ANA     A
    JNZ     R_ESC_SEQ_DRIVER			;brif active: ESCape sequence driver
    MOV     A,C
    LHLD    CSRY_R						;Cursor row (1-8) + column (1-40)
    CPI     09H							;TAB
    JZ      R_TAB_FUN				    ;Tab routine
    CPI     7FH							;DEL
    JZ      L_DISP_BKSP
    CPI     ' '
    JC      R_LCD_OUT_DRIVER			;brif char < ' ': LCD output driver
    CALL    R_CHAR_PLOT_6				;Character plotting level 6.
										;Save character in C to LCD RAM & call level 7
    CALL    R_ESC_C_FUN				    ;ESC C routine (move cursor right)
    RNZ
    MVI     H,01H
    JMP     R_LF_FUN				   	;Linefeed routine
;
; LCD output driver. 
;
R_LCD_OUT_DRIVER:						;4373H
    LXI     H,R_RST_20H_LKUP_TBL-2		;Code Based. 
    MVI     C,(L_RST_20H_LKUP_END-R_RST_20H_LKUP_TBL)/3 ;08H count
;
; R_VECTORTBL_LOOKUP: Key Vector table lookup
;
; IN:
;	A		value to match
;	HL		vector table - 2. Code Based. 
;	C		max count
;
; OUT:
;	L		Cursor row
;	H		Cursor column
;
R_VECTORTBL_LOOKUP:						;entry point with different count and HL
    INX     H							;Skip entry handler address
    INX     H							;Skip handler address MSB
    DCR     C							;Decrement entry counter
    RM									;Return if entry not found in table
    CMP     M							;Test if this entry matches
    INX     H							;Skip the key value
    JNZ     R_VECTORTBL_LOOKUP			;If no match, jump to test next entry
	GETHLFROMM							;match: get Handler Address to HL
    PUSH    H							;Push the key handler address on stack
	LHLD	CSRY_R						;Cursor row (1-8) + column (1-40)
	RET									;"RETurn" to the key handler address
;
; RST 20H lookup table
;
R_RST_20H_LKUP_TBL:						;438AH
    DB   07H
    DW   R_BEEP_FUN
    DB   08H
    DW   R_BKSPACE_FUN
    DB   09H
    DW   R_TAB_FUN
    DB   0AH
    DW   R_LF_FUN
    DB   0BH
    DW   R_ESC_H_FUN
    DB   0CH
    DW   R_CLS_FUN
    DB   0DH
    DW   R_CR_FUN
    DB   1BH
    DW   L_STORE_ESC_SEQ
L_RST_20H_LKUP_END:
;
; Conditionally POP PSW from stack based on value at POPPSW_R
;
L_POPPSW:
    LDA     POPPSW_R
    ANA     A
    RZ									;Return if zero (No POP needed) 
    POP     PSW
    RET

L_UPD_LINPROT:
    LDA     LINPROT_R					;Label line protect status
    ADI		08H
    RET
;
; ESC Y routine (Set cursor position)
;
R_ESC_Y_FUN:								;43AFH
    MVI     A,02H
	SKIP_2BYTES_INST_BC					;skip SKIP_BYTE_INST and XRA A
;
; Store Escape Sequence
;
L_STORE_ESC_SEQ:						;43B2H
	SKIP_BYTE_INST						;Sets A to 0AFH
L_CLR_ESC_SEQ:							;clear ESC mode flag for OUTCHR (RST 20H)
    XRA     A
    STA		ESCRST20_R					;set ESCRST20_R
    RET
;
; LCD Escape sequence lookup table
; TODO ESC-I missing
;
R_LCD_ESC_LKUP_TBL:						;43B8H
    DB      'j'
    DW   	R_CLS_FUN
    DB      'E'
    DW   	R_CLS_FUN
    DB      'K'
    DW   	R_ESC_K_FUN
    DB      'J'
    DW   	R_ESC_CapJ_FUN
    DB      'l'
    DW   	R_ESC_l_FUN
    DB      'L'
    DW   	R_ESC_CapL_FUN
    DB      'M'
    DW   	R_ESC_M_FUN
    DB      'Y'
    DW   	R_ESC_Y_FUN
    DB      'A'
    DW   	R_ESC_A_FUN
    DB      'B'
    DW   	R_ESC_B_FUN
    DB      'C'
    DW   	R_ESC_C_FUN
    DB      'D'
    DW   	R_ESC_D_FUN
    DB      'H'
    DW   	R_ESC_H_FUN
    DB      'p'
    DW   	R_ESC_p_FUN
    DB      'q'
    DW   	R_ESC_q_FUN
    DB      'P'
    DW   	R_ESC_CapP_FUN
    DB      'Q'
    DW   	R_ESC_CapQ_FUN
    DB      'T'
    DW   	R_ESC_T_FUN
    DB      'U'
    DW   	R_ESC_U_FUN
    DB      'V'
    DW   	R_ESC_V_FUN
    DB      'W'
    DW   	R_ESC_W_FUN
    DB      'X'
    DW   	R_ESC_X_FUN
R_LCD_ESC_LKUP_END:
;
; ESCape sequence driver
;
; IN:
;	C
;	HL		ptr to ESCRST20_R
;
R_ESC_SEQ_DRIVER:						;43FAH
    MOV     A,C
    CPI     1BH							;ESC
    MOV     A,M							;ESC letter
    JZ      L_DBL_ESC_SEQ				;brif C == ESC: Double Escape
    ANA     A							;test ESC letter
    JP      L_ESC_SEQ_1					;brif A >= 0
    CALL    L_CLR_ESC_SEQ
    MOV     A,C
    LXI     H,R_LCD_ESC_LKUP_TBL-2		;Code Based. 
    MVI     C,(R_LCD_ESC_LKUP_END-R_LCD_ESC_LKUP_TBL)/3	;16H
    JMP     R_VECTORTBL_LOOKUP			;returns L==Cursor row

L_ESC_SEQ_1:
    DCR     A
    STA     ESCRST20_R					;ESC mode flag for OUTCHR (RST 20H)
    LDA     LINWDT_R					;Active columns count (1-40)
    LXI     D,CSRX_R				    ;Cursor column (1-40)
    JZ      +
    LDA     LINCNT_R					;Console height
    LXI     H,LINPROT_R				   	;Label line protect status
    ADD     M
    DCX     D
+	MOV     B,A
    MOV     A,C
    SUI     20H
    CMP     B
    INR     A
    STAX    D
    RC
    MOV     A,B
    STAX    D
    RET
;
; ESC p routine (start inverse video)
;
R_ESC_p_FUN:							;4431H
	SKIP_XRA_A							;ORI 0AFH
;
; ESC q routine (cancel inverse video)
;
R_ESC_q_FUN:							;4432H
    XRA     A
    STA     REVFLG_R					;Reverse video switch
    RET
;
; ESC U routine (unprotect line 8)
;
R_ESC_U_FUN:							;4437H
    XRA     A
	SKIP_2BYTES_INST_JNZ				;skip SKIP_BYTE_INST & 0FFH
;
; ESC T routine (protect line 8)
;
R_ESC_T_FUN:							;4439H
	SKIP_BYTE_INST						;Sets A to 0AFH
; RST38H instruction always skipped but A set based on Entry function R_ESC_U_FUN or R_ESC_T_FUN
	DB		0FFH						;RST38H
	STA		LINPROT_R					;0: not protected. !=0 protected
	RET
;
; ESC V routine (stop automatic scrolling)
;
R_ESC_V_FUN:							;443FH
	SKIP_XRA_A							;ORI 0AFH
;
; ESC W routine (resume automatic scrolling)
;
R_ESC_W_FUN:							;4440H
    XRA     A
    STA     SCRLDIS_R					;Scroll disable flag
    RET
;
; IN:
;	HL		ptr to ESCRST20_R
;
L_DBL_ESC_SEQ:
    INX     H							;ptr to ESCRST20_R+1
    MOV     M,A							;save code
    JMP     L_STORE_ESC_SEQ
;
; ESC X routine
;
R_ESC_X_FUN:
    LXI     H,ESCRST20_R+1				;Double ESC mode flag for OUTCHR (RST 20H)
    MOV     A,M							;get code
    MVI		M,00H						;clear code
    DCX     H							;point to ESCRST20_R
    MOV     M,A							;store code
    RET
;
; ESC C routine (move cursor right)
;
R_ESC_C_FUN:							;4453H
    LDA     LINWDT_R					;Active columns count (1-40)
    CMP     H
    RZ
    INR     H
    JMP     L_ESC_B_1
;
; ESC D routine (move cursor left)
;
R_ESC_D_FUN:							;445CH
    DCR     H
    RZ
    JMP     L_ESC_B_1
;
; Backspace routine
;
R_BKSPACE_FUN:							;4461H
    CALL    R_ESC_D_FUN				    ;ESC D routine (move cursor left)
    RNZ
    LDA     LINWDT_R					;Active columns count (1-40)
    MOV     H,A
;
; ESC A routine (move cursor up)
;
R_ESC_A_FUN:							;4469H
    DCR     L
    RZ
    JMP     L_ESC_B_1
;
; ESC B routine (move cursor down)
;
R_ESC_B_FUN:							;446EH
    CALL    L_GET_LCD_ROWS				;Get # of LCD rows based on label protect, preserve flags
    CMP     L
    RZ
    JC      +
    INR     L
L_ESC_B_1:
    SHLD    CSRY_R						;Cursor row (1-8) + column (1-40)
    RET

+	DCR     L
    XRA     A
    JMP     L_ESC_B_1
;
; Tab routine
;
R_TAB_FUN:								;4480H
    LDA     CSRX_R						;Cursor column (1-40)
    PUSH    PSW
    MVI     A,' '
    OUTCHR								;Send character in A to screen/printer
    POP     B
    LDA     CSRX_R						;Cursor column (1-40)
    CMP     B
    RZ
    DCR     A
    ANI     07H
    JNZ     R_TAB_FUN				    ;Loop
    RET
;
; Linefeed routine
;
R_LF_FUN:								;4494H
    CALL    R_ESC_B_FUN				    ;ESC B routine (move cursor down)
    RNZ
    LDA     SCRLDIS_R					;Scroll disable flag
    ANA     A
    RNZ									;retif Scroll disable flag != 0
    CALL    L_ESC_B_1
    CALL    L_SCROLL_LCD
    MVI     L,01H						;
    JMP     L_ESC_M_1
;
; Verticle tab and ESC H routine (home cursor)
;
R_ESC_H_FUN:							;44A8H
    MVI     L,01H
;
; CR routine
;
R_CR_FUN:								;44AAH
    MVI     H,01H
    JMP     L_ESC_B_1
;
; ESC P routine (turn cursor on)
;
R_ESC_CapP_FUN:							;44AFH
    MVI     A,01H
    STA     CURSTAT_R				    ;Cursor status (0 = off)
    CALL    L_POPPSW					;Conditionally POP PSW from stack based on value at POPPSW_R
    JMP     L_INIT_CRS_BLINK			;Initialize Cursor Blink to start blinking
;
; ESC Q routine (turn cursor off)
;
R_ESC_CapQ_FUN:							;44BAH
    XRA     A
    STA     CURSTAT_R					;Cursor status (0 = off)
    CALL    L_POPPSW					;Conditionally POP PSW from stack based on value at POPPSW_R
    JMP     L_BLINK_LCD					;Turn off background task, blink & reinitialize cursor blink time
;
; ESC M routine
;
R_ESC_M_FUN:							;44C4H
    CALL    R_CR_FUN				    ;CR routine
L_ESC_M_1:
    CALL    L_POPPSW					;Conditionally POP PSW from stack based on value at POPPSW_R
    CALL    L_UPD_LINPROT				;result in A
    SUB     L
    RC									;retif A < L
	if		HWSCROLL
;	•	Hardware scroll condition is detected
;	•	Scroll active flag is set
;	•	hardware scroll for top and bottom drivers at the same time
;	•	return to R_LCD_SCROLL (44D2H) routine
	call	TRAP_M
	else
    JZ      R_ESC_l_FUN					;ESC l routine (erase current line)
	endif
;
;Scroll LCD screen A times at line number in L
;
; IN:
;	A		# of scrolls
;	L		starting line number
;
R_LCD_SCROLL:							;44D2H
    PUSH    PSW							;save A: #of scrolls
    MVI     H,MAXCHRCOLUMN				;40	line count
-	INR     L							;next line
    CALL    R_GET_LCD_CHAR				;Get character at HL from LCD RAM in C, RevVid status in A
    DCR     L							;back to previous line
    CALL    R_CHAR_PLOT_6a				;draw char in C
    DCR     H							;count
    JNZ     -
    INR     L							;next line
    POP     PSW							;restore #of scrolls
    DCR     A							;update #of scrolls
    JNZ     R_LCD_SCROLL				;Loop until done
; A now 0
	if		HWSCROLL
;	•	here, the return from software scrolling is intercepted
;	•	scroll active flag is disabled here
	JMP		RET_M
	else
    JMP     R_ESC_l_FUN				 	;ESC l routine (erase current line)
	endif
;
; ESC L routine (insert line)
;
R_ESC_CapL_FUN:							;44EAH
    CALL    R_CR_FUN				    ;CR routine
    CALL    L_POPPSW					;Conditionally POP PSW from stack based on value at POPPSW_R
    CALL    L_UPD_LINPROT				;result in A
    MOV     H,A							;save
    SUB     L							;sets Z flag and carry
    RC									;retif H < L
	if		HWSCROLL
;	•	Hardware scroll condition is detected
;	•	Scroll active flag is set
;	•	hardware scroll for top and bottom drivers at the same time
;	•	return to 44EAH routine
;	.	A holds # of scrolls
;	.	L == the line number to process first
	call	TRAP_L
	else
    JZ      R_ESC_l_FUN				    ;brif H == L: ESC l routine (erase current line)
	endif
    MOV     L,H
; IN:
;	A		# of scrolls
;	L		starting line number
R_LCD_SCROLL_DOWN:						;44FAH @STEVEADOLPH
    PUSH    PSW							;save # of scrolls
    MVI     H,MAXCHRCOLUMN				;40 column loop counter
-	DCR     L							;previous line
    CALL    R_GET_LCD_CHAR				;Get character at HL from LCD RAM to C
    INR     L							;backup to original line
    CALL    R_CHAR_PLOT_6a				;draw char in C
    DCR     H
    JNZ     -
    DCR     L							;previous line
    POP     PSW							;restore # of scrolls
    DCR     A
    JNZ     R_LCD_SCROLL_DOWN

	if		HWSCROLL
;	•	Hardware scroll condition is detected
;	•	Scroll active flag is set
;	•	hardware scroll for top and bottom drivers at the same time
;	•	return to R_ESC_CapL_FUN routine
	JMP		RET_L
	else
    JMP     R_ESC_l_FUN				    ;ESC l routine (erase current line)
	endif
;
; Get character at HL from LCD RAM
;
; IN:
;	HL		H: column (base 1) L: row (base 1)
; OUT:
;	A		RevVid Status
;	C		char
;
R_GET_LCD_CHAR:							;4512H
    PUSH    H							;save row/column
    PUSH    H							;again
    CALL    L_LCD_LOC					;compute ptr to LCD_R
    MOV     C,M							;get char
    POP     H							;restore row/column
    CALL    L_LCD_REV_LOC				;LCD Reverse Video bitmap locator
    ANA     M							;A & [HL]
    POP     H							;restore row/column
    RET

L_DISP_BKSP:
    LDA     REVFLG_R					;Reverse video flag state
    PUSH    PSW							;save it
    CALL    R_INV_CHAR_DISABLE       	;Cancel inverse character mode
    MVI     A,08H						;BKSP
    OUTCHR								;Send character in A to screen/printer
    MVI     A,' '
    OUTCHR								;Send character in A to screen/printer
    MVI     A,08H						;BKSP
    OUTCHR								;Send character in A to screen/printer
    POP     PSW							;restore reverse video flag state
    ANA     A							;test it
    RZ									;retif not reverse video
    JMP     R_INV_CHAR_ENABLE			;Set inverse character mode and return
;
; ESC l routine (erase current line)
;
; in
;	L		Line number
;
R_ESC_l_FUN:							;4535H
    MVI     H,01H						;column number
;
; ESC K routine (erase to EOL)
;
; in
;	L		Line number
;	H		column to start
;
R_ESC_K_FUN:							;4537H
    CALL    L_POPPSW					;Conditionally POP PSW from stack based on value at POPPSW_R
-	MVI     C,' '
    XRA     A							;no RevVid
    CALL    R_CHAR_PLOT_6a				;draw char in C
    INR     H							;next column
    MOV     A,H
    CPI     MAXCHRCOLUMN+1				;41	column overflow
    JC      -
    RET
;
; Form Feed (0CH)), CLS), ESC E), and ESC J routine
;
R_CLS_FUN:								;4548H
    CALL    R_ESC_H_FUN				    ;Verticle tab and ESC H routine (home cursor)
    CALL    L_CLR_ALTLCD
;
; ESC J routine: erase to end of page
;
; IN:
;	H
;	L
;
R_ESC_CapJ_FUN:							;454EH
    CALL    L_POPPSW
-	CALL    R_ESC_K_FUN				    ;ESC K routine (erase to EOL)
    CALL    L_UPD_LINPROT				;result in A
    CMP     L
    RC									;retif A < L
    RZ									;retif A == L
    MVI     H,01H
    INR     L
    JMP     -

;
; Character plotting level 6.  Save character in C to LCD RAM & call level 7
;
; IN:
;	HL		LCD char coordinates
;	A		Reverse Video status
;	C		char
;
R_CHAR_PLOT_6:							;4560H
    CALL    L_POPPSW					;Conditionally POP PSW from stack based on value at FAC7H
    LDA     REVFLG_R					;Reverse video switch
R_CHAR_PLOT_6a:							;draw char in C
    PUSH    H
    PUSH    PSW							;save Reverse Video status
    PUSH    H
    PUSH    H							;save LCD char coordinates
    CALL    L_LCD_REV_UPD				;input A
    POP     H							;restore LCD char coordinates
    CALL    L_LCD_LOC					;compute ptr to LCD_R
    MOV     M,C							;update LCD_R
    POP     D							;restore LCD char coordinates to DE
	if		HWSCROLL
;	•	here the scroll active flag is tested
;	•	if a scroll is active then we look for the special condition where the line being “software scrolled” is occurring
;	•	when this happens, we actually employ the routine at R_CHAR_PLOT_7 (73EEH) to copy the new line into the LCD drivers,
;	•	the source being Video RAM.	if scroll is not active, then carry on to R_CHAR_PLOT_7
	CALL	stop_access
	else
    CALL    R_CHAR_PLOT_7				;Character plotting level 7.  Plot character in C on LCD at (HL)
	endif
    POP     PSW							;restore Reverse Video status
    ANA     A							;set flags
    POP     H
    RZ									;retif !Reverse Video
    DI 
    MVI     A,0DH						;00001101 MSE==1 Unmask 6.5. Mask INT 7.5 & 5.5
    SIM    
    EI     
    CALL    R_BLINK_CURSOR				;Blink the cursor
; TODO save a byte by jumping to L_ENA_INT_75_65()
    MVI     A,09H						;00001001 MSE==1 Unmask 7.5 & 6.5. Mask INT 5.5
    SIM    
    RET
;
; Compute ptr to LCD_R
; IN:
;	H: column L: row base 1
; compute (40 * (row - 1)) + Column - overflow (-100 or 0) + LCD_R + 255
; each row is 40 columns, range 1..8.
; L is 1 based so there is a -40 correction in the calculation
; H is also 1 based so another -1 correction
;
L_LCD_LOC:
    MOV     A,L
    ADD     A							;*2
    ADD     A							;*4
    ADD     L							;*5
    ADD     A							;*10
    ADD     A							;*20
    ADD     A							;*40	Carry!
    MOV     E,A
;
; make D == -1 if no overflow, D == 0 if overflow
;
    SBB     A							;if Carry, result is 0FFH
    CMA									;complement to 0 else 0FFH
    MOV     D,A							;E now 40*Row, D is 0 or -1
    MOV     L,H							;zero extend H to HL
    MVI     H,00H
    DAD     D							;HL += DE. Tricky binary math.
    LXI     D,LCD_R+0D7H				;LCD_R+215 = LCD_R + 256 - 40 - 1
    DAD     D
    RET
;
; Update LCD char bitmap
; this bitmap reflects the Reverse Video state of each char shown on the LCD
; 40 char per line, 8 lines, total 320 bits
;
; IN:
;	A		set or reset
;	HL		Column & Row
;
L_LCD_REV_UPD:
    MOV     B,A
    CALL    L_LCD_REV_LOC				;LCD Reverse Video bitmap locator
    INR     B							;test B for 0
    DCR     B
    JZ      +							;L_LCDBITS_CLEAR brif B == 0
;L_LCDBITS_SET:
    ORA     M							;[HL] |= A
    MOV     M,A
    RET
;L_LCDBITS_CLEAR:
+	CMA									;complement bit mask
    ANA     M							;[HL] &= ~A
    MOV     M,A
    RET
;
; LCD characters Reverese Video bitmap locator
;
; IN:
;	H: Column (1 based), L: Row (1 based)
; OUT:
;	HL returns ((Column - 1) / 8) + ((Row - 1) * 5) + LCDBITS_R
;	A		bitmask for M
;
; LCDBITS_R reflects the Reverse Video status of each char
;
L_LCD_REV_LOC:
    MOV     A,L							;row (1 based)
    ADD     A							;*2
    ADD     A							;*4
    ADD     L							;*5
    MOV     L,A
    MOV     A,H							;column
    DCR     A
    PUSH    PSW							;save Column - 1
    RRC									;divide by 8
    RRC
    RRC
    ANI     1FH							;00011111B
    ADD     L							;+ row
    MOV     L,A							;zero extend to HL
    MVI     H,00H
    LXI     D,LCDBITS_R-5				;LCD table. Offset by 5 since Row is 1 based.
    DAD     D							;index. result in HL
    POP     PSW							;restore Column - 1
    ANI     07H							;mod 8
    MOV     D,A							;loop count
    XRA     A							;A == 0
    STC									;set Carry
;create a bit mask
-	RAR									;rotate carry into bit 7 
    DCR     D
    JP      -
    RET

L_FLIP_REV:
    PUSH    H							;save HL
    CALL    L_LCD_REV_LOC				;LCD Reverse Video bitmap locator
    XRA     M							;[HL] ~= A
    MOV     M,A
    POP     H							;restore HL
    RET

L_CLR_ALTLCD:
    CALL    L_POPPSW					;Conditionally POP PSW from stack based on value at POPPSW_R
    LDA     FNKMOD_R					;Function key mode/ BIT 7=in TEXT (0x80); BIT 6=in TELCOM (0x40)
    ADD     A							;move bit 6 to sign bit
    RP  								;retif TEXT
;
; TELCOM app
;
    PUSH    H							;save HL
;
; clear ALTLCD screen buffer
;
    LXI     H,ALTLCD_R				    ;Start of Alt LCD character buffer
    LXI     B,MAXCHRCOLUMN*MAXCHRROW	;0140H/320 ALTLCD buffer counter
-	MVI     M,' '						;set space
    INX     H
    DCX     B							;decrement loop counter
    MOV     A,B							;test loop counter
    ORA     C
    JNZ     -							;brif not done
    POP     H							;restore HL
    RET

L_SCROLL_LCD:
    CALL    L_POPPSW
    LDA     FNKMOD_R					;Function key mode/ BIT 7=in TEXT (0x80); BIT 6=in TELCOM (0x40)
    ADD     A							;double
    RP									;return if !TEXT
; scroll and copies first line of LCD_R too
    LXI     D,ALTLCD_R				    ;Start of Alt LCD character buffer
    LXI     H,ALTLCD_R+MAXCHRCOLUMN		;+28H
    LXI     B,MAXCHRCOLUMN*MAXCHRROW	;0140H/320
    JMP     R_MOVE_BC_BYTES_INC      	;Move BC bytes from M to (DE) with increment
;
; LCDrefresh -- Refresh LCD from LCD_R
;
L_LCDrefresh:
    CALL    L_BLINK_LCD					;Turn off background task, blink & reinitialize cursor blink time
L_LCDrefresh_0:							;used by VT100inROM
    MVI     L,01H						;row loop counter
L_LCDrefresh_1:
    MVI     H,01H						;Column loop counter
-	CALL    R_GET_LCD_CHAR				;Get character at HL from LCD RAM in C, Rev Vid status in A
    CALL    R_CHAR_PLOT_6a				;draw char in C
    INR     H							;next column
    MOV     A,H
    CPI     MAXCHRCOLUMN+1				;41	;Columns 1..40
    JNZ     -
    INR     L							;next row
    MOV     A,L
    CPI     MAXCHRROW+1					;09H rows 1..8
    JNZ     L_LCDrefresh_1
    JMP     L_CHAR_PLOT_4_1

L_ALTLCDrefresh:
    LXI     H,ALTLCD_R				    ;Start of Alt LCD character buffer
    MVI     E,01H						;row 1..8
L_ALTLCDrefresh_1:
    MVI     D,01H						;column 1..40
-	PUSH    H							;save HL, DE
    PUSH    D
    MOV     C,M							;load character from ALTLCD_R
    CALL    R_CHAR_PLOT_7				;Character plotting level 7: Plot character in C on LCD at (HL)
    POP     D							;restore DE, HL
    POP     H
    INX     H							;next
    INR     D							;next column
    MOV     A,D
    CPI     MAXCHRCOLUMN+1				;Column Overflow
    JNZ     -
    INR     E							;next row
    MOV     A,E
    CPI     MAXCHRROW+1					;Row overflow
    JNZ     L_ALTLCDrefresh_1
    RET
;
; Input and display line and store
;
R_INP_DISP_LINE:						;463EH
    MVI     A,'?'
    OUTCHR								;Send character in A to screen/printer
    MVI     A,' '
    OUTCHR								;Send character in A to screen/printer
;
; Input and display (no "?") line and store
;
R_INP_DISP_LINE_NO_Q:					;4644H
    CALL    L_TST_FCBLAST
    JNZ     L_INP_FILE					;brif FCBLAST != 0
    LDA     CSRX_R						;Cursor column (1-40)
    STA     CSRXSVD_R					;saved Cursor column
    LXI     D,INPBUF_R				    ;Keyboard buffer
    MVI     B,01H
;
; Continuation function magic here
;
L_INP_LINE_1:
    CALL    R_WAIT_KEY				    ;Blocking wait for key from keyboard
    LXI     H,L_INP_LINE_1				;push address continuation function
    PUSH    H
    RC									;brif no key, keep checking
;
; L_INP_LINE_1 now on the stack. A return will continue reading chars
;
    CPI     7FH							;DEL key
    JZ      R_INP_BKSP_HANDLER       	;Input routine backspace), left arrow), CTRL-H handler
    CPI     ' '
    JNC     R_INP_HANDLER				;brif A >= ' '
	LXI		H,R_KEY_VECTOR_LKUP_TBL-2	;Code Based. Load pointer to key vector table
	MVI		C,07H						;Seven entries in table
	JMP		R_VECTORTBL_LOOKUP			;Key Vector table lookup
;
R_KEY_VECTOR_LKUP_TBL:
    DB      03H
    DW		R_INP_CTRL_C_HANDLER
    DB      08H
    DW		R_INP_BKSP_HANDLER
    DB      09H
    DW		R_INP_TAB_HANDLER
    DB      0DH
    DW		R_INP_ENTER_HANDLER
    DB      15H
    DW		R_INP_CTRL_U_HANDLER
    DB      18H
    DW		R_INP_CTRL_U_HANDLER
    DB      1DH
    DW		R_INP_BKSP_HANDLER
;
; Input routine Control-C handler
;
R_INP_CTRL_C_HANDLER:				    ;4684H
    POP     H							;remove continue checking return address
    MVI     A,'^'
    OUTCHR								;Send character in A to screen/printer
    MVI     A,'C'
    OUTCHR								;Send character in A to screen/printer
    CALL    R_SEND_CRLF				    ;Send CRLF to screen or printer
    LXI     H,INPBUF_R				    ;Keyboard buffer
    MVI     M,00H
    DCX     H
    STC
    RET
;
; Input routine ENTER handler
;
; IN:
;	DE		current Buffer ptr
;
; OUT:
;	HL		start Buffer ptr - 1
;
R_INP_ENTER_HANDLER:				  	;4696H
    POP     H							;remove continue checking return address
    CALL    R_SEND_CRLF				  	;Send CRLF to screen or printer
    XRA     A							;terminate buffer
    STAX    D
    LXI     H,INPBUF_R-1				;Keyboard buffer
    RET
;
; Input routine backspace), left arrow), CTRL-H handler
;
R_INP_BKSP_HANDLER:						;46A0H
    MOV     A,B							;buffer counter
    DCR     A							;backup
    STC									;set carry
    RZ									;retif now empty
    DCR     B							;backup counter
    DCX     D							;backup buffer ptr
    CALL    L_INP_DO_BKSP				;returns value in A
-	PUSH    PSW							;save A
    MVI     A,7FH						;DEL
    OUTCHR								;Send character in A to screen/printer
    LHLD    CSRY_R						;Cursor row (1-8) + column (1-40)
    DCR     L							;decrement both
    DCR     H
    MOV     A,H
    ORA     L
    JZ      +							;brif row & column are 0
    LXI     H,CSRX_R				  	;Cursor column (1-40)
    POP     PSW							;restore A
    CMP     M
    JNZ     -
    RET

+	POP     PSW							;cleanup stack
    STC
    RET
;
; Input routine CTRL-U & X handler
;
R_INP_CTRL_U_HANDLER:				  	;46C3H
    CALL    R_INP_BKSP_HANDLER         	;Input routine backspace), left arrow), CTRL-H handler
    JNC     R_INP_CTRL_U_HANDLER       	;Input routine CTRL-U & X handler
    RET
;
; Input routine Tab handler
;
R_INP_TAB_HANDLER:						;46CAH
    MVI     A,09H
;
; Input routine handler
;
; IN:
;	A		key char
;	B		buffer count (0..255)
;	DE		buffer ptr
;
R_INP_HANDLER:
    INR     B
    JZ      +							;brif count overflow (256)
    OUTCHR								;Send character in A to screen/printer
    STAX    D							;store in buffer
    INX     D							;next buffer ptr
    RET
;
; keyboard buffer Overflow
;
; IN:
;	B		0
;
+	DCR     B							;undo previous increment
    JMP     R_BEEP_STMT				    ;BEEP and return
;
; backspace
;
; IN:
;	B		keyboard buffer counter
;
L_INP_DO_BKSP:
    PUSH    B
    LDA     CSRXSVD_R					;saved Cursor column
    DCR     B
    JZ      L_INP_DO_BKSP_1				;brif buffer counter == 0
    MOV     C,A							;saved CSRX_R
    LXI     H,INPBUF_R					;Keyboard buffer ptr
-	INR     C
    MOV     A,M
    CPI     09H							;TAB
    JNZ     +
; key is TAB
    MOV     A,C
    DCR     A
    ANI     07H							;mod 8
    JNZ     -							;brif result != 0
+	LDA     LINWDT_R					;Active columns count (1-40)
    CMP     C
    JNC     +							;brif LINWDT_R >= C
    MVI     C,01H
+	INX     H							;keyboard buffer ptr
    DCR     B							;keyboard buffer counter
    JNZ     -							;brif keyboard buffer counter != 0
    MOV     A,C
L_INP_DO_BKSP_1:
    POP     B
    RET

L_INP_FILE:
    LHLD    FCBLAST_R					;FCB ptr for the last file used (2 bytes)
    PUSH    H							;save FCB ptr
    INX     H							;to Device code in FCB
    INX     H
    INX     H
    INX     H
    MOV     A,M							;get device code
    SUI     RAM_DEV						;0F8H
    JNZ     +							;brif !RAM_DEV
;
; FCBLAST_R was RAM_DEV. A now 0
;
    MOV     L,A
    MOV     H,A
    SHLD    FCBLAST_R					;Clear FCB ptr for the last file used (2 bytes)
    LXI     H,DOFILPTR_R				;increment [DOFILPTR_R]
    INR     M
    MOV     A,M							;get it
    RRC									;bit 0 to carry
    CNC     R_INV_CHAR_ENABLE			;calif no carry: Start inverse character mode
    LXI     H,L_NEWLINE_MSG				;Code Based.
    CALL    R_PRINT_STRING				;Print buffer at M until NULL or '"'
    CALL    R_INV_CHAR_DISABLE         	;Cancel inverse character mode
+	POP     H							;restore FCB ptr
    SHLD    FCBLAST_R					;restore FCB ptr for the last file used (2 bytes)
    MVI     B,00H						;count 256
    LXI     H,INPBUF_R				  	;Keyboard buffer
-	XRA     A
    STA     FILNUM_R					;clear FILNUM_R (2 bytes)
    STA     FILNUM_R+1
    CALL    L_DEV_INPUT
    JC      L_INP_FILE_2				;brif error
    MOV     M,A
    CPI     0DH
    JZ      L_INP_FILE_1				;brif CR
    CPI     09H
    JZ      +							;brif TAB
    CPI     ' '
    JC      -							;brif < ' ': loop
;TAB
+	INX     H							;next buffer ptr
    DCR     B							;count
    JNZ     -							;brif B != 0
L_INP_FILE_1:								;CR
    XRA     A							;terminate buffer
    MOV     M,A
    LXI     H,INPBUF_R-1				;Keyboard buffer
    RET
L_INP_FILE_2:
    MOV     A,B							;count
    ANA     A							;test
    JNZ     L_INP_FILE_1				;brif B != 0
    LDA     OPNFIL_R
    ANI     80H							;set bit 7
    STA     OPNFIL_R
    CALL    L_CLS_FILE0					;close file 0 & Load LSTVAR_R
    MVI     A,0DH						;CR
    OUTCHR								;Send character in A to screen/printer
    CALL    R_ERASE_TO_EOL				;Erase from cursor to end of line
    LDA     EXCFLG_R
    ANA     A
    JZ      L_INP_FILE_3
    CALL    R_INIT_BASIC_VARS			;Initialize BASIC Variables for new execution
    JMP     L_NEWSTT					;Execute BASIC program

L_INP_FILE_3:
    LDA     EDITFLG_R
    ANA     A
    JNZ     L_EDIT_MODE_3
    JMP     R_POP_GO_BASIC_RDY         	;Pop stack and vector to BASIC ready

L_DIM_CONT_FUN:
    DCX     H							;backup text ptr
    CHRGET								;Get next non-white char from M
    RZ									;retif end of line
	SYNCHK	','
;
; DIM statement
;
R_DIM_STMT:								;478BH
    LXI     B,L_DIM_CONT_FUN			;continuation function
    PUSH    B
	SKIP_XRA_A							;ORI 0AFH. A != 0
;
; Find address of variable at M and store in DE
;
R_FIND_VAR_ADDR:						;4790H
    XRA     A
    STA     CRELOC_R					;set Variable Create/Locate switch: != 0 => DIM
    MOV     C,M							;first char of variable to C
    CALL    R_ISLET_M				  	;Check if M is alpha character
    JC      R_GEN_SN_ERROR				;brif not letter: Generate Syntax error
    XRA     A
    MOV     B,A							;clear A
    CHRGET								;Get next non-white char from M. Carry set means numeric.
    JC      +							;brif numeric
    CALL    R_ISLET					  	;Check if A is alpha character
    JC      L_FIND_ADDR_1				;brif not letter
+	MOV     B,A							;save second char of variable
-	CHRGET								;Get next non-white char from M
    JC      -							;brif numeric: skip
    CALL    R_ISLET				  		;Check if A is alpha character
    JNC     -							;brif letter: skip
L_FIND_ADDR_1:
    CPI     '&'							;26H
    JNC     +							;brif char >= '&'
    LXI     D,L_FIND_ADDR_2				;continuation function
    PUSH    D
    MVI     D,02H						;preset type to integer
    CPI     '%'							;25H
    RZ									;to continuation function
    INR     D							;preset type to STRING
    CPI     '$'
    RZ									;to continuation function
    INR     D							;preset type to SNGL
    CPI     '!'
    RZ 									;to continuation function
    MVI     D,08H						;preset type to DBL
    CPI     '#'
    RZ									;to continuation function     
    POP     PSW							;remove continuation function
+	MOV     A,C							;first character
    ANI     7FH							;01111111
    MOV     E,A							;zero extend char to DE
    MVI     D,00H
    PUSH    H							;save text ptr
    LXI     H,DEFTBL_R-41H				;DEFTBL_R start - 'A'
    DAD     D							;index
    MOV     D,M							;get default type
    POP     H							;restore text ptr
    DCX     H							;backup
; Continuation function
L_FIND_ADDR_2:
    MOV     A,D							;get type
    STA     VALTYP_R					;Store Type of last expression used
    CHRGET								;Get next non-white char from M
    LDA     SUBFLG_R					;DONT RECOGNIZE SUBSCRIPTED VARIABLES flag
    DCR     A							;test
    JZ      L_NO_SUBSCRIPT				;brif SUBFLG_R==1
    JP      +							;brif SUBFLG_R > 1
    MOV     A,M							;next char
    SUI     '('							;28H
    JZ      L_SUBSCRIPT					;brif subscript
    SUI     '['-'('						;33H
    JZ      L_SUBSCRIPT					;brif subscript
; no subscript
+	XRA     A
    STA     SUBFLG_R					;clear DONT RECOGNIZE SUBSCRIPTED VARIABLES flag
    PUSH    H							;save text ptr
    LHLD    VARTAB_R					;Start of variable data pointer
    JMP     L_FIND_ADDR_4				;start search at end of variables test
;
; DE points to Variable Descriptors
; BC has first 2 chars of variable
; Text Ptr on Stack
;
L_FIND_ADDR_3:
    LDAX    D							;get 2 bytes from *DE++ into L & A
    MOV     L,A							;get type into L
    INX     D
    LDAX    D							;get first char into A
    INX     D
    CMP     C							;compare first char
    JNZ     +							;brif chars don't match
    LDA     VALTYP_R					;Type of last expression used
    CMP     L
    JNZ     +							;brif types don't match
    LDAX    D							;get second char *DE
    CMP     B
    JZ      L_FIND_ADDR_9				;brif chars and type match
+	INX     D							;next
    MVI     H,00H						;zero extend type to HL
    DAD     D							;point to next variable descriptor
; Entry point
; HL = variable descriptor ptr
; Check for end of variable descriptors table
L_FIND_ADDR_4:
    XCHG								;next variable descriptor ptr to DE
    LDA     ARYTAB_R					;array table pointer
    CMP     E
    JNZ     L_FIND_ADDR_3				;brif different: loop
    LDA     ARYTAB_R+1					;0FBB5H
    CMP     D
    JNZ     L_FIND_ADDR_3				;brif different: loop
    JMP     L_FIND_ADDR_8				;next variable descriptor ptr == *ARYTAB_R

L_FIND_ADDR_5:
    CALL    R_FIND_VAR_ADDR				;Find address of variable at M and store in DE
L_FIND_ADDR_6:
    RET
;
; HL holds continuation address L_FIND_ADDR_6:
;	R_FIND_VAR_ADDR() called from L_FIND_ADDR_5
; 2 items on stack
; A == 0
;
; OUT:
;	DE		ptr to Variable Descriptor
;
L_FIND_ADDR_7:
    MOV     D,A							;Clear DE: no variable descriptor ptr
    MOV     E,A
    POP     B							;remove saved DE				
    XTHL								;Text Ptr to HL, L_FIND_ADDR_6 on stack
    RET									;to L_FIND_ADDR_6
;
; variable not found. Add new Variable Descriptor
; DE is [ARYTAB_R]
; JMPed to, not called.
; Text Ptr on Stack
;
L_FIND_ADDR_8:
; get value under TOS (return address) to HL
    POP     H							;restore Txt Ptr
    XTHL								;Txt Ptr to stack. Return address to HL
    PUSH    D							;save [ARYTAB_R]
; did we come from L_FIND_ADDR_5?
    LXI     D,L_FIND_ADDR_6				;"RET" code at L_FIND_ADDR_5 call
    COMPAR								;HL - DE
    JZ      L_FIND_ADDR_7				;brif match. A == 0
; did we come from R_ISVAR?
    LXI     D,L_ISVAR_1					;return address if called from R_ISVAR()
    COMPAR								;HL - DE
    POP     D							;restore [ARYTAB_R]
    JZ      L_CLEAR_FAC1				;brif called from R_ISVAR(). A==0
    XTHL								;swap HL and [SP]		
    PUSH    H							;push previous [SP]
    PUSH    B
    LDA     VALTYP_R					;Type of last expression used
    MOV     C,A							;type to C
    PUSH    B							;save BC
    MVI     B,00H						;zero extend C to BC
    INX     B							;BC += 3: size of variable descriptor
    INX     B
    INX     B
    LHLD    STRGEND_R					;Unused memory pointer
    PUSH    H							;save Unused memory pointer
    DAD     B							;add TYPE+3 (size, 2 chars, type) to Unused memory pointer
    POP     B							;restore BC
    PUSH    H							;save new Unused memory pointer
    CALL    L_CPY_BC_TO_HL_CHK			;Copy data from BC to HL down until BC == DE w/ check
    POP     H							;restore new Unused memory pointer
    SHLD    STRGEND_R					;update Unused memory pointer
    MOV     H,B							;HL = BC
    MOV     L,C
    SHLD    ARYTAB_R					;New ptr to Start of array table
;
; HL is ptr beyond Variable descriptor
; DE is ptr to Variable descriptor
; Clear Variable descriptor
; Variable type and name on stack
;
-	DCX     H
    MVI     M,00H
    COMPAR								;HL - DE
    JNZ     -
; HL now points to new Variable Desciptor
    POP     D							;restore Type
    MOV     M,E							;store E at M: Type
    INX     H
    POP     D							;restore Name
    MOV     M,E							;store DE at M: variable name
    INX     H
    MOV     M,D
    XCHG		
L_FIND_ADDR_9:							;tail merging
    INX     D							;point to Variable Value
    POP     H							;restore text ptr
    RET
;
; HL holds intercepted return address L_ISVAR_1
; 1 item on stack
; A == 0
; R_FIND_VAR_ADDR() called from R_ISVAR()
;
L_CLEAR_FAC1:
    STA     DFACLO_R					;Clear FAC1
    MOV     H,A							;Clear HL
    MOV     L,A
    SHLD    IFACLO_R					;Clear FAC1 for integers
    LSTTYP								;Determine type of last var used: C Clr = DBL P Clr = SNGL Z Set = String S: Set = Integer
    JNZ     +							;brif !STRING type
    LXI     H,R_NULL_MSG				;Code Based. 
    SHLD    IFACLO_R					;FAC1 for integers
+	POP     H							;restore text ptr
    RET
;
; subscript found
;
; IN:
;	A		== 0
;
L_SUBSCRIPT:
    PUSH    H							;save text ptr
; CRELOC_R != 0 => DIM
    LHLD    CRELOC_R					;Variable Create/Locate switch (L) + VALTYP_R (H)
    XTHL								;swap text ptr and just loaded HL
    MOV     D,A							;subscripts counter
; push subscript values on the stack
L_MULTIDIM:								;multi-dimensional loop start
    PUSH    D							;save count
    PUSH    B							;save BC
    CALL    L_EVAL_POS_EXPR_PREINC		;get char & Evaluate positive expression at M-1 to DE
    POP     B							;restore BC
    POP     PSW							;restore count from DE to A
    XCHG								;expression result to HL, txt ptr to DE
    XTHL								;swap [SP] & HL
    PUSH    H							;Variable Create/Locate switch (L) + VALTYP_R (H)
    XCHG								;txt ptr back to HL
    INR     A							;increment subscripts count
    MOV     D,A							;store in D
    MOV     A,M							;next char
    CPI     ','
    JZ      L_MULTIDIM					;brif multi-dimensional
    CPI     ')'
    JZ      +							;brif end of subscripts found
    CPI     ']'
    JNZ     R_GEN_SN_ERROR				;Generate Syntax error
;
; D contains subscripts counter. subscript expressions on stack
; above Variable Create/Locate switch (L) + VALTYP_R (H)
;
+	CHRGET								;Get next non-white char from M
    SHLD    TEMP2_R					;save txt ptr
    POP     H							;Variable Create/Locate switch (L) + VALTYP_R (H)
    SHLD    CRELOC_R					;store it. TODO Apparently CRELOC_R could change
    MVI     E,00H						;zero extend subscripts counter
    PUSH    D							;save subscripts count
	SKIP_2BYTES_INST_DE					;skip PUSH H & PUSH PSW
;
; No subscript allowed entry point (DONT RECOGNIZE SUBSCRIPTED VARIABLES == 1)
;
L_NO_SUBSCRIPT:
    PUSH    H							;txt ptr
    PUSH    PSW
    LHLD    ARYTAB_R					;ptr to Start of array table
	SKIP_BYTE_INST						;Sets A to 0AFH. Skip DAD D first time through loop
L_SUBSCRIPT_1:
    DAD     D							;index ARYTAB ptr + 
    XCHG
    LHLD    STRGEND_R					;load Unused memory pointer to DE
    XCHG
    COMPAR								;Compare Unused memory pointer and ARYTAB ptr: HL - DE
    JZ      L_SUBSCRIPT_2				;brif ARYTAB ptr == Unused memory pointer: no Arrays yet
; Add to array space
    MOV     E,M							;get VALTYP_R to E
    INX     H							;next
    MOV     A,M							;get first letter name to A
    INX     H							;to second letter
    CMP     C							;first letter existing array and new array match?
    JNZ     +							;brif A != C
    LDA     VALTYP_R					;Type of last expression used
    CMP     E							;compare with VARTAB_R of existing array
    JNZ     +							;brif VALTYP_R != E
    MOV     A,M							;get second letter existing variable to A
    CMP     B							;second letter existing array and new array match?
+	INX     H							;next
	GETDEFROMM							;get extended size. flags unaffected. Used to find next array
    JNZ     L_SUBSCRIPT_1				;brif second letter does not match: check next array
; names and type match. Invalid if declaring an array (DIM)
    LDA     CRELOC_R					;Variable Create/Locate switch
    ORA     A
    JNZ     R_GEN_DD_ERROR				;brif switch set: Generate Double dimensioned array error
    POP     PSW							;subscripts count current variable
    MOV     B,H							;BC = HL
    MOV     C,L
    JZ      L_POP_HL					;brif Z: POP txt ptr & return
    SUB     M							;subscripts count existing variable
    JZ      L_SUBSCRIPT_5				;brif A - subscripts count == 0
L_GEN_ERR_9:
    LXI     D,0009H
    JMP     R_GEN_ERR_IN_E				;Generate error 9
;
; Add an array variable. subscripts count on stack
;
; HL == ARYTAB ptr, DE == Unused memory pointer
;
; Layout:	VALTYP_R			1 byte
;			variable name		2 bytes
;			size + 1 + 2 count	2 bytes. Helps finding end of array variable
;			subscripts count	1 byte
;			dimension			2 bytes:  subscripts count times
;			data				type size * dimension 1 * dimension 2...
;
L_SUBSCRIPT_2:
    LDA     VALTYP_R					;Type of last expression used
    MOV     M,A							;store				
    INX     H							;next
    MOV     E,A							;sign extend VALTYP_R to DE: size of each entry
    MVI     D,00H
    POP     PSW							;subscripts count count. TODO no flags!
    JZ      R_GEN_FC_ERROR				;Generate FC error
    MOV     M,C							;store variable name
    INX     H
    MOV     M,B
    INX     H
    MOV     C,A							;save subscripts count
    CALL    R_GETSTK					;Test for C units free in stack space
    INX     H							;reserve 2 bytes
    INX     H
    SHLD    TEMP3_R						;save ARYTAB ptr
    MOV     M,C							;store subscripts count
    INX     H							;next
    LDA     CRELOC_R					;Variable Create/Locate switch
    RAL									;Bit 7 to carry. Preserve during next loop.
    MOV     A,C							;loop count
L_SUBSCRIPT_3:
    LXI     B,000BH						;preset 11: default array size
    JNC     +							;brif CRELOC_R was 0: no dimensions on stack
    POP     B							;dimension on stack
    INX     B							;actual range is 1 larger
+	MOV     M,C							;store dimension
    PUSH    PSW							;save loop counter
    INX     H
    MOV     M,B
    INX     H
    CALL    L_INT16_MUL					;multiply DE (ACCUMULATED entry size) and BC to DE
; DE is now accumulated array size
    POP     PSW							;restore loop counter
    DCR     A							;count. carry unaffected
    JNZ     L_SUBSCRIPT_3				;brif not done
    PUSH    PSW							;save carry (CRELOC_R). A == 0
    MOV     B,D							;BC now array size
    MOV     C,E
    XCHG								;multiplication result to HL, ARYTAB_R ptr to DE
    DAD     D							;HL += DE
    JC      L_OUTOFMEMORY				;brif overflow (way overflow)
    CALL    R_GETSTK2					;Test HL against stack space for collision
    SHLD    STRGEND_R					;update unused memory pointer
;
; Clear array data until HL == ARYTAB_R ptr
;
-	DCX     H
    MVI     M,00H
    COMPAR								;HL - DE
    JNZ     -
    INX     B							;increment array size 
    MOV     D,A							;prepare zero extend subscripts count
    LHLD    TEMP3_R						;restore ARYTAB_R ptr to subscripts count
    MOV     E,M							;get subscripts count
    XCHG								;to HL. ARYTAB_R ptr to subscripts count to DE
    DAD     H							;double it
    DAD     B							;add incremented array size
    XCHG								;to DE. ARYTAB_R ptr to subscripts count to HL
    DCX     H							;ptr to reserved space
    DCX     H
    MOV     M,E							;store incremented array size + 2 * subscripts count
    INX     H							;this value is used to find the next array
    MOV     M,D
    INX     H
    POP     PSW							;restore carry (CRELOC_R = CREate or LOCate)
    JC      L_SUBSCRIPT_7				;brif declaration: load TEMP2_R & return
;
; Locate array
; HL points to subscripts count in array
; Data on stack
;
L_SUBSCRIPT_5:							;A == 0 entry point
    MOV     B,A							;start with BC == 0
    MOV     C,A
    MOV     A,M							;subscripts count
    INX     H							;ptr to dimensions
	SKIP_BYTE_INST_D
; subscripts loop
-	POP     H							;array index ptr
	GETDEFROMM							;get dimension to DE
    XTHL								;swap dimension ptr and [SP]
    PUSH    PSW							;save subscripts count
    COMPAR								;Compare dimension and array index: HL - DE
    JNC     L_GEN_ERR_9					;brif HL >= DE: Generate error 9
    CALL    L_INT16_MUL					;multiply DE and BC to DE
    DAD     D							;Add to HL
    POP     PSW							;restore subscripts count
    DCR     A							;count down
    MOV     B,H							;update BC
    MOV     C,L
    JNZ     -							;brif more subscripts
    LDA     VALTYP_R					;Type of last expression used
    MOV     B,H							;BC = HL
    MOV     C,L
    DAD     H							;X2
    SUI     04H							;SNGL type?
    JC      +							;brif type < SNGL: INT or STR
; type now >= SNGL
    DAD     H							;X4 flags not affected
    JZ      L_SUBSCRIPT_6				;brif type == SNGL
    DAD     H							;X8 flags not affected
+	ORA     A
    JPO     L_SUBSCRIPT_6				;brif A >= 0
    DAD     B							;HL += BC
L_SUBSCRIPT_6:
    POP     B							;restore BC
    DAD     B							;HL += BC
    XCHG								;result to DE
L_SUBSCRIPT_7:
    LHLD    TEMP2_R
    RET
;
; USING function
;
R_USING_FUN:							;4991H
    CALL    L_FRMCHK      				;Main BASIC_1 evaluation routine
    CALL    L_CHKSTR
	SYNCHK	';'
    XCHG
    LHLD    IFACLO_R					;FAC1 for integers
    JMP     L_USING1

L_USING0:
    LDA     PRT_USING_R
    ORA     A
    JZ      L_USING2
    POP     D
    XCHG
L_USING1:
    PUSH    H
    XRA     A
    STA     PRT_USING_R
    INR     A
    PUSH    PSW
    PUSH    D
    MOV     B,M
    INR     B
    DCR     B
L_USING2:
    JZ      R_GEN_FC_ERROR				;Generate FC error
    INX     H
	GETHLFROMM							;get ptr to HL
    JMP     L_USING5

L_USING3:
    MOV     E,B
    PUSH    H
    MVI     C,02H
-	MOV     A,M
    INX     H
    CPI     '\\'
    JZ      L_USING_BACK
    CPI     ' '
    JNZ     +
    INR     C
    DCR     B
    JNZ     -
+	POP     H
    MOV     B,E
    MVI     A,'\\'						;5CH
L_USING4:
    CALL    L_USING_PLUS				;Print '+' if needed
    OUTCHR								;Send character in A to screen/printer
L_USING5:
    XRA     A							;clear A, DE
    MOV     E,A
    MOV     D,A
-	CALL    L_USING_PLUS				;Print '+' if needed
    MOV     D,A
    MOV     A,M
    INX     H
    CPI     '!'
    JZ      L_USING_BANG
    CPI     '#'
    JZ      L_USING_HASH
    DCR     B
    JZ      L_USING12
    CPI     '+'
    MVI     A,08H
    JZ      -
    DCX     H
    MOV     A,M
    INX     H
    CPI     '.'
    JZ      L_USING6
    CPI     '\\'
    JZ      L_USING3
    CMP     M
    JNZ     L_USING4
    CPI     '$'
    JZ      L_USING_DLR
    CPI     '*'
    JNZ     L_USING4
    INX     H
    MOV     A,B
    CPI     02H
    JC      +
    MOV     A,M
    CPI     '$'
+	MVI     A,' '
    JNZ     +
    DCR     B
    INR     E
	SKIP_XRA_A_CP						;A unaffected
L_USING_DLR:
    XRA     A
    ADI		10H
    INX     H
+	INR     E
    ADD     D
    MOV     D,A
L_USING_HASH:
    INR     E
    MVI     C,00H
    DCR     B
    JZ      L_USING8
    MOV     A,M
    INX     H
    CPI     '.'
    JZ      L_USING_DOT
    CPI     '#'
    JZ      L_USING_HASH
    CPI     ','
    JNZ     L_USING7
    MOV     A,D
    ORI     40H
    MOV     D,A
    JMP     L_USING_HASH

L_USING6:
    MOV     A,M
    CPI     '#'
    MVI     A,'.'
    JNZ     L_USING4
    MVI     C,01H
    INX     H
L_USING_DOT:
    INR     C
    DCR     B
    JZ      L_USING8
    MOV     A,M
    INX     H
    CPI     '#'
    JZ      L_USING_DOT
L_USING7:
    PUSH    D
    LXI     D,L_USING_CONT				;continuation function
    PUSH    D
    MOV     D,H
    MOV     E,L
    CPI     '^'
    RNZ
    CMP     M
    RNZ
    INX     H
    CMP     M
    RNZ
    INX     H
    CMP     M
    RNZ
    INX     H
    MOV     A,B
    SUI     04H
    RC
    POP     D
    POP     D
    MOV     B,A
    INR     D
    INX     H
	SKIP_2BYTES_INST_JZ					;skip XCHG & POP D
L_USING_CONT:
    XCHG
    POP     D
L_USING8:
    MOV     A,D
    DCX     H
    INR     E
    ANI     08H
    JNZ     L_USING9
    DCR     E
    MOV     A,B
    ORA     A
    JZ      L_USING9
    MOV     A,M
    SUI     2DH
    JZ      +
    CPI     0FEH
    JNZ     L_USING9
    MVI     A,08H
+	ADI		04H
    ADD     D
    MOV     D,A
    DCR     B
L_USING9:
    POP     H
    POP     PSW
    JZ      L_USING13
    PUSH    B
    PUSH    D
    CALL    L_FRMEVL					;Main BASIC evaluation routine
    POP     D
    POP     B
    PUSH    B
    PUSH    H
    MOV     B,E
    MOV     A,B
    ADD     C
    CPI     19H
    JNC     R_GEN_FC_ERROR				;brif A >= 19H: Generate FC error
    MOV     A,D
    ORI     80H							;10000000H
    CALL    R_PRINT_FAC1
    CALL    R_PRINT_STRING				;Print buffer at M until NULL or '"'
L_USING10:
    POP     H
    DCX     H
    CHRGET								;Get next non-white char from M
    STC
    JZ      L_USING11
    STA     PRT_USING_R
    CPI     ';'
    JZ      +
    CPI     ','
    JNZ     R_GEN_SN_ERROR				;Generate Syntax error
+	CHRGET								;Get next non-white char from M
L_USING11:
    POP     B
    XCHG
    POP     H
    PUSH    H
    PUSH    PSW
    PUSH    D
    MOV     A,M
    SUB     B
    INX     H
    MVI     D,00H
    MOV     E,A
	GETHLFROMM							;get ptr to HL
    DAD     D
    MOV     A,B
    ORA     A
    JNZ     L_USING5
    JMP     +

L_USING12:
    CALL    L_USING_PLUS				;Print '+' if needed
    OUTCHR								;Send character in A to screen/printer
+	POP     H
    POP     PSW
    JNZ     L_USING0
L_USING13:
    CC      L_PRINT_CRLF
    XTHL
    CALL    L_FRETM2
    POP     H
    JMP     L_FINPRT

L_USING_BANG:
    MVI     C,01H
	SKIP_BYTE_INST						;Sets A to 0AFH
L_USING_BACK:
    POP     PSW
    DCR     B
    CALL    L_USING_PLUS				;Print '+' if needed
    POP     H
    POP     PSW
    JZ      L_USING13
    PUSH    B
    CALL    L_FRMEVL					;Main BASIC evaluation routine
    CALL    L_CHKSTR
    POP     B
    PUSH    B
    PUSH    H
    LHLD    IFACLO_R					;FAC1 for integers
    MOV     B,C
    MVI     C,00H
    MOV     A,B
    PUSH    PSW
    CALL    L_LEFT_STR_2
    CALL    L_PRINT_LST_STR
    LHLD    IFACLO_R					;FAC1 for integers
    POP     PSW
    SUB     M
    MOV     B,A
    MVI     A,' '
    INR     B							;pre-increment
;
; output ' ' B times
;
-	DCR     B
    JZ      L_USING10					;brif done
    OUTCHR								;Send character in A to screen/printer
    JMP     -
;
; Print '+' if needed
;
; IN:
;	D		need marker
;
L_USING_PLUS:
    PUSH    PSW
    MOV     A,D
    ORA     A
    MVI     A,'+'
    CNZ     R_SEND_A_LCD_LPT			;Send A to screen or printer
    POP     PSW
    RET
;
; Send A to screen or printer
;
R_SEND_A_LCD_LPT:						;4B44H
    PUSH    PSW
    PUSH    H
    CALL    L_TST_FCBLAST
    JNZ     L_DEV_OUTPUT				;brif FCBLAST != 0
    POP     H
    LDA     PRTFLG_R					;Output device for RST 20H (0=screen)
    ORA     A
    JZ      R_LCD_CHAR_OUT_FUN			;PSW pushed
    POP     PSW
;
; Print A to printer), expanding tabs if necessary
;
R_PRINT_A_EXPAND:						;4B55H
    PUSH    PSW							;save char
    CPI     09H
    JNZ     L_PRINT_A
-	MVI     A,' '
    CALL    R_PRINT_A_EXPAND			;Print A to printer), expanding tabs if necessary
    LDA     LPTPOS_R					;Line printer head position
    ANI     07H							;modulo 8
    JNZ     -							;loop
    POP     PSW							;restore char
    RET

L_PRINT_A:
    SUI     0DH							;CR
    JZ      +							;brif char is CR. A == 0
    JC      L_PRINT_A_1					;brif char < CR
    LDA     LPTPOS_R					;Line printer head position
    INR     A
+	STA 	LPTPOS_R					;update Line printer head position
L_PRINT_A_1:
    POP     PSW							;restore char
L_PRINT_A_2:
    CPI     0AH							;LF
    JNZ     +							;brif char != LF
; A == LF
    PUSH    B							;save BC
    MOV     B,A							;save LF
    LDA     LASTLPT_R					;get Last char sent to printer
    CPI     0DH							;CR
    MOV     A,B							;restore LF
    POP     B							;restore BC
+	STA     LASTLPT_R					;update Last char sent to printer
    RZ									;retif char == CR
    CPI     1AH
    RZ									;retif char == ^Z
    JMP     R_OUT_CH_TO_LPT				;Output character to printer
;
; Reinitialize output back to LCD
;
R_SET_OUT_DEV_LCD:						;4B92H
    XRA     A
    STA     PRTFLG_R					;Output device for RST 20H (0=screen)
    LDA     LPTPOS_R					;Line printer head position
    ORA     A
    RZ
    LDA     LPT_MOVING_R				;test
    ORA     A
    RZ
L_LPT_NEWLINE:							;send CR to printer
    MVI     A,0DH						;CR
    CALL    L_PRINT_A_2					;send to printer. TODO CALL R_PRINT_A_EXPAND shorter
    XRA     A
    STA     LPTPOS_R					;Line printer head position
    RET
;
; LCD character output routine
;
R_LCD_CHAR_OUT_FUN:
    POP     PSW							;retrieve PSW 
    PUSH    PSW
    CALL    R_PRINT_A_TO_LCD			;Print A to the screen
    LDA     CSRX_R						;Cursor column (1-40)
    DCR     A
    STA     CURHPOS_R					;Horiz. position of cursor (0-39)
    POP     PSW
    RET
;
;Move LCD to blank line (send CRLF if needed)
;
R_LCD_NEW_LINE:							;4BB8H
    LDA     CSRX_R						;Cursor column (1-40)
    DCR     A
    RZ									;retif CSRX_R == 1
    JMP     L_PRINT_CRLF
;
; TODO unreachable code
;
    MVI     M,00H
    CALL    L_TST_FCBLAST
    LXI     H,INPBUF_R-1				;Keyboard buffer
    JNZ     L_RECORD_CR					;brif FCBLAST != 0
L_PRINT_CRLF:
    MVI     A,0DH
    OUTCHR								;Send character in A to screen/printer
    MVI     A,0AH
    OUTCHR								;Send character in A to screen/printer
;
; record a CR
;
L_RECORD_CR:
    CALL    L_TST_FCBLAST
;
; TODO: shorter to JNZ to XRA A, RET Code
;
    JZ      L_RESET_POS					;brif FCBLAST == 0
    XRA     A
    RET

L_RESET_POS:
    LDA     PRTFLG_R					;Output device for RST 20H (0=screen)
    ORA     A
    JZ      L_REST_POS_LCD				;brif 0 to screen
    XRA     A							;newline to printer
    STA     LPTPOS_R					;Line printer head position
    RET

L_REST_POS_LCD:
    XRA     A							;newline to LCD
    STA     CURHPOS_R					;Horiz. position of cursor (0-39)
    RET
;
; INKEY$ function
;
R_INKEY_FUN:							;4BEAH
    CHRGET								;Get next non-white char from M
    PUSH    H							;save text ptr
    CALL    R_CHK_KEY_QUEUE				;Check keyboard queue for pending characters
    JZ      +
    CALL    R_WAIT_KEY				  	;Wait for key from keyboard
    PUSH    PSW							;save key
    CALL    L_PREP_STR_LEN1
    POP     PSW							;restore key
    MOV     E,A							;to E
    CALL    L_CHR_1						;Store character and add to String Stack. No return here.
+	LXI     H,R_NULL_MSG				;Code Based. 
    SHLD    IFACLO_R					;FAC1 for integers
    MVI     A,03H						;type STRING
    STA     VALTYP_R					;Type of last expression used
    POP     H							;restore text ptr
    RET
;
; push HL and eval Filename
; IN:
;	E
L_PSH_HL_EVAL_FILNAM:
    PUSH    H							;save txt ptr
    JMP     L_EVAL_FILNAM_1
;
; Evaluate arguments to RUN/OPEN/SAVE/NAME/MERGE commands
;
; OUT:
;	D			Device Code
;	Z			result of L_DEVTST_FUN call
;
L_EVAL_FILNAM:
    CALL    L_FRMEVL					;Main BASIC evaluation routine
    PUSH    H							;save txt ptr
    CALL    L_FRESTR					;FREE UP TEMP & CHECK STRING
    MOV     A,M							;get length
    ORA     A
    JZ      L_BAD_FILESPEC				;brif 0 length string
    INX     H							;to address of string
    MOV     E,M							;get address to HL
    INX     H
    MOV     H,M
    MOV     L,E
    MOV     E,A							;length of string in E
L_EVAL_FILNAM_1:
    CALL    L_DEVTST_FUN				;E == length of string
    PUSH    PSW							;save result of L_DEVTST_FUN call
    LXI     B,FILNAM_R				    ;Destination: Current Filename
    MVI     D,09H						;max length+1
    INR     E							;pre-increment
L_EVAL_FILNAM_2:
	DCR     E							;string length
    JZ      L_PAD_FILESPEC				;brif done
    CALL    R_CONV_M_TOUPPER			;Get char at M and convert to uppercase
    CPI     ' '
    JC      L_BAD_FILESPEC				;brif < ' ': Bad Filename
    CPI     7FH							;DEL
    JZ      L_BAD_FILESPEC				;brif Bad Filename
    CPI     '.'
    JZ      L_FOUND_DOT					;brif extension found
    STAX    B							;copy char to filename
    INX     B							;next destination
    INX     H							;next source
    DCR     D							;length 9..1
    JNZ     L_EVAL_FILNAM_2				;loop
L_EVAL_FILNAM_3:
    POP     PSW							;restore result of L_DEVTST_FUN call
    PUSH    PSW
    MOV     D,A							;move to D
    LDA     FILNAM_R					;Current Filename
    INR     A							;test for 0FFH
    JZ      L_BAD_FILESPEC				;error
    POP     PSW							;result of L_DEVTST_FUN call
    POP     H							;restore src ptr
    RET

L_BAD_FILESPEC:
    JMP     R_GEN_NM_ERR_FUN			;Generate NM error (Bad Filename)
;
; skip '.'
;
L_SKIP_DOT:
    INX     H
    JMP     L_EVAL_FILNAM_2				;continue
;
; found '.' in filespec
;
L_FOUND_DOT:								
    MOV     A,D							;chars left
    CPI     09H	
    JZ      L_BAD_FILESPEC				;brif filename starts with '.'
    CPI     03H
    JC      L_BAD_FILESPEC				;brif < 2 characters left
    JZ      L_SKIP_DOT					;exactly 2 chars left
    MVI     A,' '						;pad filename before extension
    STAX    B
    INX     B
    DCR     D							;length
    JMP     L_FOUND_DOT					;loop
;
; filename padding
;
L_PAD_FILESPEC:
    MVI     A,' '						;pad filename
    STAX    B
    INX     B
    DCR     D							;length 9..1
    JNZ     L_PAD_FILESPEC
    JMP     L_EVAL_FILNAM_3				;finish
;
; get next char from HL, remaining length in E
;
; OUT:
;	Z		if no more chars (E == 0)
;
L_NEXTCHAR_DECE:
    MOV     A,M
    INX     H
    DCR     E
    RET

R_GET_FCB:
    CALL    L_CONINT
;
; Get FCB for file # in A
;
; IN:
;	A		file #
; OUT:
;	Z		file status
;	carry	set if success
;	HL		FCB ptr
;	A		File Status
;
R_GET_FCB_FROM_A:						;4C84H
    MOV     L,A							;file #
    LDA     MAXFILES_R					;Maxfiles
    CMP     L
    JC      R_GEN_BN_ERR_FUN			;if Maxfile < file # Generate BN error
    MVI     H,00H						;zero extend
    SHLD    FILNUM_R					;store validated file #
    DAD     H							;double zero extended validated file number
    XCHG								;offset to DE
    LHLD    FCBTBL_R					;HO now points to FCB table
    DAD     D							;index into FCB table
	GETHLFROMM							;get FCB ptr to HL
    MOV     A,M							;File Type
    ORA     A
    RZ									;retif File Not Open
    PUSH    H							;save FCB ptr
    LXI     D,DEV_IN_FCB_OFS			;0004H offset in FCB: Device code
    DAD     D							;index
    MOV     A,M							;get DCB code
    CPI     09H
    JNC     +							;brif DCB code >= 9
	RST38H	1EH
    JMP     R_GEN_IE_ERR_FUN			;Generate IE error

+	POP     H							;restore FCB ptr
    MOV     A,M							;get File status
    ORA     A							;test
    STC									;set carry: success
    RET
;
; Set FCBLAST_R from file#
;
; OUT:
;	A		File Status
;	HL		FCB ptr
;
L_SET_FCBLAST:
    DCX     H							;backup txt ptr
    CHRGET								;Get next non-white char from M
    CPI     '#'
    CZ      L_CHRGTR					;Get next non-white char from M
    CALL    L_GETBYT					;Evaluate byte expression at M-1
    XTHL								;swap HL and [SP]
    PUSH    H							;push return address again
L_SETUP_FCB:
    CALL    R_GET_FCB_FROM_A			;Get FCB for file in A
    JZ      R_GEN_CF_ERR_FUN			;brif if file not open: Generate CF error
    SHLD    FCBLAST_R					;FCB ptr for the last file used (2 bytes)
	RST38H	0CH
    RET
;
; OPEN statement:
;	OPEN "filespec" FOR mode AS num
;
R_OPEN_STMT:							;4CCBH
    LXI     B,L_FINPRT					;ZERO PTRFIL WHEN DONE continuation function
    PUSH    B
    CALL    L_EVAL_FILNAM				;Evaluate arguments to RUN/OPEN/SAVE commands
    JNZ     +							;brif DEV was specified
    MVI     D,RAM_DEV					;set to RAM_DEV if not
+	SYNCHK	_FOR						;81H
    CPI     _INPUT						;84H
    MVI     E,01H						;preload File open Mode
    JZ      L_OPEN_INPUT
    CPI     _OUT						;96H
    JZ      L_OPEN_OUTPUT
	SYNCHK	'A'
	SYNCHK	'P'
	SYNCHK	'P'
	SYNCHK	_END						;80H
    MVI     E,08H						;append File open Mode
    JMP     L_OPEN_INPUT_1

L_OPEN_OUTPUT:
    CHRGET								;Get next non-white char from M
	SYNCHK	'P'
	SYNCHK	'U'
	SYNCHK	'T'
    MVI     E,02H						;File open Mode
	SKIP_BYTE_INST						;Sets A to 0AFH
L_OPEN_INPUT:							;E == 1 File open Mode entry point
    CHRGET								;Get next non-white char from M
L_OPEN_INPUT_1:							;E == 8 File open Mode entry point (append)
	SYNCHK	'A'
	SYNCHK	'S'
    PUSH    D							;save markers in DE
    MOV     A,M							;get next char
    CPI     '#'
    CZ      L_CHRGTR					;Get next non-white char from M: skip '#'
    CALL    L_GETBYT    				;Evaluate byte expression at M-1: file number
    ORA     A							;result
    JZ      R_GEN_BN_ERR_FUN			;Generate BN error
	RST38H	18H
	SKIP_BYTE_INST_E					;skip markers in D,E push
;
; R_OPEN_FILE
;
; IN:
;	A			File #
;	D			Device code
;	E			DCB function: 1: Open for Input. 2: Open for Output 8: Open for append
;
R_OPEN_FILE:							;A is argument for this entry point
    PUSH    D							;save markers in D,E
    DCX     H							;backup text ptr
    MOV     E,A							;save file #
    CHRGET								;Get next non-white char from M
    JNZ     R_GEN_SN_ERROR				;Generate Syntax error if more characters
    XTHL								;swap return address & text ptr
    MOV     A,E							;restore file #
    PUSH    PSW							;save it
    PUSH    H							;return address?
    CALL    R_GET_FCB_FROM_A			;Get FCB for file in A
    JNZ     R_GEN_AO_ERR_FUN			;brif file open: Generate AO error
    POP     D							;restore markers in D,E
    MOV     A,D							;device code (0F8H..0FFH)
    CPI     09H							;Max device code
	RST38H	1CH
    JC      R_GEN_IE_ERR_FUN			;Generate IE error if device code < 9
    PUSH    H							;save FCB ptr
    LXI     B,DEV_IN_FCB_OFS			;index to device code in FCB
    DAD     B
    MOV     M,D							;set device code
    MVI     A,DCBOPN_FUN				;00H no flags affected
    POP     H							;restore FCB ptr
    JMP     L_EXEC_DCB_FUNC
;
; IN:
;	A		File #
;	Carry
;
L_CLS_FILENUM:
    PUSH    H
    ORA     A
    JNZ     +							;brif A != 0
; A == 0. Close OPNFIL_R
    LDA     OPNFIL_R					;File status
    ANI     01H							;isolate bit 0
    JNZ     L_POPH_RET					;brif bit 0 set: POP H & RET
+	CALL    R_GET_FCB_FROM_A			;Get FCB for file in A. Carry set if success
    JZ      R_LCD_CLOSE_FUN_1			;brif File Status == 0. Carry still valid. A == 0
    SHLD    FCBLAST_R					;FCB ptr for the last file used (2 bytes)
    PUSH    H
    MVI     A,DCBCLS_FUN				;02H DCB Close function
    JC      L_EXEC_DCB_FUNC				;brif success from R_GET_FCB_FROM_A
	RST38H	14H
    JMP     R_GEN_IE_ERR_FUN			;Generate IE error
;
; LCD), CRT), and LPT file close routine
; Jumped to (not called) with 2 ptrs pushed before a return address
;
; Top of Stack:	FCB ptr
;
R_LCD_CLOSE_FUN:						;4D59H
    CALL    L_CLR_FCBLAST_BUF			;Clear FCBLAST_R buffer. Returns A == 0
    POP     H							;FCB ptr
R_LCD_CLOSE_FUN_1:						;A == 0
    PUSH    H							;save FCB ptr
    LXI     D,FILPOS_IN_FCB_OFS			;0007H						
    DAD     D							;index to Relative position
    MOV     M,A							;clear Relative position LSB field
    MOV     H,A							;clear HL
    MOV     L,A
    SHLD    FCBLAST_R					;clear FCB ptr for the last file used (2 bytes)
    POP     H							;restore FCB ptr. A still 0
    ADD     M							;A == previous File Status
    MVI     M,00H						;clear File Status (0 == closed)
    POP     H
    RET
;
; RUN_2 statement
;
R_RUN_STMT_2:							;4D6EH
    STC									;marker for RUN
	SKIP_2BYTES_INST_DE					;skip SKIP_XRA_A & XRA A
;
; LOAD statement
;
R_LOAD_STMT:							;4D70H
	SKIP_XRA_A							;ORI 0AFH Set A to 0AFH
;
; RUN (RUN,R), LOAD (LOAD,R) or MERGE statement
;
R_MERGE_STMT:							;4D71H
    XRA     A							;marker for MERGE
    PUSH    PSW							;Marker: 0AFH (LOAD), Z (MERGE) and carry (RUN)
    DCX     H							;backup to current char
    CHRGET								;Get next non-white char from M
    CPI     'M'							;extra 'M'?
    JZ      R_LOADM_STMT				;LOADM and RUNM statement
    CALL    L_EVAL_FILNAM				;Evaluate arguments to RUN/OPEN/SAVE commands
    JZ      L_RAMFILE					;brif Device was NOT specified
    MOV     A,D							;device code
    CPI     RAM_DEV						;0F8H
    JZ      L_RAMFILE
    CPI     CAS_DEV						;0FDH
    JZ      L_CLOAD_STMT_1				;brif CAS device
	RST38H	1AH
; not RAM or CAS device
L_MERGE_1:
    POP     PSW							;retrieve marker
    PUSH    PSW
    JZ      +							;brif MERGE
    MOV     A,M							;next char
    SUI     ','
    ORA     A
    JNZ     +
    CHRGET								;Get next non-white char from M
	SYNCHK	'R'
    POP     PSW							;set carry in marker
    STC
L_MERGE_2:								;D has Device Code
    PUSH    PSW
+	PUSH    PSW
    XRA     A							;File # == 0
    MVI     E,01H						;Open for Input marker
    CALL    R_OPEN_FILE
L_MERGE_3:								;entry point with 2 x PSW on stack
    LHLD    FCBLAST_R					;FCB ptr for the last file used (2 bytes)
    LXI     B,FILPOS_IN_FCB_OFS			;0007H 
    DAD     B							;index
    POP     PSW							;last pushed PSW
    SBB     A							;0 or 0FFH based on carry
    ANI     80H							;isolate bit 7
    ORI     01H							;set bit 0: open for input
    STA     OPNFIL_R
    POP     PSW							;first pushed PSW (Marker)
    PUSH    PSW
    SBB     A							;0 or 0FFH based on carry: run program after load
    STA     EXCFLG_R					;Flag to execute BASIC program
    MOV     A,M
    ORA     A
    JM      L_SAVE_ERR2					;Generate NM error
    POP     PSW
    CNZ     SCRTCH
    CALL    R_CLSALL					;Close Files
    XRA     A
    CALL    L_SETUP_FCB
    JMP     R_GO_BASIC_RDY				;Silent vector to BASIC ready
;
; SAVE statement
;
R_SAVE_STMT:							;4DCFH
    CPI     'M'
    JZ      R_SAVEM_STMT				;SAVEM statement
    CALL    R_INIT_BASIC_VARS_2
    CALL    L_EVAL_FILNAM				;Evaluate arguments to RUN/OPEN/SAVE commands. returns Device Code in D
    JZ      L_SAVE_RAM					;brif Device was NOT specified
    MOV     A,D							;get Device Code
    CPI     RAM_DEV						;0F8H
    JZ      L_SAVE_RAM					;brif RAM device
    CPI     CAS_DEV						;0FDH
    JZ      L_CSAVE_BAS					;brif Cassette device
; device other than RAM or CAS specified
	RST38H	16H
    DCX     H							;backup text ptr
    CHRGET								;Get next non-white char from M
    MVI     E,80H						;set File Mode to 80H
    STC									;preset carry
    JZ      +							;brif end of statement
	SYNCHK	','							;save BASIC program in ASCII mode
	SYNCHK	'A'
    ORA     A							;set flags
    MVI     E,02H						;File Mode Output
+	PUSH    PSW
    MOV     A,D							;Device code
    CPI     09H
    JC      L_SAVE_ASC					;brif Device code < 9
    MOV     A,E							;File Mode
    ANI     80H							;isolate bit 7
    JZ      L_SAVE_ASC					;brif bit 7 set
    MVI     E,02H						;marker Open File for Output
    POP     PSW
    XRA     A							;clear carry on stack
    PUSH    PSW
L_SAVE_ASC:								;PSW pushed for this entry point
    XRA     A							;File # == 0
    CALL    R_OPEN_FILE					;DE must be set
    POP     PSW
    JC      L_SAVE_ERR1					;brif carry (error)
    DCX     H
    CHRGET								;Get next non-white char from M
    JMP     R_LIST_STMT				  	;use LIST statement code to save BASIC file

L_SAVE_ERR1:
	RST38H	22H
    JMP     R_GEN_NM_ERR_FUN			;Generate NM error

L_SAVE_ERR2:
	RST38H	24H
    JMP     R_GEN_NM_ERR_FUN			;Generate NM error
;
; Close Files
;
R_CLSALL:
    LDA     OPNFIL_R					;Any open files flag
    ORA     A
    RM
    XRA     A
;
; CLOSE statement
;	CLOSE [file1, file2...]
;
R_CLOSE_STMT:							;4E28H
    LDA     MAXFILES_R					;Maxfiles
    JNZ     R_CLOSE_STMT_2				;brif if any File Number
;
; just CLOSE: close all active File Numbers.
; default for MAXFILES_R is 1 so close file # 1 and 0
;
    PUSH    H							;text ptr
-	PUSH    PSW
    ORA     A							;current file #
    CALL    L_CLS_FILENUM			;close file #
    POP     PSW
    DCR     A							;next File Number
    JP      -							;brif A >= 0
    POP     H							;text ptr
    RET

R_CLOSE_STMT_2:
    MOV     A,M							;next char
    CPI     '#'
    CZ      L_CHRGTR					;Get next non-white char from M
    CALL    L_GETBYT					;Evaluate byte expression at M-1
    PUSH    H							;save text ptr
    STC									;set Carry
    CALL    L_CLS_FILENUM
    POP     H							;restore text ptr
    MOV     A,M							;next char
    CPI     ','
    RNZ									;return if done
    CHRGET								;Get next non-white char from M
    JMP     R_CLOSE_STMT_2				;repeat
;
; Jumped too. AF) and HL) on STACK
;
L_DEV_OUTPUT:
    POP     H							;restore pushed registers
    POP     PSW
    PUSH    H							;save all registers
    PUSH    D
    PUSH    B
    PUSH    PSW
    LHLD    FCBLAST_R					;FCB ptr for the last file used (2 bytes)
    MVI     A,DCBOUT_FUN
    CALL    L_DEV_VALIDATOR				;HL contains FCB ptr. No return
	RST38H	20H
    JMP     R_GEN_NM_ERR_FUN			; Generate NM error
;
; I/O helper function.
; HL, DE, BC pushed on stack before call
;
; L_DEV_OUTPUT() also pushes PSW
;
; Validates Device Code
;
; Only returns to caller if error
; IN:
;	A			DCB function
;	HL			FCB ptr
; OUT:
;
;
; DE preserved
;
L_DEV_VALIDATOR:
    PUSH    PSW							;save DCB function
    PUSH    D							;save DE ptr
    XCHG								;FCB ptr to DE
    LXI     H,DEV_IN_FCB_OFS			;offset 4 
    DAD     D							;index
    MOV     A,M							;get Device code (negative offset 0F8H..0FFH)
    XCHG								;FCB ptr back to HL
    POP     D							;restore DE ptr
    CPI     09H							;Device code limit
    JC      L_POPPSW_RET				;brif A < 9: POP PSW & RET
    POP     PSW							;restore DCB function
    XTHL								;remove return address from stack
    POP     H
    JMP     L_EXEC_DCB_FUNC
;
; Device Input Function.
;
; IN:
;	HL			FCB ptr
; OUT:
;	carry		set if Error
;
L_DEV_INPUT:
    PUSH    B							;save BC, HL, DE
    PUSH    H
    PUSH    D
    LHLD    FCBLAST_R					;FCB ptr for the last file used (2 bytes)
    MVI     A,DCBIN_FUN					;DCB In function 
    CALL    L_DEV_VALIDATOR				;HL contains FCB ptr. No return
	RST38H	0EH
    JMP     R_GEN_NM_ERR_FUN			; Generate NM error
;
; Pops DE, HL, BC from stack
; Must be jumped to.
;
L_POPDHBREGS:
    POP     D
    POP     H
    POP     B
    RET
;
; INPUT_2 statement
;
; INPUT$(num[, file])
;
; Chars read are store in a string which is pushed on the string stack
;
;
R_INPUT_STMT_2:							;4E8EH
    CHRGET								;Get next non-white char from M
	SYNCHK	'$'
	SYNCHK	'('
    PUSH    H
    LHLD    FCBLAST_R					;FCB ptr for the last file used (2 bytes)
    PUSH    H
    LXI     H,0
    SHLD    FCBLAST_R					;Clear FCB ptr for the last file used (2 bytes)
    POP     H							;swap HL and [STK]
    XTHL
    CALL    L_GETBYT					;Evaluate byte expression at M-1
    PUSH    D							;save number of bytes to read
    MOV     A,M							;get next char
    CPI     ','
    JNZ     L_INPUT_2_1					;brif no ',': use keyboard
; ',' found
    CHRGET								;Get next non-white char from M
    CALL    L_SET_FCBLAST				;get FCB ptr from file#. Returns File status and text pointer on stack
    CPI     01H							;00000001 internal use?
    JZ      +
    CPI     04H							;00000100 reserved?
    JNZ     R_GEN_EF_ERR_FUN			;Generate EF error
+	POP     H							;retrieve text ptr returned by L_SET_FCBLAST
    XRA     A							;TODO useless
    MOV     A,M							;get next char
L_INPUT_2_1:
    PUSH    PSW							;save flags: File or keyboard
	SYNCHK	')'
    POP     PSW							;restore A
    XTHL								;swap text ptr and [SP]
    PUSH    PSW							;save A
    MOV     A,L							;test LSB File number
    ORA     A
    JZ      R_GEN_FC_ERROR				;Generate FC error
    PUSH    H
    CALL    L_PREP_STR					;Reserve String space and set Transitory String
    XCHG
    POP     B							;number of bytes to read to BC
; Actual read
-	POP     PSW							;retrieve flags:  flags: File or keyboard
    PUSH    PSW
    JZ      L_INPUT_2_4					;brif Z: read from Device
    CALL    R_WAIT_KEY				  	;Wait for key from keyboard
    CPI     03H							;^C
    JZ      L_INPUT_2_3
;
; store char read in Transient string
;
L_INPUT_2_2:
    MOV     M,A							;keyboard char to Transient string
    INX     H							;next
    DCR     C							;count
    JNZ     -							;read more
    POP     PSW							;clear stack
    POP     B
    POP     H
	RST38H	10H
    SHLD    FCBLAST_R					;FCB ptr for the last file used (2 bytes)
    PUSH    B							;text ptr
    JMP     L_STRSTK_ADD				;add Transient String to String Stack
;
; ^C on keyboard
;
L_INPUT_2_3:
    POP     PSW
    LHLD    CURLIN_R					;Currently executing line number
    SHLD    ERRLIN_R					;Line number of last error
    POP     H
    JMP     R_INIT_AND_READY			;Initialize system and go to BASIC ready
;
; read a char from DEVICE
;
L_INPUT_2_4:
    CALL    L_DEV_INPUT					;read char
    JC      R_GEN_EF_ERR_FUN			;brif error: Generate EF error
    JMP     L_INPUT_2_2
;
; Clear FCB buffer if FCBLAST_R
; OUT:
;	A		0
;	HL		&(FCBLAST_R->9)
;
L_CLR_FCBLAST_BUF:
    CALL    L_GET_FCBLAST_BUF
    PUSH    H
    MVI     B,00H						;256 count
    CALL    R_CLEAR_MEM				  	;Zero B bytes at M. A == 0
L_POPH_RET:								;tail merge
    POP     H
    RET
;
; Zero B bytes at M
;
; IN:
;	HL
; OUT:
;	A == 0
;
R_CLEAR_MEM:							;4F0AH
    XRA     A
;R_LOAD_MEM:							;4F0BH
-	MOV     M,A
    INX     H
    DCR     B
    JNZ     -							;R_LOAD_MEM Load B bytes at M with A
    RET
;
; OUT:
;	HL		&(FCBLAST_R->BUFFER_IN_FCB)
;
L_GET_FCBLAST_BUF
    LHLD    FCBLAST_R					;FCB ptr for the last file used (2 bytes)
    LXI     D,BUFFER_IN_FCB_OFS			;offset 9
    DAD     D							;index
    RET
;
; POP PSW & RET
;
L_POPPSW_RET:
    POP     PSW
    RET
;
; Generate "Direct Statement in File" error if FCBLAST != 0
;
L_LINE_NONUM:
    CALL    L_TST_FCBLAST
    JZ      R_RUN_BASIC_AT_HL			;brif FCBLAST==NULL: Start executing BASIC program at HL
    XRA     A
    CALL    L_CLS_FILENUM
    JMP     R_GEN_DS_ERR_FUN			;Generate "Direct Statement in File" error

L_VALIDATE_FILE:						;validate File #
    MVI     C,01H						;indicated INPUT file mode
L_VALIDATE_FILE_1:
    CPI     '#'							;indicates filenumber coming
    RNZ
;
; PRINT # or INPUT # initialization routine
; INPUT # and LINE INPUT # do not allow for a prompt string
;
; IN:
;	C		file mode
;
R_PRINT_LB_INIT_FUN:					;4F2EH
    PUSH    B							;save BC
    CALL    L_GTBYTC					;Evaluate byte expression at M: filenumber to E
	SYNCHK	','
    MOV     A,E
    PUSH    H							;save txt ptr
    CALL    L_SETUP_FCB
    MOV     A,M							;read from FCB: file mode
    POP     H							;restore txt ptr
    POP     B							;restore BC
    CMP     C			
    JZ      +							;TODO JNZ Err shorter
    JMP     R_GEN_BN_ERR_FUN			;Generate BN error
+	MOV     A,M							;next char from txt
    RET
;
;close file 0 & Load LSTVAR_R
;
L_CLS_FILE0:							;close file 0 & Load LSTVAR_R:
    LXI     B,L_INIT_BASIC_1			;Continuation function: "load Address of last variable assigned"
    PUSH    B
    XRA     A							
    JMP     L_CLS_FILENUM				;close file# 0
;
; FCBLAST != 0
; Called from R_READ_STMT
; variable address on stack
;
L_READ_STMT_9:
    LSTTYP								;Determine type of last var used: C Clr = DBL P Clr = SNGL Z Set = String S: Set = Integer
; A now contains VALTYP_R - 3
    LXI     B,L_READ_STMT_5				;continuation function
    LXI     D,2C20H						;", "
    JNZ     L_LINE_IN_0					;brif not String type
    MOV     E,D							;',,' or 2C2CH
    JMP     L_LINE_IN_0
;
; LINE INPUT FILENUM statement
; No prompt string allowed
;
R_LINE_INPUT_FILE:						;4F5BH
    LXI     B,L_FINPRT				;continuation function
    PUSH    B							;L_FINPRT when done
    CALL    L_VALIDATE_FILE				;process Filenum #
    CALL    R_FIND_VAR_ADDR				;Find address of variable at M and store in DE
    CALL    L_CHKSTR					;must be a string variable
    PUSH    D							;save variable address
    LXI     B,L_ASSIGN					;continuation function
    XRA     A							;set A to be (VALTYP_R - 3)
    MOV     D,A							;D == 0 means do not skip leading spaces
    MOV     E,A
;
; DE contains format (if jumped from L_READ_STMT_9/R_READ_STMT) or NULL
; BC contains a continuation function Address
; A contains (VALTYP_R - 3)
; variable address on stack
;
L_LINE_IN_0:							;on entry, DE contains char pattern
    PUSH    PSW							;save PSW (VALTYP_R - 3)
    PUSH    B							;continuation function
    PUSH    H							;txt ptr
-	CALL    L_DEV_INPUT					;get string
    JC      R_GEN_EF_ERR_FUN			;brif error: Generate EF error
    CPI     ' '							;skip spaces, max D count
    JNZ     +
    INR     D							;test D
    DCR     D
    JNZ     -							;brif D != 0
+	CPI     '"'
    JNZ     +							;branch forward if A != '"'
    MOV     A,E							;char pattern
    CPI     ','
    MVI     A,'"'						;preload '"'
    JNZ     +							;brif E != ','
    MOV     D,A
    MOV     E,A
    CALL    L_DEV_INPUT
    JC      L_LINE_IN_ERR				;brif error
+	LXI     H,INPBUF_R				    ;Keyboard buffer
    MVI     B,0FFH
L_LINE_IN_1:
    MOV     C,A
    MOV     A,D
    CPI     '"'							;22H
    MOV     A,C
    JZ      L_LINE_IN_2
    CPI     0DH							;CR
    PUSH    H
    JZ      L_LINE_IN_5
    POP     H
    CPI     0AH							;LF
    JNZ     L_LINE_IN_2					;brif A != LF
-	MOV     C,A							;save A
    MOV     A,E							;char pattern
    CPI     ','
    MOV     A,C							;restore A
    CNZ     L_LINE_IN_8
    CALL    L_DEV_INPUT
    JC      L_LINE_IN_ERR				;brif error
    CPI     0AH							;LF
    JZ      -							;brif A == LF
    CPI     0DH							;CR
    JNZ     L_LINE_IN_2					;brif A != CR
; A == CR
    MOV     A,E
    CPI     ' '
    JZ      L_LINE_IN_3
    CPI     ','
    MVI     A,0DH						;CR
    JZ      L_LINE_IN_3
L_LINE_IN_2:
    ORA     A
    JZ      L_LINE_IN_3
    CMP     D
    JZ      L_LINE_IN_ERR
    CMP     E
    JZ      L_LINE_IN_ERR
    CALL    L_LINE_IN_8
L_LINE_IN_3:
    CALL    L_DEV_INPUT
    JNC     L_LINE_IN_1					;brif if no error: loop
; Error Condition
L_LINE_IN_ERR:
    PUSH    H
    CPI     '"'							;22H
    JZ      L_LINE_IN_4
    CPI     ' '	
    JNZ     L_LINE_IN_6
L_LINE_IN_4:
    CALL    L_DEV_INPUT					;brif error
    JC      L_LINE_IN_6
    CPI     ' '
    JZ      L_LINE_IN_4
    CPI     ','
    JZ      L_LINE_IN_6
    CPI     0DH							;CR
    JNZ     +				
L_LINE_IN_5:
    CALL    L_DEV_INPUT
    JC      L_LINE_IN_6					;brif error
    CPI     0AH							;LF
    JZ      L_LINE_IN_6
+	LHLD    FCBLAST_R					;FCB ptr for the last file used (2 bytes)
    MOV     C,A
    MVI     A,DCBIO_FUN
    CALL    L_DEV_VALIDATOR				;HL contains FCB ptr. No return
	RST38H	12H
    JMP     R_GEN_NM_ERR_FUN			;Generate NM error
L_LINE_IN_6:
    POP     H							;restore txt ptr
L_LINE_IN_7:
    MVI     M,00H						;mark end of line
    LXI     H,INPBUF_R-1				;Keyboard buffer
    MOV     A,E
    SUI     ' '	
    JZ      +							;brif char < ' '
    MVI     B,00H
    CALL    R_STRLTI_FOR_B				;Search string at M until 0 found
    POP     H
    RET
+	LSTTYP								;Determine type of last var used: C Clr = DBL P Clr = SNGL Z Set = String S: Set = Integer
    PUSH    PSW							;save result
    CHRGET								;Get next non-white char from M
    POP     PSW							;retrieve LSTTYP result
    PUSH    PSW
    CC      R_ASCII_TO_DBL				;Convert ASCII number at M to double precision in FAC1
    POP     PSW							;restore LSTTYP result
    CNC     R_ASCII_TO_DBL				;Convert ASCII number at M to double precision in FAC1
    POP     H
    RET

L_LINE_IN_8:
    ORA     A							;test A
    RZ									;retif A == 0
    MOV     M,A							;update M
    INX     H							;next
    DCR     B							;counter
    RNZ									;retif not done
    POP     PSW
    JMP     L_LINE_IN_7
;
; Generate NM error
;
R_GEN_NM_ERR_FUN:						;504EH
    MVI     E,37H
	SKIP_2BYTES_INST_BC
;
; Generate AO error
;
R_GEN_AO_ERR_FUN:						;5051H
    MVI     E,35H
	SKIP_2BYTES_INST_BC
;
; Generate DS error
;
R_GEN_DS_ERR_FUN:						;5054H
    MVI     E,38H
	SKIP_2BYTES_INST_BC
;
; Generate FF error
;
R_GEN_FF_ERR_FUN:						;5057H
    MVI     E,34H
	SKIP_2BYTES_INST_BC
;
; Generate CF error
;
R_GEN_CF_ERR_FUN:						;505AH
    MVI     E,3AH
	SKIP_2BYTES_INST_BC
;
; Generate BN error
;
R_GEN_BN_ERR_FUN:						;505DH
    MVI     E,33H
	SKIP_2BYTES_INST_BC
;
; Generate IE error
;
R_GEN_IE_ERR_FUN:						;5060H
    MVI     E,32H
	SKIP_2BYTES_INST_BC
;
; Generate EF error
;
R_GEN_EF_ERR_FUN:						;5063H
    MVI     E,36H
	SKIP_2BYTES_INST_BC
;
; Generate FL error
;
R_GEN_FL_ERR_FUN:						;5066H
    MVI     E,39H
    JMP     R_GEN_ERR_IN_E				;Generate error 39H
;
; LOF function
;
R_LOF_FUN:								;506BH
	RST38H	4EH
;
; LOC function
;
R_LOC_FUN:								;506DH
	RST38H	50H
;
; LFILES function
;
R_LFILES_FUN:							;506FH
	RST38H	52H
;
; DSKO$ function
;
R_DSKO_FUN:								;5071H
	RST38H	56H
;
; DSKI$ function
;
; IN:
;	HL		string ptr
;	E		length of string
;
R_DSKI_FUN:								;5073H
	RST38H	54H
L_DEVTST_FUN:							;test for DEVICE name
	RST38H	28H
    MOV     A,M							;next char
    CPI     ':'
    JC      L_NM_ERR					;brif < ':': Generate NM error
    PUSH    H							;save txt ptr
    MOV     D,E							;save length of string
    CALL    L_NEXTCHAR_DECE				;updates E
    JZ      L_DEVTST_0					;brif no more chars
-	CPI     ':'
    JZ      L_DEVSPEC_FND				;brif Device Specifier found
    CALL    L_NEXTCHAR_DECE
    JP      -							;brif E >= 0
; Device Specifier NOT found.
; string ptr on stack
L_DEVTST_0:
    MOV     E,D							;restore length of string
    POP     H							;restore txt ptr
    XRA     A
	RST38H	2AH							;RST 38H Vector entry based on argument
    RET

L_NM_ERR:
	RST38H	2EH
    JMP     R_GEN_NM_ERR_FUN			;Generate NM error
;
; Device Specifier found
; string ptr on stack
;
L_DEVSPEC_FND:
    MOV     A,D							;A = original length of string
    SUB     E							;	- remaining length of string - 1
    DCR     A
    CPI     02H
    JNC     +							;brif A >= 2
	RST38H	2CH
    JMP     R_GEN_NM_ERR_FUN			;Generate NM error

+	CPI     05H							;length
    JNC     R_GEN_NM_ERR_FUN			;brif if A >= 5: Generate NM error 
    POP     B							;restore string ptr
    PUSH    D							;DE to stack
    PUSH    B							;save string ptr
    MOV     C,A							;count
    MOV     B,A							;saved count
    LXI     D,R_DEV_NAME_TBL			;Code Based.
										;	DE: "LCD","CRT","CAS","COM","WAND","LPT","MDM","RAM"
    XTHL								;swap HL with saved string ptr
    PUSH    H							;save string ptr	
;
; on stack
;	string Ptr
;	HL
;	DE
;		
LOOP_DEVNAME:
	CALL    R_CONV_M_TOUPPER			;Get char at M and convert to uppercase
    PUSH    B							;save BC: string length
    MOV     B,A							;uppercase char
    LDAX    D							;Code Based. from DEVNAMES
    INX     H							;next string ptr
    INX     D							;next DEVNAME ptr
    CMP     B
    POP     B							;restore BC
    JNZ     L_DEVNAME_NOMATCH			;brif A != B
    DCR     C							;count
    JNZ     LOOP_DEVNAME
L_DEVSPEC_0:							;DEVNAME partial match
    LDAX    D							;DEVNAME device code
    ORA     A
    JM      +							;brif DEVNAME device code bit 7 set
    CPI     '1'
    JNZ     L_DEVNAME_NOMATCH			;brif DEVNAME device code != '1'
;
; since '1' is not in the DEVNAMEs table, must be old test code
;
    INX     D							;next
    LDAX    D							;load to D
    JMP     L_DEVNAME_NOMATCH
;
; successful DEVNAME match
;
+	POP     H							;string ptr
    POP     H							;HL
    POP     D							;DE
    ORA     A
    RET
;
; no DEVNAME match. Find next DEVNAME
;
L_DEVNAME_NOMATCH:
    ORA     A							;test if char == DEVNAME device code
    JM      L_DEVSPEC_0					;brif device code
-	LDAX    D							;get char
    ORA     A
    INX     D							;next
    JP      -							;brif !device code
; found a device code
    MOV     C,B							;restore count
    POP     H							;restore string ptr
    PUSH    H							;and save string ptr
    LDAX    D							;next char from DEVNAME table. DE not incremented
    ORA     A
    JNZ     LOOP_DEVNAME				;brif not end of table
    JMP     R_GEN_NM_ERR_FUN			;Generate NM error
;
; Device name table
;
R_DEV_NAME_TBL:							;50F1H
    DB  "LCD", LCD_DEV	
    DB  "CRT", CRT_DEV	
    DB  "CAS", CAS_DEV	
    DB  "COM", COM_DEV	
    DB  "WAND", WAND_DEV
    DB  "LPT", LPT_DEV	
    DB  "MDM", MDM_DEV
    DB  "RAM", RAM_DEV
    DB	0
;
; Device control block vector addresses table
;
; Each DCB may have upto 5 functions:
;	0	Open
;	2	Close
;	4	Out
;	6	In
;	8	IO
;
R_DCB_VCTR_TBL:							;5113H
    DW      R_LCD_DCB, R_CRT_DCB, R_CAS_DCB
    DW      R_COM_DCB, R_BCR_DCB, R_LPT_DCB
    DW      R_MDM_DCB, R_RAM_DCB
;
; L_EXEC_DCB_FUNC
;
; HL, DE, BC pushed on stack
;
; IN:
;	HL			;FCB ptr
;	DE			;E has function code
;	A			DCB function (word corrected)
;
L_EXEC_DCB_FUNC:
	RST38H	30H
    PUSH    H							;save FCB ptr
    PUSH    D							;save DE. E has function code
    PUSH    PSW							;save DCB function
    LXI     D,DEV_IN_FCB_OFS
    DAD     D							;index to device code
    MVI     A,0FFH						;0FFH - device code => index into R_DCB_VCTR_TBL
    SUB     M
    ADD     A							;double
    MOV     E,A							;offset
    MVI     D,00H						;zero extend
    LXI     H,R_DCB_VCTR_TBL			;Code Based. 
    DAD     D							;index into R_DCB_VCTR_TBL
	GETDEFROMMNOINC						;DCB function block: Code Based. 
    POP     PSW							;restore DCB function
    MOV     L,A							;zero extend DCB function into HL
    MVI     H,00H
    DAD     D							;index into DCB function block
	GETDEFROMMNOINC						;function
    XCHG								;action to HL
    POP     D							;restore. E has function code
    XTHL								;action to stack, restore FCB ptr
    RET									;jump to function

	if HWMODEM
;
; TELCOM Entry point
;
R_TELCOM_ENTRY:							;5146H
    CALL    R_RESUME_AUTO_SCROLL     	;Resume automatic scrolling
    LXI     H,R_TELCOM_LABEL_TXT		;Code Based.
    CALL    R_SET_DISP_FKEY				;Set and display function keys (M has key table)
    JMP     R_PRINT_TELCOM_STAT      	;Print current STAT settings

L_TELCOM_ERR:
    CALL    R_BEEP_STMT				    ;BEEP statement
    LXI     H,R_TELCOM_LABEL_TXT
    CALL    R_SET_FKEYS				    ;Set new function key table
;
; Re-entry point for TELCOM commands
;
R_TELCOM_RE_ENTRY:						;515BH
    CALL    L_RESET_SP_0				;Stop BASIC, Restore BASIC SP
    LXI     H,L_TELCOM_ERR
    SHLD    ACTONERR_R					;active ON ERROR handler vector
    LXI     H,L_TELCOM_MSG				;Code Based.
    CALL    R_PRINT_STRING_2			;Print_2 buffer at M until NULL or '"'
    CALL    R_INP_DISP_LINE_NO_Q     	;Input and display (no "?") line and store
    CHRGET								;Get next non-white char from M
    ANA     A
    JZ      R_TELCOM_RE_ENTRY			;Re-entry point for TELCOM commands
    LXI     D,R_TELCOM_CMD_VCTR_TBL		;Code Based.
    CALL    L_TELCOM_EXEC_CMD
    JZ      L_TELCOM_ERR
    RET

L_TELCOM_MSG:
    DB      "Telcom: ",00H
;
; TELCOM command vector table
;
R_TELCOM_CMD_VCTR_TBL:				    ;5185H
    DB      "STAT"
    DW      R_TELCOM_STAT_FUN		 	;51C0H
    DB      "TERM"
    DW      R_TELCOM_TERM_FUN		 	;5455H
    DB      "CALL"
    DW      R_TELCOM_CALL_FUN		 	;522FH
    DB      "FIND"
    DW      R_TELCOM_FIND_FUN		 	;524DH
    DB      "MENU"
    DW      R_MENU_ENTRY			 	;5797H
    DB      0FFH
;
; TELCOM label line text table
;
R_TELCOM_LABEL_TXT:						;51A4H
    DB      "Find",0A0H
    DB      "Call",0A0H
    DB      "Stat",0A0H
    DB      "Term",8DH
    DB      80H
    DB      80H
    DB      80H
    DB      "Menu",8DH
;
; TELCOM STAT instruction routine
;
R_TELCOM_STAT_FUN:						;51C0H
    DCX     H
    CHRGET								;Get next non-white char from M. Returns Carry flag if Numeric. Zero flag if 0.
    INR     A							;check for string after "STAT"
    DCR     A
    JNZ     R_SET_TELCOM_STAT			;Set STAT and return to TELCOM ready
;
; Print current STAT settings
;
R_PRINT_TELCOM_STAT:				    ;51C7H
    LXI     H,SERMOD_R				    ;Serial initialization string
    MVI     B,05H
-	MOV     A,M
    OUTCHR								;Send character in A to screen/printer
    INX     H
    DCR     B
    JNZ     -
    MVI     A,','
    OUTCHR								;Send character in A to screen/printer
    LDA     MDMSPD_R					;Dial speed (1=10pps), 2=20pps
    RRC									;bit 0 to carry
    MVI     A,'2'						;32H
    SBB     B							;B == 0
    OUTCHR								;Send character in A to screen/printer
    LXI     H,L_PPS_MSG					;Code Based.
    CALL    R_PRINT_STRING				;Print buffer at M until NULL or '"'
    JMP     R_TELCOM_RE_ENTRY			;Re-entry point for TELCOM commands

L_PPS_MSG:
    DB      "0 pps",00H
;
; Set STAT and return to TELCOM ready
;
; IN: carry means CHRGET returned Numeric
;
R_SET_TELCOM_STAT:						;51EDH
    JC      +							;brif numeric char 
    CPI     ','
    JZ      L_SET_STAT_1
    CALL    R_CONV_A_TOUPPER			;Convert A to uppercase
    CPI     'M'							;4DH
    JNZ     L_TELCOM_ERR
    INX     H							;skip 'M'
+	CALL    R_SET_RS232_PARAMS       	;Set RS232 parameters from string at M
    CALL    R_UNINIT_RS232_MDM       	;Deactivate RS232 or modem
    DCX     H
    CHRGET								;Get next non-white char from M
    ANA     A
    JZ      R_TELCOM_RE_ENTRY			;Re-entry point for TELCOM commands
L_SET_STAT_1:
	SYNCHK	','
    CALL    L_GETBYT    				;Evaluate byte expression at M-1
    CPI     14H
    JZ      +
    SUI     0AH
    JNZ     L_TELCOM_ERR
    INR     A
+	STA     MDMSPD_R					;Dial speed (1=10pps), 2=20pps
    JMP     R_TELCOM_RE_ENTRY			;Re-entry point for TELCOM commands

L_TELCOM_CALL:
    LXI     H,L_CALLING_MSG				;Code Based.
    CALL    R_PRINT_STRING2				;Print NULL terminated string at M
    POP     D
    CALL    L_UTILS_FND_COLON
    JZ      L_TELCOM_ERR
    XCHG
	SKIP_XRA_A							;actually skip STC
;
; TELCOM CALL instruction routine
;
R_TELCOM_CALL_FUN:						;522FH
    STC
    PUSH    H
    LXI     H,L_CALLING_MSG				;Code Based.
    CC      R_PRINT_STRING2				;Print NULL terminated string at M
    POP     H
    CALL    R_EXEC_LOGON_SEQ			; Execute logon sequence at M
    JC      L_TELCOM_ERR
    JNZ     R_TELCOM_RE_ENTRY			;Re-entry point for TELCOM commands
    JMP     L_TELCOM_TERM_1

L_CALLING_MSG:
    DB      "Calling ",00H
;
; TELCOM FIND instruction routine
; text in buffer
;
R_TELCOM_FIND_FUN:						;524DH
    SUB     A							;fnd flag
    CALL    L_SET_UTILS_OUTPUT
    PUSH    H
    CALL    L_SEARCH_ADRS
    JZ      L_TELCOM_ERR
    CALL    R_GET_FILE_ADDR_PREINC_HL	;Get start address of file at M
    XCHG
    POP     H
-	CALL    R_FIND_TEXT_IN_FILE      	;Find text at M in the file at (DE)
    JNC     R_TELCOM_RE_ENTRY			;Re-entry point for TELCOM commands
    PUSH    H
    PUSH    D
    CALL    L_SET_UTIL_WIDTH
    CALL    L_UTILS_FND_COLON
    CNZ     L_UTILS_FND_AUTOLOG
    CALL    R_SEND_CRLF				    ;Send CRLF to screen or printer
    CALL    L_TELCOM_FOUND
    JZ      R_TELCOM_RE_ENTRY			;Re-entry point for TELCOM commands
    CPI     'C'							;43H
    JZ      L_TELCOM_CALL
    POP     D
    CALL    R_FIND_NEXT_LINE_IN_FILE 	;Increment DE past next CRLF in text file at (DE)
    POP     H
    JMP     -

L_UTILS_FND_COLON:
    CALL    L_CHK_UTILS_EOL
    RZ
    OUTCHR								;Send character in A to screen/printer
    CPI     ':'
    INX     D
    JNZ     L_UTILS_FND_COLON
; A == ':'
    JMP     L_CHK_UTILS_EOF				;TODO no purpose. Just ret

L_UTILS_FND_AUTOLOG:
    CALL    L_CHK_UTILS_EOL
    RZ
    CPI     '<'
    JZ      L_UTILS_DISP_AUTOLOG
    CPI     ':'
    RZ
    OUTCHR								;Send character in A to screen/printer
    INX     D
    JMP     L_UTILS_FND_AUTOLOG

L_UTILS_DISP_AUTOLOG:
    OUTCHR								;Send character in A to screen/printer
    MVI     A,'>'
    OUTCHR								;Send character in A to screen/printer
    RET

L_CHK_UTILS_EOL:
    CALL    R_CHECK_FOR_CRLF			;Check next byte(s) at (DE) for CRLF
    DCX     D							;backup ptr
    LDAX    D
    RZ									;retif NULL char	
L_CHK_UTILS_EOF:
    CPI     1AH							;^Z
    JZ      L_TELCOM_ERR
    RET
;
; Go off-hook
;
R_GO_OFFHOOK:							;52B4H
    INPORT	0BAH						;read 8155 PIO Port B
    ANI     7FH							;clear bit 7: RTS (not) line for RS232
    OUTPORT	0BAH						;set 8155 PIO Port B
    RET
;
; Disconnect phone line and disable modem carrier
;
R_DISCONNECT_PHONE:						;52BBH
    CALL    L_DIS_MODEM
    CALL    L_DIS_MODEM_RELAY
L_DISCONNECT_SERIAL:
    INPORT	0BAH						;read 8155 PIO Port B
    ORI     80H							;set bit 7: RTS (not) line for RS232
    OUTPORT	0BAH						;set 8155 PIO Port B
    RET

L_ENA_MODEM_RELAY:
    LDA     PORTA8_R					;Contents of port 0A8H
    ORI     01H							;set MODEM relay
    JMP     L_SET_MODEM
;
; Connect phone line and enable modem carrier
;
R_CONNECT_PHONE:						;52D0H
    CALL    R_GO_OFFHOOK				;Go off-hook
    MVI     A,03H						;bit 0: MODEM relay bit 1: MODEM ENABLE
    JMP     L_SET_MODEM

L_DIS_MODEM:
    LDA     PORTA8_R					;Contents of port 0A8H
    ANI     01H							;isolate bit 0/clear bit 1
L_SET_MODEM:
    STA     PORTA8_R					;Contents of port 0A8H
    OUTPORT	0A8H
    STC
    RET
;
; Go off-hook and wait for carrier
;
R_GO_OFFHOOK_WAIT:						;52E4H
    INPORT	0BBH						;read 8155 PIO Port C
    ANI     10H
    JZ      +
    CALL    R_CONNECT_PHONE				;Connect phone line and enable modem carrier
L_WAIT_CD:
    CALL    R_CHK_SHIFT_BREAK			;Check if SHIFT-BREAK is being pressed
    RC									;retif pressed
    CALL    R_CHECK_CD				    ;Check for carrier detect
    JNZ     L_WAIT_CD
    RET
+	CALL    L_ENA_MODEM_RELAY
    CALL    R_GO_OFFHOOK				;Go off-hook
    NOP    
    NOP    
    NOP    
    CALL    L_WAIT_CD
    RC									;retif Shift-Break pressed
    MVI     A,05H
    CALL    L_PAUSE						;pause
    CALL    R_CONNECT_PHONE				;Connect phone line and enable modem carrier
    ANA     A
    RET
;
; Pause for about 2 seconds
;
R_TELCOM_PAUSE:							;5310H
    XRA     A
    MVI     A,05H
-	CNZ     L_PAUSE_400MSEC				;skip first time through loop
L_PAUSE:								;Entry Point with A loaded.
    DCR     A
    JNZ     -
; Pause for about 400 mSeconds
L_PAUSE_400MSEC:
    MVI     C,200						;0C8H
-	CALL    L_PAUSE_1400uSec
    CALL    L_PAUSE_1400uSec
    DCR     C
    JNZ     -
; Pause 172 * (10 (DCR) + 10 (JNZ)) T-States = 3440 T-states (400 nSec) = 1.376 mSecs
L_PAUSE_1400uSec:
    MVI     B,172						;0ACH
-	DCR     B
    JNZ     -
    RET
;
; Execute logon sequence at M
;
R_EXEC_LOGON_SEQ:						;532DH
    INPORT	0BAH						;read 8155 PIO Port B
    PUSH    PSW							;save result
    ORI     08H							;00001000 set bit 3: Serial toggle (1-Modem, 0-RS232)
    OUTPORT	0BAH						;set 8155 PIO Port B
    CALL    R_DIALING_FUN				;Dialing routine. Returns carry
    POP     B							;last 8155 PIO Port B read
    PUSH    PSW							;save A/Flags
    MOV     A,B							;isolate bit 3 in B
    ANI     08H
    MOV     B,A
    INPORT	0BAH						;read 8155 PIO Port B
    ANI     0F7H						;11110111 clear bit 3
    ORA     B							;or in B bit 3
    OUTPORT	0BAH						;set 8155 PIO Port B
    POP     PSW							;restore A/Flags
    RNC									;retif carry not set
    CALL    R_DISCONNECT_PHONE       	;Disconnect phone line and disable modem carrier
    CALL    L_ENA_MODEM_RELAY
    MVI     A,03H
    CALL    L_PAUSE						;pause
L_DIS_MODEM_RELAY:
    LDA     PORTA8_R					;Contents of port 0A8H
    ANI     02H							;00000010 Isolate bit 1/Clear bit 0
    JMP     L_SET_MODEM
;
; Dialing routine
;
R_DIALING_FUN:							;5359H
    XRA     A
    STA     PORTA8_R					;clear Contents of port 0A8H
    CALL    L_DISCONNECT_SERIAL
    CALL    L_ENA_MODEM_RELAY
    CALL    L_PAUSE_400MSEC
    CALL    R_CONNECT_PHONE				;Connect phone line and enable modem carrier
    CALL    L_DIS_MODEM
    CALL    R_TELCOM_PAUSE				;Pause for about 2 seconds
    DCX     H
-	CALL    R_CHK_SHIFT_BREAK			;Check if SHIFT-BREAK is being pressed
    RC									;retif pressed
    PUSH    H
    XCHG
    CALL    R_CHECK_FOR_CRLF			;Check next byte(s) at (DE) for CRLF
    DCX     D
    LDAX    D
    POP     H
    JZ      R_AUTO_LOGIN_SEQ			;Auto logon sequence
    CPI     1AH							;ESC
    JZ      R_AUTO_LOGIN_SEQ			;Auto logon sequence
    CHRGET								;Get next non-white char from M
    JZ      R_AUTO_LOGIN_SEQ			;Auto logon sequence
    PUSH    PSW
    CC      R_DIAL_DIGIT				;Dial the digit in A & print on LCD
    POP     PSW
    JC      -
    CPI     '<'
    STC
    JZ      R_AUTO_LOGIN_SEQ			;Auto logon sequence
    CPI     '='
    CZ      R_TELCOM_PAUSE				;Pause for about 2 seconds
    JMP     -
;
;Auto logon sequence
;
R_AUTO_LOGIN_SEQ:						;539EH
    PUSH    PSW
    LDA     MDMSPD_R					;Dial speed (1=10pps), 2=20pps
    RRC									;bit 0 to carry
    CNC     L_PAUSE_400MSEC				;calif 
    POP     PSW
    JNC     R_DISCONNECT_PHONE       	;Disconnect phone line and disable modem carrier
    LDA     SERMOD_R					;Serial initialization string
    CPI     'M'
    STC
    RNZ									;retif first char != 'M'
    PUSH    H							;save HL
    LXI     H,SERMOD_R+1				;skip 'M'
    ANA     A							;clear carry
    CALL    R_SET_RS232_PARAMS       	;Set RS232 parameters from string at M
    MVI     A,04H
    CALL    L_PAUSE						;pause
    POP     H							;restore HL
    CALL    R_GO_OFFHOOK_WAIT			;Go off-hook and wait for carrier
    RC
L_AUTO_LOG_1:
    CALL    L_DRAIN_RS232_IN_QUEUE
    CALL    L_NXTCHR_FROM_M
    RZ									;retif 0
    CPI     '>'
    RZ
    CPI     '='
    JZ      L_AUTO_LOG_3
    CPI     '^'
    JZ      L_AUTO_LOG_5
    CPI     '?'
    JZ      L_AUTO_LOG_4
    CPI     '!'
    CZ      L_NXTCHR_FROM_M
    RZ
L_AUTO_LOG_2:
    CALL    R_SEND_A_USING_XON       	;Send character in A to serial port using XON/XOFF
    XRA     A
    INR     A
L_AUTO_LOG_3:
    CZ      R_TELCOM_PAUSE				;Pause for about 2 seconds
    JMP     L_AUTO_LOG_1

L_AUTO_LOG_4:
    CALL    L_NXTCHR_FROM_M
    RZ									;retif 0
-	CALL    R_READ_RS232_QUEUE       	;Get a character from RS232 receive queue
    RC									;retif SHIFT_BREAK 
    OUTCHR								;Send character in A to screen/printer
    CMP     M
    JNZ     -
    JMP     L_AUTO_LOG_1

L_AUTO_LOG_5:
    CALL    L_NXTCHR_FROM_M
    RZ									;retif char == 0
    ANI     1FH							;00011111
    JMP     L_AUTO_LOG_2

L_NXTCHR_FROM_M:
    INX     H
    MOV     A,M
    ANA     A
    RET
;
; Dial the digit in A & print on LCD
;
R_DIAL_DIGIT:							;540AH
    OUTCHR								;Send character in A to screen/printer
    DI 
    ANI     0FH
    MOV     C,A
    JNZ     L_DIAL_DIGIT_1
    MVI     C,0AH
L_DIAL_DIGIT_1:
    LDA     MDMSPD_R					;Dial speed (1=10pps), 2=20pps
    RRC
    LXI     D,161CH						;delay constants
    JNC     +
    LXI     D,2440H						;delay constants
+	CALL    L_DISCONNECT_SERIAL
-	CALL    L_PAUSE_1400uSec
    DCR     E
    JNZ     -
    CALL    R_GO_OFFHOOK				;Go off-hook
-	CALL    L_PAUSE_1400uSec
    DCR     D
    JNZ     -
    DCR     C
    JNZ     L_DIAL_DIGIT_1
    EI     
    LDA     MDMSPD_R					;Dial speed (1=10pps), 2=20pps
    ANI     01H
    INR     A
    JMP     L_PAUSE						;pause

	else								;HWMODEM
;
;Unused RAM locations if !HWMODEM
;
;	MDMSPD_R (0F62BH)	Dial speed (1=10pps), 2=20pps
;	PORTA8_R (0FAAEH)   Contents of port 0A8H
;
;
; TELCOM Entry point
;
R_TELCOM_ENTRY:							;5146H
    CALL    R_RESUME_AUTO_SCROLL     	;Resume automatic scrolling
    LXI     H,R_TELCOM_LABEL_TXT		;Code Based.
    CALL    R_SET_DISP_FKEY				;Set and display function keys (M has key table)
    JMP     R_PRINT_TELCOM_STAT      	;Print current STAT settings

L_TELCOM_ERR:
    CALL    R_BEEP_STMT				    ;BEEP statement
    LXI     H,R_TELCOM_LABEL_TXT		;Code Based.
    CALL    R_SET_FKEYS				    ;Set new function key table
;
; Re-entry point for TELCOM commands
;
R_TELCOM_RE_ENTRY:						;515BH
    CALL    L_RESET_SP_0				;Stop BASIC, Restore BASIC SP
    LXI     H,L_TELCOM_ERR
    SHLD    ACTONERR_R					;active ON ERROR handler vector
    LXI     H,R_TELCOM_TXT				;Code Based.
    CALL    R_PRINT_STRING_2			;Print_2 buffer at M until NULL or '"'
    CALL    R_INP_DISP_LINE_NO_Q     	;Input and display (no "?") line and store
    CHRGET								;Get next non-white char from M
    ANA     A
    JZ      R_TELCOM_RE_ENTRY			;Re-entry point for TELCOM commands
    LXI     D,R_TELCOM_CMD_VCTR_TBL		;Code Based.
    CALL    L_TELCOM_EXEC_CMD
    JZ      L_TELCOM_ERR
    RET

R_DISCONNECT_PHONE:
	RET

R_TELCOM_TXT:
    DB      "Telcom: ",00H
;
; TELCOM instruction vector table
;
R_TELCOM_CMD_VCTR_TBL:				    ;5185H
    DB      "STAT"
    DW      R_TELCOM_STAT_FUN
    DB      "TERM"
    DW      R_TELCOM_TERM_FUN		 	;5455H
    DB      "MENU"
    DW      R_MENU_ENTRY			 	;5797H
    DB      0FFH
;
; TELCOM label line text table
;
R_TELCOM_LABEL_TXT:
    DB      80H
    DB      80H
    DB      "Stat",0A0H
    DB      "Term",8DH
    DB      80H
    DB      80H
    DB      80H
    DB      "Menu",8DH
;
; TELCOM STAT instruction routine
;
R_TELCOM_STAT_FUN:
    DCX     H
    CHRGET								;Get next non-white char from M. Returns Carry flag if Numeric. Zero flag if 0.
    INR     A							;check for string after "STAT"
    DCR     A
    JNZ     R_SET_TELCOM_STAT			;Set STAT and return to TELCOM ready
;
; Print current STAT settings
;
R_PRINT_TELCOM_STAT:
    LXI     H,SERMOD_R				    ;Serial initialization string
    MVI     B,05H
-	MOV     A,M
    OUTCHR								;Send character in A to screen/printer
    INX     H
    DCR     B
    JNZ     -
    JMP     R_TELCOM_RE_ENTRY			;Re-entry point for TELCOM commands
;
; Set STAT and return to TELCOM ready
;
; IN: carry means CHRGET returned Numeric, HL
;
R_SET_TELCOM_STAT:
    JC		+							;brif numeric
    CALL    R_CONV_A_TOUPPER			;Convert A to uppercase
    CPI     'M'							;use modem
    JNZ     L_TELCOM_ERR
    INX     H
+	CALL    R_SET_RS232_PARAMS       	;Set RS232 parameters from string at M
    CALL    R_UNINIT_RS232_MDM       	;Deactivate RS232 or modem
    DCX     H
    CHRGET								;Get next non-white char from M
    ANA     A
    JMP     R_TELCOM_RE_ENTRY			;Re-entry point for TELCOM commands

R_END_MDM_PATCH:

	if	VT100INROM
	include "vt100inrom.asm"
	
R_END_VT100_PATCH:

	DS		5443H-R_END_VT100_PATCH		;fill gap 12 FREE CODE SPACE
	else								;VT100INROM
	DS		5443H-R_END_MDM_PATCH		;269H bytes (to update) 617 FREE CODE SPACE
	endif								;VT100INROM
	endif								;HWMODEM

L_TERM_FUN_KEYS:						;5443H
    DB      "Pre",80H | 'v'				;0F6H
    DB      "Dow",80H | 'n'				;0EEH
    DB      " U",80H | 'p'				;0F0H
    DB      80H
    DB      80H
    DB      80H
    DB      80H
    DB      "By",80H | 'e'				;0E5H
	
;
; TELCOM TERM instruction routine
; Serial initialization string starting with 'M' means modem
;
R_TELCOM_TERM_FUN:						;5455H
    LXI     H,SERMOD_R-1				;Serial initialization string-1
    CHRGET								;Get next non-white char from M. Return Carry if numeric (terminal)
    CNC     L_INCHL						;Increment HL. Carry unaffected. Skip 'M' if present
    PUSH    PSW							;save Carry (set if numeric)
    CALL    R_SET_RS232_PARAMS			;Set RS232 parameters from string at M
    POP     PSW							;restore carry
    CMC									;complement carry => Carry clear if numeric, set if modem
	if	HWMODEM
    CC      R_GO_OFFHOOK_WAIT			;Go off-hook and wait for carrier if Modem.
	else
    CALL    R_CHK_SHIFT_BREAK			;Check if SHIFT-BREAK is being pressed
	endif
    JC      L_TELCOM_DISCNNCT			;carry if SHIFT-BREAK pressed
L_TELCOM_TERM_1:
    MVI     A,40H						;set TELCOM mode
    STA     FNKMOD_R					;Function key mode/ BIT 7=in TEXT (0x80); BIT 6=in TELCOM (0x40)
    STA     CURLIN_R+1					;MSB of CURLIN_R
    XRA     A
    STA     SER_UPDWN_R					;clear
    STA     SER_UPDWN_R+1
    CALL    L_CLR_ALTLCD
	LXI     H,L_TERM_FUN_KEYS			;Code Based.
    CALL    R_SET_FKEYS				  	;Set new function key table
    CALL    L_TELCOM_FULL_1
    CALL    L_TELCOM_ECHO_1
    CALL    L_TELCOM_ECHO_2
    CALL    R_DISP_FKEY_LINE			;Display function key line
    CALL    R_TURN_CURSOR_ON			;Turn the cursor on
L_TELCOM_TERM_2:
    CALL    L_RESET_SP					;Restore BASIC SP
    LXI     H,L_TELCOM_TERM_4			;continuation function
    SHLD    ACTONERR_R					;active ON ERROR handler vector
    LDA     XONFLG_R					;XON/XOFF enable flag
    ANA     A
    JZ      L_TERMLOOP
    LDA     XONXOFF_R					;XON/XOFF protocol control
    LXI     H,FNKSTR_R+50H				;F6
    XRA     M
    RRC
    CC      L_TELCOM_ECHO_2
L_TERMLOOP:								;check for keyboard character
    CALL    R_CHK_KEY_QUEUE				;Check keyboard queue for pending characters
    JZ      +							;brif no key available
    CALL    R_WAIT_KEY					;Wait for key from keyboard
    JC      R_TELCOM_DISPATCH			;TELCOM "dispatcher" routine
    MOV     B,A							;save character
    LDA     DUPLEX_R					;Full/Half duplex switch
    ANA     A
    MOV     A,B							;reload character
    CZ      R_SEND_A_LCD_LPT 			;Send A to screen or printer
    ANA     A							;test
    CNZ     R_SEND_A_USING_XON       	;Send key character in A to serial port using XON/XOFF
    JC      L_TELCOM_TERM_3
;check for incoming serial character
+	CALL    R_CHECK_RS232_QUEUE      	;Check RS232 queue for pending characters
    JZ      L_TELCOM_TERM_2
    CALL    R_READ_RS232_QUEUE       	;Get a character from RS232 receive queue
    JC      L_TELCOM_TERM_2
    OUTCHR								;Send character in A to screen/printer
    MOV     B,A
    LDA     ECHO_R
    ANA     A
    MOV     A,B
    CNZ     R_PRINT_A_EXPAND			; Print A to printer), expanding tabs if necessary
    CALL    L_TELCOM_DOWN_2
    JMP     L_TELCOM_TERM_2

L_TELCOM_TERM_3:
    XRA     A
    STA     XONXOFF_R					;XON/XOFF protocol control
-	CALL    R_CHK_SHIFT_BREAK			;Check if SHIFT-BREAK is being pressed
    JC      -							;brif pressed
    JMP     L_TELCOM_TERM_2

L_TELCOM_TERM_4:
    CALL    R_BEEP_STMT				    ;BEEP statement
    XRA     A
    STA     ECHO_R
    CALL    L_TELCOM_ECHO_1
    JMP     L_TELCOM_TERM_2
;
; TELCOM "dispatcher" routine
;
R_TELCOM_DISPATCH:						;54FCH
    MOV     E,A							;index
    MVI     D,0FFH						;negative
    LXI     H,R_TERM_FKEY_VCTR_TBL+2*8	;Code Based.
										;	Beyond TERM Mode function key vector table
    DAD     D
    DAD     D
	GETHLFROMM							;get ptr to HL
    LXI     D,L_TELCOM_TERM_2					;continuation function
    PUSH    D
    PCHL   
;
; TERM Mode function key vector table
;
R_TERM_FKEY_VCTR_TBL:				    ;550DH
    DW      R_TELCOM_PREV_FUN, R_TELCOM_DOWN_FUN, R_TELCOM_UP_FUN
    DW      R_TELCOM_FULL_FUN, R_TELCOM_ECHO_FUN, R_TERM_FKEY_VCTR_F6
    DW      R_TERM_FKEY_VCTR_F7, R_TELCOM_BYE_FUN
;TERM Mode function key vector table
R_TERM_FKEY_VCTR_F6:
	RST38H	32H
	RET
	
R_TERM_FKEY_VCTR_F7:
	RST38H	34H
    RET
;
; TELCOM PREV function routine
;
R_TELCOM_PREV_FUN:						;5523H
    CALL    L_POPPSW					;Conditionally POP PSW from stack based on value at POPPSW_R
    CALL    R_TURN_CURSOR_OFF			;Turn the cursor off
    CALL    L_ALTLCDrefresh
-	CALL    R_CHK_KEY_QUEUE				;Check keyboard queue for pending characters
    JZ      -
    CALL    R_WAIT_KEY				    ;Wait for key from keyboard
    CALL    L_LCDrefresh
    CALL    R_TURN_CURSOR_ON			; Turn the cursor on
    JMP     R_SEND_ESC_X				;Send ESC X
;
; TELCOM FULL/HALF function routine
;
R_TELCOM_FULL_FUN:						;553EH
    LXI     H,DUPLEX_R				  	;Full/Half duplex switch
    MOV     A,M
    CMA									;complement
    MOV     M,A
L_TELCOM_FULL_1:
    LDA     DUPLEX_R					;Full/Half duplex switch
    LXI     D,FNKSTR_R+30H				;F4
    LXI     H,L_FULLHALF_MSG			;Code Based.
    JMP     L_TELCOM_ECHO_3
;
; TELCOM ECHO function routine
;
R_TELCOM_ECHO_FUN:						;5550H
    LXI     H,ECHO_R
    MOV     A,M
    CMA									;complement
    MOV     M,A
L_TELCOM_ECHO_1:
    LDA     ECHO_R
    LXI     D,FNKSTR_R+40H				;F5
    LXI     H,L_ECHO_MSG				;Code Based.
    JMP     L_TELCOM_ECHO_3

L_TELCOM_ECHO_2:
    LDA     XONXOFF_R					;XON/XOFF protocol control
    LXI     D,FNKSTR_R+50H				;F6
    LXI     H,L_WAIT_MSG				;Code Based.
;
; Update Function Keys Labels
;
L_TELCOM_ECHO_3:
    ANA     A							;[DUPLEX_R] or [ECHO_R] or [XONXOFF_R]
    LXI     B,0004H
    JNZ     +
    DAD     B							;add 4 to HL: Full=>Half, Echo=>"    ", Wait=>" \0  "
+	MOV     B,C							;4
    CALL    R_MOVE_B_BYTES				;Move 4 bytes from M to (DE)
    MVI     B,12						;0CH
R_CLR_B_BYTES:							;clear B bytes at (DE)
    XRA     A
-	STAX    D
    INX     D
    DCR     B
    JNZ     -
    JMP     R_DISP_FKEYS				;Display function keys on 8th line

L_FULLHALF_MSG:
    DB      "FullHalf"
L_ECHO_MSG:
    DB      "Echo    "
L_NEWLINE_MSG:
    DB      0DH," "
L_WAIT_MSG:
    DB      "Wait ",00H,"  "
;
; TELCOM UPLOAD function routine
;
R_TELCOM_UP_FUN:						;559DH
    LXI     H,L_UP_ABORTED				;continuation function
    SHLD    ACTONERR_R					;active ON ERROR handler vector
    PUSH    H
    LDA     SER_UPDWN_R
    ANA     A
    RNZ
    CALL    LNKFIL						;Fix up the directory start pointers
    LXI     H,L_FileToUpload_MSG		;Code Based.
    CALL    R_PRINT_STRING_2			;Print_2 buffer at M until NULL or '"'
    CALL    R_INP_DISP_LINE				;Input and display line and store
    CHRGET								;Get next non-white char from M
    ANA     A
    RZ
    STA     TLCMKEY_R
    CALL    R_STRLEN				    ;Count length of string at M
    CALL    L_PSH_HL_EVAL_FILNAM		;push HL and eval Filename
    RNZ
    CALL    R_FINDFILE
    LXI     H,L_NoFile_MSG				;Code Based.
    JZ      R_PRINT_STRING_2			;Print_2 buffer at M until NULL or '"'
    XCHG
    XTHL
    PUSH    H
    LXI     H,L_Width_MSG				;Code Based. 
    CALL    R_PRINT_STRING_2			;Print_2 buffer at M until NULL or '"'
    CALL    R_INP_DISP_LINE_NO_Q		;Input and display (no "?") line and store
    RC
    CHRGET								;Get next non-white char from M
    ANA     A
    MVI     A,01H
    STA     SER_UPDWN_R+1
    STA     LCDPRT_R					;LCD vs Printer output indication - output to LCD
    JZ      +
    CALL    L_GETBYT					;Evaluate byte expression at M-1
    CPI     0AH
    RC
    CPI     85H
    RNC
    LXI     H,LINBUF_R
    SHLD    CURPOS_R
    STA     OUTFMTWIDTH_R				;Output format width (40 or something else for CTRL-Y)
    STA     SER_UPDWN_R+1
    POP     PSW
    POP     D
	SKIP_2BYTES_INST_BC					;skip POP PSW & POP H
+	POP     PSW
    POP     H
    PUSH    D
    PUSH    H
    CALL    R_DISP_FKEYS				;Display function keys on 8th line
    POP     H
    POP     D
L_TELCOM_UP_1:
    LDA     SER_UPDWN_R+1
    DCR     A
    JZ      L_TELCOM_UP_2
    PUSH    D
    XCHG
    LHLD    CURPOS_R
    XCHG
    COMPAR								;HL - DE
    POP     D
    JNZ     L_TELCOM_UP_2
    CALL    L_BDL_LINE_DE				;Build next line from .DO file at (DE) into line buffer
    MOV     A,D							;test DE for 0FFFFH
    ANA     E
    INR     A
    JNZ     +							;brif ! EOF
; EOF reached
    LHLD    CURPOS_R
    MVI     M,1AH						;set [CURPOS_R] to ^Z
    INX     H
    SHLD    CURPOS_R
+	LXI     H,LINBUF_R
L_TELCOM_UP_2:
    MOV     A,M							;get char
    CPI     1AH							;^Z
	RST38H	36H
    JZ      L_TELCOM_UP_3						;brif A == 1AH
    CPI     0AH							;LF
    JNZ     +							;brif A != 0AH
    LDA     LFFLG_R						;RS232 auto linefeed switch
    ANA     A
    JNZ     +							;brif LFFLG_R != 0
    LDA     TLCMKEY_R
    CPI     0DH							;CR
+	MOV     A,M
    STA     TLCMKEY_R					;update
    JZ      +
    CALL    R_SEND_A_USING_XON       	;Send character in A to serial port using XON/XOFF
    CALL    L_DRAIN_RS232_IN_QUEUE
+	INX     H
    CALL    R_CHK_KEY_QUEUE				;Check keyboard queue for pending characters
    JZ      L_TELCOM_UP_1
    CALL    R_WAIT_KEY				    ;Wait for key from keyboard
    CPI     03H							;^C
    JZ      L_TELCOM_UP_3				;brif ^C
    CPI     13H
    CZ      R_WAIT_KEY				    ;Wait for key from keyboard
    CPI     03H
    JNZ     L_TELCOM_UP_1
L_TELCOM_UP_3:
    XRA     A
    STA     SER_UPDWN_R+1
    JMP     R_DISP_FKEYS				;Display function keys on 8th line

L_DRAIN_RS232_IN_QUEUE:
    CALL    R_CHECK_RS232_QUEUE      	;Check RS232 queue for pending characters
    RZ									;retif empty
    CALL    R_READ_RS232_QUEUE       	;Get a character from RS232 receive queue
    OUTCHR								;Send character in A to screen/printer
    JMP     L_DRAIN_RS232_IN_QUEUE
;
; TELCOM DOWNLOAD function routine
;
R_TELCOM_DOWN_FUN:						;567EH
    CALL    LNKFIL						;Fix up the directory start pointers
    LDA     SER_UPDWN_R
    XRI     0FFH						;Flip
    STA     SER_UPDWN_R
    JZ      L_TELCOM_DOWN_1				;brif SER_UPDWN_R == 0
    LXI     H,L_TELCOM_DOWN_4			;error handler
    SHLD    ACTONERR_R					;active ON ERROR handler vector
    PUSH    H
    LXI     H,L_FileToDownload_MSG		;Code Based.
    CALL    R_PRINT_STRING_2			;Print_2 buffer at M until NULL or '"'
    CALL    R_INP_DISP_LINE				;Input and display line and store
    CHRGET								;Get next non-white char from M
    ANA     A
    RZ
    STA     TLCMKEY_R					;update with non-zero value
    POP     PSW
-	PUSH    H
    CALL    R_GET_FIND_DO_FILE       	;Get .DO filename and locate in RAM directory
    JC      +
    SHLD    DOFILPTR_R					;ptr to DO file
    CALL    L_FNDEOFTXT					;Find EOF at HL Text Line
    POP     PSW
    CALL    L_EXPND_DO					;Expand .DO file so it fills all memory for editing
    JMP     R_DISP_FKEYS				;Display function keys on 8th line

+	XCHG
    CALL    KILASC						;kill text file:  DE & HL are inputs
    POP     H
    JMP     -

L_TELCOM_DOWN_1:
    CALL    R_DISP_FKEYS				;Display function keys on 8th line
    JMP     L_DEL_ZEROS					;Delete zeros from end of edited DO file and update pointers

L_TELCOM_DOWN_2:
    MOV     C,A
    LDA     SER_UPDWN_R
    ANA     A
    MOV     A,C
    RZ
    CALL    L_IS_CTRL_CHAR
    RZ
    JNC     L_TELCOM_DOWN_3
    CALL    L_TELCOM_DOWN_3
    MVI     A,0AH
L_TELCOM_DOWN_3:
    LHLD    DOFILPTR_R					;get ptr to DO file
    CALL    L_INSRT_DO					;Insert byte in A to .DO file at address HL.
    SHLD    DOFILPTR_R					;update ptr to DO file
    RNC
L_TELCOM_DOWN_4:						;Error handler
    XRA     A
    STA     SER_UPDWN_R
    CALL    R_DISP_FKEYS				;Display function keys on 8th line
    LXI     H,L_Download_MSG			;Code Based.
    JMP     +							;Aborted Message

L_UP_ABORTED:
    LXI     H,L_Upload_MSG				;Code Based.
+	CALL    R_PRINT_STRING_2			;Print_2 buffer at M until NULL or '"'
    LXI     H,L_Aborted_MSG				;Code Based.
    CALL    R_PRINT_STRING				;Print buffer at M until NULL or '"'
    JMP     L_TELCOM_TERM_2

L_IS_CTRL_CHAR:
    MOV     C,A							;save char
    ANA     A							;test it
    RZ
    CPI     1AH							;^Z
    RZ
    CPI     7FH							;DEL
    RZ
    CPI     0AH							;LF
    JNZ     +							;brif A != Linefeed
    LDA     TLCMKEY_R
    CPI     0DH							;CR
+	MOV     A,C							;restore
    STA     TLCMKEY_R
    RZ
    CPI     0DH							;CR
    STC									;clear carry
    CMC
    RNZ
    ANA     A
    STC									;set carry
    RET
;
; TELCOM BYE function routine
;
R_TELCOM_BYE_FUN:						;571EH
    LXI     H,L_Disconnect_MSG			;Code Based.
    CALL    R_PRINT_STRING_2			;Print_2 buffer at M until NULL or '"'
    CALL    R_INP_DISP_LINE				;Input and display line and store
    CHRGET								;Get next non-white char from M
    CALL    R_CONV_A_TOUPPER			;Convert A to uppercase
    CPI     'Y'
    JZ      L_TELCOM_DISCNNCT
    LXI     H,L_Aborted_MSG				;Code Based.
    CALL    R_PRINT_STRING_2			;Print_2 buffer at M until NULL or '"'
    JMP     L_TELCOM_TERM_2

L_TELCOM_DISCNNCT:
    XRA     A
    STA     FNKMOD_R					;Clear function key mode/ BIT 7=in TEXT (0x80), BIT 6=in TELCOM (0x40)
    MOV     L,A							;Clear HL
    MOV     H,A
    SHLD    SER_UPDWN_R
    CALL    R_UNINIT_RS232_MDM       	;Deactivate RS232 or modem
    CALL    R_TURN_CURSOR_OFF			;Turn the cursor off
    CALL    R_DISCONNECT_PHONE       	;Disconnect phone line and disable modem carrier
    CALL    L_FND_END_DO_FILES
    JMP     R_TELCOM_ENTRY				;TELCOM Entry point

L_FileToUpload_MSG:
    DB      "File to "
L_Upload_MSG:
    DB      "Upload",00H

L_FileToDownload_MSG:
    DB      "File to "
L_Download_MSG:
    DB      "Download",00H

L_Aborted_MSG:
    DB      " aborted",0DH,0AH,00H

L_NoFile_MSG:
    DB      "No file",0DH,0AH,00H

L_Disconnect_MSG:
    DB      "Disconnect",00H

;
; Print_2 buffer at M until NULL or '"'
;
R_PRINT_STRING_2:						;5791H
    CALL    R_LCD_NEW_LINE				;Move LCD to blank line (send CRLF if needed)
    JMP     R_PRINT_STRING				;Print buffer at M until NULL or '"'
;
; MENU Program
;
R_MENU_ENTRY:							;5797H
    LHLD    MEMSIZ_R					;File buffer area pointer. Also end of Strings Buffer Area.
    SHLD    STRBUF_R					;BASIC string buffer pointer
    CALL    R_INIT_BASIC_VARS_2			;Initialize BASIC variables for new execution
    CALL    R_UNINIT_RS232_MDM       	;Deactivate RS232 or modem
    CALL    L_FND_END_DO_FILES
    CALL    LNKFIL						;Fix up the directory start pointers
    CALL    R_INV_CHAR_DISABLE       	;Cancel inverse character mode
    CALL    R_TURN_CURSOR_OFF			;Turn the cursor off
    CALL    R_ERASE_FKEY_DISP			;Erase function key display
    CALL    R_STOP_AUTO_SCROLL       	;Stop automatic scrolling
    LDA     CONDEV_R					;New Console device flag
    STA     TMPCONDEV_R					;temporary Console device flag
    MVI     A,0FFH
    STA     UNUSED5_R
    INR     A							;A now 0
    STA     FNKMOD_R					;Function key mode/ BIT 7=in TEXT (0x80); BIT 6=in TELCOM (0x40)
    STA     LINENA_R					;clear Label line enable flag
    CALL    L_SCREEN_STMT_1				;arg A == 0
    CALL    L_RESET_SP_1				;Stop BASIC, Restore BASIC SP &	clear SHIFT-PRINT Key
    LXI     H,R_MENU_ENTRY				;Set MENU program as the ON ERROR handler
    SHLD    ACTONERR_R					;Save as active ON ERROR handler vector
    CALL    R_CLEAR_FKEY_TBL			;Clear function key definition table
    CALL    R_CLS_PRINT_TIME_DAY     	;Print time, day and date on first line of screen
    LXI     H,1C01H						;Row 28, column 1
    CALL    R_SET_CURSOR_POS			;Set the current cursor position
    LXI     H,L_MSFT_MSG				;Code Based. Microsoft string
    CALL    R_PRINT_STRING2				;Print NULL terminated string at M
    LXI     H,MNU2RAM_R				    ;Map of MENU entry positions to RAM directory positions
    SHLD    TMP_UTIL_R
    MVI     B,RAMDIRCNT*2				;54 => 27 items
-	MVI     M,0FFH						;initialize the map
    INX     H
    DCR     B
    JNZ		-
    MOV     L,B							;B == 0
    LXI     D,R_DIR_DISP_ORDER_TBL   	;Code Based. Directory file-type display order table
;
; Display directory entries
;
; IN:
;	DE
;
;
R_DISP_DIR:								;57F8H
    LDAX    D
    ORA     A
    JZ      +							;brif [DE] == 0
    MOV     C,A
    PUSH    D
    CALL    R_DISP_DIR_TYPE_C			;Display directory entries of type in register C
    POP     D
    INX     D
    JMP     R_DISP_DIR				    ;loop
+	MOV     A,L
    DCR     A
    STA     MENMAX_R					;Maximum MENU directory location
    CPI     17H							;23
    JZ      +
-	CALL    R_NEXT_DIR_ENTRY			;Position cursor for next directory entry
    PUSH    H							;save HL
    LXI     H,L_NOENTRY_MSG				;Code Based.
    CALL    R_PRINT_STRING2				;Print NULL terminated string at M
    POP     H							;restore HL
    INR     L
    MOV     A,L
    CPI     18H							;24
    JNZ     -
+	SUB     A							;clear A
    STA     STRNAM_R
    STA     MENPOS_R					;Current MENU directory location
    MOV     L,A							;L == 0
    CALL    L_REV_VID_FNAME
    LXI     H,1808H						;H == 24, L == 8
    CALL    R_SET_CURSOR_POS			;Set the current cursor position
    CALL    R_DISP_FREE_BYTES			;Display number of free bytes on LCD
;
; Handle CTRL-U key from MENU command loop
;
R_MENU_CTRL_U_HANDLER:					;5837H
    CALL    L_RESET_SP_1				;Stop BASIC, Restore BASIC SP &	clear SHIFT-PRINT Key
    LXI     H,L_MENU_CTRLU_HANDLER		;error handler
    SHLD    ACTONERR_R					;active ON ERROR handler vector
    LXI     H,0108H						;Row 1, Column 1
    CALL    R_SET_CURSOR_POS			;Set the current cursor position
    LXI     H,L_Select_MSG				;Code Based. 
    CALL    R_PRINT_STRING2				;Print NULL terminated string at M
    LXI     H,0908H						;Row 9, column 9
    CALL    R_SET_CURSOR_POS			;Set the current cursor position
    SUB     A							;clear A
    STA     MENUCMD_R					;Menu command entry count: clear
    LXI     H,STRNAM_R
    INR     A							;A now 1
;
; MENU Program command loop
;
R_MENU_CMD_LOOP:						;585AH
    CZ      R_BEEP_STMT					;BEEP statement
L_MENU_CMD_LOOP_NOBEEP:					;also continuation function
    CALL    R_PRINT_TIME_LOOP			;Print time on top line until key pressed
    CALL    R_GET_KEY_CONV_TOUPPER     	;Wait for char from keyboard & convert to uppercase
    CPI     0DH							;CR
    JZ      R_MENU_ENTER_HANDLER       	;Handle ENTER key from MENU command loop
    CPI     08H							;BKSP
    JZ      R_MENU_BKSP_HANDLER        	;Handle Backspace key from MENU command loop
    CPI     7FH							;DEL
    JZ      R_MENU_BKSP_HANDLER        	;Handle Backspace key from MENU command loop
    CPI     15H							;^U
    JZ      R_MENU_CTRL_U_HANDLER      	;Handle CTRL-U key from MENU command loop
    CPI     ' '
    JC      L_MENU_HANDLER_1			;brif A < ' '. A is argument
    MOV     C,A
    LDA     MENUCMD_R					;Menu command entry count
    CZ      + 
	CPI     09H							;TAB
    JZ      R_MENU_CMD_LOOP				;MENU Program command loop
    CALL    L_CMD_CHAR					;store char as a command
    JMP     L_MENU_CMD_LOOP_NOBEEP
;
; Handle Backspace key from MENU command loop
;
R_MENU_BKSP_HANDLER:				    ;588EH
    CALL    L_RUBOUT_CMD
    JZ      R_MENU_CMD_LOOP				;MENU Program command loop
    JMP     L_MENU_CMD_LOOP_NOBEEP

+	ORA     A
    RNZ
    POP     PSW
    MVI     A,1CH						;28
L_MENU_HANDLER_1:
    PUSH    PSW							;save A
    LDA     MENPOS_R					;Current MENU directory location
    MOV     E,A							;to E
    POP     PSW							;restore A
    SUI     1CH							;28
    LXI     B,L_MENU_CMD_LOOP_NOBEEP	;continuation function
    PUSH    B
    RM									;retif A was <1CH/28
    LXI     B,L_MENU_HANDLER_2			;another continuation function
    PUSH    B
    JZ      L_MENU_HANDLER_5
    DCR     A
    JZ      L_MENU_HANDLER_4			;brif A == 0
    DCR     A
    POP     B
    JZ      L_MENU_HANDLER_3			;brif A == 0
    MOV     A,E
    ADI		04H							;4 files per line
    MOV     D,A
    LDA     MENMAX_R					;Maximum MENU directory location
    CMP     D
    RM									;retif MENMAX_R < D
    MOV     A,D
L_MENU_HANDLER_2:						;also continuation function
    STA     MENPOS_R					;Current MENU directory location
    PUSH    H
    LHLD    CSRY_R						;Cursor row (1-8) + column (1-40)
    PUSH    H
    MOV     L,E
    PUSH    D
    CALL    L_REV_VID_FNAME
    POP     D
    MOV     L,D
    CALL    L_REV_VID_FNAME
    POP     H
    CALL    R_SET_CURSOR_POS			;Set the current cursor position
    POP     H
    RET

L_MENU_HANDLER_3:
    MOV     A,E
    SUI     04H
    MOV     D,A
    RM
    PUSH    B
    RET
;
; IN:
;	E
; OUT:
;	A
;
L_MENU_HANDLER_4:
    MOV     A,E							;D = E - 1
    DCR     A
    MOV     D,A
    RP     
    LDA     MENMAX_R					;Maximum MENU directory location
    MOV     D,A
    RET
;
; IN:
;	E
; OUT:
;	A
;
L_MENU_HANDLER_5:
    MOV     A,E							;D = E + 1
    INR     A
    MOV     D,A
    LDA     MENMAX_R					;Maximum MENU directory location
    CMP     D
    MOV     A,D
    RP     
    SUB     A							;clear A
    MOV     D,A
    RET
;
; Handle ENTER key from MENU command loop
; in HL
;
R_MENU_ENTER_HANDLER:				  	;58F7H
    LDA     MENUCMD_R					;Menu command entry count
    ORA     A
    JZ      +							;brif MENUCMD_R == 0
    MVI     M,00H
    CALL    L_CHKDC_1
    JNZ     L_MENU_CTRLU_1
;
; MENU CTRL-U ON ERROR Handler
;
L_MENU_CTRLU_HANDLER:
    CALL    R_BEEP_STMT					;BEEP statement
    JMP     R_MENU_CTRL_U_HANDLER		;Handle CTRL-U key from MENU command loop

+	LDA     MENPOS_R					;Current MENU directory location
    LXI     H,MNU2RAM_R				    ;Map of MENU entry positions to RAM directory positions
    LXI     D,0002H
-	ORA     A
    JZ      +							;brif A == 0
    DAD     D							;add 2 to HL
    DCR     A
    JMP     -
+	CALL    R_GET_FILE_ADDR
L_MENU_CTRLU_1:
    PUSH    H							;save HL
    CALL    R_CLS_STMT				    ;Clear Screen
    CALL    R_RESUME_AUTO_SCROLL		;Resume automatic scrolling
    LDA     TMPCONDEV_R					;temporary Console device flag
    CALL    L_SCREEN_STMT_1
    MVI     A,0CH						;CR
    OUTCHR								;Send character in A to screen/printer
    SUB     A							;clear A
    STA     UNUSED5_R
    MOV     L,A							;clear HL
    MOV     H,L
    SHLD    ACTONERR_R					;active ON ERROR handler vector
    DCR     A							;A == 0FFH
    STA     LINENA_R					;Label line enable flag
    POP     H							;restore HL
    MOV     A,M							;get file type
    CALL    R_GET_FILE_ADDR_PREINC_HL	;Get start address of file at M
    CPI     0A0H						;10100000 Filetype
    JZ      R_EXEC_CO_FILE				;Launch .CO files from MENU
    CPI     0B0H						;10110000 Filetype
    JZ      R_EXEC_ROM_FILE				;Launch ROM command file from MENU program
    CPI     0F0H						;11110000 Filetype
    JZ      ROMJMP_R					;launch option ROM. Code in RAM
    CPI     0C0H						;11000000 Filetype
    JZ      R_EDIT_DO_FILE_FUN			;Edit .DO files
; assume we have a BASIC file here
    SHLD    TXTTAB_R					;Start of BASIC program pointer
    DCX     D
    DCX     D
    XCHG
    SHLD    RAMDIRPTR_R
    CALL    R_UPDATE_LINE_ADDR			;Update line addresses for current BASIC program
    CALL    R_LOAD_BASIC_FKEYS			;Copy BASIC Function key table to key definition area
    CALL    L_SET_STRBUF
    CALL    R_INIT_BASIC_VARS			;Initialize BASIC Variables for new execution
    JMP     L_NEWSTT					;Execute BASIC program
;
; Launch ROM command file from MENU program
;
R_EXEC_ROM_FILE:						;596FH
    PCHL   
;
; Display directory entries of type in register C
; RAMDIR_R size = 27 * 11 = 297 (129H) bytes
;
R_DISP_DIR_TYPE_C:						;5970H
    MVI     B,RAMDIRCNT					;max directory entries
    LXI     D,RAMDIR_R					;Start of RAM directory
L_DISP_DIR_TYPE_C_1:
    LDAX    D
    INR     A							;test for 0FFH
    RZ									;end of directory
    DCR     A
    CMP     C							;desired type?
    JNZ     +							;check next entry
    PUSH    B							;save all W regs
    PUSH    D
    PUSH    H
    LHLD    TMP_UTIL_R
    MOV     M,E
    INX     H
    MOV     M,D
    INX     H
    INX     D
    INX     D
    INX     D
    SHLD    TMP_UTIL_R					;update
    POP     H
    CALL    R_NEXT_DIR_ENTRY			;Position cursor for next directory entry
    PUSH    H
    LXI     H,STRNAM_R
    PUSH    H
    CALL    R_CONV_FILENAME				;Convert filename from space padded to '.ext' format
    POP     H
    CALL    R_PRINT_STRING2				;Print NULL terminated string at M
    POP     H
    INR     L
    POP     D
    POP     B
+	PUSH    H
    LXI     H,RAMDIRLEN					;000BH	length of directory item
    DAD     D
    XCHG
    POP     H
    DCR     B
    JNZ     L_DISP_DIR_TYPE_C_1
    RET
;
;Convert filename from space padded to '.ext' format
;
; IN:
;	DE		space padded filename ptr
;	HL		. format destination ptr
;
;
R_CONV_FILENAME:						;59ADH
    MVI     A,06H
    CALL    R_COPY_MEM_DE_M				;Copy 6 bytes from (DE) to M
    MVI     A,' '						;backup over spaces
-	DCX     H
    CMP     M
    JZ      -							;brif [HL] == ' '
    INX     H							;potential dot location
    MVI     M,00H						;terminate speculatively
    LDAX    D							;get ext char
    CPI     ' '
    RZ									;return if ext char == ' '
    MVI     M,'.'						
    INX     H
    CALL    R_COPY_WORD_DE_M			;copy 2 byte extension
    MVI     M,00H						;terminate
    RET
;
; Position cursor for next directory entry
;
R_NEXT_DIR_ENTRY:						;59C9H
    PUSH    D
    PUSH    H
    MOV     A,L
    RAR
    RAR
    ANI     3FH							;00111111
    MOV     E,A
    INR     E
    INR     E
    MOV     A,L
    ANI     03H							;00000011
    ADD     A
    MOV     D,A
    ADD     A
    ADD     A
    ADD     D
    MOV     D,A
    INR     D
    INR     D
    XCHG
    CALL    R_SET_CURSOR_POS			;Set the current cursor position
    POP     H
    POP     D
    RET
;
; IN:
;
L_REV_VID_FNAME:
    CALL    L_BLINK_LCD					;Turn off background task, blink & reinitialize cursor blink time
    CALL    R_NEXT_DIR_ENTRY			;Position cursor for next directory entry
    MVI     B,10						;leading space+6+dot+2
    PUSH    H							;save HL
    LXI     H,CSRX_R					;Cursor column (1-40)
    DCR     M
-	PUSH    B							;save loop counter
    PUSH    D							;save DE
    LHLD    CSRY_R						;Cursor row (1-8) + column (1-40)
    CALL    L_FLIP_REV				;set reverse video bit
    XCHG
    CALL    L_SET_LCTEYX				;Rebase LCD column # & row #
    DI 
    CALL    R_BLINK_CURSOR				;Blink the cursor
    EI     
    POP     D							;restore DE
    LXI     H,CSRX_R					;Cursor column (1-40)
    INR     M							;increment Cursor column
    POP     B							;restore loop counter
    DCR     B							;decrement loop counter
    JNZ     -
    CALL    L_BLINK_LCD					;Turn off background task, blink & reinitialize cursor blink time
    POP     H							;restore HL
    RET
;
; Print time, day and date on first line of screen
;
R_CLS_PRINT_TIME_DAY:				    ;5A12H
    CALL    R_CLS_STMT				    ;Clear Screen
;
; Print time),day),date on first line w/o CLS
;
R_PRINT_TIME_DAY:						;5A15H
    CALL    R_SEND_CURSOR_HOME         	;Home cursor
    LXI     H,ALTLCD_R+203				;0FD8BH temp storage in ALTLCD_R
    CALL    R_READ_DATE				    ;DATE$ function
    MVI     M,' '
    INX     H
    CALL    R_READ_DAY				    ;Read day and store at M
    XCHG
    MVI     M,' '
    INX     H
    CALL    R_READ_TIME				    ;Read time and store it at M
    MVI     M,00H
    LDA     TIMBUF_R+9					;Month (1-12). Loop counter
    LXI     H,L_Months_MSG-3			;Code Based. pre-decremented
    LXI     B,3
-	DAD     B
    DCR     A
    JNZ     -
    LXI     D,ALTLCD_R+200				;0FD88H	temp storage in ALTLCD_R
    XCHG
    PUSH    H
    MOV     A,C
    CALL    R_COPY_MEM_DE_M				;Copy A bytes from (DE) to M
    MOV     D,H							;DE = HL
    MOV     E,L
    MVI     M,' '
    INX     D							;DE += 3
    INX     D
    INX     D
    INX     H
    CALL    R_COPY_WORD_DE_M
    MVI     M,','						;2CH
    INX     H
    MVI     M,'2'
    INX     H
    MVI     M,'0'
    POP     H
;
; Print NULL terminated string at M
;
R_PRINT_STRING2:						;5A58H
    MOV     A,M
    ORA     A
    RZ
    OUTCHR								;Send character in A to screen/printer
    INX     H
    JMP     R_PRINT_STRING2				;Print NULL terminated string at M
;
; Copy 2 bytes from (DE) to M
;
R_COPY_WORD_DE_M:
    MVI     A,02H
;
; Copy A bytes from (DE) to M
;
R_COPY_MEM_DE_M:						;5A62H
    PUSH    PSW
    LDAX    D
    MOV     M,A
    INX     D
    INX     H
    POP     PSW
    DCR     A
    JNZ     R_COPY_MEM_DE_M				;Copy A bytes from (DE) to M
    RET
;
; Compare string at DE with that at M (max C bytes)
; TODO Only called ONCE so could be inlined. Saves 4 bytes
;
R_CMP_MEM_DE_M:							;5A6DH
    LDAX    D
    CMP     M
    RNZ
    ORA     A
    RZ
    INX     H
    INX     D
    DCR     C
    JNZ     R_CMP_MEM_DE_M				;Compare string at DE with that at M (max C bytes)
    RET
;
; Clear function key definition table
;
R_CLEAR_FKEY_TBL:						;5A79H
    LXI     H,L_EMPTY_KEY_FUNC			;Code Based. empty function key definition table
;
; Set new function key table
; 8 entries, each 16 bytes.
;
R_SET_FKEYS:							;5A7CH
    LXI     D,FNKSTR_R					;Function key definition area
    MVI     B,08H						;8 entries
L_SET_FKEYS_1:
    MVI     C,10H						;max 16 chars per label
-	MOV     A,M							;source
    INX     H							;next
    ORA     A							;test bit 7
    PUSH    PSW							;save flags
    ANI     7FH							;clear bit 7
    STAX    D							;update Function keys
    POP     PSW							;restore flags
    JM      +							;brif bit 7 set
    INX     D							;next
    DCR     C
    JNZ     -
+	SUB     A							;clear A
-	INX     D							;zero fill
    DCR     C
    STAX    D
    JNZ     -
    DCR     B
    JNZ     L_SET_FKEYS_1
;
; Display function keys on 8th line
;
R_DISP_FKEYS:							;5A9EH
    LDA     LINPROT_R					;Label line protect status
    ORA     A
    CNZ     R_DISP_FKEY_LINE			;Display function key line
    RET

L_SEARCH_ADRS:
    LXI     D,L_ADRS_DO_MSG				;Code Based. "ADRS.DO"
;
; Search directory for filename
;
R_CHKDC:
R_SEARCH_DIR:							;5AA9H
    MVI     A,08H
    LXI     H,STRNAM_R
    CALL    R_COPY_MEM_DE_M				;Copy A bytes from (DE) to M
L_CHKDC_1:
    MVI     B,RAMDIRCNT
    LXI     D,RAMDIR_R					;Start of RAM directory
L_CHKDC_2:
    LXI     H,0FDF0H
    LDAX    D
    INR     A
    RZ
    ANI     80H
    JZ      L_CHKDC_3
    PUSH    D
    INX     D
    INX     D
    INX     D
    PUSH    H
    CALL    R_CONV_FILENAME				;Convert filename from space padded to '.ext' format
    POP     H
    MVI     C,09H
    LXI     D,STRNAM_R
    CALL    R_CMP_MEM_DE_M				;Compare string at DE with that at M (max C bytes)
    JNZ     +
    POP     H
    INR     C
    RET
+	POP     D
L_CHKDC_3:
    LXI     H,000BH
    DAD     D
    XCHG
    DCR     B
    JNZ     L_CHKDC_2
    RET
;
; Get start address of file at M
; result in HL
;
R_GET_FILE_ADDR_PREINC_HL:				;5AE3H
    INX     H
R_GET_FILE_ADDR:
    MOV     E,M							;[HL] -> DE
    INX     H
    MOV     D,M
    XCHG								;to HL
    RET

L_Months_MSG:
    DB      "Jan"
    DB      "Feb"
    DB      "Mar"
    DB      "Apr"
    DB      "May"
    DB      "Jun"
    DB      "Jly"
    DB      "Aug"
    DB      "Sep"
    DB      "Oct"
    DB      "Nov"
    DB      "Dec"
L_MSFT_MSG:
    DB      "(C)Microsoft",00H

L_NOENTRY_MSG:
    DB      "-.-",00H
;
; Directory file-type display order table
;
R_DIR_DISP_ORDER_TBL:					;5B1EH
    DB      0B0H,0F0H,0C0H,80H,0A0H,00H

L_Select_MSG:
    DB      "Select: _         ",00H

L_SPACE_MSG:
    DB      ' ',08H,08H					;20H,08H,08H

L_UNDERSCORE_MSG:
    DB      '_',08H						;5FH,08H

L_NULL_MSG:
    DB      00H,00H
;
; empty function key definition table
;
L_EMPTY_KEY_FUNC:
    DB      80H,80H,80H,80H,80H,80H,80H,80H
;
; Function Key Labels for BASIC
;
R_BASIC_FKEYS_TBL:						;5B46H
    DB      "Files",8DH
    DB      "Load ",0A2H
    DB      "Save ",0A2H
    DB      "Run",8DH
    DB      "List",8DH
    DB      80H
    DB      80H
    DB      "Menu",8DH
;
; ADDRSS Entry point
;
R_ADDRSS_ENTRY:							;5B68H
    LXI     D,L_ADRS_DO_MSG				;Code Based. "ADRS.DO"
;R_ADDRSS_ENTRY_W_FILE:				    ;5B6BH
    SUB     A							;ADDRSS_ENTRY flag
    JMP     L_ADDRSS_SCHEDL
;
; SCHEDL Entry point
;
R_SCHEDL_ENTRY:							;5B6FH
    LXI     D,L_NOTE_DO_MSG				;Code Based. "NOTE.DO"
;R_SCHEDL_ENTRY_W_FILE:				    ;5B72H
    MVI     A,0FFH						;SCHEDL_ENTRY flag
; joint entry point
L_ADDRSS_SCHEDL:
    STA     MENUCMD_R					;Flag to ADDRSS_ENTRY or SCHEDL_ENTRY
    CALL    L_RESET_SP_1				;Stop BASIC, Restore BASIC SP &	clear SHIFT-PRINT Key
    PUSH    D							;save ptr to desired filename
    CALL    R_SEARCH_DIR				;Search directory for filename
    CALL    R_GET_FILE_ADDR_PREINC_HL	;Get start address of file at M
    JNZ     L_UTIL_FILE_FND				;ADRS.DO or NOTE.DO found
    POP     H							;restore ptr to desired filename
    SHLD    MENPOS_R					;Used for filename ptr here
;
; Could not open NOTE.DO or ADRS.DO
;
L_UTIL_NOT_OPEN:						;ON ERROR handler vector
    LXI     H,L_UTIL_NOT_OPEN
    SHLD    ACTONERR_R					;active ON ERROR handler vector
    CALL    R_CLS_STMT				    ;Clear Screen
    CALL    R_BEEP_STMT				    ;BEEP statement
    LHLD    MENPOS_R					;filename ptr
    CALL    R_PRINT_STRING2				;Print NULL terminated string at M
    LXI     H,L_notfound_MSG			;Code Based.
    CALL    R_PRINT_STRING2				;Print NULL terminated string at M
    LXI     H,L_MENU_MSG
    CALL    R_SPACE_KEY
    JMP     R_MENU_ENTRY				;MENU Program
;
; NOTE.DO or ADRS.DO found. Open and start SCHEDL.
;
L_UTIL_FILE_FND:
    SHLD    TMP_UTIL_R					;store start address of file
    CALL    R_CLS_STMT				    ;Clear Screen
    LXI     H,L_FUNC_KEYS_TBL_UTIL		;Code Based.
    CALL    R_SET_DISP_FKEY				;Set and display function keys (M has key table)
    LXI     H,L_UTIL_FILE_1				;ON ERROR handler vector
    SHLD    ACTONERR_R					;active ON ERROR handler vector
L_UTIL_FILE_FND_0:
	CALL    L_RESET_SP					;Restore BASIC SP
    SUB     A
    STA     PRTFLG_R					;Output device for RST 20H (0=screen)
    LXI     H,L_Adrs_MSG				;Code Based. "Adrs: "
    LDA     MENUCMD_R					;Menu command entry count
    ORA     A
    JZ      + 
	LXI     H,L_Schd_MSG				;Code Based. "Schd: "
+	CALL    R_PRINT_STRING2				;Print NULL terminated string at M
    CALL    R_INP_DISP_LINE_NO_Q		;Input and display (no "?") line and store
    INX     H
    MOV     A,M
    ORA     A
    JZ      L_UTIL_FILE_FND_0
    LXI     D,R_ADDRSS_INST_VCTR_TBL	;Code Based. ADDRSS/SCHEDL instruction vector table
    CALL    L_TELCOM_EXEC_CMD
    RNZ
L_UTIL_FILE_1:
    SUB     A							;clear A
    STA     PRTFLG_R					;Output device for RST 20H (0=screen)
    CALL    R_LCD_NEW_LINE				;Move LCD to blank line (send CRLF if needed)
    CALL    R_BEEP_STMT				    ;BEEP statement
    LXI     H,L_FUNC_KEYS_TBL_UTIL		;Code Based.
    CALL    R_SET_FKEYS				    ;Set new function key table
    JMP     L_UTIL_FILE_FND_0
;
; FIND instruction for ADDRSS/SCHEDL
;
R_ADDRSS_FIND_FUN:						;5BF5H
    SUB     A							;fnd flag
	SKIP_2BYTES_INST_BC
;
; LFND instruction for ADDRSS/SCHEDL
;
R_ADDRSS_LFND_FUN:						;5BF7H
    MVI     A,0FFH						;Lfnd flag
    CALL    L_SET_UTILS_OUTPUT
L_ADDRSS_LFND_FUN_1:
    CALL    R_FIND_TEXT_IN_FILE        	;Find text at M in the file at (DE)
    JNC     L_UTIL_FILE_FND_0
    PUSH    H
    PUSH    D
    CALL    L_SET_UTIL_WIDTH
L_ADDRSS_LFND_FUN_2:
    CALL    L_BDL_LINE_DE				;Build next line from .DO file at (DE) into line buffer
    LDA     MENPOS_R					;Used as Lfnd flag here
    STA     PRTFLG_R					;Output device for RST 20H (0=screen)
    CALL    L_DISP_LINE_1
    SUB     A
    STA     PRTFLG_R					;Output device for RST 20H (0=screen)
    LDA     MENPOS_R					;Used as Lfnd flag here
    ORA     A
    JNZ     +
    CALL    L_TST_FOR_Q
    JZ      L_UTIL_FILE_FND_0
+	DCX     D
    LDAX    D
    INX     D
    CPI     0AH							;LF
    JZ      + 
	PUSH    D
    INX     D
    MOV     A,E
    ORA     D
    POP     D
    JNZ     L_ADDRSS_LFND_FUN_2
    JMP     L_UTIL_FILE_FND_0

+	POP     D
    CALL    R_FIND_NEXT_LINE_IN_FILE	;Increment DE past next CRLF in text file at (DE)
    POP     H
    JMP     L_ADDRSS_LFND_FUN_1

;
; Find text at M in the file at (DE)
;
R_FIND_TEXT_IN_FILE:					;5C3FH
    PUSH    D
L_FIND_TEXT_IN_FILE_1:
    PUSH    H
    PUSH    D
-	LDAX    D
    CALL    R_CONV_A_TOUPPER			;Convert A to uppercase
    MOV     C,A
    CALL    R_CONV_M_TOUPPER			;Get char at M and convert to uppercase
    CMP     C
    JNZ     +
    INX     D
    INX     H
    JMP     -
+	CPI     00H
    MOV     A,C
    POP     B
    POP     H
    JZ      +
    CPI     1AH
    JZ      L_POP_RET
    CALL    R_CHECK_FOR_CRLF			;Check next byte(s) at (DE) for CRLF
    JNZ     L_FIND_TEXT_IN_FILE_1
    POP     PSW
    JMP     R_FIND_TEXT_IN_FILE			;Find text at M in the file at (DE)
+	POP     D
    STC
    RET
;
; Increment DE past next CRLF in text file at (DE)
;
R_FIND_NEXT_LINE_IN_FILE:				;5C6DH
    CALL    R_CHECK_FOR_CRLF			;Check next byte(s) at (DE) for CRLF
    JNZ     R_FIND_NEXT_LINE_IN_FILE   	;Increment DE past next CRLF in text file at (DE)
    RET
;
; Check next byte(s) at (DE) for CRLF
;
R_CHECK_FOR_CRLF:						;5C74H
    LDAX    D
    CPI     0DH
    INX     D
    RNZ
    LDAX    D
    CPI     0AH
    RNZ
    INX     D
    RET

L_TELCOM_FOUND:
    PUSH    D
    LXI     H,L_FUNC_KEYS_TBL_TELCOM	;Code Based.
    CALL    R_SET_FKEYS				  	;Set new function key table
    CALL    L_MENU_KEY					;get key
    PUSH    PSW							;save it
    LXI     H,R_TELCOM_LABEL_TXT		;Code Based.
L_SET_FUNC_KEYS:
    CALL    R_SET_FKEYS				  	;Set new function key table
    CALL    L_SET_UTIL_MAXLINE
    POP     PSW							;restore key
    CPI     'Q'							;51H
L_POP_RET:
    POP     D
    RET
;
; set extended function keys table.
; this happens if more than 6 entries are available to display
;
L_SET_EXT_FUNC_KEYS:
    PUSH    D
    LXI     H,L_FUNC_KEYS_TBL_UTIL_EXT	;Code Based.
    CALL    R_SET_FKEYS				  	;Set new function key table
-	CALL    L_MENU_KEY
    CPI     'C'							;43H
    JZ      -
    PUSH    PSW							;save key
    LXI     H,L_FUNC_KEYS_TBL_UTIL		;Code Based.
    JMP     L_SET_FUNC_KEYS

L_MENU_KEY:
    CALL    R_WAIT_KEY				  	;Wait for key from keyboard
    PUSH    PSW
    SUB     A							;clear
    STA     FNKMAC_R+1
    POP     PSW
    CALL    R_CONV_A_TOUPPER			;Convert A to uppercase
    CPI     'Q'
    RZ
    CPI     ' '
    RZ
    CPI     'M'
    RZ
    CPI     'C'
    RZ
    CPI     0DH
    JNZ     L_MENU_KEY
; A is now 0DH
    ADI		36H
    RET

L_ADRS_DO_MSG:
    DB      "ADRS.DO",00H

L_notfound_MSG:
    DB      " not found",00H

L_Adrs_MSG:
    DB      "Adrs: ",00H

L_Schd_MSG:
    DB      "Schd: ",00H
;
; ADDRSS/SCHEDL instruction vector table
;
R_ADDRSS_INST_VCTR_TBL:				    	;5CEFH
    DB      "FIND"
    DW      R_ADDRSS_FIND_FUN				;5BF5H
    DB      "LFND"
    DW      R_ADDRSS_LFND_FUN				;5BF7H
    DB      "MENU"
    DW      R_MENU_ENTRY					;5797H
    DB      0FFH

L_NOTE_DO_MSG:
    DB      "NOTE.DO",00H
;
; Function Key Tables
;
L_FUNC_KEYS_TBL_UTIL:
    DB      "Find",0A0H					;' ' OR 80H
    DB      80H
    DB      80H
    DB      80H
    DB      "Lfnd",0A0H					;' ' OR 80H
    DB      80H
    DB      80H
    DB      "Menu",8DH					;CR OR 80H
L_FUNC_KEYS_TBL_UTIL_EXT:
    DB      80H
    DB      80H
    DB      "Mor",0E5H					;'e' OR 80H
    DB      "Qui",0F4H					;'t' OR 80H
    DB      80H,80H,80H

L_FUNC_KEYS_TBL_TELCOM:
    DB      80H
    DB      "Call",0A0H					;' ' OR 80H
    DB      "Mor",0E5H					;'e' OR 80H
    DB      "Qui",0F4H					;'t' OR 80H
    DB      80H,80H,80H,80H

    JMP     R_MENU_ENTRY				;MENU Program
;
; TODO unreachable
;
    LXI     D,0010H
    DAD     D
    DCR     C
    RET

L_SKIP_SPACE_AT_M:						;skip space at M
    MOV     A,M
    INX     H
    CPI     ' '
    RZ
    DCX     H
    RET
;
; Stop BASIC, Restore BASIC SP & clear SHIFT-PRINT Key
;
L_RESET_SP_1:
    LXI     H,L_NULL_MSG				;Code Based
    SHLD    SHFTPRNT_R
;
; Stop BASIC, Restore BASIC SP
;
L_RESET_SP_0:
    LXI     H,0FFFFH
    SHLD    CURLIN_R					;Currently executing line number
    INX     H							;Clear HL
    SHLD    SER_UPDWN_R
;
; Restore BASIC SP
;
L_RESET_SP:
    POP     B							;pop return address
    LHLD    BASSTK_R					;SP used by BASIC to reinitialize the stack
    SPHL								;set SP
    PUSH    B							;push return address
    RET
;
; Wait for char from keyboard & convert to uppercase
;
R_GET_KEY_CONV_TOUPPER:				  	;5D64H
    CALL    R_WAIT_KEY				  	;Wait for key from keyboard
    JMP     R_CONV_A_TOUPPER			;Convert A to uppercase
;
; Home cursor
;
R_SEND_CURSOR_HOME:						;5D6AH
    LXI     H,0101H
    JMP     R_SET_CURSOR_POS			;Set the current cursor position
;
; Print time on top line until key pressed
;
R_PRINT_TIME_LOOP:						;5D70H
    PUSH    H
    LHLD    CSRY_R						;Cursor row (1-8) + column (1-40)
    PUSH    H
    CALL    R_CHK_KEY_QUEUE				;Check keyboard queue for pending characters
    PUSH    PSW
    CZ      R_PRINT_TIME_DAY			;Print time),day),date on first line w/o CLS
    POP     PSW
    POP     H							;Cursor row + column
    PUSH    PSW
    CALL    R_SET_CURSOR_POS			;Set the current cursor position
    POP     PSW
    POP     H
    JZ      R_PRINT_TIME_LOOP			;Print time on top line until key pressed
    RET
;
; IN:
;	C		character typed
;	HL		ptr to buffer
;
L_CMD_CHAR:
    MOV     M,C
    INX     H
    PUSH    H
    LXI     H,MENUCMD_R				  	;Menu command entry count
    INR     M
    MOV     A,C
    OUTCHR								;Send character in A to screen/printer
    LXI     H,L_UNDERSCORE_MSG			;Code Based. Prompt cursor
    CALL    R_PRINT_STRING2				;Print NULL terminated string at M
    POP     H
    RET
;
; CMD mode means typing into the SELECT: field
; MENUCMD_R has the char count
;
L_MENU_OR_CMD:
    LDA     MENUCMD_R					;Flag to indicate MENU entry (0) or command entry
    ORA     A
    RET

L_RUBOUT_CMD:
    CALL    L_MENU_OR_CMD				;TODO inline
    RZ									;retif MENUCMD_R == 0: ignore
    DCR     A							;decrement MENUCMD_R
    STA     MENUCMD_R					;update MENUCMD_R
    DCX     H
    PUSH    H
    LXI     H,L_SPACE_MSG				;Code Based.
    CALL    R_PRINT_STRING2				;Print NULL terminated string at M
    POP     H
    INR     A
    RET
;
; Set output target for utils
;
L_SET_UTILS_OUTPUT:
    STA     MENPOS_R					;Used as Lfnd flag here
    CALL    L_SKIP_SPACE_AT_M			;skip space at M
    XCHG
    LHLD    TMP_UTIL_R					;start address of file to DE
    XCHG
L_SET_UTIL_MAXLINE:
    LDA     LINCNT_R					;Console height
    DCR     A
    DCR     A
    STA     MENMAX_R					;Maximum output window line here
    RET

L_SET_UTIL_WIDTH:
    LXI     H,LINWDT_R				  	;Active columns count (1-40)
    MVI     A,0FFH
    STA     WWRAP_R						;Get word-wrap enable flag
    STA     LCDPRT_R					;LCD vs Printer output indication - output to LCD
    LDA     MENPOS_R					;Used as Lfnd flag here
    ORA     A
    JZ      +							;brif MENPOS_R == 0
; output to printer
    MVI     A,01H
    STA     LCDPRT_R					;LCD vs Printer output indication - output to LCD
    LXI     H,PRTWDTH_R					;Printer output width from CTRL-Y
+	MOV     A,M
    STA     OUTFMTWIDTH_R				;Output format width (40 or something else for CTRL-Y)
    RET

L_TST_FOR_Q:
    LXI     H,MENMAX_R				  	;Maximum MENU directory location
    DCR     M
    CZ      L_SET_EXT_FUNC_KEYS
    CPI     51H							;'Q'
    RET
;
; TEXT Entry point
;
R_TEXT_ENTRY:							;5DEEH
    LXI     H,L_TEXT_ENTRY_1			;ON ERROR handler vector
    SHLD    ACTONERR_R					;active ON ERROR handler vector
    LXI     H,R_TEXT_FKEY_TBL			;Code Based. TEXT Function key table - empty
    CALL    R_SET_FKEYS				  	;Set new function key table
    XRA     A
L_TEXT_ENTRY_1:							;ON ERROR handler vector
    CNZ     R_BEEP_STMT				  	;BEEP statement
    CALL    L_RESET_SP_0				;Stop BASIC, Restore BASIC SP
    LXI     H,L_EDITFILE_MSG			;Code Based.
    CALL    R_PRINT_STRING				;Print buffer at M until NULL or '"'
    CALL    R_INP_DISP_LINE				;Input and display line and store
    CHRGET								;Get next non-white char from M
    ANA     A
    JZ      R_MENU_ENTRY				;MENU Program
    CALL    R_GET_FIND_DO_FILE         	;Get .DO filename and locate in RAM directory
    JMP     R_EDIT_DO_FILE_FUN         	;Edit .DO files

L_EDITFILE_MSG:
    DB      "File to edit",00H
;
; TEXT Function key table - empty
;
R_TEXT_FKEY_TBL:						;5E22H
    DB      80H,80H,80H,80H,80H,80H,80H,83H
;
; TEXT Function key table - Normal FKeys
;
R_TEXT_FKEY2_TBL:
    DB      "Find",8EH
    DB      "Load",96H
    DB      "Save",87H
    DB      80H
    DB      "Copy",8FH
    DB      "Cut ",95H
    DB      "Sel ",8CH
    DB      "Menu",1BH
	DB		9BH
;
; CTRL-Y (Print) Keystroke emulation
;
L_CTRLY:
	DB		19H, 00H
;
; EDIT statement
; Z Flag means no EDIT linenumbers were specified
;
; EDIT clears the screen, list statements in range and enters EDIT mode
;
R_EDIT_STMT:							;5E51H
    PUSH    H							;save txt ptr
    PUSH    PSW							;save Z flag
    MVI     A,01H						;preload A no EDIT linenumbers were specified
    JZ      +
    MVI     A,0FFH						;A value if EDIT linenumbers were specified
+	STA     EDITFLG_R
    XRA     A
    STA     FILNAM_R+2					;clear
    LXI     H,2020H						;"  "
    SHLD    FILNAM_R+6					;Filename extension
    LXI     H,L_EDIT_ERR2				;EDIT ERROR handler vector
    SHLD    ACTONERR_R					;active ON ERROR handler vector
    LXI     D,0F802H					;E == Marker 2: Open for Output. D == RAM_DEV
    LXI     H,L_NULL_STR
    CALL    R_OPEN_FILE
    LXI     H,L_EDIT_ERR1				;EDIT ERROR handler vector
    SHLD    ACTONERR_R					;active ON ERROR handler vector
    POP     PSW							;restore Z flag
    POP     H							;restore txt ptr
    PUSH    H							;and push a fake return address
    JMP     R_LIST_STMT				   	;shared code in LIST statement

L_EDIT_MODE:
    CALL    L_CLS_FILE0					;close file 0 & Load LSTVAR_R						
    CALL    L_DEL_LINES
    LDA     LINPROT_R					;Label line protect status
    STA     LINPROT2_R					;save it
    LXI     H,0
    SHLD    TMPLIN_R					;temp storage for line ptr
L_EDIT_MODE_1:
    CALL    LNKFIL						;Fix up the directory start pointers
    CALL    R_CLEAR_COM_INT_DEF       	;Clear all COM), TIME), and KEY interrupt definitions
    LHLD    RICKY_R+1
    MOV     A,M
    CPI     1AH							;^Z
    JZ      L_EOF_FND					;brif ^Z found
    PUSH    H
    XRA     A
    LXI     H,L_EDIT_MODE_2				;continuation function
    JMP     L_EDIT_DO_FILE_FUN_1

L_EDIT_MODE_2:
    XRA     A
    LXI     H,L_EDIT_ERR3				;ERROR handler vector
    SHLD    ACTONERR_R					;active ON ERROR handler vector
    LXI     H,L_NULL_STR
    MVI     D,RAM_DEV					;0F8H Device Code
    JMP     L_MERGE_2

L_EDIT_MODE_3:
    CALL    R_CLS_STMT				    ;Clear Screen
L_EOF_FND:
    XRA     A
    STA     EDITFLG_R					;leave EDIT mode
    MOV     L,A							;clear HL
    MOV     H,A
    SHLD    ACTONERR_R					;clear active ON ERROR handler vector
    CALL    L_CLR_SELECTION				;Clear selection
    CALL    L_INIT_BASIC				;Initialize BASIC for new execution
    LDA     LINPROT2_R					;restore Label line protect status
    STA     LINPROT_R
    JMP     L_ALT_BASIC_ENTRY
;
; EDIT ERROR handler vectors
;
L_EDIT_ERR1:
    PUSH    D							;save DE
    CALL    L_CLR_SELECTION				;Clear selection
    POP     D							;restore DE
L_EDIT_ERR2:							;ERROR handler vector
    PUSH    D							;save DE
    XRA     A							;clear EDITFLG_R & HL
    STA     EDITFLG_R
    MOV     L,A
    MOV     H,A
    SHLD    ACTONERR_R					;clear active ON ERROR handler vector
    CALL    L_CLS_FILE0					;close file 0 & Load LSTVAR_R
    POP     D							;restore DE
    JMP     R_GEN_ERR_IN_E				;Generate error in E

L_EDIT_ERR3:
    MOV     A,E
    PUSH    PSW
    LHLD    FCB1_BUF_R					;ptr to buffer first file
    DCX     H
    MOV     B,M
    DCR     B
    DCX     H
    MOV     C,M
    DCX     H
    MOV     L,M
    XRA     A
    MOV     H,A
    DAD     B
    LXI     B,0FFFFH
    DAD     B
    JC      +
    MOV     L,A
    MOV     H,A
+	SHLD    TMPLIN_R					;temp storage for line ptr
    CALL    L_CLS_FILE0					;close file 0 & Load LSTVAR_R
    POP     PSW
    CPI     07H
    LXI     H,L_MEMFULL_MSG
    JZ      + 
	LXI     H,L_ILL_FRMD_TXT			;Code Based.
+	CALL    R_CLS_STMT					;Clear Screen
    CALL    R_PRINT_STRING				;Print buffer at M until NULL or '"'
    LXI     H,L_TEXT_MSG				;Code Based.
    CALL    R_SPACE_KEY
    JMP     L_EDIT_MODE_1

R_SPACE_KEY:
    PUSH    H
    LXI     H,L_PRESS_SPACE				;Code Based.
    CALL    R_PRINT_STRING				;Print buffer at M until NULL or '"'
    POP     H
    CALL    R_PRINT_STRING				;Print buffer at M until NULL or '"'
;
; Wait for a space to be entered on keyboard
;
R_WAIT_FOR_SPACE_KEY:				    ;5F2FH
    CALL    R_WAIT_KEY				    ;Wait for key from keyboard
    CPI     ' '	
    JNZ     R_WAIT_FOR_SPACE_KEY     	;Wait for a space to be entered on keyboard
    RET

L_ILL_FRMD_TXT:
    DB      "Text ill-formed",07H
L_NULL_STR:
    DB      00H

L_PRESS_SPACE:
    DB      0DH,0AH
    DB      "Press space bar for ",00H

L_TEXT_MSG:
    DB      "TEXT",00H
;
; Edit .DO files
;
R_EDIT_DO_FILE_FUN:						;5F65H
    PUSH    H
    LXI     H,0
    SHLD    TMPLIN_R					;temp storage for line ptr
    MVI     A,01H
    LXI     H,R_MENU_ENTRY
L_EDIT_DO_FILE_FUN_1:
    STA     WWRAP_R						;Get word-wrap enable flag
    SHLD    0F765H
    CALL    R_INV_CHAR_DISABLE         	;Cancel inverse character mode
    CALL    R_ERASE_FKEY_DISP			;Erase function key display
    CALL    R_STOP_AUTO_SCROLL        	;Stop automatic scrolling
    CALL    R_TURN_CURSOR_OFF			;Turn the cursor off
    CALL    L_GET_KEY
    LXI     H,R_TEXT_FKEY2_TBL			;Code Based.
    CALL    R_SET_FKEYS				  	;Set new function key table
    LDA     EDITFLG_R
    ANA     A
    JZ      +
    LXI     H,7845H						;"EX"
    SHLD    FNKSTR_R+70H				;F8
    LXI     H,7469H						;"IT"
    SHLD    FNKSTR_R+72H
+	LXI     H,L_CTRLY					;^Y Code Based.
    SHLD    SHFTPRNT_R
    LDA     LINWDT_R					;Active columns count (1-40)
    STA     OUTFMTWIDTH_R				;Output format width (40 or something else for CTRL-Y)
    MVI     A,80H						;set TEXT mode
    STA     FNKMOD_R					;Function key mode/ BIT 7=in TEXT (0x80) BIT 6=in TELCOM (0x40)
    XRA     A							;clear A, HL
    MOV     L,A
    MOV     H,A
    STA     ESCESC_R					;Clear storage for key read from keyboard to test for ESC ESC (1 byts)
    STA     LCDPRT_R					;LCD vs Printer output indication - output to LCD
    STA     PNDERR_R
    STA     SEARCHSTR_R
    SHLD    DOADDR_R					;Start address in .DO file of SELection for copy/cut
    POP     H
    SHLD    DOLOAD_R					;Load start address of .DO file being edited
    PUSH    H
    CALL    L_FNDEOFDO					;Find end of DO file
    CALL    L_EXPND_DO					;Expand .DO file so it fills all memory for editing
    POP     D
    LHLD    TMPLIN_R					;temp storage for line ptr
    DAD     D
    CALL    L_GET_LCD_ROWS				;Get # of LCD rows based on label protect, preserve flags
    PUSH    H
    CALL    L_DISP_A_LINES				;Display 'A' lines of the .DO file at HL for editing
    POP     H
    CALL    L_SETCRS_FROM_HL			;Reposition TEXT LCD cursor to file pos in HL
;
; Main TEXT edit loop
;
R_TEXT_EDIT_LOOP:						;5FDDH
    CALL    L_RESET_SP_0				;Stop BASIC, Restore BASIC SP
    LXI     H,R_TEXT_EDIT_LOOP
    SHLD    ACTONERR_R					;active ON ERROR handler vector
    PUSH    H
    LDA     ESCESC_R					;Clear storage for key read from keyboard to test for ESC ESC (1 byts)
    STA     SAVESCESC_R
    CALL    R_TEXT_GET_NEXT_BYTE     	;Get next byte for TEXT Program entry
    STA     ESCESC_R					;Clear storage for key read from keyboard to test for ESC ESC (1 byts)
    PUSH    PSW
    CALL    L_CLR_PNDERR
    POP     PSW
    JC      L_INSRT_PASTE				;Insert PASTE buffer into .DO file
    CPI     7FH							;DEL
    JZ      L_TEXT_CTRL_H_FUN_1
    CPI     ' '	
    JNC     R_TEXT_CTRL_I_FUN			;brif A >= ' ': TEXT control I routine
    MOV     C,A							;zero extend A to BC
    MVI     B,00H
    LXI     H,R_TEXT_CTRL_VCTR_TBL		;Code Based.
    DAD     B							;index word address
    DAD     B
    MOV     C,M							;Code Based.
    INX     H							;get vector into HL
    MOV     H,M
    MOV     L,C
    PUSH    H							;set as continuation function
    LHLD    CSRY_R						;Cursor row (1-8) + column (1-40)
R_RET_FUN:
    RET

;
; TEXT control character vector table
;
R_TEXT_CTRL_VCTR_TBL:				    ;6016H
    DW      R_RET_FUN, R_TEXT_CTRL_A_FUN, R_TEXT_CTRL_B_FUN
    DW      R_TEXT_CTRL_C_FUN, R_TEXT_CTRL_D_FUN, R_TEXT_CTRL_E_FUN
    DW      R_TEXT_CTRL_F_FUN, R_TEXT_CTRL_G_FUN, R_TEXT_CTRL_H_FUN
    DW      R_TEXT_CTRL_I_FUN, R_RET_FUN, R_RET_FUN
    DW      R_TEXT_CTRL_L_FUN, R_TEXT_CTRL_M_FUN, R_TEXT_CTRL_N_FUN
    DW      R_TEXT_CTRL_O_FUN, R_TEXT_CTRL_P_FUN, R_TEXT_CTRL_Q_FUN
    DW      R_TEXT_CTRL_R_FUN, R_TEXT_CTRL_S_FUN, R_TEXT_CTRL_T_FUN
    DW      R_TEXT_CTRL_U_FUN, R_TEXT_CTRL_V_FUN, R_TEXT_CTRL_W_FUN
    DW      R_TEXT_CTRL_X_FUN, R_TEXT_CTRL_Y_FUN, R_TEXT_CTRL_Z_FUN
    DW      R_TEXT_ESC_FUN, R_TEXT_CTRL_D_FUN, R_TEXT_CTRL_S_FUN
    DW      R_TEXT_CTRL_E_FUN, R_TEXT_CTRL_X_FUN

;
; TEXT ESCape routine
;
R_TEXT_ESC_FUN:							;6056H
    LDA     SAVESCESC_R
    SUI     1BH
    RNZ
    MOV     L,A							;clear HL
    MOV     H,A
    SHLD    ACTONERR_R					;active ON ERROR handler vector
	RST38H	38H
    CALL    L_GET_KEY
    CALL    R_RESUME_AUTO_SCROLL     	;Resume automatic scrolling
    CALL    R_ERASE_FKEY_DISP			;Erase function key display
    CALL    L_NUM_LCD_ROWS						;Get # of LCD rows based on label protect + cols in HL
    CALL    R_SET_CURSOR_POS			;Set the current cursor position
    CALL    R_SEND_CRLF				    ;Send CRLF to screen or printer
    CALL    L_DEL_ZEROS					;Delete zeros from end of edited DO file and update pointers
    LHLD    0F765H
    PCHL   

;
; TEXT control P routine
;
R_TEXT_CTRL_P_FUN:						;607CH
    CALL    R_TEXT_GET_NEXT_BYTE     	;Get next byte for TEXT Program entry
    JC      L_INSRT_PASTE				;Insert PASTE buffer into .DO file
    ANA     A
    RZ
    CPI     1AH
    RZ
    CPI     7FH
    RZ
;
; TEXT control I routine: insert a char
;
R_TEXT_CTRL_I_FUN:						;608AH
    PUSH    PSW							;save char
    CALL    R_TEXT_CTRL_C_FUN			;TEXT control C routine
    CALL    L_SAV_PREV_LINEPTR
    CALL    L_GET_CRSPOS_ADDR			;Get address in .DO file of current cursor position
    POP     PSW							;restore char
L_TEXT_CTRL_I_FUN_1:
    CALL    L_INSRT_DO					;Insert byte in A to .DO file at address HL.
    JC      L_ERR_MEMFULL				;brif failure
    PUSH    H
    CALL    L_UPDATE_LINE_PTRS
    POP     H
    JMP     L_TEXT_CTRL_H_FUN_2

L_ERR_MEMFULL:
    CALL    L_CHECK_LCD_SCROLL_1
    PUSH    H
    LXI     H,L_MEMFULL_MSG				;Code Based. 
    CALL    L_PRNT_ERRMSG
L_SET_CURSOR_POS_FROM_STACK:			;Set the cursor position from pushed position
    POP     H							;arg
    JMP     R_SET_CURSOR_POS			;Set the current cursor position

L_MEMFULL_MSG:
    DB      "Memory full",07H,00H
;
; TEXT control M routine: Carriage Return & Linefeed
;
R_TEXT_CTRL_M_FUN:						;60BEH
    CALL    R_TEXT_CTRL_C_FUN			;TEXT control C routine
    CALL    L_SAV_PREV_LINEPTR
    LHLD    TXTEND_R
    INX     H
    MOV     A,M							;test for double 0
    INX     H
    ORA     M
    JNZ     L_ERR_MEMFULL				;brif NOT double 0
    CALL    L_UPDATE_LINE_PTRS
    CALL    L_GET_CRSPOS_ADDR			;Get address in .DO file of current cursor position
    MVI     A,0DH
    CALL    L_INSRT_DO					;Insert byte in A to .DO file at address HL.
    MVI     A,0AH
    JMP     L_TEXT_CTRL_I_FUN_1
;
; TEXT right arrow/control D routine
;
R_TEXT_CTRL_D_FUN:								 ; 60DEH
    CALL    L_CURSOR_RIGHT
    STC											;fall through with carry set
;
; TEXT down arrow/control X routine. Carry must be clear if called
;
R_TEXT_CTRL_X_FUN:								 ; 60E2H
    CNC     L_CURSOR_DOWN
    JMP     L_UPDATE_SEL

L_CURSOR_RIGHT:
    LHLD    CSRY_R						;L: Cursor row (1-8), H: column (1-40)
    LDA     LINWDT_R					;Active columns count (1-40)
    INR     H							;increment column
    CMP     H							;compare new column with Line Width
    JNC     L_TEXT_CTRL_E_FUN_3			;brif LINWDT_R >= H: Set the current cursor position
    MVI     H,01H						;set column
L_CURSOR_DOWN:
    INR     L							;increment row
    MOV     A,L
    PUSH    H							;save HL
    CALL    L_GET_LINEPTR				;Get address in .DO file of start of row in 'A'  
    MOV     A,E							;test DE for 0FFFFH
    ANA     D
    INR     A
    POP     H							;restore HL
    STC
    RZ									;brif DE was 0FFFFH
    CALL    L_GET_LCD_ROWS				;Get # of LCD rows based on label protect, preserve flags
    CMP     L
    CC      L_UPD_LCD_DWN						;calif LCD_ROWS < rows
    JMP     L_TEXT_CTRL_E_FUN_3			;Set the current cursor position
;
; TEXT control H routine: delete pprevious char
;
R_TEXT_CTRL_H_FUN:						;610BH
    CALL    R_TEXT_CTRL_C_FUN			;TEXT control C routine
    CALL    L_GET_CRSPOS_ADDR			;Get address in .DO file of current cursor position
    CALL    L_SETCRS_FROM_HL			;Reposition TEXT LCD cursor to file pos in HL
    CALL    L_TEXT_CTRL_E_FUN_1
    RC
L_TEXT_CTRL_H_FUN_1:
    CALL    R_TEXT_CTRL_C_FUN			;TEXT control C routine
    CALL    L_GET_CRSPOS_ADDR			;Get address in .DO file of current cursor position
    PUSH    H
    CALL    L_SETCRS_FROM_HL			;Reposition TEXT LCD cursor to file pos in HL
    POP     H
    MOV     A,M
    CPI     1AH							;^Z
    RZ
    PUSH    PSW
    PUSH    H
    PUSH    H
    CALL    L_SAV_PREV_LINEPTR
    POP     H
-	CALL    L_DELETE_DO					;Delete byte in .DO file at address HL
    CALL    L_UPDATE_LINE_PTRS_1
    POP     H
    POP     PSW
    CPI     0DH
    JNZ     L_TEXT_CTRL_H_FUN_2
    MOV     A,M
    CPI     0AH
    JNZ     L_TEXT_CTRL_H_FUN_2
    PUSH    PSW
    PUSH    H
    JMP     -

L_TEXT_CTRL_H_FUN_2:
    PUSH    H
    LDA     CSRY_R						;Cursor row (1-8)
    CALL    L_DISP_LINENUM
    POP     H
    JMP     L_VALIDATE_TEXT_PTR
;
; TEXT left arrow and control S routine
;
R_TEXT_CTRL_S_FUN:						;6151H
    CALL    L_TEXT_CTRL_E_FUN_1
    STC
;
; TEXT up arrow and control E routine
;
R_TEXT_CTRL_E_FUN:						;6155H
    CNC     L_TEXT_CTRL_E_FUN_2
    JMP     L_UPDATE_SEL

L_TEXT_CTRL_E_FUN_1:
    LHLD    CSRY_R						;Cursor row (1-8), Column (1-40)
    DCR     H
    JNZ     L_TEXT_CTRL_E_FUN_3			;brif Column != 0: Set the current cursor position
    LDA     LINWDT_R					;Active columns count (1-40)
    MOV     H,A
L_TEXT_CTRL_E_FUN_2:
    PUSH    H
    CALL    L_GET_CRS_LINEPTR			;Get address in .DO file of start of current row in DE
    LHLD    DOLOAD_R					;Load start address of .DO file being edited
    COMPAR								;HL - DE
    POP     H
    CMC
    RC
    DCR     L
    CZ      L_UPD_LCD_UP
L_TEXT_CTRL_E_FUN_3:
    CALL    R_SET_CURSOR_POS			;Set the current cursor position
    ANA     A
    RET

;
; TEXT control F routine
;
R_TEXT_CTRL_F_FUN:						;617AH
    CALL    L_GET_CRSPOS_ADDR			;Get address in .DO file of current cursor position
-	CALL    L_TEXT_CTRL_A_FUN_2
    JNZ     -
-	CALL    L_TEXT_CTRL_A_FUN_2
    JZ      -
    JMP     L_TEXT_CTRL_A_FUN_1

;
; TEXT control A routine
;
R_TEXT_CTRL_A_FUN:						;618CH
    CALL    L_GET_CRSPOS_ADDR			;Get address in .DO file of current cursor position
-	CALL    L_TEXT_CTRL_A_FUN_3
    JZ		-
-	CALL    L_TEXT_CTRL_A_FUN_3
    JNZ		-
    CALL    L_TEXT_CTRL_A_FUN_2
L_TEXT_CTRL_A_FUN_1:
    CALL    L_VALIDATE_TEXT_PTR
    JMP     L_UPDATE_SEL

L_TEXT_CTRL_A_FUN_2:
    MOV     A,M
    CPI     1AH							;^Z
    POP     B
    JZ      L_TEXT_CTRL_A_FUN_1
    INX     H
    JMP     +

L_TEXT_CTRL_A_FUN_3:
    XCHG
    LHLD    DOLOAD_R					;Load start address of .DO file being edited
    XCHG
    COMPAR								;HL - DE
    POP     B
    JZ      L_TEXT_CTRL_A_FUN_1
    DCX     H
+	PUSH    B
    PUSH    H
    MOV     A,M
    CALL    L_TEST_WWRAP_CHARS_2
    POP     H
    RET

;
; TEXT control T routine
;
R_TEXT_CTRL_T_FUN:						;61C2H
    DCR     L
    MVI     L,01H
    JNZ     L_TEXT_CTRL_T_FUN_1
    PUSH    H
    CALL    L_GET_CRS_LINEPTR			;Get address in .DO file of start of current row in DE
    XCHG
    CALL    L_TEXT_CTRL_Z_FUN_2
    POP     H
L_TEXT_CTRL_T_FUN_1:
    CALL    R_SET_CURSOR_POS			;Set the current cursor position
    JMP     L_UPDATE_SEL

;
; TEXT control B routine
;
R_TEXT_CTRL_B_FUN:						;61D7H
    PUSH    H
    INR     L
    CALL    L_GET_LCD_ROWS				;Get # of LCD rows based on label protect, preserve flags
    INR     A
    CMP     L
    JNZ     L_TEXT_CTRL_B_FUN_1
    PUSH    PSW
    CALL    L_GET_CRS_LINEPTR			;Get address in .DO file of start of current row in DE
    XCHG
    MVI     A,01H
    CALL    L_TEXT_CTRL_Z_FUN_3
    POP     PSW
L_TEXT_CTRL_B_FUN_1:
    DCR     A
    CALL    L_GET_LINEPTR				;Get address in .DO file of start of row in 'A'  
    MOV     B,A
    INX     D
    MOV     A,D
    ORA     E
    MOV     A,B
    JZ      L_TEXT_CTRL_B_FUN_1
    POP     H
    MOV     L,A
    JMP     L_TEXT_CTRL_T_FUN_1

;
; TEXT control R routine
;
R_TEXT_CTRL_R_FUN:						;61FDH
    LDA     LINWDT_R					;Active columns count (1-40)
    MOV     H,A
    CALL    R_SET_CURSOR_POS			;Set the current cursor position
    CALL    L_GET_CRSPOS_ADDR			;Get address in .DO file of current cursor position
    CALL    L_FND_CHAR_HL_LINEPTR		;Find address of 1st char on LCD line for ROW containing file pos in HL
	SKIP_2BYTES_INST_BC
;
; TEXT control Q routine
;
R_TEXT_CTRL_Q_FUN:						;620BH
    MVI     H,01H
    JMP     L_TEXT_CTRL_T_FUN_1

;
; TEXT control W routine
;
R_TEXT_CTRL_W_FUN:						;6210H
    LHLD    DOLOAD_R					;Load start address of .DO file being edited
    CALL    L_TEXT_CTRL_Z_FUN_4
    CALL    R_HOME_CURSOR			  	;Home cursor
    JMP     L_UPDATE_SEL

;
; TEXT control Z routine:
;
R_TEXT_CTRL_Z_FUN:						;621CH
    LHLD    TXTEND_R
    PUSH    H							;save HL
    CALL    L_GETLSTLINE
    POP     H							;restore HL
    COMPAR								;HL - DE
    PUSH    H
    CNC     L_TEXT_CTRL_Z_FUN_2			;calif HL > Last TxtLine Ptr
L_TEXT_CTRL_Z_FUN_1:
    POP     H
    CALL    L_SETCRS_FROM_HL			;Reposition TEXT LCD cursor to file pos in HL
    JMP     L_UPDATE_SEL

L_TEXT_CTRL_Z_FUN_2:
    CALL    L_GET_LCD_ROWS				;Get # of LCD rows based on label protect, preserve flags
L_TEXT_CTRL_Z_FUN_3:
    CALL    L_CALC_LINE_STRTS			;calculate the Line Starts array for the LCD
L_TEXT_CTRL_Z_FUN_4:
    CALL    L_ISFRSTLIN					;TXTLINTBL_R to DE, COMPAR
    RZ									;retif HL == First Line
	SHLD    TXTLINTBL_R					;Storage of TEXT Line Starts
    MVI     A,01H
    JMP     L_DISP_LINENUM_IN_A			;Display line 1 of the .DO file at HL
;
; TEXT control L routine: SELECT
;
R_TEXT_CTRL_L_FUN:						;6242H
    CALL    R_TEXT_CTRL_C_FUN			;TEXT control C routine
    CALL    L_GET_CRSPOS_ADDR			;Get address in .DO file of current cursor position
    SHLD    DOADDR_R					;Start address in .DO file of SELection for copy/cut
    SHLD    DOEND_R						;End address in .DO file of SELection for copy/cut
    MOV     E,L							;DE=HL
    MOV     D,H
    JMP     L_UPDATE_SEL_1

L_UPDATE_LINE_PTRS:
    MVI     C,00H						;00H entry point
	SKIP_2BYTES_INST_HL
L_UPDATE_LINE_PTRS_1:					;80H entry point
    MVI     C,80H
    CALL    L_GET_LCD_ROWS				;Get # of LCD rows based on label protect, preserve flags
    LXI     H,CSRY_R				    ;Cursor row (1-8)
    SUB     M							;number of LCD rows - Cursor row
    MOV     B,A							;save loop counter
    CALL    L_GET_CRS_LINEPTR			;Get address in .DO file of start of current row in DE 
    INX     H
-	INX     H							;get DE from M with preincrement
    MOV     E,M
    INX     H
    MOV     D,M
    INX     D							;test for 0FFFFH
    MOV     A,D
    ORA     E
    RZ									;retif DE was 0FFFFH
    DCR     C
    JM      +							;brif C negative
    DCX     D							;decrement DE
    DCX     D
+	DCX     H							;copy line ptr to M with predecrement
    MOV     M,E
    INX     H
    MOV     M,D
    DCR     B
    JP      -							;brif B >= 0
    RET
;
; Scroll
;
L_SCROLL_SCREEN:
    CALL    R_HOME_CURSOR				;Home cursor
    CALL    R_DEL_CUR_LINE				;Delete current line on screen
    CALL    L_GET_LCD_ROWS				;Get # of LCD rows based on label protect, preserve flags
L_MOVE_LINE_PTRS:
    ADD     A							;double because we move a ptr for each line
    MOV     B,A							;scroll line ptrs
    LXI     D,TXTLINTBL_R				;Storage of TEXT Line Starts
    LXI     H,TXTLINTBL_R+2
    JMP     R_MOVE_B_BYTES				;Move B bytes from M to (DE)
;
; TEXT control C routine: copy selection
;
R_TEXT_CTRL_C_FUN:						;628FH
    CALL    L_TEST_SEL					;Test for a valid SEL region. return to caller if not valid
    PUSH    H
    LXI     H,0
    SHLD    DOADDR_R					;Start address in .DO file of SELection for copy/cut
    CALL    L_GET_CRSPOS_ADDR			;Get address in .DO file of current cursor position
    POP     D
    JMP     +
;
L_UPDATE_SEL:
    CALL    L_TEST_SEL					;Test for a valid SEL region. return to caller if not valid
    CALL    L_GET_CRSPOS_ADDR
    XCHG
    LHLD    DOEND_R						;End address in .DO file of SELection for copy/cut
    COMPAR								;Compare DE and DOEND_R: HL - DE
    RZ									;retif equal  
    XCHG
	SHLD    DOEND_R						;End address in .DO file of SELection for copy/cut
+	CALL    L_MAKE_DE_MAX
L_UPDATE_SEL_1:
    PUSH    H							;save HL
    PUSH    D							;save DE
    CALL    L_GETLSTLINE
    POP     H							;restore saved DE to HL
    COMPAR								;HL - DE
    JC      +							;brif HL < last TxtLine
    CALL    L_NUM_LCD_ROWS				;Get # of LCD rows based on label protect # of cols in HL
+	CC      L_FND_CHAR_HL_LINEPTR		;Find address of 1st char on LCD line for ROW containing file pos in HL
    MOV     H,L
    XTHL
    CALL    L_ISFRSTLIN					;TXTLINTBL_R to DE, COMPAR
    JNC     +							;brif HL >= TXTLINTBL_R
    MVI     L,01H
+	CNC     L_FND_CHAR_HL_LINEPTR		;Find address of 1st char on LCD line for ROW containing file pos in HL
    POP     PSW
    SUB     L
    MOV     C,A
    XCHG
    LHLD    CSRY_R						;Cursor row (1-8) + column (1-40) to DE
    XCHG
    PUSH    D							;save cursor position
    MVI     H,01H
    CALL    R_SET_CURSOR_POS			;Set the current cursor position
    CALL    L_GET_CRS_LINEPTR			;Get address in .DO file of start of current row in DE
    MOV     A,C							;loop counter
-	PUSH    PSW							;save A
    CALL    L_DISP_LINE
    POP     PSW							;restore A
    DCR     A							;counter
    JP      -							;brif counter >= 0
    JMP     L_SET_CURSOR_POS_FROM_STACK	;Set the cursor position from pushed position
;
; Test for a valid SEL region. return to caller if not valid
;
; OUT:
;	HL		[DOADDR_R]
;
L_TEST_SEL:
    LHLD    DOADDR_R					;Start address in .DO file of SELection for copy/cut
    MOV     A,H							;test HL
    ORA     L
    RNZ									;retif Start address != 0
    POP     H							;remove return address		
    RET
;
; IN:
;	HL		TEXT line ptr
;
L_VALIDATE_TEXT_PTR:
    CALL    L_ISFRSTLIN					;TXTLINTBL_R to DE, COMPAR
    CC      L_UPD_LCD_UP_1				;calif HL < First TEXT line
    JC      L_VALIDATE_TEXT_PTR						;brif carry set on return
-	PUSH    H							;save TEXT line ptr
    CALL    L_GETLSTLINE				;last TEXT line ptr to DE
    POP     H							;restore TEXT line ptr
    COMPAR								;HL - DE
    CNC     L_UPD_LCD_DWN_1
    JNC     -
; 
; Reposition TEXT LCD cursor to file pos in HL
; 
L_SETCRS_FROM_HL:						;Reposition TEXT LCD cursor to file pos in HL
    CALL    L_FND_CHAR_HL_LINEPTR		;Find address of 1st char on LCD line for ROW containing file pos in HL
    JMP     R_SET_CURSOR_POS			;Set the current cursor position
;
; IN:
;	L == 0
;
L_UPD_LCD_DWN:
    DCR     L
L_UPD_LCD_DWN_1:
    PUSH    PSW
    PUSH    H
    CALL    L_SCROLL_SCREEN				;scroll
    CALL    L_GET_LCD_ROWS				;Get # of LCD rows based on label protect, preserve flags
    JMP     L_SHOW_LINE					;tail merge
;
; IN:
;	L == 0
;
L_UPD_LCD_UP:
    INR     L
L_UPD_LCD_UP_1:
    PUSH    PSW							;save PSW and HL
    PUSH    H
    CALL    L_SET_CUR_LSTLIN			;Set cursor and clear last line
    CALL    R_HOME_CURSOR				;Home cursor
    CALL    R_INSERT_LINE				;Insert line at current line
    CALL    L_GET_PREV_LINEPTR			;result in DE
    PUSH    D							;save previous line ptr
    CALL    L_GETLSTLINE
    INX     H
    MOV     E,L
    MOV     D,H
    DCX     H							;HL -= 2
    DCX     H
    DCR     A							;--A
    ADD     A							;double lines to ptr bytes
    MOV     C,A							;zero extend A to BC
    MVI     B,00H
    CALL    R_MOVE_BC_BYTES_DEC      	;Move BC bytes from M to (DE) with decrement
    XCHG
    POP     D							;restore previous line ptr
    MOV     M,D							;store at M decrementing
    DCX     H
    MOV     M,E
    MVI     A,01H
L_SHOW_LINE:							;tail merged
    CALL    L_DISP_LINENUM_IN_A			;Display line 'A' of the .DO file at HL
    POP     H							;restore HL and PSW
    POP     PSW
    RET   
	
; 
; Expand .DO file so it fills all memory for editing
; HL points to end of file. Fill with zeros
; 
L_EXPND_DO:
    LHLD    STRGEND_R					;Unused memory pointer
    LXI     B,00C8H
    DAD     B
    XRA     A
    SUB     L
    MOV     L,A
    SBB     A							;0 or 0FFH dependent on carry
    SUB     H
    MOV     H,A
    DAD     SP
    RNC
    MOV     A,H							;test HL
    ORA     L
    RZ									;retif counter == 0   
    MOV     B,H							;counter
    MOV     C,L
    LHLD    TXTEND_R
    XCHG
    INX     D
    CALL    L_MOV_DATA					;Move all files / variables after this file
-	MVI     M,00H						;fill byte in DO file with zero
    INX     H							;next
    DCX     B							;test loop counter BC
    MOV     A,B
    ORA     C
    JNZ     -							;brif not done
    RET

L_FND_END_DO_FILES:
    LHLD    DOSTRT_R					;DO files pointer
-	CALL    L_FNDEOFTXT					;Find EOF at HL Text Line
    INX     H							;ptr to next DO file
    XCHG
    LHLD    COSTRT_R					;CO files pointer to DE
    XCHG
    COMPAR								;HL - DE
    RNC									;retif HL >= DE  
    MOV     A,M							;first char of next DO file
    ANA     A							;test if
    JNZ     -							;brif != 0
; 
; Delete zeros from end of edited DO file and update pointers
; 
L_DEL_ZEROS:
    LHLD    TXTEND_R					;Pointer to end of .DO file
    PUSH    H							;save it
    LXI     B,0FFFFH					;Initialize zero count to -1
    XRA     A							;Prepare to test for zero in file
-	INX     H							;Increment file pointer
    INX     B							;Increment counter
    CMP     M							;Test if next byte is zero
    JZ      -							;brif byte == 0
    POP     H							;restore ptr to end of .DO file
    INX     H							;Increment to 1st zero in file
    JMP     MASDEL						;Delete BC characters at M. BC negated on exit.

; 
; Insert byte in A to .DO file at M (address of current file pointer)
; 
L_INSRT_DO:
    XCHG								;Save address of current file pointer to DE
    LHLD    TXTEND_R					;Pointer to end of .DO file
    INX     H							;Prepare to test if room in .DO file
    INR     M							;Test byte at end of .DO file
    DCR     M
    STC									;Preset Carry to indicate full
    RNZ									;Return if no room left in .DO file
    PUSH    PSW							;Save byte to insert
    SHLD    TXTEND_R					;Pointer to end of .DO file
    XCHG
	MOV     A,E							;Calculate number of bytes to move from
	SUB		L							;current file position to the end of the file
	MOV		C,A							;LSB of count
	MOV		A,D
	SBB		H
	MOV		B,A							;MSB of count
	MOV		L,E							;ptr to end of .DO file
	MOV		H,D
	DCX		H							;Decrement HL to insert one byte
	CALL	R_MOVE_BC_BYTES_DEC			;Move BC bytes from M to (DE) with decrement
	INX		H							;Increment back to insertion point after move above
	POP		PSW							;Retrieve byte to be inserted from stack
	MOV		M,A							;Insert the byte into the .DO file
	INX		H							;Increment current file pointer
	ANA		A							;Clear carry to indicate not full
    RET

; 
; Delete byte in .DO file at address HL.
; 
L_DELETE_DO:
    XCHG								;File ptr to DE
    LHLD    TXTEND_R					;Ptr to end of .DO file
    MOV     A,L							;Calculate number of bytes to move from
    SUB     E							;end of the file to current file position
    MOV     C,A							;LSB of count
    MOV     A,H
    SBB     D
    MOV     B,A							;MSB of count
    DCX     H
    SHLD    TXTEND_R					;Update ptr to end of .DO file
    MOV     L,E							;File ptr to HL
    MOV     H,D
    INX     H							;+1
    CALL    R_MOVE_BC_BYTES_INC      	;Move BC bytes from M to (DE) with increment
    XRA     A
    STAX    D							;Insert 0 byte at the end of the .DO file
    RET
;
; Get # of LCD rows based on label protect, preserve flags
;
; OUT:
;	A
;
L_GET_LCD_ROWS:
    PUSH    H							;save HL
    PUSH    PSW							;save flags
    LXI     H,LINPROT_R				    ;Label line protect status
    LDA     LINCNT_R					;Console height
    ADD     M							;add status: 0 or -1?
    MOV     L,A							;save result
    POP     PSW							;restore flags
    MOV     A,L							;restore result
    POP     H							;restore HL
    RET
;
; Get # of LCD rows based on label protect + cols in HL
;
; OUT:
;	L		#of LCD rows
;
L_NUM_LCD_ROWS:
    PUSH    PSW
    LHLD    LINCNT_R					;Console height + Console width
    CALL    L_GET_LCD_ROWS				;Get # of LCD rows based on label protect, preserve flags
    MOV     L,A
    POP     PSW
    RET
;
; Get next byte for TEXT Program entry
;
R_TEXT_GET_NEXT_BYTE:				    ;63E5H
    LHLD    CSRY_R						;Cursor row (1-8) & Column (1-40)
    PUSH    H							;save row & column
    MOV     A,L							;Row
    STA     LINENA_R					;Label line enable flag
    LDA     LINPROT_R					;Label line protect status
    PUSH    PSW							;save LINPROT_R
    CALL    R_WAIT_KEY					;Wait for key from keyboard
L_TEXT_BYTE:							;used by VT100 code
    POP     B							;restore LINPROT_R (from PSW)
    POP     H							;restore row & column
    PUSH    PSW							;save A
    XRA     A
    STA     LINENA_R					;Label line enable flag
    LDA     LINPROT_R					;Label line protect status
    CMP     B							;LINPROT_R changed?
    JNZ     +							;brif changed
    POP     PSW							;restore A
    RET
;
; LINPROT_R changed
;
; IN:
;	A == LINPROT_R
;	L
;
+	ANA     A							;test LINPROT_R
    JZ      +							;brif LINPROT_R == 0
    LDA     CSRY_R						;Cursor row (1-8)
    CMP     L
    LDA     LINCNT_R					;Console height
    CNZ     L_MOVE_LINE_PTRS					;move line
    POP     PSW
    RET
;
; LINPROT_R == 0
;
+	PUSH    H
    LDA     LINCNT_R					;Console height
    DCR     A
    CALL    L_GET_LINEPTR				;Get address in .DO file of start of row in 'A'  
    INX     H
    MVI     M,0FEH						;254
    INX     H
    INX     H
    MVI     M,0FEH
    DCR     A
    CALL    L_DISP_LINENUM_IN_A			;Display line 'A' of the .DO file at HL
    XRA     A
    STA     PNDERR_R
    POP     H
    CALL    R_SET_CURSOR_POS			;Set the current cursor position (H=Row,L=Col)
    POP     PSW
    RET
;
; TEXT control O routine: COPY
;
R_TEXT_CTRL_O_FUN:						;6431H
    CALL    L_TEST_SEL					;Test for a valid SEL region. return to caller if not valid
    CALL    L_DEL_ZEROS					;Delete zeros from end of edited DO file and update pointers
    CALL    L_COPY_SEL
    PUSH    PSW							;save A/Flags
    CALL    L_EXPND_DO					;Expand .DO file so it fills all memory for editing
    POP     PSW							;restore A/Flags
    JNC     R_TEXT_CTRL_C_FUN			;TEXT control C routine
    JMP     L_ERR_MEMFULL				;carry set
;
; TEXT control U routine: CUT function
;
R_TEXT_CTRL_U_FUN:						;6445H
    CALL    L_TEST_SEL					;Test for a valid SEL region. return to caller if not valid
    CALL    L_DEL_ZEROS					;Delete zeros from end of edited DO file and update pointers
    CALL    L_COPY_SEL
    PUSH    PSW
    CNC     MASDEL						;Delete BC characters at M. BC negated on exit.
    POP     PSW
    JNC     L_TEXT_CTRL_U_1
    MOV     A,B
    ANA     A
    JZ      +
-	CALL    R_KICK_PWR_OFF_WDT			;Renew automatic power-off counter
    PUSH    B
    LXI     B,0100H
    CALL    L_TEXT_CTRL_U_2
    POP     B
    DCR     B
    JNZ     -
+	MOV     A,C
    ANA     A
    CNZ     L_TEXT_CTRL_U_2
L_TEXT_CTRL_U_1:
    LXI     D,0
    XCHG
    SHLD    DOADDR_R					;Start address in .DO file of SELection for copy/cut
    XCHG
    PUSH    H
    LDA     CSRY_R						;Cursor row (1-8)
    CALL    L_DISP_A_LINES				;Display 'A' lines of the .DO file at HL for editing
    POP     H
    CALL    L_SETCRS_FROM_HL			;Reposition TEXT LCD cursor to file pos in HL
    CALL    L_FNDEOFDO					;Find end of DO file
    JMP     L_EXPND_DO					;Expand .DO file so it fills all memory for editing

L_TEXT_CTRL_U_2:
    PUSH    H
    PUSH    B
    XCHG
    LHLD    FCB1_BUF_R					;ptr to buffer first file
    XCHG
    CALL    R_MOVE_BC_BYTES_INC      	;Move BC bytes from M to (DE) with increment
    POP     B
    POP     H
    PUSH    H
    PUSH    B
    CALL    MASDEL						;Delete BC characters at M. BC negated on exit.
    LHLD    HAYASHI_R+1					;Start of Paste Buffer
    DAD     B
    XCHG
    POP     B
    CALL    L_MOV_DATA					;Move all files / variables after this file
    XCHG
    LHLD    FCB1_BUF_R					;ptr to buffer first file
    CALL    R_MOVE_BC_BYTES_INC      	;Move BC bytes from M to (DE) with increment
    POP     H
    RET

; 
; Get address of start/end of copy/cut SEL in HL,DE ensuring HL less than DE
; 
L_GET_SEL_PTRS:
    LHLD    DOADDR_R					;Start address in .DO file of SELection for copy/cut
    XCHG								;to DE
    LHLD    DOEND_R						;End address in .DO file of SELection for copy/cut
L_MAKE_DE_MAX:
    COMPAR								;HL - DE
    RC									;brif DOEND_R < DOADDR_R
    XCHG
    RET

L_COPY_SEL:
    CALL    L_CLR_PASTE_BUF
    LHLD    HAYASHI_R+1					;Start of Paste Buffer
    SHLD    EOMFILE_R					;End of RAM for file storage
    XRA     A
    STA     PASTEFLG_R
    CALL    L_GET_SEL_PTRS
    DCX     D
;
; Copy PASTE buffer to .DO file
;
; IN:
;	DE		paste buffer 1
;	HL		paste buffer 2
; OUT:
;	BC
;	HL
;
L_COPY_PASTE:
    MOV     A,E							;Calculate length of SELection: BC = DE - HL
    SUB     L
    MOV     C,A
    MOV     A,D
    SBB     H
    MOV     B,A
    JC      L_COPY_PASTE_1
    LDAX    D
    CPI     1AH							;^Z
    JZ      L_COPY_PASTE_2
    CPI     0DH							;CR
    JNZ     L_COPY_PASTE_1
    INX     D
    LDAX    D
    CPI     0AH							;LF
    JNZ     L_COPY_PASTE_1
    INX     B
L_COPY_PASTE_1:
    INX     B
L_COPY_PASTE_2:
    MOV     A,B							;test BC
    ORA     C
    RZ									;return if length of SELection == 0
    PUSH    H
    LHLD    EOMFILE_R					;End of RAM for file storage
    CALL    MAKHOL						;Insert BC spaces at M
    XCHG
    POP     H
    RC									;return if insertion failed
    LDA     PASTEFLG_R
    ANA     A
    JZ      +
    DAD     B
+	PUSH    H
    PUSH    B
    CALL    R_MOVE_BC_BYTES_INC      	;Move BC bytes from M to (DE) with increment
    POP     B
    POP     H
    RET
;
; Paste routine. Insert PASTE buffer into .DO file
;
L_INSRT_PASTE:
    CALL    R_TEXT_CTRL_C_FUN			;TEXT control C routine
    CALL    L_DEL_ZEROS					;Delete zeros from end of edited DO file and update pointers
    CALL    LNKFIL						;Fix up the directory start pointers
    CALL    L_GET_CRSPOS_ADDR			;Get address in .DO file of current cursor position
    SHLD    EOMFILE_R					;End of RAM for file storage
    MOV     A,H
    STA     PASTEFLG_R
    LHLD    HAYASHI_R+1					;Start of Paste Buffer
    MOV     A,M							;get char
    CPI     1AH							;^Z
    JZ      L_EXPND_DO					;brif Paste Buffer starts with ^Z:
										;	Expand .DO file so it fills all memory for editing
    MOV     E,L							;DE = HL
    MOV     D,H
    DCX     D							;pre-decrement
-	INX     D
    LDAX    D
    CPI     1AH							;^Z
    JNZ     -							;loop
    CALL    L_COPY_PASTE				;Copy PASTE buffer to .DO file
    PUSH    PSW
    PUSH    D
    CALL    L_FNDEOFDO					;Find end of DO file (find the 1Ah)
    CALL    L_EXPND_DO					;Expand .DO file so it fills all memory for editing
    POP     D
    POP     PSW
    JC      L_ERR_MEMFULL
;
; Redraw and position cursor after PASTE operation.
;
    PUSH    D
    LHLD    EOMFILE_R					;End of RAM for file storage
    LDA     CSRY_R						;Cursor row (1-8)
    CALL    L_DISP_A_LINES				;Display 'A' lines of the .DO file at HL for editing
    CALL    L_GETLSTLINE				;Get address in .DO file of start of row
										;	just below visible LCD
    POP     H
    COMPAR								;HL - DE
    CALL    L_GET_LCD_ROWS				;Get # of LCD rows based on label protect, preserve flags
    PUSH    H
    CNC     L_DISP_A_LINES				;Display 'A' lines of the .DO file for editing
    POP     H
    JMP     L_SETCRS_FROM_HL			;Reposition TEXT LCD cursor to file pos in HL
;
; TEXT control N routine: FIND
;
R_TEXT_CTRL_N_FUN:						;6551H
    CALL    L_CHECK_LCD_SCROLL_1
    CALL    L_GET_CRSPOS_ADDR			;Get address in .DO file of current cursor position
    PUSH    H
    LXI     H,L_String_MSG				;Code Based.
    LXI     D,SEARCHSTR_R
    PUSH    D
    CALL    L_QUERY_USER				;Print a message to display and request keyboard input
    POP     D
    INX     H
    MOV     A,M
    ANA     A
    STC
    JZ      +
    CALL    R_COPY_STRING       		;Copy NULL terminated string at M to (DE)
    POP     D
    PUSH    D
    LDAX    D
    CPI     1AH
    JZ      L_TEXT_CTRL_N_1
    INX     D
    CALL    R_FIND_TEXT_IN_FILE      	;Find text at M in the file at (DE)
    JNC     L_TEXT_CTRL_N_1
    POP     D
    PUSH    B
    PUSH    B
    CALL    L_GETLSTLINE
    POP     H
    COMPAR								;HL - DE
    JC      +
    CALL    L_DISP_SCREEN
    ANA     A
+	CC      L_CLR_PNDERR_1
    STC
L_TEXT_CTRL_N_1:
    LXI     H,L_Nomatch_MSG				;Code Based. 
    CNC     L_PRNT_ERRMSG
    JMP     L_TEXT_CTRL_Z_FUN_1

L_CHECK_LCD_SCROLL:
    CALL    R_TEXT_CTRL_C_FUN			;Check for TEXT Copy selection
L_CHECK_LCD_SCROLL_1:
    LHLD    CSRY_R						;Cursor row (1-8) + column (1-40)
    CALL    L_GET_LCD_ROWS				;Get # of LCD rows based on label protect, preserve flags
    CMP     L							;compare # of rows
    RNZ									;retif not equal
    DCR     L							;at max, decrement
    PUSH    H							;arg for L_SET_CURSOR_POS_FROM_STACK
    CALL    L_SCROLL_SCREEN				;scroll
    JMP     L_SET_CURSOR_POS_FROM_STACK

L_PRNT_ABORT:
    LXI     H,L_Aborted_MSG				;Code based
L_PRNT_ERRMSG:							;HL loaded
    MVI     A,01H
    STA     PNDERR_R
L_PRNT_MSG:
    CALL    L_SET_CUR_LSTLIN			;clear last line. HL preserved
    CALL    R_PRINT_STRING			 	;Print 
L_GET_KEY:
    CALL    R_CHK_KEY_QUEUE				;Check keyboard queue for pending characters
    RZ
    CALL    R_WAIT_KEY				   	;Wait for key from keyboard
    JMP     L_GET_KEY

;
; Copy NULL terminated string at M to (DE)
;
R_COPY_STRING:							;65C3H
    PUSH    H
-	MOV     A,M
    STAX    D
    INX     H
    INX     D
    ANA     A
    JNZ     -
    POP     H
    RET

L_Nomatch_MSG:
    DB      "No match",00H

L_String_MSG:
    DB      "String:",00H
;
; Set Cursor to last LCD line and clear Line
;
L_SET_CUR_LSTLIN:
    PUSH    H							;save HL
    CALL    L_NUM_LCD_ROWS				;Get # of LCD rows based on label protect + cols in HL
										;	result in L
    MVI     H,01H
    CALL    R_SET_CURSOR_POS			;Set the current cursor position
    POP     H							;restore HL
    JMP     R_ERASE_TO_EOL				;Erase from cursor to end of line

L_CLR_PNDERR:
    LXI     H,PNDERR_R
    XRA     A
    CMP     M
    RZ									;return if PNDERR_R == 0
    MOV     M,A							;clear PNDERR_R
L_CLR_PNDERR_1:
    LHLD    CSRY_R						;Cursor row (1-8) + column (1-40)
    PUSH    H							;arg for L_SET_CURSOR_POS_FROM_STACK
    CALL    L_GET_LCD_ROWS				;Get # of LCD rows based on label protect, preserve flags
    CALL    L_DISP_LINENUM_IN_A			;Display line 'A' of the .DO file at HL
    JMP     L_SET_CURSOR_POS_FROM_STACK

L_QUERY_USER_NULL:
    LXI     D,L_NULL_STR				;Code Based.
;
; Print a message on the display and request keyboard input
;
; IN:
;	DE		text buffer ptr
;	HL		Code Based message
;
L_QUERY_USER:
    PUSH    D							;save text buffer ptr
    CALL    L_PRNT_MSG					;HL input
    LDA     CSRX_R						;Cursor column (1-40)
    STA     CSRXSVD_R					;save it
    POP     H							;restore text buffer ptr to HL
    PUSH    H							;and save it
    CALL    R_PRINT_STRING				;Print buffer at M until NULL or '"'
-	CALL    R_WAIT_KEY				  	;Wait for key from keyboard
    JC      -
    ANA     A							;test key
    JZ      -
    POP     H							;restore text buffer ptr to HL
    CPI     0DH							;CR
    JZ      L_QUERY_USER_END			;brif key == CR
    PUSH    PSW							;save key
    CALL    L_NUM_LCD_ROWS				;Get # of LCD rows based on label protect + cols in HL
    LDA     CSRXSVD_R					;saved Cursor column
    MOV     H,A
    CALL    R_SET_CURSOR_POS			;Set the current cursor position
    CALL    R_ERASE_TO_EOL				;Erase from cursor to end of line
    POP     PSW							;restore key
    LXI     D,INPBUF_R					;Keyboard buffer
    MVI     B,01H						;counter
    ANA     A
    JMP     L_QUERY_USER_1

L_QUERY_USER_CNT:
    CALL    R_WAIT_KEY					;Wait for key from keyboard
L_QUERY_USER_1:
    LXI     H,L_QUERY_USER_CNT			;continuation function
    PUSH    H
    RC									;brif carry to continuation function
; L_QUERY_USER_CNT continuation function on stack
    CPI     7FH							;DEL
    JZ      R_INP_BKSP_HANDLER       	;Input routine backspace), left arrow), CTRL-H handler
    CPI     ' '
    JNC     L_INP_CHAR_HANDLER			;brif A >= ' '
    LXI     H,L_CTRL_CHARS-2			;Code Based. 
    MVI     C,(L_CTRL_CHARS_END-L_CTRL_CHARS)/3		;07H Table length
    JMP     R_VECTORTBL_LOOKUP

L_QUERY_USER_END:
    LXI     D,INPBUF_R				    ;Keyboard buffer
    CALL    R_COPY_STRING       		;Copy NULL terminated string at M to (DE)
    JMP		L_RET_INPBUF_PREDEC
;
; Control Chars Table
;
L_CTRL_CHARS:
    DB      03H							;^C
    DW 		L_INP_CTRL_C_HANDLER
    DB      08H							;BKSP
    DW		R_INP_BKSP_HANDLER
    DB      09H							;TAB
    DW		L_INP_TAB_HANDLER
    DB      0DH							;CR
    DW		L_INP_CR_HANDLER
    DB      15H
    DW		R_INP_CTRL_U_HANDLER
    DB      18H
    DW		R_INP_CTRL_U_HANDLER
    DB      1DH
    DW		R_INP_BKSP_HANDLER
L_CTRL_CHARS_END:
	
L_INP_CTRL_C_HANDLER:					;^C handler
    LXI     D,INPBUF_R					;Keyboard buffer start
L_INP_CR_HANDLER:						;CR handler
    POP     H
    XRA     A
    STAX    D
L_RET_INPBUF_PREDEC:
    LXI     H,INPBUF_R-1				;Keyboard buffer
    RET

L_INP_TAB_HANDLER:						;TAB handler
    MVI     A,09H
L_INP_CHAR_HANDLER:
    MOV     C,A							;save char
    LDA     LINWDT_R					;Active columns count (1-40)
    SUI     09H
    LXI     H,CSRX_R				    ;Cursor column (1-40)
    CMP     M
    JC      R_BEEP_STMT				    ;BEEP statement
    MOV     A,C							;restore char
    INR     B
    OUTCHR								;Send character in A to screen/printer
    STAX    D
    INX     D
    RET
;
; TEXT control Y routine: Prints the entire file
; Code asks for printer width
;
R_TEXT_CTRL_Y_FUN:						;6691H
    CALL    L_CHECK_LCD_SCROLL
    LXI     H,L_ABORT_HANDLER
    SHLD    ACTONERR_R					;active ON ERROR handler vector
    PUSH    H
    LHLD    CSRY_R						;Cursor row (1-8) + column (1-40)
    SHLD    TMPLIN_R					;temp storage for line ptr
    LXI     H,L_Width_MSG				;Code Based. 
    LXI     D,PRTBUF_R
    CALL    L_QUERY_USER				;Print a message to display and request keyboard input
    CHRGET								;Get next non-white char from M
    XRA     A
    CMP     M
    JZ      L_TEXT_CTRL_Y_END_0			;brif char == 0
    STA     0F688H						;clear 
    CALL    L_GETBYT					;Evaluate byte expression at M-1
    CPI     0AH							;LF
    RC									;retif char < LF
    CPI     85H
    RNC									;retif char >= 85H
    POP     D
    STA     PRTWDTH_R					;Printer output width from CTRL-Y
    STA     OUTFMTWIDTH_R				;Output format width (40 or something else for CTRL-Y)
    STA     PRTFLG_R					;Output device for RST 20H (0=screen)
    LXI     D,PRTBUF_R
    LXI     H,INPBUF_R				  	;Keyboard buffer
    CALL    R_COPY_STRING         		;Copy NULL terminated string at M to (DE)
    INR     A
    STA     LCDPRT_R					;LCD vs Printer output indication - output to LCD
    CALL    R_SEND_CRLF				  	;Send CRLF to screen or printer
    LHLD    DOLOAD_R					;Load start address of .DO file being edited
    XCHG
-	CALL    L_DISP_LINE
    MOV     A,D							;test DE
    ANA     E
    INR     A
    JNZ     -							;brif DE != 0FFFFH
    CALL    L_RESET_CONF				;reset configuration
L_TEXT_CTRL_Y_END_0:
    CALL    L_CLR_PNDERR_1
L_TEXT_CTRL_Y_END:
    LHLD    TMPLIN_R					;get temp storage for line ptr
    CALL    R_SET_CURSOR_POS			;Set the current cursor position
    JMP     R_TEXT_EDIT_LOOP			;Main TEXT edit loop
;
; Error handler
;
L_ABORT_HANDLER:
    CALL    L_RESET_CONF				;reset configuration
    CALL    L_CLS_FILE0					;close file 0 & Load LSTVAR_R
    CALL    L_PRNT_ABORT
    JMP     L_TEXT_CTRL_Y_END
;
;
L_RESET_CONF:
    LDA     LINWDT_R					;Active columns count (1-40)
    STA     OUTFMTWIDTH_R				;Output format width (40 or something else for CTRL-Y)
    XRA     A
    STA     PRTFLG_R					;Output device for RST 20H (0=screen)
    STA     LCDPRT_R					;LCD vs Printer output indication - output to LCD
    RET

L_Width_MSG:
    DB      "Width:",00H
;
; TEXT control G routine
;
R_TEXT_CTRL_G_FUN:						;6713H
    LXI     D,L_SaveTo_MSG				;Code Based. 
    CALL    L_GET_TXT_FNAME
    JC      L_ABORT_HANDLER				;brif DEVICE specified
    JZ      L_TEXT_CTRL_Y_END_0
    MVI     E,02H						;Marker Open for Output
    CALL    R_OPEN_FILE
    LHLD    DOLOAD_R					;Load start address of .DO file being edited
-	MOV     A,M
    OUTCHR								;Send character in A to screen/printer
    INX     H
    CPI     1AH							;^Z
    JNZ     -
    CALL    L_CLS_FILE0					;close file 0 & Load LSTVAR_R
    JMP     L_TEXT_CTRL_Y_END_0

L_SaveTo_MSG:
    DB      "Save to:",00H
;
; IN:
;	DE
; OUT:
;	carry, HL
;
L_GET_TXT_FNAME:
    PUSH    D							;save DE
    CALL    L_CHECK_LCD_SCROLL
    LXI     H,L_ABORT_HANDLER			;error handler
    SHLD    ACTONERR_R					;active ON ERROR handler vector
    LHLD    CSRY_R						;Cursor row (1-8), column (1-40)
    SHLD    TMPLIN_R					;temp storage for line ptr
    POP     H							;restore DE to HL
    CALL    L_QUERY_USER_NULL			;Query user, no message
    CHRGET								;Get next non-white char from M
    ANA     A
    RZ									;retif end of line
    CALL    R_STRLEN				    ;Count length of string at M
    CALL    L_PSH_HL_EVAL_FILNAM		;push HL and eval Filename. Device in D
    JNZ     +
    MVI     D,CAS_DEV					;0FDH default device
+	MOV     A,D
    CPI     RAM_DEV						;0F8H
    STC
    RZ
    CPI     CRT_DEV						;0FEH
    STC
    RZ
    CPI     LCD_DEV						;0FFH
    STC
    RZ
    LXI     H,L_NULL_STR				;Code Based.
    CMC
    MVI     A,00H
    RET
;
; TEXT control V routine: paste selection
;
R_TEXT_CTRL_V_FUN:						;6774H
    LXI     D,L_LoadFrom_MSG			;Code Based. 
    CALL    L_GET_TXT_FNAME
    JC      L_ABORT_HANDLER				;brif DEVICE specified
    JZ      L_TEXT_CTRL_Y_END_0
    PUSH    H
    LXI     H,L_TEXT_CTRL_V_4
    SHLD    ACTONERR_R					;active ON ERROR handler vector
    LHLD    TXTEND_R
    SHLD    TMPLIN_R					;temp storage for line ptr
    STA     TLCMKEY_R
    XTHL								;swap HL and [SP]
    MVI     E,01H						;marker Open for Input
    CALL    R_OPEN_FILE
    POP     H
L_TEXT_CTRL_V_1:
    CALL    L_DEV_INPUT
    JC      L_TEXT_CTRL_V_2				;brif error
    CALL    L_IS_CTRL_CHAR
    JZ      L_TEXT_CTRL_V_1
    JNC     +
    CALL    L_INSRT_DO					;Insert byte in A to .DO file at address HL.
    MVI     A,0AH
+	CNC     L_INSRT_DO					;Insert byte in A to .DO file at address HL.
    JNC     L_TEXT_CTRL_V_1
    CALL    L_CLS_FILE0					;close file 0 & Load LSTVAR_R
    CALL    L_ERR_MEMFULL
L_TEXT_CTRL_V_2:
    CALL    L_CLS_FILE0					;close file 0 & Load LSTVAR_R
L_TEXT_CTRL_V_3:
    CALL    L_FNDEOFDO					;Find end of DO file
    LHLD    TMPLIN_R					;temp storage for line ptr
    PUSH    H
    CALL    L_DISP_SCREEN
    POP     H
    CALL    L_SETCRS_FROM_HL			;Reposition TEXT LCD cursor to file pos in HL
    JMP     R_TEXT_EDIT_LOOP			;Main TEXT edit loop

L_TEXT_CTRL_V_4:
    CALL    L_CLS_FILE0					;close file 0 & Load LSTVAR_R
    CALL    L_PRNT_ABORT
    JMP     L_TEXT_CTRL_V_3

L_LoadFrom_MSG:
	DB		"Load from:",00H
;
; Build next line from .DO file at (DE) into line buffer
;
; IN:
;	DE
;
; OUT:
;	DE		0FFFFH if EOF
;
L_BDL_LINE_DE:
    XRA     A
    STA     DSPCOFF_R					;clear current column offset within display line buffer
    STA     PASTEFLG_R					;clear PASTEFLG_R
    LXI     H,LINBUF_R					;line buffer
    SHLD    CURPOS_R					;reset to start
; 
; Add next character from .DO file at (DE) into line buffer
; 
L_ADD_CHR:
    PUSH    D							;Save pointer into .DO file
    CALL    L_PROCESS_SEL				;Manage copy/cut SEL highlighting added to line buffer
    POP     D							;restore pointer into .DO file
    LDAX    D							;get char
    INX     D							;next
    CPI     1AH							;EOF
    JZ      L_ADD_EOF_CHAR				;brif EOF: Add Left arrow character to line buffer 
    CPI     0DH							;CR
    JZ      L_ADD_CR
    CPI     09H							;TAB
    JZ      +
    CPI     ' '
    JC      L_ADD_CTRL_CHAR				;brif control char
+	CALL    L_ADD_BUFF_TABS				;Add character in A to line buffer with TAB expansion
    JNC     L_ADD_CHR					;brif not at end of line buffer: add next character
    LDAX    D							;get char
    CALL    L_TEST_WWRAP_CHARS			;Test byte in A for word-wrap characters like '-', '(', ')', etc.
    JNZ     +							;brif no wrap char
    CALL    L_ADD_CHR_1					;LPT check
    LDAX    D							;get char
    CPI     ' '
    RNZ									;retif not ' '
    LDA     LCDPRT_R					;LCD vs Printer output indication - output to LCD
    ANA     A
    RZ									;retif LCDPRT_R==0
    INX     D							;next
    LDAX    D							;get char
    CPI     ' '
    RNZ									;retif not ' '
    DCX     D							;backup ptr
    RET
+	XCHG
    SHLD    EOMFILE_R					;End of RAM for file storage to DE
    XCHG
    LHLD    CURPOS_R					;temporarily save CURPOS_R
    SHLD    SAVCURPOS_R
    DCX     D							;Decrement to previous byte to test it for word-wrap
    LDAX    D							;get the previous byte
    INX     D							;back to this byte
    CALL    L_TEST_WWRAP_CHARS			;Test byte in A for word-wrap characters like '-', '(', ')', etc.
    JZ      L_ADD_CHR_1					;brif word-wrap
-	DCX     D							;Decrement to previous byte to test it for word-wrap
    LDAX    D							;get the previous byte
    INX     D							;back to this byte
    CALL    L_TEST_WWRAP_CHARS			;Test byte in A for word-wrap characters like '-', '(', ')', etc.
    JZ      L_DO_EOFLINE				;brif word-wrap: Test for end of format line
    DCX     D
    CALL    L_CURSOR_BACKUP				;Backup cursor position
    JNZ     -							;brif [DSPCOFF_R] != 0
    LHLD    SAVCURPOS_R					;restore temporarily saved CURPOS_R
    SHLD    CURPOS_R
    LHLD    EOMFILE_R					;End of RAM for file storage to DE
    XCHG
L_ADD_CHR_1:
    LDA     LCDPRT_R					;LCD vs Printer output indication - output to LCD
    DCR     A
    JZ      L_ADD_CRLF					;brif LCDPRT_R == 0
    RET

; 
; Insert control character into line buffer, preceeded by CARET
; 
L_ADD_CTRL_CHAR:
    PUSH    PSW							;save control char
    MVI     A,'^'						;5EH
    CALL    L_ADD_BUFF_TABS				;Add character in A to line buffer with TAB expansion
    JC      L_DEL_LAST_CHR				;Jump if no room in line buffer for actual code
    POP     PSW							;restore control char
    ORI     40H							;01000000 map control char to letters
    CALL    L_ADD_BUFF_TABS				;Add character in A to line buffer with TAB expansion
    JNC     L_ADD_CHR					;If not at end of line, add next character to line buffer
    LDA     LCDPRT_R					;LCD vs Printer output indication - output to LCD
    ANA     A
    JNZ     L_ADD_CRLF					;Jump if not output to LCD to add CRLF to line buffer
    RET

; 
; Remove last inserted character in line buffer
; 
L_DEL_LAST_CHR:
    POP     PSW
    DCX     D
    LHLD    CURPOS_R
    DCX     H
    SHLD    CURPOS_R
    LXI     H,DSPCOFF_R					;Current column offset within display line buffer
    DCR     M
    JMP     L_DO_EOFLINE				;Test for end of format line
; 
; Add Left arrow character to line buffer if LCD output to indicate EOF
; 
L_ADD_EOF_CHAR:
    LDA     LCDPRT_R					;LCD vs Printer output indication - output to LCD
    ANA     A
    MVI     A,9BH						;left arrow
    CZ      L_ADD_BUFF_TABS				;Add character in A to line buffer with TAB expansion
    CALL    L_DO_EOFLINE				;Test for end of format line
    LXI     D,0FFFFH
    RET
; 
; Add CR character to line buffer
;
; IN:
;	DE		
; 
L_ADD_CR:
    LDAX    D
    CPI     0AH							;LF
    MVI     A,0DH						;preload CR
    JNZ     L_ADD_CTRL_CHAR				;brif !LF
    PUSH    D							;save pointer into .DO file
    CALL    L_PROCESS_SEL				;Manage copy/cut SEL highlighting added to line buffer
    POP     D							;restore pointer into .DO file
    LDA     LCDPRT_R					;LCD vs Printer output indication - output to LCD
    ANA     A
    MVI     A,8FH						;Load ASCII code for CR mark on LCD
    CZ      L_ADD_BUFF_TABS				;Add character in A to line buffer with TAB expansion
    CALL    L_DO_EOFLINE				;Test for end of format line
    INX     D
    RET
;
; Add character in A to line buffer with TAB expansion
;
; IN:
;	A
; OUT:
;	Carry		set if at end of line buffer
;
L_ADD_BUFF_TABS:
    PUSH    H							;save HL
    CALL    L_ADD_TXT_CHR				;Add character in A to TEXT display line buffer
    LXI     H,DSPCOFF_R					;Current column offset within display line buffer
    CPI     09H							;TAB
    JZ      L_ADD_BUFF_TABS_1			;brif TAB
    INR     M							;increment DSPCOFF_R
    JMP     +							;Test if at end of line buffer
L_ADD_BUFF_TABS_1:						;Found TAB
    INR     M							;increment DSPCOFF_R
    MOV     A,M							;get DSPCOFF_R
    ANI     07H							;mod 8
    JNZ     L_ADD_BUFF_TABS_1			;brif mod 8 != 0
; 
; Test if at end of line buffer
; 
+	LDA     OUTFMTWIDTH_R				;Output format width (40 or something else for CTRL-Y)
    DCR     A
    CMP     M							;compare OUTFMTWIDTH_R and DSPCOFF_R
    POP     H							;restore HL
    RET

; 
; Add character in A to TEXT display line buffer
; 
L_ADD_TXT_CHR:
    LHLD    CURPOS_R					;current char position
    MOV     M,A
    INX     H
    SHLD    CURPOS_R					;update current char position
    RET
;
; Backup cursor position
;
; OUT:
;	Z		set if [DSPCOFF_R] == 0
;
L_CURSOR_BACKUP:
    LHLD    CURPOS_R					;get current char position
    DCX     H							;backup 3 positions
    DCX     H
    DCX     H
    MOV     A,M
    CPI     1BH							;ESC
    JZ      +							;brif char == ESC
    INX     H							;advance 2 positions
    INX     H
+	SHLD    CURPOS_R
    LXI     H,DSPCOFF_R					;Current column offset within display line buffer
    DCR     M
    RET

; 
; Test for end of format line, add ESC-K + CRLF to line buffer if at end
; 
L_DO_EOFLINE:
    LDA     DSPCOFF_R					;Current column offset within display line buffer
    LXI     H,OUTFMTWIDTH_R			;Output format width (40 or something else for CTRL-Y)
    CMP     M							;Test if we have reached the output format width
    RNC									;retif not at end of format line
    LDA     LCDPRT_R					;LCD vs Printer output indication - output to LCD
    ANA     A
    JNZ     L_ADD_CRLF					;Skip adding of ESCape sequence if not LCD
    MVI     A,1BH						;ESC
    CALL    L_ADD_TXT_CHR				;Add character in A to TEXT display line buffer
    MVI     A,'K'
    CALL    L_ADD_TXT_CHR				;Add character in A to TEXT display line buffer
L_ADD_CRLF:
    MVI     A,0DH						;CR
    CALL    L_ADD_TXT_CHR				;Add character in A to TEXT display line buffer
    MVI     A,0AH						;LF
    JMP     L_ADD_TXT_CHR				;Add character in A to TEXT display line buffer

; 
; Manage copy/cut SEL highlighting added to line buffer
;
; IN:
;	DE		ptr into .DO file
; 
L_PROCESS_SEL:
    CALL    L_TEST_SEL					;Test for a valid SEL region. return to caller if not valid
										;HL returns [DOADDR_R]
    LDA     LCDPRT_R					;LCD vs Printer output indication - output to LCD
    ANA     A
    RNZ									;Return if not output to LCD - no SEL highlighting to printer
    LXI     B,PASTEFLG_R				;used much later
    PUSH    D							;save ptr into .DO file
    XCHG
    LHLD    DOEND_R						;End address in .DO file of SELection for copy/cut to DE
    XCHG
; HL: [DOADDR_R]  DE: [DOEND_R]
    COMPAR								;Compare End address and HL: HL - DE
    POP     D							;restore ptr into .DO file
    JNC     +							;brif [DOADDR_R] >= [DOEND_R]
    XCHG								;[DOADDR_R] to DE
    COMPAR								;Compare [DOADDR_R] and ptr into .DO file: HL - DE
    JC      L_PROCESS_SEL_1				;brif ptr into .DO file < [DOADDR_R]
    XCHG
    LHLD    DOEND_R						;End address in .DO file of SELection for copy/cut to DE
    XCHG
    COMPAR								;Compare [DOEND_R] and ptr into .DO file: HL - DE
    JNC     L_PROCESS_SEL_1				;brif ptr into .DO file >= [DOEND_R]
-	LDAX    B							;[PASTEFLG_R]
    ANA     A
    RNZ									;retif [PASTEFLG_R] != 0
    INR     A							;A now 1: new [PASTEFLG_R] value
    MVI     H,'p'						;70H
    JMP     L_PROCESS_SEL_2				;output it
; HL: [DOADDR_R] DE: ptr into .DO file
+	XCHG
    COMPAR								;Compare [DOADDR_R] and ptr into .DO file: HL - DE
    JNC     L_PROCESS_SEL_1				;brif ptr into .DO file >= [DOADDR_R]
    XCHG
    LHLD    DOEND_R						;End address in .DO file of SELection for copy/cut to DE
    XCHG
    COMPAR								;Compare [DOEND_R] and ptr into .DO file: HL - DE
    JNC     -							;brif ptr into .DO file >= [DOEND_R]
L_PROCESS_SEL_1:
    LDAX    B							;[PASTEFLG_R]
    ANA     A
    RZ									;retif [PASTEFLG_R] == 0  
    XRA     A							;new [PASTEFLG_R] value
    MVI     H,'q'						;71H
L_PROCESS_SEL_2:
    PUSH    H							;save H ('p' or 'q')
    STAX    B							;update [PASTEFLG_R]
    MVI     A,1BH						;ESC
    CALL    L_ADD_TXT_CHR				;Add character in A to TEXT display line buffer
    POP     PSW							;restore H to A
    JMP     L_ADD_TXT_CHR				;Add character in A to TEXT display line buffer
;
; Test byte in A for word-wrap characters like '-', '(', ')', etc.
; IN:
;	A		operator to match
;
; OUT:
;	Z		set if match
;
L_TEST_WWRAP_CHARS:
    MOV     B,A
    LDA     WWRAP_R						;Get word-wrap enable flag
    ANA     A
    MOV     A,B
    RZ									;retif WWRAP_R==0
L_TEST_WWRAP_CHARS_2:
    LXI     H,L_WWRAP_CHARS				;Code Based. word-wrap chars list
    MVI     B,0AH						;count
-	CMP     M							;Code based
    RZ									;retif operator match
    INX     H							;next operator
    DCR     B							;update count
    JNZ     -
    CPI     '!'
    INR     B							;Clear zero flag to indicate no-wrap
    RNC									;retif character is not control code
    DCR     B							;Set zero flag to indicate wrap
    RET

L_WWRAP_CHARS:
    DB      "()<>[]+-*/"
; 
; Display entire screen of lines of the .DO file at HL for editing
; 
L_DISP_SCREEN:
    CALL    L_GET_LCD_ROWS				;Get # of LCD rows based on label protect, preserve flags
    ANA     A							;clear carry-> bit 7
    RAR									;divide by 2
;
; Display 'A' lines of the .DO file at HL for editing
;
L_DISP_A_LINES:
    CALL    L_CALC_LINE_STRTS			;calculate the Line Starts array for the LCD
    SHLD    TXTLINTBL_R					;Storage of TEXT Line Starts
    CALL    L_GET_LCD_ROWS				;Get # of LCD rows based on label protect, preserve flags
    ADD     A							;double since updating ptrs
    LXI     H,TXTLINTBL_R+2				;start at line 2
-	MVI     M,0FEH						;invalidate rest of TXTLINTBL_R
    INX     H
    DCR     A							;loop counter
    JNZ     -
    INR     A							;A == 1
    JMP     L_DISP_LINENUM_IN_A			;Display line 1 of the .DO file at HL
;
L_DISP_LINENUM:
    PUSH    PSW							;save A
    LHLD    PREVLINE_R
    MOV     A,H							;test
    ORA     L
    JZ      +							;brif PREVLINE_R == 0
    XCHG								;PREVLINE_R to DE
    CALL    L_BDL_LINE_DE				;Build next line from .DO file at (DE) into line buffer
    POP     PSW							;restore A
    MOV     B,A							;save
    CALL    L_CMP_LINEPTR_DE			;Compare DE with Line ptr for row in A
    MOV     A,B
    PUSH    PSW
    JZ      +
    DCR     A
    JZ      +
    MOV     L,A
    MVI     H,01H
    CALL    R_SET_CURSOR_POS			;Set the current cursor position
    CALL    L_DISP_LINE_1
    MOV     A,D							;test DE for 0FFFFH
    ANA     E
    INR     A
    POP     B
    JZ      R_ERASE_TO_EOL				;Erase from cursor to end of line
    PUSH    B
+	POP     PSW
; 
; Display line 'A' of the .DO file at HL for editing based on line starts array
; 
L_DISP_LINENUM_IN_A:
    MOV     L,A							;Column
    MVI     H,01H						;Row 1
    CALL    R_SET_CURSOR_POS			;Set the current cursor position
    CALL    L_GET_CRS_LINEPTR			;Get address in .DO file of start of current row 
    MOV     A,E							;test DE
    ANA     D
    INR     A
    JZ      L_DISP_LINENUM_IN_A_2		;brif DE == 0FFFFH
    CALL    L_GET_CRS_LINEPTR			;Get address in .DO file of start of current row  
-	CALL    L_NUM_LCD_ROWS				;Get # of LCD rows based on label protect + cols in L
    CMP     L
    JZ      +
    CALL    L_DISP_LINE					;result in DE
    MOV     A,D							;test DE
    ANA     E
    INR     A
    JZ      L_DISP_LINENUM_IN_A_1		;brif DE == 0FFFFH
    CALL    L_CMP_CRS_LINEPTR_DE		;Compare DE with Line ptr for current row
    JNZ     -							;brif not equal
    RET
+	CALL    L_DISP_LINE					;result in DE
-	CALL    L_GET_LCD_ROWS				;Get # of LCD rows based on label protect, preserve flags
    INR     A
    JMP     L_CMP_LINEPTR_DE			;Compare DE with Line ptr for row in A
L_DISP_LINENUM_IN_A_1:
    CALL    L_CMP_CRS_LINEPTR_DE		;Compare DE with Line ptr for current row
    JZ      -							;brif equal
L_DISP_LINENUM_IN_A_2:
	CALL    R_ERASE_TO_EOL				;Erase from cursor to end of line
    CALL    R_SEND_CRLF				    ;Send CRLF to screen or printer
    JMP     L_DISP_LINENUM_IN_A_1
;
; IN:
;	DE
; OUT:
;	DE
;
L_DISP_LINE:
    CALL    L_BDL_LINE_DE				;Build next line from .DO file at (DE) into line buffer
L_DISP_LINE_1:
    PUSH    D							;save return value
    LHLD    CURPOS_R					;current char position in line buffer
    LXI     D,LINBUF_R					;line buffer
-	LDAX    D							;get char
    OUTCHR								;Send character in A to screen/printer
    INX     D							;next line buffer
    COMPAR								;Compare line buffer ptr and CURPOS_R: HL - DE
    JNZ     -							;brif not equal
    LDA     LCDPRT_R					;LCD vs Printer output indication - output to LCD
    ANA     A
    CZ      R_INV_CHAR_DISABLE       	;Cancel inverse character mode
    POP     D							;restore return value
    RET
;
; Compare DE with Line ptr for row in A.
; Updates TXTLINTBL_R if not equal
;
; OUT:
;	Z		set if equal
;
L_CMP_LINEPTR_DE:
    PUSH    D
; Get address in .DO file of start of row in A. HL points to index into TXTLINTBL_R on return
    CALL    L_GET_LINEPTR
    JMP     +
;
; Compare DE with Line ptr for current row
; Update TXTLINTBL_R if not equal
;
; OUT:
;	Z		set if equal
;
L_CMP_CRS_LINEPTR_DE:
    PUSH    D							;save DE
; Get address in .DO file of start of current row to DE. HL points to index into TXTLINTBL_R on return
    CALL    L_GET_CRS_LINEPTR
+	MOV     C,A							;save A
    XTHL								;save HL. Pushed DE to HL
    COMPAR								;Compare start of row and HL: HL - DE
    MOV     A,C							;retrieve A
    XCHG								;HL to DE
    POP     H							;restore saved HL
    RZ									;retif start of row == HL  
    MOV     M,E							;store DE at index into TXTLINTBL_R
    INX     H
    MOV     M,D
    MOV     A,C							;retrieve A
    RET

L_GETLSTLINE:
    CALL    L_GET_LCD_ROWS				;Get # of LCD rows based on label protect, preserve flags
    INR     A							;Increment to the line below bottom of LCD
    JMP     L_GET_LINEPTR				;Get address in .DO file of start of row in 'A'  
;
; Get address in .DO file of start of current row using Line Starts array
;
; OUT:
;	A	target row number. range 1..8
;	DE	address in .DO file
;
L_GET_CRS_LINEPTR:
    LDA     CSRY_R						;Cursor row (1-8)
;
; Get address in .DO file of start of row in 'A' using Line Starts array
;
; IN:
;	A	target row number. range 1..8
; OUT:
;	A	target row number. range 1..8
;	DE	line ptr in .DO file
;
L_GET_LINEPTR:
    MOV     E,A							;zero extend A to DE, base 1
    MVI     D,00H
    LXI     H,TXTLINTBL_R-2				;Line Starts Table - 2 since row number is base 1
    DAD     D							;add target row number twice (word offset) to HL
    DAD     D
	GETDEFROMMNOINC						;get line ptr in .DO file to DE
    DCX     H							;backup to line ptr
    RET
;
; result in DE
;
L_GET_PREV_LINEPTR:
    CALL    L_GET_CRS_LINEPTR			;Get address in .DO file of start of current row . Returns CSRY_R in A, line ptr in .DO file in DE
    DCR     A
    JZ      L_CMP_DOLOAD_DE				;brif CSRY_R was 1
; CSRY_R != 1
; returned DE value not used.
    DCX     H							;backup to line ptr of previous row
    MOV     D,M							;get DE from M
    DCX     H
    MOV     E,M
    RET
;
; compare DE with [DOLOAD_R]
;
L_CMP_DOLOAD_DE:
    LHLD    DOLOAD_R					;Load start address of .DO file being edited
    COMPAR								;Compare line ptr and [DOLOAD_R]: HL - DE
    JC      +							;brif [DOLOAD_R] < line ptr
    LXI     D,0
    RET									;carry clear
+	PUSH    D							;save line ptr
    DCX     D							;end of previous line?
    COMPAR								;Compare (line ptr - 1) and [DOLOAD_R]: HL - DE
    JNC     L_CMP_DOLOAD_DE_1			;brif [DOLOAD_R] >= (line ptr - 1)
-	DCX     D
    COMPAR								;Compare (line ptr - 2) and [DOLOAD_R]: HL - DE
    JNC     L_CMP_DOLOAD_DE_1			;brif [DOLOAD_R] >= (line ptr - 1)
    LDAX    D							;get char
; Find end of line
    CPI     0AH							;LF
    JNZ     -							;brif char != 0AH: loop
    DCX     D							;backup line ptr
    COMPAR								;Compare DE and [DOLOAD_R]: HL - DE
    JNC     L_CMP_DOLOAD_DE_1			;brif [DOLOAD_R] >= DE
    LDAX    D							;previous char
    INX     D
    CPI     0DH							;CR
    JNZ     -							;brif char != CR: loop
    INX     D
L_CMP_DOLOAD_DE_1:
    PUSH    D							;save line ptr
    CALL    L_BDL_LINE_DE				;Build next line from .DO file at (DE) into line buffer
    POP     B
    XCHG
    POP     D
    PUSH    D
    COMPAR								;HL - DE
    XCHG
    JC      L_CMP_DOLOAD_DE_1
    POP     D
    MOV     E,C							;DE = BC
    MOV     D,B
    RET
;
L_SAV_PREV_LINEPTR:
    CALL    L_GET_PREV_LINEPTR			;result in DE
    XCHG								;to HL
    SHLD    PREVLINE_R					;store result
    RET
; 
; Find address of 1st char on LCD line for ROW containing line ptr in HL
;
; IN:
;	HL		Line ptr
; 
L_FND_CHAR_HL_LINEPTR:
    SHLD    TMPLIN_R					;save incoming line ptr
    PUSH    H							;store incoming line ptr (updated in loop)
    LXI     H,TXTLINTBL_R				;array of line ptrs
    CALL    L_GET_LCD_ROWS				;Get # of LCD rows based on label protect, preserve flags
    MOV     B,A							;# of rows: counter
-	GETDEFROMM							;get next Line Ptr to DE
    PUSH    H							;save current ptr in line ptrs array
    LHLD    TMPLIN_R					;restore incoming line ptr				
    COMPAR								;Compare current line ptr and incoming line ptr: HL - DE
    JC      +							;brif incoming line ptr < DE: HL pushed
    POP     H							;restore ptr in line ptrs array
    XCHG								;current line ptr to HL
    XTHL								;swap HL and [SP]: update incoming line ptr
    XCHG								;ptr in line ptrs array back to HL
    DCR     B							;# of rows
    JP      -							;brif B >= 0
    DI 
    HLT									;TODO Serious error: current line ptr not in TXTLINTBL_R
;
; Found a line ptr in TXTLINTBL_R >= incoming line Ptr
;
+	XCHG								;next line ptr to DE
    POP     H							;remove current ptr in TXTLINTBL_R table
    POP     H							;updated incoming line ptr
;
; Get ROW/COL of char in .DO file at (DE) HL=Start of current row.
;
L_GET_ROW_COL:
    PUSH    H							;Start of target line ptr
    LXI     H,LINBUF_R					;line buffer
    SHLD    CURPOS_R					;set current char position in line buffer
    XRA     A
    STA     DSPCOFF_R					;clear Current column offset within display line buffer
    POP     H							;Start of target line ptr
    DCX     H							;pre-decrement for loop
-	INX     H							;next target line ptr
    COMPAR								;Compare target line ptr and next line ptr: HL - DE
    JNC     +							;brif HL >= DE
    MOV     A,M							;get char
    CALL    L_ADD_BUFF_TABS				;Add character in A to line buffer with TAB expansion
    MOV     A,M							;get char
    CPI     ' '
    JNC     -							;brif char >= ' ': loop
    CPI     09H							;TAB
    JZ      -							;brif char == TAB: loop
    CALL    L_ADD_BUFF_TABS				;Add character in A to line buffer with TAB expansion
    JMP     -							;loop
+	LDA     DSPCOFF_R					;Current column offset within display line buffer
    INR     A							;increment it
    MOV     H,A							;to H
    CALL    L_GET_LCD_ROWS				;Get # of LCD rows based on label protect, preserve flags
    SUB     B
    MOV     L,A
    RET
;
; Get address in .DO file (DE has start of line) of current cursor position to DE
;
L_GET_CRSPOS_ADDR:
    CALL    L_GET_CRS_LINEPTR			;Get address in .DO file of start of current row in DE
    PUSH    D							;save start of line address
    INR     A							;Increment the row number
    CALL    L_GET_LINEPTR				;Get address in .DO file of start of next row
    MOV     A,D							;test DE for 0FFFFH
    ANA     E
    INR     A
    JNZ     L_GET_CRSPOS_1				;brif DE != 0FFFFH
;DE == 0FFFFH
    LHLD    TXTEND_R					;Load pointer to end of .DO file to DE
    XCHG
    INX     D							;preincrement
L_GET_CRSPOS_1:
    DCX     D							;get previous char
    LDAX    D
    CPI     0AH							;LF
    JNZ     +							;brif A != LF
; A == LF
    DCX     D							;get previous char
    LDAX    D
    CPI     0DH							;CR
    JZ      +							;brif A == CR
; A != CR
    INX     D							;point again to LF
; Test the next value of DE to see if it is where the cursor is located
+	POP     H							;retrieve address of start of current line in .DO file
    PUSH    H
    CALL    L_GET_ROW_COL				;Get ROW/COL of char in .DO file at (DE)
    LDA     CSRX_R						;Cursor column (1-40)
    CMP     H							;Test if DE points to current Cursor column
    JC      L_GET_CRSPOS_1				;Jump to decrement DE if location not found yet
    POP     H							;Pop address of start of current line in .DO file
    XCHG								;Put the address in DE, HL has COL/ROW
    RET
;
; Find end of current DO file
;
L_FNDEOFDO:
    LHLD    DOLOAD_R					;Load start address of .DO file being edited
; Find EOF at HL Text Line
L_FNDEOFTXT:
    MVI     A,1AH						;^Z
; loop assumes there always will be a ^Z
-	CMP     M
    INX     H							;next
    JNZ     -							;brif M != ^Z
    DCX     H							;backup
    SHLD    TXTEND_R					;save ptr
    RET
;
; This starts at the beginning of the .DO file and calculates
; the Line Starts array for the LCD so that the address specified in
; HL will be visible on the screen.
;
; IN:
;	A		Line Count
;	DE		ptr to edit lines start
;
L_CALC_LINE_STRTS:
    PUSH    PSW							;save Line Count
    XCHG
    LHLD    DOLOAD_R					;Load start address of .DO file being edited to DE
    XCHG
-	PUSH    H							;Push address in .DO file for display
    PUSH    D							;Push beginning of .DO file address
    CALL    L_BDL_LINE_DE				;Build next line from .DO file at (DE) into LINBUF_R. Returns DE
    POP     B							;Restore beginning of .DO file address to BC
    POP     H							;Restore address in .DO file to display
    COMPAR								;HL - DE
    JNC     -							;brif HL >= DE
    MOV     H,B							;HL = BC
    MOV     L,C
    POP     B							;Pop line count to display
    DCR     B							;Decrement line count to display (1 based)
    RZ									;retif done
    XCHG
-	PUSH    B							;save loop counter
    CALL    L_CMP_DOLOAD_DE
    POP     B							;restore loop counter
    MOV     A,D							;test DE
    ORA     E
    LHLD    DOLOAD_R					;preload start address of .DO file being edited
    RZ									;retif DE == 0
    DCR     B
    JNZ     -
    XCHG
    RET
;
; Insert A into text file at M
;
R_INSERT_A_INTO_FILE:				  	;6B61H
    LXI     B,0001H
    PUSH    PSW							;save A
    CALL    MAKHOL						;Insert BC spaces at M
    POP     B							;restore A to B
    RC									;return if no space
    MOV     M,B							;update file
    INX     H							;next
    RET
;
; Insert BC spaces at M
;
;  In order to know the free area's size, STRGEND_R
;  is the best pointer. The value of STRGEND_R and your
;  file's size should be less than [SP] - 120. The 120
;  bytes are reserved for the stack. If there is enough
;  room, MAKHOL shifts all data between the specified
;  address and STRGEND_R. If not MAKHOL returns with carry
;  set. The MAKHOL operation is detailed below:
; 
;  Return with carry set (out of memory)
;  if STRGEND_R + hole size < SP - minimum stack size (120 bytes)
;  Move the data between the specified address and STRGEND_R.
;  Adjust the pointers ASCTAB, BINTAB, VARTAB, ARYTAB and STRGEND_R.
;  Return
;  It is unnecessary to care about the pointers unless you
;  make your own MAKHOL routine. The MAKHOL in Main ROM
;  manages the pointers automatically. But it does not
;  revise the starting addresses in the directory fields.
;  For this, use LNKFIL.
; 
; NOTE: When you make a hole at ASCTAB to create
;  a new DO file, you have to adjust the pointers
;  BINTAB, VARTAB, and ARYTAB. ASCTAB must be
;  modified only when you make a hole at ASCTAB
;  to register a new BA file.
; 
;  Obviously, calling MAKHOL too often results in
;  excessive overhead. It is preferable to call
;  MAKHOL with a large number in the BC register,
;  and shrink the file to minimum size later using MASDEL.
;
; returns with carry set if no space
;
MAKHOL:									;6B6DH
    XCHG
    LHLD    STRGEND_R					;Unused memory pointer
    DAD     B
    RC									;return with carry set if overflow
    MVI     A,88H						;subtract 0FF88H (-120) from HL
    SUB     L
    MOV     L,A
    MVI     A,0FFH
    SBB     H
    MOV     H,A
    RC									;return with carry set if overflow     
    DAD     SP							;may set carry
    CMC									;complement carry
    RC									;return with carry set if no space
;
; Move all files / variables after this file
;
L_MOV_DATA:
    PUSH    B							;save length
    CALL    L_UPD_PTRS					;Update CO and variable pointers using BC (add)
    LHLD    STRGEND_R					;Unused memory pointer to HL
    MOV     A,L							;DE = HL - DE
    SUB     E
    MOV     E,A
    MOV     A,H
    SBB     D
    MOV     D,A
    PUSH    D							;save HL - DE
    MOV     E,L							;set DE = current Unused memory pointer STRGEND_R
    MOV     D,H
    DAD     B							;add spaces length
    SHLD    STRGEND_R					;update Unused memory pointer STRGEND_R
    XCHG
    DCX     D							;previous Unused memory pointer
    DCX     H							;new Unused memory pointer
    POP     B							;restore HL - DE
    MOV     A,B							;test BC
    ORA     C
    CNZ     R_MOVE_BC_BYTES_DEC         ;Move BC bytes from M to (DE) with decrement
    INX     H							;new Unused memory pointer
    POP     B							;restore spaces length
    RET
;
; Delete BC characters/spaces at M
;
;  This routine performs the reverse operation of MAKHOL.
;  The data above the HL + BC is moved up. And the pointers
;  BINTAB, VARTAB, ARYTAB are modified. If you use this
;  routine for shrinking a hole of BA file, you must adjust
;  ASCTAB with the negated [BC] after exiting this routine,
;  since MASDEL does not correct ASCTAB.
; 
;  Also, you can adjust the TXTTAB by using this negated
;  BC counter if necessary. You have to adjust TXTTAB when
;  you remove a BA file which is located at a lower address
;  than that pointed to by TXTTAB.
; 
;  If you want to utilize this routine for CO file,
;  you must correct BINTAB after calling MASDEL. MASDEL was
;  designed for deleting bytes from a DO file, so it
;  adjusts BINTAB down by the deletion size. But when
;  deleting a CO file, BINTAB shouldn't change. To deal
;  with this, you need to save and restore BINTAB across
;  calls to MASDEL, or add back in the number of bytes you
;  are deleting to BINTAB.
;
; IN:
;	BC		count (negated on exit)
;	HL		M ptr
;
MASDEL:									;6B9FH
    MOV     A,B							;test BC
    ORA     C
    RZ							 		;retif BC == 0
    PUSH    H							;save args
    PUSH    B
    PUSH    H
    DAD     B							;HL += BC
    XCHG								;move to DE
    LHLD    STRGEND_R					;Unused memory pointer to DE
    XCHG
    MOV     A,E							;BC = STRGEND_R - HL
    SUB     L
    MOV     C,A
    MOV     A,D
    SBB     H
    MOV     B,A
    POP     D
    MOV     A,B							;test BC
    ORA     C
    CNZ     R_MOVE_BC_BYTES_INC         ;Move BC bytes from M to (DE) with increment
    XCHG								;new Unused memory pointer to HL
    SHLD    STRGEND_R					;update Unused memory pointer
    POP     B
;
; compute two's complement of BC
;
    XRA     A							;0 - C
    SUB     C
    MOV     C,A
    SBB     A							;carry
    SUB     B
    MOV     B,A
    POP     H
;
; Update CO and variable pointers using BC (add). BC negative.
;
L_UPD_PTRS:
    PUSH    H							;save HL
    LHLD    COSTRT_R					;CO files pointer
    DAD     B
    SHLD    COSTRT_R					;Update CO files pointer
    LHLD    VARTAB_R					;Start of variable data pointer
    DAD     B
    SHLD    VARTAB_R					;Update Start of variable data pointer
    LHLD    ARYTAB_R					;ptr to Start of array table
    DAD     B
    SHLD    ARYTAB_R					;Update ptr to Start of array table
    POP     H							;restore HL
    RET
;
;Move BC bytes from M to (DE) with increment
;
R_MOVE_BC_BYTES_INC:				    ;6BDBH
    MOV     A,M
    STAX    D
    INX     H
    INX     D
    DCX     B
    MOV     A,B
    ORA     C
    JNZ     R_MOVE_BC_BYTES_INC      	;Move BC bytes from M to (DE) with increment
    RET
;
;Move BC bytes from M to (DE) with decrement
;
; OUT:
;	DE, HL	updated
;	BC		0
;
R_MOVE_BC_BYTES_DEC:				    ;6BE6H
    MOV     A,M
    STAX    D
    DCX     H
    DCX     D
    DCX     B
    MOV     A,B
    ORA     C
    JNZ     R_MOVE_BC_BYTES_DEC      	;Move BC bytes from M to (DE) with decrement
    RET
;
; ROM programs directory entries
;
R_ROM_CAT_ENTRIES:						;6BF1H
    DB      _DIR_ACTIVE|_DIR_COFILE|_DIR_INROM	;type 0B0H
    DW      R_BASIC_ENTRY				;6C49H
    DB      "BASIC  ",00H
    DB      _DIR_ACTIVE|_DIR_COFILE|_DIR_INROM	;type 0B0H
    DW      R_TEXT_ENTRY				;5DEEH
    DB      "TEXT   ",00H
    DB      _DIR_ACTIVE|_DIR_COFILE|_DIR_INROM	;type 0B0H
    DW      R_TELCOM_ENTRY				;5146H
    DB      "TELCOM ",00H
    DB      _DIR_ACTIVE|_DIR_COFILE|_DIR_INROM	;type 0B0H
    DW      R_ADDRSS_ENTRY				;5B68H
    DB      "ADDRSS ",00H
    DB      _DIR_ACTIVE|_DIR_COFILE|_DIR_INROM	;type 0B0H
    DW      R_SCHEDL_ENTRY				;5B6FH
    DB      "SCHEDL ",00H
    DB      _DIR_ACTIVE|_DIR_INVIS		;type 88H
    DW      0000H						;no associated function
    DB      00H,"Suzuki",' '			;20H
    DB      _DIR_ACTIVE|_DIR_DOFILE|_DIR_INVIS	;type 0C8H
    DW      0000H						;no associated function
	if		HWSCROLL
;	•	1 byte for page number storage
;	•	1 byte for scroll active flag
;	•	These 2 bytes are copied to RAM.
	DB		00H,"Hayas"
	DB		00H,00H
	else
    DB      00H,"Hayash",'i'
	endif
    DB      _DIR_DOFILE|_DIR_INVIS		;type 48H
    DW      0000H						;no associated function
    DB      00H,"RickY ",20H
;
;BASIC Entry point
;
R_BASIC_ENTRY:							;6C49H
    CALL    L_SET_STRBUF
    CALL    R_DISP_MODEL				;Display TRS-80 Model number & Free bytes on LCD
    LXI     H,SUZUKI_R					;Suzuki Directory Entry
    SHLD    RAMDIRPTR_R
    LHLD    SUZUKI_R+1					;BASIC program not saved pointer
    SHLD    TXTTAB_R					;Start of BASIC program pointer
L_ALT_BASIC_ENTRY:
    CALL    R_LOAD_BASIC_FKEYS			;Copy BASIC Function key table to key definition area
    CALL    R_DISP_FKEYS				;Display function keys on 8th line
    XRA     A
    STA     FNKMOD_R					;Function key mode/ BIT 7=in TEXT (0x80); BIT 6=in TELCOM (0x40)
    INR     A
    STA     LINENA_R					;Label line enable flag
    LXI     H,L_LLIST_MSG				;Code Based. 
    SHLD    SHFTPRNT_R
    CALL    R_UPDATE_LINE_ADDR         	;Update line addresses for current BASIC program
    CALL    R_INIT_BASIC_VARS			;Initialize BASIC Variables for new execution
    JMP     R_GO_BASIC_RDY_OK			;Vector to BASIC ready - print Ok

L_LLIST_MSG:
	DB		"llist", 0DH, 00H

L_SET_STRBUF:
    LHLD    VARTAB_R					;Start of variable data pointer
    LXI     B,0178H
    DAD     B							;HL = [VARTAB_R]+0178H (376.)
    XCHG
    LHLD    MEMSIZ_R					;File buffer area pointer. Also end of Strings Buffer Area.
    COMPAR								;Compare [VARTAB_R]+0178H (DE) and [MEMSIZ_R] (HL): HL - DE
    JC      +							;brif [MEMSIZ_R] < ([VARTAB_R]+0178H)
    DCR     H							;HL -= 256
+	SHLD    STRBUF_R					;BASIC string buffer pointer
    RET
;
; Copy key definition area to BASIC Function key table
;
R_SET_BASIC_FKEYS:						;6C93H
    LXI     H,FNKSTR_R				    ;Function key definition area
    LXI     D,BASFNK_R				    ;Function key definition area (BASIC)
    JMP     +
;
; Copy BASIC Function key table to key definition area
;
R_LOAD_BASIC_FKEYS:				      	;6C9CH
    LXI     H,BASFNK_R				  	;Function key definition area (BASIC)
    LXI     D,FNKSTR_R				  	;Function key definition area
+	MVI     B,128						;80H
    JMP     R_MOVE_B_BYTES				;Move B bytes from M to (DE)
;
; Execute Instruction Vector
;
; IN:
;	DE		instruction vector table
;
L_TELCOM_EXEC_CMD:
    DCX     H							;backup input ptr
    CHRGET								;Get next non-white char from M
L_TELCOM_EXEC_CMD_1:
    LDAX    D
    INR     A
    RZ
    PUSH    H
    MVI     B,04H
-	LDAX    D
    MOV     C,A
    CALL    R_CONV_M_TOUPPER			;Get char at M and convert to uppercase
    CMP     C
    INX     D
    INX     H
    JNZ     L_TELCOM_EXEC_CMD_2
    DCR     B
    JNZ     -
    POP     PSW
    PUSH    H
    XCHG
	GETDEFROMMNOINC
    XCHG
    POP     D
    XTHL
    PUSH    H
    XCHG
    INR     H
    DCR     H
    RET
L_TELCOM_EXEC_CMD_2:
    INX     D
    DCR     B
    JNZ     L_TELCOM_EXEC_CMD_2			;brif B != 0
    INX     D
    POP     H
    JMP     L_TELCOM_EXEC_CMD_1
;
; Re-initialize system without destroying files
;
; Zero 0FF40H..0FFFCH, basically all RAM >= XONXOFF_R
;
R_RE_INIT_SYSTEM:						;6CD6H
    DI 
    LXI     H,XONXOFF_R				    ;address of XON/XOFF protocol control
    MVI     B,LAST_RAM-XONXOFF_R+1		;size
    CALL    R_CLEAR_MEM				    ;Zero B bytes at M
    INR     A							;A == 1
;
; Warm start reset entry
;
; IN:
;	A		0 or 1
;
R_WARM_RESET:							;6CE0H
    PUSH    PSW							;save A
    DI
    MVI     A,19H						;00011001 RST 7.5 MSE==1 Unmask 7.5 & 6.5. Mask INT 5.5
    SIM    
    INPORT	0C8H						;Bidirectional data bus for UART
    MVI     A,43H
    OUTPORT	0B8H						;set PIO Command/Status Register
    MVI     A,05H						;00000101 Group 1: 256 Hz
    CALL    R_SET_CLK_CHIP_MODE      	;Set clock chip mode
    MVI     A,0EDH
    OUTPORT	0BAH						;8155 PIO Port B
    XRA     A
    STA     PORTE8_R					;Contents of port E8H
    OUTPORT	0E8H						;set Keyboard input and misc. device select
    OUTPORT	0A8H
    CALL    R_CHK_XTRNL_CNTRLER      	;Check for optional external controller
    CALL    L_SELECT_LCD_DRIVER_ALL 	;Enable all LCD drivers after short delay
    XRA     A
    OUTPORT	0FEH
    CALL    L_SELECT_LCD_DRIVER_ALL     ;Enable all LCD drivers after short delay
    MVI     A,3BH						;00111011B
    OUTPORT	0FEH
    CALL    L_CLR_LCD_TOP				;Set the display top line to zero for all LCD controllers
    CALL    L_SELECT_LCD_DRIVER_ALL     ;Enable all LCD drivers after short delay
    MVI     A,39H						;00111001B
    OUTPORT	0FEH
    EI     
    CALL    L_XTRNL_CNTRLER_1			;returns carry set if not present
    JNC     +
-	XRA     A
+	STA     DVI_STAT_R					;update DVI status
    ORA     A
    JZ      +							;brif zero: done
    LDA     VIDFLG_R
    ORA     A
    JNZ     +							;brif VIDFLG_R != 0: done
    POP     PSW							;restore flags
    RZ									;retif zero
    LHLD    VARTAB_R 					;Start of variable data pointer
    LXI     D,0E000H					;Location of init code to be copied from DVI
    COMPAR	 							;HL - DE
    RNC									;Return if not enough space to copy DVI init code
; DE = 0E000H
    CALL    L_XTRNL_CNTRLER_CPY			;Copy initialization code from DVI to E000h and execute
    PUSH    PSW
    JC		-							;brif carry: exit
+	POP     PSW
    RET
;
; Send character in A to the printer
;
R_SEND_A_TO_LPT:						;6D3FH
    PUSH    B
    MOV     C,A
-	CALL    R_CHK_SHIFT_BREAK			;Check if SHIFT-BREAK is being pressed
    JC      L_SEND_TO_LPT_EXIT			;brif pressed
    INPORT	0BBH						;read 8155 PIO Port C
    ANI     06H
    XRI     02H
    JNZ     -
    CALL    L_DIS_INT_75_65				;Disable Background task
    MOV     A,C
    OUTPORT	0B9H
    LDA     PORTE8_R					;Contents of port E8H
    MOV     B,A
    ORI     02H
    OUTPORT	0E8H						;set Keyboard input and misc. device select
    MOV     A,B
    OUTPORT	0E8H						;set Keyboard input and misc. device select
    MVI     B,24H						;delay
-	DCR     B
    JNZ     -
    MVI     A,09H						;00001001 MSE==1 Unmask 7.5 & 6.5. Mask INT 5.5
    SIM    
L_SEND_TO_LPT_EXIT:
    MOV     A,C
    POP     B
    RET
;
; Check RS232 queue for pending characters
;
R_CHECK_RS232_QUEUE:					;6D6DH
    LDA     XONFLG_R					;XON/XOFF enable flag
    ORA     A
    JZ		+							;brif not enabled
    LDA     XONXOFF1_R					;XON/XOFF protocol control
    INR     A							;test if A == 0FFH
    RZ
+	LDA     SERCNT_R					;RS232 buffer count
    ORA     A
    RET
;
; Get a character from RS232 receive queue
;
R_READ_RS232_QUEUE:						;6D7EH
    PUSH    H
    PUSH    D
    PUSH    B
    LXI     H,L_POP_WREGS_RET			;exit routine (pop all regs except PSW & RET)
    PUSH    H
    LXI     H,SERCNT_R				    ;RS232 buffer count
-	CALL    R_CHK_SHIFT_BREAK			;Check if SHIFT-BREAK is being pressed
    RC									;retif pressed
    CALL    R_CHECK_RS232_QUEUE      	;Check RS232 queue for pending characters
    JZ      -							;brif no pending chars: wait
    CPI     03H							;3 chars in queue?
    CC      R_SEND_XON				    ;Send XON (CTRL-Q) out RS232 if < 03H
    DI 
    DCR     M							;decrement RS232 buffer count
    CALL    R_INC_RS232_QUEUE_IN     	;Calculate address to save next RS232 character
    MOV     A,M
    XCHG								;RS232 Queue ptr to HL
    INX     H							;ptr += 3
    INX     H
    INR     M
    DCR     M							;decrement count
    RZ									;retif count == 0
    DCR     M							;decrement count
    JZ      +							;brif count == 0
    CMP     A							;set Z flag
    RET
+	ORI     0FFH						;return 0FFH
    RET
;
; RST 6.5 routine (RS232 receive interrupt)
;
R_RST6_5_ISR:							;6DACH
    CALL    SERHK_R						;RST 6.5 routine (RS232 receive interrupt) hook
    PUSH    H
    PUSH    D
    PUSH    B
    PUSH    PSW
    LXI     H,R_ISR_EXIT_FUN			; Interrupt exit routine (pop all regs & RET)
    PUSH    H
    INPORT	0C8H						;Bidirectional data bus for UART
    LXI     H,PARMSK_R				    ;Serial Ignore Parity Mask byte
    ANA     M							;remove Parity bit, if any
    MOV     C,A							;save Data byte
    INPORT	0D8H						;read Status control register for UART, modem
    ANI     0EH							;00001110 isolate bits 1..3: error conditions
    MOV     B,A							;save in B
    JNZ     L_RS232_ISR_1
    MOV     A,C							;restore Data byte
    CPI     11H							;DC1(XON)
    JZ      +
    CPI     13H							;DC3 (XOFF)
    JNZ     L_RS232_ISR_1
	SKIP_BYTE_INST						;Sets A to 0AFH
+	XRA     A
    STA     XONXOFF_R					;XON/XOFF protocol control
    LDA     XONFLG_R					;XON/XOFF enable flag
    ORA     A
    RNZ
L_RS232_ISR_1:
    LXI     H,SERCNT_R				    ;RS232 buffer count
    MOV     A,M
    CPI     MAXSERCNT					;64 max buffer count
    RZ									;return if full
    CPI     MAXSERCNT-24				;40	getting full?
    CNC     R_DISABLE_XON_XOFF       	;if >= 40 Turn off XON/XOFF protocol
    PUSH    B
    INR     M
    INX     H
    CALL    R_INC_RS232_QUEUE_IN     	;Calculate address to save next RS232 character
    POP     B
    MOV     M,C
    MOV     A,B
    ORA     A
    RZ
    XCHG
    INX     H
    DCR     M
    INR     M
    RNZ
    LDA     SERCNT_R					;RS232 buffer count
    MOV     M,A
    RET
;
; Calculate address to save next RS232 character
;
; IN:
;	HL		RS232 Queue ptr
; OUT:
;	DE		RS232 Queue ptr
;	HL		ptr into RS232 Character buffer
;
R_INC_RS232_QUEUE_IN:					;6DFCH
    INX     H
    MOV     C,M							;get current count
    MOV     A,C
    INR     A							;increment mod 64
    ANI     (MAXSERCNT-1)				;3FH
    MOV     M,A							;update count
    XCHG							 	;RS232 Queue ptr to DE
    LXI     H,SERBUF_R				    ;RS232 Character buffer
    MVI     B,00H						;zero-extend C to BC
    DAD     B							;index 
    RET
;
; Send XON (CTRL-Q) out RS232
;
R_SEND_XON:								;6E0BH
    LDA     XONFLG_R					;XON/XOFF enable flag
    ANA     A
    RZ
    LDA     CTRLS_R						;Control-S status
    DCR     A
    RNZ
    STA     CTRLS_R						;Control-S status
    PUSH    B
    MVI     C,11H						;DC1 (XON)
    JMP     R_SEND_C_TO_RS232			;Send character in C to serial port
;
; Turn off XON/XOFF protocol
;
R_DISABLE_XON_XOFF:						;6E1EH
    LDA     XONFLG_R					;XON/XOFF enable flag
    ANA     A
    RZ
    LDA     CTRLS_R						;Control-S status
    ORA     A
    RNZ
    INR     A
    STA     CTRLS_R						;Control-S status
    PUSH    B
    MVI     C,13H						;DC3 (XOFF)
    JMP     R_SEND_C_TO_RS232			;Send character in C to serial port
;
; Send character in A to serial port using XON/XOFF
;
R_SEND_A_USING_XON:						;6E32H
    PUSH    B							;save BC
    MOV     C,A							;character to send to C
    CALL    R_XON_XOFF_HANDLER       	;Handle XON/XOFF protocol
    JC      L_RS232_SEND_EXIT			;BC on stack
;
; Send character in C to serial port
;
R_SEND_C_TO_RS232:						;6E3AH
    CALL    R_CHK_SHIFT_BREAK			;Check if SHIFT-BREAK is being pressed
    JC      L_RS232_SEND_EXIT			;brif pressed
    INPORT	0D8H						;read Status control register for UART, modem
    ANI     10H							;00010000 isolate bit 4: Transmit buffer empty
    JZ      R_SEND_C_TO_RS232			;Send character in C to serial port
    MOV     A,C
    OUTPORT	0C8H
L_RS232_SEND_EXIT:
    MOV     A,C
    POP     B							;restore BC
    RET
;
; Handle XON/XOFF protocol
;
; IN:
;	C		character to send
;
R_XON_XOFF_HANDLER:						;6E4DH
    LDA     XONFLG_R					;XON/XOFF enable flag
    ORA     A
    RZ									;retif not enabled
    MOV     A,C
    CPI     11H							;DC1(XON, ^Q)
    JNZ     +							;brif !XON
    XRA     A
    STA     CTRLS_R						;Control-S status
    JMP     L_XON_XOFF_1
+	SUI     13H							;DC3 (XOFF, ^S)
    JNZ     L_XON_XOFF_2				;brif !XOFF
    DCR     A							;A = 0FFH
L_XON_XOFF_1:
    STA     XONXOFF1_R					;XON/XOFF protocol control
    RET
L_XON_XOFF_2:
	CALL    R_CHK_SHIFT_BREAK			;Check if SHIFT-BREAK is being pressed
    RC									;retif pressed
    LDA     XONXOFF_R					;XON/XOFF protocol control
    ORA     A
    JNZ     L_XON_XOFF_2				;brif XONXOFF_R active
    RET
;
; Set RS232 baud rate stored in H
;
R_SET_RS232_BAUD_RATE:				    ;6E75H
    PUSH    H							;save HL
    MOV     A,H
    RLC    								;times 2
    LXI     H,R_RS232_BAUD_TIMER_VALS-2	;Code Based. 
    MVI     D,00H						;zero extend A to DE
    MOV     E,A
    DAD     D							;index
    SHLD    BAUDRT_R					;ptr to UART baud rate timer value
    POP     H							;restore HL
L_RS232_SET_1:							;reset 8155
    PUSH    H							;save HL
    LHLD    BAUDRT_R					;UART baud rate timer value (word)
    MOV     A,M							;to BC/BD
    OUTPORT	0BCH						;8155 Timer register.  LSB of timer counter
    INX     H							;move to MSB of timer counter
    MOV     A,M
    OUTPORT	0BDH						;8155 Timer register.
    MVI     A,0C3H						;set Port A & B to OUTPUT, start 8155 timer
    OUTPORT	0B8H						;set 8155 PIO Command/Status Register
    POP     H							;restore HL
    RET
;
; RS232 baud rate timer values
;
R_RS232_BAUD_TIMER_VALS:				;6E94H
    DW      4800H, 456BH, 4200H
    DW      4100H, 4080H, 4040H
    DW      4020H, 4010H, 4008H
;
; Initialize RS232 or modem
; Input Carry, HL
;
R_INIT_RS232_MDM:						;6EA6H
    PUSH    H							;save all registers
    PUSH    D
    PUSH    B
    PUSH    PSW
    MVI     B,25H
    JC      +
    MVI     H,03H
    MVI     B,2DH
+	DI 
    CALL    R_SET_RS232_BAUD_RATE    	;Set RS232 baud rate stored in H
    MOV     A,B
    OUTPORT	0BAH						;8155 PIO Port B
    INPORT	0D8H						;read Status control register for UART, modem
    MOV     A,L
    ANI     1FH							;00011111 clear bits 5,6,7
    OUTPORT	0D8H
    CALL    R_INIT_SER_BUF_PARAMS    	;Initialize serial buffer parameters
    DCR     A							;A == 0FFH
    STA     SERINIT_R					;RS232 initialization status
    JMP     R_ISR_EXIT_FUN				;Interrupt exit routine (pop all regs & RET)
;
; Deactivate RS232 or modem
;
R_UNINIT_RS232_MDM:						;6ECBH
    INPORT	0BAH						;read 8155 PIO Port B
    ORI     0C0H						;11000000
    OUTPORT	0BAH						;set 8155 PIO Port B
    XRA     A
    STA     SERINIT_R					;clear RS232 initialization status
    RET

	if HWMODEM
;
; IN:
;	D
; OUT:
;	E
;	Flags
;
L_CHECK_TEL_LINE:
    MVI     E,00H						;clear count
-	INPORT	0D8H						;read Status control register for UART, modem
    ANI     01H							;isolate bit 0: Data on telephone line
    XRA     D							;xor with D
    JNZ     L_CLICK						;brif bit 0 of D == 0: Click sound port if sound enabled
    INR     E							;increment count
    JP      -							;brif E >= 0
    RET									;Minus result: time out
;
; Click sound port if sound enabled
;
L_CLICK:								;6EE5H
    PUSH    PSW							;save Flags
    LDA     SNDFLG_R					;Sound flag
    ORA     A
    CZ      R_SOUND_PORT    		   	;Click sound port
    POP     PSW							;restore Flags
    RET
;
; Check for carrier detect
;
R_CHECK_CD:								;6EEFH
    PUSH    H
    PUSH    D
    PUSH    B
    LXI     H,L_CHECK_CD_2				;continuation function
    PUSH    H
    INPORT	0BBH						;read 8155 PIO Port C
    ANI     10H							;00010000 isolate bit 4
    LXI     H,0249H						;preload
    LXI     B,1A0EH
    JNZ     L_CHECK_CD_1
    LXI     H,0427H
    LXI     B,0C07H
L_CHECK_CD_1:
    DI 
    INPORT	0D8H						;read Status control register for UART, modem
    ANI     01H							;isolate bit 0: Data on telephone line
    MOV     D,A							;argument
    CALL    L_CHECK_TEL_LINE
    JM      +							;brif timeout
    XRA     D
    MOV     D,A
    CALL    L_CHECK_TEL_LINE
+	EI     
    RM
    MOV     A,E
    CMP     B
    RNC
    CMP     C
    RC
    DCX     H
    MOV     A,H
    ORA     L
    JNZ     L_CHECK_CD_1
    CALL    R_INIT_SER_BUF_PARAMS    	;Initialize serial buffer parameters
    POP     H
	SKIP_2BYTES_INST_JNZ
L_CHECK_CD_2:
    ORI     0FFH
    JMP     R_POP_ALL_WREGS
	else								;!HWMODEM
	DS		6F31H-6ED6H					;91 bytes FREE if !HWMODEM
	endif								;HWMODEM
;
; Enable XON/OFF when CTRL-S / CTRL-Q sent
;
R_ENABLE_XON_XOFF:						;6F31H
	SKIP_BYTE_INST						;Sets A to 0AFH
R_CLR_XON_XOFF:							;6F32H
    XRA     A
    DI 
    STA     XONFLG_R					;XON/XOFF enable flag
    EI     
    RET
;
; Initialize serial buffer parameters. Returns 0 in A
;
R_INIT_SER_BUF_PARAMS:				  	;6F39H
    XRA     A							;clear A, HL
    MOV     L,A
    MOV     H,A
    SHLD    XONXOFF_R					;XON/XOFF protocol controls
    SHLD    SERCNT_R					;RS232 buffer count
    SHLD    SERPTR_R					;RS232 buffer input pointer
    RET
;
; Write cassette header and sync byte
;
R_CAS_WRITE_HEADER:						;6F46H
    LXI     B,512						;0200H
-	MVI     A,55H						;header block pattern
    PUSH    B							;save count
    CALL    L_CAS_WRITE_BYTE
    POP     B							;restore count
    DCX     B							;decrement count
    MOV     A,B							;test count
    ORA     C
    JNZ     -
    MVI     A,7FH						;sync byte
    JMP     L_CAS_WRITE_BYTE
;
; Write char in A to cassette w/o checksum or sync bit
;
R_CAS_WRITE_NO_SYNC:				    ;6F5BH
    CALL    L_CAS_WRITE_0BIT			;Write a 0 bit
L_CAS_WRITE_BYTE:
    MVI     B,08H
-	CALL    R_CAS_WRITE_BIT				;Write bit 7 of A to cassette. Shift A
    DCR     B
    JNZ     -
    JMP     R_CHK_SHIFT_BREAK			;Check if SHIFT-BREAK is being pressed, then return
;
; Write bit 7 of A to cassette. Left most bit. Shift A right 1 position
;
R_CAS_WRITE_BIT:						;6F6AH
    RLC									;bit 7 to carry
    LXI     D,1F24H						;preload Cassette frequency cycle count 1-bit
    JC      L_CAS_WRITE_DLY				;brif bit 7 was 1
L_CAS_WRITE_0BIT:
    LXI     D,4349H						;Cassette frequency cycle count 0-bit
L_CAS_WRITE_DLY:
-	DCR     D							;Delay
    JNZ		-							;L_CAS_WRITE_DLY
    MOV     D,A							;save shifted A
    MVI     A,0D0H						;11010000 SOD:1 SOE:1 RST7.5:1
    SIM
-	DCR     E							;SOD 1 duration
    JNZ     -
    MVI     A,50H						;01010000 SOD:0 SOE:1 RST7.5:1
    SIM    
    MOV     A,D							;restore shifted A
    RET
;
; Read cassette header and sync byte
;
R_CAS_READ_HEADER:						;6F85H
    MVI     B,80H
-	CALL    R_CAS_READ_BIT				;Read Cassette port data bit
    RC									;retif SHIFT-BREAK pressed
    MOV     A,C
    CPI     08H
    JC      R_CAS_READ_HEADER			;Read cassette header and sync byte
    CPI     40H
    JNC     R_CAS_READ_HEADER			;Read cassette header and sync byte
    DCR     B
    JNZ     -
L_CAS_READ_HDR_1:
    CALL    R_CHK_SHIFT_BREAK			;Check if SHIFT-BREAK is being pressed
    RC									;retif SHIFT-BREAK pressed
    LXI     H,0
    MVI     B,40H						;loop counter
L_CAS_READ_HDR_2:
    CALL    L_CAR_READ_BYTE
    RC									;retif SHIFT-BREAK pressed
    MOV     D,C
    CALL    L_CAR_READ_BYTE
    RC									;retif SHIFT-BREAK pressed
    MOV     A,D
    SUB     C
    JNC     +
    CMA
    INR     A
+	CPI     0BH
    JC      +
    INR     H
	SKIP_BYTE_INST						;Sets A to 0AFH
+	INR     L
    DCR     B							;decrement loop counter
    JNZ     L_CAS_READ_HDR_2			;brif not done
    MVI     A,40H
    CMP     L
    JZ      +
    SUB     H
    JNZ     L_CAS_READ_HDR_1
+	STA     CASPLS_R					;Cassette port pulse control
    MVI     D,00H
-	CALL    R_CAS_READ_BIT				;Read Cassette port data bit
    RC									;retif SHIFT-BREAK pressed 
    CALL    R_CAS_COUNT_PULSES			;Count and pack cassette input bits
    CPI     7FH							;sync byte
    JNZ     -
    RET
;
; Read Cassette port data bit. Resulting pulse count in C
; [Read cassette header and sync byte]
; 
R_CAS_READ_BIT:							;6FDBH
    MVI     C,00H						;clear pulse count
    LDA     CASPLS_R					;Cassette port pulse control
    ANA     A
    JZ      L_CAS_READ_NEG_PULSE		;brif CASPLS_R  == 0
;
; CASPLS_R  == 1
;	
L_CAS_READ_POS_PULSE:
	CALL    R_CHK_SHIFT_BREAK			;Check if SHIFT-BREAK is being pressed
    RC									;retif SHIFT-BREAK pressed
    RIM									;read Serial Data In
    RLC									;Data bit to Carry
    JNC     L_CAS_READ_POS_PULSE		;brif 0: wait for a 1
L_CAS_READ_BIT_C_CNT:
    INR     C							;pre-increment count
-	INR     C							;increment count
    JZ      L_CAS_READ_POS_PULSE		;brif count == 256
    RIM									;read Serial Data In
    RLC									;Data bit to Carry
    JC		-							;brif 1: wait for a 0
    JMP     L_CAS_READ_BIT_END			;exit
;
; CASPLS_R  == 0
;
L_CAS_READ_NEG_PULSE:
    CALL    R_CHK_SHIFT_BREAK			;Check if SHIFT-BREAK is being pressed
    RC									;retif pressed 
    RIM									;read Serial Data In 
    RLC									;Data bit 7 to Carry
    JC      L_CAS_READ_NEG_PULSE		;brif 1: wait for a 0
L_CAS_READ_BIT_4:
    INR     C							;pre-increment count
-	INR     C							;increment count
    JZ      L_CAS_READ_NEG_PULSE		;brif count == 256
    RIM									;read Serial Data In  
    RLC									;Data bit 7 to Carry
    JNC     -							;brif if 0: wait for a 1
L_CAS_READ_BIT_END:
    LDA     SNDFLG_R					;Sound flag
    ANA     A
    CZ      R_SOUND_PORT         		;Click sound port if SNDFLG_R == 0
    XRA     A
    RET

L_CAR_READ_BYTE:								;C is input
    CALL    L_CAS_READ_BIT_4
    RC									;retif SHIFT-BREAK pressed
    MVI     C,00H
    CALL    L_CAS_READ_BIT_C_CNT
    RC									;retif SHIFT-BREAK pressed
    JMP     L_CAS_READ_BIT_4
;
; Count and pack cassette input bits
;
; IN:
;	C		incoming pulse count
;
; D collects bits
;
R_CAS_COUNT_PULSES:						;7023H
    MOV     A,C							;get pulse count
    CPI     15H							;sets Carry if A < 15H
    MOV     A,D							;update bits
    RAL									;Carry to bit 0
	MOV     D,A
    RET
;
; Read character from cassette w/o checksum
;
R_CAS_READ_NO_CHKSUM:				  	;702AH
    CALL    R_CAS_READ_BIT				;Read Cassette port data bit into C
    RC									;retif SHIFT-BREAK pressed
    MOV     A,C							;pulse count
    CPI     15H
    JC      R_CAS_READ_NO_CHKSUM       	;brif A < 15H
    MVI     B,08H						;loop counter: 8 bits
-	CALL    R_CAS_READ_BIT				;Read Cassette port data bit
    RC									;retif SHIFT-BREAK pressed
    CALL    R_CAS_COUNT_PULSES			;Count and pack cassette input bits in D
    DCR     B							;loop counter
    JNZ     -							;loop
    XRA     A
    RET
;
; Cassette REMOTE routine - turn motor on or off
;
; IN:
;	E
;
R_CAS_REMOTE_FUN:						;7043H
    LDA     PORTE8_R					;Contents of port E8H
    ANI     0F1H						;11110001
    INR     E							;test E
    DCR     E
    JZ      +							;brif E == 0
    ORI     08H							;00001000
+	OUTPORT	0E8H						;set Keyboard input and misc. device select
    STA     PORTE8_R					;Contents of port E8H
    RET
;
; Keyboard scanning management routine
;
R_KEYSCAN_MGT_FUN:						;7055H
    LXI     H,L_ENA_INT_75_65_POP		;Set new interrupt mask and pop all regs continuation function
    PUSH    H
    LXI     H,KBDSKIP_R
    DCR     M
    RNZ
    MVI     M,03H
;
; Key detection -- Determine which keys are pressed
;
R_KEY_DETECTION:						;7060H
    LXI     H,KBDCOL1_R+8				;end of keyboard scan column storage #1
    LXI     D,KBDCOL2_R+8				;end of keyboard scan column storage #2
    CALL    R_SCAN_SPECIAL_KEYS      	;Scan BREAK),CAPS),NUM),CODE),GRAPH),CTRL),SHIFT & set bits in A
    CMA   								;complement result
    CMP     M
    MOV     M,A							;update KBDCOL1_R, column 9
    CZ      L_DECODE_KEY				;calif A == [KBDCOL1_R]
    XRA     A
    OUTPORT	0B9H
    INPORT	0E8H						;read
    INR     A							;set Z flag if A == 0FFH
    MVI     A,0FFH
    OUTPORT	0B9H
    JZ      L_KEY_DETECT_1				;brif IN 0E8H was 0FFH
    MVI     A,7FH						;starting bit pattern. 0 indicates the column being activated.
    MVI     C,07H						;loop counter == keyboard column 7..0
L_LOOPKBD:
    DCX     H							;going down!
    DCX     D
    MOV     B,A							;save bit pattern
    OUTPORT	0B9H
    INPORT	0E8H						;read
    CMA									;complement
    CMP     M
    MOV     M,A							;update
    JNZ     +							;brif different
    LDAX    D							;get code from KBDCOL2_R vector
    CMP     M							;compare with KBDCOL1_R vector
    CNZ     L_KEY_SCAN					;call if A != M
+	MVI     A,0FFH
    OUTPORT	0B9H
    MOV     A,B							;restore bit pattern
    RRC									;rotate right
    DCR     C
    JP      L_LOOPKBD
    DCX     H							;HL now points to KBDCNTR_R			
    MVI     M,02H
    LXI     H,KEYCNT2_R					;point to some key counter
    DCR     M							;decrement [KEYCNT2_R]
    JZ      L_PRE_KEY_DECODE			;brif [KEYCNT2_R] == 0
    INR     M							;increment [KEYCNT2_R]. Sets all flags except Carry
    RM									;return if bit 7 M set
    LDA     KEYXXXX_R
    LHLD    KEYPTR_R					;Pointer to entry in 2nd Storage Buffer for key
    ANA     M							;A & M
    RZ
;
; Key repeat detection
;
R_KEY_REPEAT_DET:						;70B0H
    LDA     KBCNT_R						;Keyboard buffer count
    CPI     02H
    RNC									;return if A >= 2
    LXI     H,KEYCNT_R 					;Key repeat start delay counter. Default 54H
    DCR     M
    RNZ									;return if M != 0  
    MVI     M,06H						;reset M to 6
    MVI     A,01H
    STA     CSRCNT_R
    JMP     R_KEY_DECODE				;Key decoding
;
; keyscan function
;
; IN:
;	A
;
L_KEY_SCAN:
    PUSH    B
    PUSH    H
    PUSH    D
    MOV     B,A
    MVI     A,80H
    MVI     E,07H						;loop counter 7..0
-	MOV     D,A							;save A
    ANA     M
    JZ      +							;brif (A & M) ==0
    ANA     B
    JZ      L_KEY_SCAN_3				;D, H, B on stack brif (A & M & B) == 0
+	MOV     A,D							;restore A
    RRC									;bit 0 to carry
    DCR     E							;loop counter
    JP      -							;brif E >= 0
    POP     D							;restore a ptr
L_KEY_SCAN_2:							;H, B on stack
    POP     H
    MOV     A,M
    STAX    D							;DE must be a ptr
    POP     B
    RET
;DE, A, C, D, E
;DE, HL, BC on stack
L_KEY_SCAN_3:
    LXI     H,KEYCNT2_R
    INR     A
    CMP     M
    JNZ     L_STORE_KEY						;store key
    POP     D
    POP     H
    POP     B
    RET
;
; Store key
; 
;	D, H, B on stack
; IN:
;	A
;	C
;	E
;	HL		KEYCNT2_R
;
L_STORE_KEY:
    MOV     M,A							;update [KEYCNT2_R]
    MOV     A,C
    RLC									;times 8
    RLC    
    RLC    
    ORA     E
    INX     H							;HL == KEYSTRG_R
    MOV     M,A
    INX     H							;HL == KEYXXXX_R
    MOV     M,D
    POP     D							;0FF9CH
    XCHG
    SHLD    KEYPTR_R					;Pointer to entry in 2nd Storage Buffer for key to DE
    XCHG
    JMP     L_KEY_SCAN_2				;H, B on stack
;
; IN:
;	DE		KBDCOL2_R+8
;	HL		KBDCOL1_R+8
;
L_DECODE_KEY:
    LDAX    D							;get byte from [DE] to B
    MOV     B,A
    MOV     A,M							;get byte from M
    STAX    D							;store in [DE]
    RLC									;bit 7 to carry
    RNC									;retif bit 7 was clear
    MOV     A,B							;get original byte from [DE]
    RLC									;bit 7 to carry
    RC									;retif bit 7 was set
    XTHL								;save HL to stack. Remove return address.
    LXI     H,L_KEY_DECODE_6			;continuation function
    XTHL								;set new return address, restore HL
    MVI     B,00H
    MOV     D,B							;clear B, D
    MOV     A,M							;get byte from M
    RRC									;bit 0 to carry
    MVI     A,03H						;preload
    RC									;retif bit 0 was set 
    MVI     A,13H						;return 03H or 13H
    RET
;
; IN:
;	HL		&KEYCNT2_R
;
L_PRE_KEY_DECODE:
    DCX     H							;point to KEYCNT_R
    MVI     M,54H						;reset KEYCNT_R
    DCX     H							;point to KEYSHFT_R
    LDA     KBDCOL2_R+8					;Keyboard scan column storage @2
    MOV     M,A							;copy to KEYSHFT_R
;
; Key decoding
; DE will contain delta to R_KEYBOARD_CONV_SHIFTED table (code based)
;
R_KEY_DECODE:							;7122H
    LDA     KEYSTRG_R					;Key position storage
    MOV     C,A							;key code
    LXI     D,002CH						;E=R_KEYBOARD_CONV_SHIFTED - R_KEYBOARD_CONV_MATRIX
    MOV     B,D							;D=0. Location dependent. Use MVI B,0
    CPI     33H
    JC      +							;brif A < 33H
    LXI     H,KEYXXXX_R
    MOV     M,B							;Set to 0
+	LDA     KEYSHFT_R					;Shift key status storage
    RRC									;bit 0 to carry
    PUSH    PSW							;save A/carry
    MOV     A,C							;reload key code
    CMP     E							;contains 2CH offset
    JC      L_KEY_DECODE_1				;brif key code < 2CH
    CPI     30H
    JNC     +							;brif key code >= 30H
; keycode between 2DH & 2FH
    POP     PSW							;reload A/carry
    PUSH    PSW
    RRC									;bit 0 to carry
    JC      L_KEY_DECODE_1				;brif bit 0 was set
+	LXI     H,L_KEYBOARD_4				;Code Based. preload keyboard mapping table
    POP     PSW							;restore A/carry
    JNC     +							;brif carry clear
    LXI     H,L_KEYBOARD_3				;Code Based. load keyboard mapping table
+	DAD     B							;index into table
    MOV     A,M
    RLC    
    ORA     A							;clear carry
    RAR
    MOV     C,A							;move key to C. Assume B == 0
    JNC     R_KEY_ADD_TO_BUF			;Keyboard buffer management -
										;	place subsequent key in buffer
    CPI     08H
    JNC     +							;brif A >= 08H
    LDA     FNKMOD_R					;Function key mode/ BIT 7=in TEXT (0x80);
										;	BIT 6=in TELCOM (0x40)
    ANI     0E0H						;11100000B	isolate bits 5-7
    JNZ     +
    LHLD    CURLIN_R					;Currently executing line number
    MOV     A,H							;test for 0FFFFH
    ANA     L
    INR     A
    JZ      +							;brif direct mode
    LXI     H,FKEYSTAT_R				;Function key status table (1 = on)
    DAD     B							;index
    MOV     A,M
    ORA     A
    JZ      +							;brif FKEYSTAT_R[BC] == 0
    MOV     A,C							;get key back
    ORI     80H							;mark key as Function key
    JMP     R_KEY_CTRLC_TST				;Keyboard buffer management - place key in new buffer

+	DCR     B
    JMP     R_KEY_ADD_TO_BUF			;Keyboard buffer management -
										;	place subsequent key in buffer

L_KEY_DECODE_1:
    POP     PSW
    JC      +
    MOV     E,B
+	RRC									;test SHIFT 
    PUSH    PSW							;save SHIFT Carry status
    JC      R_UNSHIFTED_KEY				;Handle unshifted & non-CTRL key during key decoding
L_KEY_DECODE_2:
    LXI     H,L_KEYBOARD_1				;Code Based. preload keyboard mapping table
    RRC									;test CTRL
    JC      L_KEY_DECODE_3
    LXI     H,L_KEYBOARD_2				;Code Based. preload keyboard mapping table
    RRC									;test GRPH
    JC      L_KEY_DECODE_3
    RRC									;test CODE
    JNC     +							;brif !CODE
    LXI     H,R_KEYBOARD_CONV_MATRIX	;Code Based. 
    DAD     B							;index
    PUSH    D							;save DE
    MOV     D,A							;save key
    CALL    R_NUM_KEY				    ;Handle NUM key during key decoding. Returns HL.
    MOV     A,D							;restore key
    POP     D							;restore DE
    JZ      L_KEY_DECODE_5				;brif R_NUM_KEY returned no match
;
; key could be a NUM value
;
+	RRC									;test CAPSLOCK
    CC      R_CAPS_LOCK_KEY				;Handle CAPS LOCK key during key decoding
    LXI     H,R_KEYBOARD_CONV_MATRIX	;Code Based. 
L_KEY_DECODE_3:
    DAD     D							;update table address
L_KEY_DECODE_4:
    DAD     B
L_KEY_DECODE_5:
    POP     PSW							;restore SHIFT Carry status
    MOV     A,M							;keyboard character 
    JNC     +							;brif no shift
    CPI     'a'- 1						;60H
    RNC									;return if >= 'a'- 1
    ANI     3FH							;00111111H. No Carry
	SKIP_2BYTES_INST_JC					;skip ORA A & RZ
+	ORA     A							;test A
    RZ									;return if A == 0
L_KEY_DECODE_6:							;continuation function
    MOV     C,A							;save key value
    ANI     0EFH						;11101111B clear bit 4
    CPI     03H							;^C
    JNZ     R_KEY_ADD_TO_BUF			;if not ^C => Keyboard buffer management - place subsequent key in buffer
    LDA     FNKMOD_R					;Function key mode/ BIT 7=in TEXT (0x80) BIT 6=in TELCOM (0x40)
    ANI     0C0H						;11000000
    JNZ     R_KEY_ADD_TO_BUF			;if TEXT or TELCOM => Keyboard buffer management - place subsequent key in buffer
    MOV     A,C							;unmodified key value: 03H or 13H (XOFF) fall through
;
; Keyboard buffer management - clear buffer if ^C
;
; IN:
;	A		key
;	BC		Extended key
;
R_KEY_CTRLC_TST:						;71D5H
    STA     PNDCTRL_R					;Holds CTRL-C or CTRL-S until it is processed
    CPI     03H							;^C
    RNZ									;brif FALSE
    LXI     H,KBCNT_R				    ;Keyboard buffer count
    MVI     M,01H						;remove pending keys
    INX     H							;to keyboard typeahead buffer KBBUF_R
    JMP     L_STORE_EXT_KEY				;store extended key
;
; Keyboard buffer management - place subsequent key in buffer
; extended key in BC
; D must be 0
;
R_KEY_ADD_TO_BUF:						;71E4H
    LXI     H,KBCNT_R				    ;Keyboard buffer count
    MOV     A,M
    CPI     32							;max
    RZ									;return if buffer full
    INR     M							;update			
    RLC									;count * 2
    INX     H							;to keyboard typeahead buffer KBBUF_R
    MOV     E,A
    DAD     D							;ptr to store location
L_STORE_EXT_KEY:						;BC input
    MOV     M,C							;store key
    INX     H							;next
    MOV     M,B							;store extended part
    POP     PSW							;clean up stack
;
; Set new interrupt mask and pop all regs & RET
;
; See also L_ENA_INT_75_65
;
;
L_ENA_INT_75_65_POP:
    MVI     A,09H						;00001001 MSE==1 Unmask 7.5 & 6.5. Mask INT 5.5
    SIM    
;
; Interrupt exit routine (pop all regs & RET)
;
R_ISR_EXIT_FUN:							;71F7H
    POP     PSW
L_POP_WREGS_RET:
    POP     B
    POP     D
    POP     H
    EI     
    RET
;
; continuation of R_KEY_DETECTION()
;
L_KEY_DETECT_1:
    LXI     H,KBDCNTR_R
    DCR     M
    RNZ									;retif KBDCNTR_R != 0
    LXI     H,KBDCOL1_R
    MVI     B,11H						;17
    JMP     R_CLEAR_MEM				    ;Zero B bytes at M. Then return from R_KEY_DETECTION()
;
; Handle unshifted & non-CTRL key during key decoding
; BC contains offset
; comment may be wrong
; PSW (SHIFT Carry status) on stack
;
R_UNSHIFTED_KEY:						;720AH
    MOV     A,C
    CPI     1AH							;26
    LXI     H,R_KEYBOARD_CONV_SHIFTED	;Code Based. preload
    JC      L_KEY_DECODE_4				;brif A < 1AH
    CPI     2CH							;','
    JC      +							;brif A < 2CH
    CPI     30H							;48
    JC      R_ARROW_KEY				    ;if A < 30H Handle Arrow keys during key decoding
+	POP     PSW
    PUSH    PSW
    JMP     L_KEY_DECODE_2
;
; Handle Arrow keys during key decoding
; B must be 0
;
R_ARROW_KEY:							;7222H
    SUI     2CH							;rebase to 0..3
    LXI     H,L_KEYBOARD_5					;Code Based. keyboard table
    MOV     C,A							;store rebased key value
    DAD     B							;index
    JMP     L_KEY_DECODE_5
;
; Handle CAPS LOCK key during key decoding
;
R_CAPS_LOCK_KEY:						;722CH
    MOV     A,C
    CPI     1AH							;26
    RNC									;retif A >= 1AH
    MVI     E,2CH						;44
    RET
;
; Handle NUM key during key decoding
;
; IN:
;	HL		indexed R_KEYBOARD_CONV_MATRIX ptr (Code Based)
; OUT:
;	HL		NUM key value for this key
;	Z		set if no match
;
R_NUM_KEY:								;7233H
    MOV     A,M							;Code Based.
    MVI     E,06H						;6..0 Loop counter: test 7 keys
    LXI     H,R_KEYBOARD_NUM			;Code Based. keyboard num decoding table
-	CMP     M							;compare with relevant NUM key entry
    INX     H							;ptr to NUM value
    RZ									;return HL here  
    INX     H							;inc ptr to next num key entry
    DCR     E							;loop counter
    JP      -							;brif E >= 0
    RET									;! Z flag
;
; Scan keyboard for character (CTRL-BREAK ==> CTRL-C)
;
R_SCAN_KEYBOARD:						;7242H
    CALL    L_DIS_INT_75_65				;Disable Background task
    LDA     KBCNT_R						;Keyboard buffer count
    ORA     A
    JZ      R_ENABLE_INTS     		 	;brif no chars: Enable interrupts as normal
    LXI     H,KBBUF_R+1
    MOV     A,M
    ADI		02H
    DCX     H
    MOV     A,M
    PUSH    PSW
    DCX     H							;to KBBUF_R
    DCR     M
    MOV     A,M
    RLC    
    MOV     C,A
    INX     H
    LXI     D,KBBUF_R+2					;0FFADH
-	DCR     C
    JM      +							;pop PSW and enable interrupt
    LDAX    D
    MOV     M,A
    INX     H
    INX     D
    JMP     -

+	POP     PSW
;
; Enable interrupts as normal
;
R_ENABLE_INTS:				    		;726AH
    PUSH    PSW
    MVI     A,09H						;00001001 MSE==1 Unmask 7.5 & 6.5. Mask INT 5.5
    SIM    
    POP     PSW
    RET
;
; Check keyboard queue for pending characters
;
R_CHK_PENDING_KEYS:						;7270H
    CALL    R_CHK_BREAK				    ;Check for break or wait (CTRL-S)
    JZ      +
    CPI     03H
    JNZ     +
    ORA     A
    STC
    RET
+	LDA     KBCNT_R						;Keyboard buffer count
    ORA     A
    RET
;
; Check for break or wait (CTRL-S)
;
R_CHK_BREAK:							;7283H
    PUSH    H
    LXI     H,PNDCTRL_R					;Holds CTRL-C or CTRL-S until it is processed
    MOV     A,M
    MVI     M,00H						;clear ^C or ^S
    POP     H
    ORA     A
    RP     								;return if ^C or ^S
    PUSH    H
    PUSH    B
    LXI     H,FNKSTR_R+41H				;Function key definition area 0F7CAH
    MOV     C,A							;zero extend A to BC
    MVI     B,00H
    DAD     B							;times 8
    DAD     B
    DAD     B
    CALL    R_TRIG_INTR				    ;Trigger interrupt.  HL points to interrupt table
    POP     B
    POP     H
    XRA     A
    RET
;
; Check if SHIFT-BREAK is being pressed
; Returns carry if pressed.
;
R_CHK_SHIFT_BREAK:						;729FH
    PUSH    B
    INPORT	0B9H						;8155 PIO Port A
    MOV     C,A
    CALL    R_SCAN_SPECIAL_KEYS      	;Scan BREAK),CAPS),NUM),CODE),GRAPH),CTRL),SHIFT & set bits in A
    PUSH    PSW
    MOV     A,C
    OUTPORT	0B9H						;8155 PIO Port A
    POP     PSW
    POP     B
    ANI     81H							;Test for SHIFT-BREAK key combination
    RNZ									;SHIFT-BREAK not pressed.
    STC									;set carry
    RET
;
; Scan BREAK),CAPS),NUM),CODE),GRAPH),CTRL),SHIFT & set bits in A
;
; DE & HL unchanged
;
R_SCAN_SPECIAL_KEYS:				    ;72B1H
    MVI     A,0FFH						;bit pattern
    OUTPORT	0B9H						;8155 PIO Port A. Select columns 1-8
    INPORT	0BAH						;read 8155 PIO Port B.
    ANI     0FEH						;11111110
    MOV     B,A							;save bit pattern
    OUTPORT	0BAH						;set 8155 PIO Port B. Deselect column 9
    INPORT	0E8H						;Keyboard input and misc. device select
    PUSH    PSW							;save result in A. 
    MOV     A,B							;restore bit pattern
    INR     A							;turn on bit 0
    OUTPORT	0BAH						;8155 PIO Port B. Select column 9
    POP     PSW							;restore result in A
    RET
;
; Produce a tone of DE freq and B duration
;
R_GEN_TONE:								;72C5H
    DI 
    MOV     A,E
    OUTPORT	0BCH						;8155 Timer register. LSB of timer counter
    MOV     A,D
    ORI     40H							;01000000
    OUTPORT	0BDH						;8155 Timer register. MSB of timer counter
    MVI     A,0C3H						;set Port A & B to OUTPUT, start 8155 timer
    OUTPORT	0B8H						;set 8155 PIO Command/Status Register
    INPORT	0BAH						;read 8155 PIO Port B
    ANI     0F8H						;11111000 clear bits 0..2
    ORI     20H							;00100000 set bit 5: Data to beeper if bit 2 set. Set if bit 2 low
    OUTPORT	0BAH						;set 8155 PIO Port B. Start tone
L_GEN_TONE_1:
    CALL    R_CHK_SHIFT_BREAK			;Check if SHIFT-BREAK is being pressed
    JNC     +							;brif NOT pressed
    MVI     A,03H						;SHIFT-BREAK to be` pressed
    STA     PNDCTRL_R					;Holds CTRL-C or CTRL-S until it is processed
    JMP     L_STOP_TONE
;
; Duration routine
;   100 times R_DELAY_FUNC(30)
;
+	MVI     C,64H						;100 to C
-	PUSH    B							;save BC
    MVI     C,1EH						;30 to C
    CALL    R_DELAY_FUNC				;Delay routine - decrement C until zero
    POP     B							;restore BC
    DCR     C
    JNZ     -
    DCR     B							;Tone duration
    JNZ     L_GEN_TONE_1				;continue while checking SHIFT-BREAK
L_STOP_TONE:
    INPORT	0BAH						;read 8155 PIO Port B
L_BEEP_RESET:							;called by vt100.asm with A==01H
    ORI     04H							;00000100. Beep toggle
										;	(1-Data from bit 5, 0-Data from 8155 timer)
    OUTPORT	0BAH						;set 8155 PIO Port B. Turn off tone
    CALL    L_RS232_SET_1				;reset 8155
    EI     
    RET

	if DEADCODE
;
; IO ports 70H..7FH are reserved for user expansion.
; IO ports 070H, 071H are used by the REMEM hardware extension.
; Unclear what original ROM code is doing.
; Could be used by an option rom.
;
L_PORT70H:
    PUSH    H
    PUSH    D
    PUSH    B
    PUSH    PSW
	GETDEFROMM
    MOV     C,M
    INX     H
    MOV     B,M							;get BC from M
    INX     H
    MOV     A,M							;get A from M
    OUT     70H
    DI 
    INX     H
    MOV     A,M
    OUT     71H
    INX     H
    MOV     A,M
    OUT     72H
-	MOV     A,B							;BC is count
    ORA     C
    JZ      R_ISR_EXIT_FUN				;Interrupt exit routine (pop all regs, EI & RET)
    IN      73H							;Read from port 73H and store at *DE
    STAX    D
    INX     D
    DCX     B
    JMP     -

	else								;DEADCODE
	rept 37								;37 bytes FREE CODE SPACE if !DEADCODE
	nop
	endm
	endif								;DEADCODE
;
; Copy clock chip regs to M (10 bytes)
;
R_GET_CLK_CHIP_REGS:				    ;7329H
	SKIP_XRA_A							;ORI 0AFH
;
; Update clock chip regs from M: 40 bits clock data
;
; A == 0 => update. A == 0AFH => copy
;
R_PUT_CLK_CHIP_REGS:				    ;732AH
    XRA     A
    PUSH    PSW							;save action
    CALL    L_DIS_INT_75_65				;Disable Background task. Flags unaffected.
    MVI     A,03H						;Group 0: Read Clock Chip mode
    CNZ     R_SET_CLK_CHIP_MODE      	;Set clock chip mode to READ if copy operation
    MVI     A,01H						;Group 0: Clock Serial Shift Mode
    CALL    R_SET_CLK_CHIP_MODE      	;Set clock chip mode
    MVI     C,07H
    CALL    R_DELAY_FUNC				;Delay routine - decrement C until zero
    MVI     B,0AH						;loop 10 times 1 nibble
ClkLoop1:
    MVI     C,04H						;nibble loop
    MOV     D,M							;get existing data from buffer (if updating)
ClkLoop2:
    POP     PSW							;copy if A != 0
    PUSH    PSW
;
; Labels & comments seems to reverse read and write
;
    JZ      R_READ_CLK_CHIP_BIT      	;Read next bit from Clock Chip
;
; Write (??) next bit to Clock Chip
; copy bit from clock chip to upper nibble in D
;
    INPORT	0BBH						;read 8155 PIO Port C
    RAR									;move bit 0 to carry: Serial data input from clock chip
    MOV     A,D							;get D into A
    RAR									;move carry into bit 7
    MOV     D,A
    XRA     A
    JMP     L_CLK_CHIP
;
; Read (??) next bit from Clock Chip
;
R_READ_CLK_CHIP_BIT:					;7352H
    MOV     A,D							;get D into A
    RRC									;move bit 0 into carry and bit 7
    MOV     D,A							;save rotated value
	; carry was old bit 0 of D. Move carry to bit 4
	; bit 4 is "Serial data into clock chip"
    MVI     A,10H						;00010000
    RAR									;C0001000
    RAR									;0C000100
    RAR									;00C00010
    RAR									;000C0001
    OUTPORT	0B9H
;
; continue. Toggle clock bit (3) to shift bit in our out of Clock Chip
;
L_CLK_CHIP:
    ORI     09H							;00001001 Set bit 3 (Clock) + C0
    OUTPORT	0B9H
    ANI     0F7H						;11110111 clear bit 3 (Clock)
    OUTPORT	0B9H
    DCR     C							;bits in nibble count
    JNZ     ClkLoop2
    MOV     A,D							;nibble from Clock Chip if reading
    RRC									;High nibble to low nibble
    RRC
    RRC
    RRC
    ANI     0FH							;00001111 isolate lower nibble
    MOV     M,A							;update Clock Chip Buffer
    INX     H
    DCR     B							;nibble
    JNZ     ClkLoop1
    POP     PSW							;get mode in Z and remove from stack
    MVI     A,02H						;Write Clock Chip Mode
    CZ      R_SET_CLK_CHIP_MODE      	;Set clock chip mode if mode was 0
    XRA     A							;nop/hold Clock Chip Mode
    CALL    R_SET_CLK_CHIP_MODE      	;Set clock chip mode
    JMP     L_ENA_INT_75_65				;Enable background tasks
;
; Set clock chip mode
;
; Port 0B9H bits:
;   0 -  C0
;   1 -  C1
;   2 -  C2
;   3 -  Clock
;	4 -  Serial data into clock chip
;
; A contains mode
;	Group 0
;	0: nop/hold
;	1: Serial Shift
;	2: Write Clock chip
;	3: Read Clock chip
;	Group 1
;	5: 256 Hz
;
;
R_SET_CLK_CHIP_MODE:				    ;7383H
    OUTPORT	0B9H
; Strobe bit 2 for Clock chip
    LDA     PORTE8_R					;Contents of port E8H
    ORI     04H							;00000100 set bit 2
    OUTPORT	0E8H						;set Keyboard input and misc. device select
    ANI     0FBH						;11111011 clear bit 2
    OUTPORT	0E8H						;set Keyboard input and misc. device select
    RET
;
;Cursor BLINK - Continuation of RST 7.5 Background hook
;
L_BLINK_CURSOR_0:
    CALL    L_DIS_INT_75_65				;Disable Background task
    LXI     H,R_KEYSCAN_MGT_FUN			;set return address
    PUSH    H
    LXI     H,CSRCNT_R
    DCR     M							;Decrement the cursor blink count-down
    RNZ									;retif not 0
    MVI     M,7DH						;reset the cursor blink count-down
    DCX     H							;Decrement to address of cursor blink on-off status: CSRSTAT_R
    MOV     A,M							;get CSRSTAT_R
    ORA     A							;test
    JP      +							;brif bit 7 clear
    RPO									;Return if Parity Odd: return if P == 0. If A == 080H, return
+	XRI     01H							;flip status and update
    MOV     M,A
;
; Blink the cursor
;
R_BLINK_CURSOR:							;73A9H
    PUSH    H
    LXI     H,LCDBUF_R				    ;LCD buffer
    MVI     D,00H						;function argument: read
    CALL    L_LCD_CHAR_RW				;read bit pattern from LCD. Updates HL
    MVI     B,06H
    DCX     H							;reverse LCDBUF_R
-	MOV     A,M
    CMA									;complement pixels to get inverse video
    MOV     M,A
    DCX     H
    DCR     B
    JNZ     -
    INX     H
    MVI     D,01H						;function argument: write
    CALL    L_LCD_CHAR_RW				;Bytes to/from LCD. Updates HL
    POP     H
    RET
;
; Turn off background task, blink & reinitialize cursor blink time
;
L_BLINK_LCD:
    PUSH    H							;save all registers
    PUSH    D
    PUSH    B
    PUSH    PSW
    CALL    L_DIS_INT_75_65				;Disable Background task
    LXI     H,CSRSTAT_R
    MOV     A,M
    RRC									;bit 0 to Carry
    CC      R_BLINK_CURSOR				;calif bit 0 was 0: Blink the cursor. Saves HL
    MVI     M,80H						;Reset Cursor Blink in CSRSTAT_R
    JMP     L_ENA_INT_75_65_POP			;Set new interrupt mask and pop all regs & RET
;
; Initialize Cursor Blink to start blinking
;
L_INIT_CRS_BLINK:
    PUSH    PSW
    PUSH    H
    CALL    L_DIS_INT_75_65				;Disable Background task
    LXI     H,CSRSTAT_R					;Cursor Blink Status
    MOV     A,M
    ANI     7FH							;clear bit 7 -> enable Cursor Blink
    MOV     M,A
    INX     H							;to CSRCNT_R
    MVI     M,01H
    MVI     A,09H						;00001001 MSE==1 Unmask 7.5 & 6.5. Mask INT 5.5
    SIM    
    POP     H
    POP     PSW
    RET
;
; Character plotting level 7.
;	Plot character in C on LCD at (HL). TODO should be at DE row & column
; IN:
;	C		char to plot
;	DE		Row & Column (1 based) char positions (not pixels)
;
R_CHAR_PLOT_7:							;73EEH
    CALL    L_DIS_INT_75_65				;Disable Background task
    LXI     H,0
    DAD     SP							;SP to HL
    SHLD    SAVEDSP_R					;store SP
    DCR     D							;make Row & Column 0 based
    DCR     E
    XCHG								;to HL
    SHLD    LCTEY_R						;store 0-based Row & Column
    MOV     A,C
    LXI     D,R_LCD_CHAR_SHAPE_TBL1-1	;Code Based. Char generation table
    SUI     20H							;rebase
;
; If A == ' ', we jump, causing DE to point to R_LCD_CHAR_SHAPE_TBL1-1
; Happens to work since byte before R_LCD_CHAR_SHAPE_TBL1 == 0
;
    JZ      +							;brif A == ' '.
    INX     D							;to R_LCD_CHAR_SHAPE_TBL1
    CPI     60H							;80H since 20H subtracted
    JC      +							;brif char was < 080H
;
; char >= 60H, meaning originally >= 128/80H
; keep the 60H (96) offset when doing table calculations
; but correct the table address by 96 * 6 = 576 bytes (240H)
;
    LXI     D,R_LCD_CHAR_SHAPE_TBL2-0240H ;Code Based. special characters table address
+	PUSH    PSW							;save Carry. Carry set means char < 80H
    MOV     L,A							;zero extend rebased char to HL
    MVI     H,00H
    MOV     B,H							;copy HL to BC
    MOV     C,L
    DAD     H							;times 2
    DAD     H							;times 4
    DAD     B							;times 5
    POP     PSW							;retrieve Carry
    PUSH    PSW
    JC      +							;brif char < 80H
; char >= 80H, width is 6 bytes
    DAD     B							;times 6
+	DAD     D							;index by adding offset to table address
    POP     PSW							;restore Carry
    JNC     +							;brif char >= 080H
;
; char < 80H. Copy bytes to LCDBUF_R so we can add a 0
;
    LXI     D,LCDBUF_R				    ;LCD buffer ptr
    PUSH    D							;save LCD buffer ptr
    MVI     B,05H
    CALL    R_MOVE_B_BYTES				;Move 5 bytes from M to (DE)
    XRA     A
    STAX    D							;terminate
    POP     H							;LCD buffer ptr to HL
+	MVI     D,01H						;function argument: write
    CALL    L_LCD_CHAR_RW				;Bytes to/from LCD
L_CHAR_PLOT_EXIT:
    XRA     A
    STA     SAVEDSP_R+1					;0FFF9H clear MSB
    CALL    L_CLR_LCD_TOP				;Set the display top line to zero for all LCD controllers
;
; See also L_ENA_INT_75_65_POP
;
L_ENA_INT_75_65:						;Enable background tasks
    MVI     A,09H						;00001001 MSE==1 Unmask 7.5 & 6.5. Mask INT 5.5
    SIM    
    RET
;
; Rebase LCD column # & row #. Store in LCTEY_R and LCTEX_R
;
; IN:
;	DE		column & row, 1 based
;
L_SET_LCTEYX:
    CALL    L_DIS_INT_75_65				;Disable Background task
    DCR     D							;rebase column & row to 0
    DCR     E
    XCHG								;DE to HL 
    SHLD    LCTEY_R						;LCD row 0..7, column 0..39
    JMP     L_ENA_INT_75_65				;Enable background tasks
;
; Plot (set) point DE on the LCD
;
; IN:
;	D		column (X) (0..239)
;	E		row (Y) in bits (0..63)
;
R_PLOT_POINT:							;744CH
	SKIP_XRA_A							;ORI 0AFH  plot: A != 0
;
; Clear (reset) point DE on the LCD
;
R_CLEAR_POINT:							;744DH
    XRA     A							;clear: A == 0
;
; Need to compute a bit address for Y, then read the byte value at the
; byte address the bit is in, clear or set the appropriate bit
; then write back the byte value to the same byte address
;
; D: column	E: row
;
    PUSH    PSW							;save mode
    CALL    L_DIS_INT_75_65				;Disable Background task
    PUSH    D							;save original coordinates
;
; compute vertical position within driver chip (column)
; driverX = column % 50
; C will be 2 times driver # (0..9)
;
    MVI     C,0FEH						;predecrement
    MOV     A,D							;get column
-	INR     C
    INR     C
    MOV     D,A							;driverX
    SUI     32H							;50
    JNC     -
    MVI     B,00H						;zero extend C to BC
;
; D is now column address within the driver #, which is in C (times 2).
; column address range 0..31H (requires 6 bits)
; E is Y (row) range 0..3FH
; Y consists of: Y-bank (bit 5) Y-page (bits 3..4) Y-bit (bits 0..2)
; row 0..1FH is TOP Drivers bank. row 20H..3FH is bottom Drivers bank.
; move bit 5 to carry to determine top or bottom bank
; update L_LCD_DRVS_TOP if carry set
; take _BV(Y-bit) to clear or set a pixel in existing byte value
;
    LXI     H,L_LCD_DRVS_TOP   			;Code Based. preload 8155 PIO chip bit patterns	for top bank
    MOV     A,E							;00XHHHHH Y
    RAL									;0XHHHHH0
    RAL									;XHHHHH00
    RAL									;HHHHH000 Y-bank (bit 5) to carry
;
; A now contains (Y << 3). Bits 6..7 are the page number of Y
; no advantage to using BASEPATCH here.
	if	0&BASEPATCH
	LXI		H,L_LCD_DRVS_TOP			;@STEVEADOLPH Why load L_LCD_DRVS_TOP again?
	CALL	L_UPD_DRV_SELECT_PTR		;C, carry is argument. Add zero extended C (2 times driver #)
	NOP
	NOP
	else								;!BASEPATCH
    JNC     +
    LXI     H,L_LCD_DRVS_BOTTOM			;Code Based.
+	DAD     B
    MOV     B,A							;save (Y << 3)
	endif								;BASEPATCH
	
    CALL    L_SELECT_LCD_DRIVER			;HL input
    MOV     A,B							;restore (Y << 3)
    ANI     0C0H						;Isolate page number
    ORA     D							;merge with driver X: PPAAAAAA
    MOV     B,A							;save complete driver address in B
    MVI     E,01H						;byte count 1
    LXI     H,LCDBUF_R					;LCD buffer
    CALL    L_LCD_PLOT_RD				;read it
    POP     D							;restore original coordinates
    MOV     D,B							;complete driver address
    MOV     A,E							;Y to A
    ANI     07H							;Y-bit
    ADD     A							;double since 2 bytes per entry 0..14
    MOV     C,A							;zero extend A to BC
    MVI     B,00H
    LXI     H,L_BIT_VCTRS	 		  	;Code Based. bit vectors 01H..80H
    DAD     B							;index into L_BIT_VCTRS
    POP     PSW							;restore mode (A==0 clear A !=0 plot)
    MOV     A,M							;get bit vector for desired bit
    LXI     H,LCDBUF_R				    ;LCD buffer
    JNZ     +							;brif Z flag not set: PLOT function
;
; Clear a pixel: [LCDBUF_R] &= ~_BV(Y-bit)
;
    CMA									;~_BV(Y-bit)
    ANA     M							;& ~_BV(Y-bit)
	SKIP_BYTE_INST_B					;skip ORA instruction
;
; Plot a pixel: [LCDBUF_R] |= _BV(Y-bit)
;
+	ORA     M							;| _BV(Y-bit)
    MOV     M,A							;update LCDBUF_R
    MOV     B,D							;complete driver address
    MVI     E,01H						;byte count 1
    CALL    L_LCD_PLOT_WR				;write byte containing the bit to set or clear
    JMP     L_ENA_INT_75_65				;Enable background tasks
;
; Bytes to/from LCD. Updates HL
;
; uses LCTEX_R and LCTEY_R as coordinates. These are
; 0 based char coordinates range 0..39 and 0..7
;
; M100 LCD hardware is addressed as 240 columns (X) by
; 8 rows (Y) byte values (not bits)
; There are 2 banks of driver chips, 5 drivers per bank
; top bank for rows 0..3 and bottom bank for rows 4..7
; Each driver has a maximum of 50 columns where each
; column contains 4 (vertical) bytes of pixels.
; These 4 bytes are called pages (1 byte per page)
; labelled page 0..3.
; Each bank of 5 drivers thus supports 250 columns
; but only 240 columns are used. The last 10 columns
; in drivers 4 and 8 are not displayed.
; The hardware supports a mechanism where it can be told
; which page to show as the top line. The default M100
; firmware does not use this facility but the
; HWSCROLL conditional does.
;
; For a given coordinate X,Y (range 0..239, 0..7)
; we need to determine the driver (0..9), the
; column offset within that driver (X % 50) and
; the page number within that driver (Y % 5)
; The driver is selected using ports 0xB9 and 0xBA (L_SELECT_LCD_DRIVER)
; The address within each driver to be read or written
; is contained in a byte of the form PPAAAAA
; where PP means the page number (0..3) in bits 6-7
; and AAAAAA is the column number (0..49) in bits 0..5
; this address is written to the selected driver using
; port 0xFE. A subsequent read of port 0xFF will return
; the byte value at that location and a write to port 0xFF
; will write a byte to that location.
;
; Keep in mind that this byte value represents 8 vertical
; pixels on the LCD where bit 0 is the top pixel of the
; column
;
; We're writing up to 6 (vertical) bytes in this function
; so these byte may span across multiple driver chips (step 1, step 2)
;
; Original ROM:
; R_LCD_BIT_PATTERNS and L_LCD_BIT_PATTERNS_2 contain bit patterns
; to write to port 0xB9 and 0xB1 to select a driver chip.
; These ports require 10 bits so the table uses 2 bytes per driver.
;
; BASEPATCH:
; R_LCD_BIT_PATTERNS has 80 bytes, 2 bytes per entry, so 40 entries
; where byte 1 is an offset in L_LCD_DRVS_TOP/L_LCD_DRVS_BOTTOM
; and byte 2 is driver column address to be used for each entry
;
; LCDPATCH:
; To save space, the R_LCD_BIT_PATTERNS tables are removed
; completely to save space. The code does the full driver decoding
; for each column for char column positions: 8, 16, 33.
; This slows down the display rendering a little but
; saves a lot of code space
;
;	if ((LCTEX_R == 8) || (LCTEX_R == 16) || (LCTEX_R == 33)) {
;		bitcol = LCTEX_R * 6;			// 6 bit columns per char
;		for (i = 0; i < 6; ++i) {
;			L_LCD_BYTE_PLOT(bitcol, LCTEY_R, pBuf + i, 1):
;				select driver based on bitcol and bank (from LCTEY_R)
;				compute driver address (based on bitcol and LCTEY_R)
;				call L_LCD_PLOT for 1 column
;				++bitcol;
;		} else {
;			L_LCD_BYTE_PLOT(bitcol, LCTEY_R, pBuf + i, 6)
;				call L_LCD_PLOT for 6 columns
;		}
;	}

;
; Function argument in D indicates read or write
;
; The M100 LCD drivers do support auto-increment of the column
; address within a driver so only the first write in a series
; of writes (character pixels) needs to specify the column address.
;
; The ROM addresses of L_LCD_CHAR_RW() and R_DELAY_FUNC(), which is
; the function after all this LCD access code need to stay the same.
;
; Note that the M100 always uses bit columns as the X coordinates and
; page numbers (columns of 8 pixels) to talk to the hardware.
; The ROM code uses byte positions coordinates (LCTEX_R and LCTEY_R)
; for the X axis when dealing with characters.
; The ROM code uses bit positions for both the X and Y axis when dealing
; with pixels.
;
; There are also special commands to send to the M100 LCD drivers,
; including scroll support by selecting the page number showing
; as the top line (HWSCROLL)
;
; L_LCD_CHAR_RW()
;
; Read/Write 6 bytes from/to the LCD at LCD
; location [LCTEX_R, LCTEY_R]
;
; IN:
;	D		0 (read) or 1 (write)
;	HL		buffer to read or write
;
; Normally uses 2 steps in case the 6 bytes span two driver chips.
;

L_LCD_CHAR_RW:							;74A2H

	if LCDPATCH							;simplified BASEPATCH
	push	h							;save buffer ptr
;
; compute LCD Driver Selection table ptr
;
	xra		a							;clear carry for coming RARs
	lda		LCTEY_R						;LCD char row 0..7 00000421
;
; determine LCD bank driver 0..4 (top) or 5..9 (bottom)
; also moves bits 1,2 to 6,7: page number
; LCTEY_R should be in the range 0..7: 00000421
;
	RAR									;00000042 1 to carry 
  	RAR									;10000004 2 to carry
   	RAR									;21000000 4 to carry. A has page number (range 0..3) in bits 6,7
	mov		e,a							;save page number
	LXI		H,L_LCD_DRVS_TOP			;Code Based. preload top table ptr
	JNC		+
	LXI		H,L_LCD_DRVS_BOTTOM			;bottom bank
+	SHLD	PBTABLE_R					;store LCD Driver Selection table ptr
    MVI     c,0							;preset split flag
    LDA     LCTEX_R						;LCD char column (0..39)
    CPI     08H
    JZ      +							;brif 8
    CPI     16
    JZ      +							;brif 16
    CPI     33
    JNZ     L_LCD_PLOT_2				;brif !33
; LCTEX_R == 8, 16 or 33: need to address each column individually
+	inr		c							;set split flag to 1
L_LCD_PLOT_2:
;
; multiply A by 6 to get LCD bit column
; A should be in the range 0..39 so no bits in position 6 & 7
;
	mov		l,a
	rlc									;times 2
	rlc									;times 4
	add		l							;times 5
	add		l							;times 6
	pop		h							;restore buffer ptr
;
; A is column number
; C is split flag
; D is read/write argument
; E is page number in bits 6..7
; HL is buffer ptr
;
	mov		b,a							;save column number - 1
	mov		a,c							;split flag
	ora		a							;test
	mov		a,b							;restore column number - 1
	jnz		L_LCD_PLOT_3				;must split character render
;
; A is column number
; D is read/write argument
; E is page number in bits 6..7
; HL is buffer ptr
;
	mvi		b,6							;send all char columns at once
	call	L_CHAR_COL_OUT
	ret
	
L_LCD_PLOT_3:
	dcr		a							;pre-decrement.
	mvi		b,6							;loop counter 6..1
L_LCD_CHAR_LOOP:
	push	b							;save loop counter
	inr		a							;next column
	push	psw							;save new column
	mvi		b,1							;send just 1 column
	call	L_CHAR_COL_OUT
	pop		psw							;restore current column
	pop		b							;update loop counter
	dcr		b							
	jnz		L_LCD_CHAR_LOOP				;brif not done
	ret
;
; A is column number  (0..239)
; B is column cnt	(1 or 6)
; D is read/write argument
; E is page number in bits 6..7
; HL is buffer ptr
;
L_CHAR_COL_OUT:
    PUSH    H							;save buffer ptr
	push	d							;save D,E: read/write & page number
	mov		d,b							;save column cnt
;
; compute vertical position within driver chip (column)
; A has column number. E has page number in bits 6..7
;
    MVI     C,0FEH						;predecrement
-	INR     C
    INR     C
    MOV     E,A							;column within driver
    SUI     32H							;50
    JNC     -
;
; D = column cnt
; E = column % 50
; C now 2 times driver # (0..9)
;
	MVI		B,00H						;zero extend C to BC
	LHLD	PBTABLE_R					;retrieve LCD Driver Selection table ptr
	DAD		B							;index into table
	CALL	L_SELECT_LCD_DRIVER			;HL input
	mov		a,e							;restore driver column address to A
	mov		c,d							;restore column cnt to C
	pop		d							;restore D,E: read/write & page number
	ORA		E							;merge in page number
	MOV		B,A							;B is complete driver address: PPAAAAAA
	POP		H							;restore updated buffer ptr
	push	d							;save read/write & page number
	mov		e,c							;column cnt: argument for L_LCD_PLOT()
	DCR		D							;decrement function argument. Sets Z flag if write argument
	CALL	L_LCD_PLOT					;Z is set: write. Z not set: read. Increments buffer ptr
	pop		d							;restore read/write & page number
	ret
	
	elseif BASEPATCH
	
    PUSH    H							;save buffer ptr
    MVI     E,06H						;preload byte count for step 1
    LDA     LCTEX_R						;LCD char column (0..39)
    CPI     08H							;8
    JZ      +							;brif 8: E -= 4: write 2 bytes in step 1
    CPI     10H							;16
    JZ      L_LCD_PLOT_1				;brif 16: E -= 2: write 4 bytes in step 1
    CPI     21H							;33
    JNZ     L_LCD_PLOT_2				;brif !33
; LCTEX_R == 33: write 2 bytes in step 1
+	DCR     E							;adjust byte count step 1
    DCR     E							;adjust byte count step 1
L_LCD_PLOT_1:
    DCR     E							;adjust byte count step 1
    DCR     E							;adjust byte count step 1
L_LCD_PLOT_2:
	RLC									;LCD column times 2
	MOV C,A								;sign extend A to BC
	MVI B,00H
	LXI H,R_LCD_BIT_PATTERNS			;Code Based. 
	DAD B								;index
	MOV C,M								;get offset to C
	INX H								;next
	MOV A,M								;get driver column address to A
	PUSH PSW							;save driver column address
	LDA LCTEY_R							;LCD char row 0..7 00000421
;
;determine LCD bank driver 0..4 (top) or 5..9 (bottom)
;also moves bits 1,2 to 6,7: page number
;
	RAR									;00000042 1 to carry 
  	RAR									;10000004 2 to carry
   	RAR									;21000000 4 to carry. A has page number (0..3) in bits 6,7
	LXI H,L_LCD_DRVS_TOP				;Code Based. preload
; add zero extended C (offset) to potentially updated HL
	CALL L_UPD_DRV_SELECT_PTR			;add C, carry is input. May update HL. Returns page number in B (bits 6..7)
	CALL L_SELECT_LCD_DRIVER			;HL input
	SHLD PBTABLE_R						;store updated LCD Driver Selection table ptr
	POP PSW								;restore driver column address to A
	ORA B								;merge in page number
	MOV B,A								;B is complete driver address.
	POP H								;restore buffer ptr
	DCR D								;decrement function argument. Sets Z flag if 1
	CALL L_LCD_PLOT						;Z is set: Z not set: read
	INR D								;increment function argument
	MVI A,06H							;compute byte count for step 2
	SUB E								;number of bytes just written
	RZ									;retif 0: done
	MOV E,A								;byte count for step 2
	PUSH H								;save HL
	LHLD PBTABLE_R						;restore updated LCD Driver Selection table ptr
;
; step 2 happens when the 6 bytes data for char generation span
; a driver boundary (just 3 cases, X==8, 16 or 33)
; if we need step 2, the column address within the new driver
; always starts at 0
;
    CALL    L_SELECT_LCD_DRIVER			;HL input
    POP     H							;restore ptr LCD Buffer
    MOV     A,B							;complete driver address
    ANI     0C0H						;isolate bits 6..7
    MOV     B,A							;page number only (column address 0)
    DCR     D							;clear carry for read/write
;
;	FALL THROUGH to step 2: L_LCD_PLOT_WR
;
; IN:
;	B		complete driver address PPAAAAAA
;	E		byte count
;	HL		ptr to bytes to read/write
;	carry	must be clear
;
	SKIP_2BYTES_INST_JC					;skip SKIP_XRA_A. Continue at L_LCD_PLOT_WR

	else								;~ (LCDPATCH | BASEPATCH)

    PUSH    H							;save buffer ptr
    MVI     E,06H						;preload byte count for step 1
    LDA     LCTEX_R						;LCD char column (0..39)
    CPI     08H							;8
    JZ      +							;brif 8: E -= 4: write 2 bytes in step 1
    CPI     10H							;16
    JZ      L_LCD_PLOT_1				;brif 16: E -= 2: write 4 bytes in step 1
    CPI     21H							;33
    JNZ     L_LCD_PLOT_2				;brif !33
; LCTEX_R == 33: write 2 bytes in step 1
+	DCR     E							;adjust byte count step 1
    DCR     E							;adjust byte count step 1
L_LCD_PLOT_1:
    DCR     E							;adjust byte count step 1
    DCR     E							;adjust byte count step 1
L_LCD_PLOT_2:
    MOV     C,A							;LCD char column (0..39)
    ADD     C							;times 2
    ADD     C							;3 bytes per column
    MOV     C,A							;zero extend A to BC
    MVI     B,00H
	LDA LCTEY_R							;LCD char row 0..7 00000421
;
; determine LCD bank 0..4 (top) or 5..9 (bottom). Move bits 1,0 to 7,6
;
	RAR									;00000042 1 to carry 
  	RAR									;10000004 2 to carry
   	RAR									;21000000 4 to carry
;
; A has page number (0..3) in bits 6,7
;
    LXI     H,L_LCD_BIT_PATTERNS_2		;Code Based. preload enable bit patterns for bottom LCD drivers
    JC      +							;brif bottom drivers
    LXI     H,R_LCD_BIT_PATTERNS     	;Code Based. enable bit patterns for top LCD drivers
+	DAD     B							;index
    MOV     B,A							;save page number in bits 6,7
    CALL    L_SELECT_LCD_DRIVER			;HL input and updated
    SHLD    PBTABLE_R					;store updated LCD Driver Selection table ptr
    MOV     A,B							;restore page number in bits 6,7
    ORA     M							;merge in column address
    MOV     B,A							;complete driver address in B
    POP     H							;restore HL
    DCR     D							;set Z based on function argument
    CALL    L_LCD_PLOT					;Z is set: Z not set: read
    INR     D							;restore function argument
    MVI     A,06H						;compute number of bytes for step 2
    SUB     E							;number of bytes just written
    RZ									;retif 0: done
    MOV     E,A							;remaining number of bytes to write
    PUSH    H							;save HL
    LHLD    PBTABLE_R					;restore updated LCD Driver Selection table ptr
	INX     H							;skip column address already used
;
; step 2 happens when the 6 bytes data for char generation span
; a driver boundary (just 3 cases, X==8, 16 or 33)
; if we need step 2, the column address within the new driver
; always starts at 0
;
    CALL    L_SELECT_LCD_DRIVER			;HL input
    POP     H							;restore ptr LCD Buffer
    MOV     A,B							;complete driver address
    ANI     0C0H						;isolate bits 6..7
    MOV     B,A							;page number only (column address 0)
    DCR     D							;clear carry for read/write
;
;	FALL THROUGH to step 2: L_LCD_PLOT_WR
;
; IN:
;	B		complete driver address PPAAAAAA
;	E		byte count
;	HL		ptr to bytes to read/write
;	carry	must be clear
;
	SKIP_2BYTES_INST_JC					;skip SKIP_XRA_A. Continue at L_LCD_PLOT_WR
 	endif								;LCDPATCH or BASEPATCH or NO PATCH

L_LCD_PLOT_RD:
	SKIP_XRA_A							;ORI 0AFH. A != 0 means read request
L_LCD_PLOT_WR:
    XRA     A							;A==0 means write request
;
; IN:
;	B		complete driver address
;	E		column count
;	HL		buffer ptr
;	Z		is set: write. not set: read
;
L_LCD_PLOT:

	if		HWSCROLL
;	The value of the B register must be corrected to use the page number
	JMP		correct_b					;preserves flags (Z set means write)
L_LCD_PLOT_7:

	else								;HWSCROLL
    PUSH    D							;save DE
    PUSH    PSW							;save read/write mode
    MOV     A,B							;complete driver address
	endif								;HWSCROLL
; Z flag contains mode
    CALL    R_WAIT_LCD_DRIVER			;Wait for LCD driver to be available. Preserves flags
    OUTPORT	0FEH						;set complete driver address
    JZ      +							;brif Z set (write mode)
    CALL    R_WAIT_LCD_DRIVER			;Wait for LCD driver to be available
    INPORT	0FFH						;read from LCD (Dummy Read)
+	POP     PSW							;restore mode: A==0: write A!=0: read
    JNZ     L_LCD_RD					;brif read
;
; Write E bytes to LCD
;
L_LCD_WR:
	INPORT	0FEH						;Wait for LCD driver to be available: REALM100
    RAL									;status bit 7 to carry
    JC      L_LCD_WR					;brif not available
    MOV     A,M							;send byte at M to LCD
    OUTPORT	0FFH						;auto-updates address
    INX     H							;next
    DCR     E							;byte count
    JNZ     L_LCD_WR					;brif more
    POP     D							;restore DE
    RET
;
; read E bytes from LCD. Model 100 has a map of current LCD characters
; but not of current LCD bits.
;
L_LCD_RD:
    INPORT	0FEH						;Wait for LCD driver to be available: REALM100
    RAL									;status bit 7 to carry
    JC      L_LCD_RD					;brif not available
    INPORT	0FFH						;read from LCD. auto-updates address
    MOV     M,A							;store byte from LCD to M
    INX     H							;next
    DCR     E							;byte count
    JNZ     L_LCD_RD					;brif more
    POP     D							;restore DE
    RET
;
; Set the display top line to zero for all LCD controllers
;
L_CLR_LCD_TOP:

	if		HWSCROLL
;	•	The page setting routine is modified to use the page number
;	•	In addition, this routine is used to set page for the ESC-M and ESC-L routines.
	CALL	set_page					;returns page_loc in A
;L_CLR_LCD_TOP_1:
	ORI		3EH							;set page command
	else
    CALL    L_SELECT_LCD_DRIVER_ALL     ;Enable all LCD drivers after short delay
    MVI     A,3EH						;set page 0 command (page 0 is top page)
	endif

    OUTPORT	0FEH
    RET
;
; Enable all LCD drivers after short delay
;
; OUT:
;	HL		LCD Driver Selection table ptr. Code Based.
;
L_SELECT_LCD_DRIVER_ALL:				;7533H
    MVI     C,03H
    CALL    R_DELAY_FUNC				;Delay routine - decrement C until zero
    LXI     H,L_LCD_SELECT_ALL			;Code Based. Table contains 0FFH, 03H
;
; Select LCD drivers
;
; IN:
;	HL		ptr to 2 byte driver select bit pattern
;
L_SELECT_LCD_DRIVER:
    MOV     A,M
    OUTPORT	0B9H						;select driver chip in 8155 PIO Port A
    INX     H
    INPORT	0BAH						;read 8155 PIO Port B
    ANI     0FCH						;11111100B	Clear bits 0..1
    ORA     M
    OUTPORT	0BAH						;select driver chip in 8155 PIO Port B
    INX     H
    RET
;
; Wait for LCD driver to be available
; REALM100: just return
;
R_WAIT_LCD_DRIVER:						;7548H
    PUSH    PSW
-	INPORT	0FEH
    RAL
    JC      -
    POP     PSW
    RET
;
; 8155 PIO chip bit patterns for LCD drivers
;
	if	LCDPATCH

	if		VT100INROM
	include	"VT100inROM2.asm"
	endif								;!VT100INROM
;
; Insert !REALM100 RST 7 handler here for now
; Reserved for future projects
;
	if REALM100==0
;
;code is 34. bytes longer than REALM100 code, total 68. bytes
;need to try using D to store RST38ARG_R but requires pushing D
; currently gap is only 9 bytes
;
R_RAM_VCTR_TBL_DRIVER:
    XTHL							 	;(HL) points to offset byte
    PUSH    PSW
    MOV     A,M						 	;get offset byte
    STA     RST38ARG_R					;save offset of this RST 38H call
    POP     PSW
    INX     H						 	;(HL) now points to return address
    XTHL							 	;set return address and restore HL
	PUSH    H
    PUSH    B
    PUSH    PSW							;value to output, if any
	LDA		RST38ARG_R					;Restore Offset of this RST 38H call
	CPI		61H							;5 extra bytes here
	JNC		L_IOPORTS
    LXI     H,RST38_R				    ;Start of RST 38H vector table
    MOV     C,A						 	;offset is 2 * index 
    MVI     B,00H
    DAD     B
	GETHLFROMM							;get ptr to HL
    POP     PSW
    POP     B
    XTHL							 	;swap saved HL on stack with jmp vector
R_RET_INSTR:
    RET							 		;to jmp vector
; The code below requires 33 bytes.
L_IOPORTS:
	PUSH	PSW							;save opcode
	ani		0FH							;isolate lower nibble
	jz		L_INPORT					;brif nibble == 0
	cpi		9
	jnc		L_INPORT					;brif nibble >= 9
	pop		PSW							;restore opcode
	adi		47H							;actual port#	
	out		STO_OPCODE
	pop		PSW							;restore value to output
	out		EXC_WR_OPCODE
	jmp		L_IOEXIT
L_INPORT:
	pop		PSW							;restore opcode
	if 0								;TODO
	sbi		08H							;remove IN coding. MERGE
	adi		47H							;restore opcode
	else
	adi		3FH							;-08H + 47H
	endif
	out		STO_OPCODE
	pop		PSW							;stack sync
	in		EXC_WR_OPCODE
L_IOEXIT:
	pop		B							;restore stack
	pop		H
	ret

	else

	DS		9							;9 bytes FREE CODE SPACE if REALM100

	endif								;REALM100

	if		HWSCROLL
	include "HWScroll.asm"
	
	DS	(7641H-75D2H)					;FREE code space if LCDPATCH && HWSCROLL
	endif

;
	elseif BASEPATCH

; 80 bytes table. Use this table in conjunction with L_LCD_DRVS_TOP and L_LCD_DRVS_BOTTOM
R_LCD_BIT_PATTERNS:						;7551H
	DB		00H,00H,00H,06H,00H,0CH,00H,12H
	DB		00H,18H,00H,1EH,00H,24H,00H,2AH
	DB		00H,30H,02H,04H,02H,0AH,02H,10H
	DB		02H,16H,02H,1CH,02H,22H,02H,28H
	DB		02H,2EH,04H,02H,04H,08H,04H,0EH
	DB		04H,14H,04H,1AH,04H,20H,04H,26H
	DB		04H,2CH,06H,00H,06H,06H,06H,0CH
	DB		06H,12H,06H,18H,06H,1EH,06H,24H
	DB		06H,2AH,06H,30H,08H,04H,08H,0AH
	DB		08H,10H,08H,16H,08H,1CH,08H,22H
;
;
; IN:
;	A
;	C		offset
;	HL		LCD Driver Selection table ptr: L_LCD_DRVS_TOP
;	carry	if set, update Driver Selection table
;
; OUT:
;	B		A
;
L_UPD_DRV_SELECT_PTR:
	JNC		+
; TODO location dependency. Can be fixed by using LXI H,L_LCD_DRVS_BOTTOM
; which is 1 byte longer, so effects other code
; incoming HL (always L_LCD_DRVS_TOP) and L_LCD_DRVS_BOTTOM must have same MSB
	MVI		L,L_LCD_DRVS_BOTTOM & 255	;LSB of L_LCD_DRVS_BOTTOM
+	MVI		B,00H						;zero extend C to BC
	DAD		B							;index into table
	MOV		B,A							;save A 
	RET
	
	if		HWSCROLL
	include "HWScroll.asm"
	
; 7603H to 7640H free to use if HWSCROLL
	DS		62							;62 bytes FREE CODE SPACE if REALM100
	
	else			;HWSCROLL
;
; 75ABH to 7640H free to use
;
	DS	(7641H-75ABH)					;150 bytes FREE if !HWSCROLL
	endif								;if	HWSCROLL

	else								;~ (LCDPATCH | BASEPATCH)
	
R_LCD_BIT_PATTERNS:
;
; 120 bytes table: 40 entries of 3 bytes each
; each entry is the start location of a char
; in a line. First 2 bytes select the driver.
; third byte is the offset in driver for that char
;
    DB      01H,00H,00H,01H,00H,06H,01H,00H
    DB      0CH,01H,00H,12H,01H,00H,18H,01H
    DB      00H,1EH,01H,00H,24H,01H,00H,2AH
    DB      01H,00H,30H,02H,00H,04H,02H,00H
    DB      0AH,02H,00H,10H,02H,00H,16H,02H
    DB      00H,1CH,02H,00H,22H,02H,00H,28H
    DB      02H,00H,2EH,04H,00H,02H,04H,00H
    DB      08H,04H,00H,0EH,04H,00H,14H,04H
    DB      00H,1AH,04H,00H,20H,04H,00H,26H
    DB      04H,00H,2CH,08H,00H,00H,08H,00H
    DB      06H,08H,00H,0CH,08H,00H,12H,08H
    DB      00H,18H,08H,00H,1EH,08H,00H,24H
    DB      08H,00H,2AH,08H,00H,30H,10H,00H
    DB      04H,10H,00H,0AH,10H,00H,10H,10H
    DB      00H,16H,10H,00H,1CH,10H,00H,22H

L_LCD_BIT_PATTERNS_2:
;
; 120 bytes table: 40 entries of 3 bytes each
; each entry is the start location of a char
; in a line.
; note that every third byte is identical to table
; R_LCD_BIT_PATTERNS
; note that the first 2 bytes are also available
; in table L_LCD_DRVS_TOP
; BASEPATCH takes advantage of these facts
;
    DB      20H,00H,00H,20H,00H,06H,20H,00H
    DB      0CH,20H,00H,12H,20H,00H,18H,20H
    DB      00H,1EH,20H,00H,24H,20H,00H,2AH
    DB      20H,00H,30H,40H,00H,04H,40H,00H
    DB      0AH,40H,00H,10H,40H,00H,16H,40H
    DB      00H,1CH,40H,00H,22H,40H,00H,28H
    DB      40H,00H,2EH,80H,00H,02H,80H,00H
    DB      08H,80H,00H,0EH,80H,00H,14H,80H
    DB      00H,1AH,80H,00H,20H,80H,00H,26H
    DB      80H,00H,2CH,00H,01H,00H,00H,01H
    DB      06H,00H,01H,0CH,00H,01H,12H,00H
    DB      01H,18H,00H,01H,1EH,00H,01H,24H
    DB      00H,01H,2AH,00H,01H,30H,00H,02H
    DB      04H,00H,02H,0AH,00H,02H,10H,00H
    DB      02H,16H,00H,02H,1CH,00H,02H,22H
	endif								;if LCDPATCH or BASEPATCH or none

L_LCD_SELECT_ALL:						;7641H
    DB      0FFH,03H
;
; 8155 PIO chip bit patterns for LCD drivers
; These are the driver select bit patterns
; for the TOP and BOTTOM banks
; Also used for bit vectors mapping
; Two tables need to stay together
;
L_BIT_VCTRS:
L_LCD_DRVS_TOP:							;7643H
    DB      01H,00H,02H,00H,04H,00H,08H,00H,10H,00H
L_LCD_DRVS_BOTTOM:
    DB      20H,00H,40H,00H,80H,00H,00H,01H,00H,02H
;
; Delay routine - decrement C until zero
;
R_DELAY_FUNC:							;7657H
    DCR     C
    JNZ     R_DELAY_FUNC				;Delay routine - decrement C until zero
    RET
;
; Set interrupt to 1DH
; Disable Background task
;
L_DIS_INT_75_65:						;765CH
    DI 
    MVI     A,1DH						;00011101 SIM mask to disable RST 5.5 & 7.5. Set RST7.5
    SIM    
    EI     
    RET
;
; Beep routine
;
R_BEEP_FUN:								;7662H
    CALL    L_DIS_INT_75_65				;Disable Background task
    MVI     B,00H						;00 equals 256 here
-	CALL    R_SOUND_PORT      		 	;Click sound port
    MVI     C,50H						;80 to C
    CALL    R_DELAY_FUNC				;Delay routine - decrement C until zero
    DCR     B
    JNZ     -
    JMP     L_ENA_INT_75_65				;Enable background tasks
;
; Click sound port
;
R_SOUND_PORT:							;7676H
    INPORT	0BAH						;read 8155 PIO Port B
    XRI     20H							;00100000: Data to beeper if bit 2 set.  Set if bit 2 low
    OUTPORT	0BAH						;set 8155 PIO Port B
    RET

	if	DVIENABLED

R_TESTDVI_FUN:
    LDA     DVIFLG_R					;optional external controller flag
    INR     A							;set flag. If present (0FFH), Z flag set
    RET
;
; Check for optional external controller
;
R_CHK_XTRNL_CNTRLER:				    ;7682H
    LXI     H,DVIFLG_R					;optional external controller flag
    IN      82H
    ANI     07H
    JZ      R_XTRNL_CNTRLER_DRIVER   	;Optional external controller driver
    MVI     M,00H						;clear optional external controller flag
    RET
;
; Optional external controller driver
;
R_XTRNL_CNTRLER_DRIVER:					;768FH
    ORA     M
    RNZ
    MVI     M,0FFH						;set optional external controller flag
L_XTRNL_CNTRLER_INIT:
    MVI     A,0C1H
    OUT     83H
    IN      80H
    MVI     A,04H
    OUT     81H
    OUT     80H
    RET
;
; Send CMD 0 (??) to DVI
;
; OUT:
;	carry		set means no DVI present
;
L_XTRNL_CNTRLER_1:
    CALL    R_TESTDVI_FUN				;test for optional external controller
    STC									;preset Carry
    RNZ									;return if not present
    MVI     A,03H
    STA     DVIBOX_R					;DVI MAILBOX SELECT area
    XRA     A
    CALL    R_DVICMD_FUN				;Send command byte to DVI
    CALL    R_DVIRDY_FUN				;Wait for DVI RX_FULL and read next byte from DVI??
    RLC    								;move bit 7, Carry to bits 1,0
    RLC    
    ANI     03H							;isolate bits 1,0
    RET
;
; Copy initialization code from DVI to E000h and execute
;
; IN:
;	DE		target RAM address (currently ignored)
;
L_XTRNL_CNTRLER_CPY:
    MVI     A,03H
    STA     DVIBOX_R					;DVI MAILBOX SELECT area
    LXI     H,L_DVI_CMD_TBL				;Code Based. Load address of Byte sequence to sent to DVI (2, 1, 0, 0, 1)
    MVI     B,05H						;send 5 command bytes
-	MOV     A,M							;Get next DVI command byte
    CALL    R_DVICMD_FUN				;Send command byte to DVI
    INX     H
    DCR     B
    JNZ     -
;
; B is now 0/256
;
    CALL    R_DVIRDY_FUN				;Wait for DVI RX_FULL and read next byte from DVI
    ORA     A
    STC									;preset carry return value
    RNZ									;Return if the response is not zero
    LXI     H,0E000H					;destination RAM location
-	CALL    R_DVIRDY_FUN				;Wait for DVI RX_FULL and read next byte from DVI
    MOV     M,A							;store result in 0E000H..0E0FFH
    INX     H
    DCR     B							;max 256 bytes
    JNZ     -
    JMP     0E000H						;execute initialization code
;
; Send command byte to DVI
;
R_DVICMD_FUN:
    PUSH    PSW
-	CALL    R_CHK_SHIFT_BREAK			;Check if SHIFT-BREAK is being pressed
    JC      L_XTRNL_CNTRLER_BRK			;brif pressed
    IN      82H
    RLC									;Rotate DVI TX EMPTY bit (MSB) into Carry
    JNC     -							;brif not empty
    LDA     DVIBOX_R					;DVI MAILBOX SELECT area
    OUT     81H
    POP     PSW
    OUT     80H
    RET
;
; SHIFT-BREAK Exit handler for DVI Read/Write loops
;
L_XTRNL_CNTRLER_BRK:
    POP     PSW							;remove pushed PSW from R_DVICMD_FUN
L_XTRNL_CNTRLER_BRK_1:
    POP     PSW							;remove previous function return address
    CALL    L_XTRNL_CNTRLER_INIT		;Re-initialize the DVI
    STC									;Indicate SHIFT-BREAK pressed
    RET
;
; Wait for DVI RX_FULL and read next byte from DVI
;
R_DVIRDY_FUN:
    CALL    R_CHK_SHIFT_BREAK			;Check if SHIFT-BREAK is being pressed
    JC      L_XTRNL_CNTRLER_BRK_1		;brif pressed
    IN      82H
    ANI     20H							;isolate bit 5
    JZ      R_DVIRDY_FUN				;loop
    IN      80H
    RET
;
; DVI command table - sent to external DVI
;
L_DVI_CMD_TBL:
    DB      02H,01H,00H,00H,01H,00H

	else								;DVIENABLED
	
R_CHK_XTRNL_CNTRLER:
	XRA		A							;clear
;	STA		DVIFLG_R					;optional external controller flag
	RET

L_XTRNL_CNTRLER_1:
    STC									;preset Carry
    RET									;return not present

L_XTRNL_CNTRLER_CPY:
    STC
    RET									;return not present

	rept 134							;134 FREE CODE SPACE if !DVIENABLED
	NOP
	endm
	
	endif								;DVIENABLED
;
; LCD char generator shape table (20H-7FH)
; each character is represented by 5 bytes
; 96 * 5 = 480 bytes
;
R_LCD_CHAR_SHAPE_TBL1:				     	;7711H
    DB      00H,00H,00H,00H,00H,00H,00H,4FH
    DB      00H,00H,00H,07H,00H,07H,00H,14H
    DB      7FH,14H,7FH,14H,24H,2AH,7FH,2AH
    DB      12H,23H,13H,08H,64H,62H,3AH,45H
    DB      4AH,30H,28H,00H,04H,02H,01H,00H
    DB      00H,1CH,22H,41H,00H,00H,41H,22H
    DB      1CH,00H,22H,14H,7FH,14H,22H,08H
    DB      08H,3EH,08H,08H,00H,80H,60H,00H
    DB      00H,08H,08H,08H,08H,08H,00H,60H
    DB      60H,00H,00H,40H,20H,10H,08H,04H
    DB      3EH,51H,49H,45H,3EH,44H,42H,7FH
    DB      40H,40H,62H,51H,51H,49H,46H,22H
    DB      41H,49H,49H,36H,18H,14H,12H,7FH
    DB      10H,47H,45H,45H,29H,11H,3CH,4AH
    DB      49H,49H,30H,03H,01H,79H,05H,03H
    DB      36H,49H,49H,49H,36H,06H,49H,49H
    DB      29H,1EH,00H,00H,24H,00H,00H,00H
    DB      80H,64H,00H,00H,08H,1CH,36H,63H
    DB      41H,14H,14H,14H,14H,14H,41H,63H
    DB      36H,1CH,08H,02H,01H,51H,09H,06H
    DB      32H,49H,79H,41H,3EH,7CH,12H,11H
    DB      12H,7CH,41H,7FH,49H,49H,36H,1CH
    DB      22H,41H,41H,22H,41H,7FH,41H,22H
    DB      1CH,7FH,49H,49H,49H,41H,7FH,09H
    DB      09H,09H,01H,3EH,41H,49H,49H,3AH
    DB      7FH,08H,08H,08H,7FH,00H,41H,7FH
    DB      41H,00H,30H,40H,41H,3FH,01H,7FH
    DB      08H,14H,22H,41H,7FH,40H,40H,40H
    DB      40H,7FH,02H,0CH,02H,7FH,7FH,06H
    DB      08H,30H,7FH,3EH,41H,41H,41H,3EH
    DB      7FH,09H,09H,09H,06H,3EH,41H,51H
    DB      21H,5EH,7FH,09H,19H,29H,46H,26H
    DB      49H,49H,49H,32H,01H,01H,7FH,01H
    DB      01H,3FH,40H,40H,40H,3FH,0FH,30H
    DB      40H,30H,0FH,7FH,20H,18H,20H,7FH
    DB      63H,14H,08H,14H,63H,07H,08H,78H
    DB      08H,07H,61H,51H,49H,45H,43H,00H
    DB      7FH,41H,41H,00H,04H,08H,10H,20H
    DB      40H,00H,41H,41H,7FH,00H,04H,02H
    DB      01H,02H,04H,40H,40H,40H,40H,40H
    DB      00H,01H,02H,04H,00H,20H,54H,54H
    DB      54H,78H,7FH,28H,44H,44H,38H,38H
    DB      44H,44H,44H,28H,38H,44H,44H,28H
    DB      7FH,38H,54H,54H,54H,18H,08H,08H
    DB      7EH,09H,0AH,18H,0A4H,0A4H,98H,7CH
    DB      7FH,04H,04H,04H,78H,00H,44H,7DH
    DB      40H,00H,40H,80H,84H,7DH,00H,00H
    DB      7FH,10H,28H,44H,00H,41H,7FH,40H
    DB      00H,7CH,04H,78H,04H,78H,7CH,08H
    DB      04H,04H,78H,38H,44H,44H,44H,38H
    DB      0FCH,18H,24H,24H,18H,18H,24H,24H
    DB      18H,0FCH,7CH,08H,04H,04H,08H,58H
    DB      54H,54H,54H,24H,04H,3FH,44H,44H
    DB      20H,3CH,40H,40H,3CH,40H,1CH,20H
    DB      40H,20H,1CH,3CH,40H,38H,40H,3CH
    DB      44H,28H,10H,28H,44H,1CH,0A0H,0A0H
    DB      90H,7CH,44H,64H,54H,4CH,44H,00H
    DB      08H,36H,41H,41H,00H,00H,77H,00H
    DB      00H,41H,41H,36H,08H,00H,02H,01H
    DB      02H,04H,02H,00H,00H,00H,00H,00H

;
; LCD char generator shape table (80H-FFH)
; each char >= 080H is 6 bytes => 128 * 6 = 768 bytes
;
R_LCD_CHAR_SHAPE_TBL2:				     	;78F1H
    DB      66H,77H,49H,49H,77H,66H,0FCH,86H
    DB      0D7H,0EEH,0FCH,00H,7FH,63H,14H,08H
    DB      14H,00H,78H,76H,62H,4AH,0EH,00H
    DB      0EEH,44H,0FFH,0FFH,44H,0EEH,0CH,4CH
    DB      7FH,4CH,0CH,00H,7CH,56H,7FH,56H
    DB      7CH,00H,7DH,77H,47H,77H,7FH,00H
    DB      00H,00H,7DH,00H,00H,00H,10H,20H
    DB      1CH,02H,02H,02H,54H,34H,1CH,16H
    DB      15H,00H,41H,63H,55H,49H,63H,00H
    DB      24H,12H,12H,24H,12H,00H,44H,44H
    DB      5FH,44H,44H,00H,00H,40H,3EH,01H
    DB      00H,00H,00H,08H,1CH,3EH,00H,00H
    DB      98H,0F4H,12H,12H,0F4H,98H,0F8H,94H
    DB      12H,12H,94H,0F8H,14H,22H,7FH,22H
    DB      14H,00H,0A0H,56H,3DH,56H,0A0H,00H
    DB      4CH,2AH,1DH,2AH,48H,00H,38H,28H
    DB      39H,05H,03H,0FH,00H,16H,3DH,16H
    DB      00H,00H,42H,25H,15H,28H,54H,22H
    DB      04H,02H,3FH,02H,04H,00H,10H,20H
    DB      7EH,20H,10H,00H,08H,08H,2AH,1CH
    DB      08H,00H,08H,1CH,2AH,08H,08H,00H
    DB      1CH,57H,61H,57H,1CH,00H,08H,14H
    DB      22H,14H,08H,00H,1EH,22H,44H,22H
    DB      1EH,00H,1CH,12H,71H,12H,1CH,00H
    DB      00H,04H,02H,01H,00H,00H,20H,55H
    DB      56H,54H,78H,00H,0EH,51H,31H,11H
    DB      0AH,00H,64H,7FH,45H,45H,20H,00H
    DB      00H,01H,02H,04H,00H,00H,7FH,10H
    DB      10H,0FH,10H,00H,00H,02H,05H,02H
    DB      00H,00H,04H,0CH,1CH,0CH,04H,00H
    DB      00H,04H,7FH,04H,00H,00H,18H,0A7H
    DB      0A5H,0E5H,18H,00H,7FH,41H,65H,51H
    DB      7FH,00H,7FH,41H,5DH,49H,7FH,00H
    DB      17H,08H,34H,22H,71H,00H,55H,3FH
    DB      10H,68H,44H,0E2H,17H,08H,04H,6AH
    DB      59H,00H,06H,09H,7FH,01H,7FH,01H
    DB      29H,2AH,7CH,2AH,29H,00H,70H,29H
    DB      24H,29H,70H,00H,38H,45H,44H,45H
    DB      38H,00H,3CH,41H,40H,41H,3CH,00H
    DB      1CH,22H,7FH,22H,14H,00H,08H,04H
    DB      04H,08H,04H,00H,20H,55H,54H,55H
    DB      78H,00H,30H,4AH,48H,4AH,30H,00H
    DB      3CH,41H,40H,21H,7CH,00H,40H,7FH
    DB      49H,49H,3EH,00H,71H,11H,67H,11H
    DB      71H,00H,38H,54H,56H,55H,18H,00H
    DB      3CH,41H,42H,20H,7CH,00H,38H,55H
    DB      56H,54H,18H,00H,00H,04H,00H,04H
    DB      00H,00H,48H,7EH,49H,01H,02H,00H
    DB      40H,0AAH,0A9H,0AAH,0F0H,00H,70H,0AAH
    DB      0A9H,0AAH,30H,00H,00H,02H,0E9H,02H
    DB      00H,00H,30H,4AH,49H,4AH,30H,00H
    DB      38H,42H,41H,22H,78H,00H,08H,04H
    DB      02H,04H,08H,00H,38H,55H,54H,55H
    DB      18H,00H,00H,02H,68H,02H,00H,00H
    DB      20H,54H,56H,55H,7CH,00H,00H,00H
    DB      6AH,01H,00H,00H,30H,48H,4AH,49H
    DB      30H,00H,3CH,40H,42H,21H,7CH,00H
    DB      0CH,50H,52H,51H,3CH,00H,7AH,11H
    DB      09H,0AH,71H,00H,42H,0A9H,0A9H,0AAH
    DB      0F1H,00H,32H,49H,49H,4AH,31H,00H
    DB      0E0H,52H,49H,52H,0E0H,00H,0F8H,0AAH
    DB      0A9H,0AAH,88H,00H,00H,8AH,0F9H,8AH
    DB      00H,00H,70H,8AH,89H,8AH,70H,00H
    DB      78H,82H,81H,82H,78H,00H,00H,45H
    DB      7CH,45H,00H,00H,7CH,55H,54H,55H
    DB      44H,00H,7CH,54H,56H,55H,44H,00H
    DB      0E0H,50H,4AH,51H,0E0H,00H,00H,88H
    DB      0FAH,89H,00H,00H,70H,88H,8AH,89H
    DB      70H,00H,3CH,40H,42H,41H,3CH,00H
    DB      0CH,10H,62H,11H,0CH,00H,3CH,41H
    DB      42H,40H,3CH,00H,7CH,55H,56H,54H
    DB      44H,00H,0E0H,51H,4AH,50H,0E0H,00H
    DB      00H,00H,00H,00H,00H,00H,0FH,0FH
    DB      0FH,00H,00H,00H,00H,00H,00H,0FH
    DB      0FH,0FH,0F0H,0F0H,0F0H,00H,00H,00H
    DB      00H,00H,00H,0F0H,0F0H,0F0H,0FH,0FH
    DB      0FH,0F0H,0F0H,0F0H,0F0H,0F0H,0F0H,0FH
    DB      0FH,0FH,0FH,0FH,0FH,0FH,0FH,0FH
    DB      0F0H,0F0H,0F0H,0F0H,0F0H,0F0H,0FFH,0FFH
    DB      0FFH,00H,00H,00H,00H,00H,00H,0FFH
    DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FH,0FH,0FH
    DB      0FH,0FH,0FH,0FFH,0FFH,0FFH,0FFH,0FFH
    DB      0FFH,0F0H,0F0H,0F0H,0F0H,0F0H,0F0H,0FFH
    DB      0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH
    DB      00H,00H,0F8H,08H,08H,08H,08H,08H
    DB      08H,08H,08H,08H,08H,08H,0F8H,00H
    DB      00H,00H,08H,08H,0F8H,08H,08H,08H
    DB      00H,00H,0FFH,08H,08H,08H,00H,00H
    DB      0FFH,00H,00H,00H,00H,00H,0FH,08H
    DB      08H,08H,08H,08H,0FH,00H,00H,00H
    DB      08H,08H,0FH,08H,08H,08H,08H,08H
    DB      0FFH,00H,00H,00H,08H,08H,0FFH,08H
    DB      08H,08H,3FH,1FH,0FH,07H,03H,01H
    DB      80H,0C0H,0E0H,0F0H,0F8H,0FCH,01H,03H
    DB      07H,0FH,1FH,3FH,0FCH,0F8H,0F0H,0E0H
    DB      0C0H,80H,55H,0AAH,55H,0AAH,55H,0AAH

;
; Keyboard conversion matrix
;
; Code currently assumes some of these tables are somewhat close together
; meaning their distance is <= 255 bytes.
;
R_KEYBOARD_CONV_MATRIX:				    	;7BF1H
    DB      7AH,78H,63H,76H,62H,6EH,6DH,6CH		;"zxcvbnml" column 1 from left
    DB      61H,73H,64H,66H,67H,68H,6AH,6BH		;"asdfghjk" column 2 from left
    DB      71H,77H,65H,72H,74H,79H,75H,69H		;"qwertyui" column 3 from left 
    DB      6FH,70H,5BH,3BH,27H,2CH,2EH,2FH		;"op[;',./" column 4 from left
    DB      31H,32H,33H,34H,35H,36H,37H,38H		;"12345678" column 5 from left
    DB      39H,30H,2DH,3DH						;"90-=" column 6 from left

R_KEYBOARD_CONV_SHIFTED:
    DB      5AH,58H,43H,56H,42H,4EH,4DH,4CH		;"ZXCVBNML" column 1 from left
    DB      41H,53H,44H,46H,47H,48H,4AH,4BH		;"ASDFGHJK" column 2 from left
    DB      51H,57H,45H,52H,54H,59H,55H,49H		;"QWERTYUI" column 3 from left
    DB      4FH,50H,5DH,3AH,22H,3CH,3EH,3FH		;"OP]:\"<>?" column 4 from left
    DB      21H,40H,23H,24H,25H,5EH,26H,2AH		;"!@#$%^&*" column 5 from left
    DB      28H,29H,5FH,2BH						;"()_+" column 6 from left

L_KEYBOARD_1:
    DB      00H,83H,84H,00H,95H,96H,81H,9AH
    DB      85H,8BH,00H,82H,00H,86H,00H,9BH
    DB      93H,94H,8FH,89H,87H,90H,91H,8EH
    DB      98H,80H,60H,92H,8CH,99H,97H,8AH
    DB      88H,9CH,9DH,9EH,9FH,0B4H,0B0H,0A3H
    DB      7BH,7DH,5CH,8DH,0E0H,0EFH,0FFH,00H
    DB      00H,00H,0F6H,0F9H,0EBH,0ECH,0EDH,0EEH
    DB      0FDH,0FBH,0F4H,0FAH,0E7H,0E8H,0E9H,0EAH
    DB      0FCH,0FEH,0F0H,0F3H,0F2H,0F1H,7EH,0F5H
    DB      00H,0F8H,0F7H,00H,0E1H,0E2H,0E3H,0E4H
    DB      0E5H,0E6H,00H,00H,00H,00H,7CH,00H

L_KEYBOARD_2:
    DB      0CEH,0A1H,0A2H,0BDH,00H,0CDH,00H,0CAH
    DB      0B6H,0A9H,0BBH,00H,00H,00H,0CBH,0C9H
    DB      0C8H,00H,0C6H,00H,00H,0CCH,0B8H,0C7H
    DB      0B7H,0ACH,0B5H,0ADH,0A0H,0BCH,0CFH,0AEH
    DB      0C0H,00H,0C1H,00H,00H,00H,0C4H,0C2H
    DB      0C3H,0AFH,0C5H,0BEH,00H,0DFH,0ABH,0DEH
    DB      00H,00H,0A5H,0DAH,0B1H,0B9H,0D7H,0BFH
    DB      00H,00H

L_KEYBOARD_3:
    DB      0DBH,0D9H,0D8H,00H,0D6H,0AAH,0BAH,0DCH
    DB      0B3H,0D5H,0B2H,00H,00H,00H,0A4H,0DDH
    DB      00H,00H,0D0H,00H

L_KEYBOARD_4:
    DB      0D1H,00H,00H,00H,0D4H,0D2H,0D3H,0A6H
    DB      0A7H,0A8H

R_KEYBOARD_NUM:
    DB      6DH,30H,6AH,31H,6BH,32H,6CH,33H			;DB "m0j1k2l3"
    DB      75H,34H,69H,35H,6FH,36H,01H,06H			;DB "u4i5o6",01H,06H
    DB      14H,02H,20H,7FH,09H,1BH,8BH,88H
    DB      8AH,0DH,80H,81H,82H,83H,84H,85H
    DB      86H,87H,1DH,1CH,1EH,1FH,20H,08H
    DB      09H,1BH,8BH,88H,89H,0DH,80H,81H
    DB      82H,83H,84H,85H,86H,87H

L_KEYBOARD_5:
    DB      51H,52H,57H,5AH				;"QRWZ"

;
; Boot routine
;
R_BOOT_ROUTINE:							;7D33H
    DI 
    LXI     SP,BOOTSTK_R+18H			;Stack area while booting
    LXI     H,10000						;delay count
-	DCX     H
    MOV     A,H
    ORA     L
    JNZ     -
    MVI     A,43H						;Load configuration for PIO (A=OUT, B=OUT, C=IN, Stop Timer counter)
    OUTPORT	0B8H						;PIO Command/Status Register: set PIO chip configuration
    MVI     A,0ECH						;PIO B configuration (RTS low, DTR low, SPKR=1, Serial=Modem, Keyscan col 9 enable)
    OUTPORT	0BAH						;Set PIO chip port B configuration
    MVI     A,0FFH						;PIO A configuration (Used for Key scan, LCD data, etc.)
    OUTPORT	0B9H						;Initialize PIO chip port A
    INPORT	0E8H						;Scan Keyboard to test for CTRL-BREAK (cold boot indicator)
    ANI     82H							;Mask all but CTRL-BREAK keys
    MVI     A,0EDH						;Load code to disable key-scan col 9 (for CTRL-BREAK)
    OUTPORT	0BAH						;Disable key-scan col 9
    JZ      R_COLD_BOOT					;Cold boot routine if CTRL-BREAK pressed
    LHLD    SYSRAM_R   					;Active system signature -- Warm vs Cold boot
    LXI     D,BOOTMARKER				;Compare value to test if cold boot needed
    COMPAR	         					;HL - DE
    JNZ     R_COLD_BOOT					;Cold boot routine
    LDA     LOMEM_R+1					;Load MSB of lowest known RAM address to D
    MOV     D,A
    CALL    R_CALC_FREE_RAM				;Calculate physical RAM available
    CMP     D							;RAM change?
    JNZ     R_COLD_BOOT					;Cold boot routine

	if OPTROM							;Option ROM
    CALL    ROMTST_R					;Call RAM routine to Detect Option ROM (copied to RAM by cold-boot)
    MVI     A,00H						;preserve flags. Indicate no Option ROM detected
    JNZ     +							;brif no Option ROM detected
    DCR     A							;now 0FFH. Indicate OptROM detected
+	LXI     H,ROMFLG_R  				;Option ROM flag
    CMP     M							;Test if option ROM added or removed
    JNZ     R_COLD_BOOT					;Cold boot routine
	else								;!OPTROM
	JMP		+
	DS		13							;13 bytes FREE if !OPTROM
	endif								;OPTROM
	
+	LHLD    AUTPWR_R					;Get Auto PowerDown signature
    XCHG								;to DE
    LXI     H,0							;Prepare to clear signature for Auto Poweroff
    SHLD    AUTPWR_R					;Clear signature for Auto Poweroff
    LXI     H,AUTOPWRDWN				;Auto PowerDown signature
    COMPAR	         					;Compare DE and HL. Test if last power off was Auto Poweroff: HL - DE
    JNZ     L_NOT_AUTOPWR				;brif !Auto PowerDown
;
; reboot after auto power down
;
    LHLD    POWRSP_R    				;SP save area for power up/down
    SPHL
    CALL    BOOTHK_R					;Call Boot-up Hook
L_PWR_DOWN_BOOT:						;used by vt100
    CALL    L_BOOT_2					;tricked out target
    LHLD    SAVEDSP_R
    PUSH    H
    CALL    L_LCDrefresh
    POP     H
L_PWR_DOWN_BOOT2:						;used by vt100
    MOV     A,H
    ANA     A							;test
    JZ      R_POP_ALL_REGS				;Pop AF), BC), DE), HL from stack
    SPHL
    JMP     L_CHAR_PLOT_EXIT
;
; not Auto PowerDown restart
;
L_NOT_AUTOPWR:
	LDA     EDITFLG_R
    ANA     A
    JZ      +
    CALL    L_BOOT_2					;tricket out target
    CALL    L_RESET_SP_0				;Stop BASIC, Restore BASIC SP
    CALL    L_LCDrefresh
    JMP     R_TEXT_EDIT_LOOP        	;Main TEXT edit loop
;
; not in Edit Mode
;
+	LXI     H,IPLNAM_R  				;Start of IPL filename
    SHLD    FNKMAC_R					;Get pointer to FKey text (from FKey table) for selected FKey
    LHLD    STRBUF_R    				;BASIC string buffer pointer
    SPHL
    CALL    BOOTHK_R					;normally just returns unless VT100
    CALL    L_INIT_BASIC				;Initialize BASIC for new execution
    LXI     H,R_MENU_ENTRY
    PUSH    H
	SKIP_XRA_A							;ORI 0AFH. Sets A
L_BOOT_2:								;A == 0 entry
    XRA     A
    CALL    R_WARM_RESET				;Warm start reset entry
    XRA     A							;clear A
    STA     PWROFF_R   					;Power off exit condition switch
    LDA     SERINIT_R    				;RS232 initialization status
    ANA     A							;test
    RZ									;retif SERINIT_R == 0
    LXI     H,SERMOD_R-1				;Serial initialization string-1
    CHRGET	         					;Get next non-white char from M
    CNC     L_INCHL						;Increment HL
    JMP     R_SET_RS232_PARAMS      	;Set RS232 parameters from string at M
;
; Cold boot routine
;
R_COLD_BOOT:							;7DE7H
    LXI     SP,SYSSTK_R
    CALL    R_CALC_FREE_RAM				;Calculate physical RAM available
    MVI     B,R_FUN_INIT_IMAGE_END-R_FUN_INIT_IMAGE	;90H
    LXI     D,SYSRAM_R					;Active system signature -- Warm vs Cold boot
    LXI     H,R_FUN_INIT_IMAGE			;Code Based.
    CALL    R_MOVE_B_BYTES 				;Move B bytes from M to (DE)
    CALL    R_INIT_RST_38H_TBL       	;Initialize RST 38H RAM vector table

	if	VT100INROM
	LXI		H,640CH						;H==100, L==12
	SHLD	TIMCN2_R					;initializes both TIMCN2_R and PWRCNT_R
	CALL	L_VT100_HOOK_INIT
	NOP
	else								;!VT100INROM
    MVI     A,12						;0CH
    STA     TIMCN2_R
    MVI     A,100						;64H
    STA     PWRCNT_R
	endif								;VT100INROM

    LXI     H,R_BASIC_FKEYS_TBL			;Code Based.
    CALL    R_SET_FKEYS    				;Set new function key table
    CALL    R_SET_BASIC_FKEYS       	;Copy BASIC Function key table to key definition area
    MVI     B,8*RAMDIRLEN				;58H/88
    LXI     D,R_ROM_CAT_ENTRIES      	;Code Based. ROM programs directory entries
    LXI     H,RAMDIR_R  				;Start of RAM directory
    CALL    R_MOVE_B_BYTES_INC       	;Move B bytes from (DE) to M with increment
    MVI     B,(RAMDIRCNT-8)*RAMDIRLEN	;0D1H/209
    XRA     A
-	MOV     M,A							;clear remainder of RAMDIR_R
    INX     H
    DCR     B
    JNZ		-
    MVI     M,0FFH						;end of directory marker

	if OPTROM							;Tandy supplied Option ROM
    CALL    ROMTST_R					;Call RAM routine to Detect Option ROM (copied to RAM by cold-boot)
    JNZ     +
    DCR     A							;set A to 0FFH
    STA     ROMFLG_R         			;Option ROM flag
    LXI     H,USRRAM_R					;RAMDIR_R+58H		0F9BAH
    MVI     M,0F0H						;type 11110000B
    INX     H
    INX     H
    INX     H							;to F9BDH
    LXI     D,ROMSW_R+2
    MVI     B,06H
    CALL    R_MOVE_B_BYTES_INC			;Move B bytes from (DE) to M with increment
    MVI     M,' '
    INX     H
    MVI     M,00H
	else
	JMP		+
	DS		28							;28 bytes FREE if !OPTROM
	endif

+	XRA     A
    STA     UNUSED4_R					;TODO only use
    STA     OPNFIL_R
    CALL    R_ERASE_IPL_PRGM			;Erase current IPL program. returns 0 in A
    STA     PWRDWN_R					;clear Power Down Flag
    MVI     A,3AH						;':'
    STA     EOSMRK_R					;End of statement marker == ':'
    LXI     H,UNUSED7_R
    SHLD    PRMPRV_R
    SHLD    STRBUF_R				    ;BASIC string buffer pointer
    SHLD    MEMSIZ_R					;File buffer area pointer. Also end of Strings Buffer Area.
    MVI     A,01H
    STA     VARTAB_R+1					;0FBB3H
    CALL    L_UPD_FILEBUFS
    CALL    L_INIT_BASIC				;Initialize BASIC for new execution
    LHLD    LOMEM_R						;Lowest RAM address used by system
    XRA     A
    MOV     M,A
    INX     H
    SHLD    TXTTAB_R					;Start of BASIC program pointer
    SHLD    SUZUKI_R+1					;BASIC program not saved pointer
    MOV     M,A							;enter double 0
    INX     H
    MOV     M,A
    INX     H
    SHLD    DOSTRT_R					;DO files pointer
    SHLD    HAYASHI_R+1					;Start of Paste Buffer
    MVI     M,1AH						;enter ^Z
    INX     H
    SHLD    COSTRT_R					;CO files pointer
    SHLD    VARTAB_R					;Start of variable data pointer
    LXI     H,SUZUKI_R					;Suzuki Directory Entry
    SHLD    RAMDIRPTR_R
    CALL    SCRTCH						;NEW()
    CALL    R_RE_INIT_SYSTEM			;Re-initialize system without destroying files
L_RESET_TIME:
    LXI     H,0
    SHLD    TIMYR1_R					;Year (ones)
    LXI     H,R_INIT_CLK_CHIP_REGS		;Code Based. Initial clock chip register values
    CALL    R_PUT_CLK_CHIP_REGS			;Update clock chip regs from M
    JMP     R_MENU_ENTRY				;MENU Program
;
; Display TRS-80 Model number & Free bytes on LCD
;
R_DISP_MODEL:							;7EA6H
    LXI     H,L_MENU_LOGO				;Code Based. TRS-80 model number string
    CALL    R_PRINT_STRING				;Print buffer at M until NULL or '"'
;
; Display number of free bytes on LCD
;
R_DISP_FREE_BYTES:						;7EACH
    LHLD    VARTAB_R					;Start of variable data pointer
    XCHG
    LHLD    STRBUF_R					;BASIC string buffer pointer
    MOV     A,L							;HL -= DE
    SUB     E
    MOV     L,A
    MOV     A,H
    SBB     D
    MOV     H,A
    LXI     B,-14						;0FFF2H
    DAD     B
    CALL    R_PRINT_HL_ON_LCD			;Print binary number in HL at current position
    LXI     H,R_MENU_TEXT_STRINGS		;Code Based. MENU Text Strings
    JMP     R_PRINT_STRING				;Print buffer at M until NULL or '"'
;
; Initialize RST 38H RAM vector table
; First 29 entries will point to R_RET_INSTR,
; next 19 entries will points to R_GEN_FC_ERROR
; total 29+19=48 entries; max offset in table 2 * 48 = 96 (60H)
;
R_INIT_RST_38H_TBL:						;7EC6H
    LXI     H,RST38_R				    ;Start of RST 38H vector table
    LXI     B,1D02H					 	;B = 1DH, C = 02H
    LXI     D,R_RET_INSTR				;Code Based
-	MOV     M,E
    INX     H
    MOV     M,D
    INX     H
    DCR     B
    JNZ     -
    MVI     B,13H						;second part
    LXI     D,R_GEN_FC_ERROR			;Code Based
    DCR     C
    JNZ     -
    RET
;
; Calculate physical RAM available
; RAM always available at 0E000H (8K) so test 0C000H, 0A000H and 8000H
; Only test first 256 bytes of each bank
;
R_CALC_FREE_RAM:						;7EE1H
    LXI     H,0C000H					;start at 0C000H, first optional RAM
-	MOV     A,M							;read memory
    CMA
    MOV     M,A							;update memory
    CMP     M							;did it change
    CMA									;restore original value
    MOV     M,A							;restore memory
    MOV     A,H							;page #
    JNZ     +							;brif memory unchanged
    INR     L							;next byte
    JNZ     -							;brif !end of page
    SUI     20H							;update page # to next RAM chip
    MOV     H,A
    JM      -							;brif H >= 80H
+	MVI     L,00H
    ADI		20H							;undo last page update
    MOV     H,A
    SHLD    LOMEM_R						;Lowest RAM address available to system
    RET
;
; Initial clock chip register values
;
R_INIT_CLK_CHIP_REGS:				    ;7F01H
    DB      00H,00H,00H,00H,00H,00H,01H,00H,00H,01H
;
; MAXFILES function
;
R_MAX_FUN2:								;7F0BH
	SYNCHK	_FILES						;9DH	FILES token
	SYNCHK	_EQUAL_						;'=' token
    CALL    L_GETBYT					;Evaluate byte expression at M-1
    JNZ     R_GEN_SN_ERROR				;Generate Syntax error
    CPI     16							;MAXFILES == 15
    JNC     R_GEN_FC_ERROR				;if A >= 10H Generate FC error
    SHLD    LSTVAR_R					;Address of last variable assigned
    PUSH    PSW							;save new MAXFILES value
    CALL    R_CLSALL					;Close Files
    POP     PSW							;restore new MAXFILES value
    CALL    L_UPD_FILEBUFS
    CALL    R_INIT_BASIC_VARS_3
    JMP     L_NEWSTT					;Execute BASIC program
;
; A == new MAXFILES value
; Compute new MEMSIZ_R. Every file needs 9 + 256 = 267 bytes (114H)
;
L_UPD_FILEBUFS:
    PUSH    PSW							;save new MAXFILES value
    LHLD    HIMEM_R						;HIMEM
    LXI     D,0FEF5H					;-267
; loop new MAXFILES times
-	DAD     D							;subtract 267 from HIMEM
    DCR     A							;MAXFILES cnt
    JP      -							;Loop while A >= 0
    XCHG								;new File Buffer Area Start Address to DE
    LHLD    STRBUF_R					;BASIC string buffer pointer
    MOV     B,H							;BC = HL
    MOV     C,L
    LHLD    MEMSIZ_R					;File buffer area pointer. Also end of Strings Buffer Area.
; compute size of String Buffer Area.
    MOV     A,L							;HL = [MEMSIZ_R] - [STRBUF_R]
    SUB     C
    MOV     L,A
    MOV     A,H
    SBB     B
    MOV     H,A
    POP     PSW							;restore new MAXFILES value
    PUSH    H							;save size of String Buffer Area
    PUSH    PSW							;save new MAXFILES value
    LXI     B,008CH						;140
    DAD     B							;BC = size of String Buffer Area + 140
    MOV     B,H
    MOV     C,L
    LHLD    VARTAB_R					;Start of variable data
    DAD     B							;HL = [VARTAB_R] + size of String Buffer Area + 140
    COMPAR								;HL - new File Buffer Area Start Address
    JNC     L_OUTOFMEMORY				;brif [VARTAB_R] + size of String Buffer Area + 140 >=  new File Buffer Area Start Address
    POP     PSW							;restore new MAXFILES value
    STA     MAXFILES_R					;update Maxfiles
    MOV     L,E							;HL = new File Buffer Area Start Address
    MOV     H,D
    SHLD    FCBTBL_R					;File number description table pointer
    DCX     H
    DCX     H
    SHLD    MEMSIZ_R					;File buffer area pointer
    POP     B							;restore size of String Buffer Area
    MOV     A,L							;compute start of String Buffer Area
    SUB     C
    MOV     L,A
    MOV     A,H
    SBB     B
    MOV     H,A
    SHLD    STRBUF_R					;BASIC string buffer area pointer
    DCX     H							;decreement by 2
    DCX     H
    POP     B							;pop return address
    SPHL								;set new stack area
    PUSH    B							;push return address
    LDA     MAXFILES_R					;Maxfiles
    MOV     L,A
    INR     L							;Maxfiles+1
    MVI     H,00H						;zero extend to HL
    DAD     H							;double
    DAD     D							;DE = [FCBTBL_R] + 2 * (Maxfiles + 1): ptr to first FCB
    XCHG								;HL now [FCBTBL_R]
    PUSH    D							;save ptr to first FCB
    LXI     B,0109H						;265
;
; populate FCB table. [MAXFILES_R] + 1 entries
;
-	MOV     M,E							;[HL] = DE
    INX     H
    MOV     M,D
    INX     H
    XCHG								;FCB address to HL
	MVI     M,00H						;init FCB
    DAD     B							;add 265
    XCHG								;DE is ptr to next FCB
    DCR     A							;Maxfiles counter
    JP      -							;loop
    POP     H							;restore ptr to first FCB
    LXI     B,0009H						;add 9
    DAD     B
    SHLD    FCB1_BUF_R					;ptr to buffer first file
    RET
;
; MENU Text Strings
;
R_MENU_TEXT_STRINGS:				  	;7F98H
    DB      " Bytes free",00H

L_MENU_LOGO:
    DB      "TRS-80 Model 100 Software",0DH,0AH
    DB      "Copr. 1983 Microsoft",0DH,0AH,00H
;
; RST 38H RAM vector driver routine
;
	if REALM100
R_RAM_VCTR_TBL_DRIVER:					;07FD6H
    XTHL							 	;(HL) points to offset byte
    PUSH    PSW
    MOV     A,M						 	;get offset byte
    STA     RST38ARG_R					;save offset of this RST 38H call
    POP     PSW
    INX     H						 	;(HL) now points to return address
    XTHL							 	;set return address and restore HL
    PUSH    H
    PUSH    B
    PUSH    PSW
    LXI     H,RST38_R				    ;Start of RST 38H vector table
    LDA     RST38ARG_R					;Restore Offset of this RST 38H call
    MOV     C,A						 	;offset is 2 * index 
    MVI     B,00H
    DAD     B
	GETHLFROMM							;get jump vector to HL
    POP     PSW
    POP     B
    XTHL							 	;swap saved HL on stack with jmp vector
R_RET_INSTR:
    RET								 	;to jmp vector
	else
	DS		(7FF4H-7FD6H)				;xx bytes FREE if !REALM100
	endif								;REALM100

L_CONV_DBL_TO_FAC2:
    CALL    L_FRCDBL				    ;CDBL function
    JMP     R_FAC2_EQ_FAC1				;Move FAC1 to FAC2
;
; 6 bytes free at end of rom
;
    DB      0,0,0,0,0,0
