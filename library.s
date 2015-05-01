	AREA    lib, CODE, READWRITE
	EXPORT output_string
	EXPORT read_string
	EXPORT display_digit
	EXPORT display_led
	EXPORT pin_connect_block_setup_for_uart0
	EXPORT uart_init
	EXPORT write_character
	EXPORT read_character
	EXPORT clear_display
	EXPORT interrupt_init
	EXPORT div_and_mod
	EXPORT generate_new_random
	EXPORT write_char_at_position
	EXPORT generate_bricks
	EXPORT draw_board_init
	EXPORT rgb_led
		
	IMPORT random_number
	IMPORT memory_map
	IMPORT read_char_at_position

Base EQU 0x40000000

newline = "\n"
	ALIGN
		
store_string = "                                "
    ALIGN

digits_SET	
		DCD 0x00001F80 ; 0
        DCD 0x00000300 ; 1 
        DCD 0x00002d80 ; 2
        DCD 0x00002780 ; 3
        DCD 0x00003300 ; 4
        DCD 0x00003680 ; 5
        DCD 0x00003e80 ; 6
        DCD 0x00000380 ; 7
        DCD 0x00003f80 ; 8
        DCD 0x00003780 ; 9
        DCD 0x00003b80 ; A
        DCD 0x00003e00 ; b
        DCD 0x00001c80 ; C
        DCD 0x00002f00 ; d
        DCD 0x00003c80 ; E
        DCD 0x00003880 ; F

	ALIGN	


uart_init										
	STMFD SP!, {R4 - R5, lr}
   	ldr r4, =0xE000C00C
   	MOV r5, #131
   	STRB r5, [r4]

   	ldr r4, =0xE000C000
   	MOV r5, #120
   	STRB r5, [r4]
						   
   	ldr r4, =0xE000C004
   	MOV r5, #0
   	STRB r5, [r4]   

	ldr r4, =0xE000C00C
   	MOV r5, #3
   	STRB r5, [r4]

	bl clear_display

 	LDMFD SP!, {R4 - R5, lr}
	BX lr


