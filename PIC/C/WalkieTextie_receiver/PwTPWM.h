
#ifndef PWTPWM_H
#define	PWTPWM_H

#define INIT_PWM0_OUT() TRISAbits.TRISA2=0;
#define INIT_PWM1_OUT() TRISBbits.TRISB10=0;
#define INIT_PWM2_OUT() TRISBbits.TRISB11=0;
#define LATA_PWM0_RA2() LATAbits.LATA2=1;
#define LATA_PWM1_RB10() LATBbits.LATB10=1;
#define LATA_PWM2_RB11() LATBbits.LATB11=1;
#define TPeriodo 20

#include <xc.h>
#include "time.h"

void PwInit(void);

void MotorPWM(char pwm);

void setValor(char pwm, char valor);
//Pre: 0<=pwm<=2 y 0<=valor<=1
//Post: Calcula el el tiempo a 1 que tiene que estar el PWM depediendo del número de id en el que se encuentre.



#endif	

