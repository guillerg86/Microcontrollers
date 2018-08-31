    #define TIMER0H_LOAD_VALUE 0xFC	; Valores para cargar en el timer y provocar una interrupcion
    #define TIMER0L_LOAD_VALUE 0x17	; cada 1ms. Para el micro configurado a 4Mhz
    #define LEDS_TICKS_CHECKPOINT 0x42 
    
    ; --- FLAGS PARA COMUNICACION CON LA SIO! ---
    #define FLAG_END_TRANSMISSION   0x00;     // Flag que indica que se ha enviado el ultimo caracter de la string
    #define FLAG_UPLOAD_STRING	    0x01;     // Flag que indica que iniciamos la transmission de la frase PC --> PIC || PIC <-- PC
    #define FLAG_DOWNLOAD_STRING    0x02;     // Flag PC --> PIC (Devuelveme lo cargado en la memoria ram interna) (just for testing)
    #define FLAG_START_RFID_SEND    0x03;     // Flag PC --> PIC || PIC <-- PC Comienza a enviar por RFID
    #define FLAG_END_TASK	    0x04;     // Flag PIC --> PC , he finalizado la tarea (ya puedes reactivar los botones de la View)
    #define FLAG_UNLOCK_THREAD	    0x0A;
    #define FLAG_RESYNCRO	    0x05
    #define FLAG_RFID_END_TRANSMISION	0x06
    ; -------------------------------------------
    LIST P=18F4321, F=INHX32
    #include <p18f4321.inc>
    
;###############################################################################    
;-------------------------------------------------------------------------------
;   CONFIGURACIONES DEL MICROCONTROLADOR					
;-------------------------------------------------------------------------------
;###############################################################################    
    CONFIG OSC = INTIO1		; Configuramos la velocidad del clock
    CONFIG WDT = OFF		; Watch dog timer --> OFF 
    CONFIG PBADEN = DIG		; Configuramos el PORTB como digital
    
;###############################################################################    
;-------------------------------------------------------------------------------
;   VARIABLES
;-------------------------------------------------------------------------------
;###############################################################################    
;-------------------------------------------------------------------------------
;---- GENERIC TICKS ------------------------------------------------------------
;------------------------------------------------------------------------------- 
MAIN_COUNTER_LOW	    EQU	    0x0001
MAIN_COUNTER_HIGH	    EQU	    0x0002
;-------------------------------------------------------------------------------	    
;---- TAD LEDS VARS ------------------------------------------------------------
;-------------------------------------------------------------------------------
LEDS_V_WORKMODE		    EQU	    0x0003  ; Al ser excluyente la forma de encender los leds, usaremos una variable para indicar el modo de trabajo
LEDS_V_COUNTER		    EQU	    0x0004  ; Contador de TICS que usaremos para varias funciones
LEDS_V_FLAGS		    EQU	    0x0005  ; Variable en la que usaremos bits, para gestionar direccion del barrido, blinking status (si leds on/off)
LEDS_V_STATUS		    EQU	    0x0006  ; Estado del Workmode en el que estamos actualmente
LEDS_V_SCANNING_CHECKPOINT  EQU	    0x0007
LEDS_V_PROGRESS_CHECKPOINT  EQU	    0x0008  ; Limite o paso de la barra de progreso, cuando se supera se enciende 1 led mas	    
LEDS_V_PROGRESS_COUNTER	    EQU	    0x0009  ; Contador que usamos para saber si hemos llegado al limite o paso (checkpoint)   
LEDS_V_BLINKING_COUNTER	    EQU	    0x000A  ; Contador para el Blinking
;-------------------------------------------------------------------------------	    
;---- TAD SIO VARS -------------------------------------------------------------
;-------------------------------------------------------------------------------	    
SIO_RXBYTES_COUNTLOW	    EQU	    0x000B  ; Contador de Bytes recibidos (Low)
SIO_RXBYTES_COUNTHIGH	    EQU	    0x000C  ; Contador de Bytes recibidos (High)
SIO_TXBYTES_COUNTLOW        EQU     0x000D  ; Contador de Bytes enviados (Low)
SIO_TXBYTES_COUNTHIGH       EQU     0x000E  ; Contador de Bytes enviados (High)
SIO_CHAR_RECEIVED           EQU     0x000F  ; Variable para guardar temporalmente el Byte recibido
SIO_TIME_COUNTLOW	    EQU	    0x0010  ; Contador de tiempo (Low)
SIO_TIME_COUNTHIGH	    EQU	    0x0011  ; Contador de tiempo (High)
	    
;-------------------------------------------------------------------------------	    
;---- TAD RFID VARS ------------------------------------------------------------
;-------------------------------------------------------------------------------	    
RFID_BITS_ENVIADOS	    EQU	    0x0012
RFID_TIME_COUNTER	    EQU	    0x0013
RFID_CHAR_TOSEND	    EQU	    0x0014
RFID_TXBYTES_COUNTLOW	    EQU	    0x0015
RFID_TXBYTES_COUNTHIGH	    EQU	    0x0016
	    
VARIABLE_GUARRADA_MAXIMA_HIGH	EQU 0x0017
VARIABLE_GUARRADA_MAXIMA_LOW	EQU 0x0018	
	

;############################################################################### 		
;-------------------------------------------------------------------------------
;   DIRECCIONES PRINCIPALES
;-------------------------------------------------------------------------------
;############################################################################### 	    
    ORG 0x0000
    GOTO    SETUP
    ORG 0x0008			; Definimos la RSI para las HIGH IRQ
    GOTO    RSI_HIGH
    ORG 0x0018			; Definimos la RSI para las LOW IRQ aunque no las usaremos porque las desactivaremos
    GOTO    RSI_LOW	

