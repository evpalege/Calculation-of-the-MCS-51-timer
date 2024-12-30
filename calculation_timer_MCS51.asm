ORG			0x00
AJMP			SETUP

SETUP: 
			MOV 29H,#0x6b			// T(sec) * 10^5
			MOV 26H,#0xba
			MOV 20H,#0x20
			
			MOV 35H,#0x20 			// frequency MCU (Hz)
			MOV 33H,#0x00
			MOV 34H,#0x00
			
LOOP:
			ACALL TIMCALC
			NOP
			
			AJMP LOOP			
			
TIMCALC:							// input T(sec*10^5 - (29H26H20H), freq(Hz) - (35H33H34H), out - interrupts(R1*R2) & TIMREG(R0) 
			MOV B,#0x01				// maximum number of ticks
			MOV	R1,#0x00 
			MOV R2,#0x00
			
			MOV R4,#0x01			// 100k to avoid the fractional part
			MOV	R3,#0x86 
			MOV	R2,#0xA0
			
			ACALL MUL63  			// multiplication max nuber of ticks & 100k
			
			MOV B,35H				
			MOV R1,33H
			MOV R2,34H
	
			ACALL DIV63 			// definition Tmax = max number of ticks / frequency MCU
			
			MOV R6,29H
			MOV R5,26H
			MOV R4,20H
			
			ACALL DIV42 			// defintion N (numb of interrupts) = T(sec) / Tmax
			ACALL DIVINC 			// rounding up
			
			MOV 21H,R4 				// save number of interrupts
			MOV 22H,R5

			ACALL SEADIV 			// numb of interrupts dividing into multipliers 
			
			MOV R7,#0x00
			MOV R6,29H
			MOV R5,26H
			MOV R4,20H
			
			MOV R2,21H
			MOV R3,22H
			
			ACALL DIV42 			// definition required tick time Tt = T(sec) / N
			
			MOV 27H,R4				// 	save tick time
			MOV 28H,R5 	
			
			MOV A,R4
			MOV R2,A
			MOV A,R5
			MOV R3,A
			MOV R4,#0x00

			MOV B,35H
			MOV R1,33H
			MOV R0,34H
			
			ACALL MUL63 			// frequency MC * tick time Tt
			
			MOV B,#0x01 
			MOV R1,#0x86
			MOV R0,#0xA0
			
			ACALL DIV63 			// division 100k
			
			MOV R7,#0x01			// maximum number of ticks
			MOV	R6,#0x00 
			MOV R5,#0x00
			
			ACALL RAZN22  			// subtraction max number of ticks - division 100k(MC*Tt)0
			
			MOV A,R5
			MOV R0,A
			MOV R1,24H
			MOV R2,25H
			
			RET
RAZN22:	
			CLR C
			MOV A,R5
			SUBB A,R2
			MOV R5,A
			MOV A,R6
			SUBB A,R3
			MOV R6,A
			MOV A,R7
			SUBB A,R4
			MOV R0,A
			
			RET
SEADIV:		
			MOV R0,#0x01 
			MOV R7,#0x01 
SEADIVCYC:	
			CJNE R0,#0xfe,CYC_1 	// iteration cycle
FND:		
			MOV A,24H 				// checking for an existing value
			JZ FND_F
			MOV R0,A 				// the found divisor (RESULT R0 UMNOJENIY NA R4
			MOV 25H,R4
			mov r4,25h
			mov r0,24h
			RET	
FND_F:
			MOV R4,25H 				// choosing a divider if there is no simple one
			MOV R0,23H
			RET
CYC_1:
			CLR C
			INC R0
			MOV R4,21H 			
			MOV R5,22H 			
			ACALL DIV21
			MOV A,R5
			JZ FIDIV				// checking for 1 byte space
			SJMP SEADIVCYC
FIDIV:								// save the first number that fits in 1 byte
			MOV A,23h        		// checking for 1 found fit in 1 byte
			JZ SAVDIV
			SJMP FND_T       		// save it
SAVDIV:		
			MOV 23H,R0
			MOV 24H,R0
			MOV 25H,R4
FND_T:								// checking for a prime numbers by inversely multiplying them
			MOV A,R0
			MOV B,R4
			MUL AB
			CJNE A,21H,SEADIVCYC
			MOV A,B
			CJNE A,22H,SEADIVCYC
			JNC SAVDIV2
			SJMP SEADIVCYC
SAVDIV2:
			MOV 24h,R0
			SJMP FND
MUL63:
			MOV	A,#24
			MOV	R7,#0
			MOV	R6,#0
			MOV	R5,#0
MUL63_1:							// MUL63: multiplication routine BR1R0*R4R3R2=R7R6R5R4R3R2
			PUSH ACC					
			MOV	A,R2							
			RRC A
			JNC	MUL63_2
			MOV	A,R5
			ADD A,R0
			MOV	R5,A
			MOV	A,R6
			ADDC A,R1
			MOV	R6,A
			MOV	A,R7
			ADDC	A,B
			MOV	R7,A
