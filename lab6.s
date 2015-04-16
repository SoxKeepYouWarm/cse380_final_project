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

title =  	"        Bomberman        \n",13,0
	ALIGN
score =  	"   Time:120 Score:0000   \n",13,0
	ALIGN
line1 =  	"ZZZZZZZZZZZZZZZZZZZZZZZZZ\n",13,0
	ALIGN
line2 =  	"ZB                     xZ\n",13,0
	ALIGN
line3 =  	"Z Z Z Z Z Z Z Z Z Z Z Z Z\n",13,0
	ALIGN
line4 =  	"Z                       Z\n",13,0
	ALIGN
line5 =  	"Z Z Z Z Z Z Z Z Z Z Z Z Z\n",13,0
	ALIGN	
line6 =  	"Z                       Z\n",13,0
	ALIGN
line7 =  	"Z Z Z Z Z Z Z Z Z Z Z Z Z\n",13,0
	ALIGN
line8 =  	"Z                       Z\n",13,0
	ALIGN
line9 =  	"Z Z Z Z Z Z Z Z Z Z Z Z Z\n",13,0
	ALIGN
line10 = 	"Z                       Z\n",13,0
	ALIGN
line11 = 	"Z Z Z Z Z Z Z Z Z Z Z Z Z\n",13,0
	ALIGN
line12 = 	"Z                       Z\n",13,0
	ALIGN
line13 = 	"Z Z Z Z Z Z Z Z Z Z Z Z Z\n",13,0
	ALIGN
line14 = 	"Z                       Z\n",13,0
	ALIGN
line15 = 	"Z Z Z Z Z Z Z Z Z Z Z Z Z\n",13,0
	ALIGN
line16 = 	"Zx                     +Z\n",13,0
	ALIGN
line17 = 	"ZZZZZZZZZZZZZZZZZZZZZZZZZ\n",13,0
	ALIGN
newadress = "                                                    ",0
	ALIGN
cursor_source = " ",0
	ALIGN	

; MEMORY MAP MEMORY MAP MEMORY MAP MEMORY MAP MEMORY MAP MEMORY MAP MEMORY MAP MEMORY MAP MEMORY MAP
memory_map 	dcdu title
			dcdu score
			dcdu line1
			dcdu line2
			dcdu line3
			dcdu line4
			dcdu line5
			dcdu line6
			dcdu line7
			dcdu line8
			dcdu line9
			dcdu line10
			dcdu line11
			dcdu line12
			dcdu line13
			dcdu line14
			dcdu line15
			dcdu line16
			dcdu line17
			
	ALIGN
	
; MEMORY MAP MEMORY MAP MEMORY MAP MEMORY MAP MEMORY MAP MEMORY MAP MEMORY MAP MEMORY MAP MEMORY MAP 


	;my variables
prompt 		= 	"Welcome to our final project,\ncontrol your character movement with\nwasd, and place bombs with spacebar\npause the game by pressing the hardware key",10
	ALIGN
initiation_condition	= 0			;waiting for initialization
	ALIGN	
termination_condition 	= 0 		; set to 1 when game should end
	ALIGN
game_over				= "game over"
	ALIGN

;game variables
random_number dcdu 	0x00000000
	ALIGN

;mapping variables
bomberman_x_loc 		= 2
	ALIGN
bomberman_y_loc 		= 4
	ALIGN
bomberman_direction		= " "
	ALIGN
enemy_one_x_loc			= 24
	ALIGN
enemy_one_y_loc			= 4
	ALIGN
enemy_one_direction		= 1
	ALIGN
enemy_two_x_loc 		= 2
	ALIGN	
enemy_two_y_loc			= 18
	ALIGN
enemy_two_direction		= 0
	ALIGN
enemy_super_x_loc		= 24
	ALIGN
enemy_super_y_loc		= 18
	ALIGN
enemy_super_direction	= 1
	ALIGN
		

