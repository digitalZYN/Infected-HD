; BEGIN constants
.def TEMP = R16
.def READ_VALUE = R17
 
.equ MAIN_STATUS = 0x1C

.equ HUMAN = 0
.equ ZOMBIE = 1
.equ DOCTOR = 2

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
.equ TA0_LCNT = 0xA20
.equ TA0_HCNT = 0xA21

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
.equ TB0_CCMPINIT = 5
 
.equ TB0_CCMPL = 0xA4C
.equ TB0_CCMPH = 0xA4D
 
.equ PORTMX_CTRLD = 0x203
.equ TCB0 = 0
.equ CAPTEI = 0
 
.equ PRTA_DIR = 0x400
.equ PRTA_PIN7CTRL = 0x417
 
.equ PEN = 0
.equ PDIV0 = 1
.equ PDIV1 = 2
.equ PDIV2 = 3
.equ PDIV3 = 4

; END constants 

.org 0x0000
    rjmp    RESET

; For PWM Detection on TB0
.org 26
    rjmp    SIGNAL_FOUND
 
; Move this down a bit :)
.org 62
 
; Replace with your application code
RESET:
 
    ; Setup stackpointer
    ldi        TEMP, low(RAMEND)
    out        SPL, TEMP
 
    ldi        TEMP, high(RAMEND)
    out        SPH, TEMP
 
    ; Enable output of TCB
    ldi        TEMP, (1 << 1)
    sts        PRTA_DIR, TEMP
 
    ; Enable event system for TA0 PWM output
    ldi        TEMP, 0x05
    sts        0x18A, TEMP
 
    ldi        TEMP, 0x01
    sts        0x1A2, TEMP
 
	; Setup the STATUS as HUMAN
	ldi		TEMP, (1 << HUMAN)
	out		MAIN_STATUS, TEMP

	; Setup PA7 interrupt for Mode Button Sensing
	; It will be configured as sensing a RISING _| edge
	; so make sure to put a pull down resistor on the pin JIC!
	
	; Enable configuration directly on pin
	ldi		TEMP, 0x2
	sts		PRTA_PIN7CTRL, TEMP

    ; TA0 will be used to generate PWM output for IR LED
    ; Functions will be used to reconfigure timer settings later, but
    ; the default startup will be a human
 
    ; Set period ~27 uS and default 80% duty cycle (for zombie)
	; but the timer will not be enabled since humans do not
	; broadcast a signal
    ldi        TEMP, low(26)
    sts        TA0_LPER, TEMP
 
    ldi        TEMP, high(26)
    sts        TA0_HPER, TEMP
 
    ldi        TEMP, low(20)
	sts        TA0_LCMP1, TEMP
 
    ldi        TEMP, high(20)
    sts        TA0_HCMP1, TEMP
 
    ; Enable compare mode output and set WGM of timer to PWM
    ldi        TEMP, (1 << TA0_CMP1EN) | (0 << TA0_WGM2) | (1 << TA0_WGM1) | (1 << TA0_WGM0)
    sts        TA0_CTRLB, TEMP
 
    ; Enable will be set last to allow configuration before timer startup
    ldi        TEMP, (0 << TA0_ENABLE) | (0 << TA0_CLKSEL2) | (0 << TA0_CLKSEL1) | (0 << TA0_CLKSEL0)
    sts        TA0_CTRLA, TEMP
 
    ; Configure event system to push pin inputs to timer
    ldi        TEMP, 0x10
    sts        0x182, TEMP
 
    ldi        TEMP, 0x03
    sts        0x192, TEMP
 
    ; Configure timer to count in PWM capture mode
    ldi           TEMP, (0 << TB0_CCMPEN) | (1 << TB0_CNTMODE2) | (0 << TB0_CNTMODE1) | (0 << TB0_CNTMODE0) | (1 << TB0_CCMPINIT)
    sts           TB0_CTRLB, TEMP
 
    ; Configure TB0 to measure PWM coming in da stuff :D
 
    ldi           TEMP, (1 << TB0_CAPTEI)
    sts           TB0_EVCTRL, TEMP
 
    ldi           TEMP, (1 << TB0_CAPT)
    sts           TB0_INTCTRL, TEMP
 
    ; Enable the timer last to ensure we have configured everything
    ldi           TEMP, (1 << TB0_ENABLE)
    sts           TB0_CTRLA, TEMP
   
    ; Allow changes to S C A R Y registers >=D
    ldi           TEMP, 0xD8
    out           CCP, TEMP
 
    ; Set internal clock divide to achieve 1Mhz, but requires 16MHz internal clock
    ldi        TEMP, 0x07
    sts        MCLKCTRLB, TEMP
 
    ; Now disallow the scary changes
    clr        TEMP
    out        CCP, TEMP
 
    ; Enable all interrupts
    sei
 
