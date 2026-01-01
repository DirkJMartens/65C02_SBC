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
  RTS

RTC_SEC_INT:
;  // setup RTC for INTB output for periodic 1 sec interrupts 
;  writeRegister(RTC_ISMR, 0x00);                          // clear all interrupts 
;  writeRegister(RTC_CMD_REG, 0b00011111);                 // 00/norm=0/int en=1/run=1/24 hr mode=1/32k-1M-2M-4M=00..11 
;  writeRegister(RTC_ISMR, 0x04);                          // turn on 1 sec periodic interrupt bit
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


void ignore(void) {
  // Sketch to test / program the ICM7170 RTC chip to set day/time and configure other features. 
  // ICM7170 is on small breadboard on top of Mega shield. 
  // ALE is tied to Vdd (5V) and CSB is tied to Vss (GND) 
  // INTsrc is tied low (Vss)  
  // WRB = D6, RDB = D7, INTB = D5 
  // Address pins = PORTL (A0–A5 on PL0–PL4, Mega2560 pins D49..45)
  // Data pins = PORTC (D0–D7 on PC0–PC7, Mega2560 pins D37..D30)
  // Xtal (32K, 1M, 2M or 4M) between pins 9 and 10, each with 12pF to Vdd (5V) (Not GND as per usual)
  // For testing on breadboard, a daughterboard is used. 9/10 is Xtal, A12 is Vdd. 
  // 
  //     D7  5V  D30 D31 D32 D33 D34 D35 D36 D37     GND
  // 
  //     24  23  22  21  20  19  18  17  16  15  14  13 
  //    +------------------------------------------------+
  //    |RDB Vdd D7  D6  D5  D4  D3  D2  D1  D0 Vbu Vss  |
  //    >                                                |
  //    |WRB ALE CSB A4  A3  A2  A1  A0  Oo  Oi INTs INTB|
  //    +------------------------------------------------+
  //      1   2   3   4   5   6   7   8   9  10  11  12 
  //
  //     D6  Vdd Vss D45 D46 D47 D48 D49   Xtal Vss  D5
  //
  //    PORTC = D0..D7; PORTL = A0..A5 ; ALE = HIGH; CSB = LOW 
}

// Macros for direct port access
#define RTC_DATA_PORT       PORTC
#define RTC_DATA_DDR        DDRC
#define RTC_DATA_PIN_READ   PINC
#define RTC_ADDR_PORT       PORTL
#define RTC_ADDR_DDR        DDRL

// Miscellaneous pins and defines 
#define RTC_IRQB_PIN        3     // must be an IRQ-enabled pin on the Mega (e.g., 2, 3, etc)
#define RTC_WRB_PIN         6
#define RTC_RDB_PIN         7
#define IRQ_LED             12 
#define RTC_XTAL_PWR        A13

// ICM7170 RTC internal register addresses
#define RTC_SEC100      0x00  // 100th seconds (0..99) 
#define RTC_HRS         0x01  // Hours (0..23 or 1..12 + MSB = 0/1 for AM/PM)
#define RTC_MINS        0x02  // Minutes (0..59)
#define RTC_SECS        0x03  // Seconds (0..59)
#define RTC_MON         0x04  // Month (1..12)
#define RTC_DOM         0x05  // Day of month (1..31)
#define RTC_YEAR        0x06  // Year (00.99)
#define RTC_DOW         0x07  // Day of week (0..6)
#define RTC_ISMR        0x10  // Interrupt Status and Mask register 
#define RTC_CMD_REG     0x11  // Command register 

// ICM7170 Command Register bits (write only)
volatile uint8_t state = LOW; 

// Calendar lookup values 
const char *DoW[] = {"Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"};                                          // Dow = 0..6 
const char *MoY[] = { "", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"};  // MoY = 1..12 

int day_of_week(int day, int month, int year) {
  // calculate DoW when given a day/month/year using the Tomohiko Sakamoto's algorithm 
  // Input ranges: day=1..31; month=1..12; year=20xx
  // Return range: Sun=0..Sat=6 
  static const int offset[] = {0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4};
  year -= month < 3;
  return (year + year / 4 - year / 100 + year / 400 + offset[month - 1] + day) % 7;
}

void RTC_IRQB_ISR(void) {
  readRegister(RTC_ISMR);                                 // read ISMR to reset the interrupt 
  // state = !state; 
  // digitalWrite(IRQ_LED, state); 
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

void loop() {
  RTC_Time_to_Serial (); 
  delay(1000); 
}

void writeRegister(uint8_t regAddr, uint8_t data) {
  RTC_ADDR_DDR = 0xFF;                            // Address port as output
  RTC_ADDR_PORT = regAddr;                        // Place address on port
  RTC_DATA_DDR = 0xFF;                            // Drive data bus as output
  RTC_DATA_PORT = data;
  digitalWrite(RTC_WRB_PIN, LOW);                  // Assert WR (active low)
  digitalWrite(RTC_WRB_PIN, HIGH);                 // Return data bus high-impedance if needed later
  RTC_ADDR_DDR = 0x00;                            // Address port as output
  RTC_ADDR_PORT = 0;
  RTC_DATA_DDR = 0x00;                            // Initially set DATA as output (for writes)
  RTC_DATA_PORT = 0;
}

uint8_t readRegister(uint8_t regAddr) {
  uint8_t result;
  RTC_ADDR_DDR = 0xFF;                            // Address port as output
  RTC_ADDR_PORT = regAddr;                        // Place address on port
  RTC_DATA_DDR = 0x00;                            // Set data bus to input
  RTC_DATA_PORT = 0x00;                           // Ensure internal pull-ups off (chip will drive bus)
  digitalWrite(RTC_RDB_PIN, LOW);                  // Assert RD (active low)
  result = RTC_DATA_PIN_READ;                     // Read data from data bus
  digitalWrite(RTC_RDB_PIN, HIGH);                 // De-assert RD
  RTC_ADDR_DDR = 0x00;                            // Address port as output
  RTC_ADDR_PORT = 0;
  RTC_DATA_DDR = 0x00;                            // Initially set DATA as output (for writes)
  RTC_DATA_PORT = 0;
  return result;
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
