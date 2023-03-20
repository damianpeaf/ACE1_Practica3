include macros.asm

.model small
.stack
.radix 16

.data

; General messages

initialMessage db  "Universidad de San Carlos de Guatemala", 0dh, 0ah,"Facultad de Ingenieria", 0dh, 0ah,"Escuela de Ciencias y Sistemas", 0dh, 0ah,"Arquitectura de Compiladores y ensabladores 1", 0dh, 0ah,"Seccion B", 0dh, 0ah,"Damian Ignacio Pena Afre", 0dh, 0ah,"202110568", 0dh, 0ah,"Presiona ENTER", 0dh, 0ah, "$"

initialMenu db "1. Iniciar Juego", 0dh, 0ah, "2. Cargar Juego", 0dh, 0ah, "3. Salir", 0dh, 0ah, "$"
newLine db 0ah, "$"

; Game

boardDimension equ 9
gameBoard db 81 dup(0)
gameBoardSize equ $-gameBoard
turn db 1
commandBuffer db 258 dup(0ff)

; Checker
checkerInitialRow db 0
checkerInitialColumn db 0 

auxCheckerInitialRow db 0
auxCheckerInitialColumn db 0

checkerDestinationRow db 0
checkerDestinationColumn db 0

lastCommmandAddress dw 0
commandSize db 0

; Board
colHeaders db    "       1   2   3   4   5   6   7   8   9", 0ah, "$"
lineSeparator db "      *---*---*---*---*---*---*---*---*---*", 0ah, "$"
cellContainer db       "   |", "$"
rowHeader db "   @  |","$"
player1 db "B"
player2 db "W"

; Messages
computingTurn db "Calculando turno...", 0ah, "$"
player1InitialTurn db "Empieza el jugador 1", 0dh, 0ah, "$"
player2InitialTurn db "Empieza el jugador 2", 0dh, 0ah, "$"
player1Won db "Gano el jugador 1, con piezas >>B<<", 0dh, 0ah, "$"
player2Won db "Gano el jugador 2, con piezas >>W<<", 0dh, 0ah, "$"
player1Turn db "Turno del jugador 1 con piezas >>B<<", 0dh, 0ah, "$"
player2Turn db "Turno del jugador 2 con piezas >>W<<", 0dh, 0ah, "$"
checkerMoveRequest db "Pieza a mover : ", 0dh, 0ah, "$"
checkerDestinationRequest db "Destino : ", 0dh, 0ah, "$"
invalidCommand db "Comando invalido", 0dh, 0ah, "$"
validCommand db "Comando valido", 0dh, 0ah, "$"
invalidPosition db "Posicion invalida", 0dh, 0ah, "$"
invalidChecker db "Pieza invalida", 0dh, 0ah, "$"
invalidDestination db "Destino invalido", 0dh, 0ah, "$"
.code

.startup
    
    startMenu: 
        mPrint initialMessage      ; Show initial message
        call press_enter           ; Wait for enter

        mPrint newLine

        initial_menu:

        mPrint initialMenu         ; Show the initial menu

        mov ah, 08h                         ; Get the option
        int 21h

        cmp AL, 31h                         ; 1 -> Init game
        je start_game

        ; 2 -> Load game

        cmp AL, 33h                         ; 3 -> Exit
        je end_game

        jmp startMenu                       ; Invalid option


start_game:
    mPrint computingTurn
    ; Get the turn

    mov ah, 2ch ; get random number seed
    int 21h
    ;convert to 0 or 1
    mov al, dl
    and al, 1

    cmp al, 0
    je player1_initial_turn

    cmp al, 1
    je player_2_initial_turn

    pending_start:

    call press_enter                   ; Wait for enter

    ; Fill each position with 0
    mov cx, gameBoardSize
    mov si, offset gameBoard
    restart_board:
        mov byte ptr [si], 0
        inc si
        loop restart_board

    ; Fill the board with the checkers
    call reinit_board

    ; Show the board
    jmp game_sequence

    jmp end_game

player1_initial_turn:
    mov [turn], 1
    mPrint player1InitialTurn
    jmp pending_start
                        

player_2_initial_turn:
    mov [turn], 2
    mPrint player2InitialTurn
    jmp pending_start