MAIN:
 
	; Check if mode button is pressed!
	lds		TEMP, 0x408 ; (PRTA_IN)

	sbrs	TEMP, 7 ; Skip if bit in register is set
	rjmp	KEEP_LOOPIN

	; Disable global interrupts, so we don't get interrupted :D
	
	; To ZYN: Here is where I decided to detect when the mode button was pressed
	; I wanted to use a pin change interrupt, but it seems the Event System functionality
	; I need is already being used. It is possibly to split the functionality, but that's
	; not something I want to do right now! (because mainly laziness)

	; Anyways.. All you need to do is change the mode here. I have setup functions that you
	; can RCALL to see and set what mode you are in, those functions are:
	; IS_ZOMBIE, IS_DOCTOR, IS_HUMAN, BECOME_ZOMBIE, BECOME_DOCTOR, and BECOME_HUMAN

	; The functions have been used down at the bottom of the code if you need an example,
	; and all the functions have header notes in them to tell you what they return and do
	; etc.. Anwyays, happy coding!

	; TODO: Add debounce here and add mode change functionality

	; For future code, I will keep this here
	KEEP_LOOPIN:
    
    rjmp    MAIN

STOP_TA0:

	; Used to stop the main PWM timer

	push	TEMP

	; Stop timer
    ldi        TEMP, (0 << TA0_ENABLE) | (0 << TA0_CLKSEL2) | (0 << TA0_CLKSEL1) | (0 << TA0_CLKSEL0)
    sts        TA0_CTRLA, TEMP

	; Clear count variable
	clr		   TEMP
	sts		   TA0_LCNT, TEMP
	sts		   TA0_HCNT, TEMP

	pop		TEMP

	ret

START_TA0:

	; Used to start the main PWM timer

	push	TEMP

	; Start timer
	ldi        TEMP, (1 << TA0_ENABLE) | (0 << TA0_CLKSEL2) | (0 << TA0_CLKSEL1) | (0 << TA0_CLKSEL0)
    sts        TA0_CTRLA, TEMP

	pop		TEMP

	ret

BECOME_ZOMBIE:
 
	; Configure timer to produce zombie broadcasts!
	push	TEMP

	; Stop the timer
	rcall	STOP_TA0

	; Configure the master STATE register
	in		TEMP, MAIN_STATUS

	; Clear out all status information
	andi	TEMP, ~( (1 << HUMAN) | (1 << DOCTOR) | (1 << ZOMBIE) )
	
	; Add human status
	ori		TEMP, (1 << ZOMBIE)

	; Apply to main register
	out		MAIN_STATUS, TEMP

	; Use an 80% duty cycle for the Zombie
	ldi        TEMP, low(20)
	sts        TA0_LCMP1, TEMP
 
    ldi        TEMP, high(20)
    sts        TA0_HCMP1, TEMP

	; Start the timer
	rcall	START_TA0

	pop		TEMP

    ret
 
BECOME_DOCTOR:
	
	; Configure timer to produce doctor broadcasts!
	push	TEMP

	; Stop the timer
	rcall	STOP_TA0

	; Configure the master STATE register
	in		TEMP, MAIN_STATUS

	; Clear out all status information
	andi	TEMP, ~( (1 << HUMAN) | (1 << DOCTOR) | (1 << ZOMBIE) )
	
	; Add human status
	ori		TEMP, (1 << DOCTOR)

	; Apply to main register
	out		MAIN_STATUS, TEMP

	; Use an 20% duty cycle for the doctor
	ldi        TEMP, low(6)
	sts        TA0_LCMP1, TEMP
 
    ldi        TEMP, high(6)
    sts        TA0_HCMP1, TEMP

	; Start the timer
	rcall	START_TA0

	pop		TEMP

    ret
 
