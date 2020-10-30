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
INCLUDE "RAYTRACE.INC"


; compile-time constants (with macros)
VMEMADR EQU 0A0000h	; video memory address
SCRWIDTH EQU 320	; screen witdth
SCRHEIGHT EQU 200	; screen height

; -------------------------------------------------------------------
; CODE
; -------------------------------------------------------------------
CODESEG


PROC main
	sti
	cld
	
	push ds
	pop	es
	finit
	
	call	setVideoMode,13h
	
	
	call 	gradientPalette
	call	updateColourPalette, 64
	
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
