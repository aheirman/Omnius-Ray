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

INCLUDE "MISC.INC"
INCLUDE "VIDEO.INC"
INCLUDE "VEC.INC"
INCLUDE "RAYTRACE.INC"


; -------------------------------------------------------------------
; CODE
; -------------------------------------------------------------------
CODESEG

;PROC test_place
;@@LOCAL_STACK_SIZE EQU 2*RAY_SIZE
;	uses eax, ebx, ecx, edx, edi
;	
;	push ebp
;	mov ebp, esp
;	
;	mov ecx, @@LOCAL_STACK_SIZE
;	sub esp, ecx
;	;----------
;	; Zero initialize
;	xor eax, eax
;	cld
;	mov edi, esp
;rep stosb
;	;----------
;	
;	mov eax, esp
;	add eax, RAY_SIZE
;	mov ebx, esp
;	
;	mov [dword eax + 
;	
;	call normalize_vec3_dest, eax, ebx
;	
;	call terminate_process
;ENDP

PROC main
	sti
	cld
	
	push ds
	pop	es
	finit
	
	call	setVideoMode,13h
	
	
	call truecolor_palette
	call updateColourPalette, 256
	;call drawGradient_256
	
	;call	draw_triangle,60,60,60,60, 32
	;call	draw_triangle,80,80,100,100, 63
	;call	draw_triangle,1,1,SCRWIDTH-2,SCRHEIGHT-2, 48
	
	;call	draw_rectangle,60,60,60,60, 32
	;call	draw_rectangle,80,80,100,100, 63
	;call	draw_rectangle,1,1,SCRWIDTH-2,SCRHEIGHT-2, 48
	
	call ray_trace
	
	
	mov	ah,00h
	int	16h
	
	call terminate_process
ENDP main



; -------------------------------------------------------------------
; DATA
; -------------------------------------------------------------------
DATASEG

; -------------------------------------------------------------------
; STACK
; -------------------------------------------------------------------
STACK 300h; 100 bytes groot

END main
