;
; VT100 code to be included in M100 ROM
;
; define labels used in the VT100 code
;
coldboot	EQU	L_RESET_TIME			;cold boot
puhook		EQU	BOOTHK_R		        
himem		EQU	HIMEM_R			        ;location of himem
initsys		EQU	L_BEEP_RESET            
FCERR 		EQU	R_GEN_FC_ERROR	        ;Generate FC error
L5char		EQU	R_CHAR_PLOT_5	        ;level 5 character print
evalbuf		EQU	R_EVAL_EXPR_2	        ;Evaluate the expression in the buffer pointed to by HL
SNERR		EQU	R_GEN_SN_ERROR	        ;Generate Syntax error
HCHGET		EQU	HCHGET_R		        ;CHGET hook entry
HCHSNS		EQU	HCHSNS_R		        ;CHSNS hook entry
HCHPUT		EQU	HCHPUT_R		        ;CHPUT (print) hook entry
txtload		EQU	L_TEXT_BYTE		        ;Load Address of call within TEXT program
blnk		EQU	L_BLINK_LCD		        ;Turn off background task, blink & reinitialize cursor blink time
labelprot	EQU	LINPROT_R		        ;Label line protect status
SYSrowcol	EQU	CSRY_R			        ;SYS current row/col
SYSmaxrow	EQU LINCNT_R		        ;MAX SYS row col count
SYSmaxcol	EQU	LINWDT_R		        ;MAX SYS col count
PRTrowcol	EQU	LCDCSY_R		        ;last printed cursor row col
CLEAR1		EQU	L_EVAL_POS_EXPR	        ;called by Clear hook handler
filebufptr	EQU	MEMSIZ_R		        ;File buffer area pointer
;
; Unused RAM locations if !HWMODEM (required for VT100INROM)
;
;	MDMSPD_R		Dial speed (1=10pps, 2=20pps)
;	PORTA8_R		Contents of port A8H
;
ESC_pending	EQU MDMSPD_R				;stores pending ESC condition 0 = no ESC, 1=ESC
Ypending	EQU	PORTA8_R				;ESC Y is pending (00 = cleared, 01 = Y received, 02 = col received)
;
; next 2 locations are unused RAM locations
;
	if	AUXCON
aux_console	EQU 0FFFDH					;store which serial output to use (0=RS232,1=TTL)
	endif
var1		EQU	0FFFEH					;Flag. Initialized to 1 on cold boot
;
; TODO use last 8 bytes of Alt LCD Buffer for ESCY sequence
;
ESCY		EQU		0FDF8H

dbstart:
		call initsys					;stop beep, reset 8155
										; cursor status, FF = on, 0 = off
dbstart1:
		JMP	coldboot					;Jump into Cold boot routine to set YEAR to 0.  Why???					
;
;RST7 44H - CRT PUT Hook
;
hk_crtput:
		POP	H
		POP	PSW							;Get Byte to be sent from stack
		push PSW						;But byte back on stack
		call snda2dvi					;Call routine to send A to DVI SCREEN Mailbox
		JMP	R_POP_ALL_REGS				;Pop AF, BC, DE, HL from stack
;
;RST7 40H - CRT OPEN Hook
;
hk_crtopen:
		POP	PSW	
		JMP	R_LCD_OPEN		;LCD and PRT file open routine			
;
;RST7 08H - Print A to SCREEN hook handler 
; all printing loops through this routine, LCD or CRT
; include function to turn off cursor on CRT when console is LCD
;
hk_rst4:
		MOV	C,A							;Save byte to be printed in C
		LDA	CONDEV_R					;New Console device flag
		ORA	A							;Test if New Console flag set
		MOV	A,C							;Get byte to be printed in A
		
		LXI	H,var1						;Load cursor status
		JNZ	hk_rst4_2					;Jump to Print byte to SCREEN if New Console flag set
;
; CONDEV_R == 0
; new console device flag reset, so display on LCD (SCREEN 0)
;
		MOV	A,M							;Get cursor status flag in A
		MVI	M,00H						;indicate cursor is to be off. TODO var1 ever reset? Reset to 1 on warm reboot?
		ANA	A							;test was it off already?
		MOV	A,C							;Get byte to Print in A 
		RZ								;Return here to print character on LCD, cursor was turned off already
