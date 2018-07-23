;---------------------------------------------
; Project - Alarm Clock
; Amilton de Camargo, Rafael Vargas - April 2014
; Perform an alarm clock functionality on the
; Dragon12 board.
;--------------------------------------------- 
 
  ABSENTRY ENTRY ; Application entry point 
  INCLUDE 'mc9s12dg256.inc' 
  
  ORG $FFF0; load RTI ISR vector
  
  dc.w RTI_ISR
  
  ORG $2000 ; Program data starts at RAM address $2000

; Variables

hour_0 dc.b $1 ; Clock start at 12 o'clock
hour_1 dc.b $2
minute_0 dc.b $0
minute_1 dc.b $0
full_hour dc.b $0C
full_minute dc.b $00
clock_am dc.b $1
a_hour_0 dc.b $0 ; Alarm start at 6 o'clock
a_hour_1 dc.b $6
a_minute_0 dc.b $0
a_minute_1 dc.b $0
a_full_hour dc.b $06
a_full_minute dc.b $00
alarm_system dc.b $1
alarm_am dc.b $1
colon dc.b $3A ; Colon to be shown
counter dc.b $0
sound_on dc.b $1
show_clock dc.b $1
rti_count dc.b $0
; Keypad lookup table
KCODE0 DC.B '123A' 
KCODE1 DC.B '456B' 
KCODE2 DC.B '789C' 
KCODE3 DC.B '*0#D'

  ORG $2500 ; Program code starts at RAM address $2500

ENTRY:
  
  LDS	#$3000 ; Initialize stack @ memory location $3000
  
  ; --- Hardware configuration ---
  
  ; Buzzer
  BSET DDRT,#%00100000; Configure PT5 pin for output
  ; LEDs
  MOVB #0,PORTB ; All LEDs off
	; 7 segment displays
	MOVB #$FF,DDRP ; Disable 7 segments that are connected
	MOVB #$0F,PTP ; Disable 7 segments that are connected
	; LCD
	JSR CONFIGLCD ; configure the LCD
	; Hide cursor
  LDAA #%00001100
  JSR CMD2LCD
  ; Timer interrupt
  BSET CRGINT,#$80 ; RTIE=1 (enables RTI interrupts)
  MOVB #$40,INTCR ; Enable IRQ interrupt and respond to low level
  CLI ; enable interrupt systems
  MOVB #$49,RTICTL ; Set the delay to 10.24ms
  
  
  ; ======= Main program start ========
  
  
  beginning:
  
  ; Read character from keypad to register A
  JSR keypad
  
  ; Jump to the specified procedure
  
  CMPA #$41
  LBEQ A_action
  
  CMPA #$2A
  LBEQ STAR_action
  
  CMPA #$23
  LBEQ HASH_action
  
  CMPA #$44
  LBEQ D_action
  
  CMPA #$43
  LBEQ C_action

  BRA beginning ; Start again




; ============ SUBROUTINES, INTERRUPTS AND PROCEDURES ==============



; === Procedure to do the action for button A ===
A_action:
  ; Toggle clock show
  LDAA show_clock
  CMPA #$1
  BEQ hide_clock
  
  LDAA #$1
  STAA show_clock
  BRA A_action_ending
  
  hide_clock:
  CLR show_clock
  
  A_action_ending:
  
  LBRA beginning ; Return to main program



