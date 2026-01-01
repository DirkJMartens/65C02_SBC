;	Main assembler file for the BE6502 SBC. 
;	Prepared to be compiled and linked with WDC's assembler and linker software. 
;	Compiling/linking and generating the .HEX file is done with the BE6502_create_hex.bat file 
;	The hex_file.opt file contains the memory layout. 
;	The LCD.asm file contains the EQU and subroutines to drive a 2x16 LCD in 4 bit mode. 
;	The ICM7170.asm file contains the same for the real time clock chip. (not yet tested). 

	CHIP 65C02			; ensure 65C02-compliant code is generated (CPU is 65C816 in emulation mode) 
	TWOCHAR ON			; allows using acronyms such as NL, CR, etc. 
	PW 132				; sets listing file width to 132 chars (0..31 used for addresses and opcodes) 

.INCLUDE LCD.ASM		; EQUs and subroutines to use an 2x16 LCD module in 4 bit mode 

; EQUates that are system-specific
; *******S
; CPU definitions 
HWSTACK			EQU		$FF					; ToS location (grows towards $0000) 

; bit definitions 
bit0			EQU		(1<<0)				; %00000001 = $01
bit1			EQU		(1<<1) 				; %00000010 = $02
bit2			EQU		(1<<2) 				; %00000100 = $04
bit3			EQU		(1<<3) 				; %00001000 = $08
bit4			EQU		(1<<4) 				; %00010000 = $10
bit5			EQU		(1<<5) 				; %00100000 = $20
bit6			EQU		(1<<6) 				; %01000000 = $40
bit7			EQU		(1<<7) 				; %10000000 = $80

; ACIA definitions, used for console messages, WOZMON, etc.  
ACIA_BASE		EQU 		$5000			; UART base address 
ACIA_DATA		EQU 		ACIA_BASE		; stores send and receive data 
ACIA_STAT		EQU 		ACIA_BASE+1		; contains Tx/Rx status, error status, overrun/overflow, etc 
ACIA_CMD		EQU 		ACIA_BASE+2		; sets parity, interrupts used, etc 
ACIA_CTRL		EQU 		ACIA_BASE+3		; sets baudrate, stop/start/word length. etc
ACIA_TX_EMPTY	EQU			1<<4			; ACIA_STAT bit4 = 1/0 for Tx buffer empty/not empty 
ACIA_RX_FULL	EQU			1<<3			; ACIA_STAT bit3 = 1/0 for Rx buffer full/not full 

; VIA definitions, one port used for LCD display and one port for bar graph  
VIA_BASE		EQU		$6000
VIA_PORTB		EQU		VIA_BASE
VIA_PORTA		EQU		VIA_BASE+1
VIA_DDRB		EQU		VIA_BASE+2
VIA_DDRA		EQU		VIA_BASE+3

; ASCII definitions 
ESC             EQU			$1B     		; ESC key
; *******E

STARTUP SECTION 
RESETB_handler:			
; *******S
;	this code is the execution point after power on or a hardware reset. 
					; Setting up the CPU 
	SEI					; 78: SEt Interrupt disable 
	LDX	#HWSTACK		; A2 FF: load ToS location 
	TXS					; 9A: init SP register with it 
					; Setting up the VIA 
	LDA	#$FF			; A9 FF: 1 = output; 0 = input
	STA	VIA_DDRA		; 8D 03 60: make PORTA all outputs 
	STA	VIA_DDRB		; 8D 02 60: make PORTB all outputs 
	LDA	#$00			; A9 00: blank LED bit pattern 
	STA VIA_PORTA		; 8D 01 60: output bit pattern on PORTA
	STA VIA_PORTB		; 8D 00 60: output bit pattern on PORTB
					; prepare LCD screen for 4-bit mode 
	LDA #%00000010 		; A9 02: 0/E=0/RS=0/RW=0/high nibble  
	STA VIA_PORTB		; 8D 00 60
	ORA #LCD_EX			; 09 10: set E: 0/E=1/RS=/RW=0 
	STA VIA_PORTB		; 8D 00 60
	AND #%00001111		; 29 0F: clear E: 0/E=0/RS=0/RW=0/high nibble 
	STA VIA_PORTB		; 8D 00 60

	JSR LCD_INIT 		; 20 AC 00: prep LCD for char output 
	JSR LCD_BOOT_MSG	; 20 AC 00: write SBC model and s/w compilation date on LCD

					; Setting up the ACIA and (serial) console port 
	; LDA		#$00			; load (any) value in A register 
	; STA		ACIA_STAT		; and store to reset the ACIA
	; LDA		#%00010000		; 0=1stop/00=8bits/1=baudrate clk/1111=19200 or 0000=115200 baud
	; STA		ACIA_CTRL		; configure ACIA 
	; LDA		#%00001001		; set to 00=no parity/0=parity disable/0=Rx normal mode
								; 10=RTSB=low,no interr/1=IRQB disabled/1=enable Rx 
	; STA		ACIA_CMD		; ACIA initialized and ready to Rx/Tx 

;	JSR 	console_boot_msg

end_of_program:
	BRA end_of_program	; 80 FE 
; *******E 

VERSION 	macro
; *******S
				.byte '1'
				.byte '.'
				.byte '0'					; software version 
				endm
; *******E

STRINGS SECTION 		
; *******S
;	for LCD messages 
;					   0000000000111111
;		       		   0123456789012345
MESSAGE1		.byte 'WDC65C02 - v1.0', 'NL' 
MESSAGE2	 	.byte 'computer by DMA', 'NL'
MESSAGE3 		DATE
				.byte 'NL'
; *******E