;
;ok so turn off the cursor
;
		push PSW						;Save byte to be printed on Stack

		if 1
		mvi	a,'Q'						;turn cursor off escape sequence
		call sendESCa
		else
		MVI	C,1BH						;Prepare to send ESC sequence
		call sendc						;Send byte in C to the DVI SCREEN Mailbox
		MVI	C,51H						;Load ESC sequece to turn off cursor perhaps - yes "Q"
		call sendc						;Send byte in C to the DVI SCREEN Mailbox
		endif

		POP	PSW							;Restore byte to be printed from stack
		RET								;Return here to print character on LCD

;
; IN:
;	HL		ptr to cursor status variable
;
hk_rst4_2:
		MVI	M,0FFH						;Indicate DVI SCREEN initialized (or maybe a byte printed)???
		LXI	H,R_POP_ALL_REGS			;pop all registers on return
		XTHL							;swap HL with [SP]
		jmp	snda2dvi	

;
;RST7 04H - CHGET.  Test if called from TEXT program and intialize SCREEN.
;
hk_chget:
;
; check if we were called from R_TEXT_GET_NEXT_BYTE().
; the call to R_WAIT_KEY() pushes the return address (L_TEXT_BYTE/txtload)
; plus 3 word registers plus L_WAIT_KEY_1, so there are 5 words on the stack
;
	LXI	H,000AH							;Prepare to inspect stack 10 bytes in the past
	DAD	SP								;Get SP + 10 in HL
	MOV	A,M								;Get LSB of the address that called us
	INX	H								;Increment to MSB
	MOV	H,M								;Get MSB of the address that called us
	MOV	L,A								;Move LSB to HL
	LXI	D,txtload						;Load Address of call within TEXT program
	RST	3								;Compare DE and HL - Test if called from TEXT
	RNZ									;Return if not called from TEXT
	
	call R_TURN_CURSOR_OFF 				;Turn the cursor off
	LDA	CONDEV_R							;New Console device flag
	ANA	A								;Test if the Console has been initialized already
	RZ									;Return if console already initialized

	JMP	blnk	
		
;
;RST7 3CH - Initialize New Console for LCD/DVI Hook
; this routine is hit once, when console flag is set to 1
;
hk_newconsole:

	POP	H
	LDA	labelprot						;Get Label line protect status
	push PSW							;Save current Label Line Protect status to stack
	
	XRA	A								;Prepare to clear Label Line Protect status
	STA	labelprot						;Clear Label line protect status
	
	lhld SYSrowcol						;SYS current row/col
	push H								;Push current cursor row/col to stack
	
	lhld PRTrowcol						;last printed cursor row col
	shld SYSrowcol						;SYS current row/col
	
	LXI	H,2808H							;Prepare to configure for 8 ROWS, 40 COLS
	shld SYSmaxrow						;MAX SYS row col count	
	call L5char							;Character plotting level 5. Handle ESC sequences & call level 6
										;clears label line, 
				
	lhld SYSrowcol						;SYS current row/col
	shld PRTrowcol						;last printed cursor row col
	
	lhld DVIMAXROW_R					;MAX DVI row col count
	shld SYSmaxrow						;MAX SYS row col count
	
	POP	H								;Restore original Cursor ROW,COL from stack
	shld SYSrowcol						;SYS current row/col
	POP	PSW								;Get original Label Line protect from stack
	STA	labelprot						;Save as current Label line protect status
	RET	
	
;
;RST7 3EH - SCREEN command hook handler.  Initializes DVI SCREEN mode.
;	
;Return:  HL = Current row,col
;         DE = Active rows,cols (25,40)
;
;	only gets called if SCREEN 1 or 2, not 0
; 	implies that the LCD configuration must be detected.
;
;	enter with HL pointing to comma of 0,0 argumemnt on stack
;
hk_screen:
	call	blnk						;Turn off background task, blink & reinitialize cursor blink time
	pop		b							;get return vector
	pop		h							;get txt ptr or directory ptr
	push	h
	push	b							;rebuild stack