;############################################################################### 
;-------------------------------------------------------------------------------
;   TABLA DE "DIVISION" DESDE 0 A 300 / 10 PARA SABER EL CHECKPOINT DE LEDS
;-------------------------------------------------------------------------------
;############################################################################### 
    ORG 0x0020
    DATA    0x0000, 0x0000  ; Si nos envian menos de 10 caracteres, diremos que la division 
    DATA    0x0000, 0x0000  ; es 0, lo cargaremos en el checkpoint y el RFID o el que tenga 
    DATA    0x0000, 0x0101  ; que usar la barra de progreso se encargara de decidir que hacer
    DATA    0x0101, 0x0101
    DATA    0x0101, 0x0101  ; 19
    DATA    0x0202, 0x0202
    DATA    0x0202, 0x0202
    DATA    0x0202, 0x0303  ; 31
    DATA    0x0303, 0x0303
    DATA    0x0303, 0x0303  ; 39
    DATA    0x0404, 0x0404
    DATA    0x0404, 0x0404
    DATA    0x0404, 0x0505
    DATA    0x0505, 0x0505
    DATA    0x0505, 0x0505  ; 59
    DATA    0x0606, 0x0606
    DATA    0x0606, 0x0606
    DATA    0x0606, 0x0707  ; 71
    DATA    0x0707, 0x0707
    DATA    0x0707, 0x0707  ; 79
    DATA    0x0808, 0x0808
    DATA    0x0808, 0x0808
    DATA    0x0808, 0x0909  ; 91
    DATA    0x0909, 0x0909
    DATA    0x0909, 0x0909  ; 99
    DATA    0x0A0A, 0x0A0A
    DATA    0x0A0A, 0x0A0A
    DATA    0x0A0A, 0x0A0B
    DATA    0x0B0B, 0x0B0B
    DATA    0x0B0B, 0x0B0B  ; 119
    DATA    0x0C0C, 0x0C0C
    DATA    0x0C0C, 0x0C0C
    DATA    0x0C0C, 0x0D0D  ; 131
    DATA    0x0D0D, 0x0D0D
    DATA    0x0D0D, 0x0D0D  ; 139
    DATA    0x0E0E, 0x0E0E
    DATA    0x0E0E, 0x0E0E
    DATA    0x0E0E, 0x0F0F  ; 151
    DATA    0x0F0F, 0x0F0F
    DATA    0x0F0F, 0x0F0F  ; 159
    DATA    0x1010, 0x1010
    DATA    0x1010, 0x1010
    DATA    0x1010, 0x1111  ; 171
    DATA    0x1111, 0x1111
    DATA    0x1111, 0x1111  ; 179
    DATA    0x1212, 0x1212
    DATA    0x1212, 0x1212
    DATA    0x1212, 0x1313  ; 191
    DATA    0x1313, 0x1313
    DATA    0x1313, 0x1313  ; 199
    DATA    0x1414, 0x1414
    DATA    0x1414, 0x1414
    DATA    0x1414, 0x1515  ; 211 
    DATA    0x1515, 0x1515
    DATA    0x1515, 0x1515  ; 219
    DATA    0x1616, 0x1616
    DATA    0x1616, 0x1616
    DATA    0x1616, 0x1717  ; 231
    DATA    0x1717, 0x1717
    DATA    0x1717, 0x1717  ; 239
    DATA    0x1818, 0x1818
    DATA    0x1818, 0x1818
    DATA    0x1818, 0x1919  ; 251
    DATA    0x1919, 0x1919
    DATA    0x1919, 0x1919  ; 259
    DATA    0x1A1A, 0x1A1A
    DATA    0x1A1A, 0x1A1A
    DATA    0x1A1A, 0x1B1B  ; 271
    DATA    0x1B1B, 0x1B1B
    DATA    0x1B1B, 0x1B1B  ; 279
    DATA    0x1C1C, 0x1C1C 
    DATA    0x1C1C, 0x1C1C
    DATA    0x1C1C, 0x1D1D  ; 291
    DATA    0x1D1D, 0x1D1D
    DATA    0x1D1D, 0x1D1D  ; 299
    DATA    0x1E1E, 0x0000  ; 300s
;############################################################################### 
;-------------------------------------------------------------------------------
;   RUTINA DE SERVICIO DE INTERRUPCIONES
;-------------------------------------------------------------------------------
;###############################################################################
RSI_LOW
    RETFIE  FAST    
RSI_HIGH
    BTFSC   INTCON,TMR0IF
    GOTO    GESTIONA_INT_TIMER
    RETFIE  FAST
    
GESTIONA_INT_TIMER 
    BCF	    INTCON, TMR0IF,0
    CALL    CARREGA_VALORS_TIMER
    INFSNZ  SIO_TIME_COUNTLOW,1,0
    INCF    SIO_TIME_COUNTHIGH,1,0
    
    
    INCF    MAIN_COUNTER_LOW,1
    INCF    RFID_TIME_COUNTER,1
    INCF    LEDS_V_COUNTER,1,0		; Incrementamos los ticks para el contador de leds
    INCF    LEDS_V_BLINKING_COUNTER,1,0	; Incrementamos los ticks para el contador de blinking
    RETFIE  FAST

;############################################################################### 
;-------------------------------------------------------------------------------
;   CONFIGURACIONES DEL MICROCONTROLADOR
;-------------------------------------------------------------------------------
;###############################################################################        
CONF_VARS
    CLRF MAIN_COUNTER_LOW, 0
    CLRF MAIN_COUNTER_HIGH, 0
    RETURN   
    
CONF_SIO
    ; CONFIGURACION DEL TXSTA
    MOVLW   b'00100110'
    MOVWF   TXSTA, 0
    BCF	    TXSTA, TX9,  0
    BSF	    TXSTA, TXEN, 0
    BCF	    TXSTA, SYNC, 0
    BSF	    TXSTA, BRGH, 0
    
    ;CONFIGURACIÓN DEL RCSTA
    MOVLW   b'10010000'
    MOVWF   RCSTA, 0
    BSF	    RCSTA, SPEN, 0
    BCF	    RCSTA, RX9,  0
    BSF	    RCSTA, CREN, 0
    BCF	    RCSTA, FERR, 0
    BCF	    RCSTA, OERR, 0
    
    ;CONFIGURACION DEL BAUDCON
    MOVLW   b'00000000'
    MOVWF   BAUDCON,0
    MOVLW   .25
    MOVWF   SPBRG,0
    RETURN    
    
CONF_TIMER0
    MOVLW   b'10011000'		; Activamos TIMER0, config 16bits, clock interno, clock de bajada, prescaler off, prescaler conf 0
    MOVWF   T0CON, 0
    
CARREGA_VALORS_TIMER
    MOVLW   TIMER0H_LOAD_VALUE	
    MOVWF   TMR0H, 0	
    MOVLW   TIMER0L_LOAD_VALUE		
    MOVWF   TMR0L, 0
    RETURN
    
CONF_INTERRUPTS
    BCF	    RCON, IPEN, 0	; Desactivamos prioridades en las interrupciones
    MOVLW   b'11100000'		; Configuramos para el INTCON el GIE = 1, PEIE = 1, TMR0IE = 1, todo lo demas a 0
    MOVWF   INTCON, 0		; Lo escribimos
    BCF	    INTCON2,RBPU,0
    RETURN    

