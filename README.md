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
; dieser Player ist für den ZX-Spectrum, wird aber bestimmt nach
; einigen Anpassungen auf den Schneider CPC funktionieren
