//
.def TEMP = R16

.equ TA0_CTRLA = 0xA00
.equ TA0_CTRLB = 0xA01
.equ TA0_CTRLC = 0xA02
.equ TA0_CTRLD = 0xA03

.equ TB0_CTRLA = 0xA40
.equ TB0_CTRLB = 0xA41
.equ TB0_INTCTRL = 0xA45
.equ TB0_INTFLAGS = 0xA46
.equ TB0_EVCTRL = 0xA44
.equ MCLKCTRLB = 0x61
.equ CCP = 0x34
.equ SPL = 0x3D
.equ SPH = 0x3F


.equ TA0_ENABLE = 0
.equ TA0_CLKSEL2 = 3
.equ TA0_CLKSEL1 = 2
.equ TA0_CLKSEL0 = 1

.equ TA0_LPER = 0xA26
.equ TA0_HPER = 0xA27
.equ TA0_LCMP1 = 0xA2A
.equ TA0_HCMP1 = 0xA2B

.equ TA0_CMP1EN = 5
.equ TA0_WGM2 = 2
.equ TA0_WGM1 = 1
.equ TA0_WGM0 = 0

.equ TB0_CLKSEL1 = 2
.equ TB0_CLKSEL0 = 1
.equ TB0_ENABLE = 0

.equ TB0_CNTMODE2 = 2
.equ TB0_CNTMODE1 = 1
.equ TB0_CNTMODE0 = 0
.equ TB0_CCMPEN = 4
.equ TB0_CAPTEI = 0
.equ TB0_CAPT = 0

.equ TB0_CCMPL = 0xA4C
.equ TB0_CCMPH = 0xA4D

.equ PORTMX_CTRLD = 0x203
.equ TCB0 = 0
.equ CAPTEI = 0

.equ PRTA_DIR = 0x400

.equ PEN = 0
.equ PDIV0 = 1
.equ PDIV1 = 2
.equ PDIV2 = 3
.equ PDIV3 = 4

.org 0x0000
    rjmp    RESET

; Replace with your application code
RESET:

	; Setup stackpointer
	ldi		   TEMP, low(RAMEND)
	out		   SPL, TEMP

	ldi		   TEMP, high(RAMEND)
	out		   SPH, TEMP

    ; Enable output of TCB
    ldi        TEMP, (1 << 1)
    sts        PRTA_DIR, TEMP

	; Enable event system for TA0 PWM output
	ldi		   TEMP, 0x05
	sts		   0x18A, TEMP

	ldi		   TEMP, 0x01
	sts		   0x1A2, TEMP

	; TA0 will be used to generate PWM output for IR LED
	; Functions will be used to reconfigure timer settings later, but
	; the default startup will be a human

	; Set period ~27 uS and default 20% duty cycle (for human)
	ldi		   TEMP, low(26)
	sts		   TA0_LPER, TEMP

	ldi		   TEMP, high(26)
	sts		   TA0_HPER, TEMP

	ldi		   TEMP, low(6)
	sts		   TA0_LCMP1, TEMP

	ldi		   TEMP, high(6)
	sts		   TA0_HCMP1, TEMP

	; Enable compare mode output and set WGM of timer to PWM
	ldi		   TEMP, (1 << TA0_CMP1EN) | (0 << TA0_WGM2) | (1 << TA0_WGM1) | (1 << TA0_WGM0)
	sts		   TA0_CTRLB, TEMP

	; Enable will be set last to allow configuration before timer startup
	ldi		   TEMP, (1 << TA0_ENABLE) | (0 << TA0_CLKSEL2) | (0 << TA0_CLKSEL1) | (0 << TA0_CLKSEL0)
	sts		   TA0_CTRLA, TEMP

	; Configure event system to push pin inputs to timer
	ldi		   TEMP, 0x10
	sts		   0x182, TEMP

	ldi		   TEMP, 0x03
	sts		   0x192, TEMP

	; Configure TB0 to measure PWM coming in da stuff :D

	ldi			  TEMP, (1 << TB0_CAPTEI)
	sts			  TB0_EVCTRL, TEMP

	ldi			  TEMP, (1 << TB0_CAPT)
	sts			  TB0_INTCTRL, TEMP

	; Configure timer to count in PWM capture mode
	ldi			  TEMP, (0 << TB0_CCMPEN) | (1 << TB0_CNTMODE2) | (0 << TB0_CNTMODE1) | (0 << TB0_CNTMODE0)
	sts			  TB0_CTRLB, TEMP

	; Enable the timer last to ensure we have configured everything
	ldi			  TEMP, (1 << TB0_ENABLE)
	sts		      TB0_CTRLA, TEMP
	
	; Allow changes to S C A R Y registers >=D
	ldi			  TEMP, 0xD8
	out			  CCP, TEMP

	; Set internal clock divide to achieve 1Mhz, but requires 16MHz internal clock
	ldi		   TEMP, 0x07
	sts		   MCLKCTRLB, TEMP

	; Now disallow the scary changes
	clr		   TEMP
	out		   CCP, TEMP

    ; Enable all interrupts
    sei

	; Call become human
	rcall	   BECOME_HUMAN

MAIN:

    nop
    rjmp    MAIN

BECOME_ZOMBIE:

	ret

BECOME_DOCTOR:

	ret

BECOME_HUMAN:

	push	TEMP

	nop

	pop		TEMP

	ret