; === Procedure to do the action for button * ===
STAR_action:
  
  ; Check if the alarm is been shown
  LDAA show_clock
  CMPA #$0
  LBEQ increment_hour_alarm
  
  ; --- Action to clock ---
  
  ; Increment the hour
  
  ; Load the first part
  LDAA hour_0
  LDAB #10
  MUL ; A:B = A * B
  ; Load the second part
  LDAA hour_1
  ABA ; A = A + B
  
  ; Get the new hour
  INCA ; A = A + 1
  
  ; Check if it is 13, and reset the value
  CMPA #13
  BEQ STAR_action_reset
  
  ; Store it
  STAA full_hour
  EXG A,D
  LDX #10
  IDIV ; X = D / X, D = remainder
  STAB hour_1
  EXG X,D
  LDX #10
  IDIV ; X = D / X, D = remainder
  STAB hour_0
  
  LBRA beginning ; Return to main program
  
  STAR_action_reset:
  CLR hour_0
  LDAA #$1
  STAA hour_1
  STAA full_hour
  JSR toggle_am_clock
  
  LBRA beginning ; Return to main program
  
  ; --- Action to alarm ---
  
  increment_hour_alarm:
  
  ; Increment the hour
  
  ; Load the first part
  LDAA a_hour_0
  LDAB #10
  MUL ; A:B = A * B
  ; Load the second part
  LDAA a_hour_1
  ABA ; A = A + B
  
  ; Get the new hour
  INCA ; A = A + 1
  
  ; Check if it is 13, and reset the value
  CMPA #13
  BEQ STAR_action_reset_alarm
  
  ; Store it
  STAA a_full_hour
  EXG A,D
  LDX #10
  IDIV ; X = D / X, D = remainder
  STAB a_hour_1
  EXG X,D
  LDX #10
  IDIV ; X = D / X, D = remainder
  STAB a_hour_0
  
  LBRA beginning ; Return to main program
  
  STAR_action_reset_alarm:
  CLR a_hour_0
  LDAA #$1
  STAA a_hour_1
  STAA a_full_hour
  JSR toggle_am_alarm
  
  LBRA beginning



; === Procedure to do the action for button # ===
HASH_action:
  
  ; Check if the alarm is been shown
  LDAA show_clock
  CMPA #$0
  LBEQ increment_minute_alarm
  
  ; --- Action to clock ---
  
  ; Increment the minute
  
  ; Load the first part
  LDAA minute_0
  LDAB #10
  MUL ; A:B = A * B
  ; Load the second part
  LDAA minute_1
  ABA ; A = A + B
  
  ; Get the new minute
  INCA ; A = A + 1
  
  ; Check if it is 60, and reset the value
  CMPA #60
  BEQ HASH_action_reset
  
  ; Store it
  STAA full_minute
  EXG A,D
  LDX #10
  IDIV ; X = D / X, D = remainder
  STAB minute_1
  EXG X,D
  LDX #10
  IDIV ; X = D / X, D = remainder
  STAB minute_0
  
  LBRA beginning ; Return to main program
  
  HASH_action_reset:
  CLR minute_0
  CLR minute_1
  CLR full_minute
  
  LBRA beginning ; Return to main program
  
  ; --- Action to alarm ---
  
  increment_minute_alarm:
  
  ; Increment the minute
  
  ; Load the first part
  LDAA a_minute_0
  LDAB #10
  MUL ; A:B = A * B
  ; Load the second part
  LDAA a_minute_1
  ABA ; A = A + B
  
  ; Get the new minute
  INCA ; A = A + 1
  
  ; Check if it is 60, and reset the value
  CMPA #60
  BEQ HASH_action_reset_alarm
  
  ; Store it
  STAA a_full_minute
  EXG A,D
  LDX #10
  IDIV ; X = D / X, D = remainder
  STAB a_minute_1
  EXG X,D
  LDX #10
  IDIV ; X = D / X, D = remainder
  STAB a_minute_0
  
  LBRA beginning ; Return to main program
  
  HASH_action_reset_alarm:
  CLR a_minute_0
  CLR a_minute_1
  CLR a_full_minute
  
  LBRA beginning ; Return to main program



; === Procedure to do the action for button D ===
D_action:
  ; Toggle buzzer sound enable
  LDAA sound_on
  CMPA #$1
  BEQ sound_off
  
  LDAA #$1
  STAA sound_on
  BRA D_action_ending
  
  sound_off:
  CLR sound_on
  
  D_action_ending:
  
  LBRA beginning ; Return to main program
  
  
  
