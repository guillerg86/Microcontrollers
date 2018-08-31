
#ifndef COTCONVERSION_H
#define	COTCONVERSION_H
#define CONVERSION_MAX_VALUE 2000
#define CONVERSION_MIN_VALUE 200
#define PARAMETER_MAX_VALUE 1023
#define PARAMETER_MIN_VALUE 0


#include <xc.h> // include processor files - each processor file is guarded. 

int CoGetConversion(int valor);
//Pre: Que sea un valor entre 0 y 1024
//Post: Devuelve el valor de la conversión a segundos

char CoGetPeriode(unsigned int value);
//Pre: 0<=value<=300
//Post: Devuelve un char corrspondiente al periodo mapeado entre 1 y 127. 

#endif	/* XC_HEADER_TEMPLATE_H */

