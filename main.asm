stm8/
	; SCAN works OK ,PC4 = AIN2 ,PD2 = AIN3 , PD3 = AIN4 , PD5 = UART TX , PD6 = UART RX
	#include "mapping.inc"
	#include "stm8s103f.inc"
	
;;;;;;MACROS;;;;;;;;;;;;;;;;;;;;;;;	
	
pointerX MACRO first
	ldw X,first
	MEND
pointerY MACRO first
	ldw Y,first
	MEND	
	
	
;;;;;;;;;VARIABLES;;;;;;;;;;;;;;;;;;;;	
	segment byte at 100 'ram1'
buffer1 ds.b
buffer2 ds.b
buffer3 ds.b
buffer4 ds.b
buffer5 ds.b
buffer6 ds.b
buffer7 ds.b
buffer8 ds.b
buffer9 ds.b
buffer10 ds.b
buffer11 ds.b
buffer12 ds.b
buffer13 ds.b	; remainder byte 0 (LSB)
buffer14 ds.b	; remainder byte 1
buffer15 ds.b	; remainder byte 2
buffer16 ds.b	; remainder byte 3 (MSB)
buffer17 ds.b	; loop counter
captureH ds.b
captureL ds.b	
captureHS ds.b
captureLS ds.b
captureHT ds.b
captureLT ds.b
capture_state ds.b	
nibble1  ds.b
data	 ds.b
address  ds.b
signbit  ds.b
state    ds.b
temp1    ds.b
decimal  ds.b
result12  ds.b
result11  ds.b
ADCresult10  ds.b
ADCresult9  ds.b
ADCresult8  ds.b
ADCresult7  ds.b
ADCresult6  ds.b
ADCresult5  ds.b
result4  ds.b		; be careful used by bin_to_ascii also, save before use
result3  ds.b		; be careful used by bin_to_ascii also, save before use
result2  ds.b		; be careful used by bin_to_ascii also, save before use
result1  ds.b		; be careful used by bin_to_ascii also, save before use
counter1 ds.b
counter2 ds.b
num1 	  ds.b     ;divisor top
num2 	  ds.b     ;divisor top
num3	  ds.b     ;divisor top
num4 	  ds.b     ;divisor top
num5 	  ds.b     ;divisor top
num6 	  ds.b     ;divisor top
num7 	  ds.b     ;divisor top
num8 	  ds.b     ;divisor top
buffers  ds.b 23



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


	segment 'rom'
main.l
	; initialize SP
	ldw X,#stack_end
	ldw SP,X

	#ifdef RAM0	
	; clear RAM0
ram0_start.b EQU $ram0_segment_start
ram0_end.b EQU $ram0_segment_end
	ldw X,#ram0_start
clear_ram0.l
	clr (X)
	incw X
	cpw X,#ram0_end	
	jrule clear_ram0
	#endif

	#ifdef RAM1
	; clear RAM1
ram1_start.w EQU $ram1_segment_start
ram1_end.w EQU $ram1_segment_end	
	ldw X,#ram1_start
clear_ram1.l
	clr (X)
	incw X
	cpw X,#ram1_end	
	jrule clear_ram1
	#endif

	; clear stack
stack_start.w EQU $stack_segment_start
stack_end.w EQU $stack_segment_end
	ldw X,#stack_start
clear_stack.l
	clr (X)
	incw X
	cpw X,#stack_end	
	jrule clear_stack
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	

infinite_loop.l
	
	mov CLK_CKDIVR,#$00	; cpu clock no divisor = 16mhz
uart_setup:
	;UART1_CK PD4;;;;;;;;;;;;;
	;UART1_TX PD5;;;;;;;;;;;;;;;
	;UART1_RX PD6;;;;;;;;;;;;;
	ld a,#$03			  ;$0683 = 9600 ,$008B = 115200, 
	ld UART1_BRR2,a		  ; write BRR2 firdt
	ld a,#$68
	ld UART1_BRR1,a		  ; write BRR1 next
	bset UART1_CR2,#3	  ; enable TX
	bset UART1_CR2,#2	  ; enable RX

	pointerX #string	  ; macro pointerX points to label string "hello world"
	call stringloop		  ; call procedure stringloop to send null terminated string to USART
	
		