CONF_PORTS
    CLRF    TRISD,0
    BCF	    TRISC,RC0,0
    BCF	    TRISE,RE0,0
    BCF	    TRISE,RE1,0
    BSF	    TRISC, RC7, 0	; SEGUN EL DATASHEET LOS PUERTOS DE LA SIO TIENEN QUE ESTAR COMO ENTRADAS
    BSF	    TRISC, RC6, 0
    BSF	    TRISB, RB4, 0	; PUERTO PULSADOR CARREGA DADES
    BSF	    TRISB, RB3, 0	; PUERTO PULSADOR ENVIA RF
    CLRF    LATD,0
    BCF	    LATE,RE0,0
    BCF	    LATE,RE1,0
    RETURN
CONF_OSCINTERNAL
    ; CARGAMOS 4MHZ (110)
    BSF	    OSCCON,IRCF2,0 
    BSF	    OSCCON,IRCF1,0
    BCF	    OSCCON,IRCF0,0
    BSF	    OSCCON, SCS1,0
    RETURN
;############################################################################### 
;-------------------------------------------------------------------------------
;   PROGRAMA PRINCIPAL 
;-------------------------------------------------------------------------------
;###############################################################################   
SETUP
    CALL    CONF_VARS
    CALL    CONF_TIMER0
    CALL    CONF_INTERRUPTS
    CALL    CONF_PORTS
    CALL    CONF_OSCINTERNAL 
    CALL    CONF_SIO
    
    CALL    SIO_INIT			; Inicia la configuracion del TAD SIO
    CALL    RFID_INIT			; Inicia la configuracion del TAD RFID
    CALL    LEDS_INIT			; Inicia la configuracion del TAD LEDS
    GOTO MAIN    
    
MAIN
    CALL    LEDS_RUN
    
    BTFSC   PIR1,RCIF,0
    CALL    SIO_RUN_FROM_PC
    
    BTFSS   PORTB,RB3,0
    CALL    GESTIONA_RFID_BTN  
    
    BTFSS   PORTB,RB4,0
    CALL    GESTIONA_SIO_BTN
    
    CALL    SIO_SEND_UNLOCK_THREAD_BYTE	; Me parece una guarrada, pero el serial port es bloqueante, asi que vamos 
    GOTO    MAIN			; enviando caracteres para desbloquear el read

GESTIONA_SIO_BTN
    CALL    ESPERA_REBOTES
    CALL    ESPERA_SIO_BTN_UP
    CALL    ESPERA_REBOTES
    CALL    SIO_SEND_REQSIGNAL
    RETURN
     
GESTIONA_RFID_BTN
    CALL    ESPERA_REBOTES
    CALL    SIO_SEND_RFID_START_SIGNAL
    CALL    ESPERA_RFID_BTN_UP
    CALL    ESPERA_REBOTES    
    MOVLW   .0
    CPFSEQ  VARIABLE_GUARRADA_MAXIMA_HIGH,0
    GOTO    RFID_ENVIA
    MOVLW   .0
    CPFSEQ  VARIABLE_GUARRADA_MAXIMA_LOW,0
    GOTO    RFID_ENVIA
    CALL    SIO_SEND_END_TASK
    CALL    LEDS_F_RESET_STATUS
    MOVLW   .1
    MOVWF   LEDS_V_WORKMODE,0
    RETURN   
    
GESTIONA_ENVIA_RFID_PC
    MOVLW   .0
    CPFSEQ  VARIABLE_GUARRADA_MAXIMA_HIGH,0
    GOTO    RFID_ENVIA
    MOVLW   .0
    CPFSEQ  VARIABLE_GUARRADA_MAXIMA_LOW,0
    GOTO    RFID_ENVIA
    CALL    SIO_SEND_END_TASK
    CALL    LEDS_F_RESET_STATUS
    MOVLW   .1
    MOVWF   LEDS_V_WORKMODE,0
    RETURN   
    
ESPERA_SIO_BTN_UP
    BTFSS   PORTB,RB3,0
    GOTO    ESPERA_SIO_BTN_UP
    RETURN
    
ESPERA_RFID_BTN_UP
    BTFSS   PORTB,RB4,0
    GOTO    ESPERA_RFID_BTN_UP
    RETURN
    
ESPERA_REBOTES
    CLRF    MAIN_COUNTER_LOW,0
ESPERA_REBOTES_LOOP    
    MOVLW   .255
    CPFSEQ  MAIN_COUNTER_LOW,0
    GOTO    ESPERA_REBOTES_LOOP
    RETURN    
;###############################################################################     
; ------------------------------------------------------------------------------
; ---------------------------------- TAD SIO -----------------------------------
; ------------------------------------------------------------------------------
;###############################################################################     
SIO_INIT
SIO_RESET
    CALL    SIO_RESET_RXBYTES
    CALL    SIO_RESET_TXBYTES
    CLRF    SIO_TIME_COUNTHIGH,0
    CLRF    SIO_TIME_COUNTLOW,0
    RETURN

SIO_RESET_RXBYTES
    MOVLW   .128
    MOVWF   SIO_RXBYTES_COUNTLOW,0
    CLRF    SIO_RXBYTES_COUNTHIGH,0
    CLRF    VARIABLE_GUARRADA_MAXIMA_LOW,0
    CLRF    VARIABLE_GUARRADA_MAXIMA_HIGH,0    
    RETURN

SIO_RESET_TXBYTES
    MOVLW   .128
    MOVWF   SIO_TXBYTES_COUNTLOW,0
    CLRF    SIO_TXBYTES_COUNTHIGH,0

    RETURN

SIO_RUN_FROM_PC   
    MOVFF   RCREG,SIO_CHAR_RECEIVED
    
    MOVLW   FLAG_UPLOAD_STRING		; Codigo que nos indicara que hemos de recibir datos (la frase)
    SUBWF   SIO_CHAR_RECEIVED,0
    BTFSC   STATUS,Z,0
    GOTO    SIO_RECEIVE_STRING
    
    MOVLW   FLAG_DOWNLOAD_STRING	; Codigo que nos indicara que hemos de enviar datos por serial
    SUBWF   SIO_CHAR_RECEIVED,0
    BTFSC   STATUS,Z,0
    GOTO    SIO_SEND_STRING
    
    MOVLW   FLAG_START_RFID_SEND	; Codigo que nos indicara que hemos de enviar datos RF
    SUBWF   SIO_CHAR_RECEIVED,0
    BTFSC   STATUS,Z,0
    GOTO    GESTIONA_ENVIA_RFID_PC
    RETURN

