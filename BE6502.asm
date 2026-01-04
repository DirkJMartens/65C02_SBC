; ************************************************************************************************
; *                                                                                              *
; *  Main file for the 65c02-based single board computer, following the Ben Eater design         *
; *                                                                                              *
; *  Some changes include:                                                                       *
; *       - CPU 65c02 is 65C816 running in emulation mode                                        *
; *       - ACIA 65C51 is replaced with UM6551 which does not have the Tx register feature/bug   *
; *       - Added ICM7170 RTC to keep track of date and time                                     *
; *                                                                                              *
; ************************************************************************************************
;	Compiling and linking to be done with the WDC compiler and linker 
;	Batch file BE6502_create_HEX.bat will create a .HEX file as output 
; 	This .hex file can be programmed into a 32K EEPROM (28c256) using Xgpro and a XGecu T48 
;	Files for LCD, ACIA and RTC are separate and included in this file. 

	CHIP 65C02					; ensure compiler generates 65C02 code 
	TWOCHAR ON					; enable use of symbols like 'LF', 'CR', et. 
	PW 132						; make listing file .lst 132 chars wide (0..31 is addr and opcodes) 

	INCLUDE LCD.ASM				; 2x16 LCD in 4 bit mode 
	INCLUDE ICM7170.ASM			; RTC
	INCLUDE UM6551.ASM			; ACIA 
	INCLUDE WOZMON.ASM			; WOZMON monitor program 

; EQUates			
; *******S
; CPU definitions 
HWSTACK			EQU		$FF					; ToS location (grows towards $0000) 

; bit definitions 
bit0			EQU		1<<0				; %00000001 = $01
bit1			EQU		1<<1 				; %00000010 = $02
bit2			EQU		1<<2 				; %00000100 = $04
bit3			EQU		1<<3 				; %00001000 = $08
bit4			EQU		1<<4 				; %00010000 = $10
bit5			EQU		1<<5 				; %00100000 = $20
bit6			EQU		1<<6 				; %01000000 = $40
bit7			EQU		1<<7  				; %10000000 = $80

; ACIA definitions 
ACIA_BASE		EQU 	$5000				; UART base address 

; VIA definitions 
VIA_BASE		EQU		$6000				; VIA base address 
VIA_PORTB		EQU		VIA_BASE
VIA_PORTA		EQU		VIA_BASE+1
VIA_DDRB		EQU		VIA_BASE+2
VIA_DDRA		EQU		VIA_BASE+3

;-------------------------------------------------------------------------
;  ASCII Constants
;-------------------------------------------------------------------------
BEL				EQU		$07				; Bell 
BS              EQU     $08             ; Backspace key 
TAB				EQU		$09				; TAB key 
LF				EQU		$0A			 	; Line Feed
CR              EQU     $0D             ; Carriage Return
ESC             EQU     $1B             ; ESC key
PROMPT          EQU     '\'             ; Command Prompt character
; *******E

STARTUP SECTION 
RESETB_handler:			
; *******S
					; Setting up the CPU 
;	CLD					; clear decimal (=BCD) mode 
;	SEI					; 78: SEt Interrupt disable 
	CLI					; clear interrupt disable (enable interrupts) 
	LDX	#HWSTACK		; A2 FF: load ToS location 
	TXS					; 9A: init SP register 
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
;	CLI					; enable interrupts 

	JSR LCD_INIT 		; 20 AC 00: prep LCD for char output 
	JSR LCD_BOOT_MSG	; 20 AC 00: write SBC model and s/w compilation date on LCD

					; Setting up the ACIA and (serial) console port 
	JSR ACIA_INIT		; initialize the ACIA 
	JSR CONSOLE_BOOT_MSG

	JSR WOZ_RESET 

end_of_program:
	BRA end_of_program	; 80 FE 
; *******E 

STRINGS SECTION 		
; *******S
;				for LCD messages 
;					   0000000000111111
;		       		   0123456789012345
MESSAGE1		.byte 'WDC65C02 - v1.0', 'NL' 
MESSAGE2	 	.byte 'computer by DMA', 'NL'
MESSAGE3 		DATE
				.byte 'NL'
; *******E

ISRS: SECTION 
COP_handler:
ABORTB_handler:
NMIB_handler: 			
; *******S
	LDA		#$55				; load test pattern %01010101
	STA 	VIA_PORTA				; output it on PORTA 
	RTI 
; *******E

IRQB_handler: 			
; *******S
; ACIA generates an IRQB when the Rx buffer is full (currently only source for IRQB) 
; ACIA "Tx empty" interrupt is disabled during ACIA init 
; VIA interrupts are also disabled during its init 
; When IRQB is triggered, the ASCII code of the character is in the ACIA_DATA register 
	PHA										; save A register on ToS
	PHX										; save X register on ToS
		LDA	ACIA_STAT				; reading status auto-clears ACIA IRQ 
		LDA	ACIA_DATA				; read ASCII code of byte received 
		; JSR 		ECHO					; echo char on the console 
;		STA	VIA_PORTA				; echo it on PORTA 
		STA ACIA_DATA
?tx_wait:
		LDA	ACIA_STAT
		AND #ACIA_TX_EMPTY
		BEQ ?tx_wait 
	PLX										; restore X register from stack
	PLA										; restore A register from stack 
	RTI
; *******E 

INTERRUPT_VECTORS: SECTION 		
; *******S
				; EMULATION mode / startup interrupts 
	.word 						; $FFF0,1 - reserved 
	.word 						; $FFF2,3 - reserved 
	.word 	COP_handler			; $FFF4,5 - software (co-processor) 
	.word						; $FFF6,7 - reserved
	.word	ABORTB_handler		; $FFF8.9 - hardware (ABORTB pin) 
	.word	NMIB_handler		; $FFFA,B - hardware (NMIB pin) 
	.word	RESETB_handler		; $FFFC,D - hardware (RSTB pin) 
	.word	IRQB_handler		; $FFFE,F - hardware (IRQB) / software (BREAK)
; *******E
