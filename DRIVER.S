;******************************************
; Mad Max's  Soundchip-Player             *
; converted by bITmASTER of BSW           *
; aka Dunkelwind                          *
;******************************************
; Hi Z80-Freaks !
;
; Dieser Driver spielt die MAD MAX ( Jochen Hippel) Sounds
; von den Atari ST auf einem Z80-Rechner ab. Als Soundchip
; ist der AY-3-8912 oder YM 2149 geeignet.
; Die Sounddaten selbst brauchen nicht konvertiert zu werden.
;
; Init:	ld a,Soundnummer ;Soundnummer = 1,2,3...., 0 = Sound aus
;       call mad_max
;
; Play: call mad_max+6	 ;alle 20 ms im Interrupt
;
; die Interruptroutine braucht auch die Shadow-Register, also bei
; Bedarf noch pushen & popen !
;
; dieser Player ist fÅr den ZX-Spectrum, wird aber bestimmt nach
; einigen Anpassungen auf den Schneider CPC funktionieren
;



track_base:         equ 0                   ;.l
track_index:        equ 4                   ;.w
seq_note:           equ 6                   ;.b
seq_hkurve:         equ 7                   ;.b
hkurve_base:        equ 8                   ;.l
hkurve_index:       equ 12                  ;.w
instr_base:         equ 14                  ;.l
instr_index:        equ 18                  ;.w
track_hkurve:       equ 20                  ;.b
track_note:         equ 21                  ;.b
hkurve_time:        equ 22                  ;.b
hkurve_time_init:   equ 23                  ;.b
hkurve_count:       equ 24                  ;.b
instr_count:        equ 25                  ;.b
instr_note:         equ 26                  ;.b
delta_f:            equ 27                  ;.b
mod_f_max:          equ 28                  ;.b
mod_f_work:         equ 29                  ;.b
tfmx_count:         equ 30                  ;.b
flags:              equ 31                  ;.b
seq_instr:          equ 32                  ;.b
noise_freq:         equ 33                  ;.b
voice_nr:           equ 34                  ;.b
hkurve_amplitude:   equ 35                  ;.b
track_daempfung:    equ 36                  ;.b
daempfung:          equ 37                  ;.b
tune_noise:         equ 38                  ;.b
not_used1:          equ 39                  ;.b
seq_ptr:            equ 40                  ;.l
seq_time:           equ 44                  ;.b
seq_time_init:      equ 45                  ;.b
bend_var:           equ 46                  ;.l
track_count:        equ 50                  ;.w
not_used2:          equ 52                  ;.w

;------------------ Soundchip ----------------------------------------------

nr:                 equ 65533
data:               equ 49149

                    org 7000h
                    di
                    ld hl,int_tab
                    ld a,l
                    and a                           ;Low-Teil = 0 ?
                    jr z,int_v_ok                   ;ja
                    ld l,0
                    inc h
int_v_ok:           ld a,h
                    ld i,a                          ;I-Register
                    ld b,0                          ;256 Bytes
                    ld a,70h                        ;Int-Routine bei 7070h
fill_int_tab:       ld (hl),a
                    inc hl
                    djnz fill_int_tab
                    ld (hl),a
                    inc hl
                    ld (hl),a
                    im 2
                    jp next
                
                    ds 52h

;------------------ Interruptroutine Adr: 7070H ----------------------------
                
                    push af
                    push bc
                    ld a,5                          ;Border schwarz
                    out (0feh),a
                    call mad_max+6                  ;Play Sound
                    ld a,7                          ;Border weiû
                    out (0feh),a
                    pop bc
                    pop af
                    ei
                    reti

sound_nr:           db 1

next:               ld a,07h
                    out (0feh),a            ;Border weiû
next2:              ld a,(sound_nr)
                    call mad_max
                    ei
                    ld a,(sound_nr)
                    inc a
                    cp 11
                    jr c,next1
                    ld a,1
next1:              ld (sound_nr),a
                    call key
                    ld (ym_set7),a
                    jr next2
                    
;------------------ Sound-Driver -------------------------------------------

mad_max:            jp select_snd
                    jp dummy
                    jp play
                    jp dummy
                    
select_snd:         push bc
                    push de
                    push hl
                    push ix
                    push af
                    ld ix,coso              ;Sound-Anfang
                    call reloziere
                    pop af                  ;Sound-Nr
                    dec a                   ;-1
                    add a,a                 ;a:=a*6
                    ld b,a
                    add a,a
                    add a,b
                    ld c,a
                    ld b,0
                    ld hl,(adr_sound)
                    add hl,bc
                    ld b,(hl)               ;bc := Sound-Start
                    inc hl
                    ld c,(hl)
                    inc hl
                    ld d,(hl)               ;de := Sound-End
                    inc hl
                    ld e,(hl)
                    inc hl
                    inc hl
                    ld a,(hl)               ;Play-Speed
                    ld (play_speed),a       ;beim Orginal 16 Bit !
                    call init_voice
                    pop ix
                    pop hl
                    pop de
                    pop bc
dummy:              ret

reloziere:          xor a
                    ld (mmme_flag),a
                    ld a,4dh                ;M
                    cp (ix+32)
                    jr nz,no_mmme
                    cp (ix+33)
                    jr nz,no_mmme
                    cp (ix+34)
                    jr nz,no_mmme
                    ld a,45h                ;E
                    cp (ix+35)
                    jr nz,no_mmme
                    ld a,1
                    ld (mmme_flag),a        ;MMME-Driver
