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

INCLUDE "VEC.INC"
INCLUDE "MISC.INC"
INCLUDE "STRUC.INC"

CODESEG

;IMPORTANT: ptrs may aliase (That's good) :)
PROC vec3_sub_res
	ARG @@VEC3_PTR_links:dword, @@VEC3_PTR_rechts:dword, @@res_ptr:dword
	USES eax, ebx, ecx
	
	mov eax, [@@VEC3_PTR_links]
	mov ebx, [@@VEC3_PTR_rechts]
	mov ecx, [@@res_ptr]
	
	fld [eax + vec3.x]
	fld [ebx + vec3.x]
	fsubp
	fstp [ecx + vec3.x]
	
	fld [eax + vec3.y]
	fld [ebx + vec3.y]
	fsubp
	fstp [ecx + vec3.y]
	
	fld [eax + vec3.z]
	fld [ebx + vec3.z]
	fsubp
	fstp [ecx + vec3.z]
	
	ret
ENDP vec3_sub_res

;IMPORTANT: ptrs may aliase (That's good) :)
PROC vec3_add_res
	ARG @@VEC3_PTR_links:dword, @@VEC3_PTR_rechts:dword, @@res_ptr:dword
	USES eax, ebx, ecx
	
	mov eax, [@@VEC3_PTR_links]
	mov ebx, [@@VEC3_PTR_rechts]
	mov ecx, [@@res_ptr]
	
	fld [eax + vec3.x]
	fld [ebx + vec3.x]
	faddp
	fstp [ecx + vec3.x]
	
	fld [eax + vec3.y]
	fld [ebx + vec3.y]
	faddp
	fstp [ecx + vec3.y]
	
	fld [eax + vec3.z]
	fld [ebx + vec3.z]
	faddp
	fstp [ecx + vec3.z]
	
	ret
ENDP vec3_add_res

;IMPORTANT: ptrs may aliase (That's good) :)
PROC vec3_add_float_res
	ARG @@VEC3_PTR:dword, @@FLOAT:dword, @@res_ptr:dword
	USES eax, ecx
	
	mov eax, [@@VEC3_PTR]
	mov ecx, [@@res_ptr]
	
	fld [eax + vec3.x]
	fld [@@FLOAT]
	faddp
	fstp [ecx + vec3.x]
	
	fld [eax + vec3.y]
	fld [@@FLOAT]
	faddp
	fstp [ecx + vec3.y]
	
	fld [eax + vec3.z]
	fld [@@FLOAT]
	faddp
	fstp [ecx + vec3.z]
	
	ret
ENDP vec3_add_float_res


;IMPORTANT: ptrs may aliase (That's good) :)
PROC vec3_mul_float_res
	ARG @@VEC3_PTR:dword, @@multiplier:dword, @@res_ptr:dword
	USES eax, ecx
	
	push [@@multiplier]
	
	mov eax, [@@VEC3_PTR]
	mov ecx, [@@res_ptr]
	
	fld [dword eax + vec3.x]
	fld [dword esp]
	fmulp
	fstp [ecx + vec3.x]
	
	fld [dword  eax + vec3.y]
	fld [dword  esp]
	fmulp
	fstp [ecx + vec3.y]
	
	fld [dword eax + vec3.z]
	fld [dword esp]
	fmulp
	fstp [ecx + vec3.z]
	
	pop eax; dummie
	
	ret
ENDP vec3_mul_float_res

;IMPORTANT: vec ptrs may aliase (That's good) :)
;PROC vec_3_mul_float_ptr_res
;	ARG @@VEC3_PTR:dword, @@multiplier_ptr:dword, @@res_ptr:dword
;	USES eax, ebx, ecx
;	
;	mov eax, [@@VEC3_PTR]
;	mov ecx, [@@res_ptr]
;	
;	fld [dword eax + vec3.x]
;	fld [dword @@multiplier_ptr]
;	faddp
;	fstp [ecx + vec3.x]
;	
;	fld [dword  eax + vec3.y]
;	fld [dword @@multiplier_ptr]
;	faddp
;	fstp [ecx + vec3.y]
;	
;	fld [dword eax + vec3.z]
;	fld [dword @@multiplier_ptr]
;	faddp
;	fstp [ecx + vec3.z]
;
;	ret
;ENDP vec_3_mul_float_ptr_res

;IMPORTANT: ptrs may aliase (That's good) :)
PROC vec3_dot
	ARG @@VEC3_PTR1:dword, @@VEC3_PTR2:dword, @@res_ptr:dword
	USES eax, ebx
	
	mov eax, [@@VEC3_PTR1]
	mov ebx, [@@VEC3_PTR2]
	
	fld  [dword eax + vec3.x]
	fmul [dword ebx + vec3.x]

	fld  [dword eax + vec3.y]
	fmul [dword ebx + vec3.y]
	
	fld  [dword eax + vec3.z]
	fmul [dword ebx + vec3.z]
	
	faddp
	faddp
	
	mov eax, [@@res_ptr]
	fstp [dword eax]
	
	ret
ENDP vec3_dot

PROC print_vec3
	ARG @@vec_ptr:dword
	uses eax, ecx
	
	mov eax, [@@vec_ptr]
	sub esp, 4
	mov ecx, esp
	
	
	fld [dword eax + vec3.x]
	fistp [dword ecx]
	call print_int, [dword ecx]
	fld [dword eax + vec3.y]
	fistp [dword ecx]
	call print_int, [dword ecx]
	fld [dword eax + vec3.z]
	fistp [dword ecx]
	call print_int, [dword ecx]
	
	call print_endl
	add esp, 4
	ret
ENDP print_vec3

;IMPORTANT: ptrs may aliase (That's good) :)
PROC vec3_normalize_dest
	ARG @@VEC3_PTR:dword, @@res_ptr:dword
	USES eax, ecx
	
	mov eax, [@@VEC3_PTR]
	mov ecx, [@@res_ptr]
	
	fld [eax + vec3.x]
	fld [eax + vec3.x]
	fmulp
	
	fld [eax + vec3.y]
	fld [eax + vec3.y]
	fmulp
	
	fld [eax + vec3.z]
	fld [eax + vec3.z]
	fmulp
	
	faddp
	faddp
	fsqrt; lengte
	
	fld [eax + vec3.x]
	fdiv st, st(1)
	fstp [ecx + vec3.x]
	fst st
	
	fld [eax + vec3.y]
	fdiv st, st(1)
	fstp [ecx + vec3.y]
	fst st
	
	fld [eax + vec3.z]
	fdiv st, st(1)
	fstp [ecx + vec3.z]
	fst st
	
	ret
ENDP vec3_normalize_dest

;WARNING: POINTERS MAY NOT OVERLAP
PROC average_color_res
	ARG @@VEC3_ARRAY_PTR:dword, @@res_ptr:dword
	USES eax, ecx
	
	mov eax, [@@VEC3_ARRAY_PTR]
	mov ecx, [@@res_ptr]
	
	fld [eax + vec3.x]
	fld [eax + VEC3_SIZE + vec3.x]
	fld [eax + 2*VEC3_SIZE + vec3.x]
	fld [eax + 3*VEC3_SIZE + vec3.x]
	faddp
	faddp
	faddp
	fld [dword offset nr_4]
	fdivp st(1), st(0)
	fstp [ecx + vec3.x]
	
	fld [eax + vec3.y]
	fld [eax + VEC3_SIZE + vec3.y]
	fld [eax + 2*VEC3_SIZE + vec3.y]
	fld [eax + 3*VEC3_SIZE + vec3.y]
	faddp
	faddp
	faddp
	fld [dword offset nr_4]
	fdivp st(1), st(0)
	fstp [ecx + vec3.y]
	
	fld [eax + vec3.z]
	fld [eax + VEC3_SIZE + vec3.z]
	fld [eax + 2*VEC3_SIZE + vec3.z]
	fld [eax + 3*VEC3_SIZE + vec3.z]
	faddp
	faddp
	faddp
	fld [dword offset nr_4]
	fdivp st(1), st(0)
	fstp [ecx + vec3.z]
	
	ret
ENDP average_color_res

DATASEG
	nr_4 dd 4.0
END
