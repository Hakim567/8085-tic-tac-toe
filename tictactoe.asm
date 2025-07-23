; Define ports and memory addresses
LED_PORT:	EQU 80H  ; Port for LED output
KEYPAD_PORT:	EQU 81H  ; Port for keypad input
SEVENSEG_FIRST_PORT:	EQU 82H  ; Port for 1st 7seg output (left to right)
SEVENSEG_SECOND_PORT:	EQU 90H  ; Port for 2nd 7seg output
SEVENSEG_THIRD_PORT:	EQU 91H  ; Port for 3rd 7seg output
SEVENSEG_FOURTH_PORT:	EQU 92H  ; Port for 4th 7seg output

; Memory addresses for game state
BOARD_START:	EQU 2000H  ; Start address for storing board state
MATRIX_START:	EQU 2040H  ; Start address for the 3x3 matrix copy of the board (Needs 3 lines at least etc 1F00 - 1F20)
CURRENT_PLAYER:	EQU 2010H  ; Address to store current player (0x00 for Player 1, 0x01 for Player 2)
INPUT:		EQU 2020H  ; Address to store input
TEMP:		EQU 2030H  ; Temporary storage
SCOREP1:	EQU 2031H  ; Score storage for player 1
SCOREP2:	EQU 2032H  ; Score storage for player 2

; Initialize stack pointer
SP_INIT:	EQU 4000H   ; Stack Pointer initial value

; Start of the program
ORG 0000H
JMP START

ORG 003CH
JMP RST75_ISR

START:
	LXI SP, SP_INIT	 ; Initialize Stack Pointer
	; Enable RST 7.5 interrupt
	MVI 	A, 00011000B	; Set mask to enable RST 7.5
	SIM
	EI		; Enable interrupts globally
	MVI A, 82H
	OUT 83H
	; Initialize game board to empty
	CALL RESET_SCORE
	LXI H, BOARD_START
	MVI B, 9			; 9 cells in the board
INIT_BOARD:
	CALL OFF_LED
	CALL CLEAR_BOARD
	; Initialize current player
	MVI A, 0x00		 ; Player 1 starts
	STA CURRENT_PLAYER

	; Main loop
MAIN_LOOP:
	CALL READ_INPUT
	CALL UPDATE_BOARD
	CALL UPDATE_MATRIX
	CALL CHECK_WIN

	; Switch player
	; Assuming 0x00 for Player 1 and 0x01 for Player 2 in memory
	LDA CURRENT_PLAYER
	CPI 0x00
	JZ SWITCH_TO_PLAYER_2
	MVI A, 0x00
	JMP SWITCH_DONE

SWITCH_TO_PLAYER_2:
	MVI A, 01h

SWITCH_DONE:
	STA CURRENT_PLAYER

	JMP MAIN_LOOP

DELAY:
	MVI B, 0x0F
DELAY_LOOP:
	NOP
	DCR B
	JZ DELAY_LOOP
	RET

READY_LED:
	LDA CURRENT_PLAYER
	; Determine symbol (A or B)
	CPI 0x00
	JZ READY_LED_PLAYER_1
	MVI A, 04H
	JMP UPDATE_LED
READY_LED_PLAYER_1:
	MVI A, 08H
UPDATE_LED:
	OUT LED_PORT
	RET

OFF_LED:
	MVI A, 00H
	OUT LED_PORT
	RET

DRAW_LED:
	MVI A, 02H
	OUT LED_PORT
	RET

WINNER_LED:
	LDA CURRENT_PLAYER
	; Determine symbol (A or B)
	CPI 0x00
	JZ WINNER_LED_PLAYER_1
	MVI A, 05H
	JMP UPDATE_LED
WINNER_LED_PLAYER_1:
	MVI A, 09H
	JMP UPDATE_LED

