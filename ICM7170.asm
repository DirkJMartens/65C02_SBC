;
; ICM7170 Real Time Clock - DIP24 pin-out
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

; RTC register definitions 
RTC_BASE      EQU  $
RTC_SEC100    EQU  (RTC_BASE     )        ; 0..99
RTC_HRS       EQU  (RTC_BASE+0x01)        ; 1..12 (+80 for PM) or 0..23
RTC_MINS      EQU  (RTC_BASE+0x02)        ; 0..59
RTC_SECS      EQU  (RTC_BASE+0x03)        ; 0..59
RTC_MON       EQU  (RTC_BASE+0x04)        ; 1..12
RTC_DoM       EQU  (RTC_BASE+0x05)        ; 1..31
RTC_YEAR      EQU  (RTC_BASE+0x06)        ; 0..99
RTC_DoW       EQU  (RTC_BASE+0x07)        ; 0..6 (Sun..Sat)
RTC_IR        EQU  (RTC_BASE+0x10)        ; Interrupt Status and Mask Register 
RTC_CR        EQU  (RTC_BASE+0x11)        ; Command Register 

; RTC Interrupt Status and Mask Register definitions 
; bits6 and 7 of RTC_ISMR are not used 
RTC_IR_TEST       EQU  (bit5)          ; 0 = normal mode / 1 = test mode 
RTC_IR_IE         EQU  (bit4)          ; 0 = interrupt disable / 1 = interr enable 
RTC_IR_RUN        EQU  (bit3)          ; 0 = stop mode / 1 = run mode 
RTC_IR_24HR       EQU  (bit2)          ; 0 = 12 hr mode / 1 = 24 hr mode 
RTC_IR_4MHZ       EQU  (bit1 | bit0)   ; 11 = 4 MHz
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
TIME_MEM_LOC     EQU   $
TIME_CURR_HRS    EQU   (RTC_MEM_LOC  )
TIME_CURR_MINS   EQU   (RTC_MEM_LOC+1)
TIME_CURR_SECS   EQU   (RTC_MEM_LOC+2)
TIME_CURR_MON    EQU   (RTC_MEM_LOC+3)
TIME_CURR_DOM    EQU   (RTC_MEM_LOC+4)
TIME_CURR_YEAR   EQU   (RTC_MEM_LOC+5)
TIME_CURR_DOW    EQU   (RTC_MEM_LOC+6)

; RTC subroutines 
RTC_INIT: 
  RTS

RTC_READ_TIME:
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

RTC_SET_TIME:
  RTS

RTC_SECDIV100_INT:
  RTS

RTC_SECDIV10_INT:
  PHA
    LDA #$00                ; write $00 to IR
    STA RTC_IR              ; to clear all interrupts
    LDA #RTC_CR             ; get current Interr Reg bits
    ORA #(RTC_IE | RTC_IR_RUN) ; set Interr En and RTC Run bits 
    STA RTC_CR              ; set new command register bits 
    LDA #(RTC_SEC10INT)     ; turn 0.1 sec interrupts on 
    STA RTC_IR              ; the INTB pin 
  PLA 
RTS

RTC_SEC_INT:
  PHA
    LDA #$00                ; write $00 to IR
    STA RTC_IR              ; to clear all interrupts
    LDA #RTC_CR             ; get current Interr Reg bits
    ORA #(RTC_IE | RTC_IR_RUN) ; set Interr En and RTC Run bits 
    STA RTC_CR              ; set new command register bits 
    LDA #(RTC_1SECINT)      ; turn 1 sec interrupts on 
    STA RTC_IR              ; the INTB pin 
  PLA 
RTS

RTC_MIN_INT:
  RTS

RTC_HR_INT:
  RTS

RTC_DAY_INT:
  RTS

RTC_TIME_TO_LCD:
  PHA
    LDA #$00                ; col 0
    LDX #$01                ; row 1 (2nd line) 
    LCD_SET_CUR_POS         ; go to first char of 2nd line 
    LDA TIME_CURR_HRS       ; get current hour (1..12 or 0..23) 
    PHA                     ; push current hours on stack 
    ASR
    ASR
    ASR
    ASR                     ; get high nibble (tens hrs) 
    CLC
    ADC #$41                ; convert to ASCII
    LCD_SEND_CHAR           ; write tens hrs 
    PLA                     ; get current hours again (from stack) 
    AND $0F                 ; mask low nibble (ones hrs)
    CLC
    ADC #$41                ; convert to ASCII
    LCD_SEND_CHAR           ; write units hrs 
    LDA #':'
    LCD_SEND_CHAR           ; separating ':' 
    LDA TIME_CURR_MINS      ; get current mins (0..59) 
    PHA                     ; push current mins on stack 
    ASR
    ASR
    ASR
    ASR                     ; get high nibble (mins hrs) 
    CLC
    ADC #$41                ; convert to ASCII
    LCD_SEND_CHAR           ; write tens mins 
    PLA                     ; get current mins back again (from stack)
    AND $0F                 ; mask low nibble (ones mins)
    CLC
    ADC #$41                ; convert to ASCII
    LCD_SEND_CHAR           ; write units mins 
    LDA #':'
    LCD_SEND_CHAR           ; separating ':' 
    LDA TIME_CURR_SECS      ; get current secs (0..59) 
    PHA                     ; push current secs on stack 
    ASR
    ASR
    ASR
    ASR                     ; get high nibble (tens secs) 
    CLC
    ADC #$41                ; convert to ASCII
    LCD_SEND_CHAR           ; write tens secs 
    PLA                     ; get current secs back again (from stack) 
    AND $0F                 ; mask low nibble (ones secs) 
    CLC
    ADC #$41                ; convert to ASCII
    LCD_SEND_CHAR           ; write units secs
  PLA
