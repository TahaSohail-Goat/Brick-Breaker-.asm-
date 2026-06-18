
.MODEL SMALL
.STACK 200h

; ============================================================
; DATA SEGMENT
; ----------------------------------------------------------
.DATA

; Global Tile Colors
tileColors  DB  09h, 02h, 06h, 0Ch, 0Dh, 0Eh, 0Fh, 0Eh, 0Dh, 0Ch
            DB  0Bh, 0Ah, 09h, 0Fh, 0Eh, 0Dh, 01h, 0Bh, 0Ah, 0Bh
            DB  0Ch, 04h, 0Eh, 07h, 0Bh, 02h, 09h, 0Eh, 0Fh, 04h
            DB  01h, 0Dh, 0Ah, 0Fh, 0Ah, 03h, 04h, 02h, 0Ch, 0Ah

; Game variables
ballPos             DW  0
deltaX              DW  0
deltaY              DW  160
lives               DB  3
platformPos         DW  3910
tilesBrokenCounter  DB  0
tilesBrokenCounter2 DB  0
powerupActive       DB  0      ; 0 = inactive, 1 = active
powerupType         DB  0      ; 'L', 'S', or 'F'
powerupPos          DW  0      ; Position of powerup
slowTimer           DW  0      ; Duration of slow effect
fastTimer           DW  0      ; Duration of fast effect
tilesToWin          DB  40
tilesRows           DW  4
score               DW  0      ; Current score

; Config
tilesStartRow   DW  2
tileWidth       DW  8
tilesPerRow     DW  10

; Status arrays
tiles       DB  40 DUP(1)
tilesPos    DW  40 DUP(0)
tilesColor  DB  40 DUP(0)

; -- Title screen strings ----------------------------------
titleRow1  DB  "xxxx xxx  xxx  xxx  x   x   xxxx  xxx  xxx  xxx  x  x xxxx xxx  ", 0
titleRow2  DB  "x  x x  x  x  x     x  x    x   x x  x x   x   x x x  x    x  x ", 0
titleRow3  DB  "xxx  xxx   x  x     xxx     xxx   xxx  xxx xxxxx xx   xxx  xxx  ", 0
titleRow4  DB  "x  x x x   x  x     x  x    x   x x  x x   x   x x x  x    x  x ", 0
titleRow5  DB  "xxxx x  x xxx  xxx  x   x   xxxx  x  x xxx x   x x  x xxx  x  x ", 0

pressEnterMsg   DB  "PRESS ENTER TO START", 0

; Row colours for logo (Red, Gold, Green, Cyan, Magenta) on brown background
rowColors   DB  1Ch, 1Eh, 1Ah, 1Bh, 1Dh

; -- Win screen strings ------------------------------------
wonRow1 DB  "x   x  xxx  x   x    x   x  xxx  x   x", 0
wonRow2 DB  " x x  x   x x   x    x   x x   x xx  x", 0
wonRow3 DB  "  x   x   x x   x    x x x x   x x x x", 0
wonRow4 DB  "  x   x   x x   x    xx xx x   x x  xx", 0
wonRow5 DB  "  x    xxx   xxx     x   x  xxx  x   x", 0

pressEnterExitMsg   DB  "PRESS ENTER TO EXIT", 0

; -- Menu screen strings -----------------------------------
menuOption1     DB  "1. START GAME", 0
menuOption2     DB  "2. INSTRUCTIONS", 0
menuOption3     DB  "3. HIGH SCORES", 0
menuOption4     DB  "4. EXIT GAME", 0
useArrowsMsg    DB  "Use UP/DOWN arrow keys, press ENTER to select", 0

; Menu state variables
currentMenuOption   DB  0   ; 0 = Select Level, 1 = Exit Game
selectedLevel       DB  1   ; Store selected level (1, 2, or 3)
highestUnlockedLevel DB 1   ; Store the highest unlocked level
levelWonFlag        DB  0   ; Flag indicating if level is won
lvl1ClearedMsg1     DB  "Level 1 cleared", 0
lvl1ClearedMsg2     DB  "press enter to continue to level 2", 0
lvl1ClearedMsg3     DB  "press esc to exit", 0
lvl2ClearedMsg1     DB  "Level 2 cleared", 0
lvl2ClearedMsg2     DB  "press enter to continue to level 3", 0
lvl2ClearedMsg3     DB  "press esc to exit", 0

; -- Name input variables ----------------------------------
playerName      DB  20 DUP(0)  ; Store player name (max 20 chars)
nameLength      DB  0           ; Current length of name

; -- Instruction screen strings ---------------------------
instructTitle   DB  "GAME INSTRUCTIONS", 0
instructCtrl    DB  "CONTROLS:", 0
instructLeft    DB  "LEFT ARROW  - Move paddle left", 0
instructRight   DB  "RIGHT ARROW - Move paddle right", 0
instructEsc     DB  "ESC         - Quit game", 0
instructRules   DB  "OBJECTIVE:", 0
instructRule1   DB  "Break all bricks to win!", 0
instructRule2   DB  "Bounce ball with paddle.", 0
instructRule3   DB  "Lose life if ball falls.", 0
instructBonus   DB  "BONUS:", 0
instructBonusMsg DB  "Earn 1 extra life per 10 bricks!", 0
instructBack    DB  "Press ENTER to return to menu", 0

; -- High scores variables ---------------------------------
highScoresTitle DB  "HIGH SCORES", 0
highScoresMsg   DB  "Press ENTER to return to menu", 0
enterNameMsg    DB  "ENTER YOUR NAME", 0

; -- Game HUD strings --------------------------------------
scoreStr        DB  "SCORE: 000", 0    ; Dynamic score display (3 digits)

; ============================================================
; Game Results storage
; ============================================================
gameCounter     DB  0           ; How many games played (0-3)
highestScore    DW  0           ; Track highest score
highestScoreLvl DB  1           ; Track level of highest score
inputSkip       DB  0           ; Skip flag to balance fast mode paddle speed

; ----------------------------------------------------------
; CODE SEGMENT
; ----------------------------------------------------------
.CODE

; ============================================================
; MAIN  ?  program entry point
; ============================================================
MAIN PROC
    ; Initialise DS to our data segment (required for EXE format)
    MOV  AX, @DATA
    MOV  DS, AX

    MOV  AX, 0B800h
    MOV  ES, AX

@@main_loop:
    CALL clearScreen
    CALL drawTitleScreen   ; Home screen - press enter
    CALL clearScreen
    
    ; Clear name before each input (extra safety)
    MOV  CX, 20
    MOV  BX, OFFSET playerName
@@clear_main_name:
    MOV  BYTE PTR [BX], 0
    INC  BX
    LOOP @@clear_main_name
    MOV  BYTE PTR nameLength, 0
    
    CALL nameInputScreen   ; Name input screen
    CALL clearScreen

@@main_menu_loop:
    CALL mainMenu          ; Main menu with options (handles level selection internally)
    
    ; If we get here, a level was selected
    CALL clearScreen
    
    MOV  AL, BYTE PTR selectedLevel
    CMP  AL, 1
    JE   @@playLevel1
    CMP  AL, 2
    JE   @@playLevel2
    CMP  AL, 3
    JE   @@playLevel3
    JMP  @@level_done
    
@@playLevel1:
    CALL gameLoop1
    CMP  BYTE PTR selectedLevel, 2
    JE   @@playLevel2
    CMP  BYTE PTR selectedLevel, 3
    JE   @@playLevel3
    JMP  @@level_done
    
@@playLevel2:
    CALL gameLoop2
    CMP  BYTE PTR selectedLevel, 3
    JE   @@playLevel3
    JMP  @@level_done
    
@@playLevel3:
    CALL gameLoop3
    
@@level_done:
    CALL clearScreen
    
    JMP  @@main_menu_loop  ; After level ends, back to main menu

    CALL clearScreen
    MOV  AH, 4Ch
    MOV  AL, 0
    INT  21h
MAIN ENDP

; ============================================================
; drawTitleScreen
; ============================================================
drawTitleScreen PROC
    MOV  AX, 0B800h
    MOV  ES, AX
    CALL displayPlayerName

    ; Start at Row 5 (~offset 840), Col 20
    MOV  DI, 820
    XOR  BX, BX         ; BX = row index 0-4

@@draw_logo_loop:
    PUSH DI

    CMP  BX, 0
    JE   @@load_r1
    CMP  BX, 1
    JE   @@load_r2
    CMP  BX, 2
    JE   @@load_r3
    CMP  BX, 3
    JE   @@load_r4
    JMP  @@load_r5

@@load_r1:  MOV  SI, OFFSET titleRow1
            JMP  @@print_line
@@load_r2:  MOV  SI, OFFSET titleRow2
            JMP  @@print_line
@@load_r3:  MOV  SI, OFFSET titleRow3
            JMP  @@print_line
@@load_r4:  MOV  SI, OFFSET titleRow4
            JMP  @@print_line
@@load_r5:  MOV  SI, OFFSET titleRow5

@@print_line:
    MOV  AH, rowColors[BX]  ; colour for this row

@@char_loop:
    LODSB
    CMP  AL, 0
    JE   @@line_done

    CMP  AL, ' '
    JE   @@skip_pixel

    MOV  AL, 0DBh           ; solid block character
    MOV  WORD PTR ES:[DI], AX
    JMP  @@next_pixel

@@skip_pixel:
    MOV  WORD PTR ES:[DI], 1020h

@@next_pixel:
    ADD  DI, 2
    JMP  @@char_loop

@@line_done:
    POP  DI
    ADD  DI, 160            ; move down one text row
    INC  BX
    CMP  BX, 5
    JNE  @@draw_logo_loop

    ; Draw "PRESS ENTER TO START"
    MOV  DI, 2940           ; Row 18, Col ~30
    MOV  SI, OFFSET pressEnterMsg
    MOV  AH, 1Fh            ; bright white on brown

@@msg_loop:
    LODSB
    CMP  AL, 0
    JE   @@wait_for_input
    STOSW
    JMP  @@msg_loop

@@wait_for_input:
    MOV  AH, 00h
    INT  16h
    CMP  AL, 0Dh            ; Enter key
    JNE  @@wait_for_input
    RET
drawTitleScreen ENDP

; ============================================================
; nameInputScreen - Get player name
; ============================================================
nameInputScreen PROC
    CALL clearScreen

    MOV  AX, 0B800h
    MOV  ES, AX

    ; Title: "ENTER YOUR NAME"
    MOV  DI, 1600           ; Row 10, centered
    MOV  SI, OFFSET titleRow1
    MOV  AH, 1Fh            ; bright white on blue



@@name_title_done:
    ; Display "Enter your name" label
    MOV  DI, 1986           ; Row 12, centered (15 char text)
    MOV  SI, OFFSET enterNameMsg
    MOV  AH, 1Fh            ; Bright white on brown

@@print_enter_name:
    LODSB
    CMP  AL, 0
    JE   @@enter_name_done
    STOSW
    JMP  @@print_enter_name

@@enter_name_done:
    
    ; Draw input box outline
    MOV  DI, 2140           ; Row 13, centered (box is 20 chars wide)
    MOV  AH, 1Eh            ; Yellow on brown
    MOV  AL, 0DAh           ; Top-left corner
    MOV  WORD PTR ES:[DI], AX
    ADD  DI, 2

    MOV  CX, 18             ; Draw top line
    MOV  AL, 0C4h           ; Horizontal line
    