DISPLAY_WINNER:
	LDA CURRENT_PLAYER
	; Determine symbol (A or B)
	CPI 0x00
	JZ DISPLAY_WINNER_PLAYER_1
	MVI A, 73H
	OUT SEVENSEG_FIRST_PORT
	MVI A, 7CH
	OUT SEVENSEG_SECOND_PORT
	MVI A, 00H
	OUT SEVENSEG_THIRD_PORT
	LDA SCOREP2
	LXI H, SEVENSEGMENTTABLE ;Lookup table for BCD to 7 segment
	LOOP_SCORE_P2:
	INX H
	DCR A
	JNZ LOOP_SCORE_P2
	MOV A, M
	OUT SEVENSEG_FOURTH_PORT
	JMP DISPLAY_WINNER_UPDATE
	DISPLAY_WINNER_PLAYER_1:
		MVI A, 73H
		OUT SEVENSEG_FIRST_PORT
		MVI A, 77H
		OUT SEVENSEG_SECOND_PORT
		MVI A, 00H
		OUT SEVENSEG_THIRD_PORT
		LDA SCOREP1
		LXI H, SEVENSEGMENTTABLE
		LOOP_SCORE_P1:
		INX H
		DCR A
		JNZ LOOP_SCORE_P1
		MOV A, M
		OUT SEVENSEG_FOURTH_PORT
		JMP DISPLAY_WINNER_UPDATE
	DISPLAY_WINNER_UPDATE:
		RET

DISPLAY_TIE:
	MVI A, 07H
	OUT SEVENSEG_FIRST_PORT
	MVI A, 01H
	OUT SEVENSEG_SECOND_PORT
	MVI A, 30H
	OUT SEVENSEG_THIRD_PORT
	MVI A, 79H
	OUT SEVENSEG_FOURTH_PORT
	RET

DISPLAY_SCORE:
	MVI A, 77H
	OUT SEVENSEG_FIRST_PORT
	LXI H, SEVENSEGMENTTABLE
	LDA SCOREP1
	CPI 00H
	JZ SKIP_LOOP_DISPLAY_SCORE_P1 ; Jump if 0 cause its 0 dont need to increment
	LDA SCOREP1
	LOOP_DISPLAY_SCORE_P1:
		INX H
		DCR A
		JNZ LOOP_DISPLAY_SCORE_P1
	SKIP_LOOP_DISPLAY_SCORE_P1:
	MOV A, M
	OUT SEVENSEG_SECOND_PORT
	MVI A, 7CH
	OUT SEVENSEG_THIRD_PORT
	LXI H, SEVENSEGMENTTABLE
	LDA SCOREP2
	CPI 00H
	JZ SKIP_LOOP_DISPLAY_SCORE_P2
	LDA SCOREP2
	LOOP_DISPLAY_SCORE_P2:
		INX H
		DCR A
		JNZ LOOP_DISPLAY_SCORE_P2
	SKIP_LOOP_DISPLAY_SCORE_P2:
	MOV A, M
	OUT SEVENSEG_FOURTH_PORT
	RET

READ_INPUT: ; Read input from keypad or buttons
	CALL READY_LED
	k_dn:
	in KEYPAD_PORT
	ani 10h ; check da bit - keydown
	jz k_dn
	k_up:
	in KEYPAD_PORT
	ani 10h ; check da bit - keyup
	jnz k_up
	in KEYPAD_PORT
	ani 0fh ; get actual value
	lxi h, t_key
	mvi b, 0
	mov c, a
	dad b
	mov a, m

	MOV B, A			; assuming keypad returns value in register A
	; Convert input to board index (1-9 to 0-8)
	DCR B			   ; 1 to 0, 2 to 1, ..., 9 to 8
	MOV A, B
	STA INPUT
	LXI H, BOARD_START	;Check to make sure spot is empty
	ADD L
	MOV L, A
	MVI A, 00H
	CMP M
	JNZ k_dn
	CALL OFF_LED
	RET

