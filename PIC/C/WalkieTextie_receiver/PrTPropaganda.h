/* 
 * File:   PrTPropaganda.h
 * Author: JNM
 *
 * Placa de test per al PIC18F4321 controla el backlight del LCD, té un menú
 * interactiu pel SIO, i refresca l'estat dels perifèrics (2 pulsadors, 2 switchos,
 * 1 entrada analògica)
 * 
 */





#ifndef PRTPROPAGANDA_H
#define	PRTPROPAGANDA_H
#include <xc.h>
#include "BlTBacklight.h"
#include "SiTSio.h"
#include "PbTPushbutton.h"
#include "AuTAudio.h"
#include "AdTADC.h"
#include "SwTSwitch.h"

#include "LcTLCD.h"
#include "BdTBoardData.h"
#include "CoTConversion.h"



#define PROPAGANDA_1 "\n\rPlaca LS69. Sistemes Digitals i uProcessadors\r\n\0"
#define PROPAGANDA_2 "vCli v1.0. Programa de test\r\n\0"

/*
void myItoa(int num);
//Pre: 0<= num <= 9999
//Post: deixa a temp[3..0] el num en ASCII
void Menu(void);
//Pre: La SIO està inicialitzada
//Post: Pinta el menu pel canal sèrie

void initPropaganda(void);
//Pre: La SIO està inicialitzada
//Post: Inicialitza el timestamp i pinta la propaganda per la SIO

void MotorPropaganda(void);



*/

void initMotorLCD(void);
//Precondicion:     El LCD està inicialitzat
//Postcondicion:    Inicializa las variables necesarias para el motor

void LcNewMessage(void);
//Precondicion:     ---
//Postcondicion:    Envia a la maquina de estados a un estado de espera donde ademas 
//                  borra la informacion de la primera linea en el LCD

void MotorLCD(void);
#endif	/* PRTPROPAGANDA_H */