SIO_WAIT_10S
    MOVLW   HIGH(.10000)
    CPFSEQ  SIO_TIME_COUNTHIGH,0
    GOTO    SIO_RECEIVE_STRING_WAIT

    MOVLW   LOW(.10000)
    CPFSEQ  SIO_TIME_COUNTLOW,0
    GOTO    SIO_RECEIVE_STRING_WAIT

    CALL    LEDS_F_RESET_STATUS
    MOVLW   .1
    MOVWF   LEDS_V_WORKMODE,0
    RETURN  

SIO_RECEIVE_STRING
    CALL    SIO_RESET_RXBYTES
    CLRF    SIO_TIME_COUNTHIGH,0
    CLRF    SIO_TIME_COUNTLOW,0
SIO_RECEIVE_STRING_WAIT    
    BTFSS   PIR1, RCIF, 0
    GOTO    SIO_WAIT_10S
    CALL    RAM_RESET 
    
SIO_RECEIVE_STRING_LOOP
    BTFSS   PIR1, RCIF, 0
    GOTO    SIO_RECEIVE_STRING_LOOP	;; SI NO HEMOS RECIBIDO EL SIGUIENTE CARACTER, LO ESPERAMOS
    
    MOVFF   RCREG,SIO_CHAR_RECEIVED	;; RECUPERAMOS EL CARACTER QUE HAY EN LA SIO
    
    MOVLW   0x00			;; COMPROVAMOS SI EL CARACTER RECIBIDO ES EL CARACTER DE FINALIZACION DE STRING
    SUBWF   SIO_CHAR_RECEIVED,0
    BTFSC   STATUS,Z,0
    GOTO    SIO_END_RECEIVE_STRING	;; SI LO ES, NO LO GUARDAMOS Y ENVIAMOS FUERA

    MOVFF   SIO_CHAR_RECEIVED,POSTINC0	;; GUARDAMOS EL CARACTER RECIBIDO EN LA SIGUIENTE DIRECCION DE LA RAM
    INFSNZ  SIO_RXBYTES_COUNTLOW,1,0
    INCF    SIO_RXBYTES_COUNTHIGH,1,0
    INFSNZ  VARIABLE_GUARRADA_MAXIMA_LOW,1,0
    INCF    VARIABLE_GUARRADA_MAXIMA_HIGH,1,0
    
    
    MOVLW   HIGH(.428)			; En este trozo de codigo protegeremos al microcontrolador, haciendo que aunque el 
    CPFSEQ  SIO_RXBYTES_COUNTHIGH,0	; usuario o sistema que se conecta con el micro, envie mas de 300 caracteres, pudiendo
    GOTO    SIO_RECEIVE_STRING_LOOP	; llegar a sobreescribir zona de memoria que no toca. Nosotros hemos definido desde la 128
					; del primer banco. Ya que tenemos que poder alojar 300 caracteres, pero un banco de memoria
    MOVLW   LOW(.428)			; es solo de 256. Por lo que para evitar problemas, tan solo alojaremos 300 caracteres,  
    CPFSEQ  SIO_RXBYTES_COUNTLOW,0	; una vez recibamos el caracter 301 lo trataremos como si hubiera llegado el caracter 
    GOTO    SIO_RECEIVE_STRING_LOOP	; de fin de transmision y dejaremos de guardar en la ram.
					; Pero? El pc seguira enviando datos, no pasa nada, mientras no envie el caracter de inicio 
    CALL    SIO_END_RECEIVE_STRING	; de transmission, o de peticion de envio RFID, el TAD no entrará en ninguna opcion del "switch"
    RETURN

SIO_END_RECEIVE_STRING   
    CLRF    TBLPTRU, 0
    CLRF    TBLPTRH, 0
    MOVLW   0x20
    MOVWF   TBLPTRL,0
    
    MOVF    VARIABLE_GUARRADA_MAXIMA_HIGH,0
    ADDWF   TBLPTRH,1,0
    
    MOVF    VARIABLE_GUARRADA_MAXIMA_LOW,0	
    ADDWF   TBLPTRL,1,0
    
    MOVLW   .229
    CPFSLT  VARIABLE_GUARRADA_MAXIMA_LOW,0
    INCF    TBLPTRH,1,0
    
    TBLRD*
    MOVFF   TABLAT,LEDS_V_PROGRESS_CHECKPOINT
   
    CALL    LEDS_F_RESET_STATUS
    MOVLW   .10
    MOVWF   LEDS_V_WORKMODE,0
    RETURN

SIO_SEND_STRING
    CALL    RAM_RESET
    CALL    SIO_RESET_TXBYTES
   
    MOVF    SIO_TXBYTES_COUNTHIGH,0	    ; Si no hay ningun mensaje cargado
    CPFSEQ  SIO_RXBYTES_COUNTHIGH,0	    ; evitamos enviar la basura que pueda
    GOTO    SIO_SEND_STRING_LOOP	    ; haber en la memoria ram del microchip
    MOVF    SIO_TXBYTES_COUNTLOW,0	    ; Si el usuario solicita la informacion
    CPFSEQ  SIO_RXBYTES_COUNTLOW,0	    ; entonces, revisaremos si hay algun caracter
    GOTO    SIO_SEND_STRING_LOOP	    ; y sino, enviamos el TXSIGNAL
    
    GOTO    SIO_SEND_END_TXSIGNAL
    
SIO_SEND_STRING_LOOP    
    BTFSS   TXSTA, TRMT, 0
    GOTO    SIO_SEND_STRING_LOOP

    MOVFF   POSTINC0, TXREG
    INFSNZ  SIO_TXBYTES_COUNTLOW,1,0
    INCF    SIO_TXBYTES_COUNTHIGH,1,0
 
    MOVF    SIO_TXBYTES_COUNTHIGH,0
    CPFSEQ  SIO_RXBYTES_COUNTHIGH,0
    GOTO    SIO_SEND_STRING_LOOP
    MOVF    SIO_TXBYTES_COUNTLOW,0
    CPFSEQ  SIO_RXBYTES_COUNTLOW,0   
    GOTO    SIO_SEND_STRING_LOOP
    
    
SIO_SEND_END_TXSIGNAL
    BTFSS   TXSTA,TRMT,0
    GOTO    SIO_SEND_END_TXSIGNAL
    MOVLW   FLAG_END_TRANSMISSION
    MOVWF   TXREG,0
    RETURN    
    
SIO_SEND_RFID_START_SIGNAL
    BTFSS   TXSTA,TRMT,0
    GOTO    SIO_SEND_RFID_START_SIGNAL
    MOVLW   FLAG_START_RFID_SEND
    MOVWF   TXREG,0
    RETURN
    
SIO_SEND_REQSIGNAL
    BTFSS   TXSTA,TRMT,0
    GOTO    SIO_SEND_REQSIGNAL
    MOVLW   FLAG_UPLOAD_STRING
    MOVWF   TXREG,0
    RETURN
    