interrupt_init
	stmfd sp!, {r0, r4, r5, lr}
	
			; Push button setup		 
	LDR r4, =0xE002C000
	LDR r5, [r4]
	ORR r5, r5, #0x20000000
	BIC r5, r5, #0x10000000
	STR r5, [r4]  ; PINSEL0 bits 29:28 = 10

	LDR r4, =0xFFFFF000
	LDR r5, [r4, #0xC]
	ORR r5, r5, #0x8000 ; External Interrupt 1 
	ORR r5, r5, #0x40;and uart0 pg52
	STR r5, [r4, #0xC]

	ldr r4, =0xFFFFF010 	;interrupt enable register	(VICIntEnable)
	ldr r5, [r4]
	orr r5, r5, #0x10		;enable bit 4 for timer 0
	orr r5, r5, #0x20		;enable bit 5 for timer 1
	orr r5, r5, #0x40		;enable bit 6 for uart0 interrupt
	str r5, [r4]			
	
	ldr r4, =0xFFFFF00C 	; intterupt select register (VICIntSelect)
	ldr r5, [r4]
	orr r5, r5, #0x10		;enable bit 4 for timer 0 FIQ
	orr r5, r5, #0x20		;enable bit 5 for timer 1 FIQ
	orr r5, r5, #0x40		;enable bit 6 for fast interrupt
	str r5, [r4]			

	ldr r4, =0xE000401C		;frequency = 14745600*(5/4)
	ldr r5, =0x465000		; .25 seconds
	str r5, [r4]			;stores speed into mr1

	ldr r4, =0xE0004014		;timer 0
	ldr r5, [r4]			;enable bit 3 to generate interrupt on mr1 == tc 
	orr r5, r5, #0x18		;enable bit 4 to reset tc when mr1 == tc
	str r5, [r4]					
	
	ldr r4, =0xE000801C		;frequency = 14745600*(5/4)
	ldr r5, =0x1194000		; 1 second
	str r5, [r4]

	ldr r4, =0xE000C004		;enable uart interrupt read_data_available
	ldr r5, [r4]
	orr r5, r5, #1
	str r5, [r4]

			; Enable Interrupts
	LDR r4, =0xFFFFF000
	LDR r5, [r4, #0x10] 
	ORR r5, r5, #0x8000 ; External Interrupt 
	ORR r5, r5, #0x40 ;and uart0 pg52
	STR r5, [r4, #0x10]

		; External Interrupt 1 setup for edge sensitive
	LDR r4, =0xE01FC148
	LDR r5, [r4]
	ORR r5, r5, #2  ; EINT1 = Edge Sensitive
	STR r5, [r4]
	
	MRS r0, CPSR			; Enable FIQ's, Disable IRQ's
	BIC r0, r0, #0x40
	ORR r0, r0, #0x80
	MSR CPSR_c, r0
	

	ldmfd sp!, {r0, r4, r5, lr}
	bx lr
	
	;saves string to store_string
read_string    
    STMFD SP!, {r0 - r1, lr}                 
    LDR r1, =store_string  ;account for prompt
read_string_loop        
    bl read_character ;reads character
    CMP r0, #13 ;checks for enter button
    strbne r0, [r1], #1 ;stores the character at the address
    bne read_string_loop
	
	;must be enter
	MOV r0, #0 ;puts last character at address to 0 so easier to find
	strb r0, [r1], #1 ;stores the 0
	LDMFD SP!, {r0 - r1, lr}     
    bx lr  
	
	
;outputs characters from string at r4 untill null termination	
output_string
    STMFD SP!, {r0, r4, lr}
loop    
	LDRB r0, [r4], #1
    BL write_character
    CMP r0, #0
    BNE loop ;output_string
    LDMFD SP!, {r0, r4, lr}
    BX LR


;reads character to r0
read_character 
    STMFD SP!, {R1 - R3, lr}    ; Store register lr on stack
tloop    
	LDR r1, =0xE000C014
    LDR r2, [r1]
    AND r3, r2, #1
    CMP r3, #0
    BEQ tloop
    
	LDR r1, =0xE000C000
    LDRB r0, [r1]
    BL write_character

    LDMFD SP!, {R1 - R3, lr}
    BX LR


;prints r0 to display
write_character
    STMFD SP!, {R1 - R3, lr}
wloop    
	LDR r1, =0xE000C014
    LDR r2, [r1]
    AND r3, r2, #32
    CMP r3, #0
    BEQ wloop
	
    LDR r1, =0xE000C000
    STRB r0 , [r1]
    LDMFD SP!, {R1 - R3, lr}
    BX LR    


read_push_btns
	STMFD SP!, {R1-R12, lr}

stag1		
	LDR r4, =0xE0028018	 ; bit set
	MOV r0, #0x00000000
	STR r0, [r4]
			
	LDR r4, =0xE002801C	 ; bit clear
	MOV r0,	#0x00F00000
	STR r0, [r4]
				
	LDR r4, =0xE0028010 ;loads intput register address
	LDR r0, [r4]; reads what was entered 
	mvn r2, r0
	and r2, r2, #0x00F00000			
			;CMP r0, r2 ; if not changed read again
			
			;beq tagain1 		
	mov r0, r2
	lsr r0, r0, #20
	mov r1,r0
	MOV r8, #0
	and r7, r1, #8
	CMP r7, #8
	addeq r8, r8, #1
			
	and r7, r1, #4
	CMP r7, #4
	addeq r8, r8, #2

	and r7, r1, #2
	CMP r7, #2
	addeq r8, r8, #4

	and r7, r1, #1
	CMP r7, #1
	addeq r8, r8, #8	

	add r0, r8, #48
	cmp r0, #57
	addgt r0, r0, #7

	BL write_character ;if there is a bit equal print one
	add r0, r0, #0			
	
	b stag1
			
quit1	
	LDMFD SP!, {R1-R12, lr}
	BX LR
	
	

	; pass lives to be displayed in r0
display_led	 
	STMFD SP!, {r1 - r12, lr}

	cmp r0, #4
	moveq r1, #15
	cmp r0, #3
	moveq r1, #14
	cmp r0, #2
	moveq r1, #12
	cmp r0, #1
	moveq r1, #8
	cmp r0, #0
	moveq r1, #0

led4		
	MOV r8, #0
	and r7, r1, #8
	CMP r7, #8
	addeq r8, r8, #1
			
	and r7, r1, #4
	CMP r7, #4
	addeq r8, r8, #2

	and r7, r1, #2
	CMP r7, #2
	addeq r8, r8, #4

	and r7, r1, #1
	CMP r7, #1
	addeq r8, r8, #8
			
	MOV r1, r8
	MVN r1, r1, LSL #16 ;shifts value to store_string in board
			
	LDR r4, =0xE002801C  ;load clear for uart
			
	MOV r0, #0x00FF0000 ;value to cleas
			
	STR r0, [r4] ;clear
			
	MOV r0, #0x000F0000 ;value that you write to			
	LDR r4, =0xE0028018 ;setter to write(make it an output)			
	STR r0, [r4];make output						
	LDR r4, =0xE0028014 ;load output uart			
	STR r1, [r4] ;store value writen
					
	LDMFD SP!, {R1-R12, lr}
	BX LR



rgb_led
	STMFD SP!, {r1, r4, lr}
	
stag3
	ldr r4, =0xE002800C ; base address
	
	MOV r1, #0x00260000;load value to clear/whats writen to
	STR r1, [r4] 
	LDR r4, =0xE0028004 ;load where to write in uart
			
	CMP r0, #119; w in Ascii		
	BNE nwhite ;if not white			
	MOV r1, #0x00000000 ;white			
	STR r1, [r4];print white

nwhite		
	CMP r0, #121;y in Ascii			
	BNE nyellow; if not yellow			
	MOV r1, #0x00040000 ;yellow			
	STR r1, [r4];print yellow

nyellow		
	CMP r0, #112;p in Ascii			
	BNE npurple; if not purple			
	MOV r1, #0x00200000 ;purple
	STR r1, [r4];print purple

npurple		
	CMP r0, #98;b in Ascii			
	BNE nblue; if not blue			
	MOV r1, #0x00220000 ;blue			
	STR r1, [r4];print blue
			
nblue		
	CMP r0, #103;g in Ascii 
	BNE ngreen;if not green
	MOV r1, #0x00060000 ;green
	STR r1, [r4];print green

ngreen		
	CMP r0, #114;r in Ascii			
	BNE quit3 ;go to the begining			
	MOV r1, #0x00240000 ;red			
	STR r1, [r4];print red			
			
quit3	
	LDMFD SP!, {r1, r4, lr}
	BX LR


clear_display
    STMFD SP!, {r1, r4, lr}
	LDR r4, =0xE0028008
	MOV r1, #0x00003f80;load value to clear/whats writen to
	ORR r1, #0x00260000
	STR r1, [r4];clear original	
	LDR r4, =0xE002800C;load clear
	STR r1, [r4];
    LDMFD SP!, {r1, r4, lr}
    BX LR


	; pass number in r0
display_digit
	STMFD SP!, {r0 - r4, lr}
	
	ldr r4, =0xE0028000 ; base address
	
	MOV r1, #0x00003f80;load value to clear/whats writen to
	STR r1, [r4, #0xC] ; IOCLR
	
	LDR r3, =digits_SET
	LDR r2, [r3, r0, lsl #2]
	STR r2, [r4, #4] ; store to IOSET

	LDMFD SP!, {r0 - r4, lr}
	BX LR
	
; pass dividend and divisor into r0, and r1.  
; get quotient and remainder in r0, r1.
div_and_mod
	STMFD sp!, {r2-r7, lr}
main
	bl handle_sign
	mov r2, #0		;initialize quotient to 0
	mov r3, r0		;initialize remainder to dividend
	mov r4, #16		;initialize counter to 16
	lsl r1, #16		;logical shift left divisor 16 places
	add r4, r4, #1	;offset addition for loop subtraction
	
main_loop
	sub r4, r4, #1	
	sub r3, r3, r1	;remainder = remainder - divisor
	cmp r3, #0		; is remainder < 0?
	blt remainder_less_than_zero
	lsl r2, #1 		;left shift quotient
	add r2, r2, #1	;lsb should be 1
	b remainder_less_than_zero_branch_merged
	
remainder_less_than_zero
	add r3, r3, r1	;remainder = remainder + divisor
	lsl r2, #1		;left shift quotient, lsb = 0
	
remainder_less_than_zero_branch_merged
	lsr r1, #1		;shift right divisor
	cmp r4, #0		;is counter > 0?
	bgt main_loop
	;quotient and remainder are now known, time to check the sign flag
	cmp r7, #0
	beq flag_not_set
	neg r2, r2		;negate quotient
	neg r3, r3		;negate remainder
flag_not_set
	b end_program
		
handle_sign		
	mov r7, #0		;initialize sign flag to 0
	cmp r0, #0		;check dividend sign
	bgt check_divisor
	mov r7, #1		;increment sign flag if negative
	neg r0, r0		;negate dividend to positive
check_divisor
	cmp r1, #0		;check divisor sign
	bgt handle_sign_finished
	neg r1, r1		;negate divisor to positive
	cmp r7, #0		;check if sign flag already set
	bgt sign_reset
	mov r7, #1		;sign set
	b handle_sign_finished
sign_reset
	mov r7, #0		;sign reset
handle_sign_finished
	bx lr	
end_program
	mov r0, r2		;move the quotient to return register
	mov r1, r3		;move the remainder to return register
	ldmfd sp!, {r2 - r7, lr}
	bx lr	  		; Return to the C program
	

pin_connect_block_setup_for_uart0
    STMFD sp!, {r0, r1, lr}
    LDR r0, =0xE002C000  ; PINSEL0
    LDR r1, [r0]
    ORR r1, r1, #5
    BIC r1, r1, #0xA
    STR r1, [r0]
    LDMFD sp!, {r0, r1, lr}
    BX lr
	
	
		;save 16 - bit random to memory
generate_new_random
	stmfd sp!, {r0 - r3, lr}
	
	ldr r0, =random_number
	ldr r1, [r0]
	
	ldr r2, =0xE2842335
	mul r3, r1, r2
	
	ldr r2, =0x62626355
	add r3, r3, r2
	
random_layer_two	; first layer random number in r3
	
	mov r0, r3
	lsr r0, r0, #16
	mov r1, #4
	bl div_and_mod		; random (0 : 3)
	
	cmp r1, #0
	beq random_layer_two_generator_one
	cmp r1, #1
	beq random_layer_two_generator_two
	cmp r1, #2
	beq random_layer_two_generator_three
	cmp r1, #3 
	beq random_layer_two_generator_four
	
random_layer_two_generator_one
	mov r1, r3
	
	ldr r2, =0xF185A7B1
	mul r3, r1, r2
	
	ldr r2, =0x295C7A1B
	add r3, r3, r2

	b random_generator_done
random_layer_two_generator_two
	mov r1, r3
	
	ldr r2, =0x82E278AB
	mul r3, r1, r2
	
	ldr r2, =0x825EBA73
	add r3, r3, r2
	
	b random_generator_done
random_layer_two_generator_three
	mov r1, r3
	
	ldr r2, =0x25174927
	mul r3, r1, r2
	
	ldr r2, =0xA287B4D7
	add r3, r3, r2
	
	b random_generator_done
random_layer_two_generator_four
	mov r1, r3
	
	ldr r2, =0xC4728D75
	mul r3, r1, r2
	
	ldr r2, =0x398547AD
	add r3, r3, r2
	
random_generator_done		; second layer random number in r3
	
	ldr r0, =random_number
	str r3, [r0]
	
	ldmfd sp!, {r0 - r3, lr}
	bx lr
	
	
num_one_store = "  "
	ALIGN
num_two_store = "  "
	ALIGN
escape_key_sequence		= "                "
	ALIGN
	;take char in r0, x in r1, y in r2
write_char_at_position
	stmfd sp!, {r0 - r8, lr}
	
	mov r3, r0
	mov r4, r1
	mov r5, r2	;free up r0, r1 for div_and_mod	
	
	;store num on
	cmp r4, #10
	bge one_is_double_digit
	
one_is_single_digit
	add r7, r4, #48
	ldr r6, =num_one_store
	strb r7, [r6]
	cmp r5, #10	;check num 2
	bge two_is_double_digit
	b two_is_single_digit
	
	
one_is_double_digit
	mov r0, r4
	mov r1, #10
	bl div_and_mod
	add r0, r0, #48
	add r1, r1, #48
	ldr r6, =num_one_store
	strb r0, [r6]
	strb r1, [r6, #1]
	cmp r5, #10	;check num 2
	bge two_is_double_digit
	b two_is_single_digit
	
	
two_is_double_digit
	mov r0, r5
	mov r1, #10
	bl div_and_mod
	add r0, r0, #48
	add r1, r1, #48
	ldr r6, =num_two_store
	strb r0, [r6]
	strb r1, [r6, #1]
	b done_storing
two_is_single_digit
	ldr r6, =num_two_store
	add r5, r5, #48
	strb r5, [r6]
	
done_storing
	
	; num 1 & 2 are stored in memory, char is in r3

	ldr r4, =escape_key_sequence
	mov r5, #27		
	strb r5, [r4] 			;store ESC
	
	mov r5, #91 	; [
	strb r5, [r4, #1]!		;store bracket
	
	;add num 1
	ldr r6, =num_two_store
	ldrb r7, [r6]
	ldrb r8, [r6, #1] 
	
	strb r7, [r4, #1]!		;store first digit
	cmp r8, #32
	strbne r8, [r4, #1]!	;store second digit if it exists
	
	mov r5, #59				;store seperator 
	strb r5, [r4, #1]!
	
	;add num 2
	ldr r6, =num_one_store
	ldrb r7, [r6]
	ldrb r8, [r6, #1] 
	
	strb r7, [r4, #1]!		;store first digit of num 2
	cmp r8, #32
	strbne r8, [r4, #1]!	;store second digit of num 2 if it exists
	
	mov r5, #102		; H		;store H command
	strb r5, [r4, #1]!
	
	mov r5, #0
	strb r5, [r4, #1]!		;store null termination
	
	ldr r4, =escape_key_sequence	
	bl output_string
	
	mov r0, r3
	
	bl write_character
	
	ldr r0, =num_one_store		; clear memory variables
	mov r1, #32			
	strb r1, [r0]
	strb r1, [r0, #1]
	
	ldr r0, =num_two_store
	strb r1, [r0]
	strb r1, [r0, #1]
	
	ldr r0, =escape_key_sequence
	mov r1, #32
	mov r2, #0
clear_loop						; loop to clear escape sequence in memory
	strb r1, [r0], #1
	add r2, r2, #1
	cmp r2, #8
	bne clear_loop
	
	ldmfd sp!, {r0 - r8, lr}
	bx lr


	;pass number of bricks into r0
generate_bricks
	stmfd sp!, {r0 - r6, lr}

	mov r6, r0
	
brick_gen_loop				;gen x (2:24), y (4:18)

gen_x_loc
	bl generate_new_random
	ldr r0, =random_number
	ldr r1, [r0] 
	mov r0, r1
	lsr r0, r0, #16
	
	mov r1, #25			; upper bound
	bl div_and_mod		; potential x in r1
	cmp r1, #1
	ble gen_x_loc
	mov r4, r1
	
gen_y_loc				; valid x in r4
	bl generate_new_random
	ldr r0, =random_number
	ldr r1, [r0]
	mov r0, r1
	lsr r0, r0, #16
	
	mov r1, #19			; upper bound
	bl div_and_mod		; potential y in r1
	cmp r1, #3
	ble gen_y_loc
	mov r5, r1
	
	mov r1, r4
	mov r2, r5
	bl read_char_at_position	; check if x, y is valid	
	cmp r0, #32			
	bne brick_gen_loop			; if not valid, try again
	
	mov r0, #35
	bl write_char_at_position	; write brick to position

	ldr r3, =memory_map
	sub r1, r1, #1				; alter x, y for memory access 
	sub r2, r2, #1

	ldr r4, [r3, r2, lsl #2]
	strb r0, [r4, r1]
	
	sub r6, r6, #1
	cmp r6, #0
	bne brick_gen_loop			; loop again for more bricks

	ldmfd sp!, {r0 - r6, lr}
	bx lr

	
draw_board_init
	stmfd sp!, {r0, r4, r5, lr}
	
	mov r0, #12
	bl write_character
	
	mov r0, #0
draw_board_loop
	ldr r5, = memory_map
	ldr r4, [r5, r0, lsl #2]
	bl output_string
	add r0, r0, #1
	cmp r0, #17
	bne draw_board_loop
	
	ldmfd sp!, {r0, r4, r5, lr}
	bx lr

	END