reinit_board:
    ; Player 1 checkers

    mov si, offset gameBoard
    mov byte ptr [si], 1                        ; First row
    mov byte ptr [si+1], 1
    mov byte ptr [si+2], 1
    mov byte ptr [si+3], 1

    mov byte ptr [si+9], 1                      ; Second row
    mov byte ptr [si+0a], 1
    mov byte ptr [si+0b], 1

    mov byte ptr [si+12], 1                     ; Third row
    mov byte ptr [si+13], 1

    mov byte ptr [si+1b], 1                     ; Fourth row

    ; Player 2 checkers

    mov si, offset gameBoard
    mov byte ptr [si+35], 2                     ; First row

    mov byte ptr [si+3d], 2                     ; Second row
    mov byte ptr [si+3e], 2

    mov byte ptr [si+45], 2                     ; Third row
    mov byte ptr [si+46], 2
    mov byte ptr [si+47], 2

    mov byte ptr [si+4d], 2                     ; Fourth row
    mov byte ptr [si+4e], 2
    mov byte ptr [si+4f], 2
    mov byte ptr [si+50], 2

    ret

game_sequence:

    ;Show the board
    call show_board

    call eval_someone_won
    cmp dl, 0
    jne someone_won

    ; Show the turn
    cmp turn, 1
    je player_1_turn
    
    cmp turn, 2
    je player_2_turn


    player_1_turn:
        mPrint player1Turn

        jmp command_request

    player_2_turn:
        mPrint player2Turn

        jmp command_request

    command_request:
        mPrint checkerMoveRequest ; Show the command request
        
        mov dx, offset commandBuffer ; Get the command
        mov ah, 0ah
        int 21h

        command_type_validation:
            mov bx, offset commandBuffer

            inc bx ; Move to string size
            mov al, [bx] ; Get the size
            inc bx ; Move to the first character

            cmp al, 2 ; Check if the size is 2 (Coordinates)
            je move_request
        
            jne game_command     ; Check if it is a game command

        move_request:
            ; check valid position
            call position_validation

            cmp dl, 0 ; Check if there was an error
            jne invalid_position ; If there was an error, show the error message

            call compute_index ; Compute the index
            mov [checkerInitialRow], al 
            mov [checkerInitialColumn], ah 

            mov [auxCheckerInitialRow], al 
            mov [auxCheckerInitialColumn], ah 

            ; ? Validate if there is a checker in the position
            is_own_checker:
                mov dx, offset gameBoard
                add bx, dx ; Get the address of the position

                mov al, [bx] ; Get the value of the position
                mov ah, [turn] ; Get the turn

                cmp al, ah ; Compare the value with the turncls
                jne invalid_checker ; If they are different, it is an invalid checker

                ; saves the initial position


        destination_request:
            mPrint checkerDestinationRequest

            mov dx, offset commandBuffer ; Get the destination
            mov ah, 0ah
            int 21h
            
            mov bx, offset commandBuffer
            inc bx ; skip, max chars and char counter
            mov al, [bx] ; Get the size
            mov [commandSize], al ; Save the size of the command
            inc bx ; Move to the first character

            eval_jump:
                call position_validation

                cmp dl, 0 ; Check if there was an error
                jne invalid_position ; If there was an error, show the error message

                call compute_index ; Compute the index

                mov [checkerDestinationRow], al
                mov [checkerDestinationColumn], ah

                call is_cell_empty ; Check if its empty
                cmp dl, 1 
                jne invalid_destination ; If it is not empty, it is an invalid destination

                ; Compute distance between the initial and destination
                call compute_distance

                ; Validate jump type
                call validate_jump_type
                cmp dl, 0 ; invalid jump type
                je invalid_destination

                cmp dl, 1 ; Direct jump
                je direct_jump_validation

                cmp dl, 2 ; Multiple jump
                je multiple_jump_validation
              
                direct_jump_validation:
                    cmp [commandSize], 2 ; Check if the size is 2
                    je move_checker
                    jmp invalid_destination

                multiple_jump_validation:
                    cmp [commandSize], 2 ; Do the jump
                    je move_checker

                    ; recursive call
                    ; Comma validation
                    mov bx, [lastCommmandAddress]
                    inc bx ; Move to the comma
                    mov al, [bx]
                    cmp al, 2c ; Check if the character is a comma
                    jne invalid_destination

                    mov al, [checkerDestinationRow]
                    mov [auxCheckerInitialRow], al

                    mov al, [checkerDestinationColumn]
                    mov [auxCheckerInitialColumn], al

                    mov al, [commandSize]
                    sub al, 3 ; skip destination and comma
                    mov [commandSize], al

                    inc bx ; Move to the next character
                    jmp eval_jump

            jmp end_game ; ?