SIO_SEND_END_TASK
    BTFSS   TXSTA,TRMT,0
    GOTO    SIO_SEND_END_TASK
    MOVLW   FLAG_END_TASK
    MOVWF   TXREG,0
    RETURN
    
SIO_SEND_UNLOCK_THREAD_BYTE		    ; Es el unico que es cooperativo ya que
    BTFSS   TXSTA,TRMT,0		    ; se envia cuando la placa no tiene nada
    RETURN				    ; que hacer.
    MOVLW   FLAG_UNLOCK_THREAD
    MOVWF   TXREG,0
    RETURN
; ------------------------------------------------------------------------------
; ---------------------------------- END TAD SIO -------------------------------
; ------------------------------------------------------------------------------    

    
;###############################################################################     
; ------------------------------------------------------------------------------
; ---------------------------------- TAD RAM -----------------------------------
; ------------------------------------------------------------------------------
;###############################################################################     
; Esto es un "TAD" que unicamente lo que hace es resetear los FSR de la ram
; Sabemos que esto es un CALL y por lo tanto son 2 INSTR + 2 INSTR return
; pero a nivel de código es mas limpio / facil de modificar.
RAM_INIT
RAM_RESET
    MOVLW   .128
    MOVWF   FSR0L,0
    CLRF    FSR0H,0
    RETURN
; ------------------------------------------------------------------------------
; ---------------------------------- END TAD RAM -------------------------------
; ------------------------------------------------------------------------------
    
;###############################################################################
; ------------------------------------------------------------------------------
; ---------------------------------- TAD LEDS ----------------------------------
; ------------------------------------------------------------------------------
;###############################################################################     
LEDS_INIT
    CALL    LEDS_F_RESET_STATUS
    ; DEFAULT WORKMODE + DEFAULT CHECKPOINT / LIMIT FOR PROGRESS BAR
    MOVLW   .0
    MOVWF   LEDS_V_WORKMODE,0
    MOVLW   .30
    MOVWF   LEDS_V_PROGRESS_CHECKPOINT,0
    MOVLW   0x42
    MOVWF   LEDS_V_SCANNING_CHECKPOINT,0
    CALL    LEDS_F_STARTMODE		
    RETURN
    
LEDS_RUN
    MOVLW   .0
    SUBWF   LEDS_V_WORKMODE,0
    BTFSC   STATUS,Z,0
    GOTO    LEDS_F_RESET_STATUS
    
    MOVLW   .1
    SUBWF   LEDS_V_WORKMODE,0
    BTFSC   STATUS,Z,0
    GOTO    LEDS_F_SCANNING_RUN
    
    MOVLW   .2
    SUBWF   LEDS_V_WORKMODE,0
    BTFSC   STATUS,Z,0
    GOTO    LEDS_F_PROGRESS_RUN
    
    MOVLW   .10
    SUBWF   LEDS_V_WORKMODE,0
    BTFSC   STATUS,Z,0
    GOTO    LEDS_F_BLINKING_5HZ
    
    MOVLW   .11
    SUBWF   LEDS_V_WORKMODE,0
    BTFSC   STATUS,Z,0
    GOTO    LEDS_F_BLINKING_10HZ
    
    ; SI NO EXISTE MODO CORRECTO ENVIAMOS AL MODO ESPERA
    MOVLW   .0
    MOVWF   LEDS_V_WORKMODE,0
    RETURN
    
LEDS_F_RESET_STATUS			; Cuando cambiemos el modo de trabajo, reseteamos los estados
    CLRF    LEDS_V_FLAGS,0
    CLRF    LEDS_V_STATUS,0
    CLRF    LEDS_V_COUNTER,0
    CLRF    LEDS_V_PROGRESS_COUNTER,0
    CLRF    LEDS_V_BLINKING_COUNTER,0
    RETURN  
; ------ STARTING MODE START -----    
LEDS_F_STARTMODE
    CLRF    LATD,0			
    BCF	    LATE,RE0,0
    BCF	    LATE,RE1,0
    BSF	    LATD,RD0,0
    BSF	    LATD,RD1,0
    RETURN
; ------ STARTING MODE END ------   
; ----- SCANNING MODE START -----    
LEDS_F_SCANNING_RUN    
    MOVLW   LEDS_TICKS_CHECKPOINT	; Es un define de arriba
    CPFSEQ  LEDS_V_COUNTER,0
    RETURN
    CLRF    LATD,0			; Apagamos todos los leds
    BCF	    LATE,RE0,0
    BCF	    LATE,RE1,0
    MOVLW   .0
    SUBWF   LEDS_V_STATUS,0,0
    BTFSC   STATUS,Z,0
    GOTO    LEDS_F_SCANNING_STATUS_0
    MOVLW   .1
    SUBWF   LEDS_V_STATUS,0,0
    BTFSC   STATUS,Z,0
    GOTO    LEDS_F_SCANNING_STATUS_1
    MOVLW   .2
    SUBWF   LEDS_V_STATUS,0,0
    BTFSC   STATUS,Z,0
    GOTO    LEDS_F_SCANNING_STATUS_2
    MOVLW   .3
    SUBWF   LEDS_V_STATUS,0,0
    BTFSC   STATUS,Z,0
    GOTO    LEDS_F_SCANNING_STATUS_3
    MOVLW   .4
    SUBWF   LEDS_V_STATUS,0,0
    BTFSC   STATUS,Z,0
    GOTO    LEDS_F_SCANNING_STATUS_4
    MOVLW   .5
    SUBWF   LEDS_V_STATUS,0,0
    BTFSC   STATUS,Z,0
    GOTO    LEDS_F_SCANNING_STATUS_5
    MOVLW   .6
    SUBWF   LEDS_V_STATUS,0,0
    BTFSC   STATUS,Z,0
    GOTO    LEDS_F_SCANNING_STATUS_6
    MOVLW   .7
    SUBWF   LEDS_V_STATUS,0,0
    BTFSC   STATUS,Z,0
    GOTO    LEDS_F_SCANNING_STATUS_7
    MOVLW   .8
    SUBWF   LEDS_V_STATUS,0,0
    BTFSC   STATUS,Z,0
    GOTO    LEDS_F_SCANNING_STATUS_8
    CLRF    LEDS_V_STATUS,0		; Si no es ninguno, limpiamos estado
    RETURN    
LEDS_F_SCANNING_STATUS_0
    BSF	    LATD,RD0,0
    BSF	    LATD,RD1,0
    BSF	    LEDS_V_FLAGS,0,0		; Cambiamos direccion a la derecha
    GOTO    LEDS_F_INCREASE_SCANNING_STATUS
