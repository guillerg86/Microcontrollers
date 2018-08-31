/*
 * File:   CsTComunicacioSerial.c
 * Author: grodriguez
 *
 * Created on April 19, 2017, 6:57 PM
 */

#include "CsTComunicacioSerial.h"

#define KBD_ESCAPE 27 
#define BUFFER_SIZE 3

/*
 * DECLARACIONES DE ZONA PRIVADA
 */

static char nuevo_identificador[BUFFER_SIZE];
static unsigned int contador_caracteres_enviados = 0;



void CsEnviaMenu(void);
void CsEnviaIdentificador(void);
void CsEnviaTramasIdentificadas(void);
void CsEnviaTramasTotales(void);
void CsGuardaIdentificador(void);
void CsEnviaValorConversion(void);


void CsInit(void) {
    
}
void CsEnviaMenu(void) {
    // Precondicion:    ---
    // Postcondicion:   Envia el menu por la EUSART
    SiPutsCooperatiu("\n\nWelcome to PIC P2F2\n\n");
    SiPutsCooperatiu("\t1 - Introduir nou identificador\n");
    SiPutsCooperatiu("\t2 - Consultar ID Actual\n");
    SiPutsCooperatiu("\t3 - Consultar trames identificades\n");
    SiPutsCooperatiu("\t4 - Consultar trames rebudes totals\n");
    SiPutsCooperatiu("\t5 - Visualitzar ultim missatge\n\n");
    // DEBUG
    SiPutsCooperatiu("\t6 - DBG: Incrementa tramas identificadas\n");
    SiPutsCooperatiu("\t7 - DBG: Incrementa tramas totales\n");
    SiPutsCooperatiu("\t8 - DBG: Haz sonar altavoz\n");
    SiPutsCooperatiu("\t9 - DBG: Recibe frase\n");

    SiPutsCooperatiu("Selecciona una opcion:\n");
}
void CsEnviaIdentificador(void) {
    // Precondicion:    ---
    // Postcondicion:   Envia el identificador que tiene cargado la placa por la EUSART    
    char identificador[3];
    BdGetIdentifier(identificador);
    SiSendChar(identificador[0]); 
    SiSendChar(identificador[1]);
    SiSendChar(identificador[2]);
}
void CsEnviaTramasIdentificadas(void) {
    // Precondicion:    ---
    // Postcondicion:   Envia el numero (en ASCII) de las tramas identificadas  
    char tramas[3];
    BdGetIdentifiedFrames(tramas);
    SiSendChar(tramas[0]); 
    SiSendChar(tramas[1]);
    SiSendChar(tramas[2]);
}
void CsEnviaTramasTotales(void) {
    // Precondicion:    ---
    // Postcondicion:   Envia el numero (en ASCII) de las tramas no identificadas
    char tramas[3];
    BdGetTotalFrames(tramas);
    SiSendChar(tramas[0]); 
    SiSendChar(tramas[1]);
    SiSendChar(tramas[2]);
}
void CsGuardaIdentificador() {
    // Precondicion:    Deben existir 3 caracteres en el buffer de SERIAL
    // Postcondicion:   Introduce el nuevo identificador en el "SingleTon" BdTBoardData 
    
    // Intentamos guardar el nuevo identificador 
    if ( !BdSetIdentifier(nuevo_identificador) ) {
        SiPutsCooperatiu("ERROR: El identificador no se ha podido guardar.\n");
        SiPutsCooperatiu("\t¿Tiene el formato correcto? 3 numeros diferentes de 0\n");
    }
}
unsigned char CsEnviaUltimoMensaje(void) {
    // Precondicion:    ---
    // Postcondicion:   Envia la frase guardada en memoria por puerto serial

    SiSendChar(BdGetMessageCharacter(contador_caracteres_enviados));
    contador_caracteres_enviados++;
    if ( contador_caracteres_enviados < BdGetLastMessageSize() ) {
        return 1;
    }
    return 0;
}
void CsRecibeFrase(void) {
    // Precondicion:    ---
    // Postcondicion:   Recibe la frase por EUSART (debug), no es cooperativo 
    char sioRX = ' ';
    BdCleanLastMessage();
    while (sioRX != '#') {
        if ( SiCharAvail() > 0 ) {
            sioRX = SiGetChar();
            if (sioRX != '#' && BdGetLastMessageSize() < BdGetMaxMessageSize() ) {
                BdSaveNewMessageChar(sioRX);
            }
        }
    }
}
void MotorComunicadorSerial() {
    static unsigned char estado_siguiente = 0;
    static unsigned char estado = 0;
    static char charRX = '0'; 
    static int num_charsRX = 0;
    //static char debug_num_letrass[10]; 
    
    switch (estado) {
        case 0:
            CsEnviaMenu();
            estado = 1;
            estado_siguiente = 0;
            
        break;
        case 1:

            num_charsRX = SiCharAvail();
            if ( num_charsRX > 0 ) {
                charRX = SiGetChar();
                switch (charRX) {
                    case '1':
                        estado = 100;
                        estado_siguiente = 10;
                        break;
                    case '2':
                        estado = 100;
                        estado_siguiente = 20;
                        break;
                    case '3':
                        estado = 100;
                        estado_siguiente = 30;
                        break;
                    case '4':
                        estado = 100;
                        estado_siguiente = 40;
                        break;
                    case '5':
                        estado = 100;
                        estado_siguiente = 50;
                        break;
                    case '6':
                        estado = 100;
                        estado_siguiente = 60;
                        break;
                    case '7':
                        estado = 100;
                        estado_siguiente = 70;
                        break;
                    case '8':
                        estado = 100;
                        estado_siguiente = 80;
                        break;
                    case '9':
                        SiPutsCooperatiu("\n\nEscribe el mensaje debug, recuerda acabar con el caracter #\n");
                        estado = 100;
                        estado_siguiente = 90;
                        break;
                    default:
                        SiPutsCooperatiu("ERROR: Opció seleccionada no valida\n");
                        estado = 100;
                        estado_siguiente = 0;
                        break;
                } 
            }
            break;
        case 10:
            // CsEnviaFormatoIdentificador
            // El usuario ha introducido la opcion de insertar nuevo identificador
            SiPutsCooperatiu("Introduce un nuevo identificador\n");
            SiPutsCooperatiu("\tHa de contener 3 caracteres numericos (de 0-9 ej:069)\n");
            SiPutsCooperatiu("\tNo ha de ser 000\n");
            SiPutsCooperatiu("\tEl no cumplir estas directrices conlleva la no actualizacion del ID\n");
            
            // Limpiamos el buffer en modo cooperativo y enviamos al estado 11
            estado = 100;
            estado_siguiente = 11;
            break;
        case 11:
            // Esperamos a que llegue el primer byte
            if ( SiCharAvail() > 0 ) {
                nuevo_identificador[0] = SiGetChar();
                if (nuevo_identificador[0] == KBD_ESCAPE) {
                    estado = 100;
                    estado_siguiente = 0;
                } else {
                    estado = 12;    
                }
            }
            break;
        case 12:
            // Esperamos a que llegue el segundo byte
            if ( SiCharAvail() > 0 ) {
                nuevo_identificador[1] = SiGetChar();
                if (nuevo_identificador[1] == KBD_ESCAPE ) {
                    estado = 100;
                    estado_siguiente = 0;
                } else {
                    estado = 13;
                }
            }
            break;
        case 13:
            // Esperamos a que llegue el tercer byte 
            if ( SiCharAvail() > 0 ) { 
                nuevo_identificador[2] = SiGetChar();
                if ( nuevo_identificador[2] == KBD_ESCAPE ) {
                    estado = 100;
                    estado_siguiente = 0;
                } else {
                    estado = 14;
                }
            }
            break;
        case 14:
            // Guardamos el nuevo identificador en el TAD
            CsGuardaIdentificador();
            estado = 100;
            estado_siguiente = 0;
            break;
        case 20:
            CsEnviaIdentificador();
            estado = 100;
            estado_siguiente = 0;
            break;
        case 30:
            CsEnviaTramasIdentificadas();
            estado = 100;
            estado_siguiente = 0;
            break;
        case 40:
            CsEnviaTramasTotales();
            estado = 100;
            estado_siguiente = 0;
            break;
        case 50:
            contador_caracteres_enviados = 0;
            estado = 51;           
            break;
        case 51:

            if ( CsEnviaUltimoMensaje() == 0 ) {
                estado = 100;
                estado_siguiente = 0;
            }
            break;
        case 60:    // DEBUG
            BdIncreaseIdentifiedFrames();
            estado = 100;
            estado_siguiente = 0;
            break;
        case 70:    // DEBUG
            BdIncreaseUnidentifiedFrames();
            estado = 100;
            estado_siguiente = 0;
            break;
        case 80:    // DEBUG
            ScStartSong();
            estado = 100;
            estado_siguiente = 0;
            break;
        case 90:    // DEBUG
            
            CsRecibeFrase();            // Recibimos frase en modo no cooperativo
            ScStartSong();              // Hacemos sonar al altavoz
            LcNewMessage();             // Ponemos al LCD mostrando NEW message
            BdIncreaseIdentifiedFrames();// Incrementamos los mensajes identificados 
            estado = 100;
            estado_siguiente = 0;
            break;
        case 100:
            num_charsRX = SiCharAvail();
            if ( num_charsRX > 0 ) {
                charRX = SiGetChar();   // Limpiamos el buffer pero en modo cooperativo
            } else {
                estado = estado_siguiente;
                estado_siguiente = 0;   // Reseteamos el estado_siguiente;
            }
            break;
        default:
            estado = 0;
            estado_siguiente = 0;
            break;
    }
}



