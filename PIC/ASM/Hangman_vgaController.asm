#define TIMER0H_LOAD_VALUE 0xFE
#define TIMER0L_LOAD_VALUE 0xBD
#define COLOR_WHITE 0x07
#define	COLOR_BLACK 0x00
#define COLOR_RED   0x01
#define COLOR_GREEN 0x02  
#define	COLOR_GROUP 0x03
#define INITIAL_ERRORS 0x08
    
    LIST P=18F4321, F=INHX32
    #include <p18f4321.inc>
    
;-------------------------------------------------------------------------------
;   CONFIGURACIONES DEL MICROCONTROLADOR
;-------------------------------------------------------------------------------
    CONFIG OSC = HSPLL		; Configuramos la velocidad del clock
    CONFIG WDT = OFF		; Watch dog timer --> OFF no queremos que nos reinicie la placa
    CONFIG PBADEN = DIG		; Configuramos el PORTB como digital
;-------------------------------------------------------------------------------
;   VARIABLES
;-------------------------------------------------------------------------------
BOOL_ZONA_ACTIVA    EQU	0x0000
NLINEA_ACTH	    EQU 0x0001	; Variable que usaremos para saber el numero de linea en el que estamos
NLINEA_ACTL	    EQU 0x0002	;
NUM_ERRORES	    EQU 0x0003	; Variable para obtener el numero de errores
COLOR_A_PINTAR	    EQU	0x0004	; Variable donde cargaremos el color a pinta
ZONAS_A_PINTAR	    EQU	0x0005
AUX		    EQU 0x0006
;-------------------------------------------------------------------------------
;   DIRECCIONES PRINCIPALES
;-------------------------------------------------------------------------------
    ORG 0x0000
    GOTO    SETUP
    ORG 0x0008			; Definimos la RSI para las HIGH IRQ
    GOTO    RSI_HIGH
    ORG 0x0018			; Definimos la RSI para las LOW IRQ aunque no las usaremos porque las desactivaremos
    GOTO    RSI_LOW	   
;-------------------------------------------------------------------------------
;   CONFIGURACION INICIAL
;-------------------------------------------------------------------------------
SETUP
    CALL    CONF_TIMER0
    CALL    CONF_VARS
    CALL    CONF_PORTS
    CALL    CONF_INTERRUPTS
    CLRF    LATA,0		; Ponemos a color negro el RGB inicialmente
    CLRF    ZONAS_A_PINTAR,0
    MOVLW   COLOR_WHITE
    MOVWF   COLOR_A_PINTAR
    MOVLW   INITIAL_ERRORS
    MOVWF   NUM_ERRORES,0
    GOTO    MAIN;

CONF_INTERRUPTS
    BCF	    RCON, IPEN, 0	; Desactivamos prioridades en las interrupciones
    MOVLW   b'10100000'		; Configuramos para el INTCON el GIE = 1, TMR0IE = 1, todo lo demas a 0
    MOVWF   INTCON, 0		; Lo escribimos
    RETURN

CONF_VARS
    CLRF    NUM_ERRORES	, 0 	; Cuando encienda el programa, limpiamos el valor de la variable
	; INDICAMOS UNA LINEA ACTUAL = EJ 523
    MOVLW   HIGH(.523)		
    MOVWF   NLINEA_ACTH , 0	
    MOVLW   LOW(.523)
    MOVWF   NLINEA_ACTL	, 0	
    ; CONFIGURAMOS TIMER0
    MOVLW   TIMER0H_LOAD_VALUE	
    MOVWF   TMR0H, 0	
    MOVLW   TIMER0L_LOAD_VALUE		
    MOVWF   TMR0L, 0	
    
    RETURN
    
CONF_TIMER0   
    MOVLW   b'10011000'		; Activamos TIMER0, config 16bits, clock interno, clock de bajada, prescaler off, prescaler conf 0
    MOVWF   T0CON, 0
    RETURN
    
