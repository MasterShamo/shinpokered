Random_::
; Generate a random 16-bit value.
;	ld a, [rDIV]
;	ld b, a
;	ld a, [hRandomAdd]
;	adc b
;	ld [hRandomAdd], a
;	ld a, [rDIV]
;	ld b, a
;	ld a, [hRandomSub]
;	sbc b
;	ld [hRandomSub], a
;	ret

;joenote - implementing Patrik Rak's Xor-Shift random number generator
;Found at https://gist.github.com/raxoft/2275716fea577b48f7f0
;Patrik Rak released this code into public domain.

; 8-bit Xor-Shift random number generator.
; Created by Patrik Rak in 2008 and revised in 2011/2012.
; See http://www.worldofspectrum.org/forums/showthread.php?t=23070

	;load X[n] into bc
	ld hl, hRandomAdd + 1
	ld a, [hld]
	ld b, a
	ld a, [hl]
	ld c, a
	;load X[n-1] into de
	ld hl, hRandomLast + 1
	ld a, [hld]
	ld d, a
	ld a, [hli]
	ld e, a
	;X[n-1] = X[n] 
	ld a, b
	ld [hld], a
	ld a, c
	ld [hl], a
	
	ld  a,c         
    add a,a
    add a,a
    add a,a
    xor c
    ld  c,a
    ld  a,d         
    add a,a
    xor d
    ld  b,a
    rra             
    xor b
    xor c
    ld  b,e         
    ld  c,a    
	
	ld hl, hRandomAdd + 1
	ld a, b
	ld [hld], a
	ld a, c
	ld [hl], a
 	ret