UPDATE_BOARD:
	; Get current player
	LDA CURRENT_PLAYER
	; Determine symbol (A or B)
	CPI 0x00
	JZ PLAYER_1
	MVI A, 2BH
	JMP UPDATE_CELL

PLAYER_1:
	MVI A, 1AH

UPDATE_CELL:
	; Update board state
	STA TEMP			; Store symbol in TEMP
	LDA INPUT		   ; Load INPUT to register A
	MOV E, A			; Move INPUT to register E
	LXI H, BOARD_START
	ADD L
	MOV L, A			; Adjust H to point to board position
	LDA TEMP			; Load symbol from TEMP
	MOV M, A			; Store symbol in board
	RET

UPDATE_MATRIX:
	; This is probably not the most efficient way to do this but its ok
	;LXI H, BOARD_START
	;LXI B, MATRIX_START
	;LOOP_UPDATE_MATRIX:
	;MVI B, 3
	;MOV A, M
	;STA B
	;INX H
	;DCR B
	;JNZ LOOP_UPDATE_MATRIX

	LXI H, BOARD_START
	MOV A, M
	STA MATRIX_START
	LXI H, BOARD_START+1
	MOV A, M
	STA MATRIX_START+1
	LXI H, BOARD_START+2
	MOV A, M
	STA MATRIX_START+2
	LXI H, BOARD_START+3
	MOV A, M
	STA MATRIX_START+8
	LXI H, BOARD_START+4
	MOV A, M
	STA MATRIX_START+9
	LXI H, BOARD_START+5
	MOV A, M
	STA MATRIX_START+10
	LXI H, BOARD_START+6
	MOV A, M
	STA MATRIX_START+16
	LXI H, BOARD_START+7
	MOV A, M
	STA MATRIX_START+17
	LXI H, BOARD_START+8
	MOV A, M
	STA MATRIX_START+18
	RET

CHECK_WIN:
    ; Check rows, columns, and diagonals for a win
    ; This is a simplified example; full implementation will check all possible win conditions

    ; Check row 1
    LXI H, BOARD_START ;2000
    MOV A, M ;
    CPI 00h; Make sure its not empty
    JZ CHECK_ROW_2 ; Jump if empty
    MOV C, A 
    INX H
    CMP M
    JNZ CHECK_ROW_2
    INX H
    CMP M
    JNZ CHECK_ROW_2
    JMP WINNER_FOUND

CHECK_ROW_2:
    ; Check row 2
    LXI H, BOARD_START+3
    MOV A, M
    CPI 00h
    JZ CHECK_ROW_3
    MOV C, A
    INX H
    CMP M
    JNZ CHECK_ROW_3
    INX H
    CMP M
    JNZ CHECK_ROW_3
    JMP WINNER_FOUND

CHECK_ROW_3:
    ; Check row 3
    LXI H, BOARD_START+6
    MOV A, M
    CPI 00h
    JZ CHECK_COL_1
    MOV C, A
    INX H
    CMP M
    JNZ CHECK_COL_1
    INX H
    CMP M
    JNZ CHECK_COL_1
    JMP WINNER_FOUND

CHECK_COL_1:
    ; Check column 1
    LXI H, BOARD_START
    MOV A, M
    CPI 00h
    JZ CHECK_COL_2
    MOV C, A
    INX H
    INX H
    INX H
    CMP M
    JNZ CHECK_COL_2
    INX H
    INX H
    INX H
    CMP M
    JNZ CHECK_COL_2
    JMP WINNER_FOUND

CHECK_COL_2:
    ; Check column 2
    LXI H, BOARD_START+1
    MOV A, M
    CPI 00h
    JZ CHECK_COL_3
    MOV C, A
    INX H
    INX H
    INX H
    CMP M
    JNZ CHECK_COL_3
    INX H
    INX H
    INX H
    CMP M
    JNZ CHECK_COL_3
    JMP WINNER_FOUND