CONF_PORTS
    BCF	    TRISA, RA0, 0	; Configuramos el puerto RA0 como output --> RED
    BCF	    TRISA, RA1, 0	; Configuramos el puerto RA1 como output --> GREEN
    BCF	    TRISA, RA2, 0	; Configuramos el puerto RA2 como output --> BLUE
    BCF	    TRISE, RE0, 0	; Configuramos el puerto RE0 como output --> Hsync
    BCF	    TRISE, RE1, 0	; Configuramos el puerto RE1 como output --> Vsync
    BSF	    TRISB, RB0,	0	; Configuramos como input los bits [3..0] del RB para el contador errores
    BSF	    TRISB, RB1, 0
    BSF	    TRISB, RB2, 0
    BSF	    TRISB, RB3, 0
    BSF	    TRISB, RB4, 0	; Configuramos como input para el WIN
    BSF	    TRISD, RD0, 0	; Configuramos como input para el GAMEOVER
    RETURN 
;-------------------------------------------------------------------------------
;   RUTINA DE SERVICIO DE INTERRUPCIONES
;-------------------------------------------------------------------------------    
RSI_LOW				; No la hacemos servir, tan solo tenemos INTERRUPCIONES HIGH
    RETFIE  FAST   
    
RSI_HIGH			; 00 INSTR
    BSF     LATE, RE0, 0	; +1 INSTR --> 01 INSTR - ACTIVAMOS HSYNC
    BCF	    INTCON, TMR0IF, 0	; +1 INSTR --> 02 INSTR - BAJAMOS FLAG INTERRUPCION
	; RECONFIGURAMOS TIMER	
    MOVLW   TIMER0H_LOAD_VALUE	; +1 INSTR --> 03 INSTR 
    MOVWF   TMR0H	, 0	; +1 INSTR --> 04 INSTR
    MOVLW   TIMER0L_LOAD_VALUE	; +1 INSTR --> 05 INSTR
    MOVWF   TMR0L	, 0	; +1 INSTR --> 06 INSTR
	; COMPROBAMOS SI HEMOS DE SUBIR/BAJAR VSYNC
    MOVLW   0x00		; +1 INSTR --> 07 INSTR 
    CPFSEQ  NLINEA_ACTH, 0	; +1 INSTR --> 08 INSTR 
    GOTO    VSYNCOFF_SALTA_ALTA ; +2 INSTR --> 10 INSTR - GOTO DESACTIVA VSYNC
    MOVLW   0x02		; +1 INSTR --> 09 INSTR
    CPFSLT  NLINEA_ACTL, 0	; +1 INSTR --> 10 INSTR
    GOTO    VSYNCOFF_SALTA_BAJA	; +2 INSTR --> 12 INSTR - GOTO DESACTIVA VSYNC
    BSF	    LATE, RE1, 0	; +1 INSTR --> 11 INSTR - ACTIVAMOS VSYNC   
    NOP
    NOP
    
ESPERA_FIN_HSYNC		; LLEGAMOS CON 15 INSTR (DESDE CUALQUIER RAMA)
    CLRF    LATA, 0		; +1 INSTR --> 16 INSTR	- DESACTIVAMOS RGB

    CALL    ESPERA_16CICLOS	; +16 INSTR--> 32 INSTR
    CALL    ESPERA_4CICLOS	; +4 INSTR --> 36 INSTR
    BCF	    LATE, RE0, 0	; +1 INSTR --> 38 INSTR - DESACTIVAMOS HSYNC --> 96PIX (HSYNC) / 2.5 == 38.4 INSTR
	; INCREMENTAMOS LA LINEA ACTUAL 
    INFSNZ  NLINEA_ACTL, 1, 0	; +1 INSTR --> 39 INSTR - INCREMENTAMOS LINEA ACTUAL LOW
    GOTO    SI_INCREMENTA_LINACTH;+2 INSTR --> 41 INSTR - INCREMENTAMOS LINEA ACTUAL HIGH SI LOW HA HECHO OVERFLOW
    NOP				; +1 INSTR --> 40 INSTR
    GOTO    NO_INCREMENTA_LINACTH;+2 INSTR --> 42 INSTR - NO INCREMENTAMOS HIGH, LOW NO HA HECHO OVERFLOW

SI_INCREMENTA_LINACTH		; LLEGAMOS CON 41 INSTR
    INCF    NLINEA_ACTH, 1, 0	; +1 INSTR --> 42 INSTR
