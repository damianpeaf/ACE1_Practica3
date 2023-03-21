# **Proyecto 3**
### Universidad de San Carlos de Guatemala
### Facultad de Ingeniería
### Escuela de Ciencias y Sistemas
### Arquitectura de Computadores y Ensambladores 1
### Sección B
<br></br>

## **Manual de Usuario**
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

# **Ejecución**

1. Abrir DOSBox
2. Compilar el archivo `main.asm` con el comando `ml game.asm`
3. Ejecutar el archivo `game.exe` con el comando `game.exe`

# ** Iinicio de la aplicación**

![Inicio](img/Inicio.png)

Se una pantalla con los datos del desarrollador y es posible acceder al menú principal presionando `Enter`.

# **Menú Principal**

![Menú Principal](img/MenuPrincipal.png)

En el menú principal se puede seleccionar entre las siguientes opciones:
- Iniciar Juego
- Cargar Juego
- Salir

## **Iniciar Juego**

![Iniciar Juego](img/IniciarJuego.png)

Al seleccionar la opción `Iniciar Juego` se inicia una nueva partida.

## **Cargar Juego**

![Cargar Juego](img/CargarJuego.png)

Al seleccionar la opción `Cargar Juego` se carga una partida guardada.

## **Salir**
Esta opción cierra la aplicación.


# **Juego**

Al iniciar una partida se sortea el turno del jugador que inicia.

![Juego](img/Sorteo.png)

Luego del sorteo es posible presionar `Enter` para continuar.

![Juego](img/Juego.png)

Dentro de la partida se desplegará en la parte inferior el jugador que tiene el turno actual.

Los movimientos se realizan de la siguiente manera:
- Las piezas se moverán únicamente vertical u horizontalmente, es decir, solo por sus lados y nunca por los vertices; no tienen sentido de movimiento las piezas por su posición, estas pueden regresar si así se desea.

- Las piezas pueden saltar a otras piezas de una en una si la siguiente celda en el sentido del movimiento se encuentra libre, no importa si son propias o del rival

-Si la pieza se mueve a una celda contigua se cuenta como un movimiento completo.

- Si se desea saltar piezas se puede hacer un salto o muchos saltos.

-Si se tratan de muchos saltos las celdas destino deben ser introducidas en orden de salto en una misma línea separadas por comas, si dentro del listado hay un movimiento inválido se deberá regresar a la solucitud inicial sin efectuar nigún movimiento de la lista.

## **Comandos dentro del juego**

Se puede ingresar de manera literal los siguientes comandos:

- `GUARDAR` para guardar la partida actual en 2 archivos, `board.sav`y `turn.sav`.
- `ABANDONAR` para salir del juego y regresar al menú principal.
- `GENERARPAGINA` para generar un archivo HTML con la información de la partida actual.

# **Fin de la partida**

La partida finaliza cuando el jugador lleva sus piezas a la base contraria.

# **Cargar Partida**

Es posible cargar a partir de un archivo `board.sav` y `turn.sav` una partida guardada.
