/*
 * File:   BdTBoardData.c
 * Author: grodriguez
 *
 * Created on April 18, 2017, 4:17 PM
 */
#include "BdTBoardData.h"

static BoardData boardInfo;

// Declaracion de metodos privados
void BdResetFramesCounters(void);

void BdInit() {
    BdResetFramesCounters();
    boardInfo.identifier[0] = '0';
    boardInfo.identifier[1] = '0';
    boardInfo.identifier[2] = '0'; 
    boardInfo.last_message[300] = '\0';
    boardInfo.last_message_size = 0;
    boardInfo.savingMessage = 0;
    // Limpiamos la zona de memoria de la String, reaprovechamos la variable para contar
    for (boardInfo.last_message_size = 0; boardInfo.last_message_size<MESSAGE_SIZE; boardInfo.last_message_size++) {
        boardInfo.last_message[boardInfo.last_message_size] = ' ';
    }
    boardInfo.last_message_size = 0;
    
}
char BdHasIdentifier(void) {
    if ( (boardInfo.identifier[0] != '0') || (boardInfo.identifier[1]!='0') || (boardInfo.identifier[2]!='0') ) {
        return 1; 
    } else { 
        return -1; 
    }
}
unsigned char BdSetIdentifier(char identificador[3]) { 
    // Comprobamos que el identificador no sea 000
    if ( identificador[0] == '0' && identificador[1] == '0' && identificador[2] == '0' ) {
        return 0;
    }
    // Comprobamos que el identificador sea numerico
    if (!(identificador[0] >= '0' && identificador[0] <= '9')) { return 0; }
    if (!(identificador[1] >= '0' && identificador[1] <= '9')) { return 0; }
    if (!(identificador[2] >= '0' && identificador[2] <= '9')) { return 0; }
    
    // Si todo correcto, asignamos el nuevo identificador
    boardInfo.identifier[0] = identificador[0];
    boardInfo.identifier[1] = identificador[1];
    boardInfo.identifier[2] = identificador[2];
    
    return 1;
}
void BdGetIdentifier(char identificador[3]) {
    identificador[0] = boardInfo.identifier[0];
    identificador[1] = boardInfo.identifier[1];
    identificador[2] = boardInfo.identifier[2];
}
void BdGetIdentifiedFrames(char frames[3]) {
    frames[0] = boardInfo.frames_identified[0];
    frames[1] = boardInfo.frames_identified[1];
    frames[2] = boardInfo.frames_identified[2];
}
void BdGetTotalFrames(char frames[3]) {
    frames[0] = boardInfo.frames_total[0];
    frames[1] = boardInfo.frames_total[1];
    frames[2] = boardInfo.frames_total[2];
}
void BdIncreaseIdentifiedFrames() {
    if ( ++boardInfo.frames_identified[2] >= ('9'+1) ) {
        boardInfo.frames_identified[2] = '0';
        if ( ++boardInfo.frames_identified[1] >= ('9'+1) ) {
            boardInfo.frames_identified[1] = '0';
            if ( ++boardInfo.frames_identified[0] >= ('9'+1) ) {
                boardInfo.frames_identified[0] = '0';
            }
        }
    }
    BdIncreaseUnidentifiedFrames();
}
void BdIncreaseUnidentifiedFrames() {
    if ( ++boardInfo.frames_total[2] >= ('9'+1) ) {
        boardInfo.frames_total[2] = '0';
        if ( ++boardInfo.frames_total[1] >= ('9'+1) ) {
            boardInfo.frames_total[1] = '0';
            if ( ++boardInfo.frames_total[0] >= ('9'+1) ) {
                BdResetFramesCounters();      // Al haber llegado al limite, reiniciamos ambos contadores!
            }   
        }
    }
}
unsigned int BdGetLastMessageSize(void) {
    if ( boardInfo.savingMessage == 0 ) {
        return boardInfo.last_message_size;
    } else {
        return 0;
    }
}
unsigned int BdGetMaxMessageSize(void) {
    return MESSAGE_SIZE;
}
char BdGetMessageCharacter(unsigned int charPosition) {
    return boardInfo.last_message[charPosition];
}

void BdSaveNewMessageChar(char new_char) {
    // Protegemos al micro de no pasarse del buffer
    if ( boardInfo.last_message_size < MESSAGE_SIZE ) {
        boardInfo.last_message[boardInfo.last_message_size] = new_char;
        boardInfo.last_message_size++;
    }
}

void BdCleanLastMessage(void) {
    boardInfo.last_message_size = 0;
}
/*
 * PRIVATE METHODS
 */
void BdResetFramesCounters(void) {
    boardInfo.frames_identified[0] = boardInfo.frames_identified[1] = boardInfo.frames_identified[2] = '0';
    boardInfo.frames_total[0] = boardInfo.frames_total[1] = boardInfo.frames_total[2] = '0';
}
void BdSavingMessageStart(void) {
    boardInfo.savingMessage = 1;
}
void BdSavingMessageStop(void) {
    boardInfo.savingMessage = 0;
}
