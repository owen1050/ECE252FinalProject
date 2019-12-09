;Required GPIO and ADC Clocks
SIM_SCGC5 EQU 0x40048038
SIM_SCGC6 EQU 0x4004803C

;ADC Registers
ADC0_SC1A EQU 0x4003B000
ADC0_CFG1 EQU 0x4003B008
ADC0_RA EQU 0x4003B010
ADC0_SC3 EQU 0x4003B024
PMC_REGSC EQU 0x4007D002
SC1A_DEFAULTS EQU 0x00
ADCH_AD0 EQU 0x00
ADCH_TEMP EQU 0x1A
ADCH_BANDGAP EQU 0x1B
COCO_FLAG_MASK EQU 0x00000080
	
;Ouput PCR Registers	
PORTB_PCR0 EQU 0x4004A000 ;B0 (A1)
PORTB_PCR1 EQU 0x4004A004 ;B1 (B1)
PORTB_PCR2 EQU 0x4004A008 ;B2 (C1)
PORTB_PCR3 EQU 0x4004A00C ;B3 (D1)
PORTB_PCR8 EQU 0x4004A020 ;B8 (E1)
PORTB_PCR9 EQU 0x4004A024 ;B9 (F1)
PORTB_PCR10 EQU 0x4004A028 ;B10 (G1)
	
PORTE_PCR0 EQU 0x4004D000 ;D0 (digit 1)
PORTE_PCR1 EQU 0x4004D004 ;D1 DIGIT 2
PORTE_PCR2 EQU 0x4004D008 ;fan
	
;Input control registers	
GPIOE_PDDR EQU 0x400FF114 ; port E data direction register address
GPIOE_PSOR EQU 0x400FF104 ; port E data set output register address
GPIOE_PCOR EQU 0x400FF108 ; port E data clear output register address

GPIOB_PDDR EQU 0x400FF054 ; port B data direction register address
GPIOB_PSOR EQU 0x400FF044 ; port B data set output register address
GPIOB_PCOR EQU 0x400FF048 ; port B data clear output register address
	
;port d registers and input PCR
GPIOD_PDDR EQU 0x400FF0D4 
GPIOD_PDIR EQU 0x400FF0D0 
PORTD_PCR0 EQU 0x4004C000 
PORTD_PCR1 EQU 0x4004C008 
	
;masks for all inputs and outputs
A1_MASK EQU 0x00000001 ; PTB0
B1_MASK EQU 0x00000002;PTB1
C1_MASK EQU 0x00000004 ; PT2
D1_MASK EQU 0x00000008 ; PTB3
E1_MASK EQU 0x00000100 ; PTD8
F1_MASK EQU 0x00000200 ; PTD9
G1_MASK EQU 0x00000400 ; PTD10
SWITCH_MASK EQU 0x00000001 ; 2^0
SWITCH_MASK2 EQU 0x00000004 ; 2^0	
DIG1_MASK EQU 0x00000001 ; DIG0
DIG2_MASK EQU 0x00000002;DIG1
FAN_MASK EQU 0x00000004;DIG1
DELAY_CNT EQU 0X00D00000
	
	AREA asm_area, CODE, READONLY
	EXPORT asm_main
		
asm_main ;assembly entry point for C function, do not delete

	BL init_gpio;begin all digital GPIO 
	BL adc_init;begin analog input
	LDR R0, =0x1;used to count number of loops to check tempature
	PUSH {R0}
	
loop;looping part of code
	LDR R5, =0x0
	POP {R0}
	SUBS R0, R0, #0x1 ;subtract one every loop to only check temp every so often
	PUSH {R0}
	BNE DR ;only check temp if SUBS resulted in 0
	POP{R0}
	LDR R0, =0x60 ;reset the count on check temp
	PUSH{R0}
	LDR R0,= ADCH_AD0 ;load AD0 for adc_read
	BL adc_read ;do adc conversion
	
	;math to turn voltage into tempature
	LDR R1, =0x190
	BL divide
	SUBS R0, R0, #0x27
	LDR R1, =0xA
	BL divide ;custom divide function because UDIV/SDIV didnt work
	;divide returns remainder (ones place) in R2 and the results (tens place) in R2
	;split temp in F into individual sigits
	MOV R7, R0
	MOV R6, R2
	
