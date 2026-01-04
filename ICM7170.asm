ICM7170_ASM_INCLUDED EQU 1

	IFNDEF LCD_ASM_INCLUDED
	INCLUDE LCD.ASM
	ENDIF 

; ICM7170 Real Time Clock - DIP24 pin-out
;*******S
;
;      +------U------+
;  WRB | 1        24 | RDB 
;  ALE | 2        23 | VDD (5V)
;  CSB | 3        22 | D7
;   A4 | 4        21 | D6
;   A3 | 5        20 | D5
;   A2 | 6        19 | D4
;   A1 | 7        18 | D3
;   A0 | 8        17 | D2
; OscO | 9        16 | D1
; OscI |10        15 | D0
; ISrc |11        14 | Vbackup
; INTB |12        13 | VSS (GND) 
;      +-------------+
;
; Connections to 65C02 SBC system: 
;    A4..A0 : address bus bits A0..A4 
;    D7..D0 : data bus bits D7..D0 
;    RDB/WRB: 
;    ALE    : 5V (for non-multiplexed buses) 
;    CSB    : 
;    OscO/OscI: crystal with caps (32KHz, 1.048576MHz (2^20), 2.097152MHz (2^21), 4.194304MHz (2^22)) 
;    ISrc   : GND
;    INTB   : interrupt output pin  
;    VSS/VDD: GND/5V
;    Vbackup: CR2032 coin battery
;*******E

; RTC register definitions 
;*******S
RTC_BASE      EQU  $7000
RTC_SEC100    EQU  (RTC_BASE)        	  ; 0..99
RTC_HRS       EQU  (RTC_BASE+$01)        ; 1..12 (+80 for PM) or 0..23
RTC_MINS      EQU  (RTC_BASE+$02)        ; 0..59
RTC_SECS      EQU  (RTC_BASE+$03)        ; 0..59
RTC_MON       EQU  (RTC_BASE+$04)        ; 1..12
RTC_DOM       EQU  (RTC_BASE+$05)        ; 1..31
RTC_YEAR      EQU  (RTC_BASE+$06)        ; 0..99
RTC_DOW       EQU  (RTC_BASE+$07)        ; 0..6 (Sun..Sat)
RTC_IR        EQU  (RTC_BASE+$10)        ; Interrupt Status and Mask Register 
RTC_CR        EQU  (RTC_BASE+$11)        ; Command Register 

; RTC Interrupt Status and Mask Register definitions 
; bits6 and 7 of RTC_ISMR are not used 
RTC_IR_TEST       EQU  (bit5)          ; 0 = normal mode / 1 = test mode 
RTC_IR_IE         EQU  (bit4)          ; 0 = interrupt disable / 1 = interr enable 
RTC_IR_RUN        EQU  (bit3)          ; 0 = stop mode / 1 = run mode 
RTC_IR_24HR       EQU  (bit2)          ; 0 = 12 hr mode / 1 = 24 hr mode 
RTC_IR_4MHZ       EQU  (bit1|bit0)     ; 11 = 4 MHz
RTC_IR_2MHz       EQU  (bit1)          ; 10 = 2 MHz 
RTC_IR_1MHz       EQU  (bit0)          ; 01 = 1 MHz
RTC_IR_32K        EQU  ($0)            ; 00 = 32 KHz 

; RTC command register definitions
; bit7 of RTC Cmd Register is not used
RTC_CR_1DAYINT    EQU  (bit6)
RTC_CR_1HOURINT   EQU  (bit5)
RTC_CR_1MININT    EQU  (bit4)
RTC_CR_1SECINT    EQU  (bit3)
RTC_CR_SEC10INT   EQU  (bit2)
RTC_CR_SEC100INT  EQU  (bit1)
RTC_CR_ALARMINT   EQU  (bit0)

