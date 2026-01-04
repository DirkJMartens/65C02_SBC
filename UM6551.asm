UM6551_ASM_INCLUDED	EQU 1

; ACIA definitions 
ACIA_DATA		EQU 		ACIA_BASE		; stores send and receive data 
ACIA_STAT		EQU 		ACIA_BASE+1		; contains Tx/Rx status, error status, overrun/overflow, etc 
ACIA_CMD		EQU 		ACIA_BASE+2		; Tx/Rx funtions: parity, interrupts used, etc 
ACIA_CTRL		EQU 		ACIA_BASE+3		; baudrate, stop/start/word length. etc
ACIA_TX_EMPTY	EQU			bit4			; ACIA_STAT bit4 = 1/0 for Tx buffer empty/not empty 
ACIA_RX_FULL	EQU			bit3			; ACIA_STAT bit3 = 1/0 for Rx buffer full/not full 

ACIA_INIT: 
; *******S
	LDA		#$00			; load (any) value in A register 
	STA		ACIA_STAT		; and store it in Status Reg will reset the ACIA
	LDA		#%00010000		; 0=1stop/00=8bits/1=baudrate clk/1111=19200 or 0000=115200 baud
	STA		ACIA_CTRL		; configure ACIA settings: 115200 8N1 
	LDA		#%10001001		; 1x0=no parity                              / 0=no echo
							; 10=Tx on, no Tx interr / 0=Rx IRQB enabled / 1=Rx on 
							; bit7 is set as a requirement for Wozmon
	STA		ACIA_CMD		; ACIA initialized and ready to Rx/Tx 
	RTS
; *******E

ECHO:					
; *******S
	PHA						; save accu (i.e. char to send) on stack 
		AND #$7F			; remove bit7 
		STA ACIA_DATA		; put char in Tx buffer (will trigger sending) 
							; in WDC65C51 chips, the "Tx buffer empty" doesnt work 
							; and a software delay has to be implemented 
?tx_wait: 
		LDA ACIA_STAT		; check ACIA_STAT for "Tx buffer empty" 
		AND #ACIA_TX_EMPTY	; "Tx empty" means "bit4=1" so "AND" returns Z=1
		BEQ ?tx_wait		; loopback since "Tx not empty" 
	PLA						; restore accu 
	RTS                    	; Return.
; *******E 

CONSOLE_BOOT_MSG: 		
; *******S
	PHA						; save the accu value on ToS 
	PHX
		LDA #ESC			; clear console 
		JSR ECHO  	
		LDA #'['			; "ESC [ 2 J" is CLS in VT100 
		JSR ECHO 	
		LDA #'2'			; 
		JSR ECHO 	
		LDA #'J'			; 
		JSR ECHO 	
		LDA #ESC			; move cursor to topleft corner  
		JSR ECHO 	
		LDA #'['			; "ESC [ H" is HOME in VT100 
		JSR ECHO 	
		LDA #'H'			; 
		JSR ECHO 	
		LDX #$0				; init index 
?nextchar:
		LDA MSG_HDR_SCR,X	; load indexed char in accu
		BEQ ?skip		 	; if null char found, skip 
		STA ACIA_DATA		; put char to send in Tx buffer 
?tx_wait: 
		LDA ACIA_STAT		; check for (bit4)=1 which means "Tx buffer empty" 
		AND #ACIA_TX_EMPTY	; "Tx not empty" means "bit4=0" so "AND" returns Z=1
		BEQ ?tx_wait		; loopback if "Tx buffer not empty" 
		INX					; advance index 
		JMP ?nextchar		; next char 
?skip: 
		LDX #$0				; init index 
?nextchar1:
		LDA MSG_WELC_SCR,X	; load indexed char in accu
		BEQ ?null_found		; if null char found, skip the rest 
		STA ACIA_DATA		; put char to send in Tx buffer 
?tx_wait1: 
		LDA ACIA_STAT		; check for (bit4)=1 which means "Tx buffer empty" 
		AND #ACIA_TX_EMPTY	; "Tx not empty" means "bit4=0" so "AND" returns Z=1
		BEQ ?tx_wait1		; loopback if "Tx buffer not empty" 
		INX					; advance index 
		JMP ?nextchar1		; next char 
?null_found: 
		PLX				; restore index X register 
		PLA				; restore the accu 
		RTS
; *******E 

VERSION 	macro
; *******S
				.byte '1'
				.byte '.'
				.byte '0'					; software version 
				endm
; *******E

; strings for console messages
; *******S  
MSG_HDR_SCR		.byte '   +-----------------------------------------+', 'CR', 'LF'	; 46+2=48
				.byte '   |   '												; +7=55
				.byte ESC, '[', '5', 'm'									; +4=59
				.byte        '  Welcome to Ben Eaters WDC65C02   '			; +35=94
				.byte ESC, '[', 'm'											; +4=98
				.byte '   |', 'CR', 'LF'									; +4+2=104
				.byte '   +-----------------------------------------+', 'CR', 'LF'	; +46+2=152
				.byte 'CR', 'LF', 'NL' 										; +3=155
MSG_WELC_SCR	.byte 'H/W by WDC and S/W by Steve Wozniak.', 'CR', 'LF'	; 36+2=38
				.byte 'Adapted by DMA.', 'CR', 'LF'							; +15+2=55
				.byte 'Software version: '									; +18=73
				VERSION
				.byte ', compiled: '										; +3+12=88
				DATE
				.byte 'CR', 'LF', 'CR', 'LF'								; +21+2=113
				.byte '<addr>[.<addr>]<CR> to display <addr>', 'CR', 'LF'	; +37+2=152
				.byte '<addr>:<val>[<val>]<CR> to store value(s) @ <addr>', 'CR', 'LF' ; +50+2=210
				.byte '<addr> R<CR> to run code starting at <addr>', 'CR', 'LF', 'CR', 'LF', 'NL' ; +43+3=252
; *******E 