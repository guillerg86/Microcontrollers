/* 
 * File:   main.c
 * Author: navarrito
 *
 * Created on 25 de enero de 2014, 20:15
 */

#include <xc.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

//#include "TiTTimer.h"
#include "time.h"
//#include "LeTLeds.h"
#include "AuTAudio.h"
//#include "SwTSwitch.h"
//#include "PbTPushbutton.h"
#include "AdTADC.h"
//#include "BlTBacklight.h"
#include "SiTSio.h"
#include "LcTLCD.h"
#include "PrTPropaganda.h"
#include "BdTBoardData.h"
#include "CoTConversion.h"
#include "CsTComunicacioSerial.h"
#include "PwTPWM.h"
#include "ScTSongController.h"
#include "RfTRFID.h"
#include "RfTRFRX.h"
/*
 * 
 */



// Configuration Bits - 24.1 del Datasheet 
_CONFIG2(		IESO_OFF				// Two Speed Start-up               DISABLED
			&	SOSCSEL_LPSOSC       		// Low Power Secondary Oscillator   ENABLE
			&	WUTSEL_LEG           		// Legacy Wake-up timer selected
		 	&	FNOSC_FRCPLL        		// Fast RC oscillator w/ divide and PLL
		 	& 	FCKSM_CSDCMD			// Clock switching and clock monitor
			&	OSCIOFNC_ON			// OSCO/RC15 function               RC15
			&	IOL1WAY_OFF			// Una configuraciÛ per I/O remapejables deshabilitat
			&	POSCMOD_NONE			// Primary disabled
			& 	I2C1SEL_SEC
);


_CONFIG1(		JTAGEN_OFF                              // JTAG                             DISABLED
			&	GCP_OFF				// Code Protect                     DISABLED
			&	GWRP_OFF			// Write Protect                    DISABLED
			&	BKBUG_OFF			// Background Debugger              DISABLED
			&	COE_OFF				// Clip-on Emulation                DISABLED
			&	ICS_PGx1			// ICD pins select share            PGC1/PGD1
			&	FWDTEN_OFF			// Watchdog Timer                   DISABLED
			&	WINDIS_OFF			// Windowed WDT                     DISABLED
			&	FWPSA_PR128			// Watchdog prescaler	1:128
			&	WDTPS_PS2048			// Watchdog postscale	1:2048      Pre=128 i Post=2048 --> WatchDog Timer = 8seg
);



void initCPU(){
    CLKDIV=0x0000;          // Divisió del clock pel timer i CPU per 1
 //   OSCCON=0x0020;
    RCONbits.SWDTEN = 0;    // Desactivem el Watchdog
}




int main(void){
    initCPU();
    TiInit();
//    LeInit();
    LcInit(4,16);
    AuInit();
    SwInit();
    PbInit();
    AdInit();
    //BlInit();
    SiInit();
    LcClear();
    LcCursorOff();
    LcGotoXY(0,0);
    LcPutString("Booting...");
    initMotorLCD();
    //initPropaganda();
    BdInit();
    CsInit();   
    PwInit();
    ScInit();
    RecepcionInit();
    RfInit();
    while(1){
        
        MotorPulsador();
        //BlMotor();
//        MotorLed();
        MotorLCD();
        
        //MotorPropaganda();
        MotorSIO();
        MotorComunicadorSerial();
        MotorPWM(0);
        MotorPWM(1);
        MotorPWM(2);
        MotorSongController();
        MotorAudio();
        MotorRFID();
        MotorRecepcion();
  
    }
}