;
; if HL points to a directory entry (happens when called from L_SCREEN_STMT_1()
; and L_MENU_CTRLU_1() and the extension of the file before the current file
; ends in '1' or '2', this code will fail.
;
	dcx		h							;backup
	mov		a,m							;get arg 1

	if	AUXCON
	cpi		'2'
	jz		screen_TTL					;if 2 then jump to TTL output definition
	endif								;AUXCON

	cpi		'1'
	jz		screen_RS232				;if 1 then jump to RS-232 output definition

	inx		h							;next
	mov		a,m
	lxi		h,setnewcons				;jmp address for conditional calls
	push	h
	cpi		0B0h						;ROM command file if HL points to directory
	rz									;if called from F8 process, restore newconsole, leave aux_console
	cpi		0C0h						;TXT file if HL points to directory
	rz									;if called from F8 process (back to MENU), restore newconsole, leave aux_console
	cpi		080h						;BASIC file if HL points to directory
	rz									;if called from F8 process (back to MENU), restore newconsole, leave aux_console
	pop		H							;remove jmp address

	jmp		FCERR						;if not a "1" or a "2" then FC error
;
; console request valid
; aux console = 0 means RS232
; aux console = 1 means TTL
;
hk_screen2:
	if	AUXCON
	sta		aux_console					;store auxiliary console indicator
	endif
; fall through
setnewcons:
	MVI		A,01H						;Prepare to set New Console flag so we re-initialize
	STA		CONDEV_R					;New Console device flag
	lhld	DVIROWCOL_R					;DVI current ROW,COL
	push	H							;Save current cursor row, col on stack
	shld	SYSrowcol					;update SYS current row/col
	call	R_RESUME_AUTO_SCROLL		;Resume automatic scrolling
	call	R_TURN_CURSOR_OFF			;Turn the cursor off
	lhld	DVIMAXROW_R					;MAX DVI row col count
	XCHG								;Put active (??) rows,cols in DE (used by SCREEN command upon return)
	POP		H							;Get current cursor row,col from stack
	mov		A,D							;D was just loaded with DVIMAXCOL_R
	MOV		B,A							;Save max col WIDTH in B
; compute COLWRAP_R: max col WIDTH modulo 14, add 14
-	SUI		14
	JNC		-							;Subtract repeatedly until negative
	ADI		2*14						;Add 14 to get modulo result. Then add 14
	CMA									;negate result
	INR		A
	ADD		B							;Add original WIDTH to it.
;
; This is the last column for PRINT, 56. if DVIMAXROW_R==80
; 14. if DVIMAXROW_R==40
;
;add this function just to redisplay function key line if required
;
	push	PSW
	push	H
	push	D
	LDA		labelprot					;Label line protect status
	ora		a							;Test if Function Key line is visible
	CNZ		R_DISP_FKEY_LINE			;calif visible: Display function key line
	pop		d							;sys max row, col
	pop		h							;sys current row, col
	pop		psw							;a = comma value for print, a, hl, de ready for use by calling routine								
	RET					
					
init_RS232:								;init serial port		
	lxi		h,RS232						;Code based. 19200 8N1
	stc
	call	R_SET_RS232_PARAMS			;Set RS232 parameters from string at M
	ret

screen_RS232:
	call	init_RS232
	xra		a							;aux console = 0 means RS232
	jmp		hk_screen2

	if	AUXCON
screen_TTL:
	mvi		a,1							;aux console = 1 means TTL
	jmp		hk_screen2
	endif
;
;Call routine to send A to DVI SCREEN Mailbox
;  only gets here if newconsole flag set.
;
snda2dvi:
	call	sndA2vid					;Send A to DVI SCREEN Mailbox. Checks for TAB or DEL
	MOV		C,A							;Move Byte to send to DVI to C
	MVI		A,01H						;Prepare to indicate extra POP PSW needed
	STA		POPPSW_R					;Indicate extra PSW POP needed during Char level 5 plot   
	LDA		CONDEV_R					;New Console device flag
	ANA		A							;Test if New Console flag set
	JZ		lcdconf						;Jump if not new console - reconfigure for LCD here
										;CRT still selected
	
	call	L5char						;Character plotting level 5. Handle ESC sequences & call level 6
										;not sure what this does
										;perhaps the POP above gets this L5 routine to update cursor location
;
; update location
;
	lhld	SYSrowcol					;SYS current row/col
	shld	DVIROWCOL_R					;DVI current ROW,COL
	RET	

;
; Send A to DVI SCREEN. Checks for TAB or DEL
; preserves A
;
sndA2vid:
	CPI		09H							;Test if Byte to print is TAB
	RZ									;Return if printing a TAB
	CPI		7FH							;Test if Byte to print is DEL
	RZ									;Return if printing DEL
	push	H				
	push	D							;Save all registers to stack
	push	B				
	push	PSW			
	MOV		C,A							;Move byte to print to C
	call	sendc						;Send byte in C to the DVI SCREEN Mailbox
; 	LDA		pwrflg						;Load POWER CONT flag perhaps?
; 	ANA		A							;Test if POWER CONT flag is zero?
; 	JZ		R_POP_ALL_REGS				;Pop AF, BC, DE, HL from stack 7 RET
; 	MOV		A,C							;Restore byte printed to DVI to A
; 	CPI		58H							;Test if "X" was printed
; 	CZ		initdvi						;Call routine to initialize DVI mode if "X" printed. Why??
	JMP		R_POP_ALL_REGS				;Pop AF, BC, DE, HL from stack & RET
;
; pwrflg might also indicate if an escape code was sent?  esc-X?		
;
;Send byte in C to the DVI SCREEN
;
sendc:
;
; first test for escape sequence occurring
;
	lda		ESC_pending
	ora		a
	mov		a,c							;place byte to print in A
	jnz		mapM100ESC					;escape is pending. map M100 Escape code to VT100/VT52 code
	cpi		0Ch							;no escape pending. is the character 0CH
	jz		mapM100ESC					;match and send characters
	cpi		0Bh							;no escape pending. is the character 0BH
	jz		mapM100ESC					;match and send characters
	cpi		01Bh						;no escape pending. is the character escape?
	jnz		senda						;value to print in C and A
	mvi		a,01
	sta		ESC_pending					;indicate an ESC is pending
	ret									;ESC is trapped, just return with no print	
;
;Send A protected register
;
senda_protected:
	push	h
	push	b
	call	senda
	pop		b
	pop		h
	ret
;
;Send ESC + byte in A to the DVI SCREEN
;
sendESCa:
	push	psw							;temp store
	mvi		a,01BH						;load ESC
	call	senda						;send it
	pop		psw							;reload
;
;Send byte in A to the DVI SCREEN
;
senda:
	if	AUXCON
	mov		c,a							;temp store
	lda		aux_console
	ora		a
	mov		a,c							;restore
	jz		R_SEND_A_USING_XON			;send A via RS232
	jmp		fascas						;send at 57600 bits/sec on TTL port
	else
	jmp		R_SEND_A_USING_XON			;send A via RS232
	endif
;
; Map M100 Escape codes to VT100/VT52 + extended codes
;   look at character after ESC, and send the required sequence
;   works only for single escape codes, not nested or longer sequences.
;	ESC Y c,r	Set Cursor Location
;
mapM100ESC:								;a holds byte following ESC. or direct 0C, 0B	
	mov		c,a							;store next byte to send in C
	lda		Ypending					;0, 1 or 2
	ora		a
	jnz		processxy					;C holds data, jump here when Ypending flag
	mov		a,c
	cpi		'Y'							;no Y pending, now check if a Y followed ESC
	jnz		mapcont	
	mvi		a,1
	sta		Ypending					;Y detected - enable Ypending flag
	ret
;
mapcont:	
	mvi		a,'X'
	cmp		c
	jz		mapdone						;filter out ESCX
	lxi		h,ESCcodes
;
maploop:								;c holds data
	mov		a,m	
	ora		a
	jz		nomatch						;get lookup and compare to 00
	cmp		c
	jz		match						;get lookup and compare to c
	inx		h
	inx		h
	inx		h
	jmp		maploop
;	
match:									;hl points to match byte
	push	h
	mvi		a,'['
	call	sendESCa
	pop		h
	inx		h							;advance hl
	xchg								;place in d
	lhlx								;load hl with [de] 8085 instruction
;		
maploop2:
	mov		a,m							;byte to send
	ora 	a							;end of sequence?
	jz	 	mapdone						;yes, done
	call	senda_protected 			;send byte saving registers BC,HL
	inx		h
	jmp		maploop2
;
nomatch:								;no match found so just send original escape sequence
	mov		a,c
	call	sendESCa					;send uncorrected byte
;
mapdone:
	xra		a
	sta		ESC_pending					;reset the flag
	ret									;done
;
; processxy - handle ESC Y r,c and convert to ESC [<v>;<h>H 
; C holds next byte
;
processxy:								;ESC Y received. next 2 bytes are R and C		
	lda		Ypending					;value is 1 or 2
	cpi		2
	jz		get_row
;
get_col:								;Ypending is 1
	lxi		h,ESCY+2					;col = ascii target
	mvi		a,02
	sta		Ypending					;next state
	call	convertnum					;write row ascii in C number to location
	ret
;
get_row:
	lxi		h, ESCY
	mvi		m,1BH						;ESC to ESCY+0
	inx		h
	mvi		m,'['						;ESCY+1
	lxi		h,ESCY+4
	mvi		m,';'						;'m' to ESCY+4
	inx		h							;ESCY+5
;row = ascii target
	call	convertnum					;write col ascii in C number to location
	mvi		a,'f'						;'f'
	sta		ESCY+7
	mvi		c,8							;send 8  bytes
	lxi		h, ESCY
;
xyloop:
	mov		a,m							;get byte
	ora		a							;test. Skipping NULL here 
	cnz		senda_protected				;send byte saving registers BC,HL
	inx		h
	dcr		c							;end of sequence?
	jnz		xyloop						;no, loop back
;
xydone:
	xra		a
	sta		Ypending
	sta		ESC_pending
	ret
;
; hl points to memory for number conversion
; c holds value. Must start with '0' if C <= 9
; currently fails to do that but MVT100.exe was
; updated to accept 1 or 2 digits for the
; row/column values.
;
convertnum:
	push	h							;save destination buffer ptr
	mov		a,c
	sui 	31							;01FH
	mov		l,a							;zero extend A to HL
	mvi		h,0
	call	L_MAKINT 					;load FAC1 with hl
	call	R_PRINT_FAC1				;Convert binary number in FAC1 to ASCII at M
;
; R_PRINT_FAC1 returns &MBUFFER_R in HL.
; if C <= 9, say 4, the result will be " 4"<0>, should be " 04"<0>
;
	pop		d							;destination buffer ptr to DE
	lhld	MBUFFER_R+1					;get 2 characters from M buffer
	shlx								;8085 instruction. Store HL at [DE]
	ret
;
;Configure for LCD output format (8 lines, 40 columns)
;
lcdconf:
	LDA		labelprot					;Label line protect status
	push	PSW							;Save old Label Line protect status on stack
	XRA		A							;Prepare to clear Label line protect status
	STA		labelprot					;Clear Label line protect status
	lhld	SYSrowcol					;SYS current row/col
	push	H							;Save current Cursor / Row to stack
	lhld	DVIROWCOL_R					;DVI current ROW,COL
	shld	SYSrowcol					;SYS current row/col
	lhld	DVIMAXROW_R					;MAX DVI row col count
	shld	SYSmaxrow					;MAX SYS row col count
	call	L5char						;Character plotting level 5. Handle ESC sequences & call level 6
										;clear label line
	lhld	SYSrowcol					;SYS current row/col
	shld	DVIROWCOL_R					;DVI current ROW,COL
	LXI		H,2808H						;Switch to 40 COL, 8 ROW mode
	shld	SYSmaxrow					;MAX SYS row col count
	POP		H							;Get original current Cursor/Row from stack
	shld	SYSrowcol					;SYS current row/col
	POP		PSW							;Get Original Lable Protect Status from stack
	STA		labelprot					;Save as current Label line protect status
	RET	
;	
; Boot-up Hook. This hook is called by the Main ROM at Boot-up. (We Hooked it).
; Warm boot only.
;	
phook:
	DI									;Disable interrupts during initialization	
phook1:
	LXI	B,1000							;Setup Delay counter value	
phook2:
	call R_CHK_SHIFT_BREAK 				;Check if SHIFT-BREAK is being pressed	
	JC	phook1							;Keep looping until SHIFT-BREAK released	
	DCX	B				        	    ;Decrement count (16-bit decrement)	
	MOV	A,B				        	    ;test 16-bit count	
	ORA	C
	JNZ	phook2			        	    ;Keep looping until count = 0	
	POP	H				         	 	;Get address from where we were called	
	push H				        	    ;Put the address back so we can RET properly
	LXI		D,L_PWR_DOWN_BOOT			;Prepare to test if we were called from Auto PowerDown
	COMPAR								;compare return address and L_PWR_DOWN_BOOT
	RNZ									;If not called from Auto-PowerDown reboot routine, then just exit
	LDA	CONDEV_R				        ;New Console device flag	
	ANA	A					            ;Test if Console has been intialized	
	RZ						            ;Return if it has	
;
; We only get here if we rebooted after an auto power shutdown and CONDEV_R != 0
;									
	POP	H					            ;Get address where we would return
	LXI	H,L_PWR_DOWN_BOOT2				;or jmp there without pushing this address
	push H					            ;Push new RET address to stack	
; copy of some of the ROM code here. See "reboot after auto power down"					
	call L_BOOT_2
	lhld SAVEDSP_R
	push H                          
	call L_LCDrefresh					;Refresh LCD from LCD RAM
; start added code
	call blnk							;This is new! Turn off background task, reinitialize cursor blink time
; end added code
	POP	H                           
	RET									;Return to normal Boot-up processing
;
; This code needs to be called on a cold boot.
; Could be integrated with R_INIT_RST_38H_TBL()
;
L_VT100_HOOK_INIT:
	LXI	B,hookdat						;Load pointer to our RST 38H Vector addresses
;
; TODO:
;	CHGET (entry at offset 4, wait for keyboard input) also used by Rex
;	Need to chain the VT100 replacement with the Rex replacement
;	This code is executed at cold boot so presumably before any Rex code,
;	similar to TS-DOS.
;
	LXI	D,RST38_R						;Load Start address of RST 38H vector table
hookloop:
	ldax b								;Get offset of 1st vector to update
	INX	B								;Point to LSB of 1st RST 38H vector
	MOV	L,A								;Move Vector offset to HL             
	INR	A								;Increment A to test for FFH termination byte
	JZ init_vid							;Jump if termination byte (FFH)
	MVI	H,00H							;Zero MSB of HL for offset calculation
	DAD	D								;Offset into RST 38H vector table
	LDAX B								;Load LSB of next RST 38 vector
	INX	B								;Increment to MSB of vector
	MOV	M,A								;Save LSB of our routine to RST 38H vector table
	INX	H								;Increment to MSB location in vector table
	LDAX B								;Load MSB of our address
	INX	B								;Point to next RST 38H offset in our local table
	MOV	M,A								;Save MSB of next vector address to RST 38 Vector table
	JMP	hookloop						;Jump to load next RST 38 vector table entry	

	if 0
;
; code to reset the hook table to R_RET_INSTR.
; Ignores potential conflicting hooks (REX)
;
 Wrong: entries above offset 0x1E require R_GEN_FC_ERROR address.

L_VT100_UNHOOK:
	LXI	B,hookdat						;Load pointer to our RST 38H Vector addresses
unhookloop:
	ldax b								;Get offset of 1st vector to update
	INX	B								;Point to LSB of 1st RST 38H vector
	INX	B								;Increment to MSB of vector
	INX	B								;Point to next RST 38H offset in our local table
	MOV	L,A								;Move Vector offset to HL             
	INR	A								;Increment A to test for FFH termination byte
	JZ init_vid3						;Jump if termination byte (FFH)
	MVI	H,00H							;Zero MSB of HL for offset calculation
	LXI	D,RST38_R						;Load Start address of RST 38H vector table
	DAD	D								;Offset into RST 38H vector table
	if 1
	xchg								;resulting table ptr to DE
	lxi	h,R_RET_INSTR					;replacement address
	shlx								;store address in table. Note 8085 only instruction.
	else
	MVI	M,R_RET_INSTR & 256				;Save LSB of our routine to RST 38H vector table
	INX	H								;Increment to MSB location in vector table
	MVI	M,R_RET_INSTR >> 8				;Save MSB of next vector address to RST 38 Vector table
	endif
	JMP	unhookloo2						;Jump to load next RST 38 vector table entry
init_vid3:
	endif
	
	if 0
;
; Hack to exclude VT100.CO from the HIMEM check
; Need to return Load address of current program in HL
; Unused
;
R_CMP_HIMEM2:
	lhld	LASTLEN_R					;size of .CO File
;
; test if bit 7 of H is set, normally not possible.
; must clear bit 7 in size field if set.
;
	mvi		c,0							;preset flag to FALSE
	mov		a,h
	ora		a
	jp		+							;brif bit 7 clear
	inr		c							;set Flag
	ani		7FH							;clear bit 7
	mov		h,a							;update size of .CO File
	shld	LASTLEN_R
+	LHLD    LOADADR_R					;'Load address' of current program
	mov		a,c							;get Flag
	ora		a							;test
	rnz									;brif TRUE. Carry NOT set
	XCHG								;'Load address' of current program to DE
    LHLD    HIMEM_R						;HIMEM to HL
    XCHG								;'Load address' of current program back to HL
										;HIMEM to DE
    COMPAR								;HL - DE
    RET
	endif								;if 0
