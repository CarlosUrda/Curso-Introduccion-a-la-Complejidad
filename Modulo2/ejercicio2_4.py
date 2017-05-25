#!/bin/usr/env python3

"""
Código para solucionar el ejercicio 2.4
"""

from sys import argv


def obtener_args():
    """
    Obtener los argumentos de entrada
    """
    num_args = len(argv)
    if num_args < 3 or num_args > 4:
        print("ERROR: Número erróneo de argumentos")
        return None

    # Comprobar excepciones
    razon = float(argv[1])
    poblacion = float(argv[2])
    tiempo = 10 if num_args == 3 else int(argv[3])

    return razon, poblacion, tiempo


def modelo(razon, poblacion, tiempo):
    """
    Modelo de mapeo logístico.
    """
    for _ in range(tiempo):
        poblacion = razon * (poblacion - poblacion**2)

    return poblacion


def main():
    """
    Función principal
    """
    args = obtener_args()
    if args is None:
        print("Formato correcto => {} Razón %PoblaciónInicial [Iteraciones]".format(argv[0]))
        exit()

    razon, poblacion_inicial, tiempo = args

    poblacion = modelo(razon, poblacion_inicial, tiempo)

    print("Porcentaje de población inicial:", poblacion_inicial)
    print("Razón a aplicar al modelo:", razon)
    print("Tiempo de desarrollo:", tiempo)
    print("Porcentaje de población resultante:", poblacion)


if __name__ == "__main__":
    main()