NO_INCREMENTA_LINACTH		; LLEGAMOS CON 42 INSTR
	; COMPROBAMOS SI TENEMOS QUE RESETEAR EL CONTADOR
    MOVLW   HIGH(.524)		; +1 INSTR --> 43 INSTR
    CPFSEQ  NLINEA_ACTH, 0	; +1 INSTR --> 44 INSTR
    GOTO    NORESET_CONTLINEA_ALTA;+1 INSTR -> 46 INSTR
    MOVLW   LOW(.524)		; +1 INSTR --> 45 INSTR
    CPFSEQ  NLINEA_ACTL, 0	; +1 INSTR --> 46 INSTR 
    GOTO    NORESET_CONTLINEA_BAJA;+1 INSTR -> 48 INSTR
	; RESETEAMOS EL CONTADOR
    CLRF    NLINEA_ACTH, 0	; +1 INSTR --> 47 INSTR
    CLRF    NLINEA_ACTL, 0	; +1 INSTR --> 48 INSTR
    NOP				; +1 INSTR --> 49 INSTR
    NOP				; +1 INSTR --> 50 INSTR
SALIR_RSI			; LLEGAMOS CON 50 INSTR - PARA FIN DE LOS PORTICOS HORIZONTALES , FALTAN 7,6 INSTR
    CALL    ESPERA_4CICLOS	; +4 INSTR --> 54 INSTR
    RETFIE  FAST		; +2 INSTR --> 59 INSTR - Faltarian 0.6 instr para ajustarlo perfectamente
    
;-------------------------------------------------------------------------------
;   RAMA DE NO-RESETEO DE LINEA
;------------------------------------------------------------------------------- 
NORESET_CONTLINEA_ALTA		; LLEGAMOS CON 46 INSTR	
    NOP				; +1 INSTR --> 47 INSTR
    NOP				; +1 INSTR --> 48 INSTR
NORESET_CONTLINEA_BAJA		; LLEGAMOS CON 48 INSTR
    GOTO    SALIR_RSI		; +2 INSTR --> 50 INSTR

;-------------------------------------------------------------------------------
;   RAMA DE DESACTIVACION VSYNC
;-------------------------------------------------------------------------------     
VSYNCOFF_SALTA_ALTA		; LLEGAMOS CON 10 INSTR
    NOP				; +1 INSTR --> 10 INSTR
    NOP				; +1 INSTR --> 11 INSTR
    NOP				; +1 INSTR --> 12 INSTR --> ESTA YA DEBERIA SER ETIQUETA LA VSYNCOFF_SALTA_BAJA!
    NOP				; +1 ISNTR --> 13 INSTR 
VSYNCOFF_SALTA_BAJA		; LLEGAMOS CON 11 INSTR
    BCF	    LATE, RE1, 0	; +1 INSTR --> 12 INSTR	--> BAJAMOS VSYNC
    GOTO    ESPERA_FIN_HSYNC	; +2 INSTR --> 14 INSTR     
    
;-------------------------------------------------------------------------------
;   FUNCIONES DE COMPROBACION DE ZONA ACTIVA
;-------------------------------------------------------------------------------     
COMPROVA_ZONA_ACTIVA			; +2 INSTR --> 02 INSTR - DEBIDO A QUE ENTRAMOS SI O SI CON UN CALL
	; CONTROLAMOS EL CASO DEL QUE EL HIGH TENGA 0x01
    MOVLW   0x01			; +1 INSTR --> 03 INSTR
    SUBWF   NLINEA_ACTH, 0, 0		; +1 INSTR --> 04 INSTR
    BTFSC   STATUS , Z, 0		; +1 INSTR --> 05 INSTR - Si resta ha dado cero -> bit Z de status = 1 | Entonces si bit Z@status == 0 --> SALTA, NO ES 0x01!
    GOTO    ZONA_ACTIVA_SIGUE_ACTIVA	; +2 INSTR --> 07 INSTR - Estamos en zona activa SEGURO! 255 < LINEA_ACTUAL < 512
	; COMPROBAMOS SI EL HIGH DE LINEA ACTUAL ES 0
    MOVLW   0x00			; +1 INSTR --> 06 INSTR
    CPFSEQ  NLINEA_ACTH, 0		; +1 INSTR --> 07 INSTR
    GOTO    DESACTIVA_ZONA_ACTIVA_1	; +2 INSTR --> 09 INSTR - SI NO ES 0x00, TIENE QUE SER 0x02 --> ESTAMOS EN 512 (podemos pasar de pintar ...)
	; DADO QUE ESTAMOS EN HIGH = 0 --> COMPROBAMOS SI ESTAMOS EN LINEA MAYOR A 35 (PORTICOS VERTICALES)
    MOVLW   0X35			; +1 INSTR --> 08 INSTR
    CPFSGT  NLINEA_ACTL, 0		; +1 INSTR --> 09 INSTR
    GOTO    DESACTIVA_ZONA_ACTIVA_2	; +2 INSTR --> 11 INSTR
	; MANTENEMOS LA ZONA ACTIVA COMO ACTIVA (AL SALIR DE RSI ZACT == 1)
    NOP					; 11 instr
    RETURN				; 13 instr
  