DR;dr for "dont read" tempature
	;used to control which digit is grounded (turns on)
	CMP R5, #0x1 
	BEQ digit2
	CMP R5, #0x2
	BEQ done
	
	BL DIG1on ;ground digit 1
	;run through all possibilits for digit one and pull the correct pins high
	LDR R5, =0x1
	CMP R6, #0x0
	BEQ setD0
	CMP R6, #0x1
	BEQ setD1
	CMP R6, #0x2
	BEQ setD2
	CMP R6, #0x3
	BEQ setD3
	CMP R6, #0x4
	BEQ setD4
	CMP R6, #0x5
	BEQ setD5T
	CMP R6, #0x6
	BEQ setD6T
	CMP R6,#0x7
	BEQ setD7T
	CMP R6, #0x8
	BEQ setD8T
	CMP R6, #0x9
	BEQ setD9T
	B digit2
;ran into "branches are too far away" error so added these as jumpers
setD5T
	B setD5
setD6T
	B setD6
setD7T
	B setD7
setD8T
	B setD8
setD9T
	B setD9

digit2
	;delay before turning off digit one
	LDR R0, =0x00011000
	BL delay
	BL DIG1off
	;and turning on digit 2
	BL DIG2on
	LDR R5, =0x2;set the control state
	;set digit 2 pins to correct number
	CMP R7, #0x0
	BEQ setD0
	CMP R7, #0x1
	BEQ setD1
	CMP R7, #0x2
	BEQ setD2
	CMP R7, #0x3
	BEQ setD3
	CMP R7, #0x4
	BEQ setD4
	CMP R7, #0x5
	BEQ setD5
	CMP R7, #0x6
	BEQ setD6TT
	CMP R7,#0x7
	BEQ setD7TT
	CMP R7, #0x8
	BEQ setD8TT
	CMP R7, #0x9
	BEQ setD9TT
done
	;pause before led turns off
	LDR R0, =0x00011000
	BL delay
	BL DIG2off
	
	;check force fan on button
	BL check_input2
	BNE FANonT
	;check force fan off button
	BL check_input1
	BNE FANoffT
	;if temp is over 80 turn fan on
	CMP R7, #0x8
	BPL FANonT
	;if no buttons pressed and temp less than 80 turn fan off
	B FANoffT
	
FANR;FANR stands for fan return and is where fanOn and fanOff come back too
	B loop;return to loop
	
	;branching too far
setD6TT
	B setD6	
setD7TT
	B setD7	
setD8TT
	B setD8
setD9TT
	B setD9

;once digit one or zero is pulled low, then set these pins high to show specific numbers
setD0
	BL A1on
	BL B1on
	BL C1on
	BL D1on
	BL E1on
	BL F1on
	BL G1off
	B DR;
	
setD1
	BL A1off
	BL B1on
	BL C1on
	BL D1off
	BL E1off
	BL F1off
	BL G1off
	B DR;

setD2
	BL A1on
	BL B1on
	BL C1off
	BL D1on
	BL E1on
	BL F1off
	BL G1on
	B DR;
	
setD3
	BL A1on
	BL B1on
	BL C1on
	BL D1on
	BL E1off
	BL F1off
	BL G1on
	B DR;
	
setD4
	BL A1off
	BL B1on
	BL C1on
	BL D1off
	BL E1off
	BL F1on
	BL G1on
	B DR;
	
setD5
	BL A1on
	BL B1off
	BL C1on
	BL D1on
	BL E1off
	BL F1on
	BL G1on
	B DR;
;temp jump for fan on and off
FANonT
	B FANon
FANoffT
	B FANoff
	LTORG		
setD6
	BL A1on
	BL B1off
	BL C1on
	BL D1on
	BL E1on
	BL F1on
	BL G1on
	B DR;
	
