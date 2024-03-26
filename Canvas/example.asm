.586
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc

includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sectiunile programului, date, respectiv cod
.data
;aici declaram date
window_title DB "Exemplu proiect desenare",0
area_width EQU 640
area_height EQU 480
area DD 0


GAME_OVER DD 0 ; va decide daca jocul se termina sau nu
counter DD 0 ; numara evenimentele de tip timer
counter0 DD 0; va numara pt primul set de obstacole
counter1 DD 0 ; va numara pt al doilea set de  obstacole
counter2 DD 0 ; va numara pt al treilea set de obstacole
counter3 DD 0 ; va numara pt al patrulea det de obstacole
counter4 DD 0 ; va numara pt al cincilea obstacol
counter5 DD 0 ; va numara pt al saselea obstacol

counter_click DD 0 ; numara cate clickuri s au dat
random_number DD 0 ; definim un numar random care ne va genera obstacolele
VALID DD 0 ; vom vedea prin variabila asta daca s a dat click sau nu 
counter_points DD 0; va numara cate puncte a facut utilizatorul
arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20
botton_size_width EQU 640
botton_size_hight EQU 480 
bird_x EQU 200 ; y ul la care se afla pasarea
bird_y EQU 200 ; x ul la care se afla pasarea
len_obstacol EQU 30 ; latimea unui obstacol
start_obstacol EQU 610 ; de la ce x sa porneasca obstacolele
next_obstacol EQU 40 ; dupa cat timp sa apara urm obstacol 
intrare EQU  100
final_time EQU 75 ; cand counterul ajuge la 75 sa se stearga obstacolul


symbol_width EQU 10
symbol_height EQU 20
include digits.inc
include letters.inc

.code
; procedura make_text afiseaza o litera sau o cifra la coordonatele date
; arg1 - simbolul de afisat (litera sau cifra)
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y
make_text proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1] ; citim simbolul de afisat
	cmp eax, 'A'
	jl make_digit
	cmp eax, 'Z'
	jg make_digit
	sub eax, 'A'
	lea esi, letters
	jmp draw_text
make_digit:
	cmp eax, '0'
	jl make_space
	cmp eax, '9'
	jg make_space
	sub eax, '0'
	lea esi, digits
	jmp draw_text
make_space:	
	mov eax, 26 ; de la 0 pana la 25 sunt litere, 26 e space
	lea esi, letters
	
draw_text:
	mov ebx, symbol_width
	mul ebx
	mov ebx, symbol_height
	mul ebx
	add esi, eax
	mov ecx, symbol_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, symbol_width
bucla_simbol_coloane:
	cmp byte ptr [esi], 0
	je simbol_pixel_alb
	mov dword ptr [edi], 0
	jmp simbol_pixel_next
simbol_pixel_alb:
	mov dword ptr [edi], 0FFFFFFh
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
make_text endp

; un macro ca sa apelam mai usor desenarea simbolului
make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 16
endm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
line_horizontal macro x, y, len, color
local bucla_linie_orizontala
	mov EAX, y ; EAX = y
	mov EBX, area_width ; EBX = area_width
	mul EBX; EAX = y * area_width
	add EAX, x ; EAX = y * area_width + x
	shl EAX, 2; EAX = (y * area_width + x) * 4
	add EAX, area
	mov EDX, len
bucla_linie_orizontala :
	mov dword ptr[EAX], color
	add EAX, 4
	dec EDX
	jnz bucla_linie_orizontala
endm

line_vertical macro x, y, len, color
local bucla_linie_verticala
	mov EAX, y ; EAX = y
	mov EBX, area_width ; EBX = area_width
	mul EBX; EAX = y * area_width
	add EAX, x ; EAX = y * area_width + x
	shl EAX, 2; EAX = (y * area_width + x) * 4
	add EAX, area
	mov EDX, len
bucla_linie_verticala :
	mov dword ptr[EAX], color
	add EAX, area_width * 4
	dec EDX
	jnz bucla_linie_verticala
endm


generate_bird macro x, y, color
local bucla_corp
local bucla_aripi
local bucla_coada
; desenam corpul pasarii
	mov ECX, 9
	mov EDI, 4