@@draw_top_line:
    MOV  WORD PTR ES:[DI], AX
    ADD  DI, 2
    LOOP @@draw_top_line

    MOV  AL, 0BFh           ; Top-right corner
    MOV  WORD PTR ES:[DI], AX
    ADD  DI, 2

    ; Draw left side and input area (Row 14)
    MOV  DI, 2300           ; Row 14, centered
    MOV  AL, 0B3h           ; Vertical line
    MOV  WORD PTR ES:[DI], AX
    ADD  DI, 2

    ; Clear input area and prepare for text
    MOV  CX, 18
    MOV  AX, 1020h          ; brown background with space
    
@@clear_input:
    MOV  WORD PTR ES:[DI], AX
    ADD  DI, 2
    LOOP @@clear_input

    MOV  AL, 0B3h           ; Vertical line
    MOV  WORD PTR ES:[DI], AX
    ADD  DI, 2

    ; Draw right side (Row 15)
    MOV  DI, 2460           ; Row 15, centered
    MOV  AL, 0C0h           ; Bottom-left corner
    MOV  AH, 1Eh
    MOV  WORD PTR ES:[DI], AX
    ADD  DI, 2

    MOV  CX, 18             ; Draw bottom line
    MOV  AL, 0C4h
    
@@draw_bottom_line:
    MOV  WORD PTR ES:[DI], AX
    ADD  DI, 2
    LOOP @@draw_bottom_line

    MOV  AL, 0D9h           ; Bottom-right corner
    MOV  WORD PTR ES:[DI], AX

    ; Instruction text
    MOV  DI, 2610           ; Row 16, centered (29 char text)
    MOV  SI, OFFSET instructBack
    MOV  AH, 1Bh            ; Cyan on brown

@@print_name_instr:
    LODSB
    CMP  AL, 0
    JE   @@start_input_loop
    STOSW
    JMP  @@print_name_instr

@@start_input_loop:
    MOV  DI, 2302           ; Start of input area (Row 14, Col 1 inside box)
    XOR  BYTE PTR nameLength, 0  ; Reset name length
    
    ; Clear the playerName buffer (all 20 bytes)
    MOV  CX, 20
    MOV  BX, OFFSET playerName
@@clear_name_buf:
    MOV  BYTE PTR [BX], 0
    INC  BX
    LOOP @@clear_name_buf
    
    ; Clear the input display area (18 chars = 36 bytes)
    PUSH DI
    MOV  AX, 1020h          ; brown background with space
    MOV  CX, 18
@@clear_display_area:
    MOV  WORD PTR ES:[DI], AX
    ADD  DI, 2
    LOOP @@clear_display_area
    POP  DI

@@input_char_loop:
    MOV  AH, 00h
    INT  16h

    CMP  AL, 0Dh            ; Enter key
    JE   @@name_input_done
    
    CMP  AL, 08h            ; Backspace
    JE   @@handle_backspace_name

    CMP  AL, ' '
    JL   @@input_char_loop  ; Ignore non-printable chars
    
    CMP  BYTE PTR nameLength, 18
    JGE  @@input_char_loop  ; Max 18 chars (box width)

    ; Store character - preserve AL (the character) by using a different register for index
    MOV  BL, BYTE PTR nameLength
    XOR  BH, BH
    MOV  SI, BX
    MOV  BX, OFFSET playerName
    MOV  BYTE PTR [BX+SI], AL       ; Store the actual character
    INC  BYTE PTR nameLength

    ; Display character
    MOV  AH, 1Fh            ; Bright white on brown
    STOSW
    JMP  @@input_char_loop

@@handle_backspace_name:
    CMP  BYTE PTR nameLength, 0
    JE   @@input_char_loop
    
    DEC  BYTE PTR nameLength
    SUB  DI, 2              ; Move back one position

    ; Clear character
    MOV  AX, 1020h
    MOV  WORD PTR ES:[DI], AX
    JMP  @@input_char_loop

@@name_input_done:
    ; Make sure name is empty check
    CMP  BYTE PTR nameLength, 0
    JE   @@input_char_loop     ; Name is empty, go back to input
    
    ; Make sure name is null-terminated
    MOV  AL, BYTE PTR nameLength
    XOR  AH, AH
    MOV  SI, AX
    MOV  BX, OFFSET playerName
    MOV  BYTE PTR [BX+SI], 0
    RET
nameInputScreen ENDP

; ============================================================
; displayPlayerName - Display player name in top right corner
; ============================================================
displayPlayerName PROC
    PUSH ES
    PUSH AX
    PUSH BX
    PUSH DI
    PUSH SI
    
    MOV  AX, 0B800h
    MOV  ES, AX
    
    ; Calculate position: Row 0, starting around column 60
    MOV  DI, 120           ; Approximate starting position for name
    MOV  SI, OFFSET playerName
    MOV  AH, 1Fh           ; Bright white on brown (for menu and game screens)
    
@@print_name_loop:
    LODSB
    CMP  AL, 0             ; End of name
    JE   @@print_name_done
    STOSW                  ; Print character with color
    JMP  @@print_name_loop

@@print_name_done:
    POP  SI
    POP  DI
    POP  BX
    POP  AX
    POP  ES
    RET
displayPlayerName ENDP

; ============================================================
; displayPlayerNameBlack - Display player name on black background
; ============================================================
displayPlayerNameBlack PROC
    PUSH ES
    PUSH AX
    PUSH BX
    PUSH DI
    PUSH SI
    
    MOV  AX, 0B800h
    MOV  ES, AX
    
    ; Calculate position: Row 0, starting around column 60
    MOV  DI, 120           ; Approximate starting position for name
    MOV  SI, OFFSET playerName
    MOV  AH, 0Fh           ; Bright white on black
    
@@print_name_black_loop:
    LODSB
    CMP  AL, 0             ; End of name
    JE   @@print_name_black_done
    STOSW                  ; Print character with color
    JMP  @@print_name_black_loop

@@print_name_black_done:
    POP  SI
    POP  DI
    POP  BX
    POP  AX
    POP  ES
    RET
displayPlayerNameBlack ENDP

; ============================================================
; instructionsScreen - Display game instructions
; ============================================================
instructionsScreen PROC
    CALL clearScreen
    CALL displayPlayerName

    MOV  AX, 0B800h
    MOV  ES, AX

    ; Title
    MOV  DI, 800            ; Row 5
    MOV  SI, OFFSET instructTitle
    MOV  AH, 1Eh            ; Yellow on brown

@@print_instr_title:
    LODSB
    CMP  AL, 0
    JE   @@instr_content
    STOSW
    JMP  @@print_instr_title

@@instr_content:
    ; CONTROLS section
    MOV  DI, 1280           ; Row 8
    MOV  SI, OFFSET instructCtrl
    MOV  AH, 1Eh            ; Bright red on brown

@@print_ctrl_label:
    LODSB
    CMP  AL, 0
    JE   @@print_left_instr
    STOSW
    JMP  @@print_ctrl_label

@@print_left_instr:
    MOV  DI, 1440           ; Row 9
    MOV  SI, OFFSET instructLeft
    MOV  AH, 1Fh            ; Bright white on brown

@@print_left_text:
    LODSB
    CMP  AL, 0
    JE   @@print_right_instr
    STOSW
    JMP  @@print_left_text

@@print_right_instr:
    MOV  DI, 1600           ; Row 10
    MOV  SI, OFFSET instructRight
    MOV  AH, 1Fh            ; Bright white on brown

@@print_right_text:
    LODSB
    CMP  AL, 0
    JE   @@print_esc_instr
    STOSW
    JMP  @@print_right_text

@@print_esc_instr:
    MOV  DI, 1760           ; Row 11
    MOV  SI, OFFSET instructEsc
    MOV  AH, 1Fh            ; Bright white on brown

@@print_esc_text:
    LODSB
    CMP  AL, 0
    JE   @@print_rules_label
    STOSW
    JMP  @@print_esc_text

    ; OBJECTIVE section
@@print_rules_label:
    MOV  DI, 2080           ; Row 13
    MOV  SI, OFFSET instructRules
    MOV  AH, 1Eh            ; Bright red on brown

@@print_rules_text:
    LODSB
    CMP  AL, 0
    JE   @@print_rule1
    STOSW
    JMP  @@print_rules_text

@@print_rule1:
    MOV  DI, 2240           ; Row 14
    MOV  SI, OFFSET instructRule1
    MOV  AH, 1Fh            ; Bright white on brown

@@print_r1_text:
    LODSB
    CMP  AL, 0
    JE   @@print_rule2
    STOSW
    JMP  @@print_r1_text

@@print_rule2:
    MOV  DI, 2400           ; Row 15
    MOV  SI, OFFSET instructRule2
    MOV  AH, 1Fh            ; Bright white on brown

@@print_r2_text:
    LODSB
    CMP  AL, 0
    JE   @@print_rule3
    STOSW
    JMP  @@print_r2_text

@@print_rule3:
    MOV  DI, 2560           ; Row 16
    MOV  SI, OFFSET instructRule3
    MOV  AH, 1Fh            ; Bright white on brown

@@print_r3_text:
    LODSB
    CMP  AL, 0
    JE   @@print_bonus_label
    STOSW
    JMP  @@print_r3_text

@@print_bonus_label:
    MOV  DI, 2880           ; Row 18
    MOV  SI, OFFSET instructBonus
    MOV  AH, 1Dh            ; Bright magenta on brown

@@print_bonus_label_text:
    LODSB
    CMP  AL, 0
    JE   @@print_bonus_msg
    STOSW
    JMP  @@print_bonus_label_text

@@print_bonus_msg:
    MOV  DI, 3040           ; Row 19
    MOV  SI, OFFSET instructBonusMsg
    MOV  AH, 1Fh            ; Bright white on brown

@@print_bonus_msg_text:
    LODSB
    CMP  AL, 0
    JE   @@wait_instr_key
    STOSW
    JMP  @@print_bonus_msg_text

@@wait_instr_key:
    MOV  DI, 2940           ; Row 18 (different row)
    MOV  SI, OFFSET highScoresMsg
    MOV  AH, 1Bh            ; Bright cyan on brown

@@print_instr_exit:
    LODSB
    CMP  AL, 0
    JE   @@wait_for_instr_exit
    STOSW
    JMP  @@print_instr_exit

@@wait_for_instr_exit:
    MOV  AH, 00h
    INT  16h
    CMP  AL, 0Dh            ; Enter key
    JNE  @@wait_for_instr_exit
    RET
instructionsScreen ENDP

; ============================================================
; highScoresScreen - Display high scores
; ============================================================
highScoresScreen PROC
    CALL clearScreen
    CALL displayPlayerName

    MOV  AX, 0B800h
    MOV  ES, AX

    ; Title: "HIGH SCORES"
    MOV  DI, 1600           ; Row 10
    MOV  SI, OFFSET highScoresTitle
    MOV  AH, 1Eh            ; Yellow on brown

@@print_hs_title:
    LODSB
    CMP  AL, 0
    JE   @@print_highest_score
    STOSW
    JMP  @@print_hs_title

