/* 
 * File:   
 * Author: grodriguez
 * Comments:
 * Revision history: 
 */
#ifndef BDTBOARDDATA_H
#define	BDTBOARDDATA_H
#define MESSAGE_SIZE 301                


typedef struct  {
    char identifier[3];                 // A falta de saber el tamaño del identificador, suponemos int
    char frames_identified[3];          // Pondremos 3 caracteres
    char frames_total[3];               // Pondremos 3 caracteres
    unsigned int last_message_size;
    char last_message[MESSAGE_SIZE];
    unsigned char savingMessage;
} BoardData;

void BdInit(void);
// Precondicion:    ---
// Postcondicion:   Inicializa la estructura de datos

char BdHasIdentifier(void);
// Precondicion:    ---
// Postcondicion:   Comprueba si existe un identificador definido. 
//                  Retorna -1 en caso negativo. 
//                  Retorna +1 si ya hay identificador

unsigned char BdSetIdentifier(char identificador[3]);
// Precondicion:    ---
// Postcondicion:   Guarda el identificador.

void BdGetIdentifier(char identificador[3]);
// Precondicion:    ---
// Postcondicion:   Devuelve el array de char con el identificador que hay guardado

void BdGetIdentifiedFrames(char frames[3]);
// Precondicion:    ---
// Postcondicion:   Devuelve el array de char con el numero de tramas identificadas

void BdGetTotalFrames(char frames[3]);
// Precondicion:    ---
// Postcondicion:   Devuelve el numero total de tramas recibidas

void BdIncreaseIdentifiedFrames(void);
// Precondicion:    ---
// Postcondicion:   Incrementa el numero de tramas identificadas y llama a BdIncreaseUnidentifiedFrames() 

void BdIncreaseUnidentifiedFrames(void);
// Precondicion:    ---
// Postcondicion:   Incrementa el numero total de tramas. Cuando llega a 999
//                  Reinicia las tramas totales a 000
//                  Reinicia las tramas identificadas a 000

unsigned int BdGetMaxMessageSize(void);
// Precondicion:    ----
// Postcondicion:   Devuelve el valor del tamaño del buffer

unsigned int BdGetLastMessageSize(void);
// Precondicion:    ----
// Postcondicion:   Devuelve el tamaño del ultimo mensaje recibido

char BdGetMessageCharacter(unsigned int charPosition);
// Precondicion:    La posicion del caracter debe estar entre 0 <= posicion < BdGetLastMessageSize()
// Postcondicion:   Devuelve el caracter que hay en esa posicion



void BdSaveNewMessageChar(char new_char);
// Precondicion:    Al iniciar una nueva frase, haber llamado al BdCleanLastMessage
// Postcondicion:   Guarda el nuevo caracter en el buffer

void BdCleanLastMessage(void);
// Precondicion:    ---
// Postcondicion:   Borra el mensaje anterior guardado

void BdSavingMessageStart(void);
// Precondicion:    ---
// Postcondicion:   Indica al tad que le estan cargando una nueva frase

void BdSavingMessageStop(void);
// Precondicion:    ---
// Postcondicion:   Indica al tad que han finalizado la carga de la nueva frase.


#endif	

