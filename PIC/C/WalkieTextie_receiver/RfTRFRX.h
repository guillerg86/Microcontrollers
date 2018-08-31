#ifndef RFTRFRX_H
#define	RFTRFRX_H

#include <xc.h> // include processor files - each processor file is guarded.  

#define BUFFER_RFRX_SIZE   32




void RecepcionInit();
//Pre: -- 
//Post: Inicializa el RFID
void MotorRecepcion();

unsigned int RfCharAvail(void);
//Pre: --
//Post: Devuelve un 1 en caso de que haya un dato en el buffer

char RfGetChar(void);
//Pre: RfCharAvail()==1
//Post: Devuelve el dato que esté en el buffer
#endif	/* XC_HEADER_TEMPLATE_H */