; Memory locations in RAM to save/store time 
; This allows any application to access date and time  
TIME_MEM_LOC     EQU   $7000
TIME_CURR_HRS    EQU   (TIME_MEM_LOC)      ; 1..12 or 0..23
TIME_CURR_MINS   EQU   (TIME_MEM_LOC+1)    ; 0..59
TIME_CURR_SECS   EQU   (TIME_MEM_LOC+2)    ; 0..59
TIME_CURR_MON    EQU   (TIME_MEM_LOC+3)    ; 1..12
TIME_CURR_DOM    EQU   (TIME_MEM_LOC+4)    ; 1..31
TIME_CURR_YEAR   EQU   (TIME_MEM_LOC+5)    ; 0..99
TIME_CURR_DOW    EQU   (TIME_MEM_LOC+6)    ; 0..6 
;*******E

;*******S
; DayOfWeek_CALCULATION: 
  ; // calculate DoW when given a day/month/year using the Tomohiko Sakamoto's algorithm 
  ; // Input ranges: day=1..31; month=1..12; year=20xx
  ; // Return range: Sun=0/Mon=1/Tue=2/Wed=3/Thu=4/Fri=5/Sat=6 
  ; static const int offset[] = {0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4};
  ; year -= month < 3;  //(if month<3 then year=year-1
  ; return (year + year / 4 - year / 100 + year / 400 + offset[month - 1] + day) % 7;
  ; Example: Jan 1, 2026: 
  ; 2025 + 2025/4 - 2025/100 + 2025/400 = 2025 + 506 - 20 + 5 = 2516 
  ; offset[0] = 0
  ; day = 1 
  ; (2516 + 0 + 1) % 7 = 4 --> Thu 
  ; RTS
;*******E

; RTC subroutines 
RTC_INIT: 
;*******S
	RTS
;*******E

RTC_READ_TIME:
;*******S
	PHA                       ; save A register on stack 
		LDA  #$0
		STA  RTC_SEC100           ; latch internal time registers 
		LDA  RTC_HRS
		STA  TIME_CURR_HRS        ; update hrs in RAM mem loc
		LDA  RTC_MINS
		STA  TIME_CURR_MINS       ; update mins in RAM mem loc
		LDA  RTC_SECS
		STA  TIME_CURR_SECS       ; update secs in RAM mem loc
		LDA  RTC_MON
		STA  TIME_CURR_MON        ; update month in RAM mem loc
		LDA  RTC_DOM
		STA  TIME_CURR_DOM        ; update day of month in RAM mem loc
		LDA  RTC_YEAR
		STA  TIME_CURR_YEAR       ; update year in RAM mem loc
		LDA  RTC_DOW
		STA  TIME_CURR_DOW        ; update day of week in RAM mem loc
	PLA                       ; restore A register on stack 
	RTS
;*******E

RTC_SET_TIME:
;*******S
	RTS
;*******E

RTC_SECDIV100_INT:
;*******S
	PHA
		LDA #$00                ; write $00 to IR
		STA RTC_IR              ; to clear all interrupts
		LDA #RTC_CR             ; get current Interr Reg bits
		ORA #(RTC_IR_IE|RTC_IR_RUN) ; set Interr En and RTC Run bits 
		STA RTC_CR              ; set new command register bits 
		LDA #(RTC_CR_SEC100INT) ; turn 0.01 sec interrupts on 
		STA RTC_IR              ; the INTB pin 
	PLA 
	RTS
;*******E

RTC_SECDIV10_INT:
;*******S
	PHA
		LDA #$00                ; write $00 to IR
		STA RTC_IR              ; to clear all interrupts
		LDA #RTC_CR             ; get current Interr Reg bits
		ORA #(RTC_IR_IE|RTC_IR_RUN) ; set Interr En and RTC Run bits 
		STA RTC_CR              ; set new command register bits 
		LDA #(RTC_CR_SEC10INT)  ; turn 0.1 sec interrupts on 
		STA RTC_IR              ; the INTB pin 
	PLA 
	RTS
;*******E

RTC_SEC_INT:
;*******S
	PHA
		LDA #$00                ; write $00 to IR
		STA RTC_IR              ; to clear all interrupts
		LDA #RTC_CR             ; get current Interr Reg bits
		ORA #(RTC_IR_IE|RTC_IR_RUN) ; set Interr En and RTC Run bits 
		STA RTC_CR              ; set new command register bits 
		LDA #(RTC_CR_1SECINT)   ; turn 1 sec interrupts on 
		STA RTC_IR              ; the INTB pin 
	PLA 
	RTS
