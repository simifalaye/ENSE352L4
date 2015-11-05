;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Project: Lab 4 - Sorting arrays of characters in ascending 
;;;          order using Merge sort algorithm
;;; File: 
;;; Class: lab4_sort.s
;;; Date: 
;;; Programmer: 
;;; Description:


; Directives
	PRESERVE8	
	THUMB   

  ;;; Equates
end_of_stack	equ 0x20001000			;Allocating 4kB of memory for the stack
RAM_START		equ	0x20000000

; Vector Table Mapped to Address 0 at Reset, Linker requires __Vectors to be exported

			AREA    RESET, DATA, READONLY
			EXPORT  __Vectors
;The DCD directive allocates one or more words of memory, aligned on four-byte boundaries, 
;and defines the initial runtime contents of the memory.


__Vectors
				DCD	0x20002000		; stack pointer value when stack is empty
		    DCD	Reset_Handler		; reset vector
	 
				ALIGN

;My  program,  Linker requires Reset_Handler and it must be exported

				AREA    MYCODE, CODE, READONLY
				ENTRY
				EXPORT	Reset_Handler




Reset_Handler PROC
	;; Copy the string of characters from flash to RAM buffer so it 
	;; can be sorted  - Student to do  

  LDR R1, =string1 ;load the source string into R1
	LDR R2, =0x20000100 ;load start of destination address into R2
	LDR R3, =string1size ;putting size (in bytes) of string1 into R3
	bl byte_copy

	LDR R1, = 0x20000400
	bl sort

	
	
	;; we are finished
done	b	done		; finished mainline code.
	ENDP
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
string1
	dcb	"ABEFZACDGL"
string1size	equ . - string1

	align
size1
	dcd	string1size
		
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Author:
;;; Sort an array of characters in ascending order using the 
;;; algorithm described in the lab handout
;;; 
;;; Require:
;;; R1: ptr to buffer in RAM containing the input string (string_buffer)
;;; R2: ptr to auxiliary buffer in RAM used by subroutine "merge" (aux_buffer)
;;; R3: size of the string (contained in [size1] )
;;; 
;;; Promise: Returns 1 in error register R10 if there was an error, else 
;;; R10 is 0 and the buffer in RAM contains the sorted string of characters
;;;	Subroutine must not modify any other register.
;;; 
	ALIGN
sort PROC
	;; include here the body of your routine
	PUSH {LR,R1,R2,R3,R4,R5,R6,R7}
	
	MOV R7, #2
	CMP	R3, #1
	BNE part2
	LDRB R0, [R2]
	STRB R0, [R1]
	POP {LR,R1,R2,R3,R4,R5,R6,R7}
	BX LR
	
part2
	;R1 is a new location under R2 0x20000400
	;R2 is the location of the start of the string we copied from byte copy
	;R3 is the size in bytes of the string
	;R5 is the size of sublist2 which we calculate
	;R6 is the size of sublist1 which we calculate
	CMP	R3, #2
	BNE part3
	ADD	R4, R2, #1	; R4 (sublist2)
	MOV R5, #1 ;Size of sublist2
	MOV R6, #1 ;Size of sublist1
	BL merge

	POP {LR,R1,R2,R3,R4,R5,R6,R7}
	BX LR
part3
	SDIV R3, R3, R7
	MOV	R6, R3 ; Size of sublist1
	BL		sort
	
	ADD		R4, R6, R2
	MOV	R5, R3 ; Size of sublist2
	BL sort
	
	BL merge
	POP {LR,R1,R2,R3,R4,R5,R6,R7}
	bx	lr
	
	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; copy an array of bytes from source ptr R1 to dest ptr R2.  R3
;;; contains the number of bytes to copy.
;;; Require:
;;; The destination had better be somewhere in RAM, but that's the
;;; caller's responsibility.  As is the job to ensure the source and 
;;; dest arrays don't overlap.
;;;
;;; Promise: No registers are modified.  The destination buffer is
;;;          modified.
;;; Author: Prof. Karim Naqvi (Oct 2013)
	ALIGN
byte_copy  PROC
	push {r1,r2,r3,r4}
	LDR R4, =0x00000000
	