no_mmme:            ld (adr_coso),ix        ;Soundstart merken
                    push ix
                    pop de                  ;de:=ix
                    ld h,(ix+6)
                    ld l,(ix+7)
                    add hl,de
                    ld (adr_instr),hl       ;Adr der Instr-Daten

                    ld h,(ix+10)
                    ld l,(ix+11)
                    add hl,de
                    ld (adr_h_kurve),hl     ;Adr der HÅllkurven-Daten

                    ld h,(ix+14)
                    ld l,(ix+15)
                    add hl,de
                    ld (adr_sequenz),hl     ;Adr der Sequenzdaten

                    ld h,(ix+18)
                    ld l,(ix+19)
                    add hl,de
                    ld (adr_track),hl       ;Adr der Track-Daten

                    ld h,(ix+22)
                    ld l,(ix+23)
                    add hl,de
                    ld (adr_sound),hl       ;Adr der Sound-Daten ( Start, LÑnge, xxxx )

                    ld h,(ix+26)
                    ld l,(ix+27)
                    add hl,de
                    ld (adr_effekt),hl      ;Adr der GerÑusche

                    ld a,1
                    ld (relozier_flag),a
                    ret

;---------------------------------------------------------------------
;In: bc: Start
;    de: End

init_voice:         ld h,d                  ;hl := End
                    ld l,e
                    xor a
                    sbc hl,bc               ;End - Start = LÑnge
                    ld (track_length),hl    ;LÑnge des Tracks merken
                    inc de                  ;End + 1

                    ld h,b                  ;bc * 12
                    ld l,c
                    call mul12
                    ld b,h
                    ld c,l

                    ld ix,voice0
                    ld e,0                  ;Voice-Nr

init_voices:        ld (ix+instr_base),L(default_h)
                    ld (ix+instr_base+1),H(default_h)
 
                    ld (ix+instr_index),0
                    ld (ix+instr_index+1),0

                    ld (ix+hkurve_base),L(default_h)
                    ld (ix+hkurve_base+1),H(default_h)
                    
                    ld (ix+hkurve_index),0
                    ld (ix+hkurve_index+1),0
                    
                    ld (ix+seq_note),0
                    ld (ix+seq_hkurve),0
                    ld (ix+instr_note),0
                    ld (ix+hkurve_amplitude),0
                    ld (ix+hkurve_time_init),1
                    ld (ix+hkurve_time),1
                    ld (ix+hkurve_count),0
                    ld (ix+instr_count),0
                    ld (ix+delta_f),0
                    ld (ix+mod_f_max),0
                    ld (ix+mod_f_work),0
                    ld (ix+tfmx_count),0
                    ld (ix+seq_instr),0
                    ld (ix+noise_freq),0
                    ld (ix+voice_nr),e              ;Voice-Nr

                    ld hl,(track_length)            ;Track-LÑnge
                    ld (ix+track_count),l
                    ld (ix+track_count+1),h
                    
                    ld hl,(adr_track)               ;Beginn Tracks
                    add hl,bc                       ;+ Startpunkt
                    ld d,0
                    add hl,de                       ;+ ( Voice * 4 )
                    add hl,de
                    add hl,de
                    add hl,de
                    ld (ix+track_base),l            ;Startpunkt in Track
                    ld (ix+track_base+1),h

                    ld (ix+track_index),12          ;zeigt auf Eintrag 1
                    ld (ix+track_index+1),0
                    
                    ld a,(hl)                       ;Sequenz
                    inc hl
                    exx
                    ld hl,(adr_sequenz)
                    ld b,0                          ;bc = Sequenz 
                    ld c,a
                    add hl,bc                       ;+ 2* Sequenz
                    add hl,bc
                    ld d,(hl)                       ;Offset holen (68000!)
                    inc hl
                    ld e,(hl)
                    ld hl,(adr_coso)
                    add hl,de                       ;relozieren
                    ld (ix+seq_ptr),l               ;Adr der Sequenz
                    ld (ix+seq_ptr+1),h
                    exx
                    
                    ld (ix+seq_time),0
                    ld (ix+seq_time_init),0
                    
                    ld (ix+tune_noise),2
                                                            
                    ld a,(hl)                       ;Note 
                    inc hl
                    ld (ix+track_note),a
                    ld a,(hl)                       ;HÅllkurve
                    inc hl
                    ld (ix+track_hkurve),a
                    
                    ld (ix+daempfung),0
                    ld (ix+track_daempfung),0
                    
                    ld a,(hl)                       
                    ld d,a
                    and 0f0h
                    cp 0f0h                         ;die obersten 4 Bits = 1 ?
                    jr nz,no_daempfung              ;nein
                    ld a,d                          ;ja
                    and 0fh
                    ld (ix+track_daempfung),a       ;DÑmpfung einstellen

no_daempfung:       ld (ix+bend_var),0
                    ld (ix+bend_var+1),0
                    ld (ix+bend_var+2),0
                    ld (ix+bend_var+3),0
                    
                    ex de,hl
                    ld de,54
                    add ix,de                       ;next Voice
                    ex de,hl
                    inc e                           ;next Voice-Nr
                    ld a,3                          ;3 Voices fertig ? 
                    cp e
                    jp nz,init_voices               ;nî
                    ld a,1
                    ld (play_speed_count),a         ;beim Orginal 16 Bit !
                    ret

;------------------ Player, alle 20 ms -------------------------------------