@@print_highest_score:
    ; Display highest score
    MOV  DI, 2080           ; Row 13
    MOV  AH, 1Fh            ; Bright white on brown
    
    MOV  AL, 'H'
    STOSW
    MOV  AL, 'i'
    STOSW
    MOV  AL, 'g'
    STOSW
    MOV  AL, 'h'
    STOSW
    MOV  AL, 'e'
    STOSW
    MOV  AL, 's'
    STOSW
    MOV  AL, 't'
    STOSW
    MOV  AL, ' '
    STOSW
    MOV  AL, 'S'
    STOSW
    MOV  AL, 'c'
    STOSW
    MOV  AL, 'o'
    STOSW
    MOV  AL, 'r'
    STOSW
    MOV  AL, 'e'
    STOSW
    MOV  AL, ':'
    STOSW
    MOV  AL, ' '
    STOSW
    
    ; Convert and display highest score
    MOV  AX, WORD PTR highestScore
    MOV  CX, 100
    XOR  DX, DX
    DIV  CX
    ADD  AL, '0'
    MOV  AH, 1Fh
    STOSW
    
    MOV  AX, DX
    MOV  CX, 10
    XOR  DX, DX
    DIV  CX
    ADD  AL, '0'
    MOV  AH, 1Fh
    STOSW
    
    ADD  DL, '0'
    MOV  AL, DL
    MOV  AH, 1Fh
    STOSW
    
    ; Print "(Lvl X)"
    MOV  AL, ' '
    STOSW
    MOV  AL, '('
    STOSW
    MOV  AL, 'L'
    STOSW
    MOV  AL, 'v'
    STOSW
    MOV  AL, 'l'
    STOSW
    MOV  AL, ' '
    STOSW
    MOV  AL, BYTE PTR highestScoreLvl
    ADD  AL, '0'
    STOSW
    MOV  AL, ')'
    STOSW

@@wait_for_hs_exit:
    MOV  DI, 2940           ; Row 18
    MOV  SI, OFFSET highScoresMsg
    MOV  AH, 1Bh            ; Bright cyan on brown

@@print_hs_exit:
    LODSB
    CMP  AL, 0
    JE   @@wait_hs_key
    STOSW
    JMP  @@print_hs_exit

@@wait_hs_key:
    MOV  AH, 00h
    INT  16h
    CMP  AL, 0Dh            ; Enter key
    JNE  @@wait_hs_key
    RET
highScoresScreen ENDP

; ============================================================
mainMenu PROC
    CALL clearScreen
    CALL displayPlayerName

    MOV  AX, 0B800h
    MOV  ES, AX



@@title_done:
    ; Menu instruction text
    MOV  DI, 1316          ; Row 8, centered (45 char text)
    MOV  SI, OFFSET useArrowsMsg
    MOV  AH, 1Bh            ; bright cyan on brown

@@print_instructions:
    LODSB
    CMP  AL, 0
    JE   @@instr_done
    STOSW
    JMP  @@print_instructions

@@instr_done:
    MOV  BYTE PTR currentMenuOption, 0  ; Reset to first option

@@menu_loop:
    CALL clearScreen        ; Clear entire screen before redrawing menu
    CALL displayPlayerName

    ; Redraw title
    MOV  DI, 800            ; Row 5, centered
    MOV  SI, OFFSET titleRow1
    MOV  AH, 1Fh            ; bright white on brown


    ; Menu instruction text
    MOV  DI, 1316          ; Row 8, centered (45 char text)
    MOV  SI, OFFSET useArrowsMsg
    MOV  AH, 1Bh            ; bright cyan on brown

@@redraw_instructions:
    LODSB
    CMP  AL, 0
    JE   @@menu_options_display
    STOSW
    JMP  @@redraw_instructions

@@menu_options_display:

    ; Display option 1: SELECT LEVEL (centered, row 10)
    MOV  DI, 1664           ; Row 10, centered (15 char text)
    MOV  AH, 1Fh            ; bright white on brown

    CMP  BYTE PTR currentMenuOption, 0
    JNE  @@opt1_normal
    MOV  AH, 3Fh            ; black on brown (selected)

@@opt1_normal:
    MOV  SI, OFFSET menuOption1  ; "1. SELECT LEVEL"

@@print_opt1:
    LODSB
    CMP  AL, 0
    JE   @@opt2_start
    STOSW
    JMP  @@print_opt1

@@opt2_start:
    ; Display option 2: INSTRUCTIONS (centered, row 11)
    MOV  DI, 1824           ; Row 11, centered (15 char text)
    MOV  AH, 1Fh            ; bright white on brown

    CMP  BYTE PTR currentMenuOption, 1
    JNE  @@opt2_normal
    MOV  AH, 3Fh            ; black on brown (selected)

@@opt2_normal:
    MOV  SI, OFFSET menuOption2  ; "2. INSTRUCTIONS"

@@print_opt2:
    LODSB
    CMP  AL, 0
    JE   @@opt3_start
    STOSW
    JMP  @@print_opt2

@@opt3_start:
    ; Display option 3: HIGH SCORES (centered, row 12)
    MOV  DI, 1986           ; Row 12, centered (14 char text)
    MOV  AH, 1Fh            ; bright white on brown

    CMP  BYTE PTR currentMenuOption, 2
    JNE  @@opt3_normal
    MOV  AH, 3Fh            ; black on brown (selected)

@@opt3_normal:
    MOV  SI, OFFSET menuOption3  ; "3. HIGH SCORES"

@@print_opt3:
    LODSB
    CMP  AL, 0
    JE   @@opt4_start
    STOSW
    JMP  @@print_opt3

@@opt4_start:
    ; Display option 4: EXIT GAME (centered, row 13)
    MOV  DI, 2148           ; Row 13, centered (12 char text)
    MOV  AH, 1Fh            ; bright white on brown

    CMP  BYTE PTR currentMenuOption, 3
    JNE  @@opt4_normal
    MOV  AH, 3Fh            ; black on brown (selected)

@@opt4_normal:
    MOV  SI, OFFSET menuOption4  ; "4. EXIT GAME"

@@print_opt4:
    LODSB
    CMP  AL, 0
    JE   @@wait_menu_input
    STOSW
    JMP  @@print_opt4

@@wait_menu_input:
    ; Wait for input
    MOV  AH, 00h
    INT  16h

    CMP  AH, 48h            ; Up arrow
    JE   @@up_pressed
    CMP  AH, 50h            ; Down arrow
    JE   @@down_pressed
    CMP  AH, 1Ch            ; Enter
    JE   @@select_menu_option
    JMP  @@do_loop

@@up_pressed:
    CMP  BYTE PTR currentMenuOption, 0
    JLE  @@do_loop
    DEC  BYTE PTR currentMenuOption
    JMP  @@do_loop

@@down_pressed:
    CMP  BYTE PTR currentMenuOption, 3
    JGE  @@do_loop
    INC  BYTE PTR currentMenuOption
    JMP  @@do_loop

@@select_menu_option:
    MOV  AL, BYTE PTR currentMenuOption
    CMP  AL, 0
    JNE  @@chk1
    MOV  AL, BYTE PTR highestUnlockedLevel
    MOV  BYTE PTR selectedLevel, AL
    RET                     ; If selected, proceed to game

@@chk1:
    CMP  AL, 1
    JNE  @@chk2
    CALL instructionsScreen
    JMP  @@do_loop          ; jump to nearby trampoline

@@chk2:
    CMP  AL, 2
    JNE  @@chk3
    CALL highScoresScreen
    JMP  @@do_loop          ; jump to nearby trampoline

@@chk3:
    CALL clearScreen
    MOV  AH, 4Ch
    MOV  AL, 0
    INT  21h

@@do_loop:                  ; trampoline ? physically close to the JMPs above
    JMP  NEAR PTR @@menu_loop
mainMenu ENDP

; ============================================================
; print_tiles  ?  draw the brick grid
; ============================================================
print_tiles PROC
    PUSH AX
    PUSH ES
    PUSH SI
    PUSH DI
    PUSH CX
    PUSH DX
    PUSH BX

    MOV  AX, 0B800h
    MOV  ES, AX
    MOV  AX, WORD PTR tilesStartRow
    MOV  CX, 160
    MUL  CX
    MOV  DX, AX             ; dynamic starting row offset
    MOV  CX, WORD PTR tilesRows ; number of rows of tiles
    XOR  BX, BX             ; tile index

outestloop:
    MOV  DI, DX
    PUSH CX
    MOV  CX, WORD PTR tilesPerRow

outerloop:
    PUSH CX

    MOV  SI, BX
    SHL  SI, 1
    MOV  WORD PTR tilesPos[SI], DI

    MOV  AH, tileColors[BX]
    MOV  tilesColor[BX], AH

    MOV  AL, tiles[BX]
    CMP  AL, 1
    JNE  skip_tile

    MOV  CX, WORD PTR tileWidth
    MOV  AL, 0DBh

each_tile:
    STOSW
    LOOP each_tile
    JMP  tile_done

skip_tile:
    MOV  AX, WORD PTR tileWidth
    SHL  AX, 1
    ADD  DI, AX

tile_done:
    INC  BX
    POP  CX
    LOOP outerloop

    POP  CX
    ADD  DX, 160
    LOOP outestloop

    POP  BX
    POP  DX
    POP  CX
    POP  DI
    POP  SI
    POP  ES
    POP  AX
    RET
print_tiles ENDP

; ============================================================
; breakTile  ?  destroy tile at index BX
; ============================================================
breakTile PROC
    PUSH ES
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH SI
    PUSH DI

    MOV  BYTE PTR tiles[BX], 0
    CALL beep
    
    ; Add 5 to score and update display
    ADD  WORD PTR score, 5
    CALL updateScore
    CALL drawScore

    ; Spawn powerup logic
    CMP  BYTE PTR powerupActive, 1
    JE   @@skip_powerup_spawn
    
    ; Generate random number
    MOV  AX, 40h
    MOV  ES, AX
    MOV  AL, ES:[6Ch]       ; Timer tick
    MOV  AH, AL             ; Save it
    AND  AL, 03h            ; 1 in 4 chance
    CMP  AL, 0
    JNE  @@skip_powerup_spawn
    
    MOV  BYTE PTR powerupActive, 1
    
    ; Get tile position (centered)
    MOV  SI, BX
    SHL  SI, 1
    MOV  DI, WORD PTR tilesPos[SI]
    ADD  DI, 6              ; Center of an 8-char tile (approx +3 chars = +6 bytes)
    MOV  WORD PTR powerupPos, DI
    
    ; Choose powerup type randomly (0=L, 1=F, 2=S, 3=S)
    MOV  AL, AH
    SHR  AL, 1
    SHR  AL, 1
    AND  AL, 03h            ; 0, 1, 2, 3
    CMP  AL, 0
    JE   @@spawn_l
    CMP  AL, 1
    JE   @@spawn_f
    ; Default to 'S'
    MOV  BYTE PTR powerupType, 'S'
    JMP  @@skip_powerup_spawn
@@spawn_l:
    MOV  BYTE PTR powerupType, 'L'
    JMP  @@skip_powerup_spawn
@@spawn_f:
    MOV  BYTE PTR powerupType, 'F'
    
@@skip_powerup_spawn:
    ; Extra-life logic: every 10 tiles broken
    INC  BYTE PTR tilesBrokenCounter
    CMP  BYTE PTR tilesBrokenCounter, 10
    JNE  @@check_win
    INC  BYTE PTR lives
    MOV  BYTE PTR tilesBrokenCounter, 0
    CALL displayLives