; === Procedure to do the action for button C ===
C_action:
  ; Toggle on-off alarm system
  LDAA alarm_system
  CMPA #$1
  BEQ alarm_system_turn_off
  
  LDAA #$1
  STAA alarm_system
  BRA C_action_ending
  
  alarm_system_turn_off:
  CLR alarm_system
  
  C_action_ending:
  
  LBRA beginning ; Return to main program
  
  
  
; === Interruption based on RTI to run the clock in real time ===
  RTI_ISR:
    PSHX
    PSHY
    PSHA
    PSHB
    
    MOVB #$80,CRGFLG ; Clear RTIF by writing a 1 to it.
    INC rti_count
        
    ; Check the counter to increment the minutes
    LDAB counter
    CMPB #60
    LBEQ increment_minute
    
    clock_continue:
    
    LDAA rti_count
    CMPA #48 ; Check if was passed 0.5 sec
    LBNE clock_ending
    
    ; Clear the LCD
    JSR clear_LCD
    
    ; Increaser for the ASCII table
    LDAB #$30
    
    ; Check if the alarm has to be shown
    LDAA show_clock
    CMPA #$0
    BEQ show_alarm
    
    ; --- Show the clock --
    
    ; Put the hour
    LDAA hour_0
    ABA
    JSR PUTCLCD
    
    LDAA hour_1
    ABA
    JSR PUTCLCD
    
    ; Put the colon
    LDAA colon
    JSR PUTCLCD
    
    ; Swap the colon
    JSR swap_colon
    
    ; Put the minute
    LDAA minute_0
    ABA
    JSR PUTCLCD
    
    LDAA minute_1
    ABA
    JSR PUTCLCD
    
    ; Put AM/PM
    LDAA #$20
    JSR PUTCLCD
    
    LDAB clock_am
    CMPB #$1
    BEQ clock_am_show
    
    LDAA #$50 ; P
    JSR PUTCLCD
    LDAA #$4D ; M
    JSR PUTCLCD
    
    LBRA clock_ending
    
    clock_am_show:
    LDAA #$41 ; A
    JSR PUTCLCD
    LDAA #$4D ; M
    JSR PUTCLCD
    
    LBRA clock_ending
    
    ; --- Show the alarm ---
    
    show_alarm:
    
    ; Put the hour
    LDAA a_hour_0
    ABA
    JSR PUTCLCD
    
    LDAA a_hour_1
    ABA
    JSR PUTCLCD
    
    ; Put the colon
    LDAA #$3A
    JSR PUTCLCD
    
    ; Put the minute
    LDAA a_minute_0
    ABA
    JSR PUTCLCD
    
    LDAA a_minute_1
    ABA
    JSR PUTCLCD
    
    ; Put AM/PM
    LDAA #$20
    JSR PUTCLCD
    
    LDAB alarm_am
    CMPB #$1
    BEQ alarm_am_show
    
    LDAA #$50 ; P
    JSR PUTCLCD
    LDAA #$4D ; M
    JSR PUTCLCD
    BRA alarm_message
    
    alarm_am_show:
    LDAA #$41 ; A
    JSR PUTCLCD
    LDAA #$4D ; M
    JSR PUTCLCD
    
    alarm_message:
    
    ; Put the "Alarm" message on the second line
    LDAA #$C0
    JSR CMD2LCD
    
    LDAA #$41 ; A
    JSR PUTCLCD
    LDAA #$6C ; l
    JSR PUTCLCD
    LDAA #$61 ; a
    JSR PUTCLCD
    LDAA #$72 ; r
    JSR PUTCLCD
    LDAA #$6D ; m
    JSR PUTCLCD
    
    ; Show if it is on-off
    LDAA #$20
    JSR PUTCLCD
    
    LDAB alarm_system
    CMPB #$1
    BNE show_alarm_off
    
    LDAA #$4F ; O
    JSR PUTCLCD
    LDAA #$6E ; n
    JSR PUTCLCD
    BRA clock_ending
    
    show_alarm_off:
    LDAA #$4F ; O
    JSR PUTCLCD
    LDAA #$66 ; f
    JSR PUTCLCD
    LDAA #$66 ; f
    JSR PUTCLCD
    
    ; --- Final procedures ---
    
    clock_ending:
    
    LDAA rti_count
    CMPA #96 ; Check if was passed 1 sec
    BNE RTI_done ; If not, go to the end
    
    CLR rti_count ; If so, clear count
    INC counter ; Increment counter variable
    
    ; --- Turn buzzer on if it is time to alarm ---
    
    ; Check if the alarm system is enabled
    LDAA alarm_system
    CMPA #$1
    BNE RTI_done
    
    ; Check if the hour is the same
    LDAA full_hour
    LDAB a_full_hour
    SBA ; A = A - B
    BNE alarm_reset_sound
    ; Check if the minute is the same
    LDAA full_minute
    LDAB a_full_minute
    SBA ; A = A - B
    BNE alarm_reset_sound
    ; Check if the AM-PM is the same
    LDAA clock_am
    LDAB alarm_am
    SBA ; A = A - B
    BNE alarm_reset_sound
    ; Check if the user did not press to turn it off
    LDAA sound_on
    CMPA #$1
    BNE RTI_done
    
    ; Turn on the sound
    JSR alarm_sound
    
    ; Get ready for the next alarm
    alarm_reset_sound:
    LDAA #$1
    STAA sound_on
    
    ; End of the subroutine
    
    RTI_done:
    
    PULB
    PULA
    PULY
    PULX
    
    RTI


  