DESACTIVA_ZONA_ACTIVA_1			; LLEGAMOS CON 09 INSTR
    NOP					; +1 INSTR --> 10 INSTR
    NOP					; +1 INSTR --> 11 INSTR
DESACTIVA_ZONA_ACTIVA_2			; LLEGAMOS CON 11 INSTR
    BCF	    BOOL_ZONA_ACTIVA, 0 ,0	; +1 INSTR --> 12 INSTR
    RETURN				; +2 INSTR --> 14 INSTR
    
ZONA_ACTIVA_SIGUE_ACTIVA		; LLEGAMOS CON 07 INSTR
    CALL    ESPERA_4CICLOS		; +4 INSTR --> 11 INSTR
    NOP					; +1 INSTR --> 12 INSTR
    RETURN				; +2 INSTR --> 14 INSTR
    
;-------------------------------------------------------------------------------
;   ETIQUETAS DE ESPERA
;------------------------------------------------------------------------------- 
ESPERA_4CICLOS
    RETURN
ESPERA_8CICLOS
    CALL ESPERA_4CICLOS
    RETURN
ESPERA_12CICLOS
    CALL ESPERA_8CICLOS
    RETURN
ESPERA_16CICLOS
    CALL ESPERA_12CICLOS
    RETURN
ESPERA_36CICLOS
    CALL    ESPERA_16CICLOS
    CALL    ESPERA_16CICLOS
    RETURN  
    
;-------------------------------------------------------------------------------
;   FUNCIONES DE PINTADO
;-------------------------------------------------------------------------------  
PINTA_ZONA_4
    MOVLW   LOW(.4)
    CPFSLT  NUM_ERRORES,0
    GOTO    PINTA
    GOTO    NOPINTES
PINTA_ZONA_3
    MOVLW   LOW(.3)
    CPFSLT  NUM_ERRORES,0
    GOTO    PINTA
    GOTO    NOPINTES
PINTA_ZONA_2
    MOVLW   LOW(.2)
    CPFSLT  NUM_ERRORES,0
    GOTO    PINTA
    GOTO    NOPINTES
PINTA_ZONA_1
    MOVLW   LOW(.1)
    CPFSLT  NUM_ERRORES,0
    GOTO    PINTA
    GOTO    NOPINTES
PINTA_ZONA
    CPFSLT  NUM_ERRORES,0
    GOTO    PINTA
    GOTO    NOPINTES
PINTA
    MOVFF   COLOR_A_PINTAR,LATA
    RETURN
NOPINTES
    RETURN

;-------------------------------------------------------------------------------
;   PROGRAMA PRINCIPAL
;-------------------------------------------------------------------------------      
MAIN				    ; CONSIDERAMOS 00 PARA EL MAIN (PERO REALMENTE LLEVAMOS 59)
    CLRF    LATA,0
    CLRF    ZONAS_A_PINTAR,0
    NOP
    
ESPERA_LINEA_50
    MOVLW   LOW(.50)
    CPFSEQ  NLINEA_ACTL,0
    GOTO    ESPERA_LINEA_50  
    
    
ESPERA_LINEA_66			    ; BLOQUE DE PINTAR LA 1A LINEA HORIZONTAL
    CALL    ESPERA_16CICLOS
    CALL    ESPERA_16CICLOS
    NOP
    MOVLW   LOW(.2)
    CALL    PINTA_ZONA_2
    NOP
    NOP
    CALL    ESPERA_36CICLOS
    CALL    ESPERA_36CICLOS
    CALL    ESPERA_36CICLOS
    CALL    ESPERA_36CICLOS
    CLRF    LATA,0		    ; Aunque no estemos pintando apagamos el 
    CALL    ESPERA_36CICLOS
    CALL    ESPERA_36CICLOS
    CALL    ESPERA_4CICLOS
    NOP
    MOVLW   LOW(.66)
    CPFSEQ  NLINEA_ACTL,0
    GOTO    ESPERA_LINEA_66