@@check_win:
    INC  BYTE PTR tilesBrokenCounter2
    MOV  AL, BYTE PTR tilesToWin
    CMP  BYTE PTR tilesBrokenCounter2, AL
    JNE  skip_win_check
    MOV  BYTE PTR levelWonFlag, 1

skip_win_check:
    MOV  AX, 0B800h
    MOV  ES, AX
    MOV  SI, BX
    SHL  SI, 1
    MOV  DI, WORD PTR tilesPos[SI]
    MOV  CX, WORD PTR tileWidth
    MOV  AX, 0720h

@@bt_clear:
    MOV  WORD PTR ES:[DI], AX
    ADD  DI, 2
    LOOP @@bt_clear

    POP  DI
    POP  SI
    POP  CX
    POP  BX
    POP  AX
    POP  ES
    RET
breakTile ENDP

; ============================================================
; eraseBall
; ============================================================
eraseBall PROC
    PUSH ES
    PUSH AX
    PUSH DI
    MOV  AX, 0B800h
    MOV  ES, AX
    MOV  DI, WORD PTR ballPos
    MOV  WORD PTR ES:[DI], 0720h
    POP  DI
    POP  AX
    POP  ES
    RET
eraseBall ENDP

; ============================================================
; drawBall
; ============================================================
drawBall PROC
    PUSH ES
    PUSH AX
    PUSH DI
    MOV  AX, 0B800h
    MOV  ES, AX
    MOV  DI, WORD PTR ballPos
    MOV  WORD PTR ES:[DI], 0F07h
    POP  DI
    POP  AX
    POP  ES
    RET
drawBall ENDP

; ============================================================
; erasePlatform
; ============================================================
erasePlatform PROC
    PUSH ES
    PUSH DI
    PUSH CX
    PUSH AX
    MOV  AX, 0B800h
    MOV  ES, AX
    MOV  DI, WORD PTR platformPos
    MOV  CX, 10

@@ep_loop:
    MOV  WORD PTR ES:[DI], 0720h
    ADD  DI, 2
    LOOP @@ep_loop

    POP  AX
    POP  CX
    POP  DI
    POP  ES
    RET
erasePlatform ENDP

; ============================================================
; drawPlatform
; ============================================================
drawPlatform PROC
    PUSH ES
    PUSH DI
    PUSH CX
    PUSH AX
    MOV  AX, 0B800h
    MOV  ES, AX
    MOV  DI, WORD PTR platformPos
    MOV  CX, 10

drawPlatformLoop:
    MOV  WORD PTR ES:[DI], 1020h
    ADD  DI, 2
    LOOP drawPlatformLoop

    POP  AX
    POP  CX
    POP  DI
    POP  ES
    RET
drawPlatform ENDP

; ============================================================
; displayLives - Original function (kept for compatibility)
; ============================================================
displayLives PROC
    PUSH ES
    PUSH AX
    PUSH DI
    MOV  AX, 0B800h
    MOV  ES, AX
    MOV  DI, 100            ; Position: Row 0, Col 50 (far right middle)

    MOV  WORD PTR ES:[DI], 0F4Ch  ; L (bright white on black)
    ADD  DI, 2
    MOV  WORD PTR ES:[DI], 0F69h  ; i
    ADD  DI, 2
    MOV  WORD PTR ES:[DI], 0F76h  ; v
    ADD  DI, 2
    MOV  WORD PTR ES:[DI], 0F65h  ; e
    ADD  DI, 2
    MOV  WORD PTR ES:[DI], 0F73h  ; s
    ADD  DI, 2
    MOV  WORD PTR ES:[DI], 0F3Ah  ; :
    ADD  DI, 2
    MOV  WORD PTR ES:[DI], 0F20h  ; space
    ADD  DI, 2

    MOV  AL, BYTE PTR lives
    ADD  AL, '0'
    MOV  AH, 0Fh
    MOV  WORD PTR ES:[DI], AX

    POP  DI
    POP  AX
    POP  ES
    RET
displayLives ENDP



; ============================================================
; clearScreen
; ============================================================
clearScreen PROC
    PUSH ES
    PUSH AX
    PUSH DI
    PUSH CX
    MOV  AX, 0B800h
    MOV  ES, AX
    XOR  DI, DI
    MOV  CX, 2000
    MOV  AX, 1020h          ; space with brown background
    REP  STOSW
    POP  CX
    POP  DI
    POP  AX
    POP  ES
    RET
clearScreen ENDP

; ============================================================
; clearScreenBlack - Clear screen with black background (for game)
; ============================================================
clearScreenBlack PROC
    PUSH ES
    PUSH AX
    PUSH DI
    PUSH CX
    MOV  AX, 0B800h
    MOV  ES, AX
    XOR  DI, DI
    MOV  CX, 2000
    MOV  AX, 0720h          ; space with black background
    REP  STOSW
    POP  CX
    POP  DI
    POP  AX
    POP  ES
    RET
clearScreenBlack ENDP
; ============================================================
beep PROC
    PUSH AX
    PUSH BX
    PUSH CX

    MOV  AL, 182
    OUT  43h, AL

    MOV  AX, 1000
    OUT  42h, AL
    MOV  AL, AH
    OUT  42h, AL

    IN   AL, 61h
    OR   AL, 03h
    OUT  61h, AL

    MOV  CX, 3000

@@delay_beep:
    LOOP @@delay_beep

    IN   AL, 61h
    AND  AL, 0FCh
    OUT  61h, AL

    POP  CX
    POP  BX
    POP  AX
    RET
beep ENDP

; ============================================================
; gameOver
; ============================================================
gameOver PROC
    CALL clearScreenBlack

    MOV  AX, 0B800h
    MOV  ES, AX
    MOV  DI, 1840            ; Row 11 or 12, center

    MOV  WORD PTR ES:[DI], 0F47h  ; G (bright white on black)
    ADD  DI, 2
    MOV  WORD PTR ES:[DI], 0F61h  ; a
    ADD  DI, 2
    MOV  WORD PTR ES:[DI], 0F6Dh  ; m
    ADD  DI, 2
    MOV  WORD PTR ES:[DI], 0F65h  ; e
    ADD  DI, 2
    MOV  WORD PTR ES:[DI], 0F20h  ; (space)
    ADD  DI, 2
    MOV  WORD PTR ES:[DI], 0F4Fh  ; O
    ADD  DI, 2
    MOV  WORD PTR ES:[DI], 0F76h  ; v
    ADD  DI, 2
    MOV  WORD PTR ES:[DI], 0F65h  ; e
    ADD  DI, 2
    MOV  WORD PTR ES:[DI], 0F72h  ; r

    CALL saveGameResult          ; Save result before exiting

    MOV  AH, 00h
    INT  16h
    RET
gameOver ENDP

; ============================================================
; checkTileCollision
; Returns AL=1 if hit, AL=0 if no hit
; ============================================================
checkTileCollision PROC
    PUSH BX
    PUSH CX
    PUSH SI
    PUSH DI

    MOV  DX, WORD PTR ballPos
    XOR  BX, BX
    XOR  SI, SI
    MOV  CX, 40

@@scan:
    MOV  AL, tiles[BX]
    CMP  AL, 1
    JNE  @@next

    MOV  DI, WORD PTR tilesPos[SI]
    MOV  AX, WORD PTR tileWidth
    DEC  AX
    SHL  AX, 1
    ADD  AX, DI

    CMP  DX, DI
    JL   @@next
    CMP  DX, AX
    JG   @@next

    CALL breakTile
    NEG  WORD PTR deltaY
    MOV  AL, 1

    POP  DI
    POP  SI
    POP  CX
    POP  BX
    RET

@@next:
    ADD  SI, 2
    INC  BX
    LOOP @@scan

    XOR  AL, AL
    POP  DI
    POP  SI
    POP  CX
    POP  BX
    RET
checkTileCollision ENDP

; ============================================================
; resetPlatform
; ============================================================
resetPlatform PROC
    PUSH ES
    PUSH AX
    PUSH DI
    PUSH CX

    MOV  AX, 0B800h
    MOV  ES, AX
    MOV  DI, WORD PTR platformPos
    MOV  CX, 10

clearOldPlatform:
    MOV  WORD PTR ES:[DI], 0720h
    ADD  DI, 2
    LOOP clearOldPlatform

    MOV  WORD PTR platformPos, 3910

    POP  CX
    POP  DI
    POP  AX
    POP  ES
    RET
resetPlatform ENDP

; ============================================================
; delay  ?  simple busy-wait loop
; ============================================================
delay PROC
    PUSH CX
    PUSH BX

    MOV  BX, 5

outerloop_delay:
    MOV  CX, 4FFFh
    PUSH CX

delayLoop:
    LOOP delayLoop

    POP  CX
    DEC  BX
    JNZ  outerloop_delay

    POP  BX
    POP  CX
    RET
delay ENDP

; ============================================================
; delay2  ?  faster busy-wait loop for Level 2
; ============================================================
delay2 PROC
    PUSH CX
    PUSH BX

    MOV  BX, 3

outerloop_delay2:
    MOV  CX, 4FFFh
    PUSH CX

delayLoop2:
    LOOP delayLoop2

    POP  CX
    DEC  BX
    JNZ  outerloop_delay2

    POP  BX
    POP  CX
    RET
delay2 ENDP

; ============================================================
; delay3  ?  fastest busy-wait loop for Level 3
; ============================================================
delay3 PROC
    PUSH CX
    PUSH BX

    MOV  BX, 1

outerloop_delay3:
    MOV  CX, 4FFFh
    PUSH CX

delayLoop3:
    LOOP delayLoop3

    POP  CX
    DEC  BX
    JNZ  outerloop_delay3

    POP  BX
    POP  CX
    RET
delay3 ENDP

; ============================================================
; checkKey  ?  non-blocking: sets ZF=1 if no key waiting
; ============================================================
checkKey PROC
    MOV  AH, 01h
    INT  16h
    RET
checkKey ENDP

; ============================================================
; readKey  ?  blocking read; AH=scan code, AL=ASCII
; ============================================================
readKey PROC
    MOV  AH, 00h
    INT  16h
    RET
readKey ENDP

; ============================================================
; checkPlatformCollision
; Returns AL=1 if collision, AL=0 otherwise
; ============================================================
checkPlatformCollision PROC
    MOV  AX, WORD PTR ballPos
    CMP  AX, 3840
    JL   noCollision
    CMP  AX, 3998
    JG   noCollision

    MOV  BX, WORD PTR platformPos
    CMP  AX, BX
    JL   noCollision
    ADD  BX, 20
    CMP  AX, BX
    JG   noCollision

    CALL beep
    NEG  WORD PTR deltaY
    SUB  WORD PTR ballPos, 160

    MOV  BX, WORD PTR platformPos
    MOV  DX, AX
    SUB  DX, BX
    SHR  DX, 1

    CMP  DX, 4
    JL   hit_left
    CMP  DX, 6
    JL   hit_center
    JMP  hit_right

hit_left:
    ; No change
    JMP  angled_done

hit_center:
    ; No change
    JMP  angled_done

hit_right:
    ; No change

angled_done:
    MOV  AL, 1
    RET

noCollision:
    XOR  AL, AL
    RET