ADC_INIT:
	mov ADC_CR1,#$21    ; ADC prscaler iis clk/4 = 010 ; ADON ,0b01000001
	mov ADC_CSR,#$04 	; select channel-2 , channel-3 and chaneel 4, PC4,PD2,PD3
	mov ADC_CR2,#$0A    ; enable scan mode -bit1,result right align bit 3
	bset ADC_CR3,#7 	; enable buffer for result storage
	mov ADC_TDRL,#$1C 	; disable schmitt trigger #2,disable schmitt trigger #3,disable schmitt trigger #4
	bres ADC_CR1,#1 	; single conversion mode
ADC_READ:
	bset ADC_CR1,#0 	; ADON
	
con_not_finish:
	ld a,ADC_CSR		; copy ADC flag register to A
	and a,#$80			; AND with 0x80 contents of flag register
	jreq con_not_finish	; loop label con_not_finish if ANDing results0, bit7 set if conversion finished
	ld a,ADC_DB2RL		; copy ADC lower result register to A ,(buffer2)
	ld ADCresult5,a		; store in ADCresult5
	ld a,ADC_DB2RH		; copy ADC higher result register to A( ,buffer2)
	ld ADCresult6,a		; store MSB in ADCresult6
	ld a,ADC_DB3RL		; copy ADC lower result register to A ,(buffer3)
	ld ADCresult7,a		; store in ADCresult7
	ld a,ADC_DB3RH		; copy ADC higher result register to A ,(buffer3)
	ld ADCresult8,a		; store MSB in ADCresult8
	ld a,ADC_DB4RL		; copy ADC lower result register to A, (buffer4)
	ld ADCresult9,a		; store in ADCresult9
	ld a,ADC_DB4RH		; copy ADC higher result register to A, (buffer4)
	ld ADCresult10,a	; store MSB in ADCresult10
	bres ADC_CR3,#6		; clear overrun flag
	mov ADC_CSR,#$04	; clear ADC conversion finish flag, and restore max chanel



ADC2:	
	ldw X,#$0000		; load 0 in X
	ldw buffer14,x		; store 0 in buffer14,buffer15
	ldw X,ADCresult6	; load X with contents of ADCresult6,result1 MSB-LSB
	ldw buffer16,x		; store word in buffer16,buffer17
	call bin_to_ascii	; procedure to convert binary value to ASCII , to be converted values in buffer14,15,16,17 msb to lsb , result in buffers to buffers+11
	pointerX #buffers   ; point X to buffers register , start point of ascii value storage, ascii values in buffers
	call write_from_buffers1	; procedure to transmit ascii bytes from buffers +++ to UART
	pointerX #count		; pointerX set on string "counts" string address
	call stringloop		; write the string to UART
	pointerX #EOL		; pointerX points to string EOL
	call stringloop		; transmit end of line ASCII characters, newline,carriage return etc
	
ADC3:	
	ldw X,#$0000		; load 0 in X
	ldw buffer14,x		; store 0 in buffer14,buffer15
	ldw X,ADCresult8	; load X with contents of result2,result1 MSB-LSB
	ldw buffer16,x		; store word in buffer16,buffer17
	call bin_to_ascii	; procedure to convert binary value to ASCII , to be converted values in buffer15,16,17 msb to lsb , result in buffers to buffers+11
	pointerX #buffers   ; point X to buffers register , start point of ascii value storage, ascii values in buffers
	call write_from_buffers1	; procedure to transmit ascii bytes from buffers +++ to UART 
	pointerX #count		; pointerX set on string "counts" string address
	call stringloop		; write the string to UART
	pointerX #EOL		; pointerX points to string EOL
	call stringloop		; transmit end of line ASCII characters, newline,carriage return etc
	