LEDS_F_SCANNING_STATUS_1 
    BSF	    LATD,RD1,0
    BSF	    LATD,RD2,0
    BTFSC   LEDS_V_FLAGS,0,0
    GOTO    LEDS_F_INCREASE_SCANNING_STATUS
    GOTO    LEDS_F_DECREASE_SCANNING_STATUS
LEDS_F_SCANNING_STATUS_2 
    BSF	    LATD,RD2,0
    BSF	    LATD,RD3,0
    BTFSC   LEDS_V_FLAGS,0,0
    GOTO    LEDS_F_INCREASE_SCANNING_STATUS
    GOTO    LEDS_F_DECREASE_SCANNING_STATUS
LEDS_F_SCANNING_STATUS_3 
    BSF	    LATD,RD3,0
    BSF	    LATD,RD4,0
    BTFSC   LEDS_V_FLAGS,0,0
    GOTO    LEDS_F_INCREASE_SCANNING_STATUS
    GOTO    LEDS_F_DECREASE_SCANNING_STATUS
LEDS_F_SCANNING_STATUS_4 
    BSF	    LATD,RD4,0
    BSF	    LATD,RD5,0
    BTFSC   LEDS_V_FLAGS,0,0
    GOTO    LEDS_F_INCREASE_SCANNING_STATUS
    GOTO    LEDS_F_DECREASE_SCANNING_STATUS
LEDS_F_SCANNING_STATUS_5 
    BSF	    LATD,RD5,0
    BSF	    LATD,RD6,0
    BTFSC   LEDS_V_FLAGS,0,0
    GOTO    LEDS_F_INCREASE_SCANNING_STATUS
    GOTO    LEDS_F_DECREASE_SCANNING_STATUS
LEDS_F_SCANNING_STATUS_6 
    BSF	    LATD,RD6,0
    BSF	    LATD,RD7,0
    BTFSC   LEDS_V_FLAGS,0,0
    GOTO    LEDS_F_INCREASE_SCANNING_STATUS
    GOTO    LEDS_F_DECREASE_SCANNING_STATUS
LEDS_F_SCANNING_STATUS_7 
    BSF	    LATD,RD7,0
    BSF	    LATE,RE0,0
    BTFSC   LEDS_V_FLAGS,0,0
    GOTO    LEDS_F_INCREASE_SCANNING_STATUS
    GOTO    LEDS_F_DECREASE_SCANNING_STATUS
LEDS_F_SCANNING_STATUS_8 
    BSF	    LATE,RE0,0
    BSF	    LATE,RE1,0
    BCF	    LEDS_V_FLAGS,0,0	; Cambiamos direccion a la izquierda	
    GOTO    LEDS_F_DECREASE_SCANNING_STATUS        
LEDS_F_INCREASE_SCANNING_STATUS
    INCF    LEDS_V_STATUS,1,0
    CLRF    LEDS_V_COUNTER
    RETURN
LEDS_F_DECREASE_SCANNING_STATUS
    DECF    LEDS_V_STATUS,1,0
    CLRF    LEDS_V_COUNTER
    RETURN
; ----- LEDS SCANNING MODE END -----    
; ----- LEDS PROGRESS MODE START -----
LEDS_F_PROGRESS_RUN
    MOVLW	.0
    SUBWF	LEDS_V_STATUS,0
    BTFSC	STATUS,Z,0
    GOTO	LEDS_F_PROGRESS_STATUS_0
    MOVLW	.1
    SUBWF	LEDS_V_STATUS,0
    BTFSC	STATUS,Z,0
    GOTO	LEDS_F_PROGRESS_STATUS_1
    MOVLW	.2
    SUBWF	LEDS_V_STATUS,0
    BTFSC	STATUS,Z,0
    GOTO	LEDS_F_PROGRESS_STATUS_2
    MOVLW	.3
    SUBWF	LEDS_V_STATUS,0
    BTFSC	STATUS,Z,0
    GOTO	LEDS_F_PROGRESS_STATUS_3
    MOVLW	.4
    SUBWF	LEDS_V_STATUS,0
    BTFSC	STATUS,Z,0
    GOTO	LEDS_F_PROGRESS_STATUS_4
    MOVLW	.5
    SUBWF	LEDS_V_STATUS,0
    BTFSC	STATUS,Z,0
    GOTO	LEDS_F_PROGRESS_STATUS_5
    MOVLW	.6
    SUBWF	LEDS_V_STATUS,0
    BTFSC	STATUS,Z,0
    GOTO	LEDS_F_PROGRESS_STATUS_6
    MOVLW	.7
    SUBWF	LEDS_V_STATUS,0
    BTFSC	STATUS,Z,0
    GOTO	LEDS_F_PROGRESS_STATUS_7
    MOVLW	.8
    SUBWF	LEDS_V_STATUS,0
    BTFSC	STATUS,Z,0
    GOTO	LEDS_F_PROGRESS_STATUS_8
    MOVLW	.9
    SUBWF	LEDS_V_STATUS,0
    BTFSC	STATUS,Z,0
    GOTO	LEDS_F_PROGRESS_STATUS_9
    MOVLW	.10
    SUBWF	LEDS_V_STATUS,0
    BTFSC	STATUS,Z,0
    GOTO	LEDS_F_PROGRESS_STATUS_10
		; Si no es ningun modo de los anteriores, PASAMOS
    RETURN	

LEDS_F_PROGRESS_STATUS_0
    CLRF	LATD,0
    BCF		LATE,RE0,0
    BCF		LATE,RE1,0
    MOVF	LEDS_V_PROGRESS_COUNTER,0
    CPFSEQ	LEDS_V_PROGRESS_CHECKPOINT,0
    RETURN
    INCF	LEDS_V_STATUS,1,0
    CLRF	LEDS_V_PROGRESS_COUNTER
    RETURN
LEDS_F_PROGRESS_STATUS_1
    BSF		LATD,0,0
    MOVF	LEDS_V_PROGRESS_COUNTER,0
    CPFSEQ	LEDS_V_PROGRESS_CHECKPOINT,0
    RETURN
    INCF	LEDS_V_STATUS,1,0
    CLRF	LEDS_V_PROGRESS_COUNTER
    RETURN	
LEDS_F_PROGRESS_STATUS_2
    BSF		LATD,1,0
    MOVF	LEDS_V_PROGRESS_COUNTER,0
    CPFSEQ	LEDS_V_PROGRESS_CHECKPOINT,0
    RETURN
    INCF	LEDS_V_STATUS,1,0
    CLRF	LEDS_V_PROGRESS_COUNTER
    RETURN	