bucla_corp :
	mov ESI, y
	sub ESI, EDI
	line_horizontal x, ESI, 50, color
	dec EDI
	loop bucla_corp
; desenam aripile
	mov ESI, x
	add ESI, 30
	add ECX, y
	sub ECX, 24
	line_vertical ESI, ECX, 50, color
	inc ESI
	line_vertical ESI, ECX, 50, color
	inc ESI
	line_vertical ESI, ECX, 50, color
	inc ESI
	line_vertical ESI, ECX, 50, color
	inc ESI
	line_vertical ESI, ECX, 50, color
	inc ESI
	line_vertical ESI, ECX, 50, color
	inc ESI
	line_vertical ESI, ECX, 50, color
	inc ESI
	line_vertical ESI, ECX, 50, color
	inc ESI
	line_vertical ESI, ECX, 50, color
	inc ESI
	line_vertical ESI, ECX, 50, color
; desenam coada
	mov ESI, x
	mov ECX, y
	sub ECX, 14
	line_vertical ESI, ECX, 30, color
	inc ESI
	line_vertical ESI, ECX, 30, color
	inc ESI
	line_vertical ESI, ECX, 30, color
	inc ESI
	line_vertical ESI, ECX, 30, color
	inc ESI
	line_vertical ESI, ECX, 30, color
	inc ESI
	line_vertical ESI, ECX, 30, color
	inc ESI
	line_vertical ESI, ECX, 30, color
	inc ESI
	line_vertical ESI, ECX, 30, color
	inc ESI
	line_vertical ESI, ECX, 30, color
	inc ESI
	line_vertical ESI, ECX, 30, color
	
	
	
	
	
	; line_vertical bird_x - 10, 0, area_height - 1, color
	; mov EDI, y
	; add EDI, 24
	; line_horizontal 0, EDI, area_width - 1, color
	; sub EDI, 48
	;  0, EDI, area_width - 1, color
	; line_vertical bird_x + 50, 0, area_height - 1, color
	
endm

fly_bird macro counter, counter_click, VALID, GAME_OVER
	mov EBP, counter
	sub EBP, counter_click
	shl EBP, 3
	add EBP, bird_y
	sub EBP, 24
	cmp EBP, 1
	jg OK1
	mov GAME_OVER, 1
OK1 :
	add EBP, 48
	cmp EBP, area_height - 12
	jl OK2 
	mov GAME_OVER, 1
OK2 :
	sub EBP, 24
	cmp VALID, 0
	jnz miscare_in_sus
	generate_bird bird_x, EBP, 0
	add EBP, 8 ; 2
	generate_bird bird_x, EBP, 0FFFF00h
miscare_in_sus :
	cmp VALID, 1
	jne terminare_miscare
	add EBP, 8 ; 2
	generate_bird bird_x, EBP, 0
	sub EBP, 16 ; 4
	generate_bird bird_x, EBP, 0FFFF00h

	dec VALID
	add counter_click, 2; 2
terminare_miscare :
endm
draw_rectangle_up macro x, y, H, color
local loop_r_up
	mov ECX, H
loop_r_up :
	mov EDI, y
	add EDI, ECX
	line_horizontal x, EDI, len_obstacol, color
	loop loop_r_up
endm

draw_rectangle_down macro x, y, H, color
local loop_r_down
	mov ECX, H
loop_r_down :
	mov EDI, y
	sub EDI, ECX
	line_horizontal x, EDI, len_obstacol, color
	loop loop_r_down
endm

