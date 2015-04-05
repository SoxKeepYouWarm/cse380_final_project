	AREA interrupts, CODE, READWRITE
	IMPORT uart_init
	IMPORT output_string
	IMPORT read_string
	IMPORT write_character
	IMPORT read_character
	IMPORT interrupt_init
	IMPORT div_and_mod
		
	EXPORT FIQ_Handler
	EXPORT lab6

BASE EQU 0x40000000
	
	
	;Winnick variables
curser EQU 0x400000BC

score =  "    SCORE: 000   \n",13,0
	ALIGN
line1 =  "ZZZZZZZZZZZZZZZZZ\n",13,0
	ALIGN
line2 =  "ZB             XZ\n",13,0
	ALIGN
line3 =  "Z Z Z Z Z Z Z Z Z\n",13,0
	ALIGN
line4 =  "Z               Z\n",13,0
	ALIGN
line5 =  "Z Z Z Z Z Z Z Z Z\n",13,0
	ALIGN	
line6 =  "Z               Z\n",13,0
	ALIGN
line7 =  "Z Z Z Z Z Z Z Z Z\n",13,0
	ALIGN
line8 =  "Z               Z\n",13,0
	ALIGN
line9 =  "Z Z Z Z Z Z Z Z Z\n",13,0
	ALIGN
line10 = "Z               Z\n",13,0
	ALIGN
line11 = "Z Z Z Z Z Z Z Z Z\n",13,0
	ALIGN
line12 = "Z               Z\n",13,0
	ALIGN
line13 = "Z Z Z Z Z Z Z Z Z\n",13,0
	ALIGN
line14 = "Z               Z\n",13,0
	ALIGN
line15 = "Z Z Z Z Z Z Z Z Z\n",13,0
	ALIGN
line16 = "ZX             XZ\n",13,0
	ALIGN
line17 = "ZZZZZZZZZZZZZZZZZ\n",13,0
	ALIGN
newadress = "                                                    ",0
	ALIGN
cursor_source = " ",0
	ALIGN	


	;my variables
prompt 		= 	"Welcome to our final project,\ncontrol your character movement with wasd, and place bombs with spacebar\npause the game by pressing the hardware key",10
	ALIGN
current_direction 		= " "		; 1 up, 2 left, 3 right, 4 down
	ALIGN
initiation_condition	= 0			;waiting for initialization
	ALIGN	
termination_condition 	= 0 		; set to 1 when game should end
	ALIGN
game_over				= "game over"
	ALIGN
can_move				= 1			;count moves to time speed increments
	ALIGN
escape_key_sequence		= "        "
	ALIGN

lab6
	stmfd sp!, {r4 - r12, lr}
	ldr r4, =cursor_source
	MOV r0, #0
	STRB r0, [r4]
	bl uart_init	
	bl interrupt_init
	
	mov r0, #97
	mov r1, #5
	mov r2, #2
	bl write_char_at_position
	
	
pre_game
	ldr r4, =initiation_condition		;press "ENTER" to start the game"
	ldrb r5, [r4]
	cmp r5, #1
	bne pre_game
	
	ldr r4, =0xE0004004		;enable timer interrupt
	ldr r5, [r4]
	orr r5, r5, #1
	str r5, [r4]

	;BRICK_GENERATOR

game_loop
	
	;game mechanics and drawing operating on timed interrupt
	
	ldr r4, =termination_condition
	ldrb r5, [r4]
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
	
		
		
		
FIQ_Handler		
	stmfd sp!, {r0 - r2, lr}	
	
read_data_interrupt
	LDR r0, =0xE000C008
	LDR r1, [r0]
	and r1, r1, #1			;interrupt identification
	cmp r1, #1				;set to 1 if no pending interrupts
	beq timer_one_interrupt
	
	;read data interrupt handler code
	bl read_data_handler
			 
	b FIQ_Exit
	
timer_one_interrupt
	ldr r0, =0xE0004000
	ldr r1, [r0]
	and r2, r1, #2
	cmp r2, #2			;is mr1 set
	bne FIQ_Exit
	
	;timer 1 matches mr1 handler code
	bl timer_one_mr_one_handler
	
	LDR R0, =0xE0004000		;unset timer interrupt
	LDR R1, [R0]
	ORR R1, R1, #2
	STR R1, [R0]

FIQ_Exit
	LDMFD SP!, {r0 - r2, lr}
	SUBS pc, lr, #4
		
		
		
timer_one_mr_one_handler
	stmfd sp!, {r0, r1, lr}
			
	;bl game_mechanics
	
	ldr r0, =termination_condition
	ldrb r1, [r0]
	cmp r1, #1
	beq early_termination_break
	
	;bl board_draw

early_termination_break
	ldmfd sp!, {r0, r1, lr}
	bx lr	
		

	
		
read_data_handler
	stmfd sp!, {r4, r5, lr}
	ldr r4, =initiation_condition
	ldrb r5, [r4]
	cmp r5, #1
	bleq main_game_read_data_handler
	blne pre_game_read_data_handler
	ldmfd sp!, {r4, r5, lr}	
	bx lr
		
pre_game_read_data_handler
	stmfd sp!, {r0, r1, lr}
	
	LDR r1, =0xE000C000	;get character
	LDRB r0, [r1]
	
	cmp r0, #13
	bne pre_read_done	; didn't input enter, don't do anything
	
	ldr r0, =initiation_condition	; input was enter
	mov r1, #1
	str r1, [r0]
	
	
pre_read_done	
	ldmfd sp!, {r0, r1, lr}
	bx lr
		
main_game_read_data_handler
	stmfd sp!, {r0 - r5, lr}
	
	LDR r2, =0xE000C000	;get character
	LDRB r0, [r2]


	CMP r0, #119 ; input w - set direction up
	BEQ set_direction_up

	CMP r0, #97	; input a - set direction left
	BEQ set_direction_left

	CMP r0, #115	; input s - set direction right
	BEQ set_direction_right

	CMP r0, #100	; input d - set direction down
	BEQ set_direction_down
		
	B read_data_handler_exit

set_direction_up
	stmfd sp!, {r0 - r1}
	
	ldr r0, =current_direction
	mov r1, #105
	strb r1, [r0]
	
	ldmfd sp!, {r0 - r1}
	b read_data_handler_exit
	   
set_direction_left
	stmfd sp!, {r0 - r1}
	
	ldr r0, =current_direction
	mov r1, #106
	strb r1, [r0]

	ldmfd sp!, {r0 - r1}
	b read_data_handler_exit
	
set_direction_right
	stmfd sp!, {r0 - r1}
	
	ldr r0, =current_direction
	mov r1, #107
	strb r1, [r0]

	ldmfd sp!, {r0 - r1}
	b read_data_handler_exit
	
set_direction_down
	stmfd sp!, {r0 - r1}
	
	ldr r0, =current_direction
	mov r1, #109
	strb r1, [r0]

	ldmfd sp!, {r0 - r1}
	b read_data_handler_exit
	
read_data_handler_exit
    ldmfd sp!, {r0 - r5, lr}
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
	
	
num_one_store = "  "
	ALIGN
num_two_store = "  "
	ALIGN
	;take char in r0, x in r1, y in r2
write_char_at_position
	stmfd sp!, {r4, r5, lr}
	
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
	
	; num 1 & 2 are stored in memory, char is in r0

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
	
	bl write_character

	ldmfd sp!, {r4, r5, lr}
	bx lr

	end