ESPERA_LINEA_90			    ; BLOQUE DE PINTAR LA BARRA Y LA CUERDA
    CALL    ESPERA_16CICLOS
    CALL    ESPERA_16CICLOS
    
    NOP
    NOP
    CALL    PINTA_ZONA_1

    NOP
    NOP
    NOP
    NOP
    CLRF    LATA,0
    NOP
    CALL    ESPERA_36CICLOS
    CALL    ESPERA_36CICLOS
    CALL    ESPERA_36CICLOS		
    CALL    ESPERA_8CICLOS
    NOP
    NOP
    NOP
    NOP
    CALL    PINTA_ZONA_3
    CALL    ESPERA_4CICLOS
    CLRF    LATA,0
    CALL    ESPERA_4CICLOS
    CALL    ESPERA_36CICLOS
    CALL    ESPERA_36CICLOS
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    MOVLW   LOW(.90)
    CPFSEQ  NLINEA_ACTL,0
    GOTO    ESPERA_LINEA_90
    
  
ESPERA_LINEA_130		    ; BLOQUE DE PINTAR LA BARRA Y CABEZA
    CALL    ESPERA_16CICLOS
    CALL    ESPERA_16CICLOS
    NOP
    NOP

    CALL    PINTA_ZONA_1
    NOP
    NOP
    NOP
    NOP
    CLRF    LATA,0
    NOP

    CALL    ESPERA_36CICLOS
    CALL    ESPERA_36CICLOS
    CALL    ESPERA_36CICLOS
    NOP
    NOP
    NOP
    NOP

    CALL    PINTA_ZONA_4
    CALL    ESPERA_16CICLOS
    NOP
    NOP
    NOP
    CLRF    LATA,0
    CALL    ESPERA_36CICLOS
    CALL    ESPERA_36CICLOS

    CALL    ESPERA_4CICLOS
    MOVLW   LOW(.130)
    CPFSEQ  NLINEA_ACTL,0
    GOTO    ESPERA_LINEA_130

ESPERA_LINEA_150  
    CALL    ESPERA_16CICLOS
    CALL    ESPERA_16CICLOS
    NOP
    NOP


    CALL    PINTA_ZONA_1
    CALL    ESPERA_4CICLOS

    CLRF    LATA,0
    NOP
    NOP
    NOP
    CALL    ESPERA_36CICLOS
    CALL    ESPERA_36CICLOS
    CALL    ESPERA_36CICLOS		
    CALL    ESPERA_4CICLOS
    NOP
    NOP
    NOP
    MOVLW   LOW(.5)
    CALL    PINTA_ZONA
    CALL    ESPERA_8CICLOS
    NOP
    NOP
    CLRF    LATA,0
    CALL    ESPERA_36CICLOS
    CALL    ESPERA_36CICLOS
    NOP
    NOP
    NOP
    NOP
    CALL    ESPERA_4CICLOS
    MOVLW   LOW(.150)
    CPFSEQ  NLINEA_ACTL,0
    GOTO    ESPERA_LINEA_150
	
ESPERA_LINEA_170			; BLOQUE DE PINTAR LA BARRA Y CUERPO + BRAZOS
    CALL    ESPERA_16CICLOS
    CALL    ESPERA_16CICLOS
    NOP
    NOP
    MOVLW   LOW(.1)
    CALL    PINTA_ZONA
    NOP
    NOP
    NOP
    NOP

    CLRF    LATA,0
    NOP
    NOP

    CALL    ESPERA_36CICLOS
    CALL    ESPERA_16CICLOS
    CALL    ESPERA_16CICLOS
    CALL    ESPERA_4CICLOS
    CALL    ESPERA_16CICLOS
    NOP
    NOP
    MOVLW   LOW(.5)
    CALL    PINTA_ZONA
    CALL    ESPERA_8CICLOS
    CALL    ESPERA_16CICLOS
    NOP
    NOP
    CALL    ESPERA_36CICLOS
    CLRF    LATA,0
    CALL    ESPERA_36CICLOS
    CALL    ESPERA_12CICLOS
    CALL    ESPERA_4CICLOS
    NOP
    NOP

    MOVLW   LOW(.170)
    CPFSEQ  NLINEA_ACTL,0
    GOTO    ESPERA_LINEA_170
    