checkPlatformCollision ENDP
; ============================================================
; checkPlatformCollision1 - Collision for Level 1 extended paddle
; Extended paddle: platformPos-10 (left) to platformPos+28 (right)
; = 20 chars x 2 bytes = 40 bytes total
; ============================================================
checkPlatformCollision1 PROC
    MOV  AX, WORD PTR ballPos
    CMP  AX, 3828              ; below leftmost possible paddle position
    JL   noCollision1
    CMP  AX, 3998              ; above rightmost possible paddle position
    JG   noCollision1

    MOV  BX, WORD PTR platformPos
    SUB  BX, 10                ; left edge = platformPos - 10
    CMP  AX, BX
    JL   noCollision1
    ADD  BX, 38                ; right edge = (platformPos-10) + 38 = platformPos+28
    CMP  AX, BX
    JG   noCollision1

    CALL beep
    NEG  WORD PTR deltaY
    SUB  WORD PTR ballPos, 160  ; push ball back up one row

    ; Angle ball based on hit position within 20-char paddle
    MOV  BX, WORD PTR platformPos
    SUB  BX, 10                ; BX = left edge
    MOV  DX, AX
    SUB  DX, BX                ; DX = byte offset from left edge (0-38)
    SHR  DX, 1                 ; DX = char position (0-19)

    CMP  DX, 4
    JL   hit_far_left1
    CMP  DX, 9
    JL   hit_left1
    CMP  DX, 11
    JL   hit_center1
    CMP  DX, 16
    JL   hit_right1
    JMP  hit_far_right1

hit_far_left1:
    ; No change
    JMP  angled_done1

hit_left1:
    ; (No change to deltaX for autopilot)
    JMP  angled_done1

hit_center1:
    ; (No change to deltaX for autopilot)
    JMP  angled_done1

hit_right1:
    ; (No change to deltaX for autopilot)
    JMP  angled_done1

hit_far_right1:
    ; No change

angled_done1:
    MOV  AL, 1
    RET

noCollision1:
    XOR  AL, AL
    RET
checkPlatformCollision1 ENDP

; ============================================================
; updatePowerup - Handles falling powerup, collision, drawing
; ============================================================
updatePowerup PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    PUSH ES

    CMP  BYTE PTR powerupActive, 1
    JE   @@do_powerup
    JMP  @@powerup_done
@@do_powerup:

    MOV  AX, 0B800h
    MOV  ES, AX
    MOV  DI, WORD PTR powerupPos

    ; Erase current position
    MOV  WORD PTR ES:[DI], 0720h

    ; Move down 1 row
    ADD  DI, 160
    MOV  WORD PTR powerupPos, DI

    ; Check if fell off screen
    CMP  DI, 4000
    JGE  @@missed

    ; Collision check
    ; Powerups fall directly into the paddle row (Row 24: 3840 to 3998)
    CMP  DI, 3840
    JL   @@draw_powerup
    
    ; Check paddle collision
    MOV  BX, WORD PTR platformPos
    
    ; Determine if we have an extended paddle (Level 1) or normal (Level 2/3)
    CMP  BYTE PTR selectedLevel, 1
    JE   @@check_ext
    
    ; Normal paddle (10 chars = 20 bytes, so BX to BX+18)
    CMP  DI, BX
    JL   @@draw_powerup
    ADD  BX, 18
    CMP  DI, BX
    JG   @@draw_powerup
    JMP  @@caught
    
@@check_ext:
    ; Extended paddle (platformPos-10 to platformPos+28)
    SUB  BX, 10
    CMP  DI, BX
    JL   @@draw_powerup
    ADD  BX, 38
    CMP  DI, BX
    JG   @@draw_powerup

@@caught:
    ; Apply effect
    MOV  BYTE PTR powerupActive, 0
    CALL beep
    
    MOV  AL, BYTE PTR powerupType
    CMP  AL, 'L'
    JE   @@apply_l
    CMP  AL, 'S'
    JE   @@apply_s
    CMP  AL, 'F'
    JE   @@apply_f
    JMP  @@powerup_done
    
@@apply_l:
    INC  BYTE PTR lives
    CALL displayLives
    JMP  @@powerup_done
    
@@apply_s:
    MOV  WORD PTR slowTimer, 500
    MOV  WORD PTR fastTimer, 0
    JMP  @@powerup_done
    
@@apply_f:
    MOV  WORD PTR fastTimer, 500
    MOV  WORD PTR slowTimer, 0
    JMP  @@powerup_done

@@missed:
    MOV  BYTE PTR powerupActive, 0
    JMP  @@powerup_done

@@draw_powerup:
    ; Draw powerup character based on type
    MOV  AL, BYTE PTR powerupType
    MOV  AH, 0Ah            ; bright green by default (L)
    CMP  AL, 'L'
    JE   @@do_draw
    MOV  AH, 0Bh            ; bright cyan for S
    CMP  AL, 'S'
    JE   @@do_draw
    MOV  AH, 0Ch            ; bright red for F
@@do_draw:
    MOV  WORD PTR ES:[DI], AX

@@powerup_done:
    POP  ES
    POP  DI
    POP  SI
    POP  DX
    POP  CX
    POP  BX
    POP  AX
    RET
updatePowerup ENDP

; ============================================================
; resetBall
; ============================================================
resetBall PROC
    ; If powerup active, erase it
    CMP  BYTE PTR powerupActive, 1
    JNE  @@no_powerup_erase
    PUSH ES
    PUSH AX
    PUSH DI
    MOV  AX, 0B800h
    MOV  ES, AX
    MOV  DI, WORD PTR powerupPos
    MOV  WORD PTR ES:[DI], 0720h
    POP  DI
    POP  AX
    POP  ES
@@no_powerup_erase:
    MOV  BYTE PTR powerupActive, 0
    MOV  WORD PTR slowTimer, 0
    MOV  WORD PTR fastTimer, 0

    MOV  WORD PTR ballPos, 1840
    MOV  WORD PTR deltaX, 2
    MOV  WORD PTR deltaY, 160
    RET
resetBall ENDP

; ============================================================
; displayLevel - Display current level
; ============================================================
displayLevel PROC
    PUSH ES
    PUSH AX
    PUSH DI
    
    MOV  AX, 0B800h
    MOV  ES, AX
    
    ; Position: Row 0, Column 0 (leftmost)
    MOV  DI, 0
    MOV  AH, 0Eh            ; Bright yellow on black
    
    ; Print "Level: " directly
    MOV  AL, 'L'
    STOSW
    MOV  AL, 'e'
    STOSW
    MOV  AL, 'v'
    STOSW
    MOV  AL, 'e'
    STOSW
    MOV  AL, 'l'
    STOSW
    MOV  AL, ':'
    STOSW
    MOV  AL, ' '
    STOSW
    
    ; Print selected level (1, 2, or 3)
    MOV  AL, BYTE PTR selectedLevel
    ADD  AL, '0'
    STOSW
    
    ; Add spacing after level (10 spaces to ensure clear separation)
    MOV  AL, ' '
    STOSW
    STOSW
    STOSW
    STOSW
 
    
    POP  DI
    POP  AX
    POP  ES
    RET
displayLevel ENDP

; ============================================================
; gameWon  ?  display "YOU WON" screen and exit
; ============================================================
gameWon PROC
    CALL clearScreen
    CALL displayPlayerName

    MOV  AX, 0B800h
    MOV  ES, AX

    MOV  DI, 1000
    XOR  BX, BX

@@draw_won_loop:
    PUSH DI

    CMP  BX, 0
    JE   @@w_load_r1
    CMP  BX, 1
    JE   @@w_load_r2
    CMP  BX, 2
    JE   @@w_load_r3
    CMP  BX, 3
    JE   @@w_load_r4
    JMP  @@w_load_r5

@@w_load_r1:  MOV  SI, OFFSET wonRow1
              JMP  @@w_print_line
@@w_load_r2:  MOV  SI, OFFSET wonRow2
              JMP  @@w_print_line
@@w_load_r3:  MOV  SI, OFFSET wonRow3
              JMP  @@w_print_line
@@w_load_r4:  MOV  SI, OFFSET wonRow4
              JMP  @@w_print_line
@@w_load_r5:  MOV  SI, OFFSET wonRow5

@@w_print_line:
    MOV  AH, rowColors[BX]

@@w_char_loop:
    LODSB
    CMP  AL, 0
    JE   @@w_line_done
    CMP  AL, ' '
    JE   @@w_skip_pixel
    MOV  AL, 0DBh
    MOV  WORD PTR ES:[DI], AX
    JMP  @@w_next_pixel

@@w_skip_pixel:
    MOV  WORD PTR ES:[DI], 1020h

@@w_next_pixel:
    ADD  DI, 2
    JMP  @@w_char_loop

@@w_line_done:
    POP  DI
    ADD  DI, 160
    INC  BX
    CMP  BX, 5
    JNE  @@draw_won_loop

    ; "PRESS ENTER TO EXIT"
    MOV  DI, 2940
    MOV  SI, OFFSET pressEnterExitMsg
    MOV  AH, 1Fh            ; bright white on brown

@@w_msg_loop:
    LODSB
    CMP  AL, 0
    JE   @@wait_exit
    STOSW
    JMP  @@w_msg_loop

@@wait_exit:
    CALL saveGameResult          ; Save result before exiting
    
    MOV  AH, 00h
    INT  16h
    CMP  AL, 0Dh
    JNE  @@wait_exit

    RET
gameWon ENDP

; ============================================================
; saveGameResult  ?  Save current game score and level
; ============================================================
saveGameResult PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    
    ; Update highest score if current score is higher
    MOV  AX, WORD PTR score
    CMP  AX, WORD PTR highestScore
    JLE  @@skip_update_highest
    MOV  WORD PTR highestScore, AX
    MOV  AL, BYTE PTR selectedLevel
    MOV  BYTE PTR highestScoreLvl, AL
    
@@skip_update_highest:
    ; Store score and level based on which game this is
    MOV  AL, BYTE PTR gameCounter
    CMP  AL, 2
    JGE  @@max_games
    
    ; Increment game counter
    INC  BYTE PTR gameCounter
    
@@max_games:
    POP  SI
    POP  DX
    POP  CX
    POP  BX
    POP  AX
    RET
saveGameResult ENDP

; ============================================================
; level1WonScreen - Transition from Level 1 to Level 2
; ============================================================
level1WonScreen PROC
    CALL clearScreen
    CALL displayPlayerName

    MOV  AX, 0B800h
    MOV  ES, AX

    ; Line 1
    MOV  DI, 1664           ; Row 10, centered
    MOV  SI, OFFSET lvl1ClearedMsg1
    MOV  AH, 1Fh            ; bright white on brown
@@msg_loop1_1:
    LODSB
    CMP  AL, 0
    JE   @@print_line1_2
    STOSW
    JMP  @@msg_loop1_1

@@print_line1_2:
    ; Line 2
    MOV  DI, 1806           ; Row 11, centered
    MOV  SI, OFFSET lvl1ClearedMsg2
@@msg_loop1_2:
    LODSB
    CMP  AL, 0
    JE   @@print_line1_3
    STOSW
    JMP  @@msg_loop1_2

@@print_line1_3:
    ; Line 3
    MOV  DI, 1982           ; Row 12, centered
    MOV  SI, OFFSET lvl1ClearedMsg3
@@msg_loop1_3:
    LODSB
    CMP  AL, 0
    JE   @@wait_input1
    STOSW
    JMP  @@msg_loop1_3

