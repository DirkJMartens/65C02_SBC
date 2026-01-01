; EQUs for the 2x16 LCD display 
; *******S
; *******************************************************************************
; 2 rows x 16 columns LCD - used in 4 bit mode 
; // *******************************************************************************
; LCD definitions
LCD_RS  		EQU 	%01000000	; bit 6 = enable pin = 1 to start data read/write 
LCD_RWB 		EQU 	%00100000	; bit 5 = read/write 
LCD_EX 			EQU 	%00010000	; bit 4 = register select 
									; bit 3..0 = 4 databits connected to LCD DB4..DB7 
LCD_CLS			EQU 	%00000001	; lcd function to clear screen 
LCD_HOME		EQU 	%00000010	; lcd function to return cursor to topleft position 
LCD_ENTRY_MODE	EQU 	%00000100	; lcd function to set cursor direction and display shift 
LCD_DISPL_MODE 	EQU 	%00001000	; lcd function to turn display/cursor/blinking on/off 
LCD_FUNC_SET	EQU 	%00100000	; lcd function to set data length, display lines and font 
LCD_SET_CGRAM	EQU 	%01000000	; lcd function to set char generator RAM address 
LCD_SET_DDRAM	EQU 	%10000000	; lcd function to set data display RAM address 
LCD_NEXT_ROW	EQU 	%01000000	; on a 16x2 lcd, every line has addr multiple of $40 
LCD_TWO_LINES	EQU		%00001000	; bit3 set for 2 lines, clear for 1 line 
LCD_INCR		EQU 	%00000010	; bit1 set for auto-incr position 
LCD_DISPL		EQU 	%00000100	; bit2 set for display on, clear for display off
LCD_CURSOR		EQU 	%00000010	; bit1 set for cursor on, clear for cursor off
LCD_BLINK		EQU 	%00000001	; bit0 set for blinking cursor on, clear for off 	
; *******E

; SUBROUTINES FOR LCD 
; *******S 
; Instructions: 
;
; LCD_RWB:   1 = read ; 0 = write 
; LCD_RS :   for read:  0 : busy flag + addr counter 
                      ; 1 : data register 
          ; for write: 0 : instruction register 
                      ; 1 : data register 
; With RS=0 and R/W=0: (i.e. use instruction register and "write" to LCD)
  ; Clear display:      0000 0001
  ; Return Home:        0000 001*
  ; Entry Mode Set:     0000 01IS : I=1/0=incr/decr; S=1/0=displ shift on/off
  ; Display On/Off:     0000 1DCB : D:display on/off; C:cursor on/off; B:blink on/off
  ; Cursor/display shift:   0001 SR** : S=1/0=display/cursor shift; R=1/0=shift right/left 
  ; Function Set:       001D NF** : D=1/0=8/4 bit; N=1/0=2/1 lines; F=1/0=5x10/5x8 font 
  ; Set CGRAM address:  01AA AAAA : data=AAAAAA
  ; Set DDRAM address:  1AAA AAAA : data=AAAAAAA 

; With RS=0 and R/W=1: (i.e. use instruction register and "read" from LCD) 
  ; Read busy flag&addr:    BAAA AAAA : B=1/0=busy/ready; AAAAAAA=address counter 

; With RS=1 and R/W=0: (i.e. use data register and "write" to LCD) 
  ; Write data to CG/DDRAM: **** **** : data=******** 

; With RS=1 and R/W=1: (i.e. use data register and "read" data)
  ; Read data to CG/DDRAM:  **** **** : data=********  

; 4bit interface initialization: 
  ; After power-on, LCD defaults to 8-bit operation.
  ; and we need to change it to 4-bit operation. 
  ; Since only the high nibble of the LCD's DBx pins are 
  ; physically connected, passing 8 bits requires executing 
  ; the instruction twice, once with the high nibble payload 
  ; and then with the low nibble 
  ; Each time a payload is sent, we need to cycle the E flag, 
  ; so we need to first send with E=0, then E=1 and then again E=0. 
  ; Before proceding to the next instruction, we need to test the 
  ; busy flag is cleared, indicating the instruction was completed. 2
*******E  

LCD_CLEAR_SCREEN:		
; *******S
	PHA					; save the accu 
		; "Clear display" (0000 0001)  
		LDA #LCD_CLS 			
		JSR INSTR_TO_LCD		; instr_to_lcd includes wait for lcd ready 
	PLA					; restore the accu 
	RTS
