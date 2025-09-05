;---------------------------------------------------------------------
; Hardware Scroll Patch
;
; Patch code  - place in hole at 75ABH..		Requires BASEPATCH
;---------------------------------------------------------------------
;	.org	75ABH
;---------------------------------------------------------------------
; TRAP_M (11 bytes)
;
; IN:
;	A		holds # of scrolls
;	L		the line number to process first
;---------------------------------------------------------------------
TRAP_M:									;return vector on stack
	pop		d
 	jz		R_ESC_l_FUN					;if zero set, erase current line and done..return to caller
 	push	d
; do a scroll up on upper and lower LCD drivers
	lxi		d,0C028H					;d= 0C0h, e = 40d, 28H
	jmp		TRAP_C

;---------------------------------------------------------------------
; TRAP_L  (22 bytes)
;
; IN:
;	A		holds # of scrolls
;	L		the line number to process first
;---------------------------------------------------------------------
TRAP_L:
	pop		d							;return address
 	jz		R_ESC_l_FUN					;if zero set, erase current line and done..return to caller
 	push	d							;restore return address
; scroll down on upper and lower LCD drivers
	lxi	d,04027H						;d= 40h, e = 39d, 27H
;	Fall Through
TRAP_C:	
 	cpi		07H
 	rnz 								;if a <>7 then return and process normally
	push	psw
	mov		a,e
	sta		scroll_active				;39d or 40d
	push	h
	call	set_new_page				;D argument. updates page_loc
	pop		h
	pop		psw
	ret

;---------------------------------------------------------------------
; RET_M  RET_L (6 bytes)
;---------------------------------------------------------------------
;a is always zero on jump in.
;use this to just clear the scroll active flag
RET_M:	
RET_L:
	sta		scroll_active				;disable scroll active
	jmp		R_ESC_l_FUN

;---------------------------------------------------------------------
;  stop_access  (14 bytes)
;
; IN:
;	E		LCD coordinate
;---------------------------------------------------------------------
; prevent character plotting level 7 when hardware scrolling
stop_access:
	lda		scroll_active
	ora		a
	jz		R_CHAR_PLOT_7 				;if scroll not active then continue with character plotting
;scroll is active
; A contains scroll_active value
	add	e								;sum of e and a
	cpi	44								;some number out of normal range but same for both 
	jz		R_CHAR_PLOT_7				;process the line if we are in the copy condition
	ret									;if scroll not active then continue with character plotting

;---------------------------------------------------------------------
; set_new_page (6 bytes)
;
; page_loc holds page # in upper 2 bits: 0C0H, 80H, 40H, 00H 
;
; IN:
; 	D		holds subtract amount, 40H for down and 0C0H for up
;---------------------------------------------------------------------	
set_new_page:
	lxi		h,page_loc					;set location
	mov		a,m
	sub		d
	mov		m,a
;---------------------------------------------------------------------
; set_page  (15 bytes)
;
; TODO see L_SELECT_LCD_DRIVER_ALL for same code
;---------------------------------------------------------------------
set_page: 								;L_CLR_LCD_TOP_1 is on stack. Irrelevant
	if 0								;shorter so adjust padding
	call	L_SELECT_LCD_DRIVER_ALL
	lda		page_loc
	ret
	else
	mvi		c,03H
	call	R_DELAY_FUNC				;short delay
; duplicate code. call to instruction before L_SELECT_LCD_DRIVER
	lxi		h,L_LCD_SELECT_ALL			;Code Based. Table contains 0FFH, 03H
	call	L_SELECT_LCD_DRIVER			;select LCD drivers
	lda		page_loc					;load page data
	ret
	endif
	
;---------------------------------------------------------------------
; correct_b   (13 bytes)
;---------------------------------------------------------------------
correct_b:								;all registers in use  
	push	d							;save DE
	push	psw							;store PSW
	lda		page_loc 					;ok to just use the one page value as they should be the same
	add		b							;EXCEPT during a page scroll
	mov		c,a							;temp store
	pop		psw							;retrieve PSW
	push	psw							;make sure flags are the same as initial
	mov		a,c							;restore, hopefully C is not used
;
; 3 extra words on stack
; D and PSW pushes were done in code this call replaces.
;
	jmp		L_LCD_PLOT_7				;jump back into routine. 
	;just leave B as is; manipulate A to be the corrected page