@@wait_input1:
    MOV  BYTE PTR highestUnlockedLevel, 2 ; Unlock level 2
    CALL saveGameResult
    
@@input_wait_loop1:
    MOV  AH, 00h
    INT  16h
    CMP  AL, 0Dh            ; Enter
    JE   @@go_next1
    CMP  AL, 1Bh            ; Esc
    JE   @@go_menu1
    JMP  @@input_wait_loop1

@@go_next1:
    MOV  BYTE PTR selectedLevel, 2
    MOV  BYTE PTR levelWonFlag, 0
    RET

@@go_menu1:
    MOV  BYTE PTR selectedLevel, 0
    MOV  BYTE PTR levelWonFlag, 0
    RET
level1WonScreen ENDP

; ============================================================
; level2WonScreen - Transition from Level 2 to Level 3
; ============================================================
level2WonScreen PROC
    CALL clearScreen
    CALL displayPlayerName

    MOV  AX, 0B800h
    MOV  ES, AX

    ; Line 1
    MOV  DI, 1664           ; Row 10, centered
    MOV  SI, OFFSET lvl2ClearedMsg1
    MOV  AH, 1Fh            ; bright white on brown
@@msg_loop2_1:
    LODSB
    CMP  AL, 0
    JE   @@print_line2_2
    STOSW
    JMP  @@msg_loop2_1

@@print_line2_2:
    ; Line 2
    MOV  DI, 1806           ; Row 11, centered
    MOV  SI, OFFSET lvl2ClearedMsg2
@@msg_loop2_2:
    LODSB
    CMP  AL, 0
    JE   @@print_line2_3
    STOSW
    JMP  @@msg_loop2_2

@@print_line2_3:
    ; Line 3
    MOV  DI, 1982           ; Row 12, centered
    MOV  SI, OFFSET lvl2ClearedMsg3
@@msg_loop2_3:
    LODSB
    CMP  AL, 0
    JE   @@wait_input2
    STOSW
    JMP  @@msg_loop2_3

@@wait_input2:
    MOV  BYTE PTR highestUnlockedLevel, 3 ; Unlock level 3
    CALL saveGameResult

@@input_wait_loop2:
    MOV  AH, 00h
    INT  16h
    CMP  AL, 0Dh            ; Enter
    JE   @@go_next2
    CMP  AL, 1Bh            ; Esc
    JE   @@go_menu2
    JMP  @@input_wait_loop2

@@go_next2:
    MOV  BYTE PTR selectedLevel, 3
    MOV  BYTE PTR levelWonFlag, 0
    RET

@@go_menu2:
    MOV  BYTE PTR selectedLevel, 0
    MOV  BYTE PTR levelWonFlag, 0
    RET
level2WonScreen ENDP

; ============================================================
; gameLoop1  ?  Main game logic loop for Level 1
; ============================================================
gameLoop1 PROC
    CALL clearScreenBlack
    
    ; Reset score at start of level
    MOV  WORD PTR score, 0
    CALL updateScore
    
    ; Reset lives
    MOV  BYTE PTR lives, 3
    
    ; Config for Level 1
    MOV  BYTE PTR tilesToWin, 20
    MOV  WORD PTR tilesRows, 2

    ; Reset first 20 tiles back to 1 (not broken)
    MOV  CX, 20
    MOV  BX, 0
