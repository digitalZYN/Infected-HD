;
; TImerTest.asm
;
; Created: 10/18/2019 6:06:54 PM
; Author : Zyn
;
.def TEMP = R16

.equ TB0_CTRLA = 0xA40
.equ TB0_CTRLB = 0xA41
.equ TB0_INTCTRL = 0xA45
.equ TB0_INTFLAGS = 0xA46

.equ TB0_CLKSEL1 = 2
.equ TB0_CLKSEL0 = 1
.equ TB0_ENABLE = 0

.equ TB0_CNTMODE2 = 2
.equ TB0_CNTMODE1 = 1
.equ TB0_CNTMODE0 = 0
.equ TB0_CCMPEN = 4

.equ TB0_CCMPL = 0xA4C
.equ TB0_CCMPH = 0xA4D

.equ PORTMX_CTRLD = 0x203
.equ TCB0 = 0

.equ PRTA_DIR = 0x400

.org 0x0000
	rjmp	RESET

; Replace with your application code
RESET:

	; Enable output of TCB
	ldi		TEMP, (1 << TCB0)
	sts		PORTMX_CTRLD, TEMP

	ldi		TEMP, (1 << 6)
	sts		PRTA_DIR, TEMP

	; Configure Timer B
	ldi		TEMP, (0 << TB0_CLKSEL1) | (0 << TB0_CLKSEL0) | (1 << TB0_ENABLE)
	sts		TB0_CTRLA, TEMP
	
	ldi		TEMP, (1 << TB0_CNTMODE2) | (1 << TB0_CNTMODE1) | (1 << TB0_CNTMODE0) | (0 << TB0_CCMPEN)
	sts		TB0_CTRLB, TEMP

	; Set to count 26 times for 38kHz
	ldi		TEMP, 0x1A
	sts		TB0_CCMPL, TEMP

	ldi		TEMP, 0x04
	sts		TB0_CCMPH, TEMP

	; Enable all interrupts
	sei

MAIN:

	nop
	rjmp	MAIN
