;
; TRS-80 Model 100 ROM Source Code by JdR (Dutchtronix)
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
;	BASEPATCH required for HWSCROLL
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
; There are 3 source files:
;
;	M100-Source.asm
;	VT100inROM.asm
;	VT100inROM2.asm
;	HWPatch.asm
;	
; Notes
;	VirtualT does not emulate telephone modem hardware completely.
;	Enabling the relay and modem are ignored.
;
;	Using TERM with no emulated serial port hangs VirtualT because it VirtualT
;	never returns ready on the serial port. This can easily be fixed in VirtualT
;