;*******E

RTC_MIN_INT:
;*******S
	PHA
		LDA #$00                ; write $00 to IR
		STA RTC_IR              ; to clear all interrupts
		LDA #RTC_CR             ; get current Interr Reg bits
		ORA #(RTC_IR_IE|RTC_IR_RUN) ; set Interr En and RTC Run bits 
		STA RTC_CR              ; set new command register bits 
		LDA #(RTC_CR_1MININT)   ; turn daily interrupts on 
		STA RTC_IR              ; the INTB pin 
	PLA 
	RTS
;*******E

RTC_HR_INT:
;*******S
	PHA
		LDA #$00                ; write $00 to IR
		STA RTC_IR              ; to clear all interrupts
		LDA #RTC_CR             ; get current Interr Reg bits
		ORA #(RTC_IR_IE|RTC_IR_RUN) ; set Interr En and RTC Run bits 
		STA RTC_CR              ; set new command register bits 
		LDA #(RTC_CR_1HOURINT)  ; turn daily interrupts on 
		STA RTC_IR              ; the INTB pin 
	PLA 
	RTS
;*******E

RTC_DAY_INT:
;*******S
	PHA
		LDA #$00                ; write $00 to IR
		STA RTC_IR              ; to clear all interrupts
		LDA #RTC_CR             ; get current Interr Reg bits
		ORA #(RTC_IR_IE|RTC_IR_RUN) ; set Interr En and RTC Run bits 
		STA RTC_CR              ; set new command register bits 
		LDA #(RTC_CR_1DAYINT)   ; turn daily interrupts on 
		STA RTC_IR              ; the INTB pin 
	PLA 
	RTS
;*******E

RTC_TIME_TO_LCD:
;*******S
	PHA
		LDA #$00                ; col 0
		LDX #$01                ; row 1 (2nd line) 
		JSR LCD_SET_CUR_POS     ; go to first char of 2nd line 
		LDA TIME_CURR_HRS       ; get current hour (1..12 or 0..23) 
		PHA                     ; push current hours on stack 
			LSR
			LSR
			LSR
			LSR
			CLC
			ADC #$41              ; convert to ASCII
			JSR LCD_SEND_CHAR     ; write tens hrs 
		PLA                     ; get current hours again (from stack) 
		AND $0F                 ; mask low nibble (ones hrs)
		CLC
		ADC #$41                ; convert to ASCII
		JSR LCD_SEND_CHAR       ; write units hrs 
		LDA #':'
		JSR LCD_SEND_CHAR       ; separating ':' 
		LDA TIME_CURR_MINS      ; get current mins (0..59) 
		PHA                     ; push current mins on stack 
			LSR
			LSR
			LSR
			LSR
			CLC
			ADC #$41              ; convert to ASCII
			JSR LCD_SEND_CHAR     ; write tens mins 
		PLA                     ; get current mins back again (from stack)
		AND $0F                 ; mask low nibble (ones mins)
		CLC
		ADC #$41                ; convert to ASCII
		JSR LCD_SEND_CHAR       ; write units mins 
		LDA #':'
		JSR LCD_SEND_CHAR       ; separating ':' 
		LDA TIME_CURR_SECS      ; get current secs (0..59) 
		PHA                     ; push current secs on stack 
			LSR
			LSR
			LSR
			LSR
			CLC
			ADC #$41              ; convert to ASCII
			JSR LCD_SEND_CHAR     ; write tens secs 
		PLA                     ; get current secs back again (from stack) 
		AND $0F                 ; mask low nibble (ones secs) 
		CLC
		ADC #$41                ; convert to ASCII
		JSR LCD_SEND_CHAR       ; write units secs
	PLA
	RTS
;*******E

;*******S
; int day_of_week(int day, int month, int year) {
  ; // calculate DoW when given a day/month/year using the Tomohiko Sakamoto's algorithm 
  ; // Input ranges: day=1..31; month=1..12; year=20xx
  ; // Return range: Sun=0..Sat=6 
  ; static const int offset[] = {0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4};
  ; year -= month < 3;
  ; return (year + year / 4 - year / 100 + year / 400 + offset[month - 1] + day) % 7;
; }

