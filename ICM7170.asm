; RTC register definitions 
RTC_BASE      EQU  $
RTC_SEC100    EQU  RTC_BASE
RTC_HRS       EQU  RTC_BASE+0x01
RTC_MINS      EQU  RTC_BASE+0x02
RTC_SECS      EQU  RTC_BASE+0x03
RTC_MON       EQU  RTC_BASE+0x04
RTC_DoM       EQU  RTC_BASE+0x05
RTC_YEAR      EQU  RTC_BASE+0x06
RTC_DoW       EQU  RTC_BASE+0x07
RTC_ISMR      EQU  RTC_BASE+0x10
RTC_CMDREG    EQU  RTC_BASE+0x11

; Memory locations in RAM to save/store time 
TIME_MEM_LOC   EQU  $
TIME_CURR_HRS  EQU  RTC_MEM_LOC
TIME_CURR_MINS EQU  RTC_MEM_LOC+1
TIME_CURR_SECS EQU  RTC_MEM_LOC+2
TIME_CURR_MON  EQU  RTC_MEM_LOC+3
TIME_CURR_DOM  EQU  RTC_MEM_LOC+4
TIME_CURR_YEAR EQU  RTC_MEM_LOC+5
TIME_CURR_DOW  EQU  RTC_MEM_LOC+6

; bit definitions
bit7          EQU  (1<<7)
bit6          EQU  (1<<6)
bit5          EQU  (1<<5)
bit4          EQU  (1<<4)
bit3          EQU  (1<<3)
bit2          EQU  (1<<2)
bit1          EQU  (1<<1)
bit0          EQU  (1)

; RTC Interrupt Status and Mask Register definitions 
; bits6 and 7 of RTC_ISMR are not used 
RTC_ISMR_TEST  EQU  (RTC_ISMR | bit5)  
RTC_ISMR_IE    EQU  (RTC_ISMR | bit4)
RTC_ISMR_RUN   EQU  (RTC_ISMR | bit3)  
RTC_ISMR_24HR  EQU  (RTC_ISMR | bit2) 
RTC_ISMR_4MHZ  EQU  (RTC_ISMR | bit1 | bit0) 
RTC_ISMR_2MHz  EQU  (RTC_ISMR | bit1)
RTC_ISMR_1MHz  EQU  (RTC_ISMR | bit0) 
RTC_ISMR_32K   EQU  (RTC_ISMR)

; RTC subroutines 
RTC_INIT: 
  RTS

RTC_READ_TIME:
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
