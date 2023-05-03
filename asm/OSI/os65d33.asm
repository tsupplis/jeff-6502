; This came from https://osi.marks-lab.com/reference/files/OS65D-disassembly.zip
;
;	DISASSEMBLY OF
;
;	OHIO SCIENTIFIC DOS OS-65D V3.3
;
;	FOR C2/4P
;
;	ADDR	TRK	SEC	PAGES
;	2200	0		8
;	2A00	1	1	8
;	3200	6	2	1
;	0000	6	3	1
;	3274	13	1	8
;

DISK	=	$C000	; DISK CONTROLLER (PIA = +$00, ACIA = +$10)
SCREEN	=	$D000	; SCREEN RAM
COLOR	=	$E000	; COLOR RAM
KEYBD	=	$DF00	; KEYBOARD
ACIA	=	$FC00	; 6850 ACIA ON CPU BOARD (C2/4P)
ACIAX	=	$CF00	; 6850 ACIA ON 550 BOARD (C2/4P)
UART	=	$FB03	; S1883 UART ON 550 BOARD (C2/4P)

LDC80	=	$DC80	;
LDE00	=	$DE00	;
LF400	=	$F400	; LINE PRINTER PORT (PIA?)
LF420	=	$F420	;
LF701	=	$F701	;
LFE01	=	$FE01	;

; FIRST 3 BYTES OF TRACK 0
;
;	.DBYTE	$2200	; LOAD ADDRESS
;	.BYTE	8	; #PAGES

	*=	$2200

L2200	LDA	#1	; TRACK 1
	STA	L265E	; SECTOR 1
	JSR	L26BC	; GO TRACK
	LDA	#>$2A00
	STA	$FF
	JSR	L2754	; LOAD HEAD
	STX	$FE	; X=0 ALWAYS
	JSR	L2967	; READ SECTOR
	JSR	L2E79

L2217	STX	LF400+1	; SEL DDRA
	STX	LF400	; ALL INPUTS
	STX	LF400+3	; SEL DDRB
	DEX		; $FF
	STX	KEYBD+1
	STX	LF400+2	; ALL OUTPUTS
	LDA	UART+3
	STX	UART+2
	LDA	#4
	STA	LF400+1	; SEL PORT A
	STA	LF400+3	; SEL PORT B

	STY	DISK+1	; SEL DDRA
	LDY	#$40	; SET PA6 AS OUTPUT
	STY	DISK
	STA	DISK+1	; SEL PORTA

L2240	LDA	#1
	JSR	L29C6	; SELECT DRIVE

; INIT ACIA ON CPU BOARD

L2245	LDA	#3	; RESET ACIA
	STA	ACIA
	LDY	#$11	; /16, 8BITS, 2STOP, RTS LOW
	STY	ACIA

; INIT ACIA ON 550 BOARD

	LDX	#$1E
L2251	STA	ACIAX,X
	TYA
	STA	ACIAX,X
	LDA	#3
	DEX
	DEX
	BPL	L2251

; CLEAR SCREEN

L225E	LDX	#8
	LDA	#>SCREEN
	STA	$FF
	LDY	#<SCREEN
	STY	$FE
	LDA	#' '
L226A	STA	($FE),Y
	INY
	BNE	L226A
	INC	$FF
	DEX
	BNE	L226A

	STX	0

; FIND TOP OF RAM

L2276	LDY	#$BF	; START AT BASIC ROM
L2278	JSR	L22EC
	BEQ	L2280
	DEY
	BNE	L2278
L2280	STY	L2300

; SET DEFAULT I/O DEVICE

	LDX	#1	; ACIA ON CPU BOARD
L2285	LDA	LFE01
	BEQ	L228B
	INX		; KEYBOARD/SCREEN
L228B	STX	L2AC5+1
	NOP
	LDX	#0
L2291	STX	LDC80
	JMP	L22B3

L2297	CPX	$F022
	CLC

	LDY	#$D7	; TEST RAM AT $D7XX
	JSR	L22EC
	BNE	L22B3	; NONE
	LDY	#0
L22A4	LDX	L22C7,Y
	BEQ	L22B3
	INY
	LDA	L22C7,Y
	STA	L2599,X
	INY
	BNE	L22A4

L22B3	JSR	L2D73

	.BYTE	$D,$A,'OS-65D V3.0',0

	JMP	L2AE6	; LOAD BASIC

; VIDEO PATCH TABLE

L22C7	.BYTE	$0B,64	; 25A4
	.BYTE	$8D,64	; 2626
	.BYTE	$91,64	; 262A
	.BYTE	$AF,64	; 2648
	.BYTE	$2D,128	; 25C6
	.BYTE	$9E,128	; 2637
	.BYTE	$A1,$D7	; 263A
	.BYTE	$2A,$D7	; 25C3
	.BYTE	$34,$D7	; 25CD
	.BYTE	$3C,$D7	; 25D5
	.BYTE	$8B,$D7	; 2624
	.BYTE	$97,$D7	; 2630
	.BYTE	$BA,$D7	; 2653
	.BYTE	$7D,$D7	; 2616
	.BYTE	$84,$D7	; 261D
	.BYTE	$80,$B1	; 2619
	.BYTE	$87,$AA	; 2620
	.BYTE	$31,$00	; 25CA
	.BYTE	0

; TEST FOR RAM AT PAGE (Y)

L22EC	STY	$FF
	LDA	($FE),Y
	AND	#$3F
	EOR	#$3F
	STA	($FE),Y
	STA	$FD
	LDA	($FE),Y
	AND	#$3F
	CMP	$FD
	RTS

	.BYTE	$24

L2300	.BYTE	0	; TOP OF RAM

; CHARACTER I/O DISPATCH TABLE

L2301	.WORD	L24F6-1	; INPUT - ACIA ON CPU BOARD
	.WORD	L252B-1 ; INPUT - KEYBOARD
	.WORD	L2518-1	; INPUT - UART ON 550 BOARD
	.WORD	L2386-1	; INPUT - NULL
	.WORD	L2389-1	; INPUT - MEMORY
	.WORD	L23A1-1	; INPUT - DISK BUFFER 1
	.WORD	L23F0-1	; INPUT - DISK BUFFER 2
	.WORD	L24B0-1	; INPUT - ACIA ON 550 BOARD

L2311	.WORD	L24CD-1	; OUTPUT - ACIA ON CPU BOARD
	.WORD	L2599-1 ; OUTPUT - SCREEN
	.WORD	L250D-1	; OUTPUT - UART ON 550 BOARD
	.WORD	L249F-1	; OUTPUT - LINE PRINTER
	.WORD	L2390-1	; OUTPUT - MEMORY
	.WORD	L23B2-1	; OUTPUT - DISK BUFFER 1
	.WORD	L2403-1	; OUTPUT - DISK BUFFER 2
	.WORD	L24BD-1	; OUTPUT - ACIA ON 550 BOARD

L2321	.BYTE	$10	; INPUT DEVICE(S)
L2322	.BYTE	0	; OUTPUT DEVICE(S)
L2323	.BYTE	0	; INDEX TO ACIA ON 550 BOARD
L2324	.BYTE	0	; RANDOM NUMBER SEED (INC BY KEYBOARD POLL)
L2325	.BYTE	0	; CHARACTER RECEIVED

; DISK BUFFER 1 PARAMETERS

L2326	.WORD	L3A7E		; BUFFER START
L2328	.WORD	L3A7E+$800	; BUFFER END + 1
L232A	.BYTE	$50		; FIRST TRACK
L232B	.BYTE	$51		; LAST TRACK
L232C	.BYTE	$50		; CURRENT TRACK
L232D	.BYTE	0		; DIRTY FLAG

; DISK BUFFER 2 PARAMETERS

L232E	.WORD	L3A7E+$800	; BUFFER START
L2330	.WORD	L3A7E+$1000	; BUFFER END + 1
L2332	.BYTE	$50		; FIRST TRACK
L2333	.BYTE	$51		; LAST TRACK
L2334	.BYTE	$50		; CURRENT TRACK
L2335	.BYTE	0		; DIRTY FLAG

; INPUT CHAR (A) FROM KEYBOARD

L2336	JMP	L2CD6

; INPUT CHAR (A) FROM DEVICE WITH ECHO

L2339	LDY	#0
	LDA	L2321
	BNE	L234B

; INPUT CHAR (A) FROM KEYBOARD WITH ECHO

L2340	JSR	L2336

; OUTPUT CHAR (A) TO DEVICE

L2343	JSR	L2367	; SAVE A,X,Y
L2346	JSR	L25A6
	LDY	#L2311-L2301 ;$10

L234B	LDX	#$FF
	BNE	L2371

L234F	INX
	LSR	A
	BCC	L235C
	PHA
	TXA
	PHA
	JSR	L2376
	PLA
	TAX
	PLA
L235C	BNE	L234F

L235E	LDX	#0	; MODIFIED
L2360	LDY	#0	; MODIFIED
L2362	LDA	#0	; MODIFIED
	AND	#$7F
	RTS

; POKE A,X,Y

L2367	STA	L2362+1
	STY	L2360+1
	STX	L235E+1
	RTS

L2371	STY	L2377+1
	BNE	L234F

L2376	ASL	A
L2377	ADC	#0	; MODIFIED
	TAX
	LDA	L2301+1,X
	PHA
	LDA	L2301,X
	PHA
	LDA	L2362+1
	RTS

; INPUT - NULL DEVICE

L2386	LDA	#0
	RTS

; INPUT - MEMORY

L2389	LDA	L2E25	; MODIFIED (INITIALLY POINT TO 'RUN"BEXEC*')
	LDX	#0
	BEQ	L2395

; OUTPUT - MEMORY

L2390	STA	$8000	; MODIFIED
	LDX	#7
L2395	STA	L2362+1
	INC	L2389+1,X
L239B	BNE	L23A0
	INC	L2389+2,X
L23A0	RTS

; INPUT - DISK BUFFER 1

L23A1	LDY	#0
	JSR	L2466
	BNE	L23AB
	JSR	L23CC

L23AB	LDA	L317D+1	; MODIFIED
	LDX	#$22
	BNE	L2395

