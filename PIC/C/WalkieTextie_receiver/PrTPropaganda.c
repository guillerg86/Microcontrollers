#include "PrTPropaganda.h"
/*
 *  GUILLE: Refactorizamos totalmente el motorLCD y comentamos todo el motor propaganda para quitar lo que no nos interesa
 */


#define MAXCOLUMNES 16
#define PADDING 16
static char estatLCD = 0;
const unsigned char waittingForID[]=    {" WAITTING FOR ID"}; // Més val que tingui 16 caràcters...
const unsigned char newMessage[] =      {"  NEW  MESSAGE  "};
static unsigned char timerLCD, caracterInici;
static unsigned int mostra;
static int conversion;
static char segonaLinia[MAXCOLUMNES];
static char missatges_identificats[3];
static char missatges_totals[3];
static char id[3];
static unsigned int string_char_index, columna;
static unsigned char padding_char_index;

void initMotorLCD(void){
    //Pre: El LCD està inicialitzat
    timerLCD = TiGetTimer();
    caracterInici = 0;      
    string_char_index = 0;
    padding_char_index= 0;

    LcClear();
    
    // Limpiamos los buffers
    for ( columna = 0; columna < MAXCOLUMNES; columna++) {
        segonaLinia[columna] = ' ';
    }
    
    // SEGONALINIA
    // Los valores que no cambian hasta tener identificador 
    segonaLinia[0] = segonaLinia[1] = segonaLinia[2] = 'X';
    segonaLinia[4] = segonaLinia[5] = segonaLinia[6] = '0';
    
    // y los que no cambian nunca
    segonaLinia[3]  ='/';
    segonaLinia[10] ='I';
    segonaLinia[11] ='D';
    segonaLinia[12] =':';
    segonaLinia[13] = segonaLinia[14] = segonaLinia[15] = '0';
    // Comentar si no les gusta en la entrega
    LcGotoXY(0,3);
    LcPutString("LS26151  LS27094");
    LcGotoXY(0,0);
}
void LcNewMessage(void) {
    estatLCD = 96;
}
void LcReceivingMessage(void) {
    
}
void MotorLCD(void){
    switch (estatLCD) {
        case 0:
            // Seleccionamos la rama por la que hemos de irnos
            if ( BdHasIdentifier() == 1 ) {
                estatLCD = 10;     // Lo enviamos por la rama de no tiene identificador
            } else {
                estatLCD = 1;
            }
            columna = 0;
            break;
        /*  CAMINO SIN IDENTIFICADOR - INICIO */            
        case 1:
            // Pintamos el caracter de la frase que hay en la posicion que nos indica el indice / puntero
            LcPutChar(waittingForID[string_char_index++]);
            // Si supera el string de la frase (estamos en NO IDENTIFICADO!), reseteamos a 0
            if ( string_char_index>=16 ) { string_char_index = 0; }  
            columna++;
            // Incrementamos la columna antes de comparar!! no despues! porque sobreescribimos 2 caracteres de la otra linea
            // en la version LCD que se nos dio, al encima hacer la comparacion contador > MAX_VALUE e incrementar despues de
            // comparar, provoca la sobreescritura de 2 caracteres de la segunda linea.
            // Solucion, incrementar antes de comparar y comparar con >= no solo con > 
            // Y comparamos que tambien sea igual!
            if (columna >= MAXCOLUMNES) {
                estatLCD = 2;
                TiResetTics(timerLCD);
                LcGotoXY(0,2);
            }
            break;
        case 2:
            BdGetTotalFrames(missatges_totals);
            estatLCD = 3;
            break;
        case 3:
            segonaLinia[4] = missatges_totals[0];
            segonaLinia[5] = missatges_totals[1];
            segonaLinia[6] = missatges_totals[2];
            estatLCD = 4;
            break;
        case 4:
            if ( ++segonaLinia[13] >= '9'+1 ) { segonaLinia[13] = '0'; } 
            if ( ++segonaLinia[14] >= '9'+1 ) { segonaLinia[14] = '0'; }
            if ( ++segonaLinia[15] >= '9'+1 ) { segonaLinia[15] = '0'; }
            estatLCD = 5;
            break;
        case 5:
            mostra = AdGetMostra();         
            estatLCD = 6;
            break;
        case 6:
            conversion=CoGetConversion(mostra);
            estatLCD = 7;
            break;
        case 7:
            if (TiGetTics(timerLCD)>50){
                TiResetTics(timerLCD);
                columna = 0;
                estatLCD = 8;
            }
            break;
        case 8:
            // Mismo problema que en el estado 1
            LcPutChar(segonaLinia[columna]);
            columna++;
            if (columna >= MAXCOLUMNES) {
                estatLCD = 9;
                TiResetTics(timerLCD);
            }
            break;
        case 9:
            if (TiGetTics(timerLCD)>= conversion){
                //Alerta, ja porto 50 ms. des de l'últim refresc
                //caracterInici++;
                //if (caracterInici==16) { caracterInici=0; }
                LcGotoXY(0,0);
                //string_char_index = caracterInici;
                string_char_index = 0;
                columna = 0;
                estatLCD = 0;
            }
            break;
        /*  CAMINO SIN IDENTIFICADOR - FIN */ 
            
        /*  CAMINO CON IDENTIFICADOR - INICIO */    
        case 10:
            // Nuestra case 0 para la rama identificada
            BdGetIdentifier(id);
            estatLCD = 11;
            break;    
        case 11:
            BdGetIdentifiedFrames(missatges_identificats);
            estatLCD = 12;
            break;
        case 12:
            BdGetTotalFrames(missatges_totals);
            columna = 0;
            estatLCD = 13;
            break;
        case 13:    
            segonaLinia[0] = missatges_identificats[0];
            segonaLinia[1] = missatges_identificats[1];
            segonaLinia[2] = missatges_identificats[2];
            estatLCD = 14;
            break;
        case 14:
            segonaLinia[4] = missatges_totals[0];
            segonaLinia[5] = missatges_totals[1];
            segonaLinia[6] = missatges_totals[2];
            LcGotoXY(0,2);
            estatLCD = 15;
            break;
        case 15:    
            if ( id[0] != segonaLinia[13] ) {
                if ( ++segonaLinia[13] >= ('9'+1) ) { segonaLinia[13] = '0'; }
            }
            if ( id[1] != segonaLinia[14] ) {
                if ( ++segonaLinia[14] >= ('9'+1) ) { segonaLinia[14] = '0'; }
            }
            if ( id[2] != segonaLinia[15] ) {
                if ( ++segonaLinia[15] >= ('9'+1) ) { segonaLinia[15] = '0'; }
            }
            estatLCD = 16;
            break;
        case 16:
            LcPutChar(segonaLinia[columna]);
            columna++;
            if (columna >= MAXCOLUMNES) {
                TiResetTics(timerLCD);
                columna = 0;
                estatLCD = 17;
            }
            break;
        case 17:
            if (TiGetTics(timerLCD)>50){
                TiResetTics(timerLCD);
                LcGotoXY(0,0);
                estatLCD = 18;
            }
            break;
        case 18:
            mostra = AdGetMostra();
            estatLCD = 19;
            break;
        case 19:
            conversion=CoGetConversion(mostra);
            estatLCD = 20;
            break;
        case 20:
            // Pintamos el mensaje
            if ( padding_char_index < PADDING ) {
                padding_char_index++;
                LcPutChar(' ');
            } else if ( string_char_index < BdGetLastMessageSize() ) {
                LcPutChar( BdGetMessageCharacter(string_char_index) );
                string_char_index++;
            } else {
                LcPutChar(' ');
                padding_char_index = 1;     // Volvemos a comenzar poniendo el ptr a 0
                string_char_index = 0;      // Volvemos a comenzar poniendo el ptr a 0
            }
            
            if (++columna >= MAXCOLUMNES ) {
                estatLCD = 21;
            }
            
            break;
        case 21:    

            if (TiGetTics(timerLCD) >= conversion){       
                caracterInici++;

                if ( caracterInici < PADDING ) {
                    padding_char_index = caracterInici;
                    string_char_index = 0;
                } else if ( (caracterInici - PADDING) < BdGetLastMessageSize() ) {
                    string_char_index = (caracterInici - PADDING);
                    padding_char_index = PADDING;   // El motivo es que se ha podido resetear a 0 haciendo que el
                                                    // LCD no funcione correctamente cuando llegamos al final
                                                    // de la frase recibida
                } else {
                    caracterInici = 0;
                    padding_char_index = 0;
                    string_char_index = 0;
                }
                estatLCD = 0;  
                columna = 0;
            }
            break;            
 
        /*  CAMINO CON IDENTIFICADOR - FIN */  
            
            
        /*  CAMINO DE LIMPIEZA Y ESPERA DE FINALIZACION DE RECEPCION DE NUEVA FRASE */    
        case 96:
            columna = 0;
            LcGotoXY(0,0);
            TiResetTics(timerLCD);
            estatLCD = 97;
            break;
        case 97:
            LcPutChar(newMessage[columna]);
            if ( ++columna >= MAXCOLUMNES ) {
                columna = 0;
                caracterInici = 0;
                estatLCD = 98;
            }
            break;
        case 98:
            if ( TiGetTics(timerLCD) >= 5000) {
                padding_char_index = 0;
                string_char_index = 0;
                estatLCD = 10;
            }
            break;
        
        // EVITAR BLOQUEO!    
        default:
            estatLCD = 0;
            break;
    }
}
