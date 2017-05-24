breed [obreras obrera]
breed [nidos nido]

patches-own
[
  id-nido
  id-comida
  nivel-comida
  nivel-feromonas
]

obreras-own
[
  comida-encontrada
  comida-transportada
  vuelta-nido?
  tiempo-recolectando    ; Tiempo que la hormiga lleva buscando comida desde la última recolección llevada a un nido.
]

nidos-own
[
  comida-almacenada
]


to inicializar
  ;; Inicializar el mundo.

  clear-all
  crear-terreno
  crear-comida
  crear-nidos
  crear-obreras
  actualizar-colores
  reset-ticks
end


to crear-terreno
  ;; Se inicializa el terreno

  ask patches
  [
    set id-nido -1
    set id-comida -1
    set nivel-comida 0
    set nivel-feromonas 0
  ]
end

to crear-obreras
  ;; Crear y configurar las hormigas iniciales en el mundo.

  create-ordered-obreras poblacion
  [
    set shape "bug"
    set size 2
    set color red
    set comida-encontrada 0
    set comida-transportada 0
    set vuelta-nido? false
    set tiempo-recolectando 0
  ]
end


to crear-comida
  ;; Crear la comida inicial del mundo.

  foreach n-values num-comidas [n -> n]
  [
    n -> ask patch random-pxcor random-pycor
    [
      ask patches in-radius dimension-comida
      [
        ;set pcolor green
        set id-comida n
        set nivel-comida comida-por-celda
      ]
    ]
  ]
end


to crear-nidos
  ;; Crear el nido central

  create-ordered-nidos num-nidos
  [
    set shape "house"
    set color yellow
    set size 1
    set comida-almacenada 0
    setxy random-pxcor random-pycor
    ask (patch-set patch-here neighbors)
    [
      set pcolor orange
      set id-nido [who] of myself
    ]
  ]
end


to accionar
  ;; Empezar la acción en el mundo.

  actualizar-obreras
  actualizar-feromonas
  actualizar-colores

  ; Si no queda comida, fin.
  if not any? patches with [nivel-comida > 0] and not any? obreras with [comida-transportada > 0] [stop]

  tick
end


to actualizar-obreras
  ;; Realizar el ciclo de las hormigas obreras.

  ask obreras
  [
    ifelse vuelta-nido?
    [almacenar-comida obtener-nido-cercano]
    [recolectar-comida]

    set label comida-transportada
  ]
end


to-report volver-obrera-a-nido?
  ;; Decidir si volver al nido para almacenar la comida recolectada

  report comida-transportada > 0 and (comida-transportada >= max-comida-transportada or tiempo-recolectando >= max-tiempo-recolectando)
end


to recolectar-comida
  ;; Búsqueda de comida por parte de una hormiga obrera.

  avanzar-obrera-a-comida

  if ([nivel-comida] of patch-here) > 0
  [
    let comida-extraida comida-a-extraer
    ask patch-here
    [
      set nivel-comida (nivel-comida - comida-extraida)
      set pcolor black
    ]

    set comida-encontrada comida-encontrada + comida-extraida
    set comida-transportada comida-transportada + comida-extraida
  ]

  set tiempo-recolectando tiempo-recolectando + 1
  if volver-obrera-a-nido?
  [
    set vuelta-nido? true
    set tiempo-recolectando 0
  ]
end


to-report comida-a-extraer
  ;; Calcular la comida a extraer de una celda actual por la hormiga obrera agente.

  report min list (max-comida-transportada - comida-transportada) ([nivel-comida] of patch-here)
end


to almacenar-comida [nido-cercano]
  ;; Mover hormiga obrera al nido pasado por argumento para almacenar comida

  avanzar-obrera-a-nido nido-cercano
  if [who] of nido-cercano != [id-nido] of patch-here [stop]

  set vuelta-nido? false

  if comida-transportada = 0 [stop]

  ; Almacena la comida en el nido
  ask nido-cercano
  [
    set comida-almacenada comida-almacenada + ([comida-transportada] of myself)
    set label comida-almacenada
  ]
  set comida-transportada 0
end



to actualizar-colores
  ;; Actualizar los colores de todas las entidades: hormigas, celdas, ...

  ask obreras [cambiar-color-hormiga]
  ask patches [cambiar-color-celda]
end


to cambiar-color-hormiga
  ;; Cambiar el color de la hormiga en función de su cantidad de comida recolectada hasta ahora en total.

  if color = yellow [stop]
  ifelse comida-encontrada > 4
  [set color yellow]
  [if color = red and comida-encontrada > 2 [set color blue]]
end


to cambiar-color-celda
  ;; Cambiar el color de la celda en función de sus estado.

  ; Cambio de color en función del nivel de feromonas
  if id-nido = -1 and nivel-comida = 0
  [set pcolor scale-color blue nivel-feromonas 0 100]

  if nivel-comida > 0 [set pcolor scale-color green nivel-comida 0 (comida-por-celda + 2)]