ESPERA_LINEA_256			; BLOQUE DE PINTAR LA BARRA 
    CALL    ESPERA_16CICLOS
    CALL    ESPERA_16CICLOS
    NOP
    NOP	    
    CALL    PINTA_ZONA_1
    CALL    ESPERA_4CICLOS

    CLRF    LATA,0
    NOP
    NOP
    NOP
    CALL    ESPERA_36CICLOS
    CALL    ESPERA_36CICLOS
    CALL    ESPERA_36CICLOS		
    CALL    ESPERA_4CICLOS
    NOP
    NOP
    NOP
    MOVLW   LOW(.6)
    CALL    PINTA_ZONA
    CALL    ESPERA_8CICLOS
    NOP
    NOP
    CLRF    LATA,0
    CALL    ESPERA_36CICLOS
    CALL    ESPERA_36CICLOS
    NOP
    NOP
    NOP
    NOP
    CALL    ESPERA_4CICLOS
    MOVLW   HIGH(.256)
    CPFSEQ  NLINEA_ACTH,0
    GOTO    ESPERA_LINEA_256

    NOP				; ARREGLAMOS EL DESFASE ENTRE PARTE ALTA Y PARTE BAJA
    CALL    ESPERA_8CICLOS
    
ESPERA_LINEA_272			; BLOQUE DE PINTAR PIERNAS
    CALL    ESPERA_16CICLOS
    CALL    ESPERA_8CICLOS
    NOP
    NOP
    NOP
    MOVLW   LOW(.1)
    CALL    PINTA_ZONA
    NOP
    NOP
    NOP
    NOP
    CLRF    LATA,0
    NOP
    NOP
    CALL    ESPERA_36CICLOS
    CALL    ESPERA_16CICLOS
    CALL    ESPERA_16CICLOS
    CALL    ESPERA_4CICLOS
    CALL    ESPERA_16CICLOS
    NOP

    MOVLW   LOW(.7)
    CALL    PINTA_ZONA
    CALL    ESPERA_8CICLOS
    CALL    ESPERA_16CICLOS
    NOP
    NOP
    CALL    ESPERA_36CICLOS
    CLRF    LATA,0
    CALL    ESPERA_36CICLOS
    CALL    ESPERA_12CICLOS
    CALL    ESPERA_4CICLOS
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    CALL    ESPERA_4CICLOS
    MOVLW   LOW(.272)
    CPFSEQ  NLINEA_ACTL,0
    GOTO    ESPERA_LINEA_272
    
ESPERA_LINEA_342			    ; BLOQUE DE PINTAR LA PIERNAS 2
    CALL    ESPERA_16CICLOS
    CALL    ESPERA_8CICLOS
    NOP
    NOP
    NOP
    MOVLW   LOW(.1)
    CALL    PINTA_ZONA
    NOP
    NOP
    NOP
    NOP
    CLRF    LATA,0
    NOP
    NOP
    CALL    ESPERA_36CICLOS
    CALL    ESPERA_16CICLOS
    CALL    ESPERA_16CICLOS
    CALL    ESPERA_4CICLOS
    CALL    ESPERA_16CICLOS
    NOP

    MOVLW   LOW(.8)
    CALL    PINTA_ZONA
    CALL    ESPERA_4CICLOS
    CLRF    LATA,0
    NOP
    CALL    ESPERA_16CICLOS
    CALL    ESPERA_16CICLOS
    CALL    ESPERA_8CICLOS
    NOP
    NOP
    MOVLW   LOW(.8)
    CALL    PINTA_ZONA
    CALL    ESPERA_4CICLOS
    CLRF    LATA,0
    CALL    ESPERA_36CICLOS
    CALL    ESPERA_16CICLOS
    
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    CALL    ESPERA_4CICLOS
    



   
    MOVLW   LOW(.342)
    CPFSEQ  NLINEA_ACTL,0
    GOTO    ESPERA_LINEA_342
    
   
    