; OUTPUT - DISK BUFFER 1

L23B2	CMP	#$A
	BEQ	L23A0
	PHA
	LDY	#$17
	JSR	L2466
	BNE	L23C1
	JSR	L23CC
L23C1	PLA
L23C2	STA	L317D+1	; MODIFIED
	LDX	#$39
	STX	L232D
	BNE	L2395

L23CC	LDA	L232D
	BEQ	L23D6
	LDX	#0
	JSR	L2477

L23D6	LDA	L2326
	STA	L23AB+1
	STA	L23C2+1
	STA	$FE
	LDA	L2326+1
	STA	L23AB+2
	STA	L23C2+2
	STA	$FF
	LDX	#0
	BEQ	L2442

; INPUT - DISK BUFFER 2

L23F0	LDX	#8
	LDY	#$51
	JSR	L2468
	BNE	L23FC
	JSR	L2420

L23FC	LDA	L3D7E
	LDX	#$73
	BNE	L2395

; OUTPUT - DISK BUFFER 2

L2403	CMP	#$A
	BEQ	L2476
	PHA
	LDX	#8
	LDY	#$6A
	JSR	L2468
	BNE	L2414
	JSR	L2420
L2414	PLA
L2415	STA	L3D7E
	LDX	#$8C
	STX	L2335
	JMP	L2395

L2420	LDA	L2335
	BEQ	L242A
	LDX	#8
	JSR	L2477
L242A	LDA	L232E
	STA	L23FC+1
	STA	L2415+1
	STA	$FE
	LDA	L232E+1
	STA	L23FC+2
	STA	L2415+2
	STA	$FF
	LDX	#8
L2442	LDA	L232C,X
	CLC
	SED
	ADC	#1
	CLD
	STA	L232C,X
	JSR	L2453
	JMP	L2B1D

L2453	LDA	#0
	STA	L232D,X
	LDA	L232C,X
	CMP	L232B,X
	JSR	L2C8D
	INY
	BNE	L2491

	.BYTE	0
	.BYTE	0

L2466	LDX	#0

L2468	LDA	L23AB+1,Y
	CMP	L2328,X
	BNE	L2476
	LDA	L23AB+2,Y
	CMP	L2328+1,X
L2476	RTS

L2477	LDA	L2328+1,X
	SEC
	SBC	L2326+1,X
	STA	L265F
	LDA	L2326,X
	STA	$FE
	LDA	L2326+1,X
	STA	$FF
	JSR	L2453
	JMP	L27E1	; WRITE SECTOR

L2491	STY	L265E
	JMP	L2754	; LOAD HEAD

; RESET MEMORY INPUT/OUTPUT ADDRESS

L2497	LDA	#>$8000
	STA	L2389+2
	LDA	#<$8000
	RTS

; OUTPUT - LINE PRINTER

L249F	PHA
L24A0	LDA	LF400	; TEST PORT A BIT 0 (BUSY?)
	LSR	A
	BCS	L24A0
	PLA
	AND	#$7F	; 7 BITS ONLY
	STA	LF400+2	; OUTPUT PORT B
	LDA	LF420	; ??? (STROBE?)
	RTS

; INPUT - ACIA ON 550 BOARD

L24B0	LDX	L2323
	LDA	ACIAX,X
	LSR	A
	BCC	L24B0
	BCS	L2508

	.BYTE	0
	.BYTE	0

; OUTPUT - ACIA ON 550 BOARD

L24BD	PHA
L24BE	LDX	L2323
	LDA	ACIAX,X
	LSR	A
	LSR	A
	BCC	L24BE
	PLA
	STA	ACIAX+1,X
	RTS

; OUTPUT - ACIA ON CPU BOARD

L24CD	PHA
L24CE	LDA	ACIA
	LSR	A
	LSR	A
	BCC	L24CE
	PLA
	STA	ACIA+1	; OUTPUT
	PHA
	LDA	ACIA	; CHECK ACIA INPUT
	LSR	A
	BCC	L24F1	; NONE
	JSR	L24F6
	STA	L2325
	CMP	#$13	; CTRL-S (XOFF)
	BNE	L24F1
L24EA	JSR	L24F6
	CMP	#$11	; CTRL-Q (XON)
	BNE	L24EA
L24F1	PLA
	STA	L2362+1
	RTS

; INPUT - ACIA ON CPU BOARD

L24F6	LDA	ACIA
	INC	L2324
	LSR	A
	BCC	L24F6
	LDA	ACIA+1
	AND	#$7F
L2504	STA	L2362+1
	RTS

L2508	LDA	ACIAX+1,X
	BCS	L2504

; OUTPUT - UART ON 550 BOARD

L250D	PHA
L250E	LDA	UART+2
	BPL	L250E
	PLA
	STA	UART+1
	RTS

; INPUT - UART ON 550 BOARD

L2518	LDA	UART+2
	LSR	A
	BCC	L2518
	LDA	UART
	STA	UART+4
	STA	L2362+1
	RTS

L2528	JSR	L2544

; INPUT - KEYBOARD

L252B	JSR	L2644
L252E	INC	L2324
	JSR	L32CC
	BEQ	L252E
	STA	L2362+1
	JSR	L2644
	LDA	L2362+1
	RTS

L2540	STA	L2325
	PLA
L2544	JMP	L2504

L2547	JSR	L2644
	JMP	L2A51

;

L254D	CMP	#$5B
	BNE	L2562
	LDA	#>$8000
	STA	L2390+2
	LDA	#<$8000
	STA	L2390+1
	LDA	L2322
	ORA	#$10
	BNE	L2593

L2562	CMP	#$5D
	BNE	L2579
	JSR	L2346
	LDA	L2AC5+1
	STA	L2321
	LDA	L2322
	AND	#$EF
	STA	L2322
	LDA	#$5D

L2579	CMP	#$18
	BNE	L258A
	LDA	#$10
	STA	L2321
	JSR	L2497
	STA	L2389+1
	BCS	L2596
L258A	NOP
	NOP
	BNE	L2598
	LDA	L2322
	EOR	#8
L2593	STA	L2322
L2596	LDA	#0
L2598	RTS

; OUTPUT CHAR (L2362+1) TO SCREEN

L2599	LDA	L2362+1
	JMP	L32CF

	.BYTE	0,0

L25A1	AND	#$7F
	JMP	L2343

; GET OUTPUT DEVICES (A)

L25A6	JSR	L37DA
	PHA
	AND	#$8D	; 1000 1101
	BEQ	L25B3
	CMP	L2AC5+1
	BNE	L25B5
L25B3	PLA
	RTS

L25B5	LDA	#0	; MODIFIED
	BNE	L25B3
	LDY	L2362+1
	LDX	L31A9
L25BF	LDA	#0	; MODIFIED
	BNE	L2629
	CPY	#$C
	BEQ	L25FE
	CPY	#$A
	BNE	L25F5
	INC	L31AB
	CPX	L31AB
	BCS	L25B3
	BCC	L2601

	.BYTE	0
	.BYTE	0

; TEST KEYBOARD

L25D7	NOP
	NOP
	LDA	#1
	JSR	L263D
	BVC	L2643
	LDA	#8
	JSR	L263D
	BPL	L2643

; CTRL-S PRESSED

	LDA	L2362+1
	PHA
L25EB	JSR	L252B
	CMP	#$13	; CTRL-S
	BEQ	L25EB
	JMP	L2540

;

L25F5	CPY	#$1B
	BNE	L25B3
	DEC	L25BF+1
	BNE	L25B3
L25FE	INC	L31AB
L2601	TXA
	SEC
	SBC	L31AB
	SEC
	ADC	L31AA
	STA	L25B5+1
	TAX
	LDA	L235E+1
	LDY	L2360+1
	PHA
	LDA	#$A
L2617	JSR	L2343
	DEX
	BNE	L2617
	TXA
	STA	L25B5+1
	STA	L31AB
	PLA
	TAX
	JMP	L31A1

L2629	BMI	L2638
	TYA
	PHA
	LDY	#0
	SEC
L2630	SBC	#$A
	INY
	BCS	L2630
	JMP	L3180

L2638	JMP	L3193

	.BYTE	0
	.BYTE	0

L263D	STA	KEYBD
	BIT	KEYBD
L2643	RTS

L2644	LDX	#4-1
L2646	LDA	$213,X
	LDY	L2657,X
	STA	L2657,X
	TYA
	STA	$213,X
	DEX
	BPL	L2646
	RTS

L2657	.BYTE	$00
	.BYTE	$4C
	.BYTE	$CB
	.BYTE	$25

	.BYTE	$20
L265C	.BYTE	1	; DRIVE# (1-4)
L265D	.BYTE	0	; TRACK# (BCD $01-$39)
L265E	.BYTE	0	; SECTOR# TO READ/WRITE (1-8)
L265F	.BYTE	0	; #PAGES READ/TO WRITE (1-8)
L2660	.WORD	0	; MEMORY TO READ/WRITE
L2662	.BYTE	0	; TRACK# (1-39)

; HO	HOME

L2663	JSR	L268A	; STEP IN
	JSR	L2678	; WAIT
	STY	L265D	; 0
L266C	LDA	#2	; TEST 'TRK0'
	BIT	DISK
	BEQ	L2678	; AT TRACK 0
	JSR	L2C54
	BNE	L266C

L2678	LDX	#$C	; 12 MS

; DELAY 1 MS BY (X)

L267A	LDY	#$31	; ASSUMES 1 MHZ CLOCK
	JSR	L2707
	DEX
	BNE	L267A
L2682	RTS

; STEP OUT (TOWARDS TRK 0)

L2683	LDA	DISK+2
	ORA	#4	; SET 'DIR' HIGH
	BNE	L268F

; STEP IN (TOWARDS TRACK 39)

L268A	LDA	#$FB	; SET 'DIR' LOW
	AND	DISK+2
L268F	STA	DISK+2
	JSR	L2682
	AND	#$F7	; SET 'STEP' LOW
	JSR	L2719
	JSR	L270D
L269D	ORA	#8	; SET 'STEP' HIGH
	JSR	L2719
L26A2	LDX	#8	; 8 MS
	BNE	L267A

