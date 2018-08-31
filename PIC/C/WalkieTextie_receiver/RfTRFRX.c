/*
 * File:   RfTRFEX.c
 * Author: Ares Argiles + Guille Rodriguez 
 *
 * Created on 8 de mayo de 2017, 19:08
 */


#include <p24FJ64GA002.h>


#include "xc.h"
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include "time.h"
#include "RfTRFRX.h"

#include "SiTSio.h"


#define ESPERA_7MS 7
// Variables para la recepcion
static char timerRX;
static char bitsRecibidos;


// Variables para el guardado de los bytes recibidos (buffer)
static char buffer_rx[BUFFER_RFRX_SIZE];
static char IniciRX,cuantos,FiRx;

//static char byte_recibido[10];   // Solo para debug
static unsigned char bitsRX, startBits, startFlagRecibido;
static char byte;
static unsigned int bytesRX;
static unsigned char byteCounter;
static unsigned char bitRXAnterior = 0;




#define FLAG_START_TRANSMISSION   0x01
#define FLAG_END_TRANSMISSION   0x06

#define TIEMPO_CHKSTARTBIT 18
#define MAXTIEMPO_ALCAMBIO 5
#define ESPERA_UN_MS 4
#define ESPERA_DIEZ_MS 10
#define REPETICIONES_STARTBIT 1
#define MAXBYTES 100



void RfPuts(char dato);



void RfPuts(char dato){
    buffer_rx[IniciRX++] = dato;
	if (IniciRX == BUFFER_RFRX_SIZE) IniciRX = 0;
	cuantos++;
}

unsigned int RfCharAvail(void){
    return cuantos;
}

char RfGetChar(void){
    char tmp;
	tmp = buffer_rx[FiRx++];
	if (FiRx == BUFFER_RFRX_SIZE) FiRx = 0;
	cuantos --;
	return tmp;
    
}


void RecepcionInit(){
    timerRX=TiGetTimer();
    IniciRX=0;
    FiRx=0;
    TRISAbits.TRISA3=1;
    TRISBbits.TRISB14=0;
    LATBbits.LATB14=0;
    // byte_recibido[8]='\n';      // DEBUG
    // byte_recibido[9]='\0';      // DEBUG
}



void MotorRecepcion(){
    static unsigned char estadoRX = 0;
    switch(estadoRX) {
        case 0:
            // Reiniciamos los valores
            bitsRX = byte = bytesRX = byteCounter = 0;
            estadoRX = 1;
        break;
        case 1:
            // Esperamos a detectar el primer 1 del startbit
            if (PORTAbits.RA3 == 1) {
                TiResetTics(timerRX);
                estadoRX = 2;
            }	
        break;
        case 2:
            // Esperamos a detectar el 0 y comprobamos si el tiempo que ha estado el 1, es un tiempo
            // valido para nuestro 1 de startbit
            if ( PORTAbits.RA3 == 0) {
                // Como nuestro primer bit, la primera parte es a 0, pero la segunda es 1
                // marcaremos como el bitanterior = 0 , para luego ver el cambio en 1
                bitRXAnterior = 0;
                if ( TiGetTics(timerRX) >= 9  ) {
                    TiResetTics(timerRX);
                    estadoRX = 3;
                } else  {
                    estadoRX = 0;
                }
            }
            break;
        case 3:
            // Ahora cuando ya ha llegado el 0, miramos si el tiempo que ha estado a 0 el startbit, es
            // un tiempo valido. Si esta dentro de un tiempo valido, enviamos al estado 4 donde iremos 
            // obteniendo bit a bit.
            if ( PORTAbits.RA3 == 1) {
                if ( TiGetTics(timerRX) >=13 && TiGetTics(timerRX) <= 17 ) {
                    TiResetTics(timerRX);
                    estadoRX = 4;
                } else {
                    estadoRX = 0;
                }
            }
            break;            
        case 4:
            // Si el bit actual del puerto, es diferente al bitanterior, entonces ha sucedido un cambio
            // en la señal, por lo tanto estamos en la 2a parte de un bit enviado con el metodo de codificacion
            if ( bitRXAnterior != PORTAbits.RA3 ) {
                TiResetTics(timerRX);   // Reseteamos timer para ajustarnos/sincronizarnos
                if ( PORTAbits.RA3 == 1 ) {
                    // Si el bit es 1 , desplazamos los bits que ya hay en el byte hacia la derecha
                    // multiplicamos por 01111111 los valores que haya (asi no perdemos lo que habia)
                    // en el byte y le sumamos 10000000
                    byte = ((byte>>1) & 0x7F) | 0x80;  
                    //byte_recibido[bitsRX] = '1';      // DEBUG
                } else {
                    // Si el bit es 0, desplazamos los antiguos valores del byte hacia la derecha
                    // y simplemente multiplicamos por 01111111 para mantener los valores anteriores
                    // como el bit que queremos añadir es 0, ya no hace falta sumarselo.
                    byte = ((byte>>1) & 0x7F);
                    // byte_recibido[bitsRX] = '0';    // DEBUG
                }
                bitsRX++;
                estadoRX = 5;
            }
            break;
        case 5:
            estadoRX = 6;
            // Si ya tenemos un byte (8 bits) procedemos a gestionarlo
            if ( bitsRX >= 8 ) {
                bytesRX++;          // Actualizamos el numero de bytes recibidos
                bitsRX = 0;         // Reiniciamos el contador de bits
                RfPuts(byte);       // Guardamos el byte en el buffer
                switch ( byte ) {
                    case FLAG_END_TRANSMISSION:
                        // En caso de tener un byte de fin de transmission
                        // al encontrarlo, enviamos al estado 0 el driver de 
                        // escucha de RF.
                        estadoRX = 0;                    
                        break;
                    default:
                        // Si no es un byte de fin de transmission, simplemente dejamos que prosiga al estado 6
                        break;
                }
                /*
                if (bytesRX >= MAXBYTES) {
                    // En el caso de que nos sepamos con antelacion cuantos bytes vamos a recibir...
                    // podemos intentar contar el numero de caracteres y cuando lleguemos a ese numero
                    // entonces enviamos hacia afuera.
                    estadoRX = 0;
                }
                */
            }
            break;
        case 6:
            // Ahora ya que ya hemos recuperado 1 BIT (si BIT), esperariamos 10 ms para caer en la segunda parte del siguiente
            // bit (pero caeriamos justo cuando cambia ), pero para evitar problemas de offset o ir muy justos, lo ponemos a 8ms, 
            // cayendo asi en la primera parte del siguiente bit, y tan solo hemos de esperar al cambio y de esta forma nos 
            // resincronizamos de nuevo
            if( TiGetTics(timerRX) >= 8 ) {
                TiResetTics(timerRX);           // Reseteamos timer para resincronizar
                bitRXAnterior = PORTAbits.RA3;  // Guardamos el valor de bit de la primera parte del siguiente bit
                estadoRX = 4;                   // Enviamos al estado 4 para esperar el cambio 
            }
            break;
    }
}
  