ESPERA_LINEA_352			    ; BLOQUE DE PINTAR EL BARRA
    CALL    ESPERA_16CICLOS
    CALL    ESPERA_8CICLOS
    NOP
    NOP
    NOP
    MOVLW   LOW(.1)
    CALL    PINTA_ZONA
    CALL    ESPERA_4CICLOS
    CLRF    LATA,0

    CALL    ESPERA_36CICLOS
    CALL    ESPERA_36CICLOS
    CALL    ESPERA_36CICLOS
    CALL    ESPERA_36CICLOS
    CALL    ESPERA_36CICLOS
    CALL    ESPERA_36CICLOS


    CALL    ESPERA_4CICLOS
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    MOVLW   LOW(.352)
    CPFSEQ  NLINEA_ACTL,0
    GOTO    ESPERA_LINEA_352
    
ESPERA_LINEA_372
    CALL    ESPERA_12CICLOS

    NOP
    NOP
    NOP
    MOVLW   LOW(.1)
    CALL    PINTA_ZONA
    CALL    ESPERA_4CICLOS
    CALL    ESPERA_36CICLOS
    CLRF    LATA,0

    CALL    ESPERA_12CICLOS
    CALL    ESPERA_36CICLOS
    CALL    ESPERA_36CICLOS
    CALL    ESPERA_36CICLOS
    CALL    ESPERA_36CICLOS
    CALL    ESPERA_36CICLOS


    CALL    ESPERA_4CICLOS
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP

    MOVLW   LOW(.372)
    CPFSEQ  NLINEA_ACTL,0
    GOTO    ESPERA_LINEA_372
    
    NOP
    NOP
    NOP
;-------------------------------------------------------------------------------
;   ZONA DE LOS NUMEROS DE GRUPO
;-------------------------------------------------------------------------------      
ESPERA_LINEA_382

    CALL    ESPERA_36CICLOS
    CALL    ESPERA_36CICLOS
    CALL    ESPERA_36CICLOS
    CALL    ESPERA_16CICLOS
    CALL    ESPERA_16CICLOS
    CALL    ESPERA_16CICLOS
    MOVLW   COLOR_GROUP
    MOVWF   LATA,0
    
    CALL    ESPERA_16CICLOS
    CLRF    LATA,0
    NOP
    NOP   
    MOVLW   COLOR_GROUP
    MOVWF   LATA,0
    CALL    ESPERA_16CICLOS
    CALL    ESPERA_16CICLOS
    CLRF    LATA,0

    NOP
    NOP
    MOVLW   COLOR_GROUP
    MOVWF   LATA,0
    CALL    ESPERA_16CICLOS
    CALL    ESPERA_16CICLOS
    CLRF    LATA,0
    NOP
    NOP
    NOP
    CALL    ESPERA_16CICLOS
    
    MOVLW   LOW(.382)
    CPFSEQ  NLINEA_ACTL,0
    GOTO    ESPERA_LINEA_382

ESPERA_LINEA_422

    CALL    ESPERA_36CICLOS
    CALL    ESPERA_36CICLOS
    CALL    ESPERA_36CICLOS
    CALL    ESPERA_16CICLOS
    CALL    ESPERA_16CICLOS
    CALL    ESPERA_16CICLOS
    CALL    ESPERA_12CICLOS
    MOVLW   COLOR_GROUP
    MOVWF   LATA,0
    CALL    ESPERA_4CICLOS
    CLRF    LATA,0
    NOP
    NOP
    MOVLW   COLOR_GROUP
    MOVWF   LATA,0
    CALL    ESPERA_4CICLOS
    CLRF    LATA,0
    CALL    ESPERA_4CICLOS
    NOP
    CALL    ESPERA_16CICLOS
    MOVLW   COLOR_GROUP
    MOVWF   LATA,0
    CALL    ESPERA_4CICLOS
    CLRF    LATA,0
    NOP	 
    CALL    ESPERA_16CICLOS
    CALL    ESPERA_12CICLOS
    NOP

    MOVLW   COLOR_GROUP
    MOVWF   LATA,0
    CALL    ESPERA_4CICLOS
    CLRF    LATA,0

    CALL    ESPERA_16CICLOS
    CALL    ESPERA_4CICLOS
    MOVLW   LOW(.422)
    CPFSEQ  NLINEA_ACTL,0
    GOTO    ESPERA_LINEA_422