; GO TO TRACK (L2662) BINARY

L26A6	LDA	L2662
	SEC
	LDX	#$FF
L26AC	INX
	SBC	#$A
	BCS	L26AC
	ADC	#$A
	STA	$FA
	TXA
	ASL	A
	ASL	A
	ASL	A
	ASL	A
	ORA	$FA

; GO TO TRACK (A) BCD
; ASSUMES CURRENT TRACK IS L265D

L26BC	STA	$FA
	PHA
	BIT	L269D+1	; 0000 1000 ????
	BEQ	L26C8
	AND	#6	; 0000 0110
	BNE	L26CD
L26C8	PLA
	CMP	#$40
	BCC	L26D1
L26CD	LDA	#8	; ERROR 8
	BNE	L26DE

L26D1	LDA	L265C	; TEST DRIVE READY
	AND	#1
	TAY
	JSR	L29DA
	BCC	L26E1
	LDA	#6	; ERROR 6
L26DE	JMP	L2A4B

L26E1	LDA	$FA
	CMP	L265D
	BEQ	L270F
	BCS	L26F1
	JSR	L2683	; STEP OUT
	LDA	#$99
	BCC	L26F5
L26F1	JSR	L268A	; STEP IN
	TXA		; ALWAYS 0
L26F5	SED
	ADC	L265D
	STA	L265D
	CLD
	JMP	L26E1

; (X) = #PAGES * 8

L2700	LDA	$FA
	ASL	A
	ASL	A
	ASL	A
	TAX
	RTS

; DELAY (Y*20)+16 CYCLES

L2707	JSR	L239B	; 15
	DEY		; 2
	BNE	L2707	; 3

; SMALL DELAY

L270D	NOP		; 2
	RTS		; 6

L270F	LDY	#0
	RTS

	BCS	L2719
	LDA	#$40
L2716	ORA	DISK+2

; SET PIA PORTB

L2719	STA	DISK+2
	RTS

; WAIT FOR END OF INDEX PULSE

L271D	LDA	DISK	; WAIT INDEX PULSE START
	BMI	L271D
L2722	LDA	DISK	; WAIT INDEX PULSE END
	BPL	L2722
	RTS

; LOAD HEAD AND ...

L2728	JSR	L2754	; LOAD HEAD

; WAIT FOR END OF INDEX PULSE AND ...

L272B	JSR	L271D

; RESET DISK ACIA

L272E	LDA	#3	; RESET ACIA
	STA	DISK+$10
	LDA	#$58	; DIVIDE 1, 8E1, RTS HIGH
	STA	DISK+$10
	RTS

; READ BYTES TO ($FE) UNTIL EOT

L2739	JSR	L2728	; LOAD HEAD, INIT ACIA
L273C	LDA	DISK
	BPL	L2761	; INDEX PULSE=EOT
	LDA	DISK+$10
	LSR	A
	BCC	L273C
	LDA	DISK+$11
	STA	($FE),Y
	INY
	BNE	L273C
	INC	$FF
	JMP	L273C

; LOAD HEAD

L2754	LDA	#$7F	; 0111 1111
	AND	DISK+2
L2759	STA	DISK+2
	LDX	#$28	; 40 MS
	JMP	L267A

; UNLOAD HEAD

L2761	LDA	#$80

; MASK DISK PIA PORT B WITH (A)

L2763	ORA	DISK+2
	BNE	L2759

; FORMAT DISK (TRK 1-39)

L2768	LDA	#$39
	STA	$E5
	JSR	L2663	; GO TO TRACK 0
L276F	JSR	L2C83	; GO TO NEXT TRACK
	JSR	L277D
	LDA	L265D
L2778	CMP	#$39
	BNE	L276F
	RTS

