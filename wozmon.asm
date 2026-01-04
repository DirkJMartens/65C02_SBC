; ************************************************************************************************
; *                                                                                              *
; *  WOZMON Monitor software for the 65C02 SBC                                                   *
; *                                                                                              *
; *  Uses a $FF-byte buffer to store the commands entered via the serial port                    *
; *                                                                                              *
; *                                                                                              *
; *                                                                                              *
; ************************************************************************************************

WOZMON_ASM_INCLUDED	EQU 1

	IFNDEF UM6551_ASM_INCLUDED
	INCLUDE UM6551.ASM					; using the ACIA for console input/output
	ENDIF 

IN			 	EQU $200               	; Circular input command buffer ($FF long) 
RD_PTR			EQU $01					; Addr location to keep track of buffer read_pointer 
WR_PTR			EQU	$02					; Addr location to keep track of buffer write_pointer 

; Zeropage variables 
XAML            EQU $24               	; Last "opened" location Low
XAMH            EQU $25               	; Last "opened" location High
STL             EQU $26               	; Store address Low
STH             EQU $27               	; Store address High
L               EQU $28               	; Hex value parsing Low
H               EQU $29               	; Hex value parsing High
YSAV            EQU $2A               	; Used to see if hex value is given
MODE            EQU $2B               	; $00=XAM, $7F=STOR, $AE=BLOCK XAM

WOZMON: SECTION 
;-------------------------------------------------------------------------
;  Let's get started
;
;  Remark the RESET routine is only to be entered by asserting the RESET
;  line of the system. This ensures that the data direction registers
;  are selected.
;-------------------------------------------------------------------------
WOZ_RESET:      
	LDA RD_PTR		; Read whatever value is in read pointer and save 
	STA WR_PTR		; it to write pointer, now ensuring they are the same. 
	LDY #$8B		; bit7 of Y register MUST be set 
	LDA	#$1B		; init A with ESC to ensure fall thru to ESCAPE: 
; Program falls through to the GETLINE routine to save some program bytes
; Please note that Y still holds $7F, which will cause an automatic Escape
;-------------------------------------------------------------------------
; The GETLINE process
;-------------------------------------------------------------------------
NOTCR:          
	CMP #BS    		; BS? ($08) 
	BEQ BACKSPACE   ; Yes.
	CMP #ESC		; ESC? ($1B)
	BEQ ESCAPE      ; Yes.
	INY             ; Advance text index. After init, $8B becomes $8C 
	BPL NEXTCHAR    ; If > 127, start processing  
ESCAPE:         
	LDA #PROMPT 	; "\"
	JSR ECHO_CHR    ; Output it.
GETLINE:        
	LDA #CR	    	; CR ($0D) 
	JSR ECHO_CHR    ; Output it.
	LDA #LF	    	; LF ($0A) 
	JSR ECHO_CHR    ; Output it.
	LDY #$01        ; Initialize text index.
BACKSPACE:      
	DEY             ; Back up text index.
	BMI GETLINE     ; Beyond start of line, reinitialize to $01.
NEXTCHAR:       
	LDA ACIA_STAT   ; Check if RX full?
	AND #ACIA_RX_FULL
	BEQ NEXTCHAR    ; if not, no char typed, so loop back 
	LDA ACIA_DATA   ; char typed, Load character code in A reg.
	STA IN,Y        ; Add char to text buffer.
	JSR ECHO_CHR    ; Display it 
	CMP #CR    		; CR?
	BNE NOTCR       ; No, so not EoL yet, so loop back.
; EoL received, now let's parse it 
	LDY #$FF        ; Reset text index.
	LDA #$00        ; Default to XAM mode.
	TAX             ; 0->X.
SETBLOCK: 
	ASL
SETSTOR:
	ASL             ; Leaves $7B if setting STOR mode.
SETMODE:
	STA MODE        ; $00=XAM, $7B=STOR(=%01111011), $AE=BLOCK XAM(%10011110).
BLSKIP:         
	INY             ; Advance text index.
NEXTITEM:       
	LDA IN,Y        ; Get character.
	CMP #CR	    	; CR?
	BEQ GETLINE     ; Yes, EoL, so done this line.
	CMP #'.'        ; "."? ($2E=%00101110) XAM mode 
	BCC BLSKIP      ; Skip delimiter.
	BEQ SETBLOCK    ; Set BLOCK XAM mode.
	CMP #':'        ; ":"? ($3A=%00111010) STOR mode 
	BEQ SETSTOR     ; Yes. Set STOR mode.
	CMP #'R'        ; "R"? ($52=%01010010) RUN mode 
	BEQ RUN         ; Yes. Run user program.
	STX L           ; $00->L.
	STX H           ;  and H.
	STY YSAV        ; Save Y for comparison.
; Here we're trying to parse a new hex value
NEXTHEX:        	
	LDA IN,Y        ; Get character for hex test.
	EOR #$30        ; Map digits to $0-9.
	CMP #$0A        ; Digit?
	BCC DIG         ; Yes.
	ADC #$88        ; Map letter "A"-"F" to $41-$46.
	CMP #$FA        ; Hex letter?
	BCC NOTHEX      ; No, character not hex.