; === Subroutine to read a character from the keypad ===
keypad:
; Read one character from keypad and returns it in A 
  MOVB #$F0,DDRA ;Configure PA0-PA4 input as and PA5-PA7 output
  PSHY
  PSHB 
  ;; 1- If the user presses and holds a key down, this must be one press 

K1: 
  MOVB #%11110000,PORTA ;SET ROWS HIGH
  LDAA PORTA ;CAPTURE PORT A
  ANDA #%00001111 ;MASK OUT ROWS
  CMPA #$00 ;
  BNE K1  ;IF COLUMS IS ZERO NO BUTTON PRESSED
          ;DO NOT MOVE ON UNTILL NO BUTTON IS PRESSED

;; 2- Check if a switch is pressed

K2: 
  LDY 15
  JSR Delay_yms ; wait 15 ms
  LDAA PORTA ;
  ANDA #%00001111 ;
  CMPA #$00 ;IF COLS !=0 THEN A BUTTON IS PRESSED
  BEQ K2    ;IF NO BUTTON PRESSED KEEP CHECKING
  

;FOR DEBOUNCING, WAIT 15ms AND CHECK AGAIN
  LDY 15
  JSR Delay_yms
  LDAA PORTA ;READ PORT A
  ANDA #%00001111 ;MASK OUT ROWS
  CMPA #$00 ;CHECK FOR PRESS AFTER DEBOUNCE
  BEQ K2 ;IF NO PRESS AFTER DEBOUNCE GO BACK

; 3- A SWITCH IS PRESSED – FIND THE ROW

OVER1:

;;; Test Row 0
  LDAA #%00010000 ;MAKE HIGH ROW0 THE REST GROUNDED
  STAA PORTA ;
  LDAB #$08 ;SET COUNT TO PROVIDE SHORT DELAY FOR STABILITY
  
  ;AFTER CHANGING THE PORT A OUTPUT

P1: 
  
  DECB ;DECREMENT COUNT
  BNE P1 ;IF COUNT NOT ZERO KEEP DECREMENTING
  LDAA PORTA ;READ PORTA
  ANDA #%00001111 ;MASK OUT ROWS
  CMPA #$00 ;IS INPUT ZERO?
  BNE R0 ;IF COLUMS NOT ZERO THEN BUTTON IS IN ROW 0
  
;;; test Row 1
 
  LDAA #%00100000 ;IF ZERO THEN BUTTON NOT IN ROW0
  STAA PORTA ;TURN ON ROW 1 TURN OFF ALL OTHERS
  LDAB #$08 ;SHORT DELAY TO STABALIZE AFTER CHANGING THE PORT A OUTPUT

