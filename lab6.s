	AREA interrupts, CODE, READWRITE
	IMPORT uart_init
	IMPORT output_string
	IMPORT read_string
	IMPORT write_character
	IMPORT read_character
		
	IMPORT newline
		
	EXPORT FIQ_Handler
	EXPORT lab6
	IMPORT store_string
		
BASE EQU 0x40000000
	
prompt 		= "Welcome to lab #6",10
	ALIGN
score		= "score : ",10
	ALIGN	
;the_board 	= "|---------------|\n|               |\n|               |\n|               |\n|               |\n|               |\n|               |\n|               |\n|       *       |\n|               |\n|               |\n|               |\n|",10               |\n|               |\n|               |\n|               |\n|---------------|"
;	ALIGN	
current_direction 		= 1		; 1 up, 2 left, 3 right, 4 down
	ALIGN
current_speed			= 1		; intial speed is 1
	ALIGN
initiation_condition	= 0		;waiting for initialization
	ALIGN	
termination_condition 	= 0 	; set to 1 when game should end
	ALIGN
DEBUG		= "this is timer 1\n",10
	ALIGN

lab6
	stmfd sp!, {r4 - r12, lr}
	
	bl uart_init	
	bl interrupt_init
	
	ldr r4, =prompt
	bl output_string
	
	ldr r4, =score
	bl output_string
	
;	ldr r4, =the_board
;	bl output_string
	
pre_game
	ldr r4, =initiation_condition
	ldr r5, [r4]
	cmp r5, #1
	;bne pre_game
	
	ldr r4, =0xE0004004		;enable timer interrupt
	ldr r5, [r4]
	orr r5, r5, #1
	str r5, [r4]

game_loop
	
	;game mechanics and drawing operating on timed interrupt
	
	ldr r4, =termination_condition
	ldr r5, [r4]
	cmp r5, #1
	bne game_loop

game_termination
	
	;disable interrupts
	ldr r4, =0xFFFFF010 	;interrupt enable register	(VICIntEnable)
	ldr r5, [r4]
	bic r5, r5, #0x10		;enable bit 4 for timer 0
	;orr r5, r5, #0x20		;enable bit 5 for timer 1
	bic r5, r5, #0x40		;enable bit 6 for uart0 interrupt
	str r5, [r4]			

	MOV r0, #12
	BL write_character
	
	ldr r4, =prompt
	bl output_string
	
	ldmfd sp!, {r4 - r12, lr}
	bx lr
	
		
interrupt_init
	stmfd sp!, {r4 - r12, lr}
	
	ldr r4, =0xFFFFF010 	;interrupt enable register	(VICIntEnable)
	ldr r5, [r4]
	orr r5, r5, #0x10		;enable bit 4 for timer 0
	;orr r5, r5, #0x20		;enable bit 5 for timer 1
	orr r5, r5, #0x40		;enable bit 6 for uart0 interrupt
	str r5, [r4]			
	
	ldr r4, =0xFFFFF00C 	; intterupt select register (VICIntSelect)
	ldr r5, [r4]
	orr r5, r5, #0x10		;enable bit 4 for timer 0 FIQ
	;orr r5, r5, #0x20		;enable bit 5 for timer 1 FIQ
	orr r5, r5, #0x40		;enable bit 6 for fast interrupt
	str r5, [r4]			

	ldr r4, =0xE0004014		;timer 0
	ldr r5, [r4]			;enable bit 3 to generate interrupt on mr1 == tc 
	orr r5, r5, #0x18		;enable bit 4 to reset tc when mr1 == tc
	str r5, [r4]					
	
	;ldr r4, =0xE0008014	;timer 1
	;ldr r5, [r4]			;enable bit 3 to generate interrupt on mr1 == tc 
	;orr r5, r5, #0x18		;enable bit 4 to reset tc when mr1 == tc
	;str r5, [r4]

	ldr r4, =0xE000C004		;enable uart interrupt read_data_available
	ldr r5, [r4]
	orr r5, r5, #1
	str r5, [r4]
	
	MRS r0, CPSR			; Enable FIQ's, Disable IRQ's
	BIC r0, r0, #0x40
	ORR r0, r0, #0x80
	MSR CPSR_c, r0
	

	ldmfd sp!, {r4 - r12, lr}
	bx lr
		
		
		
