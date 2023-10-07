;-------------------------------------------------------------------------------
; MSP430 Assembler Code Template for use with TI Code Composer Studio
;
;
;-------------------------------------------------------------------------------
            .cdecls C,LIST,"msp430.h"       ; Include device header file
            
;-------------------------------------------------------------------------------
            .def    RESET                   ; Export program entry-point to
                                            ; make it known to linker.
;-------------------------------------------------------------------------------
            .text                           ; Assemble into program memory.
            .retain                         ; Override ELF conditional linking
                                            ; and retain current section.
            .retainrefs                     ; And retain any sections that have
                                            ; references to current section.

;-------------------------------------------------------------------------------
RESET       mov.w   #__STACK_END,SP         ; Initialize stackpointer
StopWDT     mov.w   #WDTPW|WDTHOLD,&WDTCTL  ; Stop watchdog timer


;-------------------------------------------------------------------------------
; Main loop here
;-------------------------------------------------------------------------------
main		MOV.B #0x3F, P2DIR
			; LCD@P2 → EN(.5) RS(.4) D7(.3) D6(.2) D5(.1) D4(.0)
	        CLR R5							; R5 guarda a instrução para o LCD
	        CLR R7							; R7 aponta para a string
	        MOV #0xFF10, R7  				; 0xFF10 é o endereço da string

	        ; Habilita gravação na memória flash
	        MOV #FWKEY+FSSEL1+FN0,&FCTL2	; SMCLK/2
	        MOV #FWKEY,&FCTL3				; Clear LOCK
	        MOV #FWKEY+WRT,&FCTL1			; Enable write

	        ; Guarda a string 'hello' na flash
	        MOV #0x1816, 0(R7)				; h 0x68
	        MOV #0x1516, 2(R7)				; e 0x65
	        MOV #0x1C16, 4(R7)				; l 0x6C
	        MOV #0x1C16, 6(R7)				; l 0x6C
	        MOV #0x1F16, 8(R7)				; o 0x6F

			; Move o cursor do LCD para a coluna 0 da linha 1
	        MOV #0x000C, 10(R7) 			; 0x0C

			; Guarda a string 'cimatec' na flash
	        MOV #0x1316, 12(R7) ; 0x63
	        MOV #0x1916, 14(R7) ; 0x69
	        MOV #0x1D16, 16(R7) ; 0x6D
	        MOV #0x1116, 18(R7) ; 0x61
	        MOV #0x1417, 20(R7) ; 0x74
	        MOV #0x1516, 22(R7) ; 0x65
	        MOV #0x1316, 24(R7) ; 0x63

	        ; Bloqueia gravação na meória flash
	        MOV #FWKEY,&FCTL1 ; Done. Clear WRT
	        MOV #FWKEY+LOCK,&FCTL3 ; Set LOCK

	        CALL #lcd_begin					; inicializa lcd

	        ; Rotina da interrupção
	        mov.b #0x00, P1OUT
        	mov.b #0x01, P1DIR

        	mov.w   #49999, &TACCR0			; Define valor de referência do Timer
            mov.w   #CCIE, &TACCTL0         ; Configura flag de comparação no Timer

            ; Set up Timer A. Up mode, divide clock by 8, clock from SMCLK, clear TAR
            mov.w   #MC_1|ID_3|TASSEL_2|TACLR,&TACTL
            bis.w   #GIE,SR                 ; Habilita interrupções globais

write       MOV @R7+, R5					; Lê instrução do LCD na memória flash
	        CALL #send						; Envia instrução ao LCD
	        CMP #0xFFFF, 0(R7)				; Verifica final de instruções na flash
	        JNZ write

clear       MOV #0x0100, R5					; Instrução para limpar o display LCD
	        CALL #send
	        MOV #0xFF10, R7					; R7 volta a apontar para o inicio da string
	        JMP write

lcd_begin   ; Rotina de inicialização do display LCD 16x2
			MOV #0x0203, R5
	        CALL #send
	        MOV #0x0203, R5
	        CALL #send
	        MOV #0x0203, R5
	        CALL #send

	        MOV #0x0802, R5
	        CALL #send
	        MOV #0x0600, R5
	        CALL #send

	        MOV #0x0C00, R5
	        CALL #send
	        MOV #0x0100, R5
	        CALL #send
	        RET

send     	; Rotina de envio de instruções para o displat LCD
			MOV.B R5, P2OUT
	        BIS.B #0x20, P2OUT
	        BIC.B #0x20, P2OUT
	        SWPB R5
	        MOV.B R5, P2OUT
	        BIS.B #0x20, P2OUT
	        BIC.B #0x20, P2OUT

			; Delay simulado com 2 contadores
	        MOV #2, R10
aux1        MOV #40000, R11
aux2        DEC R11
	        JNZ aux2
	        DEC R10
	        JNZ aux1

	        RET


timer_rti 	PUSH R5
			PUSH R7
			PUSH P2OUT
			PUSH P2DIR
			PUSH R10
			PUSH R11

			xor.b  #0x01, P1OUT        ;inverte o estado do pino P1.0

			CLR R5
			CLR R7

			POP R11
			POP R10
			POP P2DIR
			POP P2OUT
			POP R7
			POP R5

			reti
                                            
;-------------------------------------------------------------------------------
; Stack Pointer definition
;-------------------------------------------------------------------------------
            .global __STACK_END
            .sect   .stack
            
;-------------------------------------------------------------------------------
; Interrupt Vectors
;-------------------------------------------------------------------------------
            .sect   ".reset"                ; MSP430 RESET Vector
            .short  RESET
            
            .sect ".int09"
            .short timer_rti
