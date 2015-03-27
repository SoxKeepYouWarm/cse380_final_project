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
	
	
	;Winnick variables
curser EQU 0x400000BC

score =  "   SCORE: 000    \n",13,0
	ALIGN
line1 =  "|---------------|\n",13,0
	ALIGN
line2 =  "|               |\n",13,0
	ALIGN
line3 =  "|               |\n",13,0
	ALIGN
line4 =  "|               |\n",13,0
	ALIGN
line5 =  "|               |\n",13,0
	ALIGN	
line6 =  "|               |\n",13,0
	ALIGN
line7 =  "|               |\n",13,0
	ALIGN
line8 =  "|               |\n",13,0
	ALIGN
line9 =  "|       *       |\n",13,0
	ALIGN
line10 = "|               |\n",13,0
	ALIGN
line11 = "|               |\n",13,0
	ALIGN
line12 = "|               |\n",13,0
	ALIGN
line13 = "|               |\n",13,0
	ALIGN
line14 = "|               |\n",13,0
	ALIGN
line15 = "|               |\n",13,0
	ALIGN
line16 = "|               |\n",13,0
	ALIGN
line17 = "|---------------|\n",13,0
	ALIGN
newadress = "                                                    ",0
	ALIGN
cursor_source = " ",0
	ALIGN	
	
	
	;my variables
prompt 		= "Welcome to lab #6",10
	ALIGN
current_direction 		= 1			; 1 up, 2 left, 3 right, 4 down
	ALIGN
initiation_condition	= 0			;waiting for initialization
	ALIGN	
termination_condition 	= 0 		; set to 1 when game should end
	ALIGN
game_over				= "game over"
	ALIGN
		


lab6
	stmfd sp!, {r4 - r12, lr}
	
	bl uart_init	
	bl interrupt_init
	
	ldr r4, =prompt
	bl output_string
	
	ldr r4, =score
	bl output_string
	
	bl board_draw
	
pre_game
	ldr r4, =initiation_condition
	ldr r5, [r4]
	cmp r5, #1
	bne pre_game
	
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
	
	ldr r4, =0xE000401C		;frequency = 14745600hz
	mov r5, #0x384000		;set to 0x384000 for counting 1/4 seconds
	str r5, [r4]			;stores speed into mr1

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
	beq FIQ_Exit
	
	;read data interrupt handler code
	bl read_data_handler
	
timer_one_interrupt
	ldr r0, =0xE0004000
	ldr r1, [r0]
	and r2, r1, #2
	cmp r2, #2		;is mr1 set
	bne FIQ_Exit
	
	;timer 1 matches mr1 handler code
	bl timer_one_mr_one_handler

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
	
	bl winnick_mechanics

	ldmfd sp!, {r0 - r4, lr}
	bx lr
	
	
winnick_mechanics
	
		STMFD SP!, {r0-r12, lr}   ; Save registers
		
bloop   LDR r2, =0xE000C014
        LDR r3, [r2]
        AND r5, r3, #1
        CMP r5, #0
        BEQ bloop
		LDR r2, =0xE000C000
		LDRB r0, [r2]

		LDR r4,= curser
		LDR r5,= cursor_source
		LDRB r6, [r5]
		cmp r6, #0
		BEQ first
		LDR r5, =newadress
		LDR r4, [r5]
		b letters
first
		MOV r2, #1
		STRB r2, [r5]	
letters
			LDRB r1, [r4]
	
			CMP r0, #105 ;i branch to off			
			BNE letterj
			MOV r2, #45
			LDRB r3, [r4, #-20]
			CMP r2, r3
			BEQ quit
			MOV r2, #32
			STRB r2, [r4]
			SUB r4, r4, #20
			STRB r1, [r4]
			LDR r5, =newadress
			STR r4, [r5]
			b scoreinc

letterj		CMP r0, #106	;j branch clear
			BNE letterm
			MOV r2, #124
			LDRB r3, [r4, #-1]
			CMP r2, r3
			BEQ quit
			MOV r2, #32
			STRB r2, [r4]
			SUB r4, r4, #1
			STRB r1, [r4]
			LDR r5, =newadress
			STR r4, [r5]
			b scoreinc
			
letterm		CMP r0, #109 ;m branch random
			BNE letterk
			MOV r2, #45
			LDRB r3, [r4, #20]
			CMP r2, r3
			BEQ quit
			MOV r2, #32
			STRB r2, [r4]
			ADD r4, r4, #20
			STRB r1, [r4]
			LDR r5, =newadress
			STR r4, [r5]
			b scoreinc
			

letterk		CMP r0, #107	; branch quit
			BNE quit
			MOV r2, #124
			LDRB r3, [r4, #1]
			CMP r2, r3
			BEQ quit
			MOV r2, #32
			STRB r2, [r4]
			ADD r4, r4, #1
			STRB r1, [r4]
			LDR r5, =newadress
			STR r4, [r5]
			b scoreinc
			
			
scoreinc	LDR r4, =0x4000000A
			LDRH r3, [r4]
			MOV r3, r3, LSL #16
			LDR r4, =0x4000000C
			LDRH r5, [r4]
			ADD r3, r5
			ADD r3, #0x00000100
			AND r7, r3, #0x00003A00
			CMP r7, #0x00003A00
			BNE TEN
			EOR r3, #0x0A00
			ADD r3, #1
			AND r7, r3, #0x0000003A
			CMP r7, #0x0000003A
			BNE TEN
			EOR r3, #0x00000A
			ADD r3, #0x01000000
			
TEN			MOV r5, r3
			MOV r3, r3, LSR #16
			LDR r4, =0x4000000A
			STRH r3, [r4]
			LDR r4, =0x4000000C
			STRH r5, [r4]
quit		
	ldr r0, =termination_condition
	mov r1, #1
	str r1, [r0]
	LDMFD SP!, {r0-r12, lr}   ; Restore registers
	bx lr
	
board_draw
	stmfd sp!, {r0, r4, lr}
	
	MOV r0, #12
	BL write_character
	LDR r4,= score
	BL output_string
	LDR r4,= line1
	BL output_string
	LDR r4,= line2
	BL output_string
	LDR r4,= line3
	BL output_string
	LDR r4,= line4
	BL output_string
	LDR r4,= line5
	BL output_string
	LDR r4,= line6
	BL output_string
	LDR r4,= line7
	BL output_string
	LDR r4,= line8
	BL output_string
	LDR r4,= line9
	BL output_string
	LDR r4,= line10
	BL output_string
	LDR r4,= line11
	BL output_string
	LDR r4,= line12
	BL output_string
	LDR r4,= line13
	BL output_string
	LDR r4,= line14
	BL output_string
	LDR r4,= line15
	BL output_string
	LDR r4,= line16
	BL output_string
	LDR r4,= line17
	BL output_string
	
	ldmfd sp!, {r0, r4, lr}
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
	
double_game_speed
	stmfd sp!, {r0 - r1, lr}
	
	ldr r0, =0xE000401C		;load mr1
	ldr r1, [r0]
	lsr r1, #1				;half delay time				
	str r1, [r0]
	
	ldmfd sp!, {r0 - r1, lr}
	bx lr
	
halve_game_speed
	stmfd sp!, {r0 - r1, lr}
	
	ldr r0, =0xE000401C		;load mr1
	ldr r1, [r0]
	lsl r1, #1				;double delay time
	str r1, [r0]
	
	ldmfd sp!, {r0 - r1, lr}
	bx lr
		
	end