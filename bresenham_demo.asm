; **************************************************************
; BRESENHAM'S ALGORITHM FOR COMMODORE PLUS/4 ASSEMBLY
;
; TEEMU LEPPANEN (TJLEPP@GMAIL.COM), 29TH DEC 2019
;
; https://en.wikipedia.org/wiki/Bresenham%27s_line_algorithm#All_cases

; **************************************************************
; 10 SYS (5120)
;*=$1001
;    BYTE    $0E, $10, $0A, $00, $9E, $20, $28  
;    BYTE    $35, $31, $32, $30, $29, $00, $00, $00

; **************************************************************
; DEBUG

;WATCH X0
;WATCH Y0
;WATCH X1
;WATCH Y1
;WATCH OLDJX
;WATCH OLDJY

;WATCH DX
;WATCH DY
;WATCH SX
;WATCH SY
;WATCH ERR
;WATCH E2
;WATCH MASK

; **************************************************************
; VARIABLES

COLORMEM = $0800
COLORMEMLO = SETPIXEL+3
COLORMEMHI = SETPIXEL+4

KERNALKBLATCH   = $FF08
KERNALCURSORPOS = $FFF0

X0 = $1600  
Y0 = $1601
X1 = $1602
Y1 = $1603

DX   = $1604
DY   = $1605
SX   = $1606
SY   = $1607
ERR  = $1608
E2   = $1609
MASK = $160A

OLDJX = $160B
OLDJY = $160C

; **************************************************************
; MAIN PROGRAM
*=$1400
MAIN
    JSR CLEARSCREEN
    LDA #20
    STA X1
    STA OLDJX
    LDA #12
    STA Y1
    STA OLDJY
MAINLOOP
    JSR READJOY
    LDX #0  ; CHANGE NUM
CHECKX1
    LDA X1
    CMP OLDJX
    BEQ CHECKY1
    INX ; X1!=OLDJX
CHECKY1
    LDA Y1
    CMP OLDJY
    BEQ CHECKCHANGE
    INX ; Y1!=OLDJY
CHECKCHANGE
    CPX #0
    BEQ MAINLOOP    ; NO CHANGES
DRAWNEWLINES
    JSR CLEARCOLORMEM
    LDA #0
    STA X0
    STA Y0
    JSR BRESENHAM ; (0,0)-(X1,Y1)
    LDA #0
    STA X0
    LDA #24
    STA Y0
    JSR BRESENHAM ; (0,24)-(X1,Y1)
    LDA #39
    STA X0
    LDA #0
    STA Y0
    JSR BRESENHAM ; (39,0)-(X1,Y1)
    LDA #39
    STA X0
    LDA #24
    STA Y0
    JSR BRESENHAM ; (39,24)-(X1,Y1)
    LDA X1
    STA OLDJX   ; SAVE X1 FOR  NEXT LOOP
    LDA Y1
    STA OLDJY   ; SAVE Y1 FOR NEXT LOOP
    JMP MAINLOOP
;    RTS

; **************************************************************
READJOY
    LDA #$FA
    SEI
    STA KERNALKBLATCH
    LDA KERNALKBLATCH
    CLI
BIT0
    LSR A
    BCC BIT1
    INC Y1
BIT1
    LSR A
    BCC BIT2
    DEC Y1
BIT2
    LSR A
    BCC BIT3
    INC X1
BIT3
    LSR A
    BCC JOYEND
    DEC X1
JOYEND
    RTS

; **************************************************************
CLEARCOLORMEM
    LDX #0
    LDA #0    ; BLACK
CLEARCMPOS
    STA $0800,X
    STA $0900,X
    STA $0A00,X
    STA $0B00,X
    DEX
    BNE CLEARCMPOS
    RTS

; **************************************************************
CLEARSCREEN
    LDX #0
    LDA #160    ; INVERTED SPACE
CLEARSPOS
    STA $0C00,X
    STA $0D00,X
    STA $0E00,X
    STA $0F00,X
    DEX
    BNE CLEARSPOS
    RTS

; **************************************************************
*=$1500
BRESENHAM
    LDA #01
    STA SX  ; SX = 1
    STA SY  ; SY = 1
CALCDX
    LDA X1
    SEC
    SBC X0      
    BMI ABSPOS  ; A=X1-X0
    JMP SAVEDX
ABSPOS
    CLC
    TAX
    LDA #$FF
    STA MASK    
    TXA
    EOR MASK    ; A=A^MASK
    ADC #01     ; A=A+1
SAVEDX
    STA DX  ; DX = ABS(X1-X0)
CALCSX
    CLC
    LDA X1
    CMP X0      
    BMI SXNEG   ; A=X1-X0
    JMP CALCDY
SXNEG
    LDA #-01
    STA SX  ; SX = -1
CALCDY
    LDA Y1
    SEC
    SBC Y0      
    BPL ABSNEG ; A=Y1-Y0
    JMP SAVEDY
ABSNEG
    CLC
    TAX
    LDA #$FF
    STA MASK    ; MASK = 11111111
    TXA
    EOR MASK    ; A=A^MASK
    ADC #01     ; A=A+1
SAVEDY
    STA DY  ; DY = -ABS(Y1-Y0)
CALCSY
    CLC
    LDA Y1
    CMP Y0
    BMI SYNEG
    JMP CALCERR
SYNEG
    LDA #-01
    STA SY  ; SY = -1
CALCERR
    CLC
    LDA DX
    ADC DY
    STA ERR
WHILE_TRUE
    CLC
    LDX X0
    LDY Y0
    JSR PLOT ; PLOT(X0,YO)
CHECKX
    LDA X1
    CMP X0
    BEQ CHECKY  ; IF X0=X1
    JMP CALCE2
CHECKY
    LDA Y1
    CMP Y0
    BEQ ENDLINE ; IF Y0=Y1
CALCE2
    LDA ERR
    ASL A
    STA E2  ; E2=2*ERR
CMPDY
    LDA E2
    CMP DY
    BMI CMPDX   ; IF E2>=DY
    CLC
    LDA ERR
    ADC DY
    STA ERR     ; ERR+=DY
    CLC
    LDA X0
    ADC SX
    STA X0      ; X0+=SX
CMPDX
    LDA E2
    CMP DX
    BPL WHILE_TRUE  ; IF E2<=DX
    CLC
    LDA ERR
    ADC DX
    STA ERR     ; ERR+=DX
    CLC
    LDA Y0
    ADC SY
    STA Y0      ; Y0+=SY
    JMP WHILE_TRUE
ENDLINE
    RTS

; **************************************************************
; USES X,Y REGISTERS
PLOT
    CLC
    LDA COLORMEMLO  ; LSB
    ADC #40
    BCC NOINCHI
    INC COLORMEMHI  ; MSB
NOINCHI
    STA COLORMEMLO  ; LSB
    DEY
    BNE PLOT
SETPIXEL
    LDA #$73
    STA COLORMEM,X
SETORIGO
    LDA #0
    STA COLORMEMLO
    LDA #08
    STA COLORMEMHI
    RTS