;////////////////////////////////////////////////////////////////
;////////////////////////////////////////////////////////////////		
; GAME_LIFE_CYCLE GAME_LIFE_CYCLE GAME_LIFE_CYCLE GAME_LIFE_CYCLE
;////////////////////////////////////////////////////////////////	
;////////////////////////////////////////////////////////////////


lab6
	stmfd sp!, {r4 - r12, lr}
	ldr r4, =cursor_source
	MOV r0, #0
	STRB r0, [r4]
	bl uart_init	
	bl interrupt_init
	ldr r4, =prompt
	bl output_string
	
	ldr r4, =0xE0008004		; enable timer 1 interrupt
	ldr r5, [r4]			; used to generate random seed
	orr r5, r5, #1
	str r5, [r4]
	
pre_game
	
	ldr r4, =initiation_condition		;press "ENTER" to start the game"
	ldrb r5, [r4]
	cmp r5, #1
	bne pre_game
		
	bl draw_board_init
	
	ldr r4, =line2			; clear escape sequence 
	mov r5, #32				; handled chars from memory
	strb r5, [r4, #1]
	strb r5, [r4, #23]
	
	ldr r4, =line16
	mov r5, #32
	strb r5, [r4, #1]
	strb r5, [r4, #23]


	ldr r4, =0xE0008008
	ldr r5, [r4]			; load tc
	
	ldr r6, =random_number
	str r5, [r6]			; store tc as the first random number

	;BRICK_GENERATOR
	mov r0, #6				; initial number of bricks 
	bl generate_bricks

	ldr r4, =0xE0004004		; enable timer 0 interrupt
	ldr r5, [r4]			; used for timer interrupt
	orr r5, r5, #1
	str r5, [r4]

	

	mov r10, #0
	mov r5, #0
	mov r6, #0
	mov r7, #0
	mov r8, #0
	mov r9, #0
random_debug
	bl generate_new_random
	ldr r1, = random_number
	ldr r0, [r1]
	lsr r0, r0, #28
	mov r1, #10
	bl div_and_mod
	cmp r1, #0
	addeq r5, r5, #1
	cmp r1, #1
	addeq r6, r6, #1
	cmp r1, #2
	addeq r7, r7, #1
	cmp r1, #3
	addeq r8, r8, #1
	cmp r1, #4
	addeq r9, r9, #1
	
	cmp r10, #1000
	bne random_debug 

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
	
	
;////////////////////////////////////////////////////////////////
;////////////////////////////////////////////////////////////////		
; GAME_LIFE_CYCLE GAME_LIFE_CYCLE GAME_LIFE_CYCLE GAME_LIFE_CYCLE
;////////////////////////////////////////////////////////////////	
;////////////////////////////////////////////////////////////////	
	
;//////////////////////////////////////////////////////////////////	
;//////////////////////////////////////////////////////////////////		
; INTERRUPTS INTERRUPTS	INTERRUPTS INTERRUPTS INTERRUPTS INTERRUPTS
;//////////////////////////////////////////////////////////////////
;//////////////////////////////////////////////////////////////////


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
	
	
;//////////////////////////////////////////////////////////////////
;//////////////////////////////////////////////////////////////////		
; INTERRUPTS INTERRUPTS	INTERRUPTS INTERRUPTS INTERRUPTS INTERRUPTS
;//////////////////////////////////////////////////////////////////	
;//////////////////////////////////////////////////////////////////
	
;////////////////////////////////////////////////////////////////
;////////////////////////////////////////////////////////////////		
; MOVE_CHARACTERS MOVE_CHARACTERS MOVE_CHARACTERS MOVE_CHARACTERS
;////////////////////////////////////////////////////////////////	
;////////////////////////////////////////////////////////////////


move_characters
	stmfd sp!, {lr}
	
	bl move_bomberman
	bl move_enemy_one
	;bl move_enemy_two
	;bl move_enemy_super
	
	ldmfd sp!, {lr}
	bx lr
	
move_bomberman
	stmfd sp!, {r0 - r9, lr}
		
	ldr r4, =bomberman_direction
	ldr r5, =bomberman_x_loc
	ldr r6, =bomberman_y_loc
	
	ldrb r7, [r4]	; dir
	ldrb r8, [r5]	; x loc
	ldrb r9, [r6]	; y loc
	
	mov r0, #32
	mov r1, r8			; clear old position
	mov r2, r9	

	cmp r7, #32
	beq done_moving_bomberman
	
	;handling movement mechanics 
	;and mapping movement to memory
	
		
	bl write_char_at_position	;clears old position
	
	
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
	
	bl read_char_at_position		;returns char at move destination to r0
	cmp r0, #32			; empty space?
	beq can_move_bomberman
	cmp r0, #90			; wall?
	beq cant_move_bomberman
	cmp r0, #35			; brick?
	beq cant_move_bomberman
	cmp r0, #111		; bomb?
	beq cant_move_bomberman
	cmp r0, #45			; bomb blast horizontal 
	beq bomberman_died
	cmp r0, #124		; bomb blast vertical
	beq bomberman_died
	cmp r0, #120		; enemy
	beq bomberman_died
	cmp r0, #43			; super enemy
	beq bomberman_died
	; all chars handled
	
	
	
can_move_bomberman	
	mov r0, #66
	bl write_char_at_position		;normal movement
	b done_moving_bomberman
	
cant_move_bomberman
	mov r0, #66
	mov r1, r8
	mov r2, r9
	bl write_char_at_position		;rewrites bomberman to original location
	b done_moving_bomberman
	
bomberman_died
	;handle death
		
	

done_moving_bomberman
	mov r0, #32
	strb r0, [r4]	; clear bomberman_direction
	
	strb r1, [r5]	; update bomberman x loc
	strb r2, [r6]	; update bomberman y loc

	ldmfd sp!, {r0 - r9, lr}
	bx lr
	
	
	
move_enemy_one
	stmfd sp!, {r0 - r10, lr}
	
	ldr r4, =enemy_one_direction
	ldr r5, =enemy_one_x_loc
	ldr r6, =enemy_one_y_loc
	
	ldrb r7, [r4]
	ldrb r8, [r5]
	ldrb r9, [r6]
	
	mov r0, #32
	mov r1, r8			; clear old position
	mov r2, r9	
	
	bl write_char_at_position
	
enemy_one_move_loop
	bl generate_new_random
	ldr r3, =random_number
	ldr r0, [r3]
	
	bic r0, r0, #0xFF000000
	bic r0, r0, #0xFF0000
	
	mov r1, #4
	bl div_and_mod				; direction 0 - 3 (W, A, S, D)
	
	mov r10, r1		; r10 holds new direction, r7 holds old direction
	
	bl generate_new_random
	ldr r3, =random_number
	ldr r0, [r3]
	
	bic r0, r0, #0xFF000000
	bic r0, r0, #0xFF0000
	
	mov r1, #4
	bl div_and_mod				; direction 0 - 3 (W, A, S, D)
	
	cmp r1, #3	
	moveq r7, r10		; 1 in 4 chance to choose new direction
	
	cmp r7, #0		; move up?
	moveq r1, r8
	subeq r2, r9, #1	; negative vertical axis
	
	cmp r7, #1			; move left?
	subeq r1, r8, #1
	moveq r2, r9
	
	cmp r7, #2		; move right?
	addeq r1, r8, #1
	moveq r2, r9
	
	cmp r7, #3		; move down?
	moveq r1, r8
	addeq r2, r9, #1
	
	
	bl read_char_at_position		;returns char at move destination to r0
	cmp r0, #32			; empty space?
	beq can_move_enemy_one
	cmp r0, #90			; wall?
	beq cant_move_enemy_one
	cmp r0, #35			; brick?
	beq cant_move_enemy_one
	cmp r0, #111		; bomb?
	beq cant_move_enemy_one
	cmp r0, #45			; bomb blast horizontal 
	beq enemy_one_died
	cmp r0, #124		; bomb blast vertical
	beq enemy_one_died
	cmp r0, #120		; enemy
	beq cant_move_enemy_one
	cmp r0, #43			; super enemy
	beq cant_move_enemy_one
	
can_move_enemy_one
	mov r0, #120
	bl write_char_at_position
	b done_moving_enemy_one
	
cant_move_enemy_one
	cmp r7, #0
	moveq r7, #3		; invert current direction
	
	cmp r7, #1
	moveq r7, #2
	
	cmp r7, #2
	moveq r7, #1
	
	cmp r7, #3
	moveq r7, #0
	
	b enemy_one_move_loop	; try moving again with new base direction
	
enemy_one_died
	
	
done_moving_enemy_one
	strb r7, [r4]			; stores direction, x, y
	strb r1, [r5]
	strb r2, [r6]
	ldmfd sp!, {r0 - r10, lr}
	bx lr
	
move_enemy_two
	stmfd sp!, {r0 - r10, lr}
	
	ldr r4, =enemy_two_direction
	ldr r5, =enemy_two_x_loc
	ldr r6, =enemy_two_y_loc
	
	ldrb r7, [r4]
	ldrb r8, [r5]
	ldrb r9, [r6]
	
	mov r0, #32
	mov r1, r8			; clear old position
	mov r2, r9	
	
	bl write_char_at_position
	
enemy_two_move_loop
	bl generate_new_random
	ldr r3, =random_number
	ldr r0, [r3]
	
	bic r0, r0, #0xFF000000
	bic r0, r0, #0xFF0000
	
	mov r1, #4
	bl div_and_mod				; direction 0 - 3 (W, A, S, D)
	
	mov r10, r1		; r10 holds new direction, r7 holds old direction
	
	bl generate_new_random
	ldr r3, =random_number
	ldr r0, [r3]
	
	bic r0, r0, #0xFF000000
	bic r0, r0, #0xFF0000
	
	mov r1, #4
	bl div_and_mod				; direction 0 - 3 (W, A, S, D)
	
	cmp r1, #3	
	moveq r7, r10		; 1 in 4 chance to choose new direction
	
	cmp r7, #0		; move up?
	moveq r1, r8
	subeq r2, r9, #1	; negative vertical axis
	
	cmp r7, #1			; move left?
	subeq r1, r8, #1
	moveq r2, r9
	
	cmp r7, #2		; move right?
	addeq r1, r8, #1
	moveq r2, r9
	
	cmp r7, #3		; move down?
	moveq r1, r8
	addeq r2, r9, #1
	
	
	bl read_char_at_position		;returns char at move destination to r0
	cmp r0, #32			; empty space?
	beq can_move_enemy_two
	cmp r0, #90			; wall?
	beq cant_move_enemy_two
	cmp r0, #35			; brick?
	beq cant_move_enemy_two
	cmp r0, #111		; bomb?
	beq cant_move_enemy_two
	cmp r0, #45			; bomb blast horizontal 
	beq enemy_two_died
	cmp r0, #124		; bomb blast vertical
	beq enemy_two_died
	cmp r0, #120		; enemy
	beq cant_move_enemy_two
	cmp r0, #43			; super enemy
	beq cant_move_enemy_two
	
can_move_enemy_two
	mov r0, #120
	bl write_char_at_position
	b done_moving_enemy_two
	
cant_move_enemy_two
	cmp r7, #0
	moveq r7, #3		; invert current direction
	
	cmp r7, #1
	moveq r7, #2
	
	cmp r7, #2
	moveq r7, #1
	
	cmp r7, #3
	moveq r7, #0
	
	b enemy_two_move_loop	; try moving again with new base direction
	
enemy_two_died
	
	
done_moving_enemy_two
	strb r7, [r4]			; stores direction, x, y
	strb r1, [r5]
	strb r2, [r6]
	ldmfd sp!, {r0 - r10, lr}
	bx lr
	
	
	
move_enemy_super
	stmfd sp!, {r0 - r10, lr}
	
	ldr r4, =enemy_super_direction
	ldr r5, =enemy_super_x_loc
	ldr r6, =enemy_super_y_loc
	
	ldrb r7, [r4]
	ldrb r8, [r5]
	ldrb r9, [r6]
	
	mov r0, #32
	mov r1, r8			; clear old position
	mov r2, r9	
	
	bl write_char_at_position
	
enemy_super_move_loop
	bl generate_new_random
	ldr r3, =random_number
	ldr r0, [r3]
	
	bic r0, r0, #0xFF000000
	bic r0, r0, #0xFF0000
	
	mov r1, #4
	bl div_and_mod				; direction 0 - 3 (W, A, S, D)
	
	mov r10, r1		; r10 holds new direction, r7 holds old direction
	
	bl generate_new_random
	ldr r3, =random_number
	ldr r0, [r3]
	
	bic r0, r0, #0xFF000000
	bic r0, r0, #0xFF0000
	
	mov r1, #4
	bl div_and_mod				; direction 0 - 3 (W, A, S, D)
	
	cmp r1, #3	
	moveq r7, r10		; 1 in 4 chance to choose new direction
	
	cmp r7, #0		; move up?
	moveq r1, r8
	subeq r2, r9, #1	; negative vertical axis
	
	cmp r7, #1			; move left?
	subeq r1, r8, #1
	moveq r2, r9
	
	cmp r7, #2		; move right?
	addeq r1, r8, #1
	moveq r2, r9
	
	cmp r7, #3		; move down?
	moveq r1, r8
	addeq r2, r9, #1
	
	
	bl read_char_at_position		;returns char at move destination to r0
	cmp r0, #32			; empty space?
	beq can_move_enemy_super
	cmp r0, #90			; wall?
	beq cant_move_enemy_super
	cmp r0, #35			; brick?
	beq cant_move_enemy_super
	cmp r0, #111		; bomb?
	beq cant_move_enemy_super
	cmp r0, #45			; bomb blast horizontal 
	beq enemy_super_died
	cmp r0, #124		; bomb blast vertical
	beq enemy_super_died
	cmp r0, #120		; enemy
	beq cant_move_enemy_super
	cmp r0, #43			; super enemy
	beq cant_move_enemy_super
	
can_move_enemy_super
	mov r0, #120
	bl write_char_at_position
	b done_moving_enemy_super
	
cant_move_enemy_super
	cmp r7, #0
	moveq r7, #3		; invert current direction
	
	cmp r7, #1
	moveq r7, #2
	
	cmp r7, #2
	moveq r7, #1
	
	cmp r7, #3
	moveq r7, #0
	
	b enemy_super_move_loop	; try moving again with new base direction
	
enemy_super_died
	
	
done_moving_enemy_super
	strb r7, [r4]			; stores direction, x, y
	strb r1, [r5]
	strb r2, [r6]
	ldmfd sp!, {r0 - r10, lr}
	bx lr
	
	
;////////////////////////////////////////////////////////////////
;////////////////////////////////////////////////////////////////		
; MOVE_CHARACTERS MOVE_CHARACTERS MOVE_CHARACTERS MOVE_CHARACTERS
;////////////////////////////////////////////////////////////////	
;////////////////////////////////////////////////////////////////
	
;////////////////////////////////////////////////////////////////
;////////////////////////////////////////////////////////////////		
; BOARD_INTERACTIONS BOARD_INTERACTIONS BOARD_INTERACTIONS
;////////////////////////////////////////////////////////////////	
;////////////////////////////////////////////////////////////////	

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
	 
	 
	 ;take x and y coord in r1, r2. 
	 ;returns char at position in r0
read_char_at_position
	stmfd sp!, {r1 - r5, lr}
	
	;is the character bomberman?
check_for_bomberman	
	ldr r4, =bomberman_x_loc
	ldrb r5, [r4]
	cmp r5, r1
	bne check_for_enemy_one
	
	ldr r4, =bomberman_y_loc
	ldrb r5, [r4]
	cmp r5, r2
	bne check_for_enemy_one
	
	mov r0, #66		;return bomberman char
	b read_char_at_position_done
	
	
check_for_enemy_one
	ldr r4, =enemy_one_x_loc
	ldrb r5, [r4]
	cmp r5, r1
	bne check_for_enemy_two
	
	ldr r4, =enemy_one_y_loc
	ldrb r5, [r4]
	cmp r5, r2
	bne check_for_enemy_two
	
	mov r0, #120
	b read_char_at_position
	

check_for_enemy_two
	ldr r4, =enemy_two_x_loc
	ldrb r5, [r4]
	cmp r5, r1
	bne check_for_enemy_super
	
	ldr r4, =enemy_two_y_loc
	ldrb r5, [r4]
	cmp r5, r2
	bne check_for_enemy_super
	
	mov r0, #120
	b read_char_at_position_done
	
	
check_for_enemy_super
	ldr r4, =enemy_super_x_loc
	ldrb r5, [r4]
	cmp r5, r1
	bne check_memory_map
	
	ldr r4, =enemy_super_y_loc
	ldrb r5, [r4]
	cmp r5, r2
	bne check_memory_map
	
	mov r0, #43
	b read_char_at_position_done
	
check_memory_map
	ldr r4, =memory_map
	sub r2, r2, #1
	ldr r5, [r4, r2, lsl #2]	; line address of y coord
	sub r1, r1, #1
	ldrb r0, [r5, r1]			; char at y coord shifted by x
	
read_char_at_position_done	
	ldmfd sp!, {r1 - r5, lr}
	bx lr
	
draw_board_init
	stmfd sp!, {r0, r4, lr}
	
	mov r0, #12
	bl write_character
	ldr r4, =title
	bl output_string
	ldr r4, =score
	bl output_string
	ldr r4, =line1
	bl output_string
	ldr r4, =line2
	bl output_string
	ldr r4, =line3
	bl output_string
	ldr r4, =line4
	bl output_string
	ldr r4, =line5
	bl output_string
	ldr r4, =line6
	bl output_string
	ldr r4, =line7
	bl output_string
	ldr r4, =line8
	bl output_string
	ldr r4, =line9
	bl output_string
	ldr r4, =line10
	bl output_string
	ldr r4, =line11
	bl output_string
	ldr r4, =line12
	bl output_string
	ldr r4, =line13
	bl output_string
	ldr r4, =line14
	bl output_string
	ldr r4, =line15
	bl output_string
	ldr r4, =line16
	bl output_string
	ldr r4, =line17
	bl output_string
	
	ldmfd sp!, {r0, r4, lr}
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
	bic r0, r0, #0xFF000000
	bic r0, r0, #0x00FF0000
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
	bic r0, r0, #0xFF000000
	bic r0, r0, #0x00FF0000
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
	
	
;////////////////////////////////////////////////////////////////
;////////////////////////////////////////////////////////////////		
; BOARD_INTERACTIONS BOARD_INTERACTIONS BOARD_INTERACTIONS
;////////////////////////////////////////////////////////////////	
;////////////////////////////////////////////////////////////////		
	
	;save 8 - bit random to memory
generate_new_random
	stmfd sp!, {r0 - r3, lr}
	
	ldr r0, =random_number
	ldr r1, [r0]
	ldr r2, =0x15A4E35
	mul r3, r1, r2
	
	ldr r2, =0x34865
	add r3, r3, r2
	
	;and r3, r3, #0xFF
	str r3, [r0]
	
	ldmfd sp!, {r0 - r3, lr}
	bx lr
	
	
	end