setD7
	BL A1on
	BL B1on
	BL C1on
	BL D1off
	BL E1off
	BL F1off
	BL G1off
	B DR;
	
setD8
	BL A1on
	BL B1on
	BL C1on
	BL D1on
	BL E1on
	BL F1on
	BL G1on
	B DR;
	
setD9
	BL A1on
	BL B1on
	BL C1on
	BL D1off
	BL E1off
	BL F1on
	BL G1on
	B DR;
	
;turning on and off individual led segments	
A1on
	 LDR R0,=GPIOB_PSOR
	 LDR R1,[R0]
	 LDR R2,=A1_MASK
	 ORRS R1, R2
	 STR R1,[R0]
	 BX LR; return to the calling address
A1off
	 LDR R0,=GPIOB_PCOR
	 LDR R1,[R0]
	 LDR R2,=A1_MASK
	 ORRS R1, R2
	 STR R1,[R0]
	 BX LR; return to the calling address

	
B1on
	 LDR R0,=GPIOB_PSOR
	 LDR R1,[R0]
	 LDR R2,=B1_MASK
	 ORRS R1, R2
	 STR R1,[R0]
	 BX LR; return to the calling address
B1off
	 LDR R0,=GPIOB_PCOR
	 LDR R1,[R0]
	 LDR R2,=B1_MASK
	 ORRS R1, R2
	 STR R1,[R0]
	 BX LR; return to the calling address
	
C1on
	 LDR R0,=GPIOB_PSOR
	 LDR R1,[R0]
	 LDR R2,=C1_MASK
	 ORRS R1, R2
	 STR R1,[R0]
	 BX LR; return to the calling address
C1off
	 LDR R0,=GPIOB_PCOR
	 LDR R1,[R0]
	 LDR R2,=C1_MASK
	 ORRS R1, R2
	 STR R1,[R0]
	 BX LR; return to the calling address
	
D1on
	 LDR R0,=GPIOB_PSOR
	 LDR R1,[R0]
	 LDR R2,=D1_MASK
	 ORRS R1, R2
	 STR R1,[R0]
	 BX LR; return to the calling address
D1off
	 LDR R0,=GPIOB_PCOR
	 LDR R1,[R0]
	 LDR R2,=D1_MASK
	 ORRS R1, R2
	 STR R1,[R0]
	 BX LR; return to the calling address
	
E1on
	 LDR R0,=GPIOB_PSOR
	 LDR R1,[R0]
	 LDR R2,=E1_MASK
	 ORRS R1, R2
	 STR R1,[R0]
	 BX LR; return to the calling address
E1off
	 LDR R0,=GPIOB_PCOR
	 LDR R1,[R0]
	 LDR R2,=E1_MASK
	 ORRS R1, R2
	 STR R1,[R0]
	 BX LR; return to the calling address
	
F1on
	 LDR R0,=GPIOB_PSOR
	 LDR R1,[R0]
	 LDR R2,=F1_MASK
	 ORRS R1, R2
	 STR R1,[R0]
	 BX LR; return to the calling address
F1off
	 LDR R0,=GPIOB_PCOR
	 LDR R1,[R0]
	 LDR R2,=F1_MASK
	 ORRS R1, R2
	 STR R1,[R0]
	 BX LR; return to the calling address
	
G1on
	 LDR R0,=GPIOB_PSOR
	 LDR R1,[R0]
	 LDR R2,=G1_MASK
	 ORRS R1, R2
	 STR R1,[R0]
	 BX LR; return to the calling address
G1off
	 LDR R0,=GPIOB_PCOR
	 LDR R1,[R0]
	 LDR R2,=G1_MASK
	 ORRS R1, R2
	 STR R1,[R0]
	 BX LR; return to the calling address
	
	
;setting up individual digits for display	
DIG1on
	LDR R0,=GPIOE_PSOR
	LDR R1,[R0]
	LDR R2,=DIG1_MASK
	ORRS R1, R2
	STR R1,[R0]
	BX LR; return to the calling address
	 
