	AREA interrupts, CODE, READWRITE
	;EXPORT lab6
	;EXPORT FIQ_Handler
	IMPORT output_string
	IMPORT read_string
	IMPORT display_digit
	IMPORT write_character
	IMPORT uart_init
	;IMPORT SET_UART
	IMPORT read_character

BASE EQU 0x40000000

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

		
lab6	 	
	STMFD sp!, {r4 - r12, lr}
	
	BL uart_init
	;BL SET_UART
	BL interrupt_init
	LDR r4,= cursor_source
	MOV r0, #0
	STRB r0, [r4]
	
	
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

looploop


	B looploop
		
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

	
		STMFD SP!, {r0 - r5, r9, lr}   ; Save registers 
		
		


		LDMFD SP!, {r0 - r5, r9, lr}   ; Restore registers
		ORR r1, r1, #2		; Clear Interrupt
		STR r1, [r0]

		b FIQ_Exit

read_data_interrupt
		LDR r0, =0xE000C008
		LDR r1, [r0]
		and r1, r1, #1	;interrupt identification
		cmp r1, #1
		BEQ FIQ_Exit
		
		STMFD SP!, {r0-r12, lr}   ; Save registers
		
		
bloop   LDR r2, =0xE000C014
        LDR r3, [r2]
        AND r5, r3, #1
        CMP r5, #0
        BEQ bloop
		LDR r2, =0xE000C000
		LDRB r0, [r2]

		LDR r4,= curser
		LDR r5,= program_done_flag
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
			
letterm		CMP r0, #109 ;k branch random
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
		
quit		
		LDMFD SP!, {r0-r12, lr}   ; Restore registers

FIQ_Exit
		LDMFD SP!, {r0 - r1, lr}
		SUBS pc, lr, #4

	
	
	END