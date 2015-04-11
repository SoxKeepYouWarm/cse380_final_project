	AREA interrupts, CODE, READWRITE
	IMPORT uart_init
	IMPORT output_string
	IMPORT read_string
	IMPORT write_character
	IMPORT read_character
	IMPORT interrupt_init
	IMPORT div_and_mod
	;IMPORT write_char_at_position
	IMPORT double_game_speed
	IMPORT halve_game_speed
		
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
initiation_condition	= 0			;waiting for initialization
	ALIGN	
termination_condition 	= 0 		; set to 1 when game should end
	ALIGN
game_over				= "game over"
	ALIGN


;mapping variables
bomberman_x_loc 		= 3
	ALIGN
bomberman_y_loc 		= 3
	ALIGN
bomberman_direction		= " "
	ALIGN
enemy_one_x_loc			= 17
	ALIGN
enemy_one_y_loc			= 3
	ALIGN
enemy_one_direction		= 0
	ALIGN
enemy_two_x_loc 		= 3
	ALIGN	
enemy_two_y_loc			= 18
	ALIGN
enemy_two_direction		= 0
	ALIGN
enemy_super_x_loc		= 17
	ALIGN
enemy_super_y_loc		= 18
	ALIGN
enemy_super_direction	= 0
	ALIGN
		
		

lab6
	stmfd sp!, {r4 - r12, lr}
	ldr r4, =cursor_source
	MOV r0, #0
	STRB r0, [r4]
	bl uart_init	
	bl interrupt_init
	
	mov r0, #66
	mov r1, #3
	mov r2, #3
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
	
	;bl move_characters
	
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
			
	bl move_characters
	
	ldr r0, =termination_condition
	ldrb r1, [r0]
	cmp r1, #1
	beq early_termination_break
	
	

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
	strb r1, [r0]
	
pre_read_done	
	ldmfd sp!, {r0, r1, lr}
	bx lr
		
		
main_game_read_data_handler
	stmfd sp!, {r0 - r2, lr}
	
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
	
	ldr r0, =bomberman_direction
	mov r1, #119
	strb r1, [r0]
	
	b read_data_handler_exit
	   
set_direction_left
	
	ldr r0, =bomberman_direction
	mov r1, #97
	strb r1, [r0]

	b read_data_handler_exit
	
set_direction_right
	
	ldr r0, =bomberman_direction
	mov r1, #115
	strb r1, [r0]

	b read_data_handler_exit
	
set_direction_down
	
	ldr r0, =bomberman_direction
	mov r1, #100
	strb r1, [r0]

	b read_data_handler_exit
	
read_data_handler_exit
    ldmfd sp!, {r0 - r2, lr}
    bx lr
	
	
move_characters
	stmfd sp!, {lr}
	
	bl move_bomberman
	;bl move_enemy_one
	;bl move_enemy_two
	;bl move_enemy_super
	
	ldmfd sp!, {lr}
	bx lr
	
move_bomberman
	stmfd sp!, {r0 - r9, lr}
		
	ldr r4, =bomberman_direction
	ldr r5, =bomberman_x_loc
	ldr r6, =bomberman_y_loc
	
	ldrb r7, [r4]
	ldrb r8, [r5]
	ldrb r9, [r6]
	
	cmp r7, #32
	beq no_direction_input
	
	;handling movement mechanics 
	;and mapping movement to memory
	
	mov r0, #32
	mov r1, r8			; clear old position
	mov r2, r9		
	bl write_char_at_position
	
	cmp r7, #119		; move up?
	moveq r1, r8
	subeq r2, r9, #1	; negative vertical axis
	
	cmp r7, #97			; move left?
	subeq r1, r8, #1
	moveq r2, r9
	
	cmp r7, #100		; move right?
	addeq r1, r8, #1
	moveq r2, r9
	
	cmp r7, #115		; move down?
	moveq r1, r8
	addeq r2, r9, #1
	
	mov r0, #66
	bl write_char_at_position
	
	mov r0, #32
	strb r0, [r4]	; clear bomberman_direction
	
	strb r1, [r5]	; update bomberman x loc
	strb r2, [r6]	; update bomberman y loc
	
no_direction_input
	ldmfd sp!, {r0 - r9, lr}
	bx lr
	
	
	
move_enemy_one
	stmfd sp!, {r0 - r2, lr}
	
	ldr r0, =enemy_one_x_loc
	ldr r1, =enemy_one_y_loc
	ldr r2, =enemy_one_direction
	
	;handling movement mechanics 
	;and mapping movement to memory
	
	mov r0, #120
	mov r1, #0; new x coordinate
	mov r2, #0; new y coordinate
	bl write_char_at_position
	ldmfd sp!, {r0 - r2, lr}
	bx lr
	
move_enemy_two
	stmfd sp!, {r0 - r2, lr}
	
	ldr r0, =enemy_two_x_loc
	ldr r1, =enemy_two_y_loc
	ldr r2, =enemy_two_direction
	
	;handling movement mechanics 
	;and mapping movement to memory	
	
	mov r0, #120
	mov r1, #0; new x coordinate
	mov r2, #0; new y coordinate
	bl write_char_at_position
	ldmfd sp!, {r0 - r2, lr}
	bx lr
	
move_enemy_super
	stmfd sp!, {r0 - r2, lr}
	
	ldr r0, =enemy_super_x_loc
	ldr r1, =enemy_super_y_loc
	ldr r2, =enemy_super_direction
	
	;handling movement mechanics 
	;and mapping movement to memory	
	
	mov r0, #43
	mov r1, #0; new x coordinate
	mov r2, #0; new y coordinate
	bl write_char_at_position
	
	ldmfd sp!, {r0 - r2, lr}
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

	ldmfd sp!, {r0 - r8, lr}
	bx lr
	 
	
	end