LEDS_F_PROGRESS_STATUS_3
    BSF		LATD,2,0
    MOVF	LEDS_V_PROGRESS_COUNTER,0
    CPFSEQ	LEDS_V_PROGRESS_CHECKPOINT,0
    RETURN
    INCF	LEDS_V_STATUS,1,0
    CLRF	LEDS_V_PROGRESS_COUNTER
    RETURN
LEDS_F_PROGRESS_STATUS_4
    BSF		LATD,3,0
    MOVF	LEDS_V_PROGRESS_COUNTER,0
    CPFSEQ	LEDS_V_PROGRESS_CHECKPOINT,0
    RETURN
    INCF	LEDS_V_STATUS,1,0
    CLRF	LEDS_V_PROGRESS_COUNTER
    RETURN
LEDS_F_PROGRESS_STATUS_5
    BSF		LATD,4,0
    MOVF	LEDS_V_PROGRESS_COUNTER,0
    CPFSEQ	LEDS_V_PROGRESS_CHECKPOINT,0
    RETURN
    INCF	LEDS_V_STATUS,1,0
    CLRF	LEDS_V_PROGRESS_COUNTER
    RETURN
LEDS_F_PROGRESS_STATUS_6
    BSF		LATD,5,0
    MOVF	LEDS_V_PROGRESS_COUNTER,0
    CPFSEQ	LEDS_V_PROGRESS_CHECKPOINT,0
    RETURN
    INCF	LEDS_V_STATUS,1,0
    CLRF	LEDS_V_PROGRESS_COUNTER
    RETURN	
LEDS_F_PROGRESS_STATUS_7
    BSF		LATD,6,0
    MOVF	LEDS_V_PROGRESS_COUNTER,0
    CPFSEQ	LEDS_V_PROGRESS_CHECKPOINT,0
    RETURN
    INCF	LEDS_V_STATUS,1,0
    CLRF	LEDS_V_PROGRESS_COUNTER
    RETURN
LEDS_F_PROGRESS_STATUS_8
    BSF		LATD,7,0
    MOVF	LEDS_V_PROGRESS_COUNTER,0
    CPFSEQ	LEDS_V_PROGRESS_CHECKPOINT,0
    RETURN	
    INCF	LEDS_V_STATUS,1,0
    CLRF	LEDS_V_PROGRESS_COUNTER
    RETURN
LEDS_F_PROGRESS_STATUS_9
    BSF		LATE,0,0
    MOVF	LEDS_V_PROGRESS_COUNTER,0
    CPFSEQ	LEDS_V_PROGRESS_CHECKPOINT,0
    RETURN
    INCF	LEDS_V_STATUS,1,0
    CLRF	LEDS_V_PROGRESS_COUNTER
    RETURN	
LEDS_F_PROGRESS_STATUS_10
    SETF	LATD,0
    BSF		LATE,0,0
    BSF		LATE,1,0
    RETURN
; ----- LEDS PROGRESS MODE START -----    
; ----- LEDS BLINKING MODE START -----    
LEDS_F_BLINKING_5HZ		
    MOVLW   0x63
    CPFSGT  LEDS_V_BLINKING_COUNTER,0    
    RETURN
    CLRF    LEDS_V_BLINKING_COUNTER,0
    BTFSS   LEDS_V_FLAGS,1
    GOTO    LEDS_F_ALLON
    GOTO    LEDS_F_ALLOFF        
LEDS_F_BLINKING_10HZ		
    MOVLW   .50
    CPFSGT  LEDS_V_BLINKING_COUNTER,0    
    RETURN
    CLRF    LEDS_V_BLINKING_COUNTER,0
    BTFSS   LEDS_V_FLAGS,1
    GOTO    LEDS_F_ALLON
    GOTO    LEDS_F_ALLOFF        
; ----- LEDS BLINKING MODE END ----- 
LEDS_F_ALLON
    BSF	    LEDS_V_FLAGS,1
    SETF    LATD,0
    BSF	    LATE,RE0,0
    BSF	    LATE,RE1,0
    RETURN
LEDS_F_ALLOFF
    BCF	    LEDS_V_FLAGS,1
    CLRF    LATD,0
    BCF	    LATE,RE0,0
    BCF	    LATE,RE1,0
    RETURN    
; ------------------------------------------------------------------------------
; ---------------------------------- END TAD LEDS ------------------------------
; ------------------------------------------------------------------------------

; ##############################################################################
; ------------------------------------------------------------------------------
; ---------------------------------- TAD RFID ----------------------------------
; ------------------------------------------------------------------------------
;###############################################################################     
    ; En este TAD sera egoista con el Quantum que le toca de procesado.
    ; ya que mientras enviamos por RFID no tenemos que dejar a la placa
    ; hacer nada mas, salvo encender los leds de la barra de progreso.
    
RFID_START_BIT
    BSF	    LATC,RC0,0
    CALL    RFID_WAIT_20MS
    BCF	    LATC,RC0,0
    CALL    RFID_WAIT_20MS
    RETURN
    
RFID_START_BIT_2
    BSF	    LATC,RC0,0
    CALL    RFID_WAIT_2MS
    ;BCF	    LATC,RC0,0
    RETURN
    
RFID_STOP_BIT
    BCF	    LATC,RC0,0
    CALL    RFID_WAIT_20MS
    RETURN
    
RFID_ENVIA_FLAG
    MOVWF   RFID_CHAR_TOSEND,0
    CLRF    RFID_BITS_ENVIADOS,0
RFID_ENVIA_FLAG_LOOP
    CALL    ENVIAMOS_RFID_DATA
    RRNCF   RFID_CHAR_TOSEND,1,0
    INCF    RFID_BITS_ENVIADOS,1,0
    MOVLW   .8
    CPFSEQ  RFID_BITS_ENVIADOS,0
    GOTO    RFID_ENVIA_FLAG_LOOP
    CLRF    RFID_BITS_ENVIADOS,0
    
    RETURN    


RFID_ENVIA    
    CALL    RFID_ENVIA_FRASE
    CALL    SIO_SEND_END_TASK
    RETURN
    
