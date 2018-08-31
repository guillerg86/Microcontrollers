/*
 * File:   CoGetConversion.c
 * Author: ares
 *
 * Created on 18 de abril de 2017, 18:00
 */



#include "CoTConversion.h"

static int conversion;

int CoGetConversion (int valor){
    /* Queremos hacer la conversion de [0<->1023] --> [200<->2000] por lo que realizaremos la siguiente operacion:
     * Si 0 -> 200 y 1023 -> 2000 , el problema es que si realizamos la operacion como valor * 2000 / 1024 realmente
     * estaremos repartiendo los 1024 valores que nos pueden introducir entre 2000 valores, pero realmente lo queremos
     * entre 1800 (2000-200) por ello usaremos la operacion:
     * 
     *      conversion = valor * 1800 / 1024 y esto realizara el mapeo a 0->0 y 1023 -> 1800
     * tan solo debemos hacerle un offset de +200 y ya tendremos el valor correcto
     *      conversion = (valor * 1800 / 1024) + 200; 
     * En el caso de que el ADC retorne un valor == 0
     *      conversion = (0*1800/1024)+200 = 0+200 = 200 --> Correcto
     * En el caso de que el ADC retorne un valor == 1023
     *      conversion = (1023*1800/1024)+200 = 1998 --> Incorrecto! 
     * 
     * La solucion pasa por dividir entre 1023
     * 
     * conversion = (0*1800/1023)+200 = 0 + 200 = 200 --> Correcto
     * conversion = (1023*1800/1023)+200 = 1800 + 200 = 2000 --> Correcto
     * 
     * El 1,76 viene de la división de 1800 / 1023. 
     */ 
    conversion = (valor * 1.76) + CONVERSION_MIN_VALUE;
    if ( conversion < CONVERSION_MIN_VALUE ) return CONVERSION_MIN_VALUE;
    if ( conversion > CONVERSION_MAX_VALUE ) return CONVERSION_MAX_VALUE;
    return conversion; 
}
char CoGetPeriode(unsigned int value) {
    // Vamos a mapear un valor que puede ir del 1 a 300 a un rango de 1 a 127)
    // Esto significa un valor value * 127 / 300 => value * 0,423
    // Despues de hablar con Ester, hacemos que el ratio vaya de 1 a 30
    float periode = (value * 0.0633)+1;
    if ( periode > 20) { return 20;}
    return (char)periode;
}
