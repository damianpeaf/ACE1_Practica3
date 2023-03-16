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

colHeaders db    "       1   2   3   4   5   6   7   8   9", 0ah, "$"
lineSeparator db "      +---+---+---+---+---+---+---+---+---+", 0ah, "$"
cellContainer db       "   |", "$"
rowHeader db "   @  |","$"
player1 db "B"
player2 db "W"
computingTurn db "Calculando turno...", 0ah, "$"
player1InitialTurn db "Empieza el jugador 1", 0dh, 0ah, "$"
player2InitialTurn db "Empieza el jugador 2", 0dh, 0ah, "$"
player1Turn db "Turno del jugador 1 con piezas >>B<<", 0dh, 0ah, "$"
player2Turn db "Turno del jugador 2 con piezas >>W<<", 0dh, 0ah, "$"
checkerMoveRequest db "Pieza a mover : ", 0dh, 0ah, "$"
checkerDestinationRequest db "Destino : ", 0dh, 0ah, "$"
invalidCommand db "Comando invalido", 0dh, 0ah, "$"
validCommand db "Comando valido", 0dh, 0ah, "$"
invalidPosition db "Posicion invalida", 0dh, 0ah, "$"
invalidChecker db "Pieza invalida", 0dh, 0ah, "$"
.code

.startup
    
    startMenu: 
        mov dx, offset initialMessage      ; Show initial message
        mov ah, 09h                        
        int 21h

        call press_enter                   ; Wait for enter

        mov dx, offset newLine
        mov ah, 09h
        int 21h

        mov dx, offset initialMenu         ; Show the initial menu
        mov ah, 09h                        
        int 21h
    

        mov ah, 08h                         ; Get the option
        int 21h

        cmp AL, 31h                         ; 1 -> Init game
        je start_game

        ; 2 -> Load game

        cmp AL, 33h                         ; 3 -> Exit
        je end_game

        jmp startMenu                       ; Invalid option


start_game:
    mov DX, offset computingTurn
    mov AH, 09h
    int 21h
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
    mov dx, offset player1InitialTurn
    mov ah, 09h
    int 21h
    jmp pending_start
                        

player_2_initial_turn:
    mov [turn], 2
    mov dx, offset player2InitialTurn
    mov ah, 09h
    int 21h
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

    ; Show the turn
    cmp turn, 1
    je player_1_turn
    
    cmp turn, 2
    je player_2_turn


    player_1_turn:
        mov dx, offset player1Turn
        mov ah, 09h
        int 21h

        jmp command_request

    player_2_turn:
        mov dx, offset player2Turn
        mov ah, 09h
        int 21h

        jmp command_request

    command_request:
        mov dx, offset checkerMoveRequest ; Show the command request
        mov ah, 09h
        int 21h

        
        mov dx, offset commandBuffer ; Get the command
        mov ah, 0ah
        int 21h

        command_type_validation:
            mov bx, offset commandBuffer

            inc bx ; Move to string size
            mov al, [bx] ; Get the size

            cmp al, 2 ; Check if the size is 2 (Coordinates)
            je move_request
        
            jne game_command     ; Check if it is a game command

        move_request:
            ; check valid position
            call position_validation

            cmp dl, 0 ; Check if there was an error
            jne invalid_position ; If there was an error, show the error message

            ; Compute index -> i = AH + AL * 9 = column + row * 9 

            ; note: mul takes AH * operator, save AH momentarily
            mov bl, ah
            mov cl, 9
            mul cl
            mov ah, bl ; return the value

            add al, ah ; relative index
            mov bx, 0 ; reset bx
            mov bl, al ; Save the index in BL

            ; Validate if there is a checker in the position

            mov dx, offset gameBoard
            add bx, dx ; Get the address of the position

            mov al, [bx] ; Get the value of the position
            mov ah, [turn] ; Get the turn

            cmp al, ah ; Compare the value with the turncls
            jne invalid_checker ; If they are different, it is an invalid checker


        destination_request:
            mov dx, offset checkerDestinationRequest
            mov ah, 09h
            int 21h

            jmp end_game


        ;; Entry  - bx -> commandBuffer address
        ;; Output - ah -> column
        ;;          al -> row
        ;;          dl -> error (0 -> no error, 1 -> error)
        position_validation: 
            inc bx ; Move to the first character [Column, 1-9 -> ASCII 31h-39h]

            mov al, [bx] ; Get the first character
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

            ret
            

        game_command:
            jmp end_game

        position_error:
            mov dl, 1 ; Error
            ret

        invalid_position:
            mov dx, offset invalidPosition
            mov ah, 09h
            int 21h

            call press_enter

            jmp game_sequence

        invalid_checker:
            mov dx, offset invalidChecker
            mov ah, 09h
            int 21h

            call press_enter

            jmp game_sequence

        invalid_command:
            mov dx, offset invalidCommand
            mov ah, 09h
            int 21h

            call press_enter

            jmp game_sequence
            

    ; TODO : Check if the move is valid
    ; TODO : Update the board
    ; TODO : Check if the game is over
    ; TODO : Change the turn
    ; TODO : Repeat

    jmp end_game


show_board:
    ; Col headers
    mov dx, offset colHeaders
    mov ah, 09h
    int 21h

    ; Line separator
    mov dx, offset lineSeparator
    mov ah, 09h
    int 21h

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

            mov dx, offset newLine ; Print the new line
            mov ah, 09h
            int 21h

            mov dx, offset lineSeparator ; Print the line separator
            mov ah, 09h
            int 21h

            pop cx ; Restore the row counter
            loop print_line


            mov al, 40 ; Restore the row header
            mov bx, offset rowHeader
            add bx, 3 ; Move to symbol position
            mov [bx], al
        
            ret

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