DIG:            
	ASL
	ASL             ; Hex digit to MSD of A.
	ASL
	ASL
	LDX #$04        ; Shift count.
HEXSHIFT:       
	ASL             ; Hex digit left, MSB to carry.
	ROL L           ; Rotate into LSD.
	ROL H           ; Rotate into MSD’s.
	DEX             ; Done 4 shifts?
	BNE HEXSHIFT    ; No, loop.
	INY             ; Advance text index.
	BNE NEXTHEX     ; Always taken. Check next character for hex.
NOTHEX:         
	CPY YSAV        ; Check if L, H empty (no hex digits).
	BEQ ESCAPE      ; Yes, generate ESC sequence.
	BIT MODE        ; Test MODE byte.
	BVC NOTSTOR     ; B6=0 STOR, 1 for XAM and BLOCK XAM
; STOR mode, save LSD of new hex byte
	LDA L           ; LSD’s of hex data.
	STA (STL,X)     ; Store at current ‘store index’.
	INC STL         ; Increment store index.
	BNE NEXTITEM    ; Get next item. (no carry).
	INC STH         ; Add carry to ‘store index’ high order.
TONEXTITEM:     
	JMP NEXTITEM    ; Get next command item.
;-------------------------------------------------------------------------
;  RUN user's program from last opened location
;-------------------------------------------------------------------------
RUN:            
	JMP (XAML)      ; Run at current XAM index.
;-------------------------------------------------------------------------
;  We're not in Store mode
;-------------------------------------------------------------------------
NOTSTOR:        
	BMI XAMNEXT     ; B7=0 for XAM, 1 for BLOCK XAM.
	LDX #$02        ; Byte count.
; We're in XAM mode now
SETADR:         
	LDA L-1,X       ; Copy hex data to
	STA STL-1,X     ;  ‘store index’.
	STA XAML-1,X    ; And to ‘XAM index’.
	DEX             ; Next of 2 bytes.
	BNE SETADR      ; Loop unless X=0.
; Print address and data from this address, fall through next BNE.
NXTPRNT:        
	BNE PRDATA      ; NE means no address to print.
	LDA #CR	    	; CR.
	JSR ECHO_CHR    ; Output it.
	LDA #LF	    	; LF
	JSR ECHO_CHR    ; Output it.
	LDA XAMH        ; ‘Examine index’ high-order byte.
	JSR PRBYTE      ; Output it in hex format.
	LDA XAML        ; Low-order ‘examine index’ byte.
	JSR PRBYTE      ; Output it in hex format.
	LDA #':'    	; ":".
	JSR ECHO_CHR    ; Output it.
PRDATA:         
	LDA #' '        ; Space.
	JSR ECHO_CHR    ; Output it.
	LDA (XAML,X)    ; Get data byte at ‘examine index’.
	JSR PRBYTE      ; Output it in hex format.
XAMNEXT:        
	STX MODE        ; 0->MODE (XAM mode).
	LDA XAML
	CMP L           ; Compare ‘examine index’ to hex data.
	LDA XAMH
	SBC H
	BCS TONEXTITEM  ; Not less, so no more data to output.
	INC XAML
	BNE MOD8CHK     ; Increment ‘examine index’.
	INC XAMH
MOD8CHK:        
	LDA XAML        ; Check low-order ‘examine index’ byte
	AND #$07        ; For MOD 8=0
	BPL NXTPRNT     ; Always taken.
;-------------------------------------------------------------------------
;  Subroutine to print a byte in A in hex form (destructive)
;-------------------------------------------------------------------------
PRBYTE:         
	PHA             ; Save A for LSD.
	LSR
	LSR
	LSR             ; MSD to LSD position.
	LSR
	JSR PRHEX       ; Output hex digit.
	PLA             ; Restore A.
; Fall through to print hex routine

;-------------------------------------------------------------------------
;  Subroutine to print a hexadecimal digit
;-------------------------------------------------------------------------
PRHEX:          
	AND #$0F        ; Mask LSD for hex print.
	ORA #$30        ; Add "0".
	CMP #$3A        ; Digit?
	BCC ECHO_CHR    ; Yes, output it.
	ADC #$06        ; Add offset for letter.
; Fall through to print routine

;-------------------------------------------------------------------------
;  Subroutine to print a character to the terminal
;-------------------------------------------------------------------------
ECHO_CHR:       
	PHA						; save accu (i.e. char to send) on stack 
		STA ACIA_DATA		; put char in Tx buffer (will trigger sending) 
							; in WDC65C51 chips, the "Tx buffer empty" doesnt work 
							; and a software delay has to be implemented 
?tx_wait: 
		LDA ACIA_STAT		; check ACIA_STAT for "Tx buffer empty" 
		AND #ACIA_TX_EMPTY	; "Tx empty" means "bit4=1" so "AND" returns Z=1
		BEQ ?tx_wait		; loopback since "Tx not empty" 
	PLA						; restore accu 
	RTS             ; Return.
