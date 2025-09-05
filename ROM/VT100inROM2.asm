;
; second part of vt100inROM.asm
;
;====================================================================================
;Strings used by the program
;====================================================================================
RS232:
		DB	"98N1D",00H	

;====================================================================================
; M100 Escape code mapping table
;====================================================================================
ESCcodes:			
		DB	0Bh
		DW	L_home
		DB	0Ch
		DW	L_cls
		DB	"T"
		DW	lock8
		DB	"U"
		DW 	unlock8
		DB	"V"
		DW	lockscroll
		DB	"W"
		DW	unlockscroll		
		DB	"P"
		DW	L_curson
		DB	"Q"
		DW 	cursoff
		DB	"M"
		DW	delline
		DB	"L"
		DW	insline		
		DB	"K"
		DW	eraseEOL
		DB	"p"
		DW	invchr
		DB	"q"
		DW	normchr
		DB	"A"
		DW 	cursup
		DB	"B"
		DW	cursdwn
		DB	"C"
		DW	cursrt
		DB	"D"
		DW	curslft
		DB	"J"
		DW 	eraseEOP
		DB	"E"
		DW	L_cls
		DB	"j"
		DW	L_cls
		DB	"I"
		DW	erasecl	
		DB	"H"
		DW	L_home	
		DB	00
					
L_cls:		DB	"2J",01Bh,"["		; CLS, fall into HOME
L_home:		DB	"H",00				; Home
L_curson: 	DB	"?25h",00			; cursor on	
cursoff:	DB	"?25l",00			; cursor off
eraseEOL:	DB	"K",00				; erase to end of line
invchr:		DB	"7m",00				; reverse character
normchr:	DB	"0m",00				; normal character
cursup:		DB	"A",00				; up
cursdwn:	DB	"B",00				; down
cursrt:		DB	"C",00				; right	
curslft:	DB	"D",00				; left
eraseEOP:	DB	"J",00				; erase to end of page
erasecl: 	DB	"2K",00				; erase to end of page

lock8:		DB	"T",00				; lock line 8
unlock8:	DB	"U",00				; unlock line 8
lockscroll:	DB	"V",00				; lock scroll
unlockscroll: 	DB	"W",00				; unlock scroll
delline:	DB	"M",00				; delete line @ cursor
insline: 	DB	"L",00				; insert line @ cursor
		
;	double ESC trap		X		eliminated in VT100 driver.
;	L_home				0BH		mapped		[H
; 	L_cls				0CH		mapped		[2J + [H
; 	lock line 8			T		mapped		[T
;	unlock line 8		U		mapped		[U
;	lock scroll			V		mapped		[V
;	unlock scroll		W		mapped		[W
;	delete line@cursor	M		mapped		[M		
;	insert blank line	L		mapped		[L
; 	turn on cursor		P		mapped		[?25h
; 	turn off cursor		Q		mapped		[?25l
; 	erase to EOL		K		mapped		[K
; 	set reverse char	p		mapped		[7m
; 	reset reverse char	q		mapped		[0m

;	cursor up			A		mapped		[A
;	cursor down			B		mapped		[B
;	cursor right		C		mapped		[C
;	cursor left			D		mapped		[D
 
;	erase to end of page J		mapped		[J
;	set cursor location	Y,c,r	mapped		[<v>;<h>H
; 	L_cls				E		mapped		[2J			
;	L_cls		 		j		mapped		[2J			
;	erase current line	I		mapped		[2K
;	vertical tab		H		mapped		[H

;====================================================================================
;Initialize DVI and Disk BASIC variables.
; called at cold boot
;====================================================================================

init_vid:
	call	init_RS232
;
; clear flags
;
	call	xydone						;returns 0 in A

	if AUXCON
	sta		aux_console					;default is RS232
	endif

	inr		a
	sta		var1						;initialize to 1 on cold boot
	cma									;set A to 0FEH
;	
;Set signature that Disk BASIC loaded. skip things like loading IPL. Actually skips L_XTRNL_CNTRLER_CPY()
;
	STA	VIDFLG_R						;initialize to 0FFH on cold boot
;
; Reset terminal to initial state
; Only on cold boot though
;
	mvi		A,'c'						;send RIS 
	call	sendESCa
;
; not needed if R_FUN_INIT_IMAGE is changed
;
;	lxi	h,5018h							;24x80 mode
;	shld DVIMAXROW_R					;Store max number of rows and columns for CRT
;
; DVIROWCOL_R is initialized to 1,1 at cold boot using the R_FUN_INIT_IMAGE block copy
;	LXI	H,0101H							;Prepare to go to Row 1, Col 1
;	shld DVIROWCOL_R					;DVI current ROW,COL	
	RET

	if 0
;
; Uninitialize
;
uninit_vid:
	XRA		A
	STA		VIDFLG_R
	sta		ESC_pending
	sta		Ypending
	if	AUXCON
	sta		aux_console
	endif
	ret
	endif
;
;RST 7 Vector to Handler Mapping table.
;   1st Byte = HOOK #
;   2nd Byte = LSB of Hook address
;   3rd Byte = MSB of Hook address			
;	
hookdat:
	DB	44H								;CRT PUT -  called at 14FA in M100
	DW	hk_crtput				
	DB	40H								;CRT OPEN  -  called at 14F8 in M100			
	DW	hk_crtopen				
	DB	08H								;Print A to SCREEN - called at 4317 in M100, starting at RST4 / 4B44			
	DW	hk_rst4					
	DB	04H								;CHGET - called at 12D4 (CHGET routine - wait for keyboard input)			
	DW	hk_chget				
	DB	3CH								;Initialize LCD/DVI - called from level 3 character print			
	DW	hk_newconsole					;called from L_INIT_DVI, only when console flag = 1									
	DB	3EH								;SCREEN - called from 1E50
	DW	hk_screen	
	DB	0FFH							;Termination marker

	if	AUXCON
;
;fascas - send a byte to cassette for TTL serial @ 57600 bit/s
; routine to send a data byte out the cassette port
; direct connection, no filtering
; S. Adolph v2
; timing for 57600 baud
;
; send inverted TTL (so you get TTL externally)
; start = 1 (zero)
; data is inverted
; stop = 0 (one)
;     	
; start bit duration = 7+4+4+4+4+4+4+4+4+4 = 43
; data bit duration  = 4+10+4+4+4+4+4+4+4  = 42
; stop bit duration  = 4+7+4+4+4+4+4+7+4   = 42
;
; 42.65 clock cycles is ideal
; TTL Logic
;       
fascas:

	di
	cma
	mov	c,a								;store data	
	mvi	d,01000000b						;or data
	mvi	e,10000000b						;and data
           	
sendstart:
	mvi	a,11000000b						;latch one
	sim									;send start bit
		
	mvi	b,08
	nop
	nop									;start bit delay
             
sendloop:								;send 8 bits
	mov	a,c								;get data
	rrc									;rotate bits, get carry status
	mov	c,a								;store data
										;bit is in MSB
	ana	e								;get data bit
	ora	d								;set latch
		
	nop									;one delay
				
	sim									;send one bit
	dcr	b
	jnz	sendloop
             	
sendstop:    
	nop
	nop
	nop
	nop
	nop									;last bit delay for 57600
		
	mvi	a,01000000b						;latch one
	sim									;send stop bit
			
	ei
	ret									;Return to BIOS
	endif								;AUXCON
