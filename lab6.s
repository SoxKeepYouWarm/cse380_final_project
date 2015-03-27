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
the_board 	= "|---------------|\n|               |\n|               |\n|               |\n|               |\n|               |\n|               |\n|               |\n|       *       |\n|               |\n|               |\n|               |\n|               |\n|               |\n|               |\n|               |\n|---------------|"
	ALIGN	
current_direction = "1"	; 1 up, 2 left, 3 right, 4 down
	ALIGN

lab6
	stmfd sp!, {r4 - r12, lr}
	
	bl uart_init	
	bl interrupt_init
	
	
;loop
;	ldr r4, =the_board
;	bl output_string
;	bl read_string
;	ldr r4, =store_string
;	bl output_string
;	ldr r4, =newline
;	bl output_string
;	;mov r0, #0
;	;bl write_character
	
;	b loop	

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
	orr r5, r5, #0x10		;enable bit 4 for timer 0
	;orr r5, r5, #0x20		;enable bit 5 for timer 1
	orr r5, r5, #0x40		;enable bit 6 for fast interrupt
	str r5, [r4]			

	ldr r4, =0xE000C004		;enable uart interrupt read_data_available
	ldr r5, [r4]
	orr r5, r5, #1
	str r5, [r4]
	
	MRS r0, CPSR			; Enable FIQ's, Disable IRQ's
	BIC r0, r0, #0x40
	ORR r0, r0, #0x80
	MSR CPSR_c, r0
	
	ldr r4, =0xE0004014
	ldr r5, [r4]			;enable bit 3 to generate interrupt on mr == tc 
	orr r5, r5, #0x18		;enable bit 4 to reset tc when mr == tc
	str r5, [r4]					
	
	ldr r4, =0xE0008014
	ldr r5, [r4]			;enable bit 3 to generate interrupt on mr == tc 
	orr r5, r5, #0x18		;enable bit 4 to reset tc when mr == tc
	str r5, [r4]
	


	ldmfd sp!, {r4 - r12, lr}
	bx lr
		
		
		
FIQ_Handler		
	ldmfd sp!, {r0 - r1, lr}	
read_data_interrupt
	LDR r0, =0xE000C008
	LDR r1, [r0]
	and r1, r1, #1	;interrupt identification
	cmp r1, #1		;set to 1 if no pending interrupts
	beq FIQ_Exit
				
	bl read_data_handler

FIQ_Exit
	LDMFD SP!, {r0 - r1, lr}
	SUBS pc, lr, #4
		
		
		
read_data_handler
	STMFD SP!, {r0, r4, lr}
	
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
	mov r1, #49
	strb r1, [r0]
	
	ldmfd sp!, {r0 - r3}
	b read_data_handler_exit
	   
set_direction_left
	stmfd sp!, {r0 - r3}
	
	ldr r0, =current_direction
	mov r1, #50
	strb r1, [r0]

	ldmfd sp!, {r0 - r3}
	b read_data_handler_exit
	
set_direction_right
	stmfd sp!, {r0 - r3}
	
	ldr r0, =current_direction
	mov r1, #51
	strb r1, [r0]

	ldmfd sp!, {r0 - r3}
	b read_data_handler_exit
	
set_direction_down
	stmfd sp!, {r0 - r3}
	
	ldr r0, =current_direction
	mov r1, #52
	strb r1, [r0]

	ldmfd sp!, {r0 - r3}
	b read_data_handler_exit
	
read_data_handler_exit
    LDMFD SP!, {r0, r4, lr}
    BX LR
	
		
	end