copyLoop
	LDRB R0, [R1] ;Load the address in memory into R0
	STRB R0, [R2] ;Store one byte from string1 into the memory address location
	ADD R4, R4, #0x00000001 ;Increment the counter
  ADD R1, R1, #0x00000001	;
	ADD R2, R2, #0x00000001 ;Increment the memory locationIncrement to the next byte in the string
	
	CMP R4, R3 ;Compare the counter with string size
	BNE copyLoop ;Branch if they do not equal back to the loop
	ENDP
		
	pop	{r1,r2,r3,r4}
	bx	lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Author: Diego Castro (Nov 2013)
;;; Merges two sorted sublists (sublist1 and sublist2) that 
;;; contains the ASCII code of characters. Resulting array 
;;; combines the characters of both sublists and it is sorted in ascending order
;;; The subroutine will overwrite the original contents of both sublists
;;;
;;; Require: 
;;;		R1: pointer to an auxiliary buffer
;;; 	R2: pointer to sublist1
;;; 	R4: pointer to sublist2
;;;     R5: size of sublist2
;;; 	R6: size of sublist1
;;; Promise: Sublist1 and sublist2 are adjacent buffers in memory 
;;; (i.e. first memory address of sublist2 is located 
;;; right after last memory address of sublist1). Both sublists will be overwritten  
;;; with the sorted array after merging. 
;;; If stack overflow occurs, it returns 1 in error register R10 else r10 is zero. 
;;; Subroutine does not modify any other register.
;;; Example: 
;;;            sublist1  |  Sublist2
;;;                  degz|fht
;;;
;;;            sorted array
;;;                  defghtz
;;; Note: this function needs at least 9 words of free space in the stack
	ALIGN
merge		PROC
			
			;;;checking if there is enough space in stack
			ldr		r10,=end_of_stack
			subs 	r10,sp,r10			;R10 contains number of bytes available in stack			
			cmp		r10,#36				;this subroutine requires at least 9 words (36 bytes) of free space in the stack 
			bgt		no_stack_overflow
			mov		r10,#1				;not enough space in stack for this procedure
			bx 		lr
			
			
no_stack_overflow
			mov 	r10,#0
			push	{r3,lr}
			push	{r1,r2,r4,r5,r6,r7,r8}
		
		
check		cbnz	r5,load_sub1		;when r5 is 0, we are done checking sublist 1
			mov		r7,#0x8F			;done with sublist 1, loading high value in R7
			b		load_sub2
load_sub1		
			ldrb	r7,[r2]				;R7 contains current ASCII code of character in sublist1
			cbnz	r6,load_sub2
			mov		r8,#0x8F			;done with sublist 2, loading high value in R8
			b		compare
load_sub2							
			ldrb	r8,[r4]				;R8 contains current ASCII code of character in sublist2

compare		cmp 	r7,r8
			bne		charac_diff							
			strb	r7,[r1]				;both characters are equal, we copy both to the aux buffer;
			add		r1,#1
			strb	r8,[r1]
			add		r1,#1
			;;;Updating indexes
     	    cbz		r5,cont_sub2		;index for sublist 1 will be zero when we are done inspecting that sublist
			subs 	r5,#1
			add		r2,#1	
cont_sub2	cbz		r6,check_if_done	;index for sublist 2 will be zero when we are done inspecting that sublist
			subs 	r6,#1
			add		r4,#1
check_if_done	
			cmp 	r5,r6
			bne 	check
			cmp		r5,#0				;both indexes are zero, then we are done
			beq 	finish
			b		check
		
charac_diff	;;;Only copy to aux buffer the charecter with smallest code, update its corresponding index	
			bgt		reverse_order
			strb	r7,[r1]				;character in sublist1 in less than the code of character in sublist2
			add		r1,#1
			cmp		r5,#0
			beq		check_if_done		;index for sublist 1 will be zero when we are done inspecting that sublist
			subs 	r5,#1
			add		r2,#1		
			b		check_if_done
reverse_order		
			strb	r8,[r1]				;character in sublist2 in less than character in sublist1.
			add		r1,#1
			cmp		r6,#0
			beq		check_if_done		;index for sublist 1 will be zero when we are done inspecting that sublist
			subs 	r6,#1	
			add		r4,#1
			b		check_if_done	

finish		pop	{r1,r2,r4,r5,r6,r7,r8}		
			;r1 contains now the memory address of source buffer ... in this case aux_buffer
			;r2 constains now vthe memory address of destination buffer ... in this case sublist1
			add r3,r5,r6	;size of sorted string is the additiong of the size of both sublists
			
			bl 		byte_copy				;;;copy aux buffer to input buffer	
		
			pop 	{r3,pc}			
			ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; End of assembly file
	align
	end
