# 65C02_SBC
65C02 based single board computer, based on Ben Eater's design 

- Uses the design by Ben Eater (https://eater.net/6502)
- Implemented using wirewrap on Eurocard i.o. breadboards
- Contains:
  - 65C816 CPU in 65C02-emulation mode, running at 1 MHz 
  - 32K SRAM (62256)
  - 32K EEPROM (28C256)
  - 65C22 VIA giving 2 eight-bit I/O ports A and B
  - Port A is connected to an 8-LED bar graph, mainly for debugging purposes
  - Port B is connected to an 16 chars x 2 lines LCD display, running in 4-bit mode
  - 65C51 ACIA with a FTDI TTL-RS232-adapter, providing a console for serial comms @ 115.2kBaud
  - PS2 keyboard with discrete interface using 74ACT14 and 2 x 74HC595 and a VIA input port. 
  - ICM7170 Real Time Clock chip with 4.194304MHz crystal and a backup battery with 32kHz watch crystal (Chose this chip over modern I2C version since I found 2 original 1980's in my daad's parts bin and since it can be directly interfaced as a memory-mapped I/O device). 
  - Software development is never-ending, but currently working: 
    - BIOS, providing reset and initializing, LCD and ACIA functionality, etc. 
    - WOZMON monitor to view and edit memory content and to run programs 
    - MSBASIC, the original BASIC by Microsoft
   
- Ideas for future additions and modifications:
  - Video processer TMS9919 for low res text and graphics output on NTSC-compatible monitor/TV
  - FabGL32 VGA as temporary/standalone VGA console output
  - Storage:
    - adding CompactFlash card (using IDE interface)
    - adding SD card (using SPI) 