play:               push af
                    push bc
                    push de
                    push hl
                    push ix
                    push iy
                    ld iy,ym_set
                    ld ix,voice0
                    call work_voice
                    ld (iy+8),a                     ;Amplitude A
                    ld (iy+0),e                     ;Frequenz fein A
                    ld (iy+1),d                     ;Frequenz grob A
                    ld ix,voice1
                    call work_voice
                    ld (iy+9),a                     ;Amplitude B
                    ld (iy+2),e                     ;Frequenz fein B
                    ld (iy+3),d                     ;Frequenz grob B
                    ld ix,voice2
                    call work_voice
                    ld (iy+10),a                    ;Amplitude C
                    ld (iy+4),e                     ;Frequenz fein C
                    ld (iy+5),d                     ;Frequenz grob C
                    
;------------------ Soundchip programmieren --------------------------------

                    ld a,(ym_set7)
                    or 0c0h
                    ld (ym_set7),a
                    
                    ld bc,data                      ;Daten
                    ld hl,ym_set
                    exx
                    ld bc,nr                        ;nr
                    ld a,0                          ;Register
out_ym:             out (c),a                       ;Register-Nr
                    exx
                    ld d,(hl)                       ;Daten holen
                    inc hl
                    out (c),d                       ;Daten ausgeben
                    exx
                    inc a
                    cp 11
                    jr nz,out_ym

; einige Testroutinen
;                    ld a,11
;                    ld hl,ym_set
;                    call send

;                    ld a,1
;                    ld hl,dreieck
;                    call send

;                    ld a,54
;                    ld hl,voice0
;                    call send                    
mm:                    
                    ld a,(play_speed_count)
                    dec a
                    ld (play_speed_count),a
                    jr nz,play_end                  ;nix tun
                    ld a,(play_speed)               ;Init
                    ld (play_speed_count),a
                    ld ix,voice0
                    call sequenzer
                    ld ix,voice1
                    call sequenzer
                    ld ix,voice2
                    call sequenzer
play_end:           pop iy
                    pop ix
                    pop hl
                    pop de
                    pop bc
                    pop af
                    ret
                    
;------------------ Sequenz von Voice (IX) wird interpretiert --------------

sequenzer:          dec (ix+seq_time)
                    ret p                           ;nix tun
                    ld a,(ix+seq_time_init)         ;neu initialisieren
                    ld (ix+seq_time),a
sequenzer1:         ld l,(ix+seq_ptr)               ;Adresse der aktuellen Sequenz
                    ld h,(ix+seq_ptr+1)
seq_loop:           ld a,(hl)                       ;SeqByte holen
                    inc hl
                    cp 0ffh                         ;zu Ende ?
                    jp nz,sequenzer2                ;nî
                    
;------------------ Track interpretieren -----------------------------------

                    ld l,(ix+track_base)            ;Basis Track
                    ld h,(ix+track_base+1)
                    ld c,(ix+track_index)
                    ld b,(ix+track_index+1)
                    add hl,bc                       ;Basis + Index
                    ld a,(ix+voice_nr)
                    and a                           ;Voice-Nr 0 ?
                    jr nz,no_track_init             ;nein
                    
; die 3 Tracks werden nur bei Voice 0 neu initialisiert

                    dec (ix+track_count)            ;Tracks fertig ?
                    ld a,0ffh
                    cp (ix+track_count)
                    jp nz,no_track_init             ;nein
                    dec (ix+track_count+1)          ;dec HWT
                    cp (ix+track_count+1)
                    jp nz,no_track_init             ;nein
                    ld hl,(track_length)            ;LÑnge initialisieren
                    ld (ix+track_count),l
                    ld (ix+track_count+1),h
                    xor a
                    ld (ix+track_index),a           ;alle 3 Indexe = 0
                    ld (ix+track_index+1),a
                    ld (ix+track_index+54),a
                    ld (ix+track_index+55),a
                    ld (ix+track_index+108),a
                    ld (ix+track_index+109),a
                    ld l,(ix+track_base)            ;Track von vorne
                    ld h,(ix+track_base+1)
                    
no_track_init:      ld a,(hl)                       ;Sequenz-Nr
                    ex af,af'
                    inc hl
                    ld a,(hl)                       ;Tonhîhe der Sequenz
                    ld (ix+track_note),a
                    inc hl
                    ld a,(hl)                       ;HÅllkurve
                    ld (ix+track_hkurve),a
                    inc hl
                    ld a,(hl)
                    ld b,a
                    and 0f0h                        ;die obersten 4 Bits an ?
                    cp 0f0h
                    jr nz,no_track_daempf           ;nein
                    ld a,b                          ;ja
                    and 0fh                         ;die untersten 4 Bits
                    ld (ix+track_daempfung),a       ;bestimmen die DÑmpfung
                    jr no_track_speed
no_track_daempf:    cp 0e0h                         ;die obersten 3 Bits ?
                    jr nz,no_track_speed            ;nî
                    ld a,b
                    and 0fh                         ;untersten 4 Bits
                    ld (play_speed),a               ;neues Play-Speed setzen
no_track_speed:     ex af,af'
                    ld hl,(adr_sequenz)
                    ld c,a                          ;BC = Sequenz
                    ld b,0
                    add hl,bc                       ;Adresse der Sequenz
                    add hl,bc
                    ld b,(hl)                       ;HWT, BC=Offset
                    inc hl
                    ld c,(hl)
                    ld hl,(adr_coso)
                    add hl,bc                       ;relozieren
                    ld (ix+seq_ptr),l               ;neuer Sequenz-Pointer
                    ld (ix+seq_ptr+1),h
                    ld a,12
                    add a,(ix+track_index)          ;next Index
                    ld (ix+track_index),a
                    jp nc,sequenzer1                ;kein öbertrag
                    inc (ix+track_index+1)
                    jp sequenzer1

;------------------ Sequenz interpretieren ---------------------------------
                    
