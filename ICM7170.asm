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
RTC_ISMR      EQU  (RTC_BASE+0x10)        ; Interrupt Status and Mask Register 
RTC_CMDREG    EQU  (RTC_BASE+0x11)        ; Command Register 

; bit definitions
bit7          EQU  (1<<7)
bit6          EQU  (1<<6)
bit5          EQU  (1<<5)
bit4          EQU  (1<<4)
bit3          EQU  (1<<3)
bit2          EQU  (1<<2)
bit1          EQU  (1<<1)
bit0          EQU  (1<<0)

; RTC Interrupt Status and Mask Register definitions 
; bits6 and 7 of RTC_ISMR are not used 
RTC_ISMR_TEST  EQU  (RTC_ISMR | bit5)          ; 0 = normal mode / 1 = test mode 
RTC_ISMR_IE    EQU  (RTC_ISMR | bit4)          ; 0 = interrupt disable / 1 = interr enable 
RTC_ISMR_RUN   EQU  (RTC_ISMR | bit3)          ; 0 = stop mode / 1 = run mode 
RTC_ISMR_24HR  EQU  (RTC_ISMR | bit2)          ; 0 = 12 hr mode / 1 = 24 hr mode 
RTC_ISMR_4MHZ  EQU  (RTC_ISMR | bit1 | bit0)   ; 11 = 4 MHz
RTC_ISMR_2MHz  EQU  (RTC_ISMR | bit1)          ; 10 = 2 MHz 
RTC_ISMR_1MHz  EQU  (RTC_ISMR | bit0)          ; 01 = 1 MHz
RTC_ISMR_32K   EQU  (RTC_ISMR)                 ; 00 = 32 KHz 

; Memory locations in RAM to save/store time 
; This allows any application to access date and time  
TIME_MEM_LOC   EQU  $
TIME_CURR_HRS  EQU  (RTC_MEM_LOC  )
TIME_CURR_MINS EQU  (RTC_MEM_LOC+1)
TIME_CURR_SECS EQU  (RTC_MEM_LOC+2)
TIME_CURR_MON  EQU  (RTC_MEM_LOC+3)
TIME_CURR_DOM  EQU  (RTC_MEM_LOC+4)
TIME_CURR_YEAR EQU  (RTC_MEM_LOC+5)
TIME_CURR_DOW  EQU  (RTC_MEM_LOC+6)

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
  RTS

RTC_MIN_INT:
  RTS

RTC_HR_INT:
  RTS

RTC_DAY_INT:
  RTS
