
#include "PwTPWM.h"
#include "time.h"
#include "BdTBoardData.h"
#include "SiTSio.h"

static unsigned char i=0;
static char estadoPWM[3];
static char timerPWM[3];
static unsigned char vuelta[3];
static char id[3];

static const char idAtiempo[] = {
    2,4,6,8,10,12,14,16,18,20
};


void PwInit(){
    INIT_PWM0_OUT();
    INIT_PWM1_OUT();
    INIT_PWM2_OUT();    
    LATA_PWM0_RA2();
    LATA_PWM1_RB10();
    LATA_PWM2_RB11();
    

    for (i=0; i<3; i++){
        estadoPWM[i]=0;
        timerPWM[i]=TiGetTimer();
        vuelta[i]=0;    
        id[i]=0;
        TiResetTics(timerPWM[i]);
    }
   
    
}

void MotorPWM(char pwm){
    switch(estadoPWM[pwm]){
        case 0:
            BdGetIdentifier(id);
            if(TiGetTics(timerPWM[pwm]) >= idAtiempo[vuelta[pwm]]){
                TiResetTics(timerPWM[pwm]);
                setValor(pwm,0);
                estadoPWM[pwm]=1;
            }
            break;
        case 1:
            if (TiGetTics(timerPWM[pwm]) >= 20-idAtiempo[vuelta[pwm]]){
                TiResetTics(timerPWM[pwm]);
                setValor(pwm,1);
                estadoPWM[pwm]=2;
            }
            
            
            break;
        case 2:
            if( BdHasIdentifier()!=1 ){
                vuelta[pwm]++;
                if (vuelta[pwm]>=10){
                    vuelta[pwm] = 0;
                }                
            } else if( (vuelta[pwm]+48)!= id[pwm] ){
                vuelta[pwm]++;
                if (vuelta[pwm]>=10){ vuelta[pwm]=0; }  
            }
            
            estadoPWM[pwm]=0;
            break;
    }
}

void setValor(char pwm, char valor){
    switch(pwm){
        case 0:
            LATAbits.LATA2 = valor;
            break;
        case 1:
            LATBbits.LATB10 = valor;
            break;
        case 2:
            LATBbits.LATB11 = valor;
            break;
    }
}