draw_obstacol1 macro counter, H
local distruge_obstacol
local end_distrugere
	cmp counter, final_time
	jg distruge_obstacol
	mov EAX, counter
	shl EAX, 3 ; 2
	mov ESI, start_obstacol
	sub ESI, EAX
	mov EBP, area_width
	sub EBP, EAX
	draw_rectangle_down ESI, area_height, H, 0FFh
	draw_rectangle_up ESI, 0, area_height - H - intrare, 0FFh
	line_vertical EBP, 0, area_height - H - intrare + 1, 0
	line_vertical EBP, area_height - H, H, 0
	dec EBP
	line_vertical EBP, 0, area_height - H - intrare + 1, 0
	line_vertical EBP, area_height - H, H, 0
	dec EBP
	line_vertical EBP, 0, area_height - H - intrare + 1, 0
	line_vertical EBP, area_height - H , H, 0
	dec EBP
	line_vertical EBP, 1, area_height - H - intrare + 1, 0
	line_vertical EBP, area_height - H, H, 0
	dec EBP
	line_vertical EBP, 1, area_height - H - intrare + 1, 0
	line_vertical EBP, area_height - H, H, 0
	dec EBP
	line_vertical EBP, 1, area_height - H - intrare + 1, 0
	line_vertical EBP, area_height - H, H, 0
	dec EBP
	line_vertical EBP, 1, area_height - H - intrare + 1, 0
	line_vertical EBP, area_height - H, H, 0
	dec EBP
	line_vertical EBP, 1, area_height - H - intrare + 1, 0
	line_vertical EBP, area_height - H, H, 0
distruge_obstacol :
	cmp counter, final_time 
	jne end_distrugere
	draw_rectangle_down 9, area_height, H, 0
	draw_rectangle_up 9, 0, area_height - H - intrare + 1, 0
end_distrugere : 
	
endm

calcul_puncte macro counter, counter_click, H, counter_points, cnt, GAME_OVER
;local nu_ne_intereseaza
local inca_nu

; aici se va calcula acordarea punctului
    mov ECX, counter
	sub ECX, counter_click
	shl ECX, 3
	add ECX, bird_y
	sub ECX, 24 ; fi atent aici!!!
	cmp cnt, 54
	jne inca_nu
	cmp ECX, area_height - H - intrare
	jl inca_nu
	add ECX, 48
	;add EBX, intrare
	cmp ECX, area_height - H
	jg inca_nu
	inc counter_points
	inca_nu :

endm

stop macro counter, counter_click, H, cnt, GAME_OVER
local not_stop
local urmatoarea_comparare
local urmatoarea_comparare2
	cmp cnt, 46
	jl not_stop
	cmp cnt, 53
	jg not_stop
	mov ECX, counter
	sub ECX, counter_click
	shl ECX, 3
	add ECX, bird_y
	sub ECX, 24 ; fi atent aici!!!
	cmp ECX, area_height - H - intrare - 8
	jg urmatoarea_comparare
	mov GAME_OVER, 1
urmatoarea_comparare :
	add ECX, 48
	cmp ECX, area_height - H - 8
	jl not_stop
	mov GAME_OVER, 1
not_stop :

	
	
endm
; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click)
; arg2 - x
; arg3 - y
draw proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1]
	cmp eax, 1
	jz evt_click
	cmp eax, 2
	jz evt_timer ; nu s-a efectuat click pe nimic
	;mai jos e codul care intializeaza fereastra cu pixeli albi
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 0
	push area
	call memset
	add esp, 12
	jmp afisare_litere
	
evt_click:
	inc counter_click
	inc VALID ; se va verifica daca s a dat click
evt_timer:
	inc counter
	
	cmp GAME_OVER, 1
	je nu_mai_desena
	fly_bird counter, counter_click, VALID, GAME_OVER
	inc counter0
	; cmp counter0, 10
	; jg deseneaza
	; deseneaza :
    draw_obstacol1 counter0, 200
	stop counter, counter_click, 200, counter0, GAME_OVER
	calcul_puncte counter, counter_click, 200, counter_points, counter0, GAME_OVER
	cmp counter0, 25
	jl urm_instr1
	inc counter1
	draw_obstacol1 counter1, 100 
	stop counter, counter_click, 100, counter1, GAME_OVER
	calcul_puncte counter, counter_click, 100, counter_points, counter1, GAME_OVER
urm_instr1 :
	cmp counter1, 25
	jl urm_instr2
	inc counter2
	draw_obstacol1 counter2, 150
	stop counter, counter_click, 150, counter2, GAME_OVER
	calcul_puncte counter, counter_click, 150, counter_points, counter2, GAME_OVER
