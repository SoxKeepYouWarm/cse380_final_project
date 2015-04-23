	AREA interrupts, CODE, READWRITE
	IMPORT uart_init
	IMPORT output_string
	IMPORT read_string
	IMPORT write_character
	IMPORT read_character
	IMPORT interrupt_init
	IMPORT div_and_mod
	IMPORT generate_new_random
	IMPORT write_char_at_position
	IMPORT generate_bricks
	IMPORT draw_board_init
		
	EXPORT FIQ_Handler
	EXPORT lab6
	EXPORT random_number
	EXPORT memory_map
	EXPORT read_char_at_position

BASE EQU 0x40000000
	
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


; MEMORY MAP MEMORY MAP MEMORY MAP MEMORY MAP MEMORY MAP MEMORY MAP MEMORY MAP MEMORY MAP MEMORY MAP
memory_map 	dcd	 title
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
current_level = 1
	ALIGN

;mapping variables

bomberman_x_loc 		= 2
	ALIGN
bomberman_y_loc 		= 4
	ALIGN
bomberman_direction		= " "
	ALIGN
bomberman_dead			= 0
	ALIGN
enemy_one_x_loc			= 24
	ALIGN
enemy_one_y_loc			= 4
	ALIGN
enemy_one_direction		= 1
	ALIGN
enemy_one_dead			= 0
	ALIGN
enemy_two_x_loc 		= 2
	ALIGN	
enemy_two_y_loc			= 18
	ALIGN
enemy_two_direction		= 0
	ALIGN
enemy_two_dead			= 0
	ALIGN
enemy_super_x_loc		= 24
	ALIGN
enemy_super_y_loc		= 18
	ALIGN
enemy_super_direction	= 1
	ALIGN
enemy_super_dead		= 0
	ALIGN
bomb_set				= 0
	ALIGN
bomb_input				= 0
	ALIGN
bomb_timer				= 0
	ALIGN
bomb_x_loc				= 0 
	ALIGN
bomb_y_loc				= 0
	ALIGN

;////////////////////////////////////////////////////////////////
;////////////////////////////////////////////////////////////////		
; GAME_LIFE_CYCLE GAME_LIFE_CYCLE GAME_LIFE_CYCLE GAME_LIFE_CYCLE
;////////////////////////////////////////////////////////////////	
;////////////////////////////////////////////////////////////////


lab6
	stmfd sp!, {r4 - r12, lr}

	bl uart_init	
	bl interrupt_init
	ldr r4, =prompt
	;bl output_string
	
	ldr r4, =0xE0008004		; enable timer 1 interrupt
	ldr r5, [r4]			; used to generate random seed
	orr r5, r5, #1
	str r5, [r4]
	
pre_game
	
	ldr r4, =initiation_condition		;press "ENTER" to start the game"
	ldrb r5, [r4]
	cmp r5, #1
	bne pre_game
		
	ldr r4, =0xE0008008
	ldr r5, [r4]			; load tc
	
	ldr r6, =random_number
	str r5, [r6]			; store tc as the first random number
	