RFID_ENVIA_FRASE
    ; EMPEZAMOS A ENVIAR NUESTRO DATO
    CALL    LEDS_F_RESET_STATUS		; RESETEAMOS ESTADOS
    MOVLW   .2
    MOVWF   LEDS_V_WORKMODE,0

    
    CALL    RFID_RESET
    CALL    RFID_SEND_SYNC
    CALL    RFID_START_BIT
    ;CALL    RFID_START_BIT_2
    
    
    MOVLW   FLAG_UPLOAD_STRING
    CALL    RFID_ENVIA_FLAG
    
    ;CALL    RFID_RESET
    CALL    RFID_SEND_STRING
    
    MOVLW   FLAG_RFID_END_TRANSMISION
    CALL    RFID_ENVIA_FLAG
    
    CALL    RFID_STOP_BIT
    

    CALL    LEDS_F_RESET_STATUS		; RESETEAMOS ESTADOS
    MOVLW   .11				; ACTIVAMOS BLINK 10 HZ
    MOVWF   LEDS_V_WORKMODE,0
    RETURN
    
RFID_INIT
RFID_RESET

    CLRF    FSR0H, 0
    CLRF    RFID_TXBYTES_COUNTHIGH,0
    MOVLW   .128
    MOVWF   FSR0L, 0
    MOVWF   RFID_TXBYTES_COUNTLOW,0
    CLRF    RFID_BITS_ENVIADOS,0
    
    RETURN
    
RFID_WAIT_5MS
    CLRF    RFID_TIME_COUNTER,0
RFID_WAIT_5MS_LOOP
    MOVLW   .5
    CPFSEQ  RFID_TIME_COUNTER, 0
    GOTO    RFID_WAIT_5MS_LOOP
    RETURN
    
RFID_WAIT_2MS
    CLRF    RFID_TIME_COUNTER,0
RFID_WAIT_2MS_LOOP
    MOVLW   .2
    CPFSEQ  RFID_TIME_COUNTER, 0
    GOTO    RFID_WAIT_2MS_LOOP
    RETURN
    
RFID_WAIT_20MS
    CLRF    RFID_TIME_COUNTER,0
RFID_WAIT_20MS_LOOP
    MOVLW   .10
    CPFSEQ  RFID_TIME_COUNTER, 0
    GOTO    RFID_WAIT_20MS_LOOP
    RETURN

RFID_SEND_SYNC
    MOVLW   b'11001100'
    MOVWF   RFID_CHAR_TOSEND,0
    CLRF    RFID_BITS_ENVIADOS,0
RFID_SEND_SYNC_LOOP
    CALL    ENVIAMOS_RFID_DATA
    RRNCF   RFID_CHAR_TOSEND,1,0
    INCF    RFID_BITS_ENVIADOS,1,0
    MOVLW   .8
    CPFSEQ  RFID_BITS_ENVIADOS,0
    GOTO    RFID_SEND_SYNC_LOOP
    CLRF    RFID_BITS_ENVIADOS,0
    
    RETURN
    
RFID_SEND_HEADER    
    MOVLW   b'11110110'
    MOVWF   RFID_CHAR_TOSEND,0
    CLRF    RFID_BITS_ENVIADOS,0
RFID_SEND_HEADER_LOOP
    CALL    ENVIAMOS_RFID_DATA
    RRNCF   RFID_CHAR_TOSEND,1,0
    INCF    RFID_BITS_ENVIADOS,1,0
    MOVLW   .8
    CPFSEQ  RFID_BITS_ENVIADOS,0
    GOTO    RFID_SEND_HEADER_LOOP
    RETURN
    
ENVIAMOS_RFID_DATA
    BTFSS   RFID_CHAR_TOSEND,0,0
    GOTO    ENVIA_CERO
    GOTO    ENVIA_UNO
    
ENVIA_UNO
    BCF	    LATC,RC0,0
    CALL    RFID_WAIT_5MS
    BSF	    LATC,RC0,0
    CALL    RFID_WAIT_5MS
    RETURN
    
ENVIA_CERO
    BSF	    LATC,RC0,0
    CALL    RFID_WAIT_5MS
    BCF	    LATC,RC0,0
    CALL    RFID_WAIT_5MS
    RETURN
    
ROTAR_LETRA
    RRNCF   RFID_CHAR_TOSEND,1,0
    RETURN
    
    
RFID_SEND_STRING
    ;CALL    RFID_SEND_HEADER
    INFSNZ  RFID_TXBYTES_COUNTLOW,1,0
    INCF    RFID_TXBYTES_COUNTHIGH,1,0
    MOVFF   POSTINC0,RFID_CHAR_TOSEND
    CLRF    RFID_BITS_ENVIADOS,0
RFID_SEND_STRING_LOOP
    CALL    ENVIAMOS_RFID_DATA
    RRNCF   RFID_CHAR_TOSEND,1,0
    INCF    RFID_BITS_ENVIADOS,1,0
    MOVLW   .8
    CPFSEQ  RFID_BITS_ENVIADOS,0
    GOTO    RFID_SEND_STRING_LOOP
    
    INCF    LEDS_V_PROGRESS_COUNTER,1,0		; Incrementamos el contador de leds 
    MOVLW   .0					; Comprobamos si el checkpoint cargado es 0, porque han enviado menos de 10 caracteres
    CPFSEQ  LEDS_V_PROGRESS_CHECKPOINT		; Si checkpoint es 0 saltamos/evitamos la llamada a la etiqueta LEDS_RUN
    GOTO    RFID_INCREMENTA_LEDS		; Si checkpoint != 0 --> Llamamos a LEDS_RUN
    
    SETF    LATD,0				; Camino para checkpoint == 0, encendemos LATD y los dos bits de LATE
    BSF	    LATE,RE0,0
    BSF	    LATE,RE1,0
    GOTO    COMPRUEBA_FIN_FRASE

RFID_INCREMENTA_LEDS
    CALL    LEDS_RUN
    GOTO    COMPRUEBA_FIN_FRASE			; No hace falta, pero es mejor por si se toca el codigo y no se tiene cuidado

COMPRUEBA_FIN_FRASE    
    MOVF    RFID_TXBYTES_COUNTHIGH,0		; Si los bytes enviados RFID == bytes recibidos SIO, volvemos al MAIN
    CPFSEQ  SIO_RXBYTES_COUNTHIGH,0
    GOTO    RFID_SEND_STRING
    ;CALL    RFID_SYNC_INTERMEDIA
    MOVF    RFID_TXBYTES_COUNTLOW,0
    SUBWF   SIO_RXBYTES_COUNTLOW,0
    BTFSS   STATUS,Z,0
    GOTO    RFID_SEND_STRING
    RETURN
    
RFID_SYNC_INTERMEDIA
    BCF	    LATC,RC0,0
    CALL    RFID_WAIT_5MS
    MOVLW   FLAG_RESYNCRO
    CALL    RFID_ENVIA_FLAG
    RETURN
; ------------------------------------------------------------------------------
; ---------------------------------- TAD RFID ----------------------------------
; ------------------------------------------------------------------------------    

    
    END