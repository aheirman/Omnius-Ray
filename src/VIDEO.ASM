; -------------------------------------------------------------------
; 80386
; 32-bit x86 assembly language
; TASM
;
; author:       Aron Heirman
; date:         27/10/2020
; program:      Hello World!
; -------------------------------------------------------------------

IDEAL
P386
MODEL FLAT, C

ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

INCLUDE "VIDEO.INC"


; compile-time constants (with macros)
VMEMADR EQU 0A0000h	; video memory address
SCRWIDTH EQU 320	; screen witdth
SCRHEIGHT EQU 200	; screen height

; -------------------------------------------------------------------
; CODE
; -------------------------------------------------------------------
CODESEG

; create a gradient palette
PROC gradientPalette
	USES eax, ecx, edx
	;---
	; Set Colors
	;---
	
	xor ecx, ecx
	mov eax, offset palette
	
@@begin_gradient_loop:
	mov [eax],   cl; rgb hebben dezelfde intensiteit
	mov [eax+1], cl
	mov [eax+2], cl
	
	add eax, 3
	inc ecx
	cmp ecx, 64
	jnz @@begin_gradient_loop
	
	;call print_byte_list, 16, offset palette
	
	ret
ENDP gradientPalette

; create a 8-bit truecolor palette
PROC truecolor_palette
	USES eax, ecx, edx
	;---
	; Set Colors
	;---
	
	xor ecx, ecx
	mov eax, offset palette
	;Bit    7  6  5  4  3  2  1  0
	;Data   R  R  R  G  G  G  B  B
	
@@begin_r_loop:
	mov edx, ecx
	and edx, 224
	shr edx, 2
	mov [eax],   dl; r, 6bit
	mov edx, ecx
	and edx, 28
	shl edx, 1
	mov [eax+1], dl; g
	mov edx, ecx
	and edx, 3
	shl edx, 4
	mov [eax+2], dl; b
	
	add eax, 3
	inc ecx
	cmp ecx, 256
	jnz @@begin_r_loop
	
	
	ret
ENDP truecolor_palette





; Update the colour palette.
PROC updateColourPalette
	ARG @@num_colors:word
	USES eax, ecx, edx, esi

	;---
	movzx ecx, [@@num_colors]
	
	lea ecx, [2*ecx + ecx]
	xor eax, eax

	cld; clears direction flag 
	mov esi, offset palette ; set the palette (DAC) address
	mov dx, 03c8h  ; VGA DAC set port
	mov al, 0      ; set start color index
	
	out dx, al
	inc dx
rep outsb
	ret
ENDP updateColourPalette

; draw gradient on screen
PROC drawGradient_64
	USES eax, ecx, edi

	mov edi, VMEMADR
	mov ecx, SCRHEIGHT
	
@@screenloop:
	xor ax, ax
	push ecx
@@lineloop:
	mov ecx, SCRWIDTH/64
rep stosb
	inc ax
	cmp ax, 64
	jl @@lineloop
	pop ecx
	loop @@screenloop


	ret
ENDP drawGradient_64

PROC drawGradient_256
	USES eax, ecx, edi

	mov edi, VMEMADR
	mov ecx, SCRHEIGHT
	
@@screenloop:
	xor ax, ax
	push ecx
@@lineloop:
    stosb
	inc ax
	cmp ax, 256
	jl @@lineloop
	add edi,  SCRWIDTH-256
	pop ecx
	loop @@screenloop


	ret
ENDP drawGradient_256

; Fill the background (for mode 13h)
PROC fillBackground
	ARG @@color:byte
	USES eax, ebx, ecx, edx, esi
	
	;---
	; Fill Screen
	;---
;	xor ecx, ecx
;	mov eax, 0a0000h
;	mov bl, [@@color]
;	
;begin_fillBackground_loop:
;	mov [eax], bl
;	add eax, 1
;	inc ecx
;	cmp ecx, 64000
;	jnz begin_fillBackground_loop
	
	
	;---
	; Fill Screen 2
	;---
	mov edi, VMEMADR
	;mov esi, 0h
	mov ecx, 64000
	xor eax, eax
	mov	al, [@@color]
	CLD
REP 	STOSB

	ret
ENDP fillBackground



PROC draw_line
	ARG @@x0:dword, @@y0:dword, @@x1:dword, @@y1:dword, @@color:dword
	USES eax, ebx, ecx, edx, esi, edi
	
	; Based on:
	;https://github.com/ssloy/tinyrenderer/wiki/Lesson-1-Bresenham%E2%80%99s-Line-Drawing-Algorithm
	; Modified to not use floats!
	
	
	;---
	; Force: non steep
	;---
	mov eax, [@@x0]
	sub eax, [@@x1]
	mov ebx, eax
	sar ebx, 31
	xor eax, ebx
	sub eax, ebx;  eax = abs(x = x0-x1) = (x XOR y) - y, ebx = y, eax = x
	
	mov ecx, [@@y0]
	sub ecx, [@@y1]
	mov edx, ecx
	sar edx, 31
	xor ecx, edx
	sub ecx, edx;  ecx = abs(x = y0-y1) = (x XOR y) - y, edx = y, ecx = x
	
	cmp eax, ecx
	jge @@not_steep
	mov ecx, 1
	push ecx; steep = true
	
	mov eax, [@@x0]
	mov ebx, [@@y0]
	mov [@@x0], ebx
	mov [@@y0], eax
	
	mov eax, [@@x1]
	mov ebx, [@@y1]
	mov [@@x1], ebx
	mov [@@y1], eax
	
	jmp @@end_steep
