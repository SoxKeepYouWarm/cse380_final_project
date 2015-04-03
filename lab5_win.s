	AREA interrupts, CODE, READWRITE
	EXPORT lab6
	EXPORT FIQ_Handler
	IMPORT output_string
	IMPORT read_string
	IMPORT display_digit
	IMPORT write_character
	IMPORT uart_init
	EXPORT place
	IMPORT SET_UART
	IMPORT read_character

BASE EQU 0x40000000
	ALIGN
prompt = "Welcome to lab #5\n",13,0
	ALIGN
Prompt1 = "Type C to set board to 0\n",13,0
	ALIGN
Prompt2 = "Type F to turn 7 segment display off\n",13,0
	ALIGN
Prompt3 = "Type R to print a random number on the board\n",13,0
	ALIGN
Prompt4 = "Type Q to end the program\n",13,0
	ALIGN
Prompt5 = "Type N to turn board on\n",13,0
	ALIGN
place = "                              ",0	
    ALIGN
count = " ",0
	ALIGN
randomnumber = " ",0
	ALIGN
isitoff = " ",0
	ALIGN
quiting = "Goodbye",0,13
   	ALIGN
program_done_flag = "0",0
	ALIGN
		
		
lab5	 	
	STMFD sp!, {r4 - r12, lr}
	
	BL uart_init
	BL SET_UART
	BL interrupt_init
	mov r0, #0
	BL display_digit
	ldr r4, =count
	mov r1, #0
	strb r1, [r4]
	
	LDR r4,=prompt
	BL output_string
	LDR r4,=Prompt1
	BL output_string
	LDR r4,=Prompt2
	BL output_string
	LDR r4,=Prompt3
	BL output_string
	LDR r4,=Prompt4
	BL output_string
	LDR r5,=Prompt5
	BL output_string
	
	MOV r0, #0
	LDR r4, =randomnumber
looploop
	ADD r0, r0, #1
	CMP r0,	#16
	moveq r0, #0
	strb r0, [r4]
	
	ldr r5, =program_done_flag
	ldrb r6, [r5]
	cmp r6, #49
	;cmp r10, #1
	beq program_finished
	
	B looploop
		
program_finished
	MOV r0, #0
	STRB r0, [r5]
	LDMFD sp!,{r4 - r12, lr}
	BX lr

