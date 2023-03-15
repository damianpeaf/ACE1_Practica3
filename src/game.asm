.model small
.stack
.radix 16

.data

; General messages

initialMessage db 'Universidad de San Carlos de Guatemala', 0dh, 0ah,
                   'Facultad de Ingenieria', 0dh, 0ah,
                   'Escuela de Ciencias y Sistemas', 0dh, 0ah,
                   'Arquitectura de Compiladores y ensabladores 1', 0dh, 0ah,
                   'Seccion B', 0dh, 0ah,
                   'Damian Ignacio Pena Afre', 0dh, 0ah,
                   '202110568', 0dh, 0ah,
                   'Presiona ENTER', 0dh, 0ah, '$'

initialMenu db '1. Iniciar Juego', 0dh, 0ah,
               '2. Cargar Juego', 0dh, 0ah,
               '3. Salir', 0dh, 0ah, '$'

newLine db 0ah, '$'

; Game

boardDimension equ 9
gameBoard db 81 dup(0)
gameBoardSize equ $-gameBoard
turn db 0

colHeaders db    '       1   2   3   4   5   6   7   8   9', 0ah, '$'
lineSeparator db '     +---+---+---+---+---+---+---+---+---+', 0ah, '$'
cellContainer db       '   |', '$'
rowHeader db '   @  |','$'
player1 db 'W'
player2 db 'B'
computingTurn db 'Calculando turno', 0ah, '$'

.code

.startup
    
    startMenu: 
        mov dx, offset initialMessage      ; Show initial message
        mov ah, 09h                        
        int 21h

        call press_enter                   ; Wait for enter

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
    call show_board

    jmp startMenu


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