urm_instr2 :
	cmp counter2, 25
	jl urm_instr3
	inc counter3
	draw_obstacol1 counter3, 250 
	stop counter, counter_click, 250, counter3, GAME_OVER
	calcul_puncte counter, counter_click, 250, counter_points, counter3, GAME_OVER
urm_instr3 :
	cmp counter3, 25
	jl urm_instr4
	inc counter4
	draw_obstacol1 counter4, 100 
	stop counter, counter_click, 100, counter4, GAME_OVER
	calcul_puncte counter, counter_click, 100, counter_points, counter4, GAME_OVER
urm_instr4 :
	cmp counter4, 25
	jl urm_instr5
	draw_obstacol1 counter0, 200
	stop counter, counter_click, 200, counter5, GAME_OVER
	calcul_puncte counter, counter_click, 200, counter_points, counter5, GAME_OVER
urm_instr5 :
	cmp counter0, 125
	jl urm_instr6
	mov counter0, 0
	cmp counter1, 100
	jl urm_instr6
	mov counter1, 0
	cmp counter2, 125
	jl urm_instr6
	mov counter2, 0
	cmp counter3, 125
	jl urm_instr6
	mov counter3, 0
	cmp counter4, 125
	jl urm_instr6
	mov counter4, 0
	cmp counter5, 125
	jl urm_instr6
	mov counter5, 0
	; mov counter0, 0
	; mov counter1, 0
	; mov counter2, 0
	; mov counter3, 0
	
	urm_instr6 :
nu_mai_desena :
	;draw_obstacol2 counter
afisare_litere:
	;afisam valoarea counter-ului curent (sute, zeci si unitati)
	mov ebx, 10
	mov eax, counter
	;cifra unitatilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 30, 10
	;cifra zecilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 20, 10
	;cifra sutelor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 10, 10
; counterul pt obstacole
	;afisam valoarea counter-ului curent (sute, zeci si unitati)
	mov ebx, 10
	mov eax, counter_points
	;cifra unitatilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 70, 10
	;cifra zecilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 60, 10
	;cifra sutelor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 50, 10
	;scriem un mesaj
	; make_text_macro 'G', area, 110, 100
	; make_text_macro 'A', area, 120, 100
	; make_text_macro 'M', area, 130, 100
	; make_text_macro 'E', area, 140, 100
	; make_text_macro 'E', area, 150, 100
	; make_text_macro 'C', area, 160, 100
	; make_text_macro 'T', area, 170, 100
	
	; make_text_macro 'L', area, 130, 120
	; make_text_macro 'A', area, 140, 120
	
	; make_text_macro 'O', area, 100, 140
	; make_text_macro 'V', area, 110, 140
	; make_text_macro 'E', area, 120, 140
	; make_text_macro 'R', area, 130, 140
	; make_text_macro 'B', area, 140, 140
	; make_text_macro 'L', area, 150, 140
	; make_text_macro 'A', area, 160, 140
	; make_text_macro 'R', area, 170, 140
	; make_text_macro 'E', area, 180, 140
terminare_joc : 
	
	cmp GAME_OVER, 1
	jne nu_afisa
	make_text_macro 'G', area, 110, 100
	make_text_macro 'A', area, 120, 100
	make_text_macro 'M', area, 130, 100
	make_text_macro 'E', area, 140, 100
	
	make_text_macro 'O', area, 110, 120
	make_text_macro 'V', area, 120, 120
	make_text_macro 'E', area, 130, 120
	make_text_macro 'R', area, 140, 120
nu_afisa :
final_draw:
	popa
	mov esp, ebp
	pop ebp
	ret
draw endp

start:
	;alocam memorie pentru zona de desenat
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	call malloc
	add esp, 4
	mov area, eax
	;apelam functia de desenare a ferestrei
	; typedef void (*DrawFunc)(int evt, int x, int y);
	; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
	push offset draw
	push area
	push area_height
	push area_width
	push offset window_title
	call BeginDrawing
	add esp, 20
	;terminarea programului
	push 0
	call exit
end start