interrupt_init       
		STMFD SP!, {r0-r1, lr}   ; Save registers 
		
		; Push button setup		 
		LDR r0, =0xE002C000
		LDR r1, [r0]
		ORR r1, r1, #0x20000000
		BIC r1, r1, #0x10000000
		STR r1, [r0]  ; PINSEL0 bits 29:28 = 10

		; Classify sources as IRQ or FIQ
		LDR r0, =0xFFFFF000
		LDR r1, [r0, #0xC]
		ORR r1, r1, #0x8000 ; External Interrupt 1 
		ORR r1, r1, #0x40;and uart0 pg52
		STR r1, [r0, #0xC]
		 
		ldr r0, =0xE000C004	; enable data available
		ldr r1, [r0]
		orr r1, r1, #1
		str r1, [r0]

		; Enable Interrupts
		LDR r0, =0xFFFFF000
		LDR r1, [r0, #0x10] 
		ORR r1, r1, #0x8000 ; External Interrupt 
		ORR r1, r1, #0x40 ;and uart0 pg52
		STR r1, [r0, #0x10]

		;enable uart interrupt
		ldr r0, =0xE000C004
		ldr r1, [r0]
		orr r1, r1, #1
		str r1, [r0]
		
		; External Interrupt 1 setup for edge sensitive
		LDR r0, =0xE01FC148
		LDR r1, [r0]
		ORR r1, r1, #2  ; EINT1 = Edge Sensitive
		STR r1, [r0]

		; Enable FIQ's, Disable IRQ's
		MRS r0, CPSR
		BIC r0, r0, #0x40
		ORR r0, r0, #0x80
		MSR CPSR_c, r0

		LDMFD SP!, {r0-r1, lr} ; Restore registers
		BX lr             	   ; Return



FIQ_Handler
		STMFD SP!, {r0 - r1, lr}   ; Save registers 

EINT1			; Check for EINT1 interrupt
		LDR r0, =0xE01FC140
		LDR r1, [r0]
		TST r1, #2
		BEQ read_data_interrupt

	
		STMFD SP!, {r0, r3, r4, r5, r9, lr}   ; Save registers 
		
		; Push button EINT1 Handling Code
		
		;make output						
		LDR r4, =0xE0028014 ;load input uart			
		STR r1, [r4]
		LDR r4, =count;loads value from memory thats on board
		LDRB r3, [r4];stores the bit from memory
		mov r5, r3
		CMP r5, #15;checks to see if number is 15
		moveq r5, #0;if equal turn to zero
		addne r5, r5, #1;if not equal add 1

		
		mov r0, r5
		add r0, r0, #48
		cmp r0, #57
		addgt r0, r0, #7
		BL write_character
		MOV r0, #10
		BL write_character
		MOV r0, #13
		BL write_character
	
		mov r0, r5
		STR r0, [r4]
 		LDR r4, =isitoff
		LDRB r9, [r4]
		CMP r9, #1
		BEQ exitb
		BL display_digit
		

exitb
		LDMFD SP!, {r0, r3, r4, r5, r9, lr}   ; Restore registers
		ORR r1, r1, #2		; Clear Interrupt
		STR r1, [r0]
		b FIQ_Exit

read_data_interrupt
		LDR r0, =0xE000C008
		LDR r1, [r0]
		and r1, r1, #1	;interrupt identification
		cmp r1, #1
		BEQ FIQ_Exit
		
		;STMFD SP!, {r0-r12, lr}   ; Save registers 
		
		BL 	super_awesome_data_interrupt_routine
		
		;LDMFD SP!, {r0-r12, lr}   ; Restore registers


FIQ_Exit
		LDMFD SP!, {r0 - r1, lr}
		SUBS pc, lr, #4
		




super_awesome_data_interrupt_routine
	STMFD SP!, {R0 - R4, r9, lr}
	MOV r0, #0
	MOV r2, #1
	MOV r3, #0		
hey
	BL read_character

	; Your lab 5 code goes here...
		;MOV r0, r1
		CMP r0, #70 ;F branch to off
		BEQ off

		CMP r0, #67	;C branch clear
		BEQ clear

		CMP r0, #82	;R branch random
		BEQ random

		CMP r0, #81	;Q branch quit
		BEQ quit

		CMP r0, #78
		BEQ on

		MOV r0, #10
		BL write_character
		MOV r0, #13
		BL write_character
		B exit
off
		LDR r4, =0xE0028008
		MOV r1, #0x00003f80;load value to clear/whats writen to
		STR r1, [r4];clear original	
		LDR r4, =0xE002800C;load clear
		STR r1, [r4]
		MOV r0, #10
		BL write_character
		MOV r0, #13
		BL write_character
		LDR r4, =isitoff
		MOV r9, #1
		STRB r9, [r4] 
		B exit
clear
		MOV r0, #0
		MOV r3, r0
		ADD r0, r0, #48
		BL write_character
		MOV r0, #10
		BL write_character
		MOV r0, #13
		BL write_character
		MOV r0,r3
		LDR r4, =count
		STR r3, [r4]
 		LDR r4, =isitoff
		LDRB r9, [r4]
		CMP r9, #1
		BEQ exit
		BL display_digit
		B exit
		
random
	LDR r4, =randomnumber
	LDRB r0, [r4]
	;sub r0, r0, #48
	MOV r3, r0
	add r0, r0, #48
	cmp r0, #57
	addgt r0, r0, #7 
	BL write_character
	MOV r0, #10
	BL write_character
	MOV r0, #13
	BL write_character
	MOV r0, r3
	LDR r4, =count
	STR r3, [r4]
	LDR r4, =isitoff
	LDRB r9, [r4]
	CMP r9, #1
	BEQ exit
	BL display_digit
	B exit
on 
	   LDR r4, =isitoff
	   MOV r9, #0
	   STRB r9, [r4]
	   LDR r4, =count
	   LDR r3, [r4]
	   MOV r0, r3
	   BL display_digit
	   MOV r0, #10
	   BL write_character
	   MOV r0, #13
	   BL write_character
	   B exit

quit
	   MOV r0, #10
	   BL write_character
	   MOV r0, #13
	   BL write_character
	   LDR r4, =quiting
	   LDR r0, [r4]
	   BL output_string
	   ldr r3, =program_done_flag
	   mov r2, #49
	   str r2, [r3]	
	   
exit
    LDMFD SP!, {R0 - R4, r9, lr}
    BX LR

	
	
	END