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

; -------------------------------------------------------------------
; CODE
; -------------------------------------------------------------------
CODESEG

PROC test_place
@@LOCAL_STACK_SIZE EQU 2*RAY_SIZE
	uses eax, ebx, ecx, edx, edi
	
	push ebp
	mov ebp, esp
	
	mov ecx, @@LOCAL_STACK_SIZE
	sub esp, ecx
	;----------
	; Zero initialize
	xor eax, eax
	cld
	mov edi, esp
rep stosb
	;----------
	
	mov eax, esp
	add eax, RAY_SIZE
	mov ebx, esp
	
	;mov ecx, [offset nr_four]
	;mov [eax + vec3.x], ecx
	;mov [eax + vec3.y], ecx
	;mov [eax + vec3.z], ecx
	;
	;call print_vec3, eax
	;
	;call vec3_normalize_dest, eax, ebx
	;call vec3_mul_float_res, ebx, [offset nr_10000], ebx
	;call print_vec3, ebx
	
	;call random_float_0_1, ebx
	;call print_rounded_floatx1000, [dword ebx]
	call vec3_in_unit_sphere, ebx
	;call print_vec3, ebx
	;call print_vec3_x1000, ebx
	
	
	mov	ah,00h
	int	16h
	call terminate_process
ENDP test_place

PROC test_place_2
@@LOCAL_STACK_SIZE EQU VEC3_SIZE
	uses eax, ebx, ecx, edx, edi
	
	push ebp
	mov ebp, esp
	
	mov ecx, @@LOCAL_STACK_SIZE
	sub esp, ecx
	;----------
	; Zero initialize
	xor eax, eax
	cld
	mov edi, esp
rep stosb
	;----------
	
	mov eax, offset pixel_samples
	mov ecx, [offset nr_four]
	mov [eax + vec3.x], ecx
	mov [eax + vec3.y], ecx
	mov [eax + vec3.z], ecx
	call print_vec3, eax

	lea ebx, [offset pixel_samples + VEC3_SIZE]
	mov ecx, [offset nr_four]
	mov [ebx + vec3.x], ecx
	mov [ebx + vec3.y], ecx
	mov [ebx + vec3.z], ecx
	call print_vec3, ebx

	lea ebx, [offset pixel_samples + 2*VEC3_SIZE]
	mov ecx, [offset nr_two]
	mov [ebx + vec3.x], ecx
	mov [ebx + vec3.y], ecx
	mov [ebx + vec3.z], ecx
	call print_vec3, ebx

	lea ebx, [offset pixel_samples + 3*VEC3_SIZE]
	mov ecx, [offset nr_two]
	mov [ebx + vec3.x], ecx
	mov [ebx + vec3.y], ecx
	mov [ebx + vec3.z], ecx
	call print_vec3, ebx

	mov edx, esp
	call average_4_color_res, offset pixel_samples, offset pixel_samples
	call print_vec3, eax

	call vec3_mul_float_res, eax, [dword offset nr_10], edx
	call print_vec3, edx
	
	mov	ah,00h
	int	16h
	call terminate_process
ENDP test_place_2

PROC test_place_3

	
	
	mov	ah,00h
	int	16h
	call terminate_process
ENDP test_place_3

PROC main
	sti
	cld
	
	push ds
	pop	es
	finit
	call rand_init
	
	call create_bmp
	
	call setVideoMode,13h
	call truecolor_palette
	call updateColourPalette, 256
	
	call ray_trace
	
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
	nr_two            dd 2.0
	nr_10000 dd 10000.0

	nr_10    dd 10.0
	pixel_samples vec3  4 DUP(?)

; -------------------------------------------------------------------
; STACK
; -------------------------------------------------------------------
STACK 400h; 100 bytes groot

END main
