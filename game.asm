; =============================================================================
; Mario Party F (working title)
; =============================================================================

  processor f8

; =============================================================================
; Constants
; =============================================================================
; -----------------------------------------------------------------------------
; BIOS Calls
; -----------------------------------------------------------------------------
clrscrn  = $00D0 ; uses r31
delay    = $008F
pushk    = $0107 ; used to allow more subroutine stack space
popk     = $011E
drawchar = $0679

; -----------------------------------------------------------------------------
; Color Definitions
; -----------------------------------------------------------------------------
DRAWCHAR_CLEAR = $00
DRAWCHAR_BLUE  = $40
DRAWCHAR_RED   = $80
DRAWCHAR_GREEN = $C0

; =============================================================================
; Program Code
; =============================================================================
; -----------------------------------------------------------------------------
; Game Entrypoint
; -----------------------------------------------------------------------------

	org	$800

cartridgeStart:
	.byte	$55, $55					; cartridge header

cartridgeEntry:
	lis	0						; init the h/w
	outs	1
	outs	4
	outs	5
	outs	0
                
	lisu	4						; r32 = complement flag
	lisl	0
	lr	S, A
                
	li	$c6						; set to three color, grey background
	lr	3, A						; clear screen to grey
	pi	clrscrn						;

  jmp board_load

; -----------------------------------------------------------------------------
; Game Loop
; -----------------------------------------------------------------------------
				
mainLoop:
	jmp rng_update

; -----------------------------------------------------------------------------
; Random Number Generation
; -----------------------------------------------------------------------------
; Not really random, more like a very fast timer
; -----------------------------------------------------------------------------
RNG_MIN = 1
RNG_MAX = 9

rng_reset:
  li RNG_MIN
  br rng_update2

rng_update:
  lisu 4				; RNG seed is stored in r33
  lisl 1
  lr A, S
  inc
  ci RNG_MAX + 1		; Only allow values 1-9 (add 10?)
  bnz rng_update2		; If RNG exceeds maximum, set back to minimum and return
  br rng_reset

rng_update2:
  lr S, A				; Write the incremented seed back to r33
  ai DRAWCHAR_BLUE		; Add blue color to result in r0 for drawchar
  lr 0, A

  li 80
  lr 1, A
  li 80
  lr 2, A
  pi drawchar

  jmp input

; -----------------------------------------------------------------------------
; Input
; -----------------------------------------------------------------------------
input:
  clr
  outs  0
  outs  1
  ins 1
  com 
  bnz pressed
  jmp mainLoop

pressed:
  dci sfx_roll
  pi playSong
  jmp mainLoop

; -----------------------------------------------------------------------------
; Board Loading
; -----------------------------------------------------------------------------
; modifies: r5, DC0, DC1
; jumps to the multiblit code, which modifies r1-4
; -----------------------------------------------------------------------------

board_return:
  jmp mainLoop

board_load:
  ; TODO: is messing with isar necessary?
  lisu 0
  lisl 1
  dci board

board_load_space:
  ; all spaces have these dimensions
  lis 5
  lr 3, A
  lis 4
  lr 4, A

  ; load space type into r5. if it's -1, return
  lm
  ci $FF
  bz board_return
  lr 5, A

  ; load space position
  lm
  lr 1, A
  lm
  lr 2, A
  
  ; swap board data iterator into DC1 and load a gfx pointer
  xdc
  dci gfx_space_blue
  pi multiblit

  ; get our position in board data back from DC1
  xdc
  br board_load_space

; =============================================================================
; Dependencies
; =============================================================================
  include "multiblit.asm"
  include "playsong.asm"

; =============================================================================
; Game Data
; =============================================================================
; -----------------------------------------------------------------------------
; Graphics Data
; -----------------------------------------------------------------------------
gfx_space_blue:
  .byte $EA
  .byte $EA
  .byte $A2
  .byte $A3
  .byte $03

gfx_space_red:
  .byte $D5
  .byte $D5
  .byte $51
  .byte $53
  .byte $03

gfx_player_piece:
  .byte %00100000
  .byte %01110000
  .byte %00100000
  .byte %00100000
  .byte %01110000

; -----------------------------------------------------------------------------
; Music Data
; -----------------------------------------------------------------------------
sfx_roll:
  .byte 5, 69, 6, 89, 7, 108, 7, 116, 0

; -----------------------------------------------------------------------------
; Board Data
; -----------------------------------------------------------------------------
; .byte space_type, space_x, space_y
; -----------------------------------------------------------------------------
board:
  .byte $01, $10, $10
  .byte $01, $20, $10
  .byte $01, $30, $10
  .byte $FF

; -----------------------------------------------------------------------------
; Padding
; -----------------------------------------------------------------------------
	org $ff0

signature:
	.byte	"             end"
