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
INCLUDE "STRUC.INC"
INCLUDE "VIDEO.INC"
INCLUDE "VEC.INC"
INCLUDE "RAYTRACE.INC"
INCLUDE "RAND.INC"
INCLUDE "FILE.INC"
INCLUDE "MACRO.INC"

; -------------------------------------------------------------------
; CODE
; -------------------------------------------------------------------
CODESEG

PROC test_place
	LOCAL @@v_tmp1:vec3, @@v_tmp2:vec3, @@tmp1:dword, @@tmp2:dword
	uses eax, ebx, ecx, edx, edi
	ret
	lea eax, [@@v_tmp1]
	mov ecx, [dword offset nr_2]
	mov [eax + vec3.x], ecx
	mov [eax + vec3.y], ecx
	mov [eax + vec3.z], ecx
	
	lea ebx, [@@v_tmp2]
	mov ecx, [dword offset nr_3]
	mov [ebx + vec3.x], ecx
	mov [ebx + vec3.y], ecx
	mov [ebx + vec3.z], ecx

	fld [dword offset nr_half]
	VEC3_LOAD  <dword eax + vec3.>
	VEC3_LOAD  <dword ebx + vec3.>
	;fldpi
	;VEC3S_ST_MUL <6>
	;VEC3_VEC3_ADD
	;VEC3_VEC3_DOT_ST0
	;VEC3_OFFSET_ST0_MUL <1>
	;VEC3D_NORMALIZE
	;VEC3_VEC3_ST6_WEIGHTED_AVG
	
	lea ecx, [@@tmp1]
	lea edx, [@@tmp2]
	;fstp [dword ecx]
	;fstp [dword edx]
	
	VEC3_STOREP <dword ebx + vec3.>
	VEC3_STOREP <dword eax + vec3.>
	
	call random_float_0_1, ecx
	call print_rounded_floatx1000, [dword ecx]
		call random_float_0_1, ecx
	call print_rounded_floatx1000, [dword ecx]
		call random_float_0_1, ecx
	call print_rounded_floatx1000, [dword ecx]
		call random_float_0_1, ecx
	call print_rounded_floatx1000, [dword ecx]
		call random_float_0_1, ecx
	call print_rounded_floatx1000, [dword ecx]
		call random_float_0_1, ecx
	call print_rounded_floatx1000, [dword ecx]
		call random_float_0_1, ecx
	call print_rounded_floatx1000, [dword ecx]
		call random_float_0_1, ecx
	call print_rounded_floatx1000, [dword ecx]
		call random_float_0_1, ecx
	call print_rounded_floatx1000, [dword ecx]
		call random_float_0_1, ecx
	call print_rounded_floatx1000, [dword ecx]
		call random_float_0_1, ecx
	call print_rounded_floatx1000, [dword ecx]
		call random_float_0_1, ecx
	call print_rounded_floatx1000, [dword ecx]
	;call print_rounded_floatx1000, [dword edx]
	call print_endl
	;call print_vec3_x1000, ebx
	;call print_vec3_x1000, eax

	call print_int, 6

	mov	ah,00h
	int	16h
	call terminate_process
	
@@error_handler:
	mov ah, 09h
	mov edx, offset msg_comparison_was_indeterminate
	int 21h
	
	mov	ah,00h
	int	16h
	call terminate_process
ENDP test_place


PROC main
	sti
	cld
	
	push ds
	pop	es
	finit
	call rand_init
	
	call test_place
	
	call create_bmp
	
	call setVideoMode,13h
	call truecolor_palette
	call updateColourPalette, 256
	
	call ray_trace
	call close_bmp
	;call ray_info
	
	mov	ah,00h
	int	16h
	
	call terminate_process
ENDP main



; -------------------------------------------------------------------
; DATA
; -------------------------------------------------------------------
DATASEG
	nr_four           dd 4.0
	nr_2            dd 2.0
	nr_3            dd 3.0
	nr_1            dd 1.0
	nr_10000 dd 10000.0
	nr_tiny           dd 0.0001
	nr_half dd 0.5

	nr_10    dd 10.0
	pixel_samples vec3  4 DUP(?)

msg_comparison_was_indeterminate db "Floating point comparison was indeterminate", 13, 10, '$';
; -------------------------------------------------------------------
; STACK
; -------------------------------------------------------------------
STACK 400h; 100 bytes groot

END main
