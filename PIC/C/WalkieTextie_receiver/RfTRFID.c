/*
 * File:   RfTRFID.c
 * Author: ares
 *
 * Created on 8 de mayo de 2017, 16:35
 */
#include "RfTRFID.h"
#include "RfTRFRX.h"
#include "BdTBoardData.h"
#include "PrTPropaganda.h"
#include "ScTSongController.h"

#define FLAG_END_TRANSMISSION   0x06
#define FLAG_START_TRANSMISSION   0x01

static char estadoRF;
static char dato;
static char identificador[3];
static char nuestroIdentificador = 1;


void RfInit(){
    //Poner puerto RFID como entrada
    estadoRF=0;
    
    
    
}

void MotorRFID(){
    switch(estadoRF){           
        case 0:
            if (RfCharAvail()>0){
                dato = RfGetChar();
                if (dato == FLAG_START_TRANSMISSION ) {
                    nuestroIdentificador = 1;
                    BdGetIdentifier(identificador);
//                    SiPuts("\n\n");
//                    SiSendChar(identificador[0]);
//                    SiSendChar(identificador[1]);
//                    SiSendChar(identificador[2]);
//                    SiPuts("\n\n");
                    estadoRF=1;
                } 
            }
            break;
            
        case 1:
            if ( RfCharAvail() > 0) {
                dato = RfGetChar();
                if (dato!=identificador[0]){
                    nuestroIdentificador = 0;
                }
                estadoRF=2;
            }
            break;
        case 2:
            if (RfCharAvail()>0){
                dato = RfGetChar();
                estadoRF = 3;
            }
            break;
            
        case 3:
            if (dato!=identificador[1]){
                nuestroIdentificador = 0;
            }
            estadoRF = 4;
            break;
           
        case 4:
            if (RfCharAvail()>0){
                dato = RfGetChar();
                estadoRF = 5;
            }
            break;
        case 5:
            if (dato!=identificador[2]){
                nuestroIdentificador = 0;
            }
            estadoRF = 6;
            break;
        case 6:
            if ( nuestroIdentificador == 0 ) {
                estadoRF=20;
            } else {
                BdCleanLastMessage();
                BdSavingMessageStart();

                estadoRF=7;
            }
            break;
            
        case 7:
            if (RfCharAvail()>0){
                dato = RfGetChar();
                estadoRF=8;
            }
            break;
            
        case 8:
            if (dato == FLAG_END_TRANSMISSION) {
                estadoRF=10;
            }else if (BdGetLastMessageSize() < BdGetMaxMessageSize()){
                BdSaveNewMessageChar(dato);
                estadoRF=9;
            }else{
                estadoRF=9;
            }
            break;
            
        case 9:
            estadoRF=7;
            break;
            
        case 10:
            LcNewMessage();
            ScStartSong();              // Hacemos sonar al altavoz
            BdIncreaseIdentifiedFrames();// Incrementamos los mensajes identificados 
            BdSavingMessageStop();
            estadoRF=0;            
            break;
            
        case 20:
            //SiPutsCooperatiu("Identificador Invalido!");
            if (RfCharAvail()>0){
                dato = RfGetChar();
                estadoRF=21;
            }
            break;
            
        case 21:
            if (dato==FLAG_END_TRANSMISSION){
                BdIncreaseUnidentifiedFrames();
                estadoRF=0;
            }else{
                estadoRF=20;
            }
            break;
    

    }
}