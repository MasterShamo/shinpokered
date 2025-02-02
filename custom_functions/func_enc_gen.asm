;replace random mew encounters with ditto if dex diploma not attained
DisallowWildMew:
	ld a, [wcf91]	;get the current pokemon in question
	cp MEW	;is it mew? zet zero flag if true
	ret nz	;if not mew, then return
	;else we have a potential mew encounter on our hands
	CheckEvent EVENT_90B
	jr z, .replace_mew	;if event 90B is zero, then diploma has not been granted. mew is not allowed.
	CheckEvent EVENT_8C0
	jr z, .mew_allowed	;mew can appear if not already encountered
.replace_mew
	ld a, DITTO	;load the ditto constant
	ld [wcf91], a	;overwrite mew with ditto
	ld [wEnemyMonSpecies2], a
	ret
.mew_allowed
;	;the slot that triggered the mew encounter has it's likelihood of a mew cut in half
;	;idea is to give mew a 0.6% encounter rate (lowest in the game)
;	ld a, [hRandomSub]
;	bit 0, a
;	jr nz, .replace_mew
	;going to encounter mew now
	SetEvent EVENT_8C0 ;mew has been encountered now
	ResetEvent EVENT_8C2 ;turn on mew notification
	ret

	
	

CheckIfPkmnReal:
;set the carry if pokemon number in 'a' is found on the list of legit pokemon
	push hl
	push de
	push bc
	ld hl, ListRealPkmn
	ld de, $0001
	call IsInArray
	pop bc
	pop de
	pop hl

;This function loads a random trainer class (value of $01 to $2F)
GetRandTrainer:
.reroll
	call Random
	and $30
	cp $30
	jr z, .reroll
	push bc
	ld b, a
	call Random
	and $0F
	add b
	pop bc
	and a
	jr z, .reroll
	add $C8
	ld [wEngagedTrainerClass], a
	ld a, 1
	ld [wEngagedTrainerSet], a
	ret

;gets a random pokemon and puts its hex ID in register a and wcf91
GetRandMonAny:
	ld de, ListRealPkmn
	;fall through
GetRandMon:
	push hl
	push bc
	ld h, d
	ld l, e
	call Random
	ld b, a
.loop
	ld a, b
	and a
	jr z, .endloop
	inc hl
	dec b
	ld a, [hl]
	and a
	jr nz, .loop
	ld h, d
	ld l, e
	jr .loop
.endloop
	ld a, [hl]
	pop bc
	pop hl
	ld [wcf91], a
	ret
	
;generates a randomized 6-party enemy trainer roster
GetRandRoster:
	push bc
	push de
	ld b, 6
	ld de, ListNonMythPkmn
	CheckEvent EVENT_90B	;check for diploma
	jp z, GetRandRosterLoop	;no mew if no diploma
	ld de, ListRealPkmn
	jp GetRandRosterLoop
GetRandRoster3:	;3-mon party
	push bc
	push de
	ld de, ListNonMewPkmn
	ld b, 3
GetRandRosterLoop:
	ld a, [wPartyMon1Level]
	ld [wCurEnemyLVL], a
.loop	
	push bc
	push de
	call GetRandMon
	ld a, ENEMY_PARTY_DATA
	ld [wMonDataLocation], a
	
	push hl
	call ScaleTrainer
	pop hl
	
	push hl
	call AddPartyMon
	call Random
	and $01
	ld b, a
	ld a, [wCurEnemyLVL]
	add b
	call PreventARegOverflow
	ld [wCurEnemyLVL], a
	pop hl
	
	pop de
	pop bc
	dec b
	jr nz, .loop
;end of loop
	pop de
	pop bc
	xor a	;set the zero flag before returning
	ret	

	

;implement a function to scale trainer levels
ScaleTrainer:
	CheckEvent EVENT_90C
	ret z
	push bc
	jr .getHighestLevel