level_init
	
	bl draw_board_init
	
	ldr r4, =line2			; clear escape sequence 
	mov r5, #32				; handled chars from memory
	strb r5, [r4, #1]
	strb r5, [r4, #23]
	
	ldr r4, =line16			; fixes memory
	mov r5, #32
	strb r5, [r4, #1]
	strb r5, [r4, #23]

	
	ldr r4, =current_level	;BRICK_GENERATOR
	ldrb r5, [r4]
	sub r5, r5, #1
	mov r4, #3
	mul r6, r5, r4	
	add r0, r6, #10 	; initial number of bricks 
	bl generate_bricks

	ldr r4, =0xE0004004		; enable timer 0 interrupt
	ldr r5, [r4]			; used for timer interrupt
	orr r5, r5, #1
	str r5, [r4]
	
	b skip_debug_code
	; BOMB DEBUG BOMB DEBUG 
	;////////////////////////
	
	ldr r4, =bomb_timer
	mov r0, #0
	strb r0, [r4]
	ldr r1, [r4]
	sub r1, r1, #1
	str r1, [r4]
	ldr r2, [r4]
	
	
	ldr r4, =bomb_x_loc		; save current bomberman x,y 
	mov r8, #4
	strb r8, [r4]			; as bomb x, y
	ldr r4, =bomb_y_loc
	mov r9, #4
	strb r9, [r4]
	
	ldr r4, =bomb_set		; set bomb_set to 1
	mov r5, #1
	strb r5, [r4]
	
	ldr r4, =bomb_timer
	mov r5, #5
	strb r5, [r4]
	;////////////////////////
skip_debug_code

game_loop
	
	
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
	
	bl bomb_handler
	bl move_characters
	
	ldr r1, =bomberman_dead
	ldrb r0, [r1]
	
	cmp r0, #1
	; decrease lives
	; if enemy living, move back to original position
	; move bomberman back to original position
	; update variables, dont redraw board
	
	; test for all enemies dead
	ldr r1, =enemy_one_dead
	ldrb r0, [r1]
	cmp r0, #1
	bne turn_complete
	
	ldr r1, =enemy_two_dead
	ldrb r0, [r1]
	cmp r0, #1
	bne turn_complete
	
	ldr r1, =enemy_super_dead
	ldrb r0, [r1]
	cmp r0, #1
	bne turn_complete
	
	; all enemies are dead
	
	; level up
	; reset everything
	
turn_complete

	; decrease timer
	
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
	stmfd sp!, {r0 - r1, lr}
	
	ldr r1, =0xE000C000		;get character
	ldrb r0, [r1]
	
	cmp r0, #13	
	ldreq r0, =initiation_condition	; input was enter
	moveq r1, #1
	strbeq r1, [r0]
	
	ldmfd sp!, {r0 - r1, lr}
	bx lr
		
		
main_game_read_data_handler
	stmfd sp!, {r0 - r1, lr}
	
	ldr r1, =0xE000C000	;get character
	ldrb r0, [r1]

	cmp r0, #119 ; input w - set direction up
	ldreq r1, =bomberman_direction
	strbeq r0, [r1]

	cmp r0, #97	; input a - set direction left
	ldreq r1, =bomberman_direction
	strbeq r0, [r1]

	cmp r0, #115	; input s - set direction down
	ldreq r1, =bomberman_direction
	strbeq r0, [r1]

	cmp r0, #100	; input d - set direction right
	ldreq r1, =bomberman_direction
	strbeq r0, [r1]
	
	cmp r0, #32		; input *space* - set bomb, unset
	ldreq r0, =bomberman_direction
	moveq r1, #0
	strbeq r1, [r0]
	
	ldreq r0, =bomb_input
	moveq r1, #1
	strbeq r1, [r0]
		
    ldmfd sp!, {r0 - r1, lr}
    bx lr
	
	
;//////////////////////////////////////////////////////////////////
;//////////////////////////////////////////////////////////////////		
; INTERRUPTS INTERRUPTS	INTERRUPTS INTERRUPTS INTERRUPTS INTERRUPTS
;//////////////////////////////////////////////////////////////////	
;//////////////////////////////////////////////////////////////////
	
	
;/////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////		
; BOMB_HANDLER BOMB_HANDLER BOMB_HANDLER BOMB_HANDLER BOMB_HANDLER
;/////////////////////////////////////////////////////////////////	
;/////////////////////////////////////////////////////////////////

	
bomb_handler
	stmfd sp!, {r0 - r5, lr}

	ldr r4, =bomb_set
	ldrb r5, [r4]
	cmp r5, #0				
	beq handle_bomb_done	; if bomb not set, exit
	
	; bomb is set
	
	; if bomb occupies position other than
	; bomberman's position, draw to screen
	
	ldr r4, =bomb_x_loc
	ldrb r5, [r4]
	
	ldr r4, =bomberman_x_loc
	ldrb r6, [r4]
	
	cmp r5, r6
	bne skip_y_test
	
	; bomb x == bomberman x
	
	ldr r4, =bomb_y_loc
	ldrb r5, [r4]
	
	ldr r4, =bomberman_y_loc
	ldrb r6, [r4]
	
	cmp r5, r6
	beq dont_draw_bomb		; bomb y also == bomberman y
	
skip_y_test
	; bomb x y != bomberman x y
	
	ldr r4, =bomb_x_loc
	ldrb r1, [r4]
	
	ldr r4, =bomb_y_loc
	ldrb r2, [r4]
	
	mov r0, #111
	
	bl write_char_at_position
	
	
dont_draw_bomb		; skips draw stage
	
	; if bomb is set, timer is always initialized
	
	; if timer > 0 : decrement timer
	; if timer = 0 detonate bomb and decrement timer
	; if timer = -1 remove bomb explosion, unest bomb

	ldr r4, =bomb_timer
	ldrb r5, [r4]
	
	cmp r5, #0
	
	subgt r5, r5, #1				; conditional timer > 0
	strbgt r5, [r4]
	
	bleq detonate_bomb				; conditional timer == 0
	subeq r5, r5, #1
	streq r5, [r4]
	
	;////////////////// used to check if bomb asciis are readable at correct time
	;debug
	;mov r1, #1
	;mov r2, #6
	;bl read_char_at_position
	;nop
	;/////////////////
	
	cmp r5, #-1
	bleq remove_bomb_explosion		; conditional timer < 0
	ldreq r4, =bomb_set
	moveq r5, #0
	strbeq r5, [r4]
	
handle_bomb_done

	ldmfd sp!, {r0 - r5, lr}
	bx lr


detonate_bomb
	stmfd sp!, {r0 - r6, lr}

	ALIGN
explosion_length_up 	= 0
explosion_length_left 	= 0
explosion_length_right	= 0
explosion_length_down	= 0

	ldr r3, =bomb_x_loc
	ldr r4, =bomb_y_loc
	
detonate_bomb_up
	
	ldrb r1, [r3]
	ldrb r2, [r4]
	mov r3, #0			; counts explosions placed
detonate_bomb_up_loop

	sub r2, r2, #1				; move up
	bl read_char_at_position
	
	cmp r0, #32			; empty space?
	ldrne r5, =explosion_length_up
	strbne r3, [r5]
	bne bomb_up_not_empty	; test wall next
	; draw explosion
	moveq r0, #124
	bleq write_char_at_position
	; increment r3 counter
	addeq r3, r3, #1
	; cmp r3 == 2 ( done : loop )
	cmp r3, #2
	ldreq r5, =explosion_length_up
	strbeq r3, [r5]
	beq detonate_bomb_up_done
	bne detonate_bomb_up_loop
	
bomb_up_not_empty
	cmp r0, #90			; wall?
	; no explosion, done in this direction
	beq detonate_bomb_up_done
	
	cmp r0, #35			; brick?
	; no explosion, done in this direction
	beq detonate_bomb_up_done
	
	cmp r0, #66			; bomberman
	; draw explosion
	moveq r0, #124
	bleq write_char_at_position
	; increment r3 counter
	addeq r3, r3, #1
	
	; bomberman dies
	bl bomberman_dies
	
	; cmp r3 == 2 ( done : loop )
	cmp r3, #2
	beq detonate_bomb_up_done
	bne detonate_bomb_up_loop
	
	cmp r0, #120		; enemy
	; draw explosion 
	moveq r0, #124
	bleq write_char_at_position
	; increment r3 counter
	addeq r3, r3, #1
	
	; enemy dies
	mov r6, #0
	ldr r4, =enemy_one_x_loc
	ldrb r5, [r4]
	cmp r1, r5
	addeq r6, r6, #1
	
	ldr r4, =enemy_one_y_loc
	ldrb r5, [r4]
	cmp r2, r5
	addeq r6, r6, #1
	
	cmp r6, #2
	bleq enemy_one_dies
	bne enemy_two_dies
	
	; cmp r3 == 2 ( done : loop )
	cmp r3, #2
	beq detonate_bomb_up_done
	bne detonate_bomb_up_loop
	
	cmp r0, #43			; super enemy
	; draw explosion
	moveq r0, #124
	bleq write_char_at_position
	; increment r3 counter
	add r3, r3, #1
	
	; super enemy dies
	bl enemy_super_dies
	
	; cmp r3 == 2 ( done : loop)
	cmp r3, #2
	beq detonate_bomb_up_done
	bne detonate_bomb_up_loop
	
detonate_bomb_up_done



detonate_bomb_left
	
	ldr r3, =bomb_x_loc
	ldr r4, =bomb_y_loc

	ldrb r1, [r3]
	ldrb r2, [r4]
	mov r3, #0			; counts explosions placed
detonate_bomb_left_loop

	sub r1, r1, #1				; move left
	bl read_char_at_position
	
	cmp r0, #32			; empty space?
	ldrne r5, =explosion_length_left
	strbne r3, [r5]
	bne bomb_left_not_empty
	; draw explosion
	moveq r0, #45		
	bleq write_char_at_position
	; increment r3 counter
	addeq r3, r3, #1
	; cmp r3 == 4 ( done : loop )
	cmp r3, #4
	ldreq r5, =explosion_length_left
	strbeq r3, [r5]
	beq detonate_bomb_left_done
	bne detonate_bomb_left_loop
	
bomb_left_not_empty
	cmp r0, #90			; wall?
	; no explosion, done in this direction
	beq detonate_bomb_left_done
	
	cmp r0, #35			; brick?
	; no explosion, done in this direction
	beq detonate_bomb_left_done
	
	cmp r0, #66			; bomberman
	; draw explosion
	moveq r0, #45
	bleq write_char_at_position
	; increment r3 counter
	addeq r3, r3, #1
	
	; bomberman dies
	bl bomberman_dies
	
	; cmp r3 == 4 ( done : loop )
	cmp r3, #4
	beq detonate_bomb_left_done
	bne detonate_bomb_left_loop
	
	cmp r0, #120		; enemy
	; draw explosion 
	moveq r0, #45
	bleq write_char_at_position
	; increment r3 counter
	addeq r3, r3, #1
	
	; enemy dies
	mov r6, #0
	ldr r4, =enemy_one_x_loc
	ldrb r5, [r4]
	cmp r1, r5
	addeq r6, r6, #1
	
	ldr r4, =enemy_one_y_loc
	ldrb r5, [r4]
	cmp r2, r5
	addeq r6, r6, #1
	
	cmp r6, #2
	bleq enemy_one_dies
	bne enemy_two_dies
	
	; cmp r3 == 4 ( done : loop )
	cmp r3, #4
	beq detonate_bomb_left_done
	bne detonate_bomb_left_loop
	
	cmp r0, #43			; super enemy
	; draw explosion
	moveq r0, #45
	bleq write_char_at_position
	; increment r3 counter
	add r3, r3, #1
	
	; super enemy dies
	bl enemy_super_dies
	
	; cmp r3 == 4 ( done : loop)
	cmp r3, #4
	beq detonate_bomb_left_done
	bne detonate_bomb_left_loop
	
detonate_bomb_left_done

detonate_bomb_right
	
	ldr r3, =bomb_x_loc
	ldr r4, =bomb_y_loc

	ldrb r1, [r3]
	ldrb r2, [r4]
	mov r3, #0			; counts explosions placed
detonate_bomb_right_loop

	add r1, r1, #1				; move right
	bl read_char_at_position
	
	cmp r0, #32			; empty space?
	ldrne r5, =explosion_length_right
	strbne r3, [r5]
	bne bomb_right_not_empty
	; draw explosion
	moveq r0, #45
	bleq write_char_at_position
	; increment r3 counter
	addeq r3, r3, #1
	; cmp r3 == 4 ( done : loop )
	cmp r3, #4
	ldreq r5, =explosion_length_right
	strbeq r3, [r5]
	beq detonate_bomb_right_done
	bne detonate_bomb_right_loop
	
bomb_right_not_empty
	cmp r0, #90			; wall?
	; no explosion, done in this direction
	beq detonate_bomb_right_done
	
	cmp r0, #35			; brick?
	; no explosion, done in this direction
	beq detonate_bomb_right_done
	
	cmp r0, #66			; bomberman
	; draw explosion
	moveq r0, #45
	bleq write_char_at_position
	; increment r3 counter
	addeq r3, r3, #1
	
	; bomberman dies
	bl bomberman_dies
	
	; cmp r3 == 4 ( done : loop )
	cmp r3, #4
	beq detonate_bomb_right_done
	bne detonate_bomb_right_loop
	
	cmp r0, #120		; enemy
	; draw explosion 
	moveq r0, #45
	bleq write_char_at_position
	; increment r3 counter
	addeq r3, r3, #1
	
	; enemy dies
	mov r6, #0
	ldr r4, =enemy_one_x_loc
	ldrb r5, [r4]
	cmp r1, r5
	addeq r6, r6, #1
	
	ldr r4, =enemy_one_y_loc
	ldrb r5, [r4]
	cmp r2, r5
	addeq r6, r6, #1
	
	cmp r6, #2
	bleq enemy_one_dies
	bne enemy_two_dies
	
	; cmp r3 == 4 ( done : loop )
	cmp r3, #4
	beq detonate_bomb_right_done
	bne detonate_bomb_right_loop
	
	cmp r0, #43			; super enemy
	; draw explosion
	moveq r0, #45
	bleq write_char_at_position
	; increment r3 counter
	add r3, r3, #1
	
	; super enemy dies
	bl enemy_super_dies
	
	; cmp r3 == 4 ( done : loop)
	cmp r3, #4
	beq detonate_bomb_right_done
	bne detonate_bomb_right_loop
	
detonate_bomb_right_done

detonate_bomb_down

	ldr r3, =bomb_x_loc
	ldr r4, =bomb_y_loc
	
	ldrb r1, [r3]
	ldrb r2, [r4]
	mov r3, #0			; counts explosions placed
detonate_bomb_down_loop

	add r2, r2, #1				; move down
	bl read_char_at_position
	
	cmp r0, #32			; empty space?
	ldrne r5, =explosion_length_down
	strbne r3, [r5]
	bne bomb_down_not_empty
	; draw explosion
	moveq r0, #124
	bleq write_char_at_position
	; increment r3 counter
	addeq r3, r3, #1
	; cmp r3 == 2 ( done : loop )
	cmp r3, #2
	ldreq r5, =explosion_length_up
	strbeq r3, [r5]
	beq detonate_bomb_down_done
	bne detonate_bomb_down_loop
	
bomb_down_not_empty
	cmp r0, #90			; wall?
	; no explosion, done in this direction
	beq detonate_bomb_down_done
	
	cmp r0, #35			; brick?
	; no explosion, done in this direction
	beq detonate_bomb_down_done
	
	cmp r0, #66			; bomberman
	; draw explosion
	moveq r0, #124
	bleq write_char_at_position
	; increment r3 counter
	addeq r3, r3, #1
	
	; bomberman dies
	bl bomberman_dies
	
	; cmp r3 == 2 ( done : loop )
	cmp r3, #2
	beq detonate_bomb_down_done
	bne detonate_bomb_down_loop
	
	cmp r0, #120		; enemy
	; draw explosion 
	moveq r0, #124
	bleq write_char_at_position
	; increment r3 counter
	addeq r3, r3, #1
	
	; enemy dies
	mov r6, #0
	ldr r4, =enemy_one_x_loc
	ldrb r5, [r4]
	cmp r1, r5
	addeq r6, r6, #1
	
	ldr r4, =enemy_one_y_loc
	ldrb r5, [r4]
	cmp r2, r5
	addeq r6, r6, #1
	
	cmp r6, #2
	bleq enemy_one_dies
	bne enemy_two_dies
	
	; cmp r3 == 2 ( done : loop )
	cmp r3, #2
	beq detonate_bomb_down_done
	bne detonate_bomb_down_loop
	
	cmp r0, #43			; super enemy
	; draw explosion
	moveq r0, #124
	bleq write_char_at_position
	; increment r3 counter
	add r3, r3, #1
	
	; super enemy dies
	bl enemy_super_dies
	
	; cmp r3 == 2 ( done : loop)
	cmp r3, #2
	beq detonate_bomb_down_done
	bne detonate_bomb_down_loop
	
detonate_bomb_down_done

	ldmfd sp!, {r0 - r6, lr}
	bx lr



remove_bomb_explosion
	stmfd sp!, {r0 - r5, lr}
	
	; remove bomb explosion
	; unset bomb_exploding
	ldr r4, =bomb_set
	mov r3, #0
	strb r3, [r4]
	
	ldr r3, =bomb_x_loc
	ldrb r1, [r3]
	
	ldr r3, =bomb_y_loc
	ldrb r2, [r3]
		
	mov r0, #0
	bl write_char_at_position		; clear center bomb char

	mov r5, #0
remove_explosion_main_loop		; remove_explosion_main_loop

	cmp r5, #4
	beq remove_explosion_done

	ldr r3, =bomb_x_loc
	ldrb r1, [r3]
	
	ldr r3, =bomb_y_loc
	ldrb r2, [r3]
	
	;/////////	which explosion length var 
	cmp r5, #0
	ldreq r3, =explosion_length_up	; ldreq
	
	cmp r5, #1
	ldreq r3, =explosion_length_left
	
	cmp r5, #2
	ldreq r3, =explosion_length_right
	
	cmp r5, #3
	ldreq r3, =explosion_length_down
	;/////////
	
	ldrb r4, [r3]
	
	mov r0, #32
	mov r3, #0
remove_explosion_sub_loop		; remove_explosion_sub_loop
	
	cmp r3, r4
	addeq r5, r5, #1
	beq remove_explosion_main_loop
	
	;/////// which mapping opperation
	cmp r5, #0
	addeq r2, r2, #-1 
	
	cmp r5, #1
	addeq r1, r1, #-1 
	
	cmp r5, #2
	addeq r1, r1, #1  
	
	cmp r5, #3
	addeq r2, r2, #1	
	;///////
	
	bl write_char_at_position
	add r3, r3, #1
	
	b remove_explosion_sub_loop	
	
remove_explosion_done
	ldmfd sp!, {r0 - r5, lr}
	bx lr
	

;////////////////////////////////////////////////////////////////
;////////////////////////////////////////////////////////////////		
; BOMB_HANDLER BOMB_HANDLER BOMB_HANDLER BOMB_HANDLER BOMB_HANDLER
;////////////////////////////////////////////////////////////////	
;////////////////////////////////////////////////////////////////
	
	
;////////////////////////////////////////////////////////////////
;////////////////////////////////////////////////////////////////		
; MOVE_CHARACTERS MOVE_CHARACTERS MOVE_CHARACTERS MOVE_CHARACTERS
;////////////////////////////////////////////////////////////////	
;////////////////////////////////////////////////////////////////


move_characters
	stmfd sp!, {r0 - r2, lr}
	
	bl move_bomberman
	
	ldr r1, =enemy_one_dead
	ldrb r2, [r1]
	cmp r2, #0
	moveq r0, #0		; denotes enemy_one
	bleq move_enemy		; move only if alive
	
	ldr r1, =enemy_two_dead
	ldrb r2, [r1]
	cmp r2, #0
	moveq r0, #1		; denotes enemy_two
	bleq move_enemy
	
	ldr r1, =enemy_super_dead
	ldrb r2, [r1]
	cmp r2, #0
	moveq r0, #2		; denotes enemy_super
	bleq move_enemy
	
	ldmfd sp!, {r0 - r2, lr}
	bx lr
	ltorg
	
	
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

	ldr r3, =bomb_input			;bomb should be set
	ldrb r4, [r3]
	cmp r4, #1			; bomb setup code
	beq bomberman_drops_bomb
	
	
	cmp r7, #32					; no direction input
	beq done_moving_bomberman
	
		
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
	
bomberman_drops_bomb

	ldr r4, =bomb_x_loc		; save current bomberman x,y 
	strb r8, [r4]			; as bomb x, y
	ldr r4, =bomb_y_loc
	strb r9, [r4]
	
	ldr r4, =bomb_set		; set bomb_set to 1
	mov r5, #1
	strb r5, [r4]
	
	ldr r4, =bomb_timer
	mov r5, #5
	strb r5, [r4]
	
	mov r0, #83				; prints "S" for bomberman on bomb
	mov r1, r8
	mov r2, r9
	bl write_char_at_position
	
	b done_moving_bomberman
	
bomberman_died
	bl bomberman_dies

done_moving_bomberman
	mov r0, #32
	
	ldr r4, =bomberman_direction
	ldr r5, =bomberman_x_loc
	ldr r6, =bomberman_y_loc
	
	strb r0, [r4]	; clear bomberman_direction
	strb r1, [r5]	; update bomberman x loc
	strb r2, [r6]	; update bomberman y loc

	ldmfd sp!, {r0 - r9, lr}
	bx lr
	
	
	; take enemy var in r0, 
	; (0 : enemy_one, 1 : enemy_two, 2 : enemy_super)
move_enemy
	stmfd sp!, {r0 - r11, lr}
	
	mov r11, r0		; r11 will hold active enemy throughout method
	
	;//////////////////////////////
	cmp r11, #0
	ldreq r4, =enemy_one_direction
	ldreq r5, =enemy_one_x_loc
	ldreq r6, =enemy_one_y_loc
	
	cmp r11, #1
	ldreq r4, =enemy_two_direction
	ldreq r5, =enemy_two_x_loc
	ldreq r6, =enemy_two_y_loc
	
	cmp r11, #2
	ldreq r4, =enemy_super_direction
	ldreq r5, =enemy_super_x_loc
	ldreq r6, =enemy_super_y_loc
	
	;//////////////////////////////
	ldrb r7, [r4]
	ldrb r8, [r5]
	ldrb r9, [r6]
	
	mov r0, #32
	mov r1, r8			; clear old position
	mov r2, r9	
	
	bl write_char_at_position
	
	;check if enemy one is trapped
	mov r0, r1
	mov r1, r2
	bl is_enemy_trapped
	cmp r0, #1
	
	moveq r0, r7
	moveq r1, r8
	moveq r2, r9
	bleq write_char_at_position		; write char back to original position
	beq done_moving_enemy			; branch to end of move routine
	
	
enemy_move_loop
	bl generate_new_random
	ldr r3, =random_number
	ldr r0, [r3]
	lsr r0, r0, #16
	
	mov r1, #4
	bl div_and_mod				; direction 0 - 3 (W, A, S, D)
	
	mov r10, r1		; r10 holds new direction, r7 holds old direction
	
	bl generate_new_random
	ldr r3, =random_number
	ldr r0, [r3]
	lsr r0, r0, #16
	
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
	beq can_move_enemy
	cmp r0, #66			; bomberman?
	beq enemy_kills_bomberman
	cmp r0, #90			; wall?
	beq cant_move_enemy
	cmp r0, #35			; brick?
	beq cant_move_enemy
	cmp r0, #111		; bomb?
	beq cant_move_enemy
	cmp r0, #45			; bomb blast horizontal 
	beq enemy_died
	cmp r0, #124		; bomb blast vertical
	beq enemy_died
	cmp r0, #120		; enemy
	beq cant_move_enemy
	cmp r0, #43			; super enemy
	beq cant_move_enemy
	
can_move_enemy			; can_move_enemy
	;////////////////
	cmp r11, #2
	moveq r0, #43
	movne r0, #120
	;////////////////
	bl write_char_at_position
	b done_moving_enemy
	
enemy_kills_bomberman			; enemy_kills_bomberman
	bl bomberman_dies
	b can_move_enemy
	
cant_move_enemy					; cant_move_enemy
	cmp r7, #0
	moveq r7, #3		; invert current direction
	
	cmp r7, #1
	moveq r7, #2
	
	cmp r7, #2
	moveq r7, #1
	
	cmp r7, #3
	moveq r7, #0
	
	b enemy_move_loop	; try moving again with new base direction
	
enemy_died						; enemy_died
	
	;////////////////////////
	cmp r11, #0
	bleq enemy_one_dies
	
	cmp r11, #1
	bleq enemy_two_dies
	
	cmp r11, #2
	bleq enemy_super_dies
	;////////////////////////
	
	
	
	mov r7, #0		; set for done_moving routine
	mov r1, #0
	mov r2, #0
	
done_moving_enemy

	;//////////////////////////////
	cmp r11, #0
	ldreq r4, =enemy_one_direction
	ldreq r5, =enemy_one_x_loc
	ldreq r6, =enemy_one_y_loc
	
	cmp r11, #1
	ldreq r4, =enemy_two_direction
	ldreq r5, =enemy_two_x_loc
	ldreq r6, =enemy_two_y_loc
	
	cmp r11, #2
	ldreq r4, =enemy_super_direction
	ldreq r5, =enemy_super_x_loc
	ldreq r6, =enemy_super_y_loc
	
	;//////////////////////////////
	strb r7, [r4]			; stores direction, x, y
	strb r1, [r5]
	strb r2, [r6]
	ldmfd sp!, {r0 - r11, lr}
	bx lr
	

	; pass (x, y) in r0, r1,
	; return bool in r0
is_enemy_trapped
	stmfd sp!, {r1 - r4, lr}

	mov r3, r1
	mov r4, r2
	
	mov r1, r3
	sub r2, r4, #1				
	bl read_char_at_position	; check above
	bl is_enemy_trapped_subroutine
	cmp r0, #0		; can move in this direction
	beq is_enemy_trapped_done
	
	mov r1, r3
	add r2, r4, #1
	bl read_char_at_position	; check below
	bl is_enemy_trapped_subroutine
	cmp r0, #0
	beq is_enemy_trapped_done
	
	sub r1, r3, #1
	mov r2, r4
	bl read_char_at_position	; check left
	bl is_enemy_trapped_subroutine
	cmp r0, #0
	beq is_enemy_trapped_done
	
	add r1, r3, #1
	mov r2, r4
	bl read_char_at_position	; check right
	bl is_enemy_trapped_subroutine
	cmp r0, #0
	beq is_enemy_trapped_done
	
	mov r0, #1
	b is_enemy_trapped_done
	
is_enemy_trapped_subroutine
	cmp r0, #32			; empty space?
	moveq r0, #0
	beq is_enemy_trapped_subroutine_done
	
	cmp r0, #45			; bomb blast horizontal 
	moveq r0, #0
	beq is_enemy_trapped_subroutine_done
	
	cmp r0, #124		; bomb blast vertical
	moveq r0, #0
	beq is_enemy_trapped_subroutine_done
	
	cmp r0, #66			; bomberman
	moveq r0, #0
	beq is_enemy_trapped_subroutine_done
	
	;if none of those branch, enemy is trapped
	mov r0, #1
	
is_enemy_trapped_subroutine_done
	bx lr

is_enemy_trapped_done
	ldmfd sp!, {r1 - r4, lr}
	bx lr
	
bomberman_dies
	stmfd sp!, {lr}

	ldmfd sp!, {lr}
	bx lr
	
enemy_one_dies
	stmfd sp!, {lr}

	ldmfd sp!, {lr}
	bx lr

enemy_two_dies
	stmfd sp!, {lr}

	ldmfd sp!, {lr}
	bx lr

enemy_super_dies
	stmfd sp!, {lr}

	ldmfd sp!, {lr}
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

	 
	 ;take x and y coord in r1, r2. 
	 ;returns char at position in r0
read_char_at_position
	stmfd sp!, {r1 - r9, lr}
	
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
	b read_char_at_position_done
	

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
	bne check_for_bomb
	
	ldr r4, =enemy_super_y_loc
	ldrb r5, [r4]
	cmp r5, r2
	bne check_for_bomb
	
	mov r0, #43
	b read_char_at_position_done
	
check_for_bomb
	ldr r4, =bomb_x_loc
	ldrb r5, [r4]
	cmp r5, r1
	bne check_for_explosion
	
	ldr r4, =bomb_y_loc
	ldrb r5, [r4]
	cmp r5, r2
	bne check_for_explosion
	
	ldr r4, =bomb_timer
	ldr r5, [r4]
	cmp r5, #-1
	moveq r0, #45					; if timer == -1 return explosion
	beq read_char_at_position_done
	
	mov r0, #111
	b read_char_at_position_done
	
check_for_explosion
	ldr r4, =bomb_set
	ldrb r5, [r4]
	cmp r5, #1
	bne check_memory_map
	
	ldr r4, =bomb_timer
	ldr r5, [r4]
	cmp r5, #-1
	bne check_memory_map
	
	; bomb explosion is on screen now
	
	; test x - range explosion
test_x_explosion
	ldr r4, =bomb_y_loc
	ldrb r9, [r4]
	cmp r9, r2
	bne test_y_explosion	; not in line with horizontal explosion
	
	; char is in line with horizontal explosion
	
	ldr r4, =bomb_x_loc
	ldrb r5, [r4]
	ldr r4, =explosion_length_left
	ldrb r6, [r4]
	sub r7, r5, r6		;left most range
	
	ldr r4, =explosion_length_right
	ldrb r6, [r4]
	add r8, r5, r6		;right most range
	
	cmp r1, r7
	blt check_memory_map
	
	cmp r1, r8
	bgt check_memory_map
	
	mov r0, #45
	b read_char_at_position_done
	
test_y_explosion
	ldr r4, =bomb_x_loc
	ldrb r9, [r4]
	cmp r1, r9
	bne check_memory_map	; not in line with vertical explosion
	
	; char is in line with explosion
	
	ldr r4, =bomb_y_loc
	ldrb r6, [r4]
	ldr r4, =explosion_length_down
	ldrb r7, [r4]
	ldr r4, =explosion_length_up
	ldrb r8, [r4]
	sub r7, r6, r7		; lowest y value
	add r8, r6, r8		; highest y value
	
	cmp r2, r7
	blt check_memory_map		; y < lower bound?
	
	cmp r2, r8
	bgt check_memory_map		; y > upper bound?
	
	mov r0, #124
	b read_char_at_position_done
	
		
check_memory_map
	ldr r4, =memory_map
	sub r2, r2, #1
	ldr r5, [r4, r2, lsl #2]	; line address of y coord
	sub r1, r1, #1
	ldrb r0, [r5, r1]			; char at y coord shifted by x
	
read_char_at_position_done	
	ldmfd sp!, {r1 - r9, lr}
	bx lr
	

	
;////////////////////////////////////////////////////////////////
;////////////////////////////////////////////////////////////////		
; BOARD_INTERACTIONS BOARD_INTERACTIONS BOARD_INTERACTIONS
;////////////////////////////////////////////////////////////////	
;////////////////////////////////////////////////////////////////		
	

	end