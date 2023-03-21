# **Proyecto 3**
### Universidad de San Carlos de Guatemala
### Facultad de Ingeniería
### Escuela de Ciencias y Sistemas
### Arquitectura de Computadores y Ensambladores 1
### Sección B
<br></br>

## **Manual Técnico**
<br></br>

| Nombre | Carnet | 
| --- | --- |
| Damián Ignacio Peña Afre | 202110568 |
----

# **Descripción General**

Variación del juego de damas chinas para 2 jugadores, desarrollado en ensamblador para la arquitectura x86, utilizando el lenguaje de ensamblador MASM.

# **Requerimientos**
- DOSBox
- MASM

# **Variables importantes**


```asm

time db "00:00:00" ; Variable para almacenar la hora de generación

handleSaveFile dw 0 ; Variable para almacenar el manejador del archivo de guardado

commandBuffer db 258 dup(0ff) ; Variable para almacenar el comando ingresado por el usuario

gameBoard db 81 dup(0) ; Variable para almacenar el tablero de juego

turn db 1 ; Variable para almacenar el turno actual

; Variables para realizar calculos de las posiciones de las fichas

checkerInitialRow db 0
checkerInitialColumn db 0 

auxCheckerInitialRow db 0
auxCheckerInitialColumn db 0

checkerDestinationRow db 0
checkerDestinationColumn db 0

```



# **Funcion dentro del juego**

Función para leer del `commandBuffer` una posición del tablero y el par de caracteres a un fila y una columna que va desde 0 a 9.

```asm	
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
```

Función para calcular el indice asociado a el arreglo que representa el tablero de juego, a partir de una fila y una columna.

```asm
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
```

Función para calcular la distancia entre dos posiciones del tablero de juego, a partir de una fila y una columna de inicio y otra fila y columna final. Además de proporcionar la dirección de la distancia.

```asm
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
```


Función para validar que tipo de salto pretende realizar la ficha, ya sea si es un salto doble o un salto directo a una celda vacía contigua. Esto se realiza recibiendo la distancia de salto entre filas y columnas así como las direcciones horizontales y verticales. Así mismo se realiza la validación de tener una ficha intermediaría para el salto doble.


```asm
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
```


# ** Funciones Generales **


Función para comparar 2 strings referenciadas por los apuntadores DI y SI. Esta función se utiliza para comparar los comandos introducidos por el usuario con los comandos válidos del juego. Esta función se utiliza para validar los comandos introducidos por el usuario.


```asm
    ;   entry : si = offset string1
    ;           di = offset string2
    ;   exit  : dl = 1 if the command is valid, 0 otherwise
    compare_strings:
        mov cx, 0 ; 

        compare:
            mov al, [si] ; Get the command char
            mov bl, [di] ; Get the buffer char

            cmp al, bl ; Compare the chars
            jne strings_not_equal

            inc si ; Next command char
            inc di ; Next buffer char
            inc cx ; Next counter

            cmp cx, 4 ; 
            jne compare

            mov dl, 1 ; Strings are equal
            ret

        strings_not_equal:
            mov dl, 0 ; Strings are not equal
            ret     
```


# ** Funciones de Generación de archivos **


Función para transformar la hora actual del sistema y almacenarla en un string. Esta función se utiliza para generar la hora de generación del archivo de guardado.


```asm

    ; entry : none
    ; output Saves in 'time' the current time as HH:MM:SS
    convert_hour_to_ascii:
        ; Get the time
        mov ah, 2ch
        int 21h
        ; ch = hour, cl = minutes, dh = seconds, dl = hundredths of seconds

        ; Convert the hour
        mov al, ch
        call convert_to_ascii
        mov [time], bh
        mov [time + 1], bl

        mov [time + 2], 3a ; :

        ; Convert the minutes
        mov al, cl
        call convert_to_ascii
        mov [time + 3], bh
        mov [time + 4], bl

        mov [time + 5], 3a ; :

        ; Convert the seconds
        mov al, dh
        call convert_to_ascii
        mov [time + 6], bh
        mov [time + 7], bl
        
        ret

```

Funciones auxiliares para convertir un numero decimal a su representación en ascii. Esta función se utiliza para convertir la hora actual del sistema a su representación en ascii.


```asm
    ; entry : al = number to convert
    ; output 'bh' the tens
    ;        'bl' the units
    get_digits:
        mov bh, 0 ; tens
        mov bl, 0 ; units

        get_tens:
            cmp al, 0ah
            jl get_units
            sub al, 0ah
            inc bh
            jmp get_tens

        get_units:
            mov bl, al
            ret

    ; entry : al = number to convert
    ; output 'bh' the ascii code of the tens
    ;        'bl' the ascii code of the units
    convert_to_ascii:
        call get_digits

        add bh, 30h
        add bl, 30h
        ret
```