@@not_steep:
	mov ecx, 0
	push ecx; steep = fasle
@@end_steep:


	;---
	; Force: x0 << x1
	;---
	mov eax, [@@x0]
	mov ebx, [@@x1]
	cmp eax, ebx
	jle @@no_swap
	mov [@@x0], ebx
	mov [@@x1], eax
	mov eax, [@@y0]
	mov ebx, [@@y1]
	mov [@@y0], ebx
	mov [@@y1], eax
@@no_swap:

	;---
	mov eax, [@@x1]
	sub eax, [@@x0]
	mov ecx, eax;    set up ecx
	inc ecx
	
	;ecx > 0
	cmp ecx, 0
	jng @@stop_exec
	;----
	
	;--
	mov eax, [@@y1]
	sub eax, [@@y0]
	mov esi, eax;    set up y1-y0
	;--
	mov eax, [@@x1]
	sub eax, [@@x0]
	mov edi, eax;    set up x1-x0
	;--
	xor eax, eax

	;--
	; ecx --> counter
	; eax --> delta x 
	; ebx --> y0 + delta y
	; edx --> 0
	; esi --> y1-y0
	; edi --> x1-x0
	;----

@@line_loop:
	push ecx
	;--
	; Calculate y
	;--
	xor edx, edx
	push eax
	imul esi;         (y1-y0)*delta x
	;NOT ALLOWED: xor edx, edx;
	idiv edi;         ((y1-y0)*delta x)/(x1-x0)
	mov ebx, eax
	add ebx, [@@y0]; y in  ebx
	pop eax;         delta x in eax
	
	push eax
	add eax, [@@x0]; x = x0 + delta x
	;--
	; Possible Detranspotation
	;--
	mov edx, [esp+8]
	cmp edx, 0
	je @@no_tranposation
	mov edx, eax; x   -> edx
	mov eax, ebx; y   -> x
	mov ebx, edx; edx -> y
@@no_tranposation:
	
	;--
	; Set pixel
	;--
	mov ecx, VMEMADR
	xor edx, edx;    NOT Optional
	add ecx, eax;    add x
	mov eax, SCRWIDTH
	mul ebx
	add ecx, eax;    add y
	
	mov edx, [@@color]
	mov [ecx], dl
	
	pop eax
	inc eax; ga naar de volgende x
	pop ecx
	loop @@line_loop
	
@@stop_exec:
	pop eax; remove steep from stack
	ret
ENDP draw_line

; Draw a triangle (video mode 13h)
PROC draw_triangle
	ARG @@x0:dword, @@y0:dword, @@width:dword, @@height:dword, @@color:dword
	USES eax, ebx, ecx, edx, esi, edi
	
	mov eax, [@@x0]
	
	mov edi, [@@width]
	shr edi, 1
	add edi, eax; edi == [@@x0] + 1/2 [@@width]
	add eax, [@@width]
	
	mov ebx, [@@y0]
	add ebx, [@@height]
	
	xor ecx, ecx
	mov ecx, [dword @@color]
	
	mov edx, [dword @@x0]
	mov esi, [dword @@y0]

	call draw_line, edx, esi, edi, ebx, ecx; links onder
	call draw_line, edi, ebx, eax, esi, ecx; rechts onder
	call draw_line, edx, esi, eax, esi, ecx; horizontaal

	ret
ENDP draw_triangle

; Draw a rectangle (video mode 13h)
PROC draw_rectangle
	ARG @@x0:dword, @@y0:dword, @@width:dword, @@height:dword, @@color:dword
	USES eax, ebx, ecx, edx, esi
	
	mov eax, [@@x0];     x0
	mov ebx, eax
	add ebx, [@@width] ; x1
	
	mov ecx, [@@y0];     y0
	mov edx, ecx;        y1
	add edx, [@@height]
	
	mov esi, [dword @@color]
	
	call draw_line, eax, edx, ebx, edx, esi; boven
	call draw_line, eax, ecx, ebx, ecx, esi; onder
	call draw_line, eax, ecx, eax, edx, esi; links
	call draw_line, ebx, ecx, ebx, edx, esi; rechts

	ret
ENDP draw_rectangle


DATASEG
    palette 			db 768 DUP(?)

END