sequenzer2:         cp 0feh                         ;$fe-Sequenz ?
                    jr nz,no_fe_seq                 ;nî 
                    ld a,(hl)
                    ld (ix+seq_time_init),a
                    ld (ix+seq_time),a
                    inc hl
                    jp seq_loop                     ;next SeqByte                

no_fe_seq:          cp 0fdh                         ;$fd-Sequenz ?
                    jr nz,no_fd_seq                 ;nî

;------------------ Pause --------------------------------------------------

                    ld a,(hl)
                    ld (ix+seq_time_init),a
                    ld (ix+seq_time),a
                    inc hl
                    ld (ix+seq_ptr),l               ;Seq-Ptr speichern
                    ld (ix+seq_ptr+1),h
                    ret                             ;das wars
                    
no_fd_seq:          ld (ix+seq_note),a              ;Tonhîhe
                    ld b,a
                    ld a,(hl)
                    inc hl
                    ld (ix+seq_hkurve),a            ;HÅllkurve
                    and 0e0h                        ;obersten 3 Bits = 0 ?
                    jr z,no_instr                   ;ja
                    ld c,(hl)                       ;nein, noch ein Seq-Byte
                    inc hl
                    ld (ix+seq_instr),c             ;Instrument setzen
no_instr:           ld (ix+seq_ptr),l               ;Seq-Ptr speichern
                    ld (ix+seq_ptr+1),h
                    ld (ix+bend_var),0
                    ld (ix+bend_var+1),0
                    ld (ix+bend_var+2),0
                    ld (ix+bend_var+3),0
                    ld a,b
                    and a                           ;Tonhîhe negativ ?
                    ret m                           ;ja, fertig
         
                    ld a,(ix+seq_hkurve)
                    ld d,a
                    and 1fh                         ;0...31
                    add a,(ix+track_hkurve)
                    add a,a                         ;*2
                    ld hl,(adr_h_kurve)
                    ld c,a
                    ld b,0
                    add hl,bc
                    ld b,(hl)                       ;HWT, 68000!
                    inc hl
                    ld c,(hl)                       ;NWT
                    ld hl,(adr_coso)
                    add hl,bc                       ;relozieren
                    ld (ix+hkurve_index),0
                    ld (ix+hkurve_index+1),0
                    ld a,(hl)
                    inc hl
                    ld (ix+hkurve_time_init),a      ;Initialisieren
                    ld (ix+hkurve_time),a                        
                    ld b,(hl)                       ;Instrument
                    inc hl
                    ld a,(hl)
                    inc hl
                    ld (ix+delta_f),a
                    ld (ix+flags),40h
                    ld a,(hl)
                    inc hl
                    ld (ix+mod_f_max),a
                    ld (ix+mod_f_work),a
                    ld a,(hl)
                    inc hl
                    ld (ix+tfmx_count),a
                    ld (ix+hkurve_base),l           ;HÅllkurven_ptr merken
                    ld (ix+hkurve_base+1),h
                    ld a,d
                    and 40h
                    jr z,s0                         ;Instr aus hkurve 
                    ld b,(ix+seq_instr)             ;anderes Inst
s0:                 ld hl,(adr_instr)
                    ld a,b
                    add a,a                         ;*2
                    ld c,a
                    ld b,0
                    add hl,bc
                    ld b,(hl)                       ;HWT, 68000!
                    inc hl
                    ld c,(hl)                       ;NWT
                    ld hl,(adr_coso)
                    add hl,bc                       ;relozieren
                    ld (ix+instr_base),l
                    ld (ix+instr_base+1),h
                    ld (ix+instr_index),0
                    ld (ix+instr_index+1),0
                    ld (ix+instr_count),0
                    ld (ix+hkurve_count),0
                    ret

;------------------ Work Voice ---------------------------------------------
;In:  ix: Pointer auf Voice-Area
;Out: de: Teilerfaktor
;      a: Amplitude

;------------------ Instrument ---------------------------------------------

work_voice:         ld (ix+noise_freq),0
w_instr3:           xor a
                    cp (ix+instr_count)             ;0 erreicht ?
                    jr z,w_instr1                   ;ja
                    dec (ix+instr_count)
                    jp w_hkurve                     ;nix tun
w_instr1:           ld l,(ix+instr_base)            ;Instrument
                    ld h,(ix+instr_base+1)
                    ld c,(ix+instr_index)           ;Index
                    ld b,(ix+instr_index+1)
                    add hl,bc                       ;+Index
loop_instr:         ld a,(hl)                       ;laden
                    inc hl
                    ld b,a
                    sub 0e0h                        ;< $e0 ?
                    jp c,w_instr2                   ;ja
                    add a,a                         ;*2
                    exx
                    ld l,a                          ;Jump Åber Tab
                    ld h,0
                    ld bc,jmp_tab1
                    add hl,bc
                    ld c,(hl)
                    inc hl
                    ld b,(hl)
                    ld (j1+1),bc
                    exx
j1:                 jp 0
                    
jmp_tab1:           dw i0                           ;$e0
                    dw i1                           ;$e1
                    dw i2
                    dw i3
                    dw i4
                    dw i5
                    dw i6
                    dw i7
                    dw i8
                    dw i9
                    dw i10                          ;$ea
                    
;------------------ $e0: absoluter JMP -------------------------------------

i0:                 ld c,(hl)
                    ld b,0
                    ld (ix+instr_index),c           ;neuen Index setzen
                    ld (ix+instr_index+1),b
                    ld l,(ix+instr_base)
                    ld h,(ix+instr_base+1)
                    add hl,bc                       ;Index dazu addieren
                    jr loop_instr                   ;next Byte
                    
;------------------ $e1: Ende ----------------------------------------------