; *******E

LCD_SET_CUR_POS:		
; *******S
	PHA
		; For a 2x16 LCD, DDRAM address of toprow starts at $00 and of bottomrow starts at $40 
		; x-pos (col 0..15) must be passed in X register (X register: %0000cccc) 
		; y-pos (row 0..1) must be passed in Y register (Y register: %0000000r)
		; lcd position AAAAAAA is set using LCD_SET_DDRAM with instruction %1AAAAAAA 
	PHY
	PHX
		TXA					; accu is now %0000cccc 
		CPY #bit0			; Z=1 for row=1 
		BNE ?dontadd40		; no, it is not 
		CLC					; yes it is, so clear carry 
		ADC #LCD_NEXT_ROW	; so we can add $40 for row 1 
?dontadd40: 
		ADC #bit7			; set top bit to form LCD_SET_DDRAM instruction 
		JSR INSTR_TO_LCD	; send %1r00cccc with RS=RW=0 to lcd 
	PLX
	PLY
	PLA
	RTS
; *******E

LCD_GOTO_HOME_POS: 		
; *******S
	PHA
		; "return home" (0000 001*)  
		LDA #LCD_HOME 
		JSR INSTR_TO_LCD
	PLA
	RTS
; *******E

CHECK_FOR_LCD_READY:	
; *******S
	PHA			; push accu on stack 
		LDA #%11110000  	; high nibble outputs (0/E/RW/RS)
		STA VIA_DDRB		; low nibble inputs (to read status) 
?lcdbusy:
		; When RS = 0 and R/W = 1, the busy flag is output to DB7 (bit B3). 
		; The next instruction must be written after ensuring that the busy flag is 0.
		LDA #LCD_RWB		; output 0/E=0/RW=1/RS=0 
		STA VIA_PORTB		; sets the "read busy flag" instruction 
		EOR #LCD_EX 		; tell lcd to execute instruction 
		STA VIA_PORTB		; 
							; updated busy flag now in DB7 and addr counter in DB6..0 
							; since we need to read the data register in nibbles, we need two reads 
		LDA VIA_PORTB       ; 1st read: high nibble
		PHA             	; put on ToS since low nibble will overwrite accu and busy flag is in high nibble
			LDA #LCD_RWB 	; output 0/E=0/RW=1/RS=0
			STA VIA_PORTB	; i.e. "read busy flag" 
			EOR #LCD_EX  	; execute 
			STA VIA_PORTB	; 
			LDA VIA_PORTB   ; 2nd read: low nibble 
							; we are not interested in the addr counter, so we ignore the low nibble 
		PLA             	; Restore high nibble (with the busy flag status) into accu 
		AND #bit3			; if bit3=1 (lcd=busy), AND returns 1 and Z=0 
		BNE ?lcdbusy		; loopback if Z=0. if not, lcd is ready for next instruction  
		LDA #LCD_RWB 		; output 0/E=0/RW=1/RS=0 
		STA VIA_PORTB		; 
		LDA #%11111111  	; set all pins to output again 
		STA VIA_DDRB		; 
	PLA			; restore orig accu 
	RTS
; *******E

CHAR_TO_LCD:			
; *******S
	; accu should contain 8-bit code to send to lcd 
	; LCD instruction needs RW=0 and RS=1 
	PHA
	PHX
		PHA			
			; 8 bit char (hhhhllll) to print is in accu, save it on ToS 
			; high nibble 
			LSR
			LSR
			LSR
			LSR					; accu now 0000hhhh 
			ORA #LCD_RS  		; set RS: 0/E=0/RW=0/RS=1  
			STA VIA_PORTB		; accu now 0001hhhh
			ORA #LCD_EX  		; set E: 0/E=1/RW=0/RS=1  
			STA VIA_PORTB		; accu now 0101hhhh
			EOR #LCD_EX  		; reset E: 0/E=0/RW=0/RS=1 
			STA VIA_PORTB		; accu now 0001hhhh again
			; low nibble 
		PLA					; char to print is still on ToS so pull it into accu  
		AND #%00001111		; retain low nibble 0000llll
		ORA #LCD_RS  		; set RS: 0/E=0/RW=0/RS=1
		STA VIA_PORTB		; accu now 0001llll
		ORA #LCD_EX  		; set E: 0/E=1/RW=0/RS=1  
		STA VIA_PORTB		; accu now 0101llll
		EOR #LCD_EX			; reset E: 0/E=0/RW=0/RS=1 
		STA VIA_PORTB		; accu now 0001llll again 
		JSR CHECK_FOR_LCD_READY
	PLX
	PLA
	RTS