;  -----------------------------GAME Calculations-----------------------------

    ;; Entry  - bx -> commandBuffer address of the first character
    ;; Output - ah -> column
    ;;          al -> row
    ;;          dl -> error (0 -> no error, 1 -> error)
    position_validation: 
        mov al, [bx] ; Get the first character, [Column, 1-9 -> ASCII 31h-39h]
        cmp al, 39h ; Compare with 9
        jg position_error ; If it is greater than 9, it is invalid

        cmp al, 31h ; Compare with 1
        jl position_error ; If it is less than 1, it is invalid

        sub al, 31h ; Convert to 0-8 [For indexing]
        mov ah, al ; Save the column in AH

        inc bx ; Move to the second character [Row, A-I -> ASCII 41h-49h]
        mov al, [bx] ; Get the second character

        cmp al, 49h ; Compare with I
        jg position_error ; If it is greater than I, it is invalid

        cmp al, 41h ; Compare with A
        jl position_error ; If it is less than A, it is invalid

        sub al, 41h ; Convert to 0-8 [For indexing], save in AL
        mov dl, 0 ; No error

        mov [lastCommmandAddress], bx ; save the last command address   

        ret
    
    ;; Entry  - AH -> column
    ;;          AL -> row
    ;; Output - BX | BL -> index (Doesnt mutate AH or AL?, but mutates cl)
    compute_index:
        ; Compute index -> i = AH + AL * 9 = column + row * 9 

        ; note: mul takes AL * operator = AX, save AH and AL momentarily
        mov bl, al
        mov bh, ah

        mov ah, 0 ; reset ah
        mov cl, 9
        mul cl

        mov ah, bh ; restore ah once
        add al, ah ; relative index
        mov cl, al ; save the index

        mov al, bl ; restore al
        mov ah, bh ; restore ah
        
        mov bx, 0 ; reset bx
        mov bl, cl ; save the index in bl
        ret

    ;; Entry - BX -> index
    ;; Output - DL -> is empty (1 -> empty, 0 -> not empty)
    ;; mutates dx, bx, al, dl
    is_cell_empty:
        mov dx, offset gameBoard
        add bx, dx ; Get the address of the position

        mov al, [bx] ; Get the value of the position

        cmp al, 0 ; Check if the value is 0
        je cell_empty ; If it is 0, it is empty

        mov dl, 0 ; 0 for not empty
        ret

        cell_empty:
            mov dl, 1 ; 1 for empty
            ret

    ;; Entry - None
    ;; Output - al -> row distance
    ;;          ah -> column distance
    ;;          bl -> (right -> 1, left -> 0)
    ;;          bh -> (up -> 1, down -> 0)
    compute_distance:
        mov al, [auxCheckerInitialRow]
        mov ah, [auxCheckerInitialColumn]

        mov bl, [checkerDestinationRow]
        mov bh, [checkerDestinationColumn]

        sub al, bl ; Compute the difference between the rows
        sub ah, bh ; Compute the difference between the columns

        mov bl, 0
        mov bh, 1

        cmp al, 0 ; Check if the difference is negative
        jge positive_row_difference ; If it is positive, continue

        neg al ; If it is negative, make it positive
        mov bh, 0

        positive_row_difference:
            cmp ah, 0 ; Check if the difference is negative
            jge positive_column_difference ; If it is positive, continue

            neg ah ; If it is negative, make it positive
            mov bl, 1

            positive_column_difference:
                ret


    ;; Entry - al -> row distance
    ;;         ah -> column distance
    ;;         bl -> (right -> 1, left -> 0)
    ;;         bh -> (up -> 1, down -> 0)  
    ;; Output - dl -> jump type (0 -> invalid, 1 -> direct, 2 -> multiple)
    validate_jump_type:

        ; Direct jump
        ; 1st case: row_distance 1, column_distance 0 (Vertical)
        cmp al, 1
        je direct_jump_vertical

        ; 2nd case: row_distance 0, column_distance 1 (Horizontal)
        cmp ah, 1
        je direct_jump_horizontal

        ; Multiple jump
        ; 1st case: row_distance 2, column_distance 0 (Vertical)
        cmp al, 2
        je multiple_jump_vertical

        ; 2nd case: row_distance 0, column_distance 2 (Horizontal)
        cmp ah, 2
        je multiple_jump_horizontal

        jmp jump_error

        multiple_jump_vertical:
            cmp ah, 0
            jne jump_error

            mov al, [auxCheckerInitialRow]
            mov ah, [auxCheckerInitialColumn]

            ; Validate intermediate cell
            cmp bh, 1 ; Check if the jump is up
            je multiple_jump_up

            multiple_jump_down:
                add al, 1 ; Move to the intermediate cell
                jmp intermediate_vertical

            multiple_jump_up:
                sub al, 1 ; Move to the intermediate cell
                jmp intermediate_vertical

            intermediate_vertical:
                call compute_index
                call is_cell_empty
                cmp dl, 0 ; Check if the intermediate cell is not empty
                je multiple_jump

                jmp jump_error


        multiple_jump_horizontal:
            cmp al, 0
            jne jump_error

            mov al, [auxCheckerInitialRow]
            mov ah, [auxCheckerInitialColumn]

            ; Validate intermediate cell
            cmp bl, 1 ; Check if the jump is right
            je multiple_jump_right

            multiple_jump_left:
                sub ah, 1 ; Move to the intermediate cell
                jmp intermediate_horizontal

            multiple_jump_right:
                add ah, 1 ; Move to the intermediate cell
                jmp intermediate_horizontal

            intermediate_horizontal:
                call compute_index
                call is_cell_empty
                cmp dl, 0 ; Check if the intermediate cell is not empty
                je multiple_jump

                jmp jump_error
        
        multiple_jump:
            mov dl, 2
            ret

        direct_jump_vertical:
            cmp ah, 0
            je direct_jump
            jmp jump_error

        direct_jump_horizontal:
            cmp al, 0
            je direct_jump
            jmp jump_error

        direct_jump:
            mov dl, 1
            ret

        jump_error:
            mov dl, 0 ; Invalid jump
            ret

    ;; Entry - BX -> index
    ;;       - AL -> symbol
    ;; Output - None
    set_dasboard_cell:
        mov dx, offset gameBoard
        add bx, dx ; Get the address of the position
        mov [bx], al ; Set the value of the position
        ret

    move_checker:
        mov al, [checkerInitialRow]
        mov ah, [checkerInitialColumn]
        call compute_index

        mov al, 0 ; Symbol for empty cell
        call set_dasboard_cell

        mov al, [checkerDestinationRow]
        mov ah, [checkerDestinationColumn]

        call compute_index

        mov al, [turn]
        call set_dasboard_cell
    
        change_turn:
            mov al, [turn]
            cmp al, 1
            je change_turn_to_2

            mov al, 1
            mov [turn], al
            jmp game_sequence

            change_turn_to_2:
                mov al, 2
                mov [turn], al
                jmp game_sequence

    ; Entry - None
    ; Output - dl -> (1|2) -> winner (0 -> no winner)
    eval_someone_won:
        mov bx, offset gameBoard

        ; Check if the player 1 won
        eval_player_1_won:
            mov al, [bx+35]
            cmp al, 1
            jne eval_player_2_won
            mov al, [bx+3d]
            cmp al, 1
            jne eval_player_2_won
            mov al, [bx+3e]
            cmp al, 1
            jne eval_player_2_won
            mov al, [bx+45]
            cmp al, 1
            jne eval_player_2_won
            mov al, [bx+46]
            cmp al, 1
            jne eval_player_2_won
            mov al, [bx+47]
            cmp al, 1
            jne eval_player_2_won
            mov al, [bx+4d]
            cmp al, 1
            jne eval_player_2_won
            mov al, [bx+4e]
            cmp al, 1
            jne eval_player_2_won
            mov al, [bx+4f]
            cmp al, 1
            jne eval_player_2_won
            mov al, [bx+50]
            cmp al, 1
            jne eval_player_2_won

            mov dl, 1 ; Player 1 won
            ret

        ; Check if the player 2 won 
        eval_player_2_won:
            mov al, [si]
            cmp al, 2
            jne noone_won
            mov al, [si+1]
            cmp al, 2
            jne noone_won
            mov al, [si+2]
            cmp al, 2
            jne noone_won
            mov al, [si+3]
            cmp al, 2
            jne noone_won
            mov al, [si+9]
            cmp al, 2
            jne noone_won
            mov al, [si+0a]
            cmp al, 2
            jne noone_won
            mov al, [si+0b]
            cmp al, 2
            jne noone_won
            mov al, [si+12]
            cmp al, 2
            jne noone_won
            mov al, [si+13]
            cmp al, 2
            jne noone_won
            mov al, [si+1b]
            cmp al, 2
            jne noone_won

            mov dl, 2 ; Player 2 won
            ret

        ; No one won
        noone_won:
            mov dl, 0
            ret

    show_board:
        ; Col headers
        mPrint colHeaders

        ; Line separator
        mPrint lineSeparator

        ; Board
        mov di, 0 ; Cell counter
        mov cx, boardDimension ; Row counter

        print_line:
            ; Row header
            mov bx, offset rowHeader
            add bx, 3 ; Move to @ position
            
            mov al, [bx] ; copy symbol
            inc al ; Get the next symbol

            mov [bx], al ; Save the symbol
            sub bx , 3 ; Move to the start of the row header

            mov dx, bx ; Print the row header
            mov ah, 09h
            int 21h

            push cx ; Save the row counter
            mov cx, boardDimension ; Counter to print the cells

        print_cell:
            mov al, [di+gameBoard] ; Get the cell value
            mov bx, offset cellContainer ; Get the cell container
            inc bx ; Move to the symbol position

            cmp al, 0 ; Empty cell
            je empty_cell

            cmp al, 1 ; Player 1
            je player1_cell

            cmp al, 2 ; Player 2
            je player2_cell

            empty_cell:
                dec bx ; Move to the start of the cell container
                jmp print_cell_value
            
            player1_cell:
                mov al, player1 ; Get the player 1 symbol
                mov [bx], al ; Save the symbol
                dec bx ; Move to the start of the cell container
                jmp print_cell_value

            player2_cell:
                mov al, player2 ; Get the player 2 symbol
                mov [bx], al ; Save the symbol
                dec bx ; Move to the start of the cell container
                jmp print_cell_value

            print_cell_value:
                mov dx, bx ; Print the cell
                mov ah, 09h
                int 21h

                inc bx ; Restore the cell container
                mov al, 20 ; Space
                mov [bx], al ; Save the space
                dec bx ; Move to the start of the cell container

                inc di ; Next cell
                loop print_cell

                mPrint newLine ; Print the new line

                mPrint lineSeparator ; Print the line separator

                pop cx ; Restore the row counter
                loop print_line


                mov al, 40 ; Restore the row header
                mov bx, offset rowHeader
                add bx, 3 ; Move to symbol position
                mov [bx], al
            
                ret

    someone_won:
        cmp dl, 1 ; Player 1 won
        je player1_won

        ; player 2 won
            mPrint player2Won
            jmp initial_menu

        player1_won:
            mPrint player1Won
            jmp initial_menu

;  ------------------------ Game Commands ------------------------

    game_command:
        jmp end_game


; ------------------------ Errors ------------------------
    position_error:
        mov dl, 1 ; Error
        ret

    invalid_position:
        mPrint invalidPosition

        call press_enter

        jmp game_sequence

    invalid_checker:
        mPrint invalidChecker

        call press_enter

        jmp game_sequence

    invalid_command:
        mPrint invalidCommand

        call press_enter

        jmp game_sequence

    invalid_destination:
        mPrint invalidDestination
        call press_enter
        jmp game_sequence



press_enter:
    mov AH, 08h                         ; Leer un caracter
    int 21h
    cmp AL, 0dh
    jne press_enter
    ret

end_game:
    mov al, 0                           ; Terminar el programa
    mov ah, 4ch                         
    int 21h

end