i1:                 dec hl                          ;(hl)=$e1
                    dec hl                          ;(hl)=letzte Note
                    ld a,(hl)                       ;letzte Note
                    ld (ix+instr_note),a
                    jp w_hkurve
                    
;------------------ $e2: Reset HÅllkurven-Index ----------------------------

i2:                 xor a
                    ld (ix+hkurve_index),a
                    ld (ix+hkurve_index+1),a
                    inc a
                    ld (ix+hkurve_time),a           ;1
                    add a,(ix+instr_index)          ;index+1
                    ld (ix+instr_index),a
                    jr nc,loop_instr                ;next Bytes
                    inc (ix+instr_index+1)          ;öbertrag
                    jr loop_instr                   ;next Bytes
                    
;------------------ $e3: ---------------------------------------------------

i3:                 ld a,(hl)
                    inc hl
                    ld (ix+delta_f),a
                    ld a,(hl)
                    inc hl
                    ld (ix+mod_f_max),a
                    ld a,3
                    add a,(ix+instr_index)          ;index+3
                    ld (ix+instr_index),a
                    jr nc,loop_instr                ;next Bytes
                    inc (ix+instr_index+1)          ;öbertrag
                    jr loop_instr                   ;next Bytes
                    
;------------------ $e4: Noise & Tune on -----------------------------------

i4:                 ld (ix+tune_noise),0            ;Ton & Rauschen an
                    ld a,(hl)
                    inc hl
                    ld (ix+noise_freq),a
                    ld a,2
                    add a,(ix+instr_index)          ;index+2
                    ld (ix+instr_index),a
                    jp nc,loop_instr                ;next Bytes
                    inc (ix+instr_index+1)          ;öbertrag
                    jp loop_instr                   ;next Bytes

;------------------ $e5: Noise on, Tune off --------------------------------

i5:                 ld (ix+tune_noise),1
                    ld a,1
                    add a,(ix+instr_index)          ;index+1
                    ld (ix+instr_index),a
                    jp nc,loop_instr                ;next Bytes
                    inc (ix+instr_index+1)          ;öbertrag
                    jp loop_instr                   ;next Bytes

;------------------ $e6: Noise off, Tune on --------------------------------

i6:                 ld (ix+tune_noise),2
                    ld a,1
                    add a,(ix+instr_index)          ;index+1
                    ld (ix+instr_index),a
                    jp nc,loop_instr                ;next Bytes
                    inc (ix+instr_index+1)          ;öbertrag
                    jp loop_instr                   ;next Bytes

;------------------ $e7: Select Instrumentengruppe -------------------------

i7:                 ld e,(hl)
                    ld d,0
                    ex de,hl
                    add hl,hl                       ;*64
                    add hl,hl
                    add hl,hl
                    add hl,hl
                    add hl,hl
                    add hl,hl
                    ld bc,(adr_instr)
                    add hl,bc
                    ld (ix+instr_base),l            ;neue Instr-Gruppe
                    ld (ix+instr_base+1),h
                    xor a
                    ld (ix+instr_index),a           ;Index = 0
                    ld (ix+instr_index+1),a
                    ex de,hl
                    jp loop_instr                   ;next Bytes
                    
;------------------ $e8: set Instrumentcounter -----------------------------

i8:                 ld a,(hl)
                    inc hl
                    ld (ix+instr_count),a
                    ld a,2
                    add a,(ix+instr_index)          ;index+2
                    ld (ix+instr_index),a
                    jp nc,w_instr3
                    inc (ix+instr_index+1)          ;öbertrag
                    jp w_instr3

;------------------ $e9: Dreieck -------------------------------------------

i9:                 ld bc,nr
                    ld a,11                         ;hkurve fein
                    out (c),a
                    ld bc,data
                    ld a,(hl)                       ;direkte Soundchip-
                    inc hl                          ;programmierung
                    out (c),a
                    ld (dreieck),a                  ;fÅr send
                    ld bc,nr
                    ld a,12                         ;hkurve grob
                    out (c),a
                    ld bc,data
                    xor a
                    out (c),a                       ;=0
                    ld bc,nr
                    ld a,13                         ;Hform
                    out (c),a
                    ld bc,data
                    ld a,0ah                        ;Dreieck
                    out (c),a
                    ld a,2
                    add a,(ix+instr_index)          ;index+2
                    ld (ix+instr_index),a
                    jp nc,loop_instr                ;next Bytes
                    inc (ix+instr_index+1)          ;öbertrag
                    jp loop_instr                   ;next Bytes

;------------------ $ea: ---------------------------------------------------

i10:                ld (ix+seq_hkurve),20h
                    ld a,(hl)
                    inc hl
                    ld (ix+seq_instr),a
                    ld a,2
                    add a,(ix+instr_index)          ;index+2
                    ld (ix+instr_index),a
                    jp nc,loop_instr                ;next Bytes
                    inc (ix+instr_index+1)          ;öbertrag
                    jp loop_instr                   ;next Bytes

;------------------ alle Werte kleiner $e0 ---------------------------------

w_instr2:           ld (ix+instr_note),b
                    ld a,1
                    add a,(ix+instr_index)          ;index+1
                    ld (ix+instr_index),a
                    jr nc,w_hkurve                  ;next Bytes
                    inc (ix+instr_index+1)          ;öbertrag

;------------------ Ende Instrument ----------------------------------------

;------------------ HÅllkurve ----------------------------------------------

w_hkurve:           xor a
                    cp (ix+hkurve_count)            ;0 erreicht ?
                    jr z,w_hkurve1                  ;ja
                    dec (ix+hkurve_count)           ;weiter dec
                    jp get_teilerfaktor             ;nix tun
