;Archivo:	main.s
;dispositivo:	PIC16F887
;Autor:		Dylan Ixcayau
;Compilador:	pic-as (v2.31), MPLABX V5.45
;
;Programa:	Sumador de 4 bits
;Hardware:	LEDs en el puerto A y C, Botones en el Puerto B
;
;Creado:	8 feb, 2021
;Ultima modificacion: 13 feb, 2021

    
PROCESSOR 16F887
#include <xc.inc>

; Configuration word 1
  CONFIG  FOSC = XT	         
  CONFIG  WDTE = OFF            ; WDT disabled (reinicio repetitivo del PIC)
  CONFIG  PWRTE = ON            ; PWRT enabled (espera de 72ms al iniciar)
  CONFIG  MCLRE = OFF           ; El pin de MCLR se utiliza como I/O
  CONFIG  CP = OFF              ; Sin proteccion de codigo
  CONFIG  CPD = OFF             ; Sin proteccion de dato
  
  CONFIG  BOREN = OFF           ; Sin reinicio cuando el voltaje de alimentacion baja de 4v
  CONFIG  IESO = OFF            ; Reinicio sin cambio de reloj de interno a externo
  CONFIG  FCMEN = OFF           ; Cambio de reloj externo a interno en caso de fallo
  CONFIG  LVP = ON              ; Programacion en bajo voltaje permitida

; Configuration word 2
  CONFIG  BOR4V = BOR40V        ; proteccion de autoescritura por el programa desactivada
  CONFIG  WRT = OFF             ; Reinicio abajo de 4V, (BOR21V=2.1V)

  PSECT udata_bank0 ;common memory
  cont_small: DS 1 ;1 byte
    
  PSECT resVect, class=CODE, abs, delta=2

;-----------vector reset----------------------------
ORG 00h		    ; posicion 0000h para el reset
resetVec:
    PAGESEL main
    goto    main

PSECT code, delta=2, abs
ORG 100h	;posicion para el codigo
;-----------configuracion----------------------------

main:					;Configuración de los puertos
    banksel	ANSEL			;Llamo al banco de memoria donde estan los ANSEL
    clrf	ANSEL			;Pines digitales
    clrf	ANSELH
    
    banksel	TRISA			;Llamo al banco de memoria donde estan los TRISA y WPUB
    movlw	11110000B		;Configuro los puertos de salida que usare y los demas los dejo como entradas para no afectar el conteo del led
    movwf	TRISA
    
    movlw	11110000B
    movwf	TRISC
    
    
    movlw	11100000B
    movwf	TRISD
    
    movlw	11111111B		;Activo las resistencias de los puertos de B
    movwf	WPUB
    
    movlw	11111111B		;Dejo todos como los puertos como botones aunque use solo los primeros
    movwf	TRISB
    
    banksel	PORTA			;Llamo al banco de memoria donde estan los PORT
    clrf	PORTA			;Limpio los puertos
    clrf	PORTC
    clrf	PORTD
    clrf	PORTB
    
;---------------Loop Principal-------------------------
Loop:
    call	delay_small		;El delay solo para que espere un tiempo
    btfsc	PORTB, 0		;Reviso el pin RB0
    call	inc_porta		;llamo al modulo para incrementar el puerto A
    
    btfsc	PORTB, 1		;Reviso el pin RB1
    call	dec_porta		;llamo al modulo para decrementar el puerto A
    
    btfsc	PORTB, 2		;Reviso el pin RB2
    call	inc_portc		;llamo al modulo para incrementar el puerto C
    
    btfsc	PORTB, 3		;Reviso el pin RB3
    call	dec_portc		;llamo al modulo para decrementar el puerto C
    
    btfsc	PORTB, 4		;Reviso el pin RB4
    call	Suma			;llamo al modulo donde se encuentra los operadores de la suma
    
    btfsc	STATUS, 1		;Reviso si existe un overflow
    bsf		PORTD, 5		;Enciendo el pin si hay un overflow
    
    btfss	STATUS, 5		;Reviso si existe un overfow
    bcf		PORTD, 5		;Apago el pin si no hay	un overflow
    
    goto	Loop			;Regreso al loop
    
;-------------------------Modulos-----------------------------------------------------------------------    
inc_porta:
    btfsc	PORTB, 0		;Antirebote del boton
    goto	$-1			
    incf	PORTA, F		;Incremento el puerto
    return				;regresa al loop principal

dec_porta:
    btfsc	PORTB, 1		;Antirebote del boton
    goto	$-1
    decf	PORTA, F		;decremento el puerto
    return				;regresa al loop principal
	
inc_portc:
    btfsc	PORTB, 2
    goto	$-1
    incf	PORTC, F
    return

dec_portc:
    btfsc	PORTB, 3
    goto	$-1
    decf	PORTC, F
    return
;---------------------SUMA-----------------------------------
    
Suma:
    btfsc	PORTB, 4		;Antirebote del boton
    goto	$-1
    movf	PORTA, w		;Mueve el valor en el puerto A a w
    addwf	PORTC, w		;Suma el valor de w y el del puerto C y el nuevo valor lo mete de nuevo a W
    movwf	PORTD			;Mueve el valor de w al puerto D
    return				;Regresa al loop principal

delay_small:
    movlw	249		;valor inicial del contador
    movwf	cont_small
    decfsz	cont_small	;decrementar el contador
    goto	$-1		;ejecutar linea anterior
    return
    
END