ESPERA_LINEA_432    
    CALL    ESPERA_36CICLOS
    CALL    ESPERA_36CICLOS
    CALL    ESPERA_36CICLOS
    CALL    ESPERA_16CICLOS
    CALL    ESPERA_16CICLOS
    CALL    ESPERA_12CICLOS
    CALL    ESPERA_16CICLOS

    MOVLW   COLOR_GROUP
    MOVWF   LATA,0
    CALL    ESPERA_4CICLOS
    CLRF    LATA,0

    NOP
    NOP   
    MOVLW   COLOR_GROUP
    MOVWF   LATA,0
    CALL    ESPERA_16CICLOS
    CALL    ESPERA_16CICLOS
    CLRF    LATA,0
    NOP
    NOP
    CALL    ESPERA_16CICLOS
    CALL    ESPERA_12CICLOS
    MOVLW   COLOR_GROUP
    MOVWF   LATA,0
    CALL    ESPERA_4CICLOS
    CLRF    LATA,0
    NOP
    NOP
    NOP
    CALL    ESPERA_16CICLOS

    MOVLW   LOW(.432)
    CPFSEQ  NLINEA_ACTL,0
    GOTO    ESPERA_LINEA_432
    
ESPERA_LINEA_473

    CALL    ESPERA_36CICLOS
    CALL    ESPERA_36CICLOS
    CALL    ESPERA_36CICLOS
    CALL    ESPERA_16CICLOS
    CALL    ESPERA_16CICLOS
    CALL    ESPERA_16CICLOS
    CALL    ESPERA_12CICLOS
    MOVLW   COLOR_GROUP
    MOVWF   LATA,0
    CALL    ESPERA_4CICLOS
    CLRF    LATA,0
    NOP
    NOP
    NOP   
    NOP   
    CALL    ESPERA_4CICLOS
    NOP    
    CALL    ESPERA_4CICLOS
    NOP
    CALL    ESPERA_16CICLOS
    MOVLW   COLOR_GROUP
    MOVWF   LATA,0
    CALL    ESPERA_4CICLOS
    CLRF    LATA,0
    NOP	 
    CALL    ESPERA_16CICLOS
    CALL    ESPERA_12CICLOS
    NOP

    MOVLW   COLOR_GROUP
    MOVWF   LATA,0
    CALL    ESPERA_4CICLOS
    CLRF    LATA,0

    CALL    ESPERA_16CICLOS
    CALL    ESPERA_4CICLOS
    MOVLW   LOW(.473)
    CPFSEQ  NLINEA_ACTL,0
    GOTO    ESPERA_LINEA_473

ESPERA_LINEA_475
    CALL    SELECCIONA_COLOR
    CALL    CARGA_NUM_ERRORES
    CALL    ESPERA_36CICLOS
    CALL    ESPERA_36CICLOS
    CALL    ESPERA_36CICLOS
    
    MOVLW   LOW(.475)
    CPFSEQ  NLINEA_ACTL,0
    GOTO    ESPERA_LINEA_475
    
ESPERA_LINEA_525
   
    MOVLW   LOW(.525)
    CPFSEQ  NLINEA_ACTL,0
    GOTO    ESPERA_LINEA_525
    
    GOTO MAIN

CARGA_NUM_ERRORES
    MOVLW   0x0F		; Como solo nos interesan los [3..0] bits del puerto, lo pasaremos por una and y lo limpiaremos
    ANDWF   PORTB,0		; para posteriormente cargarlo en la variable de numero de errores que se usa para saber el numero
    MOVWF   NUM_ERRORES		; de errores
    NOP
    RETURN
    
SELECCIONA_COLOR
    BTFSC   PORTD,RD0,0
    GOTO    ACTIVA_LOOSE
    BTFSC   PORTB,RB4,0
    GOTO    ACTIVA_WIN
    NOP
    NOP
    MOVLW   COLOR_WHITE
    MOVWF   COLOR_A_PINTAR,0
    RETURN
ACTIVA_LOOSE			    ; LLEGO CON 5
    MOVLW   COLOR_RED
    MOVWF   COLOR_A_PINTAR,0
    RETURN
ACTIVA_WIN			    ; LLEGO CON 6
    MOVLW   COLOR_GREEN
    MOVWF   COLOR_A_PINTAR,0
    RETURN  
;-------------------------------------------------------------------------------
;   FIN DEL PROGRAMA
;-------------------------------------------------------------------------------   
    END