ADC4:	
	ldw X,#$0000		; load 0 in X
	ldw buffer14,x		; store 0 in buffer14,buffer15
	ldw X,ADCresult10	; load X with contents of result2,result1 MSB-LSB
	ldw buffer16,x		; store word in buffer16,buffer17
	call bin_to_ascii	; procedure to convert binary value to ASCII , to be converted values in buffer15,16,17 msb to lsb , result in buffers to buffers+11
	pointerX #buffers   ; point X to buffers register , start point of ascii value storage, ascii values in buffers
	call write_from_buffers1	; procedure to transmit ascii bytes from buffers +++ to UART 
	pointerX #count		; pointerX set on string "counts" string address
	call stringloop		; write the string to UART
	pointerX #EOL		; pointerX points to string EOL
	call stringloop		; transmit end of line ASCII characters, newline,carriage return etc

delay:					; apprx 3 second delay
	mov buffer3,#255
L2:	
	ldw X,#65535
L1:
	decw X
	jrne L1
	dec buffer3
	jrne L2

	jp ADC_READ			; jump to ADC_READ label to restart scan ADC


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; writes a null terminated string to UART
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
stringloop:
	ld a,(X)
	incw X
	cp a,#$00
	jreq exitstringloop
	ld data,a
	call UART_TX
	jp stringloop
exitstringloop:
	ret



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;writes what is in buffers + bytes defined in temp1
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TX_LOOP:
	ld a,(x)			; load A with value of string pointed by X
	ld data,a			; copy yte in A to data register
	call UART_TX		; call UART transmit subroutine
	incw X				; increase pointer X
	dec temp1			; decrease temp1 counter value
	jrne TX_LOOP		; loop to TX_LOOP label till temp1 is above 0
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;writes what is in buffers + bytes defined in temp1, with leading ZERO SUPPRESION
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
write_from_buffers1:
	clr state				; flag register for 1st non zero byte
	pointerX #buffers   	; point X to buffers register , start point of ascii value storage, ascii values in buffers
	mov temp1,#9			; temp1 as counter, 10 values to be printed
TX_LOOPNXZ:
	ld a, state				; copy to A flag register
	cp a,#1					; if 1 all leadings 0 finished. current 0 not ignored
	jreq noload0			; if not1  go to noload0 label and ignore all leading 0
	ld a,(x)				; load A with value of string pointed by X
	cp a,#$30				; is this ASCII 0
	jreq suppress_zero		;if ASCII 0 jump to suppress_zero
noload0:
	mov state,#1			; if above was something other than ASCII 0 load state with 1
	ld a,(x)				; load A with byte pointed by X
	ld data,a				; copy byte in A to data register
	call UART_TX			; call UART transmit subroutine
	jp not_last  			;	xxx
suppress_zero:

  	ld a,temp1				;çopy temp1 to A, if byte count is 2 next byte is last byte xxx
  	cp a,#2					;if counter is 2 we are on 8th byte/next is last byte xxxx
  	jrne not_last				;if not 2 this is not the 2nd last byte ,jump to not_last xxxx
  	ld a,(x)					; load A with byte pointed by X	, last byte ;xxxx
  	ld data,a					; copy byte in A to data register	;xxxx
  	call UART_TX				; call UART transmit subroutine, display last byte even if it is 0	;xxxx
  
not_last:
	incw X					; increase pointer X
	dec temp1				; decrease temp1 counter value
	jrne TX_LOOPNXZ			; loop to TX_LOOP label till temp1 is above 0
	ret						; return to caller

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;transmits a byte to terminal via \UART
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


UART_TX:
	ld a,data
	ld UART1_DR,a
TC_FLAG:
	btjf UART1_SR,#6 ,TC_FLAG
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
string:
	  dc.B " Hello world!" ,'\n','\n','\r',0
	  
count:
	  dc.B " ADC Counts ",0