BECOME_HUMAN:

	; Set state to HUMAN

	push	TEMP
	 
	; Simply disable the timer since humans do not broadcast anything

	; Stop the timer
	rcall	STOP_TA0

	; Configure the master STATE register
	in		TEMP, MAIN_STATUS

	; Clear out all status information
	andi	TEMP, ~( (1 << HUMAN) | (1 << DOCTOR) | (1 << ZOMBIE) )
	
	; Add human status
	ori		TEMP, (1 << HUMAN)

	; Apply to main register
	out		MAIN_STATUS, TEMP

	pop		TEMP

    ret
 
IS_HUMAN:

	; Used to TEMP register to return values
	; do not call this if you want to retain the
	; value in TEMP

	; TEMP will return 0xFF if the state is HUMAN
	; otherwise 0x00

	clr		TEMP

	sbic	MAIN_STATUS, HUMAN
	ldi		TEMP, 0xFF

	ret

IS_DOCTOR:

	; Used to TEMP register to return values
	; do not call this if you want to retain the
	; value in TEMP

	; TEMP will return 0xFF if the state is DOCTOR
	; otherwise 0x00

	clr		TEMP

	sbic	MAIN_STATUS, DOCTOR
	ldi		TEMP, 0xFF

	ret

IS_ZOMBIE:

	; Used to TEMP register to return values
	; do not call this if you want to retain the
	; value in TEMP

	; TEMP will return 0xFF if the state is ZOMBIE
	; otherwise 0x00

	clr		TEMP

	sbic	MAIN_STATUS, ZOMBIE
	ldi		TEMP, 0xFF

	ret

; This will be ran if a signal is measured by the timer
SIGNAL_FOUND:
 
    push    TEMP
    push    READ_VALUE
 
    nop
 
    lds     READ_VALUE, TB0_CCMPL
    lds     TEMP, TB0_CCMPH
 
    ; At this point, READ_VALUE is holding the number we need
    ; to check, so check to see if number is within range
 
    ; Do this -> (4 =< READ_VALUE >= 8)
 
    cpi     READ_VALUE, 4
 
    brge    GE_TO_FOUR
    rjmp    FAILED_CHECK
 
    GE_TO_FOUR:
 
        ; Now check to see if we are less than equal to 8
        cpi     READ_VALUE, 9
 
        brlt    LE_TO_EIGHT
        rjmp    FAILED_DOCTOR_CHECK
 
        LE_TO_EIGHT:
 
            ; If we end up here, then a doctor has been detected
            ; we can count up a certain amount of times or just
            ; send it on the first detection. I would recommend the prior
 
			; Check to see if they are a zombie
			rcall	IS_ZOMBIE
			cpi		TEMP, 0xFF

			; If they aren't a zombie, no need to reconfigure timers etc.
			brne	FAILED_DOCTOR_CHECK

			; Now we convert them back to human. For testing, we will simply
			; be setting them straight to a human

				   ;*Detroit :)
			rcall	BECOME_HUMAN
            nop
 
    FAILED_DOCTOR_CHECK:
 
	; Now check to see if the signal we received was a zombie!

	; Here is a logic being peformed: (17 =< READ_VALUE >= 23)

	cpi     READ_VALUE, 17

	brge    GE_TO_SEVENTEEN
    rjmp    FAILED_CHECK

	GE_TO_SEVENTEEN:

		; Now check and see if we are less than or equal to 23
		cpi     READ_VALUE, 24
 
        brlt    LE_TO_TWENTYTHREE
        rjmp    FAILED_ZOMBIE_CHECK

		LE_TO_TWENTYTHREE:

			; Now, if we end up here, a zombie's signal has reached our
			; poor player :( so now they are I N F E C T E D :O

			; Once again.. for testing, we will infect them if they are not a
			; doctor or zombie

			rcall	IS_HUMAN
			cpi		TEMP, 0xFF

			; If they aren't human, then there's no purpose in infecting them
			brne	FAILED_ZOMBIE_CHECK

			; now, deploy the infection!
			rcall	BECOME_ZOMBIE

	FAILED_ZOMBIE_CHECK:

    FAILED_CHECK:
 
    pop     READ_VALUE
    pop     TEMP
 
    reti