; FORMAT CURRENT TRACK ($265D=TRK#)

L277D	LDA	#2	; TEST 'TRK0'
	BIT	DISK
	BNE	L2788
	LDA	#3	; ERROR 3
	BNE	L2791

L2788	LDA	#$20	; TEST 'WRPROT'
	BIT	DISK
	BNE	L2794
	LDA	#4	; ERROR 4
L2791	JMP	L2A4B

L2794	JSR	L2728	; LOAD HEAD, INIT ACIA
	LDA	#$FC	; SET 'WRITE' 'ERASE' LOW
	AND	DISK+2
	STA	DISK+2
	LDX	#$A	; 10 MS
	JSR	L267A
	LDX	#'C'	; PUT TRACK-ID
	JSR	L27C2
	LDX	#'W'
	JSR	L27C2
	LDX	L265D	; PUT TRACK#
	JSR	L27C2
	LDX	#'X'
	JSR	L27C2
L27B9	LDA	DISK	; WAIT INDEX PULSE START
	BMI	L27B9
	LDA	#$83	; SET HEADLOAD 'WRITE' 'ERASE' HIGH
	BNE	L2763

; WRITE CHAR (X) TO DISK

L27C2	LDA	DISK+$10
	LSR	A
	LSR	A
	BCC	L27C2
	STX	DISK+$11
	RTS

; READ CHAR (A) FROM DISK

L27CD	LDA	DISK+$10
	LSR	A
	BCC	L27CD
	LDA	DISK+$11
L27D6	RTS

; WRITE SECTOR TO DISK  (L2660)=ADDR, (L265F)=#PAGES

L27D7	LDA	L2660
	STA	$FE
	LDA	L2660+1
	STA	$FF

; WRITE SECTOR TO DISK  ($FE)=ADDR, (L265F)=#PAGES

L27E1	LDA	L265F
	BEQ	L27E8
	BPL	L27EC
L27E8	LDA	#$B	; ERROR B
L27EA	BNE	L2791

L27EC	CMP	#9	; MAX PAGES = 8
	BPL	L27E8
	LDA	#2
	BIT	DISK
	BEQ	L27D6	; AT TRACK 0
	LSR	A
	STA	$FA	; PREV SECTOR LENGTH = 1
	LDA	#$20	; TEST 'WRPROT'
	BIT	DISK
	BNE	L2805
	LDA	#4	; ERROR 4
	BNE	L27EA

L2805	LDA	#1
	STA	$F6
L2809	LDA	#3
	STA	$F8
	JSR	L28C4	; GO TO END PREV
	JSR	L289F	; 0.8 MS * PREV LENGTH
	LDA	#$FE	; SET 'WRITE' LOW
	AND	DISK+2
	STA	DISK+2
	LDX	#2	; 0.2 MS
	JSR	L28A2
	LDA	#$FF	; ?
	AND	DISK+2
	STA	DISK+2
	JSR	L289F	; 0.8 MS * PREV LENGTH
	LDX	#'v'	; WRITE SECTOR-ID
	JSR	L27C2
	LDX	L265E	; PUT SECTOR#
	JSR	L27C2
	LDX	L265F	; PUT #PAGES
	STX	$FD
	JSR	L27C2
	LDY	#0	; PUT DATA
L2840	LDA	($FE),Y
	TAX
	JSR	L27C2
	INY
	BNE	L2840
	INC	$FF
	DEC	$FD
	BNE	L2840
	LDX	#'G'	; PUT END SECTOR ID
	JSR	L27C2
	LDX	#'S'
	JSR	L27C2
	LDA	L265F
	ASL	A
	STA	$FD
	ASL	A
	ADC	$FD
	TAX		; 0.6 MS * CURRENT LENGTH
	JSR	L28A2
	LDA	DISK+2
	ORA	#1	; SET 'WRITE' HIGH
	STA	DISK+2
	LDX	#5	; 0.5 MS
	JSR	L28A2
	LDA	#2	; SET 'ERASE' HIGH
	JSR	L2716
L2878	CLC
	TXA
	ADC	$FF
	SEC
	SBC	L265F
	STA	$FF
	JSR	L2905	; VERIFY SECTOR
	BCS	L28AF
	DEC	$F8
	BNE	L2878
	DEC	$F6
	BMI	L289B
	TXA
	ADC	$FF
	SEC
	SBC	L265F
	STA	$FF
	JMP	L2809

L289B	LDA	#2	; ERROR 2
	BNE	L28C1

; DELAY 0.8 MS BY PREVIOUS SECTOR LENGTH

L289F	JSR	L2700

; DELAY (X) 0.1 MS

L28A2	LDA	L267A+1
L28A5	BIT	0
	SEC
	SBC	#5
	BCS	L28A5
	DEX
	BNE	L28A2
L28AF	RTS

; READ CHAR (A) FROM DISK
; NO PARITY TEST
; ERRORS 9

L28B0	LDA	DISK	; INDEX PULSE?
L28B3	BPL	L28BF
	LDA	DISK+$10
	LSR	A
	BCC	L28B0
	LDA	DISK+$11
	RTS

L28BF	LDA	#9	; ERROR 9
L28C1	JMP	L2A4B

; GO TO END OF PREVIOUS SECTOR (L265E)
; ERRORS 5,9,10

L28C4	JSR	L272B	; RESET ACIA
L28C7	JSR	L28B0	; WAIT FOR TRACK-ID
L28CA	CMP	#'C'
	BNE	L28C7
	JSR	L28B0
	CMP	#'W'
	BNE	L28CA
	JSR	L27CD	; GET TRACK#
	CMP	L265D	; MATCH?
	BEQ	L28E1
	LDA	#5	; ERROR 5
	BNE	L28C1
L28E1	JSR	L27CD	; SKIP NEXT
	DEC	L265E	; PREVIOUS SECTOR
	BEQ	L28FD
	LDA	#0
	STA	$F9
L28ED	JSR	L2998	; SCAN NEXT SECTOR
	BCC	L2901	; NOT FOUND
	LDA	L265E
	CMP	$F9
	BNE	L28ED
	CMP	$FB
	BNE	L2901
L28FD	INC	L265E
	RTS

L2901	LDA	#$A	; ERROR A
	BNE	L28C1

; READ/VERIFY SECTOR
; ONLY THE ACTUAL SECTOR DATA IS PARITY TESTED
; CY=0 ON ERROR

L2905	PHA
	JSR	L28C4	; GO TO END PREV
L2909	JSR	L28B0	; WAIT FOR SECTOR-ID
	CMP	#'v'
	BNE	L2909
	JSR	L27CD	; GET SECTOR#
	CMP	L265E	; MATCH?
	BEQ	L291B
	PLA
L2919	CLC
	RTS

L291B	JSR	L27CD	; GET #PAGES
	TAX
	STA	L265F
	LDY	#0
	PLA
	BEQ	L2943

; VERIFY WITH MEMORY ($FE)

L2927	LDA	DISK+$10
	LSR	A
	BCC	L2927
	LDA	DISK+$11
	BIT	DISK+$10
	BVS	L2919	; PARITY ERROR
	CMP	($FE),Y
	BNE	L2919	; COMPARE ERROR
	INY
	BNE	L2927
	INC	$FF
	DEX
	BNE	L2927
	SEC
	RTS

; READ TO MEMORY ($FE)

L2943	LDA	DISK+$10
	LSR	A
	BCC	L2943
	LDA	DISK+$11
	BIT	DISK+$10
	BVS	L2919	; PARITY ERROR
	STA	($FE),Y
	INY
	BNE	L2943
	INC	$FF
	DEX
	BNE	L2943
	SEC
	RTS

; READ SECTOR TO (L2660) WITH RETRY
; PAGES READ=(L265F)

L295D	LDA	L2660
	STA	$FE
	LDA	L2660+1
	STA	$FF

; READ SECTOR TO ($FE) WITH RETRY
; PAGES READ=(L265F)

L2967	LDA	#3	; RECAL COUNT
	STA	$F7
L296B	LDA	#7	; RETRY COUNT
	STA	$F8
L296F	LDA	#0
	JSR	L2905	; READ SECTOR
	BCC	L297A
	RTS

L2977	DEC	$FF
	INX
L297A	CPX	L265F
	BNE	L2977
	DEC	$F8
	BNE	L296F	; RETRY
	JSR	L2683	; STEP OUT
	JSR	L2678
	JSR	L268A	; STEP IN
	JSR	L2678
	DEC	$F7
	BPL	L296B	; RETRY
	LDA	#1	; ERROR 1
	JMP	L2A4B

; SCAN NEXT SECTOR
; $FB=SECTOR#, $FA=#PAGES, INC $F9
; NC=END OF TRACK

L2998	LDA	DISK	; WAIT FOR SECTOR-ID
	BPL	L29C4	; INDEX PULSE
	LDA	DISK+$10
	LSR	A
	BCC	L2998
	LDA	DISK+$11
	CMP	#'v'
	BNE	L2998
	JSR	L27CD	; GET SECTOR#
	STA	$FB
	JSR	L27CD	; GET #PAGES
	STA	$FA
	INC	$F9
	TAY
	LDX	#0
L29B9	JSR	L27CD	; SKIP DATA
	DEX
	BNE	L29B9
	DEY
	BNE	L29B9
	SEC
	RTS

; ERROR

L29C4	CLC
	RTS

; SELECT DRIVE (A) (1,2,3 ETC)

L29C6	STA	L265C
	ASL	A
	TAX
	AND	#2
	TAY
	LDA	L29EB-2,X
	STA	DISK
	LDA	L29EB-1,X
	STA	DISK+2

; TEST IF DRIVE (Y) READY

L29DA	LDA	DISK
	LSR	A
	PHP
	CPY	#0
	BNE	L29E9
	PLP
	LSR	A
	LSR	A
	LSR	A
	LSR	A
	RTS

L29E9	PLP
	RTS

; DRIVE SELECT DATA FOR PIA

L29EB	.BYTE	$40,$FF
	.BYTE	$00,$FF
	.BYTE	$40,$DF
	.BYTE	$00,$DF

; DISPLAY ALL SECTORS ON TRACK (A)

L29F3	TAX
	BEQ	L29C4	; ERROR IF TRACK 0
	PHA
	JSR	L26BC	; GO TRACK
	JSR	L2D73

	.BYTE	$D,$A,'TRACK ',0

	PLA
	JSR	L2D92	; PRINT BCD
	TSX
	STX	$FC	; SAVE STACK
	JSR	L2754	; LOAD HEAD
	INX
	STX	L265E	; START SECTOR=1
	JSR	L28C4	; GO TO END PREV
	LDA	#0
	STA	$F9	; COUNTER
L2A1B	JSR	L2998	; SCAN NEXT SECTOR
	LDA	$FB	; SEC#
	PHA
	LDA	$FA	; #PAGES
	PHA
	BCS	L2A1B	; OK
	LDX	$FC
	BCC	L2A37	; NOT FOUND
L2A2A	JSR	L2D6A	; CRLF
	LDA	#' '
	JSR	L2A41
	LDA	#'-'
	JSR	L2A41
L2A37	DEC	$F9
	BPL	L2A2A
	LDX	$FC
	TXS
	JMP	L2761	; UNLOAD HEAD

L2A41	JSR	L2343
	LDA	$100,X
	DEX
	JMP	L2D92	; PRINT BCD

; ERROR HANDLER (A)

L2A4B	JSR	L2AC4	; DISPLAY ERROR#
L2A4E	JMP	L2A51	; DEFAULT ACTION - MODIFIED

; RETURN TO DOS COMMAND PROMPT

L2A51	LDX	#$28	; RESET STACK
	TXS
	LDA	#<L2A51
	LDY	#>L2A51
	JSR	L2A7D
	JSR	L2D6A	; CRLF
	LDA	L265C	; DRIVE#
	CLC
	ADC	#$40
	JSR	L2343
	LDA	#'*'	; PROMPT
	JSR	L2343
	JSR	L2C9B	; GET INPUT
	LDA	#>L2E1E
	STA	$E2
	LDA	#<L2E1E
	STA	$E1
	JSR	L2A84
	JMP	L2A51

; SET ERROR HANDLER (AY)

L2A7D	STA	L2A4E+1
	STY	L2A4E+2
	RTS

; PROCESS DOS COMMAND

L2A84	LDX	#0
	STX	L2CE4+1
L2A89	LDY	#0
	LDA	L2E30,X ; NEXT CHAR
	BEQ	L2AC0	; END
	JSR	L3732
	NOP
	INY
	LDA	L2E30+1,X
	JSR	L3732
	NOP
	LDA	L2E30+3,X
	PHA
	LDA	L2E30+2,X
	PHA
L2AA4	JSR	L2CE4
	CMP	#$D
	BEQ	L2AB9
	CMP	#' '
	BNE	L2AA4
L2AAF	JSR	L2CE4
	CMP	#' '
	BEQ	L2AAF
	DEC	L2CE4+1
L2AB9	RTS

L2ABA	INX
	INX
	INX
	INX
	BNE	L2A89

; D9

L2AC0	LDA	#7	; ERROR 7
	BNE	L2A4B

; PRINT ERROR NUMBER

L2AC4	PHA
L2AC5	LDA	#1	; DEFAULT I/O DEVICE - MODIFIED
	STA	L2321
	STA	L2322
	JSR	L2D73

	.BYTE	' ERR #',0

	PLA
	JSR	L2D9B
L2ADB	JMP	L2761	; UNLOAD HEAD

; AS	ASSEMBLER

L2ADE	LDA	#7	; TRACK 7
	JSR	L2AEE
	JMP	$1300

; BA	BASIC

L2AE6	LDA	#2	; TRACK 2
	JSR	L2AEE
	JMP	$20E4

L2AEE	JSR	L26BC	; GO TRACK
	LDX	#2
	STX	$E0
	STX	$FF	; >$0200
	DEX
	STX	L265E	; SECTOR 1
	DEX
	STX	$FE	; <$0200
	DEX
	STX	$E5
	JSR	L3179
L2B04	JSR	L2967	; READ SEC
	DEC	$E0
	BMI	L2B20
	JSR	L2C83	; GO TO NEXT TRACK
	JMP	L2B04

; CA	CALL

L2B11	JSR	L2D23
	JSR	L2D58
	JSR	L2C60

; READ SECTOR (L265E) TO ($FE) FROM
; CURRENTLY POSITIONED TRACK

L2B1A	JSR	L2754	; LOAD HEAD
L2B1D	JSR	L2967	; READ SECTOR
L2B20	JMP	L2761	; UNLOAD HEAD

L2B23	LDA	#0
	STA	L28B3+1
	RTS

; DI	DIRECTORY

L2B29	JSR	L2D2E
	JMP	L29F3

; EM	EXTENDED MONITOR

L2B2F	LDA	#7
	JSR	L2AEE
	JMP	$1700

; EX	EXAMINE

L2B37	JSR	L2D23
	JSR	L2D58
	JSR	L2D2E
	JSR	L26BC	; GO TRACK
	JMP	L2739

; GO

L2B46	JSR	L2D2E
	STA	L2B52+2
	JSR	L2D2E
	STA	L2B52+1
L2B52	JMP	$FFFF	; MODIFIED

; IN	INIT DISK

L2B55	JSR	L2CE4
	CMP	#$D
	BEQ	L2B68
	DEC	L2CE4+1
	JSR	L2D2E
	JSR	L26BC	; GO TRACK
	JMP	L277D

L2B68	JSR	L2D73

	.BYTE	'ARE YOU SURE?',0

	JSR	L2340
	CMP	#'Y'
	BNE	L2BA6
	JMP	L2768	; FORMAT

; IO	INPUT/OUTPUT

L2B83	JSR	L2CE4
	CMP	#','
	BEQ	L2BA0
	DEC	L2CE4+1
	JSR	L2D2E
	STA	L2321
	JSR	L2CE4
	CMP	#$D
	BEQ	L2BA6
	DEC	L2CE4+1
	JSR	L2D5B

L2BA0	JSR	L2D2E
	STA	L2322
L2BA6	RTS

; LO	LOAD

L2BA7	JSR	L2DA6
	JSR	L2C70
	STX	$E0
	BEQ	L2BB4
L2BB1	JSR	L2C83	; GO TO NEXT TRACK
L2BB4	JSR	L2967	; READ SEC
	INC	$E0
	DEC	L3A7D
	BNE	L2BB1
	LDA	$E0
	STA	L3A7D
	JMP	L327B

; ME	MEM

L2BC6	LDX	#0
	JSR	L2BD0
	JSR	L2D5B
	LDX	#7
L2BD0	JSR	L2D2E
	STA	L2389+2,X
	JSR	L2D2E
	STA	L2389+1,X
	RTS

; PU	PUT

L2BDD	JSR	L2DA6
	JSR	L2C70
	LDA	L3A7D
	STA	$E0
	LDA	#8
	JSR	L3274

L2BED	JSR	L27E1	; WRITE SECTOR
	DEC	$E0
	BEQ	L2BFA
	JSR	L2C83	; GO TO NEXT TRACK
	JMP	L2BED

L2BFA	JMP	$9C

; RE	RETURN

L2BFD	JSR	L2CE4
	CMP	#'A'	; ASSEMBLER
	BNE	L2C07
L2C04	JMP	$1303

L2C07	CMP	#'B'	; BASIC
	BNE	L2C0E
L2C0B	JMP	L2AC0

L2C0E	CMP	#'E'	; EXT MONITOR
	BNE	L2C15
L2C12	JMP	$1700

L2C15	CMP	#'M'	; MONITOR
	BNE	L2C1F
	JSR	L2644
	JMP	($FEFC)

L2C1F	JMP	L2AC0

; XQ	EXECUTE

L2C22	JSR	L2BA7
	JMP	L3A7E

; SA	SAVE

L2C28	JSR	L2C60
	JSR	L2D58
	JSR	L2D23
	JSR	L2D5E
	JSR	L2D3D
	STA	L265F
	JSR	L2754	; LOAD HEAD
	JSR	L27E1	; WRITE SECTOR
	JMP	L2761	; UNLOAD HEAD

; SE	SELECT DRIVE

L2C43	JSR	L2CE4
	SBC	#$3F
	CMP	#5
	BCS	L2C5B
	STA	$FD
	JSR	L29C6
	JMP	L2663

L2C54	JSR	L2683
	INC	$FD
	BNE	L2C6F

L2C5B	LDA	#6	; ERROR 6
L2C5D	JMP	L2A4B

L2C60	JSR	L2D2E
	JSR	L26BC	; GO TRACK
	JSR	L2D5B
	JSR	L2D3D
	STA	L265E
L2C6F	RTS

L2C70	JSR	L26BC	; GO TRACK
	LDA	#>L3A79
	STA	$FF
	LDA	#<L3A79
	STA	$FE
	LDA	#1	; SECTOR 1
	STA	L265E
	JMP	L2754	; LOAD HEAD

; GO TO NEXT TRACK

L2C83	LDA	L265D
	CLC
	SED
	ADC	#1
	CLD
	CMP	$E5
L2C8D	BEQ	L2C91
	BCS	L2C94
L2C91	JMP	L26BC	; GO TRACK

L2C94	LDA	#$D	; ERROR 13
	BNE	L2C5D

L2C98	JSR	L2D6A	; CRLF

; GET INPUT STRING TO BUFFER

L2C9B	LDA	#$11
	STA	L2CEC+1
	LDX	#0
L2CA2	JSR	L2340
	CMP	#$5F	; '_'
	BNE	L2CBC
	DEX
	BMI	L2C98
	STA	L2E1E,X
	JSR	L2D73

	.BYTE	8,8,'  ',8,8,0

	JMP	L2CA2

L2CBC	CMP	#$15	; CTRL-U
	BEQ	L2C98

L2CC0	STA	L2E1E,X
	CMP	#$D
	BEQ	L2CD0
	INX
	CPX	#$11
	BNE	L2CA2
	LDA	#$D
	BNE	L2CC0

L2CD0	JMP	L2D6A	; CRLF

	.BYTE	0
	.BYTE	0
	.BYTE	0

L2CD6	JSR	L2367
L2CD9	JSR	L2339
	JSR	L254D
	BEQ	L2CD9
	JMP	L235E

; GET CHARACTER (A) FROM BUFFER

L2CE4	LDY	#$E	; MODIFIED
	LDA	($E1),Y
	JMP	L3A6A
	NOP
L2CEC	CPY	#$11	; MODIFIED
	BEQ	L2CF4
	INC	L2CE4+1
L2CF3	RTS

L2CF4	LDA	#$D
	RTS

; PAGE 0/1 SWAPOUT

L2CF7	PLA
	CLC
	ADC	#1
	STA	L2D20+1
	PLA
	ADC	#0
	STA	L2D20+2
	LDX	#0
L2D06	LDA	$100,X
	LDY	L3079,X
	STA	L3079,X
	TYA
	STA	$100,X
	LDA	0,X
	LDY	L2F79,X
	STA	L2F79,X
	STY	0,X
	INX
	BNE	L2D06
L2D20	JMP	$1324	; MODIFIED

; GET 4 DIGIT HEX NUMBER ($FE)

L2D23	JSR	L2D2E
	STA	$FF
	JSR	L2D2E
	STA	$FE
	RTS

; GET 2 DIGIT HEX NUMBER (A)

L2D2E	JSR	L2D3D
	ASL	A
	ASL	A
	ASL	A
	ASL	A
	STA	$E0
	JSR	L2D3D
	ORA	$E0
	RTS

; GET 1 DIGIT HEX NUMBER (A)

L2D3D	JSR	L2CE4
	SEC
	SBC	#'0'
	CMP	#$A
	BCC	L2D4F
	SBC	#$11
	CMP	#6
	BCS	L2D55
	ADC	#$A
L2D4F	RTS

L2D50	LDA	0
	BEQ	L2CF7
	RTS

L2D55	JMP	L2AC0

; GET CHARACTER...

L2D58	LDA	#'='

	.BYTE	$2C

L2D5B	LDA	#','

	.BYTE	$2C

L2D5E	LDA	#'/'
	STA	$E0
	JSR	L2CE4
	CMP	$E0
	BNE	L2D55
	RTS

; OUTPUT CRLF

L2D6A	LDA	#$D
	JSR	L2343
	LDA	#$A
	BNE	L2DA3

; OUTPUT IN-LINE STRING

L2D73	PLA
	STA	$E3
	PLA
	STA	$E4
	LDY	#1
L2D7B	LDA	($E3),Y
	BEQ	L2D85
	JSR	L2343
	INY
	BNE	L2D7B
L2D85	TYA
	SEC
	ADC	$E3
	STA	$E3
	BCC	L2D8F
	INC	$E4
L2D8F	JMP	($E3)

; OUTPUT BCD NUMBER (A)

L2D92	PHA
	LSR	A
	LSR	A
	LSR	A
	LSR	A
	JSR	L2D9B
	PLA
L2D9B	AND	#$F
	CMP	#$A
	SED
	ADC	#'0'
	CLD
L2DA3	JMP	L2343

;

L2DA6	LDA	#$39 ; '9'
	STA	$E5
	JSR	L2CE4
	DEC	L2CE4+1
	CMP	#$41 ; 'A'
	BPL	L2DBE
	LDX	#0
	LDA	#$39 ; '9'
	STA	L2E79+1,X
	JMP	L2D2E

L2DBE	LDA	L2CE4+1
	STA	$E0
	LDA	#$12
	JSR	L26BC	; GO TRACK
	STY	L265E
	JMP	L2E00

L2DCE	LDX	#0
L2DD0	JSR	L2CE4
	CMP	#$D
	BNE	L2DD9
	LDA	#$20 ; ' '
L2DD9	JSR	L373C
	BNE	L2DEF
	INX
	TXA
	AND	#7
	CMP	#6
	BNE	L2DD0
	LDA	L2E79+1,X
	STA	$E5
	LDA	L2E79,X
	RTS

L2DEF	TXA
	AND	#$F8
	CLC
	ADC	#8
	TAX
	BEQ	L2E00
L2DF8	LDA	$E0
	STA	L2CE4+1
	JMP	L2DD0

L2E00	INC	L265E
	LDA	L265E
	CMP	#3
	BMI	L2E0F
	LDA	#$C	; ERROR C
	JMP	L2A4B

L2E0F	LDA	#<L2E79	; LOAD ADR
	STA	$FE
	LDA	#>L2E79
	STA	$FF
	JSR	L2B1A	; READ SECTOR
	LDX	#0
	BEQ	L2DF8

; INPUT BUFFER

L2E1E	.BYTE	$D,0,0,0,0,0,0
L2E25	.BYTE	'RUN"BEXEC*',$D

L2E30	.BYTE	'AS'
	.WORD	L2ADE-1
	.BYTE	'BA'
	.WORD	L2AE6-1
	.BYTE	'CA'
	.WORD	L2B11-1
	.BYTE	'D9'
	.WORD	L2AC0-1
	.BYTE	'DI'
	.WORD	L2B29-1
	.BYTE	'EM'
	.WORD	L2B2F-1
	.BYTE	'EX'
	.WORD	L2B37-1
	.BYTE	'GO'
	.WORD	L2B46-1
	.BYTE	'HO'
	.WORD	L2663-1
	.BYTE	'IN'
	.WORD	L2B55-1
	.BYTE	'IO'
	.WORD	L2B83-1
	.BYTE	'LO'
	.WORD	L2BA7-1
	.BYTE	'ME'
	.WORD	L2BC6-1
	.BYTE	'PU'
	.WORD	L2BDD-1
	.BYTE	'RE'
	.WORD	L2BFD-1
	.BYTE	'XQ'
	.WORD	L2C22-1
	.BYTE	'SA'
	.WORD	L2C28-1
	.BYTE	'SE'
	.WORD	L2C43-1
	.BYTE	0

; TEMP BUFFER (1 PAGE)

L2E79	INC	L265E	; SEC 2
	LDA	#6
	JSR	L26BC	; GO TRACK
	JSR	L2EB8

L2E84	LDA	#$34
	STA	LF701
	LDX	#0
	LDY	#0
L2E8D	INX
	BEQ	L2EB0
L2E90	INY
	BEQ	L2E8D
	LDA	LDE00
	BMI	L2E90

	LDY	#1
L2E9A	LDA	LDE00
	BPL	L2E9A
L2E9F	INY
	BEQ	L2EB0
	LDX	#$1F
L2EA4	DEX
	BNE	L2EA4
	LDA	0
	LDA	LDE00
	BMI	L2E9F
	BPL	L2EB2

L2EB0	LDY	#$31
L2EB2	STY	L267A+1
	LDY	#0
	RTS

;

L2EB8	JSR	L2967	; READ SEC
	INC	L265E	; SEC 3
	LDA	#0
	STA	$FE
	STA	$FF
	JSR	L2967	; READ SEC
	LDA	#1
	STA	L265E	; SEC 1
	LDA	#$13
	JSR	L26BC	; GO TRACK
	LDA	#>L3274
	STA	$FF
	LDA	#<L3274
	STA	$FE
	JMP	L2B1A

	.BYTE	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.BYTE	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.BYTE	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.BYTE	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.BYTE	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.BYTE	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.BYTE	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.BYTE	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.BYTE	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.BYTE	0,0,0,0,0,0,0,0,0,0,0,0,0

; PAGE 0 BUFFER

L2F79	.BYTE	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.BYTE	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.BYTE	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.BYTE	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.BYTE	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.BYTE	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.BYTE	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.BYTE	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.BYTE	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.BYTE	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.BYTE	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.BYTE	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.BYTE	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.BYTE	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.BYTE	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.BYTE	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

; PAGE 1 BUFFER

L3079	.BYTE	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.BYTE	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.BYTE	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.BYTE	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.BYTE	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.BYTE	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.BYTE	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.BYTE	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.BYTE	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.BYTE	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.BYTE	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.BYTE	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.BYTE	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.BYTE	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.BYTE	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.BYTE	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

L3179	LDA	#4
	STA	$E0
L317D	JMP	L2754	; LOAD HEAD

L3180	STY	L31AA
	PLA
	SEC
	SBC	L31AA
	STA	L31A9
	STA	L31AB
	DEC	L25BF+1
	BPL	L31A1

L3193	INC	L25BF+1
	CPY	#$50 ; 'P'
	BEQ	L31AC
	CPY	#$43 ; 'C'
	BNE	L31A6
	INC	L25BF+1

L31A1	LDA	#0
	STA	L2362+1

L31A6	JMP	L25B3

L31A9	.BYTE	$41
L31AA	.BYTE	1
L31AB	.BYTE	0

L31AC	INC	L25B5+1
	LDA	L235E+1
	PHA
	LDA	L2360+1
	PHA
	LDA	#0
	JSR	L2343
	JSR	L31CD
	PLA
	STA	L2360+1
	PLA
	STA	L235E+1
	DEC	L25B5+1
	JMP	L31A1

L31CD	JSR	L3233
	JSR	L32FC
	JSR	L3321
	LDA	#$AF
	LDX	#$DF
	JSR	L324C
	STY	$E6
L31DF	JSR	L3268
	INC	$E6
	LDX	$E6
	JSR	L3330
	LDY	#0
L31EB	LDA	($E2),Y
	LDX	#8-1
L31EF	CMP	L323C,X
	BEQ	L3202
	DEX
	BPL	L31EF
	CMP	#$7F
	BCS	L31FF
	CMP	#$20 ; ' '
	BCS	L3212
L31FF	LDA	#$20 ; ' '
	INX
L3202	LDA	($E0),Y
	AND	#1
	CMP	L3244,X
	BEQ	L320F
	TXA
	EOR	#$F
	TAX
L320F	TXA
	ORA	#$A0
L3212	JSR	L2343
	CPY	$F5
	INY
	BCC	L31EB
	JSR	L3268
	JSR	L3263
	LDA	$E6
	CMP	$F4
	BCC	L31DF
	LDA	#$AF
	LDX	#$AC
	JSR	L324C
	JSR	L331E
	JSR	L3305
L3233	JSR	L2D73

	.BYTE	$D,$A,$A,$A,0

	RTS

L323C	.BYTE	$20,$A8,$A6,$9A,$A7,$9D,$AA,$A5

L3244	.BYTE	0,0,0,1,0,1,0,1

;

L324C	PHA
	JSR	L3263	; CR
	TXA
	JSR	L2343	;
	PLA
	LDY	$F5	; COLS-1
L3257	ORA	#$80
	JSR	L2343
	DEY
	BPL	L3257
	TXA
	JSR	L2343

; OUTPUT CR

L3263	LDA	#$D
	JMP	L2343

; OUTPUT ?

L3268	LDA	#$DC
	JMP	L2343

	.BYTE	$43
	.BYTE	$23
	.BYTE	$20
	.BYTE	$3B
	.BYTE	$D
	.BYTE	$DA
	.BYTE	$20

; DATA FROM TRACK 13 SECTOR 1 STARTS AT $3274

L3274	JSR	$00AC
	LDX	#$F8
	BNE	L3280

L327B	JSR	L2761	; UNLOAD HEAD
	LDX	#8
L3280	LDA	$FE
	PHA
	LDA	$FF
	PHA
	LDA	#<L3A79
	STA	$FE
	LDA	#>L3A79
	STA	$FF
	STX	L32C7+1
	LDY	#3
	JSR	L32C2
	LDY	#1
	JSR	L32C2
	LDA	$200
	CMP	#$29 ; ')'
	BNE	L32BB

L32A2	LDY	#0
	LDA	($FE),Y
	INY
	TAX
	LDA	($FE),Y
	STX	$FE
	LDX	L32C7+1
	BPL	L32B4
	CLC
	ADC	#8
L32B4	STA	$FF
	JSR	L32C2
	BNE	L32A2

L32BB	PLA
	STA	$FF
	PLA
	STA	$FE
	RTS

L32C2	LDA	($FE),Y
	BEQ	L32CB
	CLC
L32C7	ADC	#9	; MODIFIED
	STA	($FE),Y
L32CB	RTS

; KEYBOARD INPUT

L32CC	JMP	L3590

L32CF	JSR	L33C0
	JMP	L25D7

; BLOCK SWAP STORAGE

L32D5	.BYTE	$00,$00,$00,$00,$FF,$0D,$00,$00
	.BYTE	$00,$00,$00,$00,$15,$AB,$0E,$20
	.BYTE	$00,$00,$06,$3F,$17,$3F,$00,$D1

L32ED	.BYTE	0	; TEMP
L32EE	.BYTE	0	; TEMP
L32EF	.BYTE	0	; TEMP

; 32X32

L32F0	.BYTE	6		; $F2
	.BYTE	64-1		; $F3
	.BYTE	24-1		; $F4 ROWS TO DISPLAY
	.BYTE	32-1		; $F5 COLS TO DISPLAY
	.BYTE	0		; $F6 COL START
	.BYTE	SCREEN+256/256	; $F7 ROW START

; 64X32

L32F6	.BYTE	6		; $F2
	.BYTE	64-1		; $F3
	.BYTE	24-1		; $F4 ROWS TO DISPLAY
	.BYTE	64-1		; $F5 COLS TO DISPLAY
	.BYTE	0		; $F6 COL START
	.BYTE	SCREEN+256/256	; $F7 ROW START

; BLOCK SWAP $E0-F7  (A,X,Y SAVED)

L32FC	STA	L32EF
	STX	L32ED
	STY	L32EE
L3305	LDX	#24-1
L3307	LDA	$E0,X
	LDY	L32D5,X
	STA	L32D5,X
	STY	$E0,X
	DEX
	BPL	L3307
	LDY	L32EE
	LDX	L32ED
	LDA	L32EF
	RTS

L331E	LDA	$ED
	.BYTE	$2C
L3321	LDA	$EF
	PHA
	JSR	L332E
	LDA	($E2),Y
	TAX
	PLA
	STA	($E2),Y
	RTS

L332E	LDX	$EB
L3330	LDA	#0
	STA	$E3
	TXA
	LDY	$F2
L3337	ASL	A
	ROL	$E3
	DEY
	BNE	L3337
	ADC	$F6
	STA	$E2
	STA	$E0
	LDA	$E3
	ADC	$F7
	STA	$E3
	ADC	#$10
	STA	$E1
	LDY	$EA
	RTS

L3350	LDA	#$FF
	PHA
	EOR	$F3
	PHA
	TXA
	TAY
	LDX	$F4
	BCS	L3367

L335C	LDA	#0
	PHA
	LDA	$F3
	ADC	#0
	PHA
	TXA
	LDY	$F4
L3367	STA	$E9
	PLA
	STA	$E6
	PLA
	STA	$E7
	TYA
	PHA
	TXA
	PHA
	JSR	L3330
	LDA	$E2
	STA	$E0
	LDA	$E3
	STA	$E1
	JSR	L339A
	PLA
	TAX
	JSR	L3330
	JSR	L339A
	PLA
	TAX
	JSR	L3330
	LDY	$F5
L3390	JSR	L357E
	DEY
	DEY
	BPL	L3390
	LDA	#0
	RTS

L339A	LDA	$F4
	SEC
	SBC	$E9
	TAX
	BEQ	L33BF
L33A2	LDA	$E0
	STA	$E2
	CLC
	ADC	$E6
	STA	$E0
	LDA	$E1
	STA	$E3
	ADC	$E7
	STA	$E1
	LDY	$F5
L33B5	LDA	($E0),Y
	STA	($E2),Y
	DEY
	BPL	L33B5
	DEX
	BNE	L33A2
L33BF	RTS

L33C0	PHA
	JSR	L32FC
L33C4	JSR	L3321
	PLA
	LDX	$E8
	BEQ	L33F4
	BPL	L33EC
	STA	$E9
	INC	$E8
	CMP	#2
	BEQ	L33E6
	CMP	#$1F
	BEQ	L33E8
	CMP	#$1D
	BEQ	L33E8
	CMP	#$11
	BEQ	L33E6
	CMP	#$16
	BNE	L3461
L33E6	INC	$E8
L33E8	INC	$E8
	BNE	L33FC
L33EC	STA	$E5,X
	DEC	$E8
	BNE	L33FC
	BEQ	L3461

L33F4	LDX	$E4
	BMI	L33FE
	BNE	L33FC
	DEC	$E4
L33FC	LDA	#0

L33FE	CMP	#$1B
	BNE	L3404
	DEC	$E8
L3404	LDX	$EB
	CMP	#8
	BNE	L3417
	DEY
	BPL	L3417
	DEX
	BPL	L3415
	INX
	JSR	L3350
	TAX
L3415	LDY	$F5
L3417	CMP	#$10
	BNE	L3424
	CPY	$F5
	BNE	L3423
	LDA	#$A
	LDY	#$FF
L3423	INY
L3424	CMP	#$D
	BNE	L342A

L3428	LDY	#0
L342A	CMP	#$A
	BNE	L343C
L342E	CPX	$F4
	BNE	L343B
	LDX	#0
	STY	$EA
	JSR	L335C
	BEQ	L3459

L343B	INX

L343C	CMP	#$E
	BNE	L3447
	INY
	TYA
	ORA	#7
	TAY
	BNE	L3475

L3447	STX	$EB
	STY	$EA
	CMP	#$20 ; ' '
	BCC	L3459
	STA	($E2),Y
	LDA	$EE
	STA	($E0),Y
	LDA	#$10
	BNE	L33F4

L3459	JSR	L331E
	STX	$EF
	JMP	L364B

L3461	LDA	$E9
	LDX	$EB

	CMP	#$12	;
	BNE	L346D
L3469	LDX	#0
	BEQ	L3428

L346D	CMP	#$11	;
	BNE	L3481
	LDX	$E6
	LDY	$E7

L3475	CPY	$F5
	BEQ	L347B
	BCS	L3459

L347B	CPX	$F4
	BEQ	L3447
	BCC	L3447

L3481	CMP	#$B	;
	BEQ	L342E

	CMP	#$C	;
	BNE	L348F
	DEX
	BPL	L3447
	INX
	LDA	#$1A

L348F	CMP	#$13	;
	BNE	L3496
	JSR	L335C

L3496	CMP	#$1A	;
	BNE	L349D
	JSR	L3350

L349D	CMP	#$1F	;
	BNE	L34A5
	LDX	$E6
	BCS	L34B3

L34A5	CMP	#1	;
	BNE	L34AD
	LDX	#0
	BCS	L34B3

L34AD	CMP	#$19	;
	BNE	L34B5
	LDX	#$E
L34B3	STX	$EE

L34B5	CMP	#5	;
	BNE	L34C7
	TYA
	ADC	#$40 ; '@'
	STA	$E7
	TXA
	ADC	#$41 ; 'A'
	STA	$E6
	LDA	#3
	BNE	L34D1

L34C7	CMP	#$21	;
	BNE	L34D5
	LDA	($E2),Y
	STA	$E6
	LDA	#2
L34D1	STA	$E4
	LDA	#0

L34D5	CMP	#$F	;
	BNE	L34DD
	LDX	$F4
	BCS	L34E1

L34DD	CMP	#$18	;
	BNE	L34F5
L34E1	CPY	$F5
	JSR	L357E
	BCC	L34E1
	INX
	JSR	L3330
	LDY	#0
	CPX	$F4
	BCC	L34E1
	BEQ	L34E1
	TYA

L34F5	CMP	#$16	;
	BNE	L3520
	CLC
	TXA
	ADC	$E6
	CMP	$F4
	BCS	L356F
	TYA
	ADC	$E7
	CMP	$F5
	BCS	L356F
	TYA
	ADC	$E2
	STA	$E2
	BCC	L3511
	INC	$E3
L3511	LDX	#1
L3513	LDA	$E2,X
	STA	$F6,X
	LDA	$E6,X
	STA	$F4,X
	DEX
	BPL	L3513
	BMI	L355E

L3520	CMP	#$14	; 32 COLUMN MODE
	BNE	L352A
	LDY	#4	; 32 COL, COLOR OFF, KBD TONE OFF
	LDX	#6-1
	BNE	L3532

L352A	CMP	#$15	; 64 COLUMN MODE
	BNE	L3545
	LDY	#5	; 64 COL, COLOR OFF, KBD TONE ON
	LDX	#12-1
L3532	STA	$EC
	STY	LDE00

	LDY	#6-1
L3539	LDA	L32F0,X
	STA	$F2,Y
	DEX
	DEY
	BPL	L3539
	LDA	#$1C

L3545	LDY	#0
	STY	$E2
	STY	$E0
	LDX	#>SCREEN
	STX	$E3
	LDX	#>COLOR
	STX	$E1
	LDX	#8

	CMP	#$1C	; CLEAR SCREEN/COLOR RAM
	BNE	L3561
L3559	JSR	L357E
	BNE	L3559
L355E	JMP	L3469

L3561	CMP	#2	;
	BEQ	L356A

	CMP	#$1D	;
	BNE	L356F
	CLC
L356A	JSR	L3572
	BNE	L356A

L356F	JMP	L3459

L3572	LDA	($E0),Y
	AND	#$F
	EOR	$E6
	BNE	L3586
	LDA	$E7
	BCS	L3584

L357E	LDA	#' '
	STA	($E2),Y
	LDA	#$E
L3584	STA	($E0),Y
L3586	INY
	BNE	L358E
	INC	$E3
	INC	$E1
	DEX
L358E	TXA
	RTS

; POLL KEYBOARD

L3590	JSR	L32FC
	LDX	$E4
	BMI	L359E
	DEC	$E4
	LDY	$E4,X
	JMP	L363B

L359E	INC	$F1
	LDA	$F1
	AND	#$F
	BNE	L35B2
	JSR	L331E
	LDA	$F1
	AND	#$10
	BNE	L35B2
	JSR	L3321

L35B2	LDX	#1
	JSR	L364E
	PHA
	INX
	LDY	#6
L35BB	JSR	L364E
	BNE	L35C9
	DEY
	TXA
	ASL	A
	TAX
	BCC	L35BB
	TAY
	BCS	L35E0

L35C9	PHA
	TYA
	ASL	A
	ASL	A
	ASL	A
	STA	L32EF
	PLA
	LDX	#$FF
L35D4	INX
	ASL	A
	BCC	L35D4
	TXA
	ADC	L32EF
	TAX
	LDY	L365D-1,X
L35E0	TYA
	BEQ	L3608
	PLA
	BMI	L35EE
	CPY	$F0
	BNE	L35EE
	LDY	#0
	BEQ	L363B

L35EE	PHA
	AND	#$20
	BEQ	L3608
	CPX	#$C
	BCS	L3608
	STY	$F0
	LDY	#$1B
	STY	L32EF
	PLA
	LDA	L3695-1,X
	DEC	$E8
	PHA
	JMP	L33C4

L3608	PLA
	STY	$F0
	CPY	#$D
	BEQ	L363B
	CPY	#$20 ; ' '
	BEQ	L363B
	CPY	#0
	BEQ	L363B
	PHA
	AND	#7
	LDX	#$20 ; ' '
	CPY	#0
	BPL	L3624
	AND	#6
	LDX	#$10
L3624	LSR	A
	BCC	L362C
	BEQ	L362E
	LDX	#$30 ; '0'
	.BYTE	$2C
L362C	BEQ	L3632
L362E	TXA
	EOR	$F0
	TAY
L3632	PLA
	AND	#$40
	BEQ	L363B
	TYA
	AND	#$1F
	TAY

L363B	LDX	#$10
L363D	DEC	L32EF
	BNE	L363D
	DEX
	BNE	L363D
	TYA
	AND	#$7F
	STA	L32EF
L364B	JMP	L3305

L364E	TXA
	EOR	#0
	STA	KEYBD
	STA	KEYBD
	LDA	KEYBD
	EOR	#0
	RTS

; KEYBOARD MATRIX

L365D	.BYTE	$B1,$B2,$B3,$B4,$B5,$B6,$B7
	.BYTE	$00,$B8,$B9,$B0,$BA,$AD,$7F
	.BYTE	$00,$00,$AE,'l','o',$8A,$0D
	.BYTE	$00,$00,$00,'w','e','r','t'
	.BYTE	'y','u','i',$00,'s','d','f'
	.BYTE	'g','h','j','k',$00,'x','c'
	.BYTE	'v','b','n','m',$AC,$00,'q'
	.BYTE	'a','z',$20,$AF,$BB,'p',$00

L3695	.BYTE	$14,$15,$12,$18
	.BYTE	$0C,$0B,$1A,$00
	.BYTE	$13,$19,$01,$00

L36A1	JSR	L2343
	PLA
	ROR	A
	BCS	L36AD
	LDA	#$11
	JSR	L2343
L36AD	JSR	$00C0
	JSR	$0E10
L36B3	JSR	$1618
	PHA
	TXA
	JSR	L2343
	PLA
	CMP	#$2C ; ','
	BNE	L36C5
	JSR	$00C0
	BNE	L36B3
L36C5	JSR	$0E0D
	PLA
	PLA
	JMP	$0A32

	.BYTE	0
	.BYTE	0

L36CF	LDA	#0
L36D0	BNE	L36D6
	JMP	$1CD1	; PRINT BASIC LINE NUMBER

L36D6	JSR	$0A73	; PRINT CRLF
L36D9	LDA	#0	; MODIFIED
	STA	$19
L36DD	LDA	#0	; MODIFIED
	STA	$1A
	PLA
	PLA
	LDA	#$FF
	STA	$87
	JSR	$08AC
	JMP	$07B4	; EXEC NEXT STATEMENT

L36ED	CMP	L232C
	BNE	L36F9
	PLA
	PLA
	PLA
	PLA
	JMP	L2291

L36F9	PHA
	LDA	L232D
	BEQ	L3707
	LDX	#0
	JSR	L2477
	JSR	L2761
L3707	PLA
	JSR	$17D8
L370B	RTS

	CMP	#$46 ; 'F'
	BEQ	L3713
L3710	JMP	$0E1E	; 'SN' ERROR

L3713	JSR	$00C0
	BEQ	L3710
	CMP	#$2C ; ','
	BNE	L3713
	JSR	$00C0
	JSR	$0CCD
	JSR	$0CBE
	JSR	$1520
	STA	L2CEC+1
	STX	$E1
	STY	$E2
	JMP	$1953

L3732	JSR	L3744
	BEQ	L370B
	PLA
	PLA
	JMP	L2ABA

L373C	STA	L374C+1
	LDA	L2E79,X
	BNE	L3749

L3744	STA	L374C+1
	LDA	($E1),Y
L3749	JSR	L3A5F
L374C	CMP	#0
	RTS

	.BYTE	0
	.BYTE	0
	.BYTE	0
	.BYTE	0
L3753	.WORD	$1B	; PTR TO BASIC INPUT BUFFER
L3755	.BYTE	$47
L3756	.BYTE	$62
L3757	.BYTE	$44
L3758	.BYTE	$10
L3759	.BYTE	$C
L375A	.BYTE	0
L375B	.BYTE	8
L375C	.BYTE	0
L375D	.BYTE	$7F
L375E	.BYTE	$5F
L375F	.BYTE	$14
L3760	.BYTE	6
L3761	.BYTE	9
L3762	.BYTE	$12
L3763	.BYTE	$40
L3764	.BYTE	7
L3765	.BYTE	$20
L3766	.BYTE	$7B
L3767	.BYTE	$D
L3768	.BYTE	0
L3769	.BYTE	0
L376A	.BYTE	$4F
L376B	.BYTE	7
L376C	.BYTE	0
L376D	.BYTE	0
L376E	.BYTE	$FF
L376F	.BYTE	0

;	BASIC - 'EDIT' KEYWORD

L3770	LDY	$87
	INY
	BEQ	L3778
	JMP	$10D0	; 'FC' ERROR

L3778	JSR	$00C6
	BEQ	L3797
	CMP	#$21 ; '!'
	BNE	L3788
	JSR	$00C0
	BEQ	L37A4
	BNE	L3794

L3788	JSR	$00C6
	BCC	L378F
	BCS	L3794

L378F	JSR	$096C
	BEQ	L37A4
L3794	JMP	$0E1E	; 'SN' ERROR

L3797	INC	$19
	BNE	L379D
	INC	$1A
L379D	LDY	#1
	LDA	($AC),Y
	BNE	L37A4
	RTS

L37A4	JSR	$0633
	BCS	L37B7
	LDY	#3
	LDA	($AC),Y
	STA	$1A
	DEY
	LDA	($AC),Y
	STA	$19
	DEY
	BNE	L379D

L37B7	LDY	#$FF
	STY	L376F
	INY
	STY	$16
	JSR	$06D8
	LDY	#$FF
	STY	L376D
	INY
	STY	L376E
	STY	L376F
	STY	$16
	LDA	L3767
	STA	($EE),Y
	PLA
	PLA
	JMP	$047D	; WAIT FOR BASIC COMMAND

;

L37DA	LDY	L376F
	BNE	L37E3
	LDA	L2322
	RTS

L37E3	LDY	$EE
	CPY	L3756
	BCS	L37FE
	CMP	L3765
	BCC	L37FE
	CMP	#$20 ; ' '
	BNE	L37F8
	CPY	L3753
	BEQ	L37FE

L37F8	LDY	#0
	STA	($EE),Y
	INC	$EE

L37FE	LDA	#0
	RTS
	CMP	#$3F ; '?'
	BNE	L3808
	JMP	$5C1

L3808	CMP	#$21 ; '!'
	BNE	L3816
	CPX	L3753
	BNE	L3816
	LDA	#$91 ; '�'
	JMP	$5C3

L3816	JMP	$5C5

; CALLED FROM BASIC - INPUT CHAR

L3819	LDA	L3753
	STA	$EE
	LDA	L3753+1
	STA	$EF
	LDA	L376E
	BEQ	L382F
	LDY	#0
	LDA	L3767
	STA	($EE),Y
L382F	LDY	#$FF
L3831	INY
	LDA	($EE),Y
	CMP	L3767
	BEQ	L3843
	LDX	L376D
	BEQ	L3831
	JSR	$0AEE	; BASIC PRINT .A
	BNE	L3831
L3843	LDX	#0
	STX	L376D
	STY	L3768
	LDA	$16
	STA	L3769
	LDA	L376C
	BEQ	L3882
	STX	L376C
	LDX	L3768
	LDA	L3767
	RTS

L385F	LDA	#$FF
	STA	L376C
	STA	L376E
	BNE	L382F

L3869	LDY	#0
	LDA	($EE),Y
	LDY	L3768
	CMP	L3767
	BEQ	L3882
	JSR	$0A73	; PRINT CRLF
	LDX	#0
	STX	$16
	DEX
	STX	L376D
	BNE	L382F

L3882	JMP	L38CE

L3885	LDX	L375C
	BEQ	L38BA
	LDX	L375A
	BEQ	L38BA

L388F	LDA	($EE),Y
	CMP	L3767
	BEQ	L389F
	LDA	L375A
	INY
	JSR	$0AEE	; PRINT .A
	BNE	L388F

L389F	TYA
	BEQ	L38C4
	DEC	$16
	LDX	#2
L38A6	LDA	L375C
L38A9	JSR	$0AEE	; PRINT .A
	DEX
	BEQ	L38A6
	BMI	L38B5
	LDA	#' '
	BNE	L38A9
L38B5	DEC	$16
	DEY
	BPL	L389F

L38BA	JSR	$0AEE	; PRINT .A
	JSR	$0A73	; PRINT CRLF
	LDA	#0
	STA	$16
L38C4	LDY	#1
L38C6	DEY
	BMI	L38C4
	LDA	L3767
	STA	($EE),Y
L38CE	STY	L3768
	JSR	$0587
	CMP	L375B
	BNE	L38DC
	JMP	L3983

L38DC	CMP	L3758
	BEQ	L38E6
	CMP	L3759
	BNE	L38E9
L38E6	JMP	L39D6

L38E9	CMP	L375F
	BNE	L38F1
	JMP	L3869

L38F1	CMP	L3760
	BNE	L38F9
	JMP	L3977

L38F9	CMP	L3761
	BNE	L3901
	JMP	L39B7

L3901	CMP	L3762
	BNE	L3909
	JMP	L39A9

L3909	CMP	L3763
	BNE	L3911
	JMP	L3885

L3911	CMP	L375D
	BEQ	L391B
	CMP	L375E
	BNE	L391E
L391B	JMP	L3A00

L391E	CMP	L3767
	BNE	L3926
	JMP	L385F

L3926	CMP	L3765
	BCC	L38CE
	CMP	L3766
	BCC	L3933
L3930	JMP	L38CE

L3933	CPY	L3755
	BCS	L3930
	LDX	$16
	CPX	L376A
	BCS	L3930
	PHA
	TXA
	CLC
	ADC	#3
	CMP	L376A
	BCC	L394F
	LDA	L3764
	JSR	$0AEE	; PRINT .A
L394F	PLA
	INC	$16
L3952	PHA
	DEC	$16
	JSR	$0AEE	; PRINT .A
	CPY	L3757
	BCC	L3963
	LDA	L3764
	JSR	$0AEE	; PRINT .A
L3963	LDA	($EE),Y
	TAX
	PLA
	STA	($EE),Y
	INY
	TXA
	CMP	L3767
	BEQ	L3996
	CPY	L3755
	BCS	L3991
	BCC	L3952

L3977	LDX	L375C
	BEQ	L39D3
	LDA	#0
	STA	L3768
	BEQ	L399B

L3983	STA	L375C
	TYA
	BEQ	L39D3
	TAX
	DEX
	STX	L3768
	CLC
	BCC	L399B

L3991	LDA	L3767
	DEC	$16
L3996	INC	L3768
	STA	($EE),Y
L399B	CPY	L3768
	BEQ	L39D3
	DEY
	LDA	L375C
	JSR	$0AEE	; PRINT .A
	BNE	L399B
L39A9	LDX	L375A
	BEQ	L39D3
	LDX	L3755
	INX
	STX	L3768
	BNE	L39EB
L39B7	LDX	L375A
	BEQ	L39D3
	LDA	#0
	STA	L3768
L39C1	CLC
	LDA	L376B
	ADC	L3768
	STA	L3768
	TYA
	CMP	L3768
	BCS	L39C1
	BCC	L39EB
L39D3	JMP	L38CE

L39D6	LDX	L375A
	BNE	L39E0
	STA	L375A
	BNE	L39E5
L39E0	CMP	L375A
	BNE	L39D3
L39E5	STY	L3768
	INC	L3768
L39EB	LDA	($EE),Y
	CMP	L3767
	BEQ	L39D3
	CPY	L3768
	BCS	L39D3
	INY
	LDA	L375A
	JSR	$0AEE	; PRINT .A
	BNE	L39EB
L3A00	LDY	#0
	LDA	($EE),Y
	LDY	L3768
	CMP	L3767
	BEQ	L39D3
	LDA	L375C
	BNE	L3A23
	LDA	L3764
	LDX	$16
	CPX	L376A
	BCS	L3A1E
	LDA	L375E
L3A1E	JSR	$0AEE	; PRINT .A
	BNE	L3A3F
L3A23	DEC	$16
	LDA	($EE),Y
	CMP	L3767
	BNE	L3A42
	LDX	#2
L3A2E	LDA	L375C
L3A31	JSR	$0AEE	; PRINT .A
	DEX
	BEQ	L3A2E
	BMI	L3A3D
	LDA	#' '
	BNE	L3A31

L3A3D	DEC	$16
L3A3F	JMP	L38C6

L3A42	INY
	LDA	($EE),Y
	DEY
	STA	($EE),Y
	PHA
	CMP	L3767
	BNE	L3A50
	LDA	#' '
L3A50	JSR	$0AEE	; PRINT .A
	DEC	$16
	INY
	PLA
	CMP	L3767
	BNE	L3A42
	JMP	L399B

; MAKE UPPERCASE

L3A5F	CMP	#'a'
	BCC	L3A69
	CMP	#'z'+1
	BCS	L3A69
	EOR	#$20
L3A69	RTS

L3A6A	JSR	L3A5F
	CMP	#$D
	BEQ	L3A69
	JMP	L2CEC

L3A79	=	$3A79
L3A7D	=	$3A7D
L3A7E	=	$3A7E

L3D7E	=	L3A7E+$300

	.END