DIG1off
	LDR R0,=GPIOE_PCOR
	LDR R1,[R0]
	LDR R2,=DIG1_MASK
	ORRS R1, R2
	STR R1,[R0]
	BX LR; return to the calling address
	
DIG2on
	LDR R0,=GPIOE_PSOR
	LDR R1,[R0]
	LDR R2,=DIG2_MASK
	ORRS R1, R2
	STR R1,[R0]
	BX LR; return to the calling address
	 
DIG2off
	LDR R0,=GPIOE_PCOR
	LDR R1,[R0]
	LDR R2,=DIG2_MASK
	ORRS R1, R2
	STR R1,[R0]
	BX LR; return to the calling address

;fan control
FANon
	LDR R0,=GPIOE_PSOR
	LDR R1,[R0]
	LDR R2,=FAN_MASK
	ORRS R1, R2
	STR R1,[R0]
	B FANR; return to the calling address
	 
FANoff
	LDR R0,=GPIOE_PCOR
	LDR R1,[R0]
	LDR R2,=FAN_MASK
	ORRS R1, R2
	STR R1,[R0]
	B FANR; return to the calling address

;delay function
delay
	SUBS R0,#1
	BNE delay
	BX LR; return to the calling address

;set z registter for button 1
check_input1
	LDR R2, =SWITCH_MASK
	LDR R0,=GPIOD_PDIR
	LDR R1,[R0]
	TSTS R1,R2; mask ANDS [input register]
	BX LR; return to the calling address
	
;set z registter for button 2	
check_input2
	LDR R2, =SWITCH_MASK2
	LDR R0,=GPIOD_PDIR
	LDR R1,[R0]
	TSTS R1,R2; mask ANDS [input register]
	BX LR; return to the calling addres
init_gpio
	; Turns on clocks for all ports
	LDR R0,=SIM_SCGC5
	LDR R1,[R0]
	LDR R2,=0x00003E00
	ORRS R1,R2 ; Set bits by ORRing original value and current setting
	STR R1,[R0] ; Store back in SIM_SCGC5
	; Outputs:
	LDR R0,=PORTB_PCR0
	LDR R1,=0x00000100
	STR R1,[R0] ; Put value into PORTB_PCR1
	LDR R0,=PORTB_PCR1
	LDR R1,=0x00000100
	STR R1,[R0] ; Put value into PORTB_PCR1
	LDR R0,=PORTB_PCR2
	LDR R1,=0x00000100
	STR R1,[R0] ; Put value into PORTB_PCR1
	LDR R0,=PORTB_PCR3
	LDR R1,=0x00000100
	STR R1,[R0] ; Put value into PORTB_PCR1
	LDR R0,=PORTB_PCR8
	LDR R1,=0x00000100
	STR R1,[R0] ; Put value into PORTB_PCR1
	LDR R0,=PORTB_PCR9
	LDR R1,=0x00000100
	STR R1,[R0] ; Put value into PORTB_PCR1
	LDR R0,=PORTB_PCR10
	LDR R1,=0x00000100
	STR R1,[R0] ; Put value into PORTB_PCR1
	
	LDR R0,=PORTE_PCR0
	LDR R1,=0x00000100
	STR R1,[R0] ; Put value into PORTB_PCR1
	LDR R0,=PORTE_PCR1
	LDR R1,=0x00000100
	STR R1,[R0] ; Put value into PORTB_PCR1
	LDR R0,=PORTE_PCR2
	LDR R1,=0x00000100
	STR R1,[R0] ; Put value into PORTB_PCR1
	 
	LDR R2,=A1_MASK
	LDR R0,=GPIOB_PDDR
	LDR R1,[R0]
	ORRS R1,R2 
	STR R1,[R0]
	
	LDR R2,=B1_MASK
	LDR R0,=GPIOB_PDDR
	LDR R1,[R0]
	ORRS R1,R2 
	STR R1,[R0] 
	
	LDR R2,=C1_MASK
	LDR R0,=GPIOB_PDDR
	LDR R1,[R0]
	ORRS R1,R2 
	STR R1,[R0]
	
	LDR R2,=D1_MASK
	LDR R0,=GPIOB_PDDR
	LDR R1,[R0]
	ORRS R1,R2 
	STR R1,[R0]
	
	LDR R2,=E1_MASK
	LDR R0,=GPIOB_PDDR
	LDR R1,[R0]
	ORRS R1,R2 
	STR R1,[R0]
	
	LDR R2,=F1_MASK
	LDR R0,=GPIOB_PDDR
	LDR R1,[R0]
	ORRS R1,R2 
	STR R1,[R0]
	
	LDR R2,=G1_MASK
	LDR R0,=GPIOB_PDDR
	LDR R1,[R0]
	ORRS R1,R2 
	STR R1,[R0]
	
	LDR R2,=DIG1_MASK
	LDR R0,=GPIOE_PDDR
	LDR R1,[R0]
	ORRS R1,R2 
	STR R1,[R0] 
	
	LDR R2,=DIG2_MASK
	LDR R0,=GPIOE_PDDR
	LDR R1,[R0]
	ORRS R1,R2 
	STR R1,[R0] 
	
	LDR R2,=FAN_MASK
	LDR R0,=GPIOE_PDDR
	LDR R1,[R0]
	ORRS R1,R2 
	STR R1,[R0] 
	
	LDR R0,=PORTD_PCR0
	LDR R1,=0x00000103
	STR R1,[R0] 
	
	LDR R0,=PORTD_PCR1
	LDR R1,=0x00000103
	STR R1,[R0]
	
	LDR R2,= SWITCH_MASK
	LDR R0,=GPIOD_PDDR
	LDR R1,[R0]
	BICS R1,R2 ; AND the original content of GPIOD_PDDR with the inverse of the SWITCH_MASK
	STR R1,[R0] ; Put new value back into GPIOD_PDDR
	
	LDR R2,= SWITCH_MASK2
	LDR R0,=GPIOD_PDDR
	LDR R1,[R0]
	BICS R1,R2 ; AND the original content of GPIOD_PDDR with the inverse of the SWITCH_MASK
	STR R1,[R0] ; Put new value back into GPIOD_PDDR


	BX LR; return to the calling address
	
	