FIQ_Handler		
	ldmfd sp!, {r0 - r2, lr}	
read_data_interrupt
	LDR r0, =0xE000C008
	LDR r1, [r0]
	and r1, r1, #1	;interrupt identification
	cmp r1, #1		;set to 1 if no pending interrupts
	beq timer_one_interrupt
	
	;read data interrupt handler code
	bl read_data_handler
	
timer_one_interrupt
	ldr r0, =0xE0004000
	ldr r1, [r0]
	and r2, r1, #2
	cmp r2, #2		;is mr1 set
	bne FIQ_Exit
	
	;timer 1 matches mr1 handler code
	
	;bl timer_one_mr_one_handler
	ldr r4, =DEBUG
	bl output_string

FIQ_Exit
	LDMFD SP!, {r0 - r2, lr}
	SUBS pc, lr, #4
		
		
		
timer_one_mr_one_handler
	stmfd sp!, {r0, r4, lr}
			
	bl game_mechanics
	
	ldr r0, =termination_condition
	ldr r1, [r0]
	cmp r1, #1
	beq early_termination_break
	
	bl board_draw

early_termination_break
	ldmfd sp!, {r0, r4, lr}
	bx lr	
		

game_mechanics
	stmfd sp!, {r0 - r4, lr}
	
	bl calc_movement
	bl update_score

	ldmfd sp!, {r0 - r4, lr}
	bx lr
	
	
calc_movement
	stmfd sp!, {r0 - r1, lr}
	
	;if destination is 45 or 124
	;set r0 to 1 for early termination
	
	ldr r0, =current_direction
	ldr r1, [r0]
	
	cmp r1, #1
	beq move_up
	
	cmp r1, #2
	beq move_left
	
	cmp r1, #3
	beq move_right
	
	cmp r1, #4
	beq move_down
	
	
move_up
	 
	 ; move up algorithm
	 
	 b move_calc_done
move_left

	;move left algorithm

	b move_calc_done
move_right

	;move right algorithm

	b move_calc_done
move_down
	 
	 ;move down algorithm
	
move_calc_done
	ldmfd sp!, {r0 - r1, lr}
	bx lr
	
update_score
	stmfd sp!, {r0 - r4, lr}
	
	
	ldmfd sp!, {r0 - r4, lr}
	bx lr
	
	
board_draw
	stmfd sp!, {r0 - r4, lr}
	
	
	ldmfd sp!, {r0 - r4, lr}
	bx lr
		
read_data_handler
	stmfd sp!, {r0, r4, lr}
	
	BL read_character

		CMP r0, #105 ; input i - set direction up
		BEQ set_direction_up

		CMP r0, #106	; input j - set direction left
		BEQ set_direction_left

		CMP r0, #107	; input k - set direction right
		BEQ set_direction_right

		CMP r0, #109	; input m - set direction down
		BEQ set_direction_down

		ldr r4, =newline
		bl output_string
		
		B read_data_handler_exit

set_direction_up
	stmfd sp!, {r0 - r3}
	
	ldr r0, =current_direction
	mov r1, #1
	strb r1, [r0]
	
	ldmfd sp!, {r0 - r3}
	b read_data_handler_exit
	   
set_direction_left
	stmfd sp!, {r0 - r3}
	
	ldr r0, =current_direction
	mov r1, #2
	strb r1, [r0]

	ldmfd sp!, {r0 - r3}
	b read_data_handler_exit
	
set_direction_right
	stmfd sp!, {r0 - r3}
	
	ldr r0, =current_direction
	mov r1, #3
	strb r1, [r0]

	ldmfd sp!, {r0 - r3}
	b read_data_handler_exit
	
set_direction_down
	stmfd sp!, {r0 - r3}
	
	ldr r0, =current_direction
	mov r1, #4
	strb r1, [r0]

	ldmfd sp!, {r0 - r3}
	b read_data_handler_exit
	
read_data_handler_exit
    ldmfd sp!, {r0, r4, lr}
    bx lr
		
	end