@@reset_tiles_loop:
    MOV  BYTE PTR tiles[BX], 1
    INC  BX
    LOOP @@reset_tiles_loop
    
    ; Reset remaining 20 tiles to 0 (so they don't spawn / collide)
    MOV  CX, 20
@@reset_tiles_loop_empty:
    MOV  BYTE PTR tiles[BX], 0
    INC  BX
    LOOP @@reset_tiles_loop_empty
    
    ; Reset tile break counters
    MOV  BYTE PTR tilesBrokenCounter, 0
    MOV  BYTE PTR tilesBrokenCounter2, 0
    
    ; Reset paddle position to center
    MOV  WORD PTR platformPos, 3910
    
    ; Initialize ball position
    CALL resetBall
    
    ; Draw HUD elements at top
    CALL displayLevel           ; Display Level first (top left)
    CALL drawScore              ; Display Score (after level)
    CALL displayLives           ; Display Lives dynamically
    CALL displayPlayerNameBlack ; Display player name (top right) with black background
    
    ; Draw game elements
    CALL print_tiles            ; Draw brick grid
    CALL drawBall               ; Draw ball
    
    ; -- Level 1: Clear and draw full extended paddle (5+10+5 = 20 chars) ---
    PUSH ES
    PUSH AX
    PUSH DI
    PUSH CX
    MOV  AX, 0B800h
    MOV  ES, AX
    
    ; Clear the area first (from left extension to right extension)
    MOV  DI, 3900           ; platformPos (3910) - 10 bytes
    MOV  CX, 20             ; 20 words to clear
    MOV  AX, 0720h          ; Black background
    REP  STOSW
    
    ; Now draw the full paddle at correct position
    MOV  DI, 3900           ; Start at left extension (platformPos - 10)
    MOV  CX, 20             ; Draw 20 characters
    MOV  AX, 1020h          ; Bright white space
@@draw_initial_paddle:
    MOV  WORD PTR ES:[DI], AX
    ADD  DI, 2
    LOOP @@draw_initial_paddle
    
    POP  CX
    POP  DI
    POP  AX
    POP  ES


gameLoop1_MainLoop:
    CALL eraseBall

    ; -- Input handling ------------------------------------
    ; --- AUTOPILOT ---
    ; Erase row 24 entirely (160 bytes = 80 words)
    PUSH ES
    PUSH AX
    PUSH DI
    PUSH CX
    MOV  AX, 0B800h
    MOV  ES, AX
    MOV  DI, 3840
    MOV  CX, 80
    MOV  AX, 0720h
    REP  STOSW
    
    ; Track ball's X position to middle of paddle
    MOV  AX, WORD PTR ballPos
    XOR  DX, DX
    MOV  CX, 160
    DIV  CX                 ; DX = col * 2 (0-158)
    ADD  DX, 3840           ; Row 24 start
    MOV  WORD PTR platformPos, DX
    
    POP  CX
    POP  DI
    POP  AX
    POP  ES
    
    ; Auto ESC key check just in case user wants to quit
    CALL checkKey
    JZ   @@skipInput1
    CALL readKey
    CMP  AH, 01h            ; ESC
    JNE  @@skipInput1
    CALL saveGameResult
    ADD  SP, 2
    RET

@@skipInput1:
    ; -- Predictive wall bounce (prevents line-wrap bug) ---
    MOV  AX, WORD PTR ballPos
    XOR  DX, DX
    MOV  CX, 160
    DIV  CX                 ; DX = current column (0-158)

    ADD  DX, WORD PTR deltaX

    CMP  DX, 160
    JL   @@checkLeftEdge1
    CMP  WORD PTR deltaX, 0
    JLE  @@checkLeftEdge1
    NEG  WORD PTR deltaX
    JMP  @@calcPos1

@@checkLeftEdge1:
    CMP  DX, 0
    JGE  @@calcPos1
    CMP  WORD PTR deltaX, 0
    JGE  @@calcPos1
    NEG  WORD PTR deltaX

@@calcPos1:
    ; -- Move ball -----------------------------------------
    MOV  AX, WORD PTR ballPos
    ADD  AX, WORD PTR deltaX
    ADD  AX, WORD PTR deltaY

    PUSH AX
    PUSH DX
    XOR  DX, DX
    MOV  BX, 160
    DIV  BX                 ; AX = row, DX = col
    MOV  BX, AX
    MOV  AX, DX

    CMP  BX, 1
    JG   @@skip_ry1
    JMP  reverseY1
@@skip_ry1:

    CMP  BX, 25
    JL   @@skip_bl1
    JMP  reverseY1
@@skip_bl1:

    CMP  AX, 0
    JG   @@skip_rx1
    JMP  reverseX1
@@skip_rx1:

    CMP  AX, 158
    JL   @@skip_rx1_2
    JMP  reverseX1
@@skip_rx1_2:

    POP  DX
    POP  AX
    MOV  WORD PTR ballPos, AX

    CALL drawBall
    
    ; -- Level 1: Draw full extended paddle (5+10+5 = 20 chars) ---
    PUSH ES
    PUSH AX
    PUSH DI
    PUSH CX
    MOV  AX, 0B800h
    MOV  ES, AX
    
    ; Calculate start position (platformPos - 10 for left extension)
    MOV  DI, WORD PTR platformPos
    SUB  DI, 10
    
    ; Draw all 20 characters (left extension + base + right extension)
    MOV  CX, 20
    MOV  AX, 1020h          ; Bright white space
@@draw_full_paddle:
    MOV  WORD PTR ES:[DI], AX
    ADD  DI, 2
    LOOP @@draw_full_paddle
    
    POP  CX
    POP  DI
    POP  AX
    POP  ES
    
    ; -- Level 1: Normal ball speed (single delay) ---
    CALL updatePowerup
    CMP  WORD PTR fastTimer, 0
    JA   @@skip_delay1
    CALL delay
    CMP  WORD PTR slowTimer, 0
    JE   @@skip_delay1
    CALL delay
    
    ; Extra input poll to keep paddle speed normal during slow mode
    CALL checkKey
    JZ   @@skip_extra_in1
    CALL readKey
    CALL processInput1
@@skip_extra_in1:

    DEC  WORD PTR slowTimer
@@skip_delay1:
    CMP  WORD PTR fastTimer, 0
    JE   @@no_dec_fast1
    DEC  WORD PTR fastTimer
@@no_dec_fast1:

    CALL checkTileCollision
    CMP  BYTE PTR levelWonFlag, 1
    JNE  @@continue_loop1
    JMP  @@doLevelWon1
@@continue_loop1:
    CALL checkPlatformCollision1    ; Level 1: uses extended paddle range

    JMP  gameLoop1_MainLoop

reverseX1:
    POP  DX
    POP  AX
    NEG  WORD PTR deltaX
    MOV  AX, WORD PTR ballPos
    ADD  AX, WORD PTR deltaX
    ADD  AX, WORD PTR deltaY
    MOV  WORD PTR ballPos, AX
    JMP  gameLoop1_MainLoop

reverseY1:
    POP  DX
    POP  AX
    NEG  WORD PTR deltaY
    MOV  AX, WORD PTR ballPos
    ADD  AX, WORD PTR deltaX
    ADD  AX, WORD PTR deltaY
    MOV  WORD PTR ballPos, AX
    JMP  gameLoop1_MainLoop

ballLost1:
    POP  DX
    POP  AX

    DEC  BYTE PTR lives
    CALL displayLives
    CMP  BYTE PTR lives, 0
    JNE  @@skipGameOver1
    JMP  @@doGameOver1
@@skipGameOver1:

    ; -- Level 1: Erase full 20-char extended paddle at OLD position BEFORE reset ---
    PUSH ES
    PUSH AX
    PUSH DI
    PUSH CX
    MOV  AX, 0B800h
    MOV  ES, AX
    MOV  DI, WORD PTR platformPos
    SUB  DI, 10             ; Start from left extension of OLD position
    MOV  CX, 20             ; Erase 20 words (5+10+5 chars)
    MOV  AX, 0720h          ; Black background
    REP  STOSW
    POP  CX
    POP  DI
    POP  AX
    POP  ES

    ; Now reset platform position to center
    MOV  WORD PTR platformPos, 3910
    
    ; -- Level 1: Draw full extended paddle at NEW center position ---
    PUSH ES
    PUSH AX
    PUSH DI
    PUSH CX
    MOV  AX, 0B800h
    MOV  ES, AX
    
    ; Draw the full paddle at reset position
    MOV  DI, 3900           ; Start at left extension (3910 - 10)
    MOV  CX, 20             ; Draw 20 characters
    MOV  AX, 1020h          ; Bright white space
@@draw_reset_paddle1:
    MOV  WORD PTR ES:[DI], AX
    ADD  DI, 2
    LOOP @@draw_reset_paddle1
    
    POP  CX
    POP  DI
    POP  AX
    POP  ES

    ; Wait removed - spawn immediately

    CALL resetBall
    JMP  gameLoop1_MainLoop   ; continue the game loop


@@doGameOver1:
    CALL gameOver
    RET

@@doLevelWon1:
    CALL level1WonScreen
    RET
gameLoop1 ENDP

; ============================================================
; processInput1 - Handle input for Level 1
; ============================================================
processInput1 PROC
    CMP  AH, 01h            ; ESC scan code -> save and exit game
    JNE  @@checkLeft1
    CALL saveGameResult
    ADD  SP, 2              ; discard return to gameLoop1_MainLoop
    RET                     ; exit gameLoop1 back to MAIN (-> menu)

@@checkLeft1:
    CMP  AH, 4Bh            ; Left arrow
    JE   @@moveLeft1
    CMP  AH, 4Dh            ; Right arrow
    JE   @@moveRight1
    RET

@@moveLeft1:
    ; Already at left boundary? Skip entirely
    CMP  WORD PTR platformPos, 3850
    JLE  processInput1_done
    
    ; -- Level 1: Erase full extended paddle before moving ---
    PUSH ES
    PUSH AX
    PUSH DI
    PUSH CX
    MOV  AX, 0B800h
    MOV  ES, AX
    MOV  DI, WORD PTR platformPos
    SUB  DI, 10
    MOV  CX, 20
    MOV  AX, 0720h
    REP  STOSW
    POP  CX
    POP  DI
    POP  AX
    POP  ES
    
    ; Move left by 8, then clamp to minimum 3850
    MOV  AX, WORD PTR platformPos
    SUB  AX, 8
    CMP  AX, 3850
    JGE  @@leftOk1
    MOV  AX, 3850
@@leftOk1:
    MOV  WORD PTR platformPos, AX
    JMP  processInput1_done

@@moveRight1:
    ; Already at right boundary? Skip entirely
    CMP  WORD PTR platformPos, 3970
    JGE  processInput1_done
    
    ; -- Level 1: Erase full extended paddle before moving ---
    PUSH ES
    PUSH AX
    PUSH DI
    PUSH CX
    MOV  AX, 0B800h
    MOV  ES, AX
    MOV  DI, WORD PTR platformPos
    SUB  DI, 10
    MOV  CX, 20
    MOV  AX, 0720h
    REP  STOSW
    POP  CX
    POP  DI
    POP  AX
    POP  ES
    
    ; Move right by 8, then clamp to maximum 3970
    MOV  AX, WORD PTR platformPos
    ADD  AX, 8
    CMP  AX, 3970
    JLE  @@rightOk1
    MOV  AX, 3970
@@rightOk1:
    MOV  WORD PTR platformPos, AX

processInput1_done:
    RET
processInput1 ENDP

; ============================================================
; gameLoop2  ?  Main game logic loop for Level 2
; ============================================================
gameLoop2 PROC
    CALL clearScreenBlack
    
    ; Reset score at start of level
    MOV  WORD PTR score, 0
    CALL updateScore
    
    ; Reset lives
    MOV  BYTE PTR lives, 3
    
    ; Config for Level 2
    MOV  BYTE PTR tilesToWin, 30
    MOV  WORD PTR tilesRows, 3

    ; Reset first 30 tiles back to 1 (not broken)
    MOV  CX, 30
    MOV  BX, 0
@@reset_tiles_loop2:
    MOV  BYTE PTR tiles[BX], 1
    INC  BX
    LOOP @@reset_tiles_loop2
    
    ; Reset remaining 10 tiles to 0
    MOV  CX, 10
@@reset_tiles_loop_empty2:
    MOV  BYTE PTR tiles[BX], 0
    INC  BX
    LOOP @@reset_tiles_loop_empty2
    
    ; Reset tile break counters
    MOV  BYTE PTR tilesBrokenCounter, 0
    MOV  BYTE PTR tilesBrokenCounter2, 0
    
    ; Reset paddle position to center
    MOV  WORD PTR platformPos, 3910
    
    ; Initialize ball position
    CALL resetBall
    
    ; Draw HUD elements at top
    CALL displayLevel           ; Display Level first (top left)
    CALL drawScore              ; Display Score (after level)
    CALL displayLives           ; Display Lives dynamically
    CALL displayPlayerNameBlack ; Display player name (top right) with black background
    
    ; Draw game elements
    CALL print_tiles            ; Draw brick grid
    CALL drawBall               ; Draw ball
    CALL drawPlatform           ; Draw paddle

gameLoop2_MainLoop:
    CALL playLoop2Frame
    JMP  gameLoop2_MainLoop

gameLoop2 ENDP

; ============================================================
; playLoop2Frame - Single frame of Level 2 game loop
; ============================================================
playLoop2Frame PROC
    CALL eraseBall

    ; -- Input handling ------------------------------------
    ; --- AUTOPILOT ---
    ; Erase row 24 entirely (160 bytes = 80 words)
    PUSH ES
    PUSH AX
    PUSH DI
    PUSH CX
    MOV  AX, 0B800h
    MOV  ES, AX
    MOV  DI, 3840
    MOV  CX, 80
    MOV  AX, 0720h
    REP  STOSW
    
    ; Track ball's X position to middle of paddle
    MOV  AX, WORD PTR ballPos
    XOR  DX, DX
    MOV  CX, 160
    DIV  CX                 ; DX = col * 2 (0-158)
    ADD  DX, 3840           ; Row 24 start
    MOV  WORD PTR platformPos, DX
    
    POP  CX
    POP  DI
    POP  AX
    POP  ES
    
    ; Auto ESC key check just in case user wants to quit
    CALL checkKey
    JZ   @@skipInput2
    CALL readKey
    CMP  AH, 01h            ; ESC
    JNE  @@skipInput2
    CALL saveGameResult
    ADD  SP, 2
    RET

@@skipInput2:
    ; -- Predictive wall bounce (prevents line-wrap bug) ---
    MOV  AX, WORD PTR ballPos
    XOR  DX, DX
    MOV  CX, 160
    DIV  CX                 ; DX = current column (0-158)

    ADD  DX, WORD PTR deltaX

    CMP  DX, 160
    JL   @@checkLeftEdge2
    CMP  WORD PTR deltaX, 0
    JLE  @@checkLeftEdge2
    NEG  WORD PTR deltaX
    JMP  @@calcPos2

@@checkLeftEdge2:
    CMP  DX, 0
    JGE  @@calcPos2
    CMP  WORD PTR deltaX, 0
    JGE  @@calcPos2
    NEG  WORD PTR deltaX

@@calcPos2:
    ; -- Move ball -----------------------------------------
    MOV  AX, WORD PTR ballPos
    ADD  AX, WORD PTR deltaX
    ADD  AX, WORD PTR deltaY

    PUSH AX
    PUSH DX
    XOR  DX, DX
    MOV  BX, 160
    DIV  BX                 ; AX = row, DX = col
    MOV  BX, AX
    MOV  AX, DX

    CMP  BX, 1
    JG   @@skip_ry2
    JMP  reverseY2
@@skip_ry2:

    CMP  BX, 25
    JL   @@skip_bl2
    JMP  reverseY2
@@skip_bl2:

    CMP  AX, 0
    JG   @@skip_rx2
    JMP  reverseX2
@@skip_rx2:

    CMP  AX, 158
    JL   @@skip_rx2_2
    JMP  reverseX2
@@skip_rx2_2:

    POP  DX
    POP  AX
    MOV  WORD PTR ballPos, AX

    CALL drawBall
    CALL drawPlatform
    CALL updatePowerup
    CMP  WORD PTR fastTimer, 0
    JA   @@skip_delay2
    CALL delay2
    CMP  WORD PTR slowTimer, 0
    JE   @@skip_delay2
    CALL delay2
    
    ; Extra input poll to keep paddle speed normal during slow mode
    CALL checkKey
    JZ   @@skip_extra_in2
    CALL readKey
    CALL processInput2
@@skip_extra_in2:
    
    DEC  WORD PTR slowTimer
@@skip_delay2:
    CMP  WORD PTR fastTimer, 0
    JE   @@no_dec_fast2
    DEC  WORD PTR fastTimer
@@no_dec_fast2:

    CALL checkTileCollision
    CMP  BYTE PTR levelWonFlag, 1
    JNE  @@continue_loop2
    JMP  @@doLevelWon2
@@continue_loop2:
    CALL checkPlatformCollision

    RET

reverseX2:
    POP  DX
    POP  AX
    NEG  WORD PTR deltaX
    MOV  AX, WORD PTR ballPos
    ADD  AX, WORD PTR deltaX
    ADD  AX, WORD PTR deltaY
    MOV  WORD PTR ballPos, AX
    RET

reverseY2:
    POP  DX
    POP  AX
    NEG  WORD PTR deltaY
    MOV  AX, WORD PTR ballPos
    ADD  AX, WORD PTR deltaX
    ADD  AX, WORD PTR deltaY
    MOV  WORD PTR ballPos, AX
    RET

ballLost2:
    POP  DX
    POP  AX

    DEC  BYTE PTR lives
    CALL displayLives
    CMP  BYTE PTR lives, 0
    JE   @@doGameOver2

    CALL resetPlatform
    CALL drawPlatform


    CALL resetBall
    RET

@@doGameOver2:
    CALL gameOver
    ADD  SP, 2      ; discard return to gameLoop2_MainLoop
    RET             ; return all the way to MAIN

@@doLevelWon2:
    CALL level2WonScreen
    ADD  SP, 2      ; discard return to gameLoop2_MainLoop
    RET             ; return all the way to MAIN
playLoop2Frame ENDP

; ============================================================
; processInput2 - Handle input for Level 2
; ============================================================
processInput2 PROC
    CMP  AH, 01h            ; ESC scan code -> save and exit game
    JNE  @@checkLeft2
    CALL saveGameResult
    ADD  SP, 4              ; skip: return-to-playLoop2Frame + return-to-gameLoop2_MainLoop
    RET                     ; return all the way to MAIN -> main menu

@@checkLeft2:
    CMP  AH, 4Bh            ; Left arrow
    JE   @@moveLeft2
    CMP  AH, 4Dh            ; Right arrow
    JE   @@moveRight2
    RET

@@moveLeft2:
    CMP  WORD PTR platformPos, 3840
    JLE  processInput2_done    ; already at left edge
    CALL erasePlatform
    MOV  AX, WORD PTR platformPos
    SUB  AX, 8
    CMP  AX, 3840
    JGE  @@leftOk2
    MOV  AX, 3840              ; clamp to row boundary
@@leftOk2:
    MOV  WORD PTR platformPos, AX
    JMP  processInput2_done

@@moveRight2:
    CMP  WORD PTR platformPos, 3980
    JGE  processInput2_done    ; already at right edge
    CALL erasePlatform
    MOV  AX, WORD PTR platformPos
    ADD  AX, 8
    CMP  AX, 3980
    JLE  @@rightOk2
    MOV  AX, 3980              ; clamp to row boundary
@@rightOk2:
    MOV  WORD PTR platformPos, AX

processInput2_done:
    RET
processInput2 ENDP

; ============================================================
; gameLoop3  ?  Main game logic loop for Level 3
; ============================================================
gameLoop3 PROC
    CALL clearScreenBlack
    
    ; Reset score at start of level
    MOV  WORD PTR score, 0
    CALL updateScore
    
    ; Reset lives
    MOV  BYTE PTR lives, 3
    
    ; Config for Level 3
    MOV  BYTE PTR tilesToWin, 40
    MOV  WORD PTR tilesRows, 4

    ; Reset all tiles back to 1 (not broken)
    MOV  CX, 40
    MOV  BX, 0
@@reset_tiles_loop3:
    MOV  BYTE PTR tiles[BX], 1
    INC  BX
    LOOP @@reset_tiles_loop3
    
    ; Reset tile break counters
    MOV  BYTE PTR tilesBrokenCounter, 0
    MOV  BYTE PTR tilesBrokenCounter2, 0
    
    ; Reset paddle position to center
    MOV  WORD PTR platformPos, 3910
    
    ; Initialize ball position
    CALL resetBall
    
    ; Draw HUD elements at top
    CALL displayLevel           ; Display Level first (top left)
    CALL drawScore              ; Display Score (after level)
    CALL displayLives           ; Display Lives dynamically
    CALL displayPlayerNameBlack ; Display player name (top right) with black background
    
    ; Draw game elements
    CALL print_tiles            ; Draw brick grid
    CALL drawBall               ; Draw ball
    CALL drawPlatform           ; Draw paddle

gameLoop3_MainLoop:
    CALL playLoop3Frame
    JMP  gameLoop3_MainLoop

gameLoop3 ENDP

; ============================================================
; playLoop3Frame - Single frame of Level 3 game loop
; ============================================================
playLoop3Frame PROC
    CALL eraseBall

    ; -- Input handling ------------------------------------
    ; --- AUTOPILOT ---
    ; Erase row 24 entirely (160 bytes = 80 words)
    PUSH ES
    PUSH AX
    PUSH DI
    PUSH CX
    MOV  AX, 0B800h
    MOV  ES, AX
    MOV  DI, 3840
    MOV  CX, 80
    MOV  AX, 0720h
    REP  STOSW
    
    ; Track ball's X position to middle of paddle
    MOV  AX, WORD PTR ballPos
    XOR  DX, DX
    MOV  CX, 160
    DIV  CX                 ; DX = col * 2 (0-158)
    ADD  DX, 3840           ; Row 24 start
    MOV  WORD PTR platformPos, DX
    
    POP  CX
    POP  DI
    POP  AX
    POP  ES
    
    ; Auto ESC key check just in case user wants to quit
    CALL checkKey
    JZ   @@skipInput3
    CALL readKey
    CMP  AH, 01h            ; ESC
    JNE  @@skipInput3
    CALL saveGameResult
    ADD  SP, 4
    RET

@@skipInput3:
    ; -- Predictive wall bounce (prevents line-wrap bug) ---
    MOV  AX, WORD PTR ballPos
    XOR  DX, DX
    MOV  CX, 160
    DIV  CX                 ; DX = current column (0-158)

    ADD  DX, WORD PTR deltaX

    CMP  DX, 160
    JL   @@checkLeftEdge3
    CMP  WORD PTR deltaX, 0
    JLE  @@checkLeftEdge3
    NEG  WORD PTR deltaX
    JMP  @@calcPos3

@@checkLeftEdge3:
    CMP  DX, 0
    JGE  @@calcPos3
    CMP  WORD PTR deltaX, 0
    JGE  @@calcPos3
    NEG  WORD PTR deltaX

@@calcPos3:
    ; -- Move ball -----------------------------------------
    MOV  AX, WORD PTR ballPos
    ADD  AX, WORD PTR deltaX
    ADD  AX, WORD PTR deltaY

    PUSH AX
    PUSH DX
    XOR  DX, DX
    MOV  BX, 160
    DIV  BX                 ; AX = row, DX = col
    MOV  BX, AX
    MOV  AX, DX

    CMP  BX, 1
    JG   @@skip_ry3
    JMP  reverseY3
@@skip_ry3:

    CMP  BX, 25
    JL   @@skip_bl3
    JMP  reverseY3
@@skip_bl3:

    CMP  AX, 0
    JG   @@skip_rx3
    JMP  reverseX3
@@skip_rx3:

    CMP  AX, 158
    JL   @@skip_rx3_2
    JMP  reverseX3
@@skip_rx3_2:

    POP  DX
    POP  AX
    MOV  WORD PTR ballPos, AX

    CALL drawBall
    CALL drawPlatform
    CALL updatePowerup
    CMP  WORD PTR fastTimer, 0
    JA   @@skip_delay3
    CALL delay3
    CMP  WORD PTR slowTimer, 0
    JE   @@skip_delay3
    CALL delay3
    
    ; Extra input poll to keep paddle speed normal during slow mode
    CALL checkKey
    JZ   @@skip_extra_in3
    CALL readKey
    CALL processInput3
@@skip_extra_in3:
    
    DEC  WORD PTR slowTimer
@@skip_delay3:
    CMP  WORD PTR fastTimer, 0
    JE   @@no_dec_fast3
    DEC  WORD PTR fastTimer
@@no_dec_fast3:

    CALL checkTileCollision
    CMP  BYTE PTR levelWonFlag, 1
    JNE  @@continue_loop3
    JMP  @@doLevelWon3
@@continue_loop3:
    CALL checkPlatformCollision

    RET

reverseX3:
    POP  DX
    POP  AX
    NEG  WORD PTR deltaX
    MOV  AX, WORD PTR ballPos
    ADD  AX, WORD PTR deltaX
    ADD  AX, WORD PTR deltaY
    MOV  WORD PTR ballPos, AX
    RET

reverseY3:
    POP  DX
    POP  AX
    NEG  WORD PTR deltaY
    MOV  AX, WORD PTR ballPos
    ADD  AX, WORD PTR deltaX
    ADD  AX, WORD PTR deltaY
    MOV  WORD PTR ballPos, AX
    RET

ballLost3:
    POP  DX
    POP  AX

    DEC  BYTE PTR lives
    CALL displayLives
    CMP  BYTE PTR lives, 0
    JE   @@doGameOver3

    CALL resetPlatform
    CALL drawPlatform

    ; Wait removed - spawn immediately

    CALL resetBall
    RET

@@doGameOver3:
    CALL gameOver
    ADD  SP, 2      ; discard return to gameLoop3_MainLoop
    RET             ; return all the way to MAIN

@@doLevelWon3:
    CALL gameWon
    ADD  SP, 2
    RET
playLoop3Frame ENDP

; ============================================================
; processInput3 - Handle input for Level 3
; ============================================================
processInput3 PROC
    CMP  AH, 01h            ; ESC scan code -> save and exit game
    JNE  @@checkLeft3
    CALL saveGameResult
    ADD  SP, 4              ; skip: return-to-playLoop3Frame + return-to-gameLoop3_MainLoop
    RET                     ; return all the way to MAIN -> main menu

@@checkLeft3:
    CMP  AH, 4Bh            ; Left arrow
    JE   @@moveLeft3
    CMP  AH, 4Dh            ; Right arrow
    JE   @@moveRight3
    RET

@@moveLeft3:
    CMP  WORD PTR platformPos, 3840
    JLE  processInput3_done    ; already at left edge
    CALL erasePlatform
    MOV  AX, WORD PTR platformPos
    SUB  AX, 8
    CMP  AX, 3840
    JGE  @@leftOk3
    MOV  AX, 3840              ; clamp to row boundary
@@leftOk3:
    MOV  WORD PTR platformPos, AX
    JMP  processInput3_done

@@moveRight3:
    CMP  WORD PTR platformPos, 3980
    JGE  processInput3_done    ; already at right edge
    CALL erasePlatform
    MOV  AX, WORD PTR platformPos
    ADD  AX, 8
    CMP  AX, 3980
    JLE  @@rightOk3
    MOV  AX, 3980              ; clamp to row boundary
@@rightOk3:
    MOV  WORD PTR platformPos, AX

processInput3_done:
    RET
processInput3 ENDP

; ============================================================
; updateScore  ?  Update scoreStr based on current score (3 digits max)
; ============================================================
updateScore PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH DI
    PUSH SI
    
    ; Position in scoreStr to update (after "SCORE: " = 7 chars, pointing to position after last digit)
    MOV  DI, OFFSET scoreStr
    ADD  DI, 9              ; Point to last digit position for right-to-left fill
    
    MOV  AX, WORD PTR score  ; Load score value
    MOV  BX, AX              ; Keep copy in BX
    
@@convert_digit:
    XOR  DX, DX
    MOV  CX, 10
    DIV  CX                  ; AX = quotient, DX = remainder (digit)
    
    ADD  DL, '0'             ; Convert digit to ASCII
    MOV  BYTE PTR [DI], DL   ; Store digit (right to left)
    DEC  DI
    
    CMP  AX, 0               ; If quotient is 0, we're done
    JNE  @@convert_digit
    
    ; Fill remaining spaces with '0' on the left
    MOV  DL, '0'
@@fill_zeros:
    CMP  DI, OFFSET scoreStr + 6  ; Stop at position after "SCORE: "
    JLE  @@done_converting
    MOV  BYTE PTR [DI], DL
    DEC  DI
    JMP  @@fill_zeros
    
@@done_converting:
    ; Restore original score value
    MOV  WORD PTR score, BX
    
    POP  SI
    POP  DI
    POP  DX
    POP  CX
    POP  BX
    POP  AX
    RET
updateScore ENDP

; ============================================================
; drawScore  ?  Display score in top left corner
; ============================================================
drawScore PROC
    PUSH ES
    PUSH AX
    PUSH DI
    PUSH SI
    PUSH CX
    
    MOV  AX, 0B800h
    MOV  ES, AX
    
    ; Clear the area first (20 positions to be safe)
    MOV  DI, 30
    MOV  AH, 0Fh
    MOV  AL, ' '
    MOV  CX, 20
@@clear_score_area:
    STOSW
    LOOP @@clear_score_area
    
    ; Position: Row 0, Column 16 (after Level display with spacing)
    MOV  DI, 30
    MOV  SI, OFFSET scoreStr
    MOV  AH, 0Fh            ; Bright white on black
    
@@print_score_loop:
    LODSB
    CMP  AL, 0
    JE   @@print_spaces
    STOSW
    JMP  @@print_score_loop

@@print_spaces:
    ; Print spacing after score to clear the area (15 spaces)
    MOV  AL, ' '
    MOV  AH, 0Fh
    STOSW
    STOSW
    STOSW
  

@@score_done:
    POP  CX
    POP  SI
    POP  DI
    POP  AX
    POP  ES
    RET
drawScore ENDP

END MAIN

