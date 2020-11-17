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
	
	fld [dword eax + vec3.x]
	fld [dword ebx + vec3.x]
	fsubp
	fstp [dword ecx + vec3.x]
	
	fld [dword eax + vec3.y]
	fld [dword ebx + vec3.y]
	fsubp
	fstp [dword ecx + vec3.y]
	
	fld [dword eax + vec3.z]
	fld [dword ebx + vec3.z]
	fsubp
	fstp [dword ecx + vec3.z]
	
	ret
ENDP vec3_sub_res

;IMPORTANT: ptrs may aliase (That's good) :)
PROC vec3_add_res
	ARG @@VEC3_PTR_links:dword, @@VEC3_PTR_rechts:dword, @@res_ptr:dword
	USES eax, ebx, ecx
	
	mov eax, [@@VEC3_PTR_links]
	mov ebx, [@@VEC3_PTR_rechts]
	mov ecx, [@@res_ptr]
	
	fld [dword eax + vec3.x]
	fld [dword ebx + vec3.x]
	faddp
	fstp [dword ecx + vec3.x]
	
	fld [dword eax + vec3.y]
	fld [dword ebx + vec3.y]
	faddp
	fstp [dword ecx + vec3.y]
	
	fld [dword eax + vec3.z]
	fld [dword ebx + vec3.z]
	faddp
	fstp [dword ecx + vec3.z]
	
	ret
ENDP vec3_add_res

;IMPORTANT: ptrs may aliase (That's good) :)
PROC vec3_add_float_res
	ARG @@VEC3_PTR:dword, @@FLOAT:dword, @@res_ptr:dword
	USES eax, ecx
	
	mov eax, [@@VEC3_PTR]
	mov ecx, [@@res_ptr]
	
	fld  [dword eax + vec3.x]
	fld  [dword @@FLOAT]
	faddp
	fstp [dword ecx + vec3.x]
	
	fld  [dword eax + vec3.y]
	fld  [dword @@FLOAT]
	faddp
	fstp [dword ecx + vec3.y]
	
	fld  [dword eax + vec3.z]
	fld  [dword @@FLOAT]
	faddp
	fstp [dword ecx + vec3.z]
	
	ret
ENDP vec3_add_float_res


;IMPORTANT: ptrs may aliase (That's good) :)
PROC vec3_mul_float_res
	ARG @@VEC3_PTR:dword, @@multiplier:dword, @@res_ptr:dword
	USES eax, ecx
	
	push [@@multiplier]
	
	mov eax, [@@VEC3_PTR]
	mov ecx, [@@res_ptr]
	
	fld  [dword eax + vec3.x]
	fld  [dword esp]
	fmulp
	fstp [dword ecx + vec3.x]
	
	fld  [dword  eax + vec3.y]
	fld  [dword  esp]
	fmulp
	fstp [dword ecx + vec3.y]
	
	fld  [dword eax + vec3.z]
	fld  [dword esp]
	fmulp
	fstp [dword ecx + vec3.z]
	
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

PROC vec3_neg
	ARG @@VEC3_PTR1:dword
	USES eax, ebx
	
	mov eax, [@@VEC3_PTR1]
	
	fldz
	fld  [dword eax + vec3.x]
	fsubp
	fstp [dword eax + vec3.x]

	fldz
	fld  [dword eax + vec3.y]
	fsubp
	fstp [dword eax + vec3.y]
	
	fldz
	fld  [dword eax + vec3.z]
	fsubp
	fstp [dword eax + vec3.z]
	
	ret
ENDP vec3_neg

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

PROC print_vec3_x1000
	ARG @@vec_ptr:dword
	uses eax, ecx
	
	mov eax, [dword @@vec_ptr]

	
	call print_rounded_floatx1000, [dword eax]
	lea ecx, [eax + vec3.y]
	call print_rounded_floatx1000, [dword ecx]
	lea ecx, [eax + vec3.z]
	call print_rounded_floatx1000, [dword ecx]
	
	call print_endl

	ret
ENDP print_vec3_x1000

;IMPORTANT: ptrs may aliase (That's good) :)
PROC vec3_normalize_dest
	ARG @@VEC3_PTR:dword, @@res_ptr:dword
	USES eax, ecx
	
	mov eax, [dword @@VEC3_PTR]
	mov ecx, [dword @@res_ptr]
	
	fld [dword eax + vec3.x]
	fld [dword eax + vec3.x]
	fmulp
	
	fld [dword eax + vec3.y]
	fld [dword eax + vec3.y]
	fmulp
	
	fld [dword eax + vec3.z]
	fld [dword eax + vec3.z]
	fmulp
	
	faddp
	faddp
	fsqrt; lengte
	
	fld [dword eax + vec3.x]
	fdiv st, st(1)
	fstp [dword ecx + vec3.x]
	fst st
	
	fld [dword eax + vec3.y]
	fdiv st, st(1)
	fstp [dword ecx + vec3.y]
	fst st
	
	fld [dword eax + vec3.z]
	fdiv st, st(1)
	fstp [dword ecx + vec3.z]
	fst st
	
	ret
ENDP vec3_normalize_dest

;NOTE: POINTERS MAY OVERLAP
PROC average_4_color_res
	ARG @@VEC3_ARRAY_PTR:dword, @@res_ptr:dword
	USES eax, ecx
	
	mov eax, [@@VEC3_ARRAY_PTR]
	mov ecx, [@@res_ptr]
	
	fld [dword eax + vec3.x]
	fld [dword eax + VEC3_SIZE + vec3.x]
	fld [dword eax + 2*VEC3_SIZE + vec3.x]
	fld [dword eax + 3*VEC3_SIZE + vec3.x]
	faddp
	faddp
	faddp
	fld [dword offset nr_4]
	fdivp st(1), st(0)
	fstp [dword ecx + vec3.x]
	
	fld [dword eax + vec3.y]
	fld [dword eax + VEC3_SIZE + vec3.y]
	fld [dword eax + 2*VEC3_SIZE + vec3.y]
	fld [dword eax + 3*VEC3_SIZE + vec3.y]
	faddp
	faddp
	faddp
	fld [dword offset nr_4]
	fdivp st(1), st(0)
	fstp [dword ecx + vec3.y]
	
	fld [dword eax + vec3.z]
	fld [dword eax + VEC3_SIZE + vec3.z]
	fld [dword eax + 2*VEC3_SIZE + vec3.z]
	fld [dword eax + 3*VEC3_SIZE + vec3.z]
	faddp
	faddp
	faddp
	fld [dword offset nr_4]
	fdivp st(1), st(0)
	fstp [dword ecx + vec3.z]
	
	ret
ENDP average_4_color_res

PROC vec3_in_unit_sphere
	;Uses: Rejection sampling
	;      https://en.wikipedia.org/wiki/Rejection_sampling#Examples
	ARG @@VEC3_DEST_PTR:dword
	USES eax, ebx, ecx, edx, esi
	mov esi, [@@VEC3_DEST_PTR]

	sub esp, 4
	mov ebx, esp
	xor ecx, ecx
	
@@try_again:

	cmp ecx, 1000
	jg @@error_handler_many
	inc ecx

	;lea overbodig
	call random_float_n1_1, esi
	lea edx, [esi + vec3.y]
	call random_float_n1_1, edx
	lea edx, [esi + vec3.z]
	call random_float_n1_1, edx

	;call print_vec3_x1000, eax
	;call print_vec3, eax
	call vec3_dot, esi, esi, ebx
	;call print_rounded_floatx1000, [dword ebx]
	fld [dword ebx]
	fld1
	fcompp ST(1)
	fstsw ax            ;copy the Status Word containing the result to AX
	fwait               ;insure the previous instruction is completed
	sahf                ;transfer the condition codes to the CPU's flag register
	jpe @@error_handler     ;the comparison was indeterminate
					    ;this condition should be verified first
					    ;then only two of the next three conditional jumps
					    ;should become necessary, in whatever order is preferred,
					    ;the third jump being replaced by code to handle that case
	;ja   st0_positive   ;when all flags are 0
	;jb   st0_negative   ;only the C0 bit (CF flag) would be set if no error
	;jz   st0_zero       ;only the C3 bit (ZF flag) would be set if no error
	jb	@@try_again
	
	jmp @@return
@@error_handler:
	mov ah, 09h
	mov edx, offset msg_comparison_was_indeterminate
	int 21h

	mov	ah,00h
	int	16h
	call terminate_process
@@error_handler_many:
	mov ah, 09h
	mov edx, offset msg_too_many_attempts
	int 21h
	
	mov	ah,00h
	int	16h
	call terminate_process
@@return:
	add esp, 4
	ret
ENDP vec3_in_unit_sphere

PROC vec3_in_unit_hemisphere
	ARG @@NORMAL:dword, @@MULTIPLIER:dword, @@DEST:dword
	LOCAL @@DOT_PROD:dword
	USES eax, ebx, ecx
	
	mov ecx, [@@DEST]
	call vec3_in_unit_sphere, ecx

	mov eax, [@@MULTIPLIER]
	call vec3_mul_float_res, ecx, eax, ecx
	
	lea ebx, [@@DOT_PROD]
	mov eax, [@@NORMAL]
	call vec3_dot, ecx, eax, ebx
	
	fld [dword ebx]
	ftst                ;equivalent met fldz fcomp ST(1)
	                    ;compare the value of ST(0) to +0.0
	fstsw ax            ;copy the Status Word containing the result to AX
	fwait               ;insure the previous instruction is completed
	sahf                ;transfer the condition codes to the CPU's flag register
	jpe @@error_handler ;the comparison was indeterminate
					    ;this condition should be verified first
					    ;then only two of the next three conditional jumps
					    ;should become necessary, in whatever order is preferred,
					    ;the third jump being replaced by code to handle that case
	;ja   st0_positive   ;when all flags are 0
	;jb   st0_negative   ;only the C0 bit (CF flag) would be set if no error
	;jz   st0_zero       ;only the C3 bit (ZF flag) would be set if no error
	ja @@end; no invert needed

	call vec3_neg, ecx
	
	jmp @@end
@@error_handler:
	mov ah, 09h
	mov edx, offset msg_comparison_was_indeterminate
	int 21h

	mov	ah,00h
	int	16h
	call terminate_process
@@end:
	ret
ENDP vec3_in_unit_hemisphere

PROC vec3_mul_vec3_res
	ARG @@VEC3_PTR_1:dword, @@VEC3_PTR_2:dword, @@res_ptr:dword
	USES eax, ebx, ecx
	
	mov eax, [dword @@VEC3_PTR_1]
	mov ebx, [dword @@VEC3_PTR_2]
	mov ecx, [dword @@res_ptr]
	
	fld  [dword eax + vec3.x]
	fld  [dword ebx + vec3.x]
	fmulp
	fstp [dword ecx + vec3.x]
	
	fld  [dword eax + vec3.y]
	fld  [dword ebx + vec3.y]
	fmulp
	fstp [dword ecx + vec3.y]
	
	fld  [dword eax + vec3.z]
	fld  [dword ebx + vec3.z]
	fmulp
	fstp [dword ecx + vec3.z]

	ret
ENDP vec3_mul_vec3_res

DATASEG
	nr_4 dd 4.0
	msg_comparison_was_indeterminate db "Floating point comparison was indeterminate", 13, 10, '$';
	msg_too_many_attempts            db "Too many attempts were necessary to find a proper vector using the rejection method", 13, 10, '$';
END
