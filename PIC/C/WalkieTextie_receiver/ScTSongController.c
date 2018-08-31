/*
 * File:   ScTSongController.c
 * Author: grodriguez
 *
 * Created on April 26, 2017, 4:01 PM
 */

#include "ScTSongController.h"
#include "SiTSio.h"

static unsigned char estadoSController;
static unsigned char timerSController;
static unsigned char song_step_index;
const unsigned char song_steps[SONG_MAX_STEPS] ={   
                                                    1,1,1,0,0,
                                                    0,0,0,1,1,
                                                    0,0,1,1,0,
                                                    0,0,1,1,0,
                                                    0,0,1,1,1
                                                };

//static char aux[] = {'\0','\0','\0','\0','\0','\0','\0','\0','\0','\0'};
static char periodo = 0;
static unsigned int sizem;

void ScInit(void) {
    estadoSController = 0;
    timerSController = TiGetTimer();    
}
void ScStartSong(void) {
    // Precondicion:    ---
    // Postcondicion:   Hace salir al motor del estado 0 provocando el inicio de la cancion  
    estadoSController = 1;
}
void MotorSongController(void) {
    switch (estadoSController) {
        case 0:
            // Estamos a la espera de que nos indiquen desde fuera que cantemos
            disableAudio();
            break;
        case 1:
            sizem = BdGetLastMessageSize();
            /*
            sprintf(aux,"%d\n",sizem);
            aux[5] = '\0';
            SiPuts("Size_message: ");
            SiPuts(aux);
            */
            estadoSController = 2;
            break;
        case 2:
            periodo = CoGetPeriode(sizem);
            estadoSController = 3;
            break;
        case 3:
            // Arreglamos el "fallo" de que para mensaje corto 
            periodo = 21 - periodo;
            estadoSController = 4;
            break;
        case 4: // DEBUG
            setAudioPeriode(periodo);
            /*
            sprintf(aux,"%d\n",periodo);
            aux[5] = '\0';
            SiPuts("Periodo: ");
            SiPuts(aux);
            */
            estadoSController = 5;
            break;
        case 5:
            TiResetTics(timerSController);
            song_step_index = 0;
            estadoSController = 6;
            break;
            
        case 6:
            if ( song_step_index < SONG_MAX_STEPS ) {
                estadoSController = 7;
                enableAudio();
            } else {
                estadoSController = 0;
                disableAudio();
            }
            break;
        case 7:
            if ( TiGetTics(timerSController) >= SONG_STEP_TIME_MS ) {
                TiResetTics(timerSController);
                estadoSController = 6;
                if ( song_steps[song_step_index] == 1 ) {
                    if ( periodo < 21 ) {
                        setAudioPeriode(++periodo);
                    }
                    //enableAudio();
                } else {
                    if ( periodo > 1) {
                        setAudioPeriode(--periodo);
                    }
                    //disableAudio();
                }  
                song_step_index++;
                //SiPuts("Valor del song_step_index: ");
                //sprintf(aux,"%d\n",song_step_index);
                //SiPuts(aux);
            }
            break;
        default:
            //SiPuts("SongController DEFAULT\n");
            estadoSController = 0;
            break;
    }
}