;================;
; Multiblit Code ;
;================;
;
; green: %00
; red  : %01
; blue : %10
; background: %11. 
;
;-------------------;
; Multiblit Graphic ;
;-------------------;

; takes graphic parameters from ROM, stores them in r1-r4, changes
; the DC and calls the multiblit function with the parameters
;
; modifies: r1-r4, Q, DC

MultiBlitGraphic:
	; set ISAR
	lisu	0
	lisl	1
	; load four bytes from the parameters into r1-r4
	lm   
	lr	I, A						; store byte and increase ISAR
	lm   
	lr	I, A
	lm   
	lr	I, A
	lm   
	lr	S, A

	; load the graphics address
	lm
	lr	Qu, A						; into Q
	lm
	lr	Ql, A
	lr	DC, Q						; load it into the DC

	; call the blit function
	jmp	multiblit

;--------------------;
; Multiblit Function ;
;--------------------;
;
; Adjusted so that (0,0) is the top left pixel in the MESS display.
; Full screen starts at (-4;-4) or you can remove the 
; three row "fix"es below for faster display.
;
;
; this function blits a 4-color graphic based on parameters set
; in r1-r4 and the graphic data pointed to by DC0, onto the
; screen
; originally from cart 26, modified for color and annotated
;
; modifies: r0-r7, DC

; register reference:
; -------------------
; r1 = x position
; r2 = y position
; r3 = width
; r4 = height (and vertical counter)
;
; r5 = horizontal counter
; r6 = graphics byte
; r7 = pixel counter
;
; DC = pointer to graphics

multiblit:
	; fix the x coordinate
	lis	4
	as	1
	lr	1, A
	; fix the y coordinate
	lis	4
	as	2
	lr	2, A

	lis	1
	lr	7, A						; load #1 into r7 so it'll be reset when we start
	lr	A, 2						; load the y offset
	com							; invert it
.multiblitRow:
	outs	5						; load accumulator into port 5 (row)

	; check vertical counter
	ds	4						; decrease r4 (vertical counter)
	bnc	.multiblitExit					; if it rolls over exit

	; load the width into the horizontal counter
	lr	A, 3
	lr	5, A

	lr	A, 1						; load the x position
	com							; complement it
.multiblitColumn:
	outs	4						; use the accumulator as our initial column
	; check to see if this byte is finished
	ds	7						; decrease r7 (pixel counter)
	bnz	.multiblitDrawPixel				; if we aren't done with this byte, branch

.multiblitGetByte:
	; get the next graphics byte and set related registers
	lis	4
	lr	7, A						; load #4 into r7 (pixel counter)
	lm
	lr	6, A						; load a graphics byte into r6

.multiblitDrawPixel:
	; get new color
	lr	A, 6
	sr	4
	sr	1
	sr	1
	lr	0, A						; save two-bit color in r0

	; shift graphics byte
	lr	A, 6						; load r6 (graphics byte)
	sl	1
	sl	1						; shift left two
	lr	6, A						; save it

	; output the color
	clr
.multiblitGetColor:
	ds	0
	bnc	.multiblitGetColorEnd
	ai	$40						; multiply color number by $40
	br	.multiblitGetColor
.multiblitGetColorEnd:
	outs	1						; output A in p1 (color)

.multiblitTransferData:
	; transfer the pixel data
	li	$60
	outs	0
	li	$c0
	outs	0
	; and delay a little bit
.multiblitSavePixelDelay:
	ai	$60						; add 96
	bnz	.multiblitSavePixelDelay			; loop if not 0 (small delay)

.multiblitCheckColumn:
	ds	5						; decrease r5 (horizontal counter)
	bz	.multiblitCheckRow				; if it's 0, branch

	ins	4						; get p4 (column)
	ai	$ff						; add 1 (complemented)
	br	.multiblitColumn				; branch

.multiblitCheckRow:
	ins	5						; get p5 (row)
	ai	$ff						; add 1 (complemented)
	br	.multiblitRow					; branch

.multiblitExit:
	; return from the subroutine
	pop