w_hkurve1:          dec (ix+hkurve_time)
                    jp nz,get_teilerfaktor          ;nix tun
                    ld a,(ix+hkurve_time_init)      ;neu setzen
                    ld (ix+hkurve_time),a
                    ld l,(ix+hkurve_base)
                    ld h,(ix+hkurve_base+1)
                    ld c,(ix+hkurve_index)
                    ld b,(ix+hkurve_index+1)
                    add hl,bc                       ;Adr HÅllkurve
loop_hkurve:        ld a,(hl)                       ;Amplitude laden
                    inc hl
                    ld b,a
                    sub 0e0h                        ;< $e0 ?
                    jp c,w_hkurve2                  ;ja
                    add a,a                         ;*2
                    exx
                    ld l,a                          ;Jump Åber Tab
                    ld h,0
                    ld bc,jmp_tab2
                    add hl,bc
                    ld c,(hl)
                    inc hl
                    ld b,(hl)
                    ld (j2+1),bc
                    exx
j2:                 jp 0
                    
jmp_tab2:           dw h1
                    dw h2
                    dw h0
                    dw h0
                    dw h0
                    dw h0
                    dw h0
                    dw h0
                    dw h3

;------------------ $e2, $e3, $e4, $e5, $e7: Abbruch -----------------------

h0:                 ret

;------------------ $e0: absoluter JMP -------------------------------------

h1:                 ld a,(hl)
                    inc hl
                    sub 5                           ;5 Parameterbytes abziehen                                    
                    ld c,a
                    ld b,0
                    ld l,(ix+hkurve_base)
                    ld h,(ix+hkurve_base+1)
                    add hl,bc                       ;neue Adr
                    ld (ix+hkurve_index),c
                    ld (ix+hkurve_index+1),b
                    jr loop_hkurve                  ;next Bytes
                    
;------------------ $e1: Ende ----------------------------------------------

h2:                 dec hl                          ;(hl)=$e1
                    dec hl                          ;(hl)=letzte Amplitude
                    ld a,(hl)
                    ld (ix+hkurve_amplitude),a
                    jr get_teilerfaktor             ;fertig
                    
;------------------ $e8: set HÅllkurvencounter -----------------------------

h3:                 ld a,(hl)
                    ld (ix+hkurve_count),a
                    ld a,2
                    add a,(ix+hkurve_index)         ;Index+2
                    ld (ix+hkurve_index),a
                    jr nc,w_hkurve
                    inc (ix+hkurve_index+1)
                    jp w_hkurve
                    
;------------------ kleiner $e0 --------------------------------------------

w_hkurve2:          ld (ix+hkurve_amplitude),b
                    ld a,1
                    add a,(ix+hkurve_index)         ;Index+1
                    ld (ix+hkurve_index),a
                    jr nc,get_teilerfaktor
                    inc (ix+hkurve_index+1)         ;öbertrag

;------------------ Ende HÅllkurve -----------------------------------------

;------------------ Gesamtnote & Teilerfaktor ------------------------------
                            
get_teilerfaktor:   ld a,(ix+instr_note)            ;Tonhîhe des Instruments
                    and a
                    jp m,get_teilerfaktor1          ;negativ
                    add a,(ix+seq_note)             ;transformieren
                    add a,(ix+track_note)
get_teilerfaktor1:  and 7fh
                    add a,a                         ;*2
                    ld (note2),a                    ;merken
                    ld l,a
                    ld h,0
                    ld bc,teiler_faktor
                    add hl,bc
                    ld e,(hl)                       ;de = teilerfaktor
                    inc hl
                    ld d,(hl)
                    
;------------------ Tongeneratoren & Rausche ein/ausschalten ---------------

                    ld l,(ix+voice_nr)
                    ld h,0
                    add hl,hl
                    add hl,hl
                    ld bc,mask_tab
                    add hl,bc
                    ld c,(hl)                       ;Ton & Rauschen
                    inc hl                          ;einschalten
                    ld a,(ym_set7)
                    and c
                    ld c,a
                    ld b,(ix+tune_noise)
                    xor a
                    cp b
                    jr z,w_tune_noise2              ;Ton & Rauschen bleibt an
                    inc a                           ;a = 1
                    cp b
                    jr nz,w_tune_on                 ;Ton einschalten
                    ld a,(hl)
                    or c                            ;nur Rauschen
                    ld c,a
                    ld a,(ix+seq_note)
                    ld (ix+noise_freq),a
                    ld a,(ix+instr_note)
                    and a
                    jp p,w_tune_noise1
                    and 7fh
                    ld (ix+noise_freq),a
                    jr w_tune_noise2
w_tune_noise1:      add a,(ix+noise_freq)
                    ld (ix+noise_freq),a
                    jr w_tune_noise2
w_tune_on:          inc hl
                    ld a,(hl)
                    or c                            ;nur Ton
                    ld c,a
w_tune_noise2:      ld a,c
                    ld (ym_set7),a                  ;r7 setzen      
                    ld a,(ix+noise_freq)
                    and a                           ;Rauschfrequenz definiert ?
                    jr z,tfmx_mmme                  ;nein
                    cpl
                    and 1fh
                    ld (ym_set6),a
                    jr tfmx_mmme                    
                    
;                   db T&R,  R,    T
mask_tab:           db 036h, 001h, 008h, 00h        ;Voice0
                    db 02dh, 002h, 010h, 00h        ;Voice1
                    db 01bh, 004h, 020h, 00h        ;Voice2
                    
tfmx_mmme:          ld a,(mmme_flag)
                    and a
                    jp z,tfmx