EOL:
	  dc.B '\n','\r',0
	  	  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;subtraction routine for BIN to ASCII procedure
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
A32bit_subtraction1:	
	ld a,result1
	sub a,buffer4
	ld result1,a
	ld a,result2
	sbc a,buffer3
	ld result2,a
	ld a,result3
	sbc a,buffer2
	ld result3,a
	ld a,result4
	sbc a,buffer1
	ld result4,a
	JRULT load_signbit_register1
	clr signbit
	ret
load_signbit_register1
	mov signbit,#1
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;converts BINARY to ASCII values , 0 to 10000000
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

bin_to_ascii:
	ldw x,buffer16
	ldw data,x			; result 16bit word stored in buffer5 + buffer6 in data and address registers
	ld a,buffer15		; result MSB in buffer4 stored in nibble register sram, concecutive bytes
	ld nibble1,a		; result MSB in buffer4 stored in nibble register sram, concecutive bytes
	clr buffer1			; clear sram registers for bin_to_ascii calculations
	clr buffer2			; clear sram registers for bin_to_ascii calculations
	clr buffer3			; clear sram registers for bin_to_ascii calculations
	clr buffer4			; clear sram registers for bin_to_ascii calculations
	clr buffer5			; clear sram registers for bin_to_ascii calculations
	clr buffer6			; clear sram registers for bin_to_ascii calculations
	clr buffer7			; clear sram registers for bin_to_ascii calculations
	clr buffer8			; clear sram registers for bin_to_ascii calculations
	clr result4			; clear sram registers for bin_to_ascii calculations
	clr result3			; clear sram registers for bin_to_ascii calculations
	clr result2			; clear sram registers for bin_to_ascii calculations
	clr result1			; clear sram registers for bin_to_ascii calculations
	mov result3,nibble1	; mov MSB of result in nibble1 to buffer6 (buffer5,6,7,8 used for holding result)
	ldw x,data			; load result word (LSB1,LSB0) to data & address register in sran (concecutive) 
	ldw result2,x		; load result word (LSB1,LSB0) to data & address register in sran (concecutive)	
onecrore:
	ldw x,#$9680		; load x with low word of 10,000,000
	ldw buffer3,x		; store in buffer3 and buffer4
	ldw x,#$0098		; load x with high word of 10,000,000
	ldw buffer1,x		; store in buffer1 and buffer2,(buffer1,2,3,4 used for holding test value)
	call A32bit_subtraction1		; call 32 bit subtraction routine, buffer5,6,7,8 - buffer1,2,3,4)
	inc temp1			; increase temp register to count how many 1 crrore in result
	ld a,signbit		; copy signbit register contents to accumulator
	jreq onecrore		; if signbit register is 0 (previous subtraction didnt result in negative) branch onecrore label
	dec temp1			; if negative value in subtraction , decrease temp register (we dont count)
revert_result0:	
	ld a,result1		; laod A with LSB of sutracted result1
	add a,buffer4		; add A with LSB0 of value subtracted. we reverse the result to pre negative value
	ld result1,a		; rectified LSB0 stored back in result1 
	ld a,result2		; laod A with LSB1 of sutracted result2
	adc a,buffer3		; add A with LSB1 of value subtracted. we reverse the result to pre negative value
	ld result2,a		; rectified LSB1 stored back in result2
	ld a,result3		; laod A with LSB2 of sutracted result3
	adc a,buffer2		; add A with LSB2 of value subtracted. we reverse the result to pre negative value
	ld result3,a		; rectified LSB2 stored back in result3 
	ld a,result4		; laod A with MSB of sutracted result4
	adc a,buffer1		; add A with MSB of value subtracted. we reverse the result to pre negative value
	ld result4,a		; rectified MSB stored back in result3 
	ld a,#$30			; ascii 0 loaded in A
	add a,temp1			; add temp1 (contains how many decimal places) to ascii 0 to get ascii value of poaition
	ld buffers ,a		; store result of ascii conversion of MSB position in buffers register SRAM
	clr temp1			; clear temp1 for next decimal position calculation
