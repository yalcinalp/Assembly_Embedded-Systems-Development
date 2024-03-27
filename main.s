PROCESSOR 18F8722

#include <xc.inc>

; CONFIGURATION (DO NOT EDIT)
; CONFIG1H
CONFIG OSC = HSPLL      ; Oscillator Selection bits (HS oscillator, PLL enabled (Clock Frequency = 4 x FOSC1))
CONFIG FCMEN = OFF      ; Fail-Safe Clock Monitor Enable bit (Fail-Safe Clock Monitor disabled)
CONFIG IESO = OFF       ; Internal/External Oscillator Switchover bit (Oscillator Switchover mode disabled)
; CONFIG2L
CONFIG PWRT = OFF       ; Power-up Timer Enable bit (PWRT disabled)
CONFIG BOREN = OFF      ; Brown-out Reset Enable bits (Brown-out Reset disabled in hardware and software)
; CONFIG2H
CONFIG WDT = OFF        ; Watchdog Timer Enable bit (WDT disabled (control is placed on the SWDTEN bit))
; CONFIG3H
CONFIG LPT1OSC = OFF    ; Low-Power Timer1 Oscillator Enable bit (Timer1 configured for higher power operation)
CONFIG MCLRE = ON       ; MCLR Pin Enable bit (MCLR pin enabled; RE3 input pin disabled)
; CONFIG4L
CONFIG LVP = OFF        ; Single-Supply ICSP Enable bit (Single-Supply ICSP disabled)
CONFIG XINST = OFF      ; Extended Instruction Set Enable bit (Instruction set extension and Indexed Addressing mode disabled (Legacy mode))
CONFIG DEBUG = OFF      ; Disable In-Circuit Debugger


GLOBAL var1
GLOBAL var2
GLOBAL var3
    
GLOBAL prev_re0
GLOBAL prev_re1

GLOBAL b_work
GLOBAL c_work



; Define space for the variables in RAM
PSECT udata_acs
var1:
    DS 1 ; Allocate 1 byte for var1
var2:
    DS 1
var3:
    DS 1

prev_re0:
    DS 1
prev_re1:
    DS 1 
 
    
b_work:
    DS 1
c_work:
    DS 1
    

PSECT resetVec,class=CODE,reloc=2
resetVec:
    goto       main

PSECT CODE
main:
    clrf var1	; var1 = 0
    clrf var2
    clrf var3
    
    clrf prev_re0
    clrf prev_re1
    
    clrf b_work
    clrf c_work
    
    
    ; PORTB
    ; LATB
    ; TRISB determines whether the port is input/output
    ; set output ports
    
    clrf TRISB
    clrf TRISC
    clrf TRISD
    setf TRISE ; PORTE is input

    setf LATB ; alp: this one light up all as well 
    setf LATC ; light up all pins in PORTC
    setf LATD
    
    call busy_wait
    
    clrf LATB
    clrf LATC ; light up all pins in PORTC
    clrf LATD

main_loop:
    ; Round robin
    call main_wait			
    call update_display			
    goto main_loop

busy_wait:
    
    ; for (var3 = 5; var3 != 0; ; --var3)
	; for (var2 = 0; var2 != 255; ; ++var1)
	    ; for (var1 = 255; var1 != 0; --var1)
    
    movlw 00000101B
    movwf var3
    
    most_outer_loop:
	
	    movlw 0
	    movwf var2		; var2 = 0
	    outer_loop_start:
		setf var1	; var1 = 255
		loop_start:
		    decf var1
		    bnz loop_start
		incfsz var2	 
		bra outer_loop_start
	
	decf var3
	bnz most_outer_loop
	
    return
    
    
main_wait:
    ; similar to busy_wait but half time
    
    movlw 00000101B
    movwf var3
    
    most_outer_loop2:
	
	    movlw 192
	    movwf var2		; var2 = 192
	    outer_loop_start2:
		movlw 77
		movwf var1	; var1 = 77
		loop_start2:
		    decf var1
		    
		    call check_buttons
		    
		    bnz loop_start2
		incfsz var2	  
		bra outer_loop_start2
	
	decf var3
	bnz most_outer_loop2
	
    return

curr_re0_check:
    
    btfss PORTE, 0
	btg c_work, 0
    return
    
curr_re1_check:
    
    btfss PORTE, 1
	btg b_work, 0
    return
    
 
check_buttons:
    
    ; if (prev_re0 == 1 AND curr_re0 == 0): b_state_change = 1
    ; in all conditions we need to update prev_re0 and prev_re1 all the time
    
    btfsc prev_re1, 0
	call curr_re1_check
	
    bcf prev_re1, 0	    ; Clear prev_re1
    btfsc PORTE, 1	    ; Check if PORTE[1] is set
	bsf prev_re1, 0     ; Set prev_re1 if PORTE[1] was set
	
    btfsc prev_re0, 0
	call curr_re0_check
    
    bcf prev_re0, 0	    ; Clear prev_re0
    btfsc PORTE, 0	    ; Check if LSB of PORTE is set
	bsf prev_re0, 0     ; Set prev_re0 if PORTE LSB was set

    return

usual_b_light:
    
    rlncf LATB		   ; shift bits to left and rotate the most sig. bit?? 
    bsf LATB, 0
    
    return
  

b_algo_light:
    
    ; if LATB == 255 (means that all leds are up) we need to reset it
    btfss LATB, 7
	bra else2
    clrf LATB
    bra continue2
    else2:
	call usual_b_light
    continue2:
    return

    
usual_c_light:
    
    rrncf LATC		; shift bits to right and rotate the most sig. bit?? 
    bsf LATC, 7		; Set the 7th bit of LATC to "1"

    return
    
    
c_algo_light:
    ; if LATC == 255 (means that all leds are up) we need to reset it
    btfss LATC, 0
	bra else3
    clrf LATC
    bra continue3
    else3:
	call usual_c_light
    continue3:
    return    
    

handle_b:
    
    btfss b_work, 0
	bra dont_light_b

    call b_algo_light
    bra continue4
    dont_light_b:
	clrf LATB

    continue4:
    return
    
handle_c:

    btfss c_work, 0
	bra dont_light_c
	
    call c_algo_light
    bra continue5
    
    dont_light_c:
    	clrf LATC    	
    continue5:

    return 
    

update_display:
    
    btg PORTD, 0
    call handle_b
    call handle_c
    return
    
end resetVec