;------------------ MMME-Driver --------------------------------------------

                    xor a
                    cp (ix+tfmx_count)
                    jr z,mmme
                    dec (ix+tfmx_count)
                    jr mmme_bender
                   
mmme:               ld a,(ix+mod_f_max)
                    add a,a
                    ld b,a                          ;max
                    ld a,(ix+mod_f_work)
                    bit 5,(ix+flags)
                    jr z,mmme_add                   ;addieren

                    sub (ix+delta_f)                ;Subtrahieren
                    jr nc,mmme1                     ;>= 0
                    xor a
                    res 5,(ix+flags)                ;auf add umschalten
                    jr mmme1

mmme_add:           add a,(ix+delta_f)
                    cp b
                    jr c,mmme1                      ;work < max
                    ld a,b                          ;auf max begrenzen
                    set 5,(ix+flags)                ;auf sub umschalten

mmme1:              push de
                    ld b,d
                    ld c,e
                    ld d,0
                    ld (ix+mod_f_work),a
                    sub (ix+mod_f_max)              ;Mittelinie
                    jr nc,mmme4                     ;positiv
                    ld d,0ffh
mmme4:              ld e,a
                    call mul
                    
                    ld e,d                          ;/256 &
                    ld d,c
                    sra b                    
                    rr d                            ;/4 = /1024
                    rr e
                    sra b
                    rr d
                    rr e

                    pop hl
                    add hl,de
                    ex de,hl                    

mmme_bender:        bit 5,(ix+seq_hkurve)
                    jp z,w_amplitude                ;nicht benden
                    ld b,0
                    ld c,(ix+seq_instr)
                    bit 7,b                         ;negativ
                    jr z,mmme_bender1               ;nein
                    ld b,0ffh
mmme_bender1:       ld l,(ix+bend_var)
                    ld h,(ix+bend_var+1)
                    add hl,bc
                    ld (ix+bend_var),l
                    ld (ix+bend_var+1),h
                    push de
                    ld b,d
                    ld c,e
                    ex de,hl
                    call mul
                    
                    ld e,d                          ;/256 &
                    ld d,c
                    sra b                    
                    rr d                            ;/4 = /1024
                    rr e
                    sra b
                    rr d
                    rr e
                    pop hl
                    xor a
                    sbc hl,de
                    ex de,hl                    
                    jp w_amplitude
                            
;------------------ TFMX-Driver --------------------------------------------

tfmx:               
                    xor a
                    cp (ix+tfmx_count)
                    jr z,tfmx1
                    dec (ix+tfmx_count)
                    jr bender                       ;nix tun
                    
tfmx1:              ld a,(ix+mod_f_max)
                    and a
                    jp m,get_mod_f_max
                    add a,a                         ;0...127 -> 0..254
                    jr tfmx_mod
get_mod_f_max:      and 7fh                         ;128...255 -> 0...127

tfmx_mod:           ld b,a                          ;Maxwert -> b
                    ld a,(ix+mod_f_work)
                    ld c,(ix+flags)
                    bit 7,c
                    jr z,tfmx_mod1
                    bit 6,c
                    jr nz,tfmx_mod3                 ;kein add / sub
tfmx_mod1:          bit 5,c
                    jr nz,f_add
                    
;------------------ b5 = 0, subtrahieren -----------------------------------

                    sub (ix+delta_f)
                    jr nc,tfmx_mod2                 ;>0
                    set 5,c                         ;auf addieren umschalten
                    xor a
                    jr tfmx_mod2
                    
;------------------ b5 = 1, addieren ---------------------------------------

f_add:              add a,(ix+delta_f)
                    cp b                            ;Maxwert > a ?
                    jr c,tfmx_mod2                  ;ja
                    res 5,c                         ;auf sub umschalten
                    ld a,b                          ;Maxwer
                    
tfmx_mod2:          ld (ix+mod_f_work),a            ;zurÅck
                    
tfmx_mod3:          ld h,0
                    srl b                           ;Maxwert / 2
                    sub b                           ;-max/2 ... +max/2
                    jr nc,tfmx_mod4                 ;positiv
                    ld h,0ffh                       ;negativ
tfmx_mod4:          ld l,a
                    ld a,(note2)
                    add a,160
                    jr c,tfmx_mod6                  ;die high 4 Oktaven
tfmx_mod5:          add hl,hl                       ;delta f verdoppeln
                    add a,24                        ;1 Oktave hîher
                    jr nc,tfmx_mod5          
tfmx_mod6:          add hl,de                       ;YM-Frequenz Ñndern
                    ex de,hl
                    ld a,40h                        ;Bit 6 kippeln
                    xor c
                    ld (ix+flags),a                 ;Flags speichern

;------------------ Frequenz-Bender ----------------------------------------

bender:                       
                    bit 5,(ix+seq_hkurve)           ;benden ?
                    jr z,w_amplitude                ;nî
                    