adc_init FUNCTION
	; SIM_SCGC6[ADC0] = 1
	LDR R0,=SIM_SCGC6
	LDR R1,[R0]
	LDR R2,=0x08000000
	ORRS R1,R2
	STR R1,[R0]
	; Set ADC0_CFG1[MODE] = 11b for 16-bit results
	LDR R0,=ADC0_CFG1
	LDR R1,=0x0000000C
	STR R1,[R0]
	; Set ADC0_SC3[AVGE] = 0b to disable averaging
	; Set ADC0_SC3[AVGS] = 00b for 4 sample averages
	LDR R0,= ADC0_SC3
	LDR R1,=0x00000007
	STR R1,[R0]
	; Set PMC_REGSC[BGBE] = 1b to enable 1V bandgap reference
	LDR R0,=PMC_REGSC
	LDR R1,=0x01
	STRB R1,[R0]
	 ; Wait for bandgap to come up
	LDR R2,=16000000 ;1 second wait
adc_init_wait
	SUBS R2,#1
	BNE adc_init_wait
	BX LR
	ENDFUNC
;When called, R0 contains SC1A_ADCH value
;Returns ADC value in R0
adc_read FUNCTION
	LDR R1,=SC1A_DEFAULTS
	ORRS R0,R1
	LDR R1,=ADC0_SC1A
	STR R0,[R1]
	LDR R2,=COCO_FLAG_MASK
adc_read_wait
	LDR R0,[R1]
	TST R0,R2
	BEQ adc_read_wait
	LDR R1,=ADC0_RA
	LDR R0,[R1]
	BX LR
	ENDFUNC
	
divide ;ro = ro / r1 r2= remainder
	MOV r2, r0
	LDR R0, =0x0
dv
	ADDS R0, R0, #0x1 
	SUBS R2, R2, R1
	BPL dv
	SUBS R0,R0, #0x1
	ADD R2, R2, R1
	BX LR
	

 END