CHECK_COL_3:
    ; Check column 3
    LXI H, BOARD_START+2
    MOV A, M
    CPI 00h
    JZ CHECK_DIAG_1
    MOV C, A
    INX H
    INX H
    INX H
    CMP M
    JNZ CHECK_DIAG_1
    INX H
    INX H
    INX H
    CMP M
    JNZ CHECK_DIAG_1
    JMP WINNER_FOUND

CHECK_DIAG_1:
    ; Check diagonal 1
    LXI H, BOARD_START ; 2000
    MOV A, M 
    CPI 00h ; not 0
    JZ CHECK_DIAG_2
    MOV C, A ; C is now 2000
    INX H ; 2001
    INX H ; 2002
    INX H ; 2003
    INX H ; 2004
    CMP M 
    JNZ CHECK_DIAG_2
    INX H
    INX H
    INX H
    INX H ; 2008
    CMP M
    JNZ CHECK_DIAG_2
    JMP WINNER_FOUND

CHECK_DIAG_2:
    ; Check diagonal 2
    LXI H, BOARD_START+2 ;2002
    MOV A, M
    CPI 00h
    JZ CHECK_END
    MOV C, A
    INX H ;2003
    INX H ; 2004
    CMP M
    JNZ CHECK_END
    INX H
    INX H
    CMP M
    JNZ CHECK_END
    JMP WINNER_FOUND

CHECK_END:
	JMP CHECK_DRAW

WINNER_FOUND:
	; Handle win (display message, etc.)
	LDA CURRENT_PLAYER
	; Determine symbol (A or B)
	CPI 00H
	JZ ADD_SCORE_PLAYER_1
	LDA SCOREP2
	INR A
	STA SCOREP2
	JMP DONE_ADD_SCORE
	ADD_SCORE_PLAYER_1:
		LDA SCOREP1
		INR A
		STA SCOREP1
	DONE_ADD_SCORE:
	CALL DISPLAY_WINNER
	MVI C, 04H
	WINNER_LED_LOOP:
	CALL WINNER_LED
	CALL DELAY
	CALL OFF_LED
	CALL DELAY
	DCR C
	JNZ WINNER_LED_LOOP
	LXI H, BOARD_START
	MVI B, 9
CLEAR_BOARD:
	MVI M, 00H
	INX H
	DCR B
	JNZ CLEAR_BOARD
	CALL UPDATE_MATRIX
	CALL DISPLAY_SCORE
	; Reset current player to Player 2 so player 1 always start first
	MVI A, 01H
	STA CURRENT_PLAYER

	RET

RESET_SCORE:
	LXI H, SCOREP1
	MVI M, 00H
	LXI H, SCOREP2
	MVI M, 00H
	RET

CHECK_DRAW:
	MVI B, 9 ;Checking for draw by checking all board tiles have value
	LXI H, BOARD_START ;2000
	LOOP_CHECK_DRAW:
	MOV A, M
	CPI 00h
	JZ NO_DRAW_FOUND
	INX H
	DCR B
	JNZ LOOP_CHECK_DRAW
	JMP DRAW_FOUND
	NO_DRAW_FOUND:
	RET

DRAW_FOUND:
	CALL DISPLAY_TIE
	CALL DRAW_LED
	CALL DELAY
	LXI H, BOARD_START
	MVI B, 9
	JMP CLEAR_BOARD

RST75_ISR:
	JMP START

SEVENSEGMENTTABLE:
dfb 3fh, 06h, 5bh, 4fh, 66h
dfb 6dh, 7dh, 07h, 7fh, 6fh

t_key: ;Keypad 1-9 lookup table
dfb 01h, 02h, 03h, 0ffh, 04h
dfb 05h, 06h, 0ffh, 07h, 08h
dfb 09h, 0ffh, 0Eh, 00h, 0Fh, 0ffh