;der Bender arbeitete mit Festkommazahlen
;xxxx.xx (16 Bit Vorkamma, 8 Bit Nachkomma-Stellen 

                    ld b,(ix+seq_instr)             ;x.x -Format
                    ld c,0
                    sra b
                    rr c
                    sra b
                    rr c
                    sra b
                    rr c
                    sra b
                    rr c
                    xor a
                    bit 7,b                         ;BC positiv ?
                    jr z,bender1                    ;ja
                    dec a                           ;a=-1

;bendvar = bendvar + ab.c

bender1:            ld l,(ix+bend_var)              ;Nachkommastellen
                    ld h,(ix+bend_var+1)            ;Vorkomma
                    add hl,bc
                    adc a,(ix+bend_var+2)
                    ld (ix+bend_var),l
                    ld (ix+bend_var+1),h
                    ld (ix+bend_var+2),a
                    ld l,h                          ;der Integer-Anteil
                    ld h,a
                    ex de,hl
                    xor a
                    sbc hl,de                       ;von YM-Freq abziehen
                    ex de,hl

w_amplitude:        ld a,(ix+hkurve_amplitude)
                    sub (ix+track_daempfung)
                    sub (ix+daempfung)
                    ret p                           ;>=0
                    xor a                           ;negativ, Amplitude = 0
                    ret
                    
    
;------------------ Z80-UP's (die gibt es beim 68000 nicht)-----------------

mul12:              push bc
                    add hl,hl                       ;*2
                    add hl,hl                       ;*4
                    ld b,h
                    ld c,l
                    add hl,hl                       ;*8
                    add hl,bc                       ;*8 + *4
                    pop bc
                    ret

mul:                xor a
                    or d
                    jp p,mv
                    ld hl,0
                    sbc hl,de
                    ex de,hl
                    ld hl,0
                    and a
                    sbc hl,bc
                    ld b,h
                    ld c,l
mv:                 ld hl,0
                    ld a,16
                    srl d
                    rr e
zykl:               jr nc,noadd
                    add hl,bc
noadd:              sra h
                    rr l
                    rr d
                    rr e
                    dec a
                    jr nz,zykl
                    ld b,h
                    ld c,l
                    ret
                    
cls:                ld hl,4000h
                    ld bc,6144
cls1:               ld (hl),0ffh
                    inc hl
                    dec bc
                    ld a,b
                    or c
                    jr nz,cls1
                    ret
                    
test:               ld a,41h
                    call 9f4h
                    ret

wx:                 push bc
                    ld b,10
wx1:                djnz wx1
                    pop bc
                    ret

key:                ld bc,0bffeh
no_key:             in a,(c)
                    cpl
                    and 1fh
                    jr z,no_key                     ;keine Taste
key1:               in a,(c)
                    cpl
                    and 1fh
                    jr nz,key1                      ;Taste
                    ret

; A Bytes ab (hl)

send:               push bc
                    push de
                    ld d,a
                    ld bc,nr
                    ld a,14                         ;Port A
                    out (c),a
                    ld bc,data
send1:              ld a,(hl)
                    out (c),a
                    xor a
                    out (0feh),a
                    inc hl
                    call wx
                    ld a,0ffh
                    out (0feh),a
                    call wx
                    dec d
                    jr nz,send1
                    pop de
                    pop bc
                    ret
                                                                                               
note2:              db 0                            ;tja, der Z80 hat zuwenig Register !
                    db 0
dreieck:            db 0

;---------------------------------------------------------------------------
adr_coso:           dw 0
adr_instr:          dw 0
adr_h_kurve:        dw 0
adr_sequenz:        dw 0
adr_track:          dw 0
adr_sound:          dw 0
adr_effekt:         dw 0
mmme_flag:          db 0
relozier_flag:      db 0
play_speed:         db 0
play_speed_count:   db 0
track_length:       dw 0

voice0:             ds 54
voice1:             ds 54
voice2:             ds 54

default_h:          db 001h,000h,000h,000h,000h
                    db 000h,000h,0e1h

ym_set:             db 0                            ;diese Werte werden
                    db 0                            ;in den Soundchip
                    db 0                            ;Åbertragen
                    db 0
                    db 0
                    db 0
ym_set6:            db 0
ym_set7:            db 3fh
                    db 0
                    db 0
                    db 0
                                        
; 8 Oktaven von c1...h1 ( 32,7 ... 61,7 Hz )
;           bis c5...h5 (4186 ... 7902,1 Hz ) ( die hohen Freq sind leider
;                                               etwas ungenau )


                                    
;Dies ist die Orginaltabelle vom Atari ST, Der Soundchip wird
;mit 2 Mhz getaktet

teiler_faktor:      dw 3822,3607,3405,3214,3033,2863,2702,2551,2407,2272,2145,2024
                    dw 1911,1803,1702,1607,1516,1431,1351,1275,1203,1136,1072,1012
                    dw 955,901,851,803,758,715,675,637,601,568,536,506
                    dw 477,450,425,401,379,357,337,318,300,284,268,253
                    dw 238,225,212,200,189,178,168,159,150,142,134,126
                    dw 119,112,106,100,94,89,84,79,75,71,67,63
                    dw 59,56,53,50,47,44,42,39,37,35,33,31
                    dw 29,28,26,25,23,22,21,19,18,17,16,15                

;die Tabelle fÅr den ZX Spectrum (Taktfrequenz  1.7734 Mhz )


;  dw 3389, 3199, 3019, 2850, 2690, 2539, 2397, 2262, 2135, 2015, 1902, 1795
;  dw 1695, 1599, 1510, 1425, 1345, 1270, 1198, 1131, 1068, 1008, 951, 898
;  dw 847, 800, 755, 712, 673, 635, 599, 566, 534, 504, 476, 449
;  dw 424, 400, 377, 356, 336, 317, 300, 283, 267, 252, 238, 224
;  dw 212, 200, 189, 178, 168, 159, 150, 141, 133, 126, 119, 112
;  dw 106, 100, 94, 89, 84, 79, 75, 71, 67, 63, 59, 56
;  dw 53, 50, 47, 45, 42, 40, 37, 35, 33, 31, 30, 28
;  dw 26, 25, 24, 22, 21, 20, 19, 18, 17, 16, 15, 14


coso:               incb jambala1.snd 					;die Sounddaten              
                                               
int_tab:                                              ;I-Vekto low = $00-$ff