MUL63_2:
			MOV	A,R7
			RRC A
			MOV	R7,A
			MOV	A,R6
			RRC A
			MOV	R6,A
			MOV	A,R5
			RRC A
			MOV R5,A
			MOV	A,R4
			RRC A
			MOV	R4,A
			MOV A,R3
			RRC A
			MOV	R3,A
			MOV A,R2
			RRC A
			MOV	R2,A
			POP	ACC
			DJNZ ACC,MUL63_1
			RET
			
MUL42:							 // multiplication routine R1R0*R3R2=R7R6R5R4
			MOV A,#16
			MOV R7,#0
			MOV R6,#0
			MOV R5,#0
			MOV R4,#0
MUL42_1:
			PUSH ACC
			MOV A,R2
			RRC A
			JNC MUL42_2
			MOV A,R6
			ADD A,R0
			MOV R6,A
			MOV A,R7
			ADDC A,R1
			MOV R7,A
MUL42_2:
			MOV A,R7
			RRC A
			MOV R7,A
			MOV A,R6
			RRC A
			MOV R6,A
			MOV A,R5
			RRC A
			MOV R5,A
			MOV A,R4
			RRC A
			MOV R4,A
			MOV A,R3
			RRC A
			MOV R3,A
			MOV A,R2
			RRC A
			MOV R2,A
			POP ACC
			DJNZ ACC,MUL42_1
			RET
			
DIV63:							 // division routine DIV63: R7R6R5R4R3R2/BR1R0=R4R3R2
			MOV A,#24
DCLK_63:
			PUSH ACC
			CLR C
			MOV A,R2
			RLC A
			MOV R2,A
			MOV A,R3
			RLC A
			MOV R3,A
			MOV A,R4
			RLC A
			MOV R4,A
			MOV A,R5
			RLC A
			MOV R5,A
			MOV A,R6
			RLC A
			MOV R6,A
			MOV A,R7
			RLC A
			MOV R7,A
			PUSH PSW
PER1_63:
			CLR C
			MOV A,R5
			SUBB A,R0
			MOV R5,A
			MOV A,R6
			SUBB A,R1
			MOV R6,A
			MOV A,R7
			SUBB A,B
			MOV R7,A
			JC PER2_63
			POP PSW
PER3_63:
			INC R2
			SJMP PER4_63
PER2_63:
			POP PSW
			JC PER3_63
			MOV A,R5
			ADD A,R0
			MOV R5,A
			MOV A,R6
			ADDC A,R1
			MOV R6,A
			MOV A,R7
			ADDC A,B
			MOV R7,A
PER4_63:
			POP ACC
			DJNZ ACC,DCLK_63
			
			MOV 30H,R4 
			MOV 31H,R3
			MOV 32H,R2
			RET		
DIV42:									// division routine DIV63: R7R6R5R4/R3R2=R5R4
			MOV A,#16
DCLK_42:
			PUSH ACC
			CLR C
			MOV A,R4
			RLC A
			MOV R4,A
			MOV A,R5
			RLC A
			MOV R5,A
			MOV A,R6
			RLC A
			MOV R6,A
			MOV A,R7
			RLC A
			MOV R7,A
			PUSH PSW
			CLR C
			MOV A,R6
			SUBB A,R2
			MOV R6,A
			MOV A,R7
			SUBB A,R3
			MOV R7,A
			JC PER2_42
			POP PSW
PER3_42:
			INC R4
			SJMP PER4_42
PER2_42:
			POP PSW
			JC PER3_42
			MOV A,R6
			ADD A,R2
			MOV R6,A
			MOV A,R7
			ADDC A,R3
			MOV R7,A
PER4_42:
			POP ACC
			DJNZ ACC,DCLK_42
			RET
DIVINC:									// rounding routine					
			MOV A,R5
			MOV R1,A
			MOV A,R4
			MOV R0,A
			ACALL MUL42
			MOV A,R4
			CJNE A,20H,DIVINC_L
			MOV A,R5
			CJNE A,26H,DIVINC_L
			MOV A,R6
			CJNE A,29H,DIVINC_L
			ACALL DIVSV
			RET
			CLR C
			INC R4
			JC DIVINC_H
			RET
DIVINC_L:
			CLR C
			INC R0
			JC DIVINC_H
			ACALL DIVSV
			RET
DIVINC_H:	
			CLR C
			INC R1
			ACALL DIVSV
			RET
DIVSV:
			MOV A,R0
			MOV R4,A
			MOV A,R1
			MOV R5,A
			RET
			
DIV21:									// division routine DIV21: R5R4/R0=R5R4
			MOV A,R5
			MOV B,R0
			DIV AB
			MOV R5,A
			MOV A,B
			MOV B,R0
			MOV R1,#8
DWB_3: 		
			CLR C
			XCH A,R4
			RLC A
			XCH A,R4
			RLC A
			CJNE A,B,DWB_1
DWB_1: 
			JC DWB_2
			SUBB A,B
			INC R4
DWB_2: 
			DJNZ R1, DWB_3
			RET 
			
			END
		