P2: 

  DECB ;DECREMENT COUNT
  BNE P2 ;IF COUNT NOT ZERO KEEP DECREMENTING
  LDAA PORTA ;READ PORT A
  ANDA #%00001111 ;MASK OUT ROWS
  CMPA #$00 ;CHECK FOR KEY PRESS
  BNE R1 ;IF PRESSED KEY IS IN ROW1

;; test Row 2 

  LDAA #%01000000 ;IF ZERO BUTTON NOT IN ROW1
  STAA PORTA ;TURN ON ROW2 ALL OTHERS OFF
  LDAB #$08 ;SHORT DELAY TO STABALIZE PORTA

P3: ;

  DECB ;DECREMENT COUNT
  BNE P3 ;DELAY LOOP 
  LDAA PORTA ;READ PORTA
  ANDA #%00001111 ;MASK OUT ROWS
  CMPA #$00 ;CHECK FOR PRESS
  BNE R2 ;IF FOUND KEY IS IN ROW2
  
;;;;; test Row 3

  LDAA #%10000000 ;IF ZERO MOVE TO ROW3
  STAA PORTA ;TURN ON ROW3 ALL OTHERS OFF
  LDAB #$08 ;SHORT DELAY TO STABALIZE OUTPUT
P4: ;
  DECB ;DECREMENT DELAY
  BNE P4 ;DELAY LOOP
  LDAA PORTA ;READ PORT A
  ANDA #%00001111 ;MASK OUT ROWS
  CMPA #$00 ;CHECK FOR PRESS
  BNE R3 ;IF FOUND KEY IN ROW3
  BRA K2 ;IF ROW NOT FOUND GO BACK TO START 
;; ---------------------------------------------------------

R0: 
  LDX #KCODE0 ;LOAD PONTER TO ROW0 ARRAY
  BRA FIND ;GO FIND COLUMN

R1:
  LDX #KCODE1 ;LOAD POINTER TO ROW1 ARRAY
  BRA FIND ;GO FIND COUMN

R2: 
  LDX #KCODE2 ;LOAD PINTER TO ROW2
  BRA FIND ;GO FIND COLUMN

R3:
  LDX #KCODE3 ;LOAD POINTER TO ROW3
  BRA FIND ;GO FIND COLUMN
  
FIND: ;We knew the row number. Now we need to know the column number to get the key ASCII
  ANDA #%00001111 ;MASK OUT ROWS A = 0000 0001 or A = 0000 0010 or A = 0000 0100 or A = 0000 1000

SHIFT: ;
  LSRA ;LOGICAL SHIFT RIGHT PORTA
  BCS MATCH ;IF CARY SET COLUM IS FOUND
  INX ;IF CARY NOT CLEAR INCREMENT POINTER TO ROW ARRAY
  BRA SHIFT ;SHIFT RIGHT UNTIL CARY IS CLEAR.

MATCH: ; X point at the address of key’s ASCII
  LDAA 0,X ;LOAD ASCII FROM look up table
  PULB
  PULY
  RTS ; end of keypad routine 
  
  
  
  ; === Subroutine to make a delay of Y ms ===
  Delay_yms:
    PSHX ; Push X in the stack
    outerloop:
      LDX #1000 ; Load #1000 to X
      innerloop:
        PSHA  ; 2 E cycles
        PULA  ; 3 E cycles
        PSHA  ; 2 E cycles
        PULA  ; 3 E cycles
        PSHA  ; 2 E cycles
        PULA  ; 3 E cycles
        PSHA  ; 2 E cycles
        PULA  ; 3 E cycles
        NOP   ; 1 E cycle
        NOP   ; 1 E cycle
        NOP   ; 1 E cycle
        NOP   ; 1 E cycle
      DBNE X,innerloop
    DBNE Y,outerloop 
    PULX ; Return original value to X
    RTS ; Return to the program



  ; === Subroutine that send a character to the LCD ===
  PUTCLCD:
  PSHA
  PSHA ;save a copy of the data in the stack
  ANDA #$F0 
; Clear the lower 4 bits – output the upper 4 bits first 
  LSRA ;match the upper 4 bits with the LCD
  LSRA 