; *******E

INSTR_TO_LCD:			
; *******S
	; accu should contain 8-bit code to send to lcd 
	; LCD instruction needs RW=0 and RS=0 
	PHA
		PHA			
			; 8 bit char (hhhhllll) to print is in accu, save it on ToS 
			; high nibble 
			LSR
			LSR
			LSR
			LSR					; accu now 0000hhhh 
			STA VIA_PORTB		; accu now 0001hhhh
			ORA #LCD_EX  		; set E: 0/E=1/RW=0/RS=0  
			STA VIA_PORTB		; accu now 0101hhhh
			EOR #LCD_EX  		; reset E: 0/E=0/RW=0/RS=0 
			STA VIA_PORTB		; accu now 0001hhhh again
			; low nibble 
		PLA					; char to print is still on ToS so pull it into accu  
		AND #%00001111		; retain low nibble 0000llll
		STA VIA_PORTB		; accu now 0001llll
		ORA #LCD_EX  		; set E: 0/E=1/RW=0/RS=0  
		STA VIA_PORTB		; accu now 0101llll
		EOR #LCD_EX 		; reset E: 0/E=0/RW=0/RS=0 
		STA VIA_PORTB		; accu now 0001llll again 
		JSR CHECK_FOR_LCD_READY
	PLA
	RTS
; *******E

LCD_INIT: 				
; *******S
	PHA				; save A register status 
		; "Function set" (001D NF**) with D=0 (4 bit), N=1 (2 lines), F=0 (5x8 font) 
		LDA #LCD_FUNC_SET
		ORA #LCD_TWO_LINES		; set D=0, N=1, F=0 
		JSR INSTR_TO_LCD 
		
		; "Entry mode set" (0000 01IS) with I=1 (incr), S=0 (displ shift off) 
		LDA #LCD_ENTRY_MODE 
		ORA #LCD_INCR 			; set I=1; S=0
		JSR INSTR_TO_LCD
		
		; "Display on/off control" (0000 1DCB) with D=1 (display on), C=1 (cursor on), B=1 (blink on)  
		LDA #LCD_DISPL_MODE						; 
		ORA #(LCD_DISPL|LCD_CURSOR|LCD_BLINK)	; set display,cursor and blinking on 
		JSR INSTR_TO_LCD 
		
		JSR LCD_CLEAR_SCREEN	; clear the LCD screen 
		
		JSR LCD_GOTO_HOME_POS	; goto topleft of lcd 
	PLA				; restore A register 
	RTS  
; *******E

LCD_BOOT_MSG: 			
; *******S
	PHA
	PHX
	PHY 
		JSR LCD_CLEAR_SCREEN	; clear lcd screen 
		JSR LCD_GOTO_HOME_POS	; cursor topleft corner 
		LDX #$0 				; reset index register 
?next_char1: 
		LDA MESSAGE1,X			; load indexed char in accu 
		BEQ ?done1 				; if char is null (Z=1) then end 
		JSR CHAR_TO_LCD 		; if char is not null, print on LCD
		INX 					; inc index 
		JMP ?next_char1			; next char 
?done1:
		LDX #$0 				; column position
		LDY #$1					; row position 
		JSR LCD_SET_CUR_POS
		LDX #$0 				; reset index register 
?next_char: 
		LDA MESSAGE3,X			; load indexed char in accu 
		BEQ ?done 				; if char is null (Z=1) then end 
		JSR CHAR_TO_LCD 		; if char is not null, print on LCD
		INX 					; inc index 
		JMP ?next_char			; next char 
?done:
	PLY 
	PLX 
	PLA 
	RTS 
; *******E

DATE_TO_LCD: 			
; *******S
	PHA
	PHX
		JSR LCD_CLEAR_SCREEN	; clear lcd screen 
		JSR LCD_GOTO_HOME_POS	; cursor to lcd topleft 
		LDX #$0 				; init index register 
?next_char: 
		LDA MESSAGE3,X		; add index and load in accu 
		BEQ ?done 			; if char is null (Z=1) then end 
		JSR CHAR_TO_LCD 	; if char is not null, print on LCD
		INX 				; inc index 
		JMP ?next_char		; next char 
?done:
	PLX 
	PLA
	RTS 
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

