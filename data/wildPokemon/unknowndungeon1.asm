DungeonMons1:;joenote - swapped sandslash/arbok
	db $0A
	db 46,GOLBAT
	db 46,HYPNO
	db 46,MAGNETON
IF DEF (_BLUEJP)
	db 49,RAPIDASH
ELSE
	db 49,DODRIO
ENDC
	db 49,VENOMOTH
	db 49,KADABRA
IF DEF(_RED)
	db 52,SANDSLASH
ELSE
	db 52,ARBOK
ENDC
	db 52,PARASECT
	db 53,DITTO
	db 53,RAICHU
	db $00
