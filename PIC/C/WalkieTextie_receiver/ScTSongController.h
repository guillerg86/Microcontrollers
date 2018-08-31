/* 
 * File:   
 * Author: 
 * Comments:
 * Revision history: 
 */
#ifndef SCTSONGCONTROLLER_H
#define	SCTSONGCONTROLLER_H

#include "AuTAudio.h"
#include "BdTBoardData.h"
#include "CoTConversion.h"
#include "time.h"


#define SONG_STEP_TIME_MS 100
#define SONG_MAX_STEPS 25


void ScInit(void);

void ScStartSong(void);
//Pre:--
//Post: Hace que suene la melodia

void MotorSongController(void);



#endif	

