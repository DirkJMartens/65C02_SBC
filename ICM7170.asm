; RTC register definitions 
RTC_BASE      EQU  $
RTC_CTR_100th EQU  RTC_BASE
RTC_HRS       EQU  RTC_BASE+0x01
RTC_MINS      EQU  RTC_BASE+0x02
RTC_SECS      EQU  RTC_BASE+0x03
RTC_MON       EQU  RTC_BASE+0x04
RTC_DoM       EQU  RTC_BASE+0x05
RTC_YEAR      EQU  RTC_BASE+0x06
RTC_DoW       EQU  RTC_BASE+0x07
RTC_ISMR      EQU  RTC_BASE+0x10
RTC_CMDREG    EQU  RTC_BASE+0x11

; bit definitions
bit7          EQU  1<<7
bit6          EQU  1<<6
bit5          EQU  1<<5
bit4          EQU  1<<4
bit3          EQU  1<<3
bit2          EQU  1<<2
bit1          EQU  1<<1
bit0          EQU  1

; RTC Interrupt Status and Mask Register definitions 
RTC_ISMR_TEST  EQU  (RTC_ISMR | bit5)  
RTC_ISMR_IE    EQU  (RTC_ISMR | bit4)
RTC_ISMR_RUN   EQU  (RTC_ISMR | bit3)  
RTC_ISMR_24HR  EQU  (RTC_ISMR | bit2) 
RTC_ISMR_4MHZ  EQU  (RTC_ISMR | bit1 | bit0) 
RTC_ISMR_2MHz  EQU  (RTC_ISMR | bit1)
RTC_ISMR_1MHz  EQU  (RTC_ISMR | bit0) 
RTC_ISMR_32K   EQU   RTC_ISMR

; RTC subroutines 
RTC_INIT: 
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