tenlakh:
	ldw x,#$4240
	ldw buffer3,x
	ldw x,#$000f
	ldw buffer1,x
	mov buffer6,nibble1
	ldw x,data
	ldw buffer7,x
	call A32bit_subtraction1
	inc temp1
	ld a,signbit
	jreq tenlakh
	dec temp1
	
	ld a,result1
	add a,buffer4
	ld result1,a		; result LSB1
	ld a,result2
	adc a,buffer3
	ld result2,a		; result LSB2
	ld a,result3
	adc a,buffer2
	ld result3,a		; result LSB3
	ld a,result4
	adc a,buffer1
	ld result4,a		; result MSB
	ld a,#$30			; ascii 0
	add a,temp1
	ld {buffers + 1} ,a	
	clr temp1
onelakh:
	ldw x,#$86A0
	ldw buffer3,x
	ldw x,#$0001
	ldw buffer1,x
	mov buffer6,nibble1
	ldw x,data
	ldw buffer7,x
	call A32bit_subtraction1
	inc temp1
	ld a,signbit
	jreq onelakh
	dec temp1
	
	ld a,result1
	add a,buffer4
	ld result1,a		; result LSB1
	ld a,result2
	adc a,buffer3
	ld result2,a		; result LSB2
	ld a,result3
	adc a,buffer2
	ld result3,a		; result LSB3
	ld a,result4
	adc a,buffer1
	ld result4,a		; result MSB
	ld a,#$30			; ascii 0
	add a,temp1
	ld {buffers + 2} ,a
	clr temp1
tenthousand:
	ldw x,#$2710
	ldw buffer3,x
	ldw x,#$0000
	ldw buffer1,x
	mov buffer6,nibble1
	ldw x,data
	ldw buffer7,x
	call A32bit_subtraction1
	inc temp1
	ld a,signbit
	jreq tenthousand
	dec temp1
	
	ld a,result1
	add a,buffer4
	ld result1,a		; result LSB1
	ld a,result2
	adc a,buffer3
	ld result2,a		; result LSB2
	ld a,result3
	adc a,buffer2
	ld result3,a		; result LSB3
	ld a,result4
	adc a,buffer1
	ld result4,a		; result MSB
	ld a,#$30			; ascii 0
	add a,temp1
	ld {buffers + 3} ,a
	clr temp1
thousand:
	ldw x,#$3e8
	ldw buffer3,x
	ldw x,#$0000
	ldw buffer1,x
	mov buffer6,nibble1
	ldw x,data
	ldw buffer7,x
	call A32bit_subtraction1
	inc temp1
	ld a,signbit
	jreq thousand
	dec temp1
	
	ld a,result1
	add a,buffer4
	ld result1,a		; result LSB1
	ld a,result2
	adc a,buffer3
	ld result2,a		; result LSB2
	ld a,result3
	adc a,buffer2
	ld result3,a		; result LSB3
	ld a,result4
	adc a,buffer1
	ld result4,a		; result MSB
	ld a,#$30			; ascii 0
	add a,temp1
	ld {buffers + 4} ,a
	clr temp1
hundred:
	ldw x,#$0064
	ldw buffer3,x
	ldw x,#$0000
	ldw buffer1,x
	mov buffer6,nibble1
	ldw x,data
	ldw buffer7,x
	call A32bit_subtraction1
	inc temp1
	ld a,signbit
	jreq hundred
	dec temp1
	
	ld a,result1
	add a,buffer4
	ld result1,a		; result LSB1
	ld a,result2
	adc a,buffer3
	ld result2,a		; result LSB2
	ld a,result3
	adc a,buffer2
	ld result3,a		; result LSB3
	ld a,result4
	adc a,buffer1
	ld result4,a		; result MSB
	ld a,#$30			; ascii 0
	add a,temp1
	ld {buffers + 5} ,a
	clr temp1