RTS

int day_of_week(int day, int month, int year) {
  // calculate DoW when given a day/month/year using the Tomohiko Sakamoto's algorithm 
  // Input ranges: day=1..31; month=1..12; year=20xx
  // Return range: Sun=0..Sat=6 
  static const int offset[] = {0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4};
  year -= month < 3;
  return (year + year / 4 - year / 100 + year / 400 + offset[month - 1] + day) % 7;
}

void setup() {
  pinMode(RTC_WRB_PIN, OUTPUT);                           // Set control pins
  digitalWrite(RTC_WRB_PIN, HIGH);  
  pinMode(RTC_RDB_PIN, OUTPUT);  
  digitalWrite(RTC_RDB_PIN, HIGH);
  RTC_ADDR_DDR = 0xFF;    RTC_ADDR_PORT = 0;              // Address port as output
  RTC_DATA_DDR = 0xFF;    RTC_DATA_PORT = 0;              // Data port as output (ready for writes)
  pinMode(RTC_XTAL_PWR, OUTPUT);                          // Supply Vdd to xtal daughterboard 
  digitalWrite(RTC_XTAL_PWR, HIGH);                       // turn on its power 
  Serial.begin(115200);                                   // Begin serial for debug
  delay(100);                                 
  //
  RTC_Set_Time();
  // ISR for RTC INTB pin output, connected to Mega RTC_IRQB_PIN 
  state = 0; 
  pinMode(RTC_IRQB_PIN, INPUT_PULLUP);                    // RTC produces active low interrupts 
  pinMode(IRQ_LED, OUTPUT);                               // to drive LED indicating interrupt is received 
  attachInterrupt(digitalPinToInterrupt(RTC_IRQB_PIN), RTC_IRQB_ISR, FALLING);    // ISR for RTC interrupts 
  interrupts();                                           // enable interrupts 
  // setup RTC for INTB output for periodic interrupts 
  writeRegister(RTC_ISMR, 0x00);                          // clear all interrupts 
  writeRegister(RTC_CMD_REG, 0b00011111);                 // 00/norm=0/int en=1/run=1/24 hr mode=1/32k-1M-2M-4M=00..11 
  writeRegister(RTC_ISMR, 0x04);                          // turn on 1 sec periodic interrupt bit
}

void RTC_Set_Time(void) {
    // initialize RTC using __DATE__ and __TIME__ compiler variables 
  writeRegister(RTC_CMD_REG, 0b00000111);                 // halt clock / 00/norm=0/int dis=0/stop=0/24 hr mode=1/32k-1M-2M-4M=00..11
  int hrs = 0;  int mins = 0;   int secs = 0;             // temp storage vars 
  sscanf(__TIME__, "%d:%d:%d", &hrs, &mins, &secs);       // __TIME__ is compile time (format is "09:36:13")
  writeRegister(RTC_HRS,  hrs);                           // hrs (1..12 or 0..23)
  writeRegister(RTC_MINS, mins);                          // mins (0..59)
  writeRegister(RTC_SECS, secs+6);                        // secs (0..59) - +6 to account for upload delay 
  int date = 0; char mon[12];   int year = 0;             // temp storage 
  sscanf(__DATE__, "%s %d %d", mon, &date, &year);        // __DATE__ is compile date (format is "Dec 23 2025")
  int monIdx;                                             // index into MoY array 
  for (monIdx = 1; monIdx<13; monIdx++) {                 // cycle through months 1..12
    if (strcmp(mon, MoY[monIdx]) == 0)                    // if month name matches 
    break;                                                // exit loop, preserving monIdx  
  }
  writeRegister(RTC_MON,  monIdx);                        // month as number (1..12) 
  writeRegister(RTC_DOM,  date);                          // DoM (1..31) 
  writeRegister(RTC_YEAR, year-2000);                     // subtract 2000 as RTC is 2000-based 
  int dow = 0; 
  dow = day_of_week(date, monIdx, year);                  // find DoW using the __DATE__ info (Sun=0..Sat=6) 
  writeRegister(RTC_DOW,  dow);                           // DoW (0..6) 
  writeRegister(RTC_CMD_REG, 0b00011111);                 // activate clock - 00/norm=0/int en=1/run=1/24 hr mode=1/32k-1M-2M-4M=00..11 
}

void RTC_Time_to_Serial(void) {
  readRegister(RTC_SEC100);                                         // latch time 
  Serial.print(DoW[readRegister (RTC_DOW)]);  Serial.print(" ");    // read DoW 
  Serial.print(MoY[readRegister (RTC_MON)]);  Serial.print(" ");    // read month
  Serial.print(readRegister (RTC_DOM));       Serial.print(", 20"); // read day of month
  Serial.print(readRegister (RTC_YEAR));      Serial.print("   ");  // read year
  Serial.print(readRegister (RTC_HRS));       Serial.print(":");    // read hrs 
  Serial.print(readRegister (RTC_MINS));      Serial.print(":");    // read mins
  Serial.print(readRegister (RTC_SECS));      Serial.println();     // read secs 
}