end


to-report obtener-nido-cercano
  ;; Obtener el nido más cercano al actual agente hormiga obrera

  report min-one-of nidos [distance myself]
end


to actualizar-feromonas
  diffuse nivel-feromonas difusion-feromonas  ; Difuminar las feromonas
  let factor 0.2  ; A mayor factor la duración baja más drásticamente a medida que se disminuye la barra.
  ask patches
  [
    ifelse nivel-feromonas > 0 and nivel-feromonas < 1 ; Evitar que se difuminen eternamente con decimales bajísimos.
    [set nivel-feromonas 0]
    [set nivel-feromonas nivel-feromonas / (1 + factor - factor * duracion-feromonas)] ; Bajar el nivel en cada ciclo en función de la duración.
  ]
end


to avanzar-obrera-a-comida
  ;; Realizar el movimiento de la hormiga al dirigirse hacia la búsqueda de comida.

  let angulo 30
  let nivel-izq nivel-feromonas-siguiente-celda (- angulo)
  let nivel-dch nivel-feromonas-siguiente-celda angulo
  let nivel-ava nivel-feromonas-siguiente-celda 0
  let nivel-max max (list nivel-izq nivel-dch nivel-ava)

  ifelse nivel-max > nivel-ava
  [ifelse nivel-max = nivel-izq [left angulo] [right angulo]]
  [if nivel-max = 0 [ifelse azar [right random max-giro] [left random max-giro]]]

  forward random max-avance
end


to avanzar-obrera-a-nido [nido-cercano]
  ;; Realizar el movimiento de la hormiga al dirigirse hacia el nido más cercano.

  face nido-cercano
  forward 1 + ((max-comida-transportada - comida-transportada) / max-comida-transportada) * (max-avance - 1)
  if comida-transportada > 0 [ask patch-here [set nivel-feromonas nivel-feromonas + potencia-feromonas]]
end


to-report nivel-feromonas-siguiente-celda [angulo]
  ;; Obtener el nivel de feromonas de la siguiente celda posicionada a un determinado ángulo

  let siguiente-celda patch-right-and-ahead angulo 1
  report ifelse-value (siguiente-celda = nobody) [0] [[nivel-feromonas] of siguiente-celda]
end


to-report azar
  ;; Obtener Verdadero/Falso al azar.

  report random 2 = 0
end
@#$#@#$#@
GRAPHICS-WINDOW
498
10
1121
634
-1
-1
9.462
1
10
1
1
1
0
0
0
1
-32
32
-32
32
0
0
1
ticks
60.0

BUTTON
125
10
220
43
Preparar
inicializar
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
234
10
327
43
Empezar
accionar
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
26
87
216
120
poblacion
poblacion
1
300
143.0
1
1
NIL
HORIZONTAL

PLOT
29
384
466
633
Total comida
Tiempo
Comida
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"comida encontrada" 1.0 0 -13210332 true "" "plot sum [comida-encontrada] of obreras"
"comida almacenada" 1.0 0 -3844592 true "" "plot sum [comida-almacenada] of nidos"
"comida restante" 1.0 0 -7500403 true "" "plot sum [nivel-comida] of patches"

SLIDER
248
83
444
116
max-avance
max-avance
1
20
3.0
1
1
NIL
HORIZONTAL

SLIDER
248
123
445
156
max-giro
max-giro
1
180
89.0
1
1
NIL
HORIZONTAL

TEXTBOX
249
60
399
78
Hormigas
14
0.0
1

SLIDER
26
127
216
160
num-nidos
num-nidos
1
10
2.0
1
1
NIL
HORIZONTAL

TEXTBOX
30
62
180
80
Entorno\n
14
0.0
1

SLIDER
247
164
471
197
max-comida-transportada
max-comida-transportada
1
10
2.0
1
1
NIL
HORIZONTAL

SLIDER
247
205
471
238
max-tiempo-recolectando
max-tiempo-recolectando
10
1000
57.0
1
1
NIL
HORIZONTAL

SLIDER
248
247
471
280
potencia-feromonas
potencia-feromonas
0
100
100.0
1
1
NIL
HORIZONTAL

SLIDER
247
289
471
322
duracion-feromonas
duracion-feromonas
0
1
0.9
0.1
1
NIL
HORIZONTAL

SLIDER
27
170
217
203
num-comidas
num-comidas
1
10
3.0
1
1
NIL
HORIZONTAL

SLIDER
28
211
218
244
dimension-comida
dimension-comida
1
10
5.0
1
1
NIL
HORIZONTAL

SLIDER
29
253
217
286
comida-por-celda
comida-por-celda
1
10
3.0
1
1
NIL
HORIZONTAL

SLIDER
247
332
470
365
difusion-feromonas
difusion-feromonas
0
1
0.2
0.1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

Evitar que los nidos se junten con los centros de comida al preparar el mundo.

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