ten:
	ldw x,#$000A
	ldw buffer3,x
	ldw x,#$0000
	ldw buffer1,x
	mov buffer6,nibble1
	ldw x,data
	ldw buffer7,x
	call A32bit_subtraction1
	inc temp1
	ld a,signbit
	jreq ten
	dec temp1
	
	ld a,result1
	add a,buffer4
	ld result1,a		; result LSB1
	ld a,result2
	adc a,buffer3
	ld result2,a		; result LSB2
	ld a,result3
	adc a,buffer2
	ld result3,a		; result LSB3
	ld a,result4
	adc a,buffer1
	ld result4,a		; result MSB
	ld a,#$30			; ascii 0
	add a,temp1
	ld {buffers + 6} ,a
	clr temp1
UNIT:	
	ld a,#$30			; ascii 0
	add a,result1
	ld {buffers + 7},a
	
	clr buffer1			; clear sram registers for bin_to_ascii calculations
	clr buffer2			; clear sram registers for bin_to_ascii calculations
	clr buffer3			; clear sram registers for bin_to_ascii calculations
	clr buffer4			; clear sram registers for bin_to_ascii calculations
	clr buffer5			; clear sram registers for bin_to_ascii calculations
	clr buffer6			; clear sram registers for bin_to_ascii calculations
	clr buffer7			; clear sram registers for bin_to_ascii calculations
	clr buffer8			; clear sram registers for bin_to_ascii calculations
	clr result4			; clear sram registers for bin_to_ascii calculations
	clr result3			; clear sram registers for bin_to_ascii calculations
	clr result2			; clear sram registers for bin_to_ascii calculations
	clr result1			; clear sram registers for bin_to_ascii calculations
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;





	

	interrupt NonHandledInterrupt
NonHandledInterrupt.l
	iret

	segment 'vectit'
	dc.l {$82000000+main}									; reset
	dc.l {$82000000+NonHandledInterrupt}	; trap
	dc.l {$82000000+NonHandledInterrupt}	; irq0
	dc.l {$82000000+NonHandledInterrupt}	; irq1
	dc.l {$82000000+NonHandledInterrupt}	; irq2
	dc.l {$82000000+NonHandledInterrupt}	; irq3
	dc.l {$82000000+NonHandledInterrupt}	; irq4
	dc.l {$82000000+NonHandledInterrupt}	; irq5
	dc.l {$82000000+NonHandledInterrupt}	; irq6
	dc.l {$82000000+NonHandledInterrupt}	; irq7
	dc.l {$82000000+NonHandledInterrupt}	; irq8
	dc.l {$82000000+NonHandledInterrupt}	; irq9
	dc.l {$82000000+NonHandledInterrupt}	; irq10
	dc.l {$82000000+NonHandledInterrupt}	; irq11
	dc.l {$82000000+NonHandledInterrupt}	; irq12
	dc.l {$82000000+NonHandledInterrupt}	; irq13
	dc.l {$82000000+NonHandledInterrupt}	; irq14
	dc.l {$82000000+NonHandledInterrupt}	; irq15
	dc.l {$82000000+NonHandledInterrupt}	; irq16
	dc.l {$82000000+NonHandledInterrupt}	; irq17
	dc.l {$82000000+NonHandledInterrupt}	; irq18
	dc.l {$82000000+NonHandledInterrupt}	; irq19
	dc.l {$82000000+NonHandledInterrupt}	; irq20
	dc.l {$82000000+NonHandledInterrupt}	; irq21
	dc.l {$82000000+NonHandledInterrupt}	; irq22
	dc.l {$82000000+NonHandledInterrupt}	; irq23
	dc.l {$82000000+NonHandledInterrupt}	; irq24
	dc.l {$82000000+NonHandledInterrupt}	; irq25
	dc.l {$82000000+NonHandledInterrupt}	; irq26
	dc.l {$82000000+NonHandledInterrupt}	; irq27
	dc.l {$82000000+NonHandledInterrupt}	; irq28
	dc.l {$82000000+NonHandledInterrupt}	; irq29

	end