; void setup() {
  ; pinMode(RTC_WRB_PIN, OUTPUT);                           // Set control pins
  ; digitalWrite(RTC_WRB_PIN, HIGH);  
  ; pinMode(RTC_RDB_PIN, OUTPUT);  
  ; digitalWrite(RTC_RDB_PIN, HIGH);
  ; RTC_ADDR_DDR = 0xFF;    RTC_ADDR_PORT = 0;              // Address port as output
  ; RTC_DATA_DDR = 0xFF;    RTC_DATA_PORT = 0;              // Data port as output (ready for writes)
  ; pinMode(RTC_XTAL_PWR, OUTPUT);                          // Supply Vdd to xtal daughterboard 
  ; digitalWrite(RTC_XTAL_PWR, HIGH);                       // turn on its power 
  ; Serial.begin(115200);                                   // Begin serial for debug
  ; delay(100);                                 
  ; //
  ; RTC_Set_Time();
  ; // ISR for RTC INTB pin output, connected to Mega RTC_IRQB_PIN 
  ; state = 0; 
  ; pinMode(RTC_IRQB_PIN, INPUT_PULLUP);                    // RTC produces active low interrupts 
  ; pinMode(IRQ_LED, OUTPUT);                               // to drive LED indicating interrupt is received 
  ; attachInterrupt(digitalPinToInterrupt(RTC_IRQB_PIN), RTC_IRQB_ISR, FALLING);    // ISR for RTC interrupts 
  ; interrupts();                                           // enable interrupts 
  ; // setup RTC for INTB output for periodic interrupts 
  ; writeRegister(RTC_ISMR, 0x00);                          // clear all interrupts 
  ; writeRegister(RTC_CMD_REG, 0b00011111);                 // 00/norm=0/int en=1/run=1/24 hr mode=1/32k-1M-2M-4M=00..11 
  ; writeRegister(RTC_ISMR, 0x04);                          // turn on 1 sec periodic interrupt bit
; }

; void RTC_Set_Time(void) {
    ; // initialize RTC using __DATE__ and __TIME__ compiler variables 
  ; writeRegister(RTC_CMD_REG, 0b00000111);                 // halt clock / 00/norm=0/int dis=0/stop=0/24 hr mode=1/32k-1M-2M-4M=00..11
  ; int hrs = 0;  int mins = 0;   int secs = 0;             // temp storage vars 
  ; sscanf(__TIME__, "%d:%d:%d", &hrs, &mins, &secs);       // __TIME__ is compile time (format is "09:36:13")
  ; writeRegister(RTC_HRS,  hrs);                           // hrs (1..12 or 0..23)
  ; writeRegister(RTC_MINS, mins);                          // mins (0..59)
  ; writeRegister(RTC_SECS, secs+6);                        // secs (0..59) - +6 to account for upload delay 
  ; int date = 0; char mon[12];   int year = 0;             // temp storage 
  ; sscanf(__DATE__, "%s %d %d", mon, &date, &year);        // __DATE__ is compile date (format is "Dec 23 2025")
  ; int monIdx;                                             // index into MoY array 
  ; for (monIdx = 1; monIdx<13; monIdx++) {                 // cycle through months 1..12
    ; if (strcmp(mon, MoY[monIdx]) == 0)                    // if month name matches 
    ; break;                                                // exit loop, preserving monIdx  
  ; }
  ; writeRegister(RTC_MON,  monIdx);                        // month as number (1..12) 
  ; writeRegister(RTC_DOM,  date);                          // DoM (1..31) 
  ; writeRegister(RTC_YEAR, year-2000);                     // subtract 2000 as RTC is 2000-based 
  ; int dow = 0; 
  ; dow = day_of_week(date, monIdx, year);                  // find DoW using the __DATE__ info (Sun=0..Sat=6) 
  ; writeRegister(RTC_DOW,  dow);                           // DoW (0..6) 
  ; writeRegister(RTC_CMD_REG, 0b00011111);                 // activate clock - 00/norm=0/int en=1/run=1/24 hr mode=1/32k-1M-2M-4M=00..11 
; }
;*******E