ISRS: SECTION 
; *******S
COP_handler:
ABORTB_handler:
NMIB_handler: 			
; *******S
	LDA		#$55				; load test pattern %01010101
	STA 	VIA_PORTA			; output it on PORTA 
	RTI 
; *******E
IRQB_handler: 			
; *******S
;	ISR to handle IRQs. Can be triggered by ACIA or the RTC. 
; 	Currently only handles ACIA interrupts. 
; PHA										; save A register on ToS
	; PHX										; save X register on ToS
		; LDA			ACIA_STAT				; reading status auto-clears ACIA IRQ 
		; LDA			ACIA_DATA				; read ASCII code of byte received 
		; JSR 		ECHO					; echo char on the console 
		; STA			PORTA					; echo it on PORTA 
	; PLX										; restore X register from stack
	; PLA										; restore A register from stack 
	; RTI
; *******E 
; *******E 

INTERRUPT_VECTORS: SECTION 		
; *******S
			; 65C02 EMULATION mode / startup interrupts 
	.word 						; $FFF0,1 - reserved 
	.word 						; $FFF2,3 - reserved 
	.word 	COP_handler			; $FFF4,5 - software (co-processor) 
	.word						; $FFF6,7 - reserved
	.word	ABORTB_handler		; $FFF8.9 - hardware (ABORTB pin) 
	.word	NMIB_handler		; $FFFA,B - hardware (NMIB pin) 
	.word	RESETB_handler		; $FFFC,D - hardware (RSTB pin) 
	.word	IRQB_handler		; $FFFE,F - hardware (IRQB) / software (BREAK)
; *******E

; *******S
; CHROUT:
; ECHO:					
; ; *******S
	; PHA						; save accu (i.e. char to send) on stack 
		; STA ACIA_DATA		; put char in Tx buffer 
; ?tx_wait: 
		; LDA ACIA_STAT		; check ACIA_STAT for "Tx buffer empty" 
		; AND #ACIA_TX_EMPTY	; "Tx not empty" means "bit4=0" so "AND" returns Z=1
		; BEQ ?tx_wait		; loopback since "Tx not empty" 
	; PLA						; restore accu 
	; RTS                    	; Return.
; ; *******E 

; console_boot_msg: 		
; ; *******S
	; PHA						; save the accu value on ToS 
	; PHX
		; LDA #ESC			; clear console 
		; JSR ECHO  	
		; LDA #'['			; "ESC [ 2 J" is CLS in VT100 
		; JSR ECHO 	
		; LDA #'2'			; 
		; JSR ECHO 	
		; LDA #'J'			; 
		; JSR ECHO 	
		; LDA #ESC			; move cursor to topleft corner  
		; JSR ECHO 	
		; LDA #'['			; "ESC [ H" is HOME in VT100 
		; JSR ECHO 	
		; LDA #'H'			; 
		; JSR ECHO 	
		; LDX #$0				; init index 
; ?nextchar:
		; LDA MSG_HDR_SCR,X	; load indexed char in accu
		; BEQ ?skip		 	; if null char found, skip 
		; STA ACIA_DATA		; put char to send in Tx buffer 
; ?tx_wait: 
		; LDA ACIA_STAT		; check for (bit4)=1 which means "Tx buffer empty" 
		; AND #ACIA_TX_EMPTY	; "Tx not empty" means "bit4=0" so "AND" returns Z=1
		; BEQ ?tx_wait		; loopback if "Tx buffer not empty" 
		; INX					; advance index 
		; JMP ?nextchar		; next char 
; ?skip: 
		; LDX #$0				; init index 
; ?nextchar1:
		; LDA MSG_WELC_SCR,X	; load indexed char in accu
		; BEQ ?null_found		; if null char found, skip the rest 
		; STA ACIA_DATA		; put char to send in Tx buffer 
; ?tx_wait1: 
		; LDA ACIA_STAT		; check for (bit4)=1 which means "Tx buffer empty" 
		; AND #ACIA_TX_EMPTY	; "Tx not empty" means "bit4=0" so "AND" returns Z=1
		; BEQ ?tx_wait1		; loopback if "Tx buffer not empty" 
		; INX					; advance index 
		; JMP ?nextchar1		; next char 
; ?null_found: 
		; PLX				; restore index X register 
		; PLA				; restore the accu 
		; RTS
; *******E 
; *******E

; for console messages
; *******S  
; MSG_HDR_SCR		.byte '   +-----------------------------------------+', 'CR', 'LF'	; 46+2=48
				; .byte '   |   '												; +7=55
				; .byte ESC, '[', '5', 'm'									; +4=59
				; .byte        'Welcome to the WDC65C816 computer  '			; +35=94
				; .byte ESC, '[', 'm'											; +4=98
				; .byte '   |', 'CR', 'LF'									; +4+2=104
				; .byte '   +-----------------------------------------+', 'CR', 'LF'	; +46+2=152
				; .byte 'CR', 'LF', 'NL' 										; +3=155
; MSG_WELC_SCR	.byte 'H/W by WDC and S/W by Steve Wozniak.', 'CR', 'LF'	; 36+2=38
				; .byte 'Adapted by DMA.', 'CR', 'LF'							; +15+2=55
				; .byte 'Software version: '									; +18=73
				; VERSION
				; .byte ', compiled: '										; +3+12=88
				; DATE
				; .byte 'CR', 'LF', 'CR', 'LF'								; +21+2=113
				; .byte '<addr>[.<addr>]<CR> to display <addr>', 'CR', 'LF'	; +37+2=152
				; .byte '<addr>:<val>[<val>]<CR> to store value(s) @ <addr>', 'CR', 'LF' ; +50+2=210
				; .byte '<addr> R<CR> to run code starting at <addr>', 'CR', 'LF', 'CR', 'LF', 'NL' ; +43+3=252
; *******E 