; two shifts because the 4 bits should start from bit 2
  STAA PORTK
  BSET PORTK,#$01 ;RS=1 tell LCD you send data 
  BSET PORTK,#$02 ;EN = high
  NOP ; 3 NOP to extend the duration of EN
  NOP
  NOP
  BCLR PORTK,#$02 ;EN = low 
  PULA 
; repeat previous instructions to output the other 4 bits
  ANDA #$0F
  LSLA
  LSLA
  STAA PORTK
  BSET PORTK,#$01 ;RS=1 – we write data
  BSET PORTK,#$02 ;EN = high
  NOP
  NOP
  NOP
  BCLR PORTK,#$02 ;E = low to complete the write cycle
  LDY #$01 ;delay is needed until the LCD does all the internal
  JSR Delay_yms ;operations
  PULA
  RTS



; === Soubroutine that send a command to the LCD ===  
CMD2LCD:
  PSHA ;save a copy of the command in the stack
  ANDA #$F0 
; Clear the lower 4 bits – output the upper 4 bits first 
  LSRA ; match the upper 4 bits with the LCD
  LSRA 
; two shifts because the 4 bits should start from bit 2
  STAA PORTK
  BCLR PORTK,#$01 ;RS select LCD instruction register
  BSET PORTK,#$02 
;EN = high, 4bits of the command are sent with RS and EN 
  NOP ; 3 NOP to extend the duration of EN
  NOP
  NOP
  BCLR PORTK,#$02 ;EN = low 
  PULA 
; repeat previous instructions to output the other 4 bits
  ANDA #$0F
  LSLA
  LSLA
  STAA PORTK
  BCLR PORTK,#$01 ;RS select LCD data register
  BSET PORTK,#$02 ;EN = high
  NOP
  NOP
  NOP
  BCLR PORTK,#$02 ;E = low to complete the write cycle
  LDY #$01 ;delay is needed until the LCD does all the internal
  JSR Delay_yms ; operations
  RTS



; === Subroutine to configure initially the LCD ===
CONFIGLCD:
  PSHY
  PSHA
  MOVB #$FF,DDRK; configure port K for output
  LDY #$10
  JSR Delay_yms
  LDAA #$28 ; set 4 bit data LCD - two line display - 5x8 font
  JSR CMD2LCD 
  LDAA #$0E ; turn on display, turn on cursor , turn off blinking
  JSR CMD2LCD
  LDAA #$01 ; 
; clear display screen and return to home position
  JSR CMD2LCD 
  LDAA #$06 
;move cursor to right (entry mode set instruction) 
  JSR CMD2LCD 
  LDY #$02
  JSR Delay_yms
  PULA
  PULY
  RTS



; === Subroutine to display a string on the LCD ===
PUTSLCD: ; this subroutine displays the characters 
          ;starting from address pointed by X until it find 0 
  PSHA
NEXT: 
  LDAA 1,X+
  BEQ DONE
  JSR PUTCLCD 
  BRA NEXT
DONE: 
  PULA
  RTS


; === Subroutine that clear the LCD ===
clear_LCD:
  PSHA
  
  ; Return to the beginning of the second line
  LDAA #$C0
  JSR CMD2LCD
  ; Write spaces
  LDAA #$20
  JSR PUTCLCD
  JSR PUTCLCD
  JSR PUTCLCD
  JSR PUTCLCD
  JSR PUTCLCD
  JSR PUTCLCD
  JSR PUTCLCD
  JSR PUTCLCD
  JSR PUTCLCD
  JSR PUTCLCD
  JSR PUTCLCD
  JSR PUTCLCD
  
  ; Return to the beginning of the first line
  LDAA #$2
  JSR CMD2LCD
  ; Write spaces
  LDAA #$20
  JSR PUTCLCD
  JSR PUTCLCD
  JSR PUTCLCD
  JSR PUTCLCD
  JSR PUTCLCD
  JSR PUTCLCD
  JSR PUTCLCD
  JSR PUTCLCD
  JSR PUTCLCD
  JSR PUTCLCD
  JSR PUTCLCD
  JSR PUTCLCD
  
  ; Return to the beginning of the first line
  LDAA #$2
  JSR CMD2LCD
  
  PULA
  RTS