.backFromLVLCheck
	push af
	ld a, [wCurEnemyLVL]
	ld b, a
	pop af
	cp b
	jr c, .nolvlincrease
	jr z, .nolvlincrease
	ld [wCurEnemyLVL], a
	call Random
	and $03
	ld b, a
	ld a, [wGymLeaderNo]
	and a
	jr z, .notboss
	ld a, [wCurEnemyLVL]
	add b
	call PreventARegOverflow
	ld [wCurEnemyLVL], a
	call Random
	and $03
	ld b, a
.notboss
	ld a, [wCurEnemyLVL]
	add b
	call PreventARegOverflow
	ld [wCurEnemyLVL], a
.nolvlincrease
	pop bc
	callba EnemyMonEvolve
	ret
.getHighestLevel
	push hl
	ld hl, wStartBattleLevels
	ld a, [wPartyCount]	;1 to 6
	ld b, a	;use b for countdown
.loadHigher
	ld a, [hl]
.keepCurrent
	dec b
	jr z, .highestLVLfound
	inc hl
	cp a, [hl]
	jr c, .loadHigher
	jr .keepCurrent
.highestLVLfound
	pop hl
	jr .backFromLVLCheck


; return a = 0 if not in safari zone, else a = 1 if in safari zone
IsInSafariZone:
	ld a, [wCurMap]
	cp SAFARI_ZONE_EAST
	jr c, .notSafari
	cp SAFARI_ZONE_REST_HOUSE_1
	jr nc, .notSafari
	ld a, $01
	jr .return
.notSafari
	ld a, $00
.return
	and a
	ret

;Generate a random mon for an expanded safari zone roster
GetRandMonSafari:
	;return if special safari zone not activated
	CheckEvent EVENT_90F
	ret z	
	;return if not in safari zone
	call IsInSafariZone
	ret z
	;else continue on
	call Random
	cp 26
	ret nc	;only a 26/256 chance to have an expanded encounter
	push hl
	push bc
	call GetSafariList
	call Random
	ld b, a
.loop
	ld a, b
	and a
	jr z, .endloop
	inc hl
	dec b
	ld a, [hl]
	and a
	jr nz, .loop
	call GetSafariList
	jr .loop
.endloop
	ld a, [hl]
	pop bc
	pop hl
	ld [wcf91], a
	ld [wEnemyMonSpecies2], a
	ret	

GetSafariList:	
	ld a, [wCurMap]
	cp SAFARI_ZONE_CENTER
	ld hl, ListNonLegendPkmn
	ret z
	cp SAFARI_ZONE_EAST
	ld hl, ListMidEvolvedPkmn
	ret z
	cp SAFARI_ZONE_NORTH
	ld hl, ListNonEvolvingPkmn
	ret z
	ld hl, ListMostEvolvedPkmn
	ret
	

;this will prevent an overflow of the A register
;typically for custom functions that increase enemy levels
;defaulted to 255 on an overflow
;call after a value was just added to register A
PreventARegOverflow:
	ret nc	;return if there was no overflow
	;else set A to the max
	ld a, $FF
	ret


;randomizes the 'mon in wcf91 to an unevolved 'mon then tries to evolve it	
RandomizeRegularTrainerMons:
	CheckEvent EVENT_8D8
	ret z
	push de
	ld de, ListNonLegendUnEvoPkmn
	call GetRandMon
	callba EnemyMonEvolve
	ld a, [wcf91]
	cp EEVEE
	call z, .handleeevee
	pop de
	ret
.handleeevee
	call Random
	and $0F
	cp $0A
	ret c	;eevee
	push af
	ld a, FLAREON
	ld [wcf91], a
	pop af
	cp $0C
	ret c ;flareon
	push af
	ld a, VAPOREON
	ld [wcf91], a
	pop af
	cp $0E
	ret c ;vaporeon
	;else jolteon
	ld a, JOLTEON
	ld [wcf91], a
	ret