; === Subroutine that swap the colon to be shown ===
swap_colon:
  PSHA
  
  ; Compare the value
  LDAA colon
  CMPA #$3A
  BEQ colon_hide
  
  ; Show the colon
  LDAA #$3A
  STAA colon
  BRA swap_end
  
  ; Hide the colon
  colon_hide:
    LDAA #$20
    STAA colon
  
  swap_end:
  PULA
  RTS



; === Subroutine to toggle between AM-PM on the clock
toggle_am_clock:
  PSHA
  
  LDAA clock_am
  CMPA #$1
  BNE set_clock_am
  
  CLR clock_am
  BRA toggle_am_clock_end
  
  set_clock_am:
  LDAA #$1
  STAA clock_am
  
  toggle_am_clock_end:
  PULA
  RTS
  
  
  
; === Subroutine to toggle between AM-PM on the alarm
toggle_am_alarm:
  PSHA
  
  LDAA alarm_am
  CMPA #$1
  BNE set_alarm_am
  
  CLR alarm_am
  BRA toggle_am_alarm_end
  
  set_alarm_am:
  LDAA #$1
  STAA alarm_am
  
  toggle_am_alarm_end:
  PULA
  RTS  
  
  
  
; === Subroutine to make an alarm sound ===
  alarm_sound:
    PSHX ; Push X in the stack
    PSHY ; Push Y in the stack
    
    LDX #60
    tone: BSET PTT,#%00100000
    	LDY	#1
    	JSR	Delay_yms ; Wait 1 ms
    	BCLR PTT,#%00100000
    	LDY	#1
    	JSR	Delay_yms ; Wait 1 ms
    DBNE X,tone
    
    PULY ; Return original value to Y
    PULX ; Return original value to X
  RTS ; Return to the program
  
  
  
  ; === Procedure to increment the clock's minute ===
  increment_minute:
    ; Load the first part
    LDAA minute_0
    LDAB #10
    MUL ; A:B = A * B
    ; Load the second part
    LDAA minute_1
    ABA ; A = A + B
    
    ; Get the new minute
    INCA ; A = A + 1
    
    ; Check if it is 60, and jump to the hour change
    CMPA #60
    LBEQ increment_hour
    
    ; Store it
    STAA full_minute
    EXG A,D
    LDX #10
    IDIV ; X = D / X, D = remainder
    STAB minute_1
    EXG X,D
    LDX #10
    IDIV ; X = D / X, D = remainder
    STAB minute_0
    
    ; Reset the counter
    CLR counter
    
    LBRA clock_continue
    
    
    
  ; === Procedure to increment the clock's hour ===
  increment_hour:
    ; Load the first part
    LDAA hour_0
    LDAB #10
    MUL ; A:B = A * B
    ; Load the second part
    LDAA hour_1
    ABA ; A = A + B
    
    ; Get the new hour
    INCA ; A = A + 1
    
    ; Check if it is 13, and reset the values
    CMPA #13
    LBEQ reset_clock
    
    ; Store it
    STAA full_hour
    EXG A,D
    LDX #10
    IDIV ; X = D / X, D = remainder
    STAB hour_1
    EXG X,D
    LDX #10
    IDIV ; X = D / X, D = remainder
    STAB hour_0
    
    ; Reset the minute and counter
    CLR minute_0
    CLR minute_1
    CLR full_minute
    CLR counter
    JSR toggle_am_clock
    
    LBRA clock_continue
 
 
  
 ; === Procedure that reset the clock ===
 reset_clock:
    LDAA #1
    STAA hour_1
    STAA full_hour
    CLR hour_0
    CLR minute_0
    CLR minute_1
    CLR full_minute
    CLR counter
    JSR toggle_am_clock
    
    LBRA clock_continue
 
  
;-------End Project Alarm Clock----------