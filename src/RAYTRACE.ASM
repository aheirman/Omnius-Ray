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

INCLUDE "RAYTRACE.INC"
INCLUDE "STRUC.INC"
INCLUDE "VIDEO.INC"
INCLUDE "MISC.INC"

; compile-time constants (with macros)
VMEMADR EQU 0A0000h	; video memory address
SCRWIDTH EQU  320	; screen witdth
SCRHEIGHT EQU 200	; screen height


; -------------------------------------------------------------------
; CODE
; -------------------------------------------------------------------
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

PROC print_ray
	ARG @@ray_ptr:dword
	uses eax, ebx, ecx
	sub esp, 4
	
	;call print_int, eax
	mov ecx, esp
	mov eax, [@@ray_ptr]
	fld [dword eax + ray_obj.origin_x]
	fistp [dword ecx]
	call print_int, [dword ecx]
	fld [dword eax + ray_obj.origin_y]
	fistp [dword ecx]
	call print_int, [dword ecx]
	fld [dword eax + ray_obj.origin_z]
	fistp [dword ecx]
	call print_int, [dword ecx]
	
	fld [dword eax + ray_obj.direction_x]
	fistp [dword ecx]
	call print_int, [dword ecx]
	fld [dword eax + ray_obj.direction_y]
	fistp [dword ecx]
	call print_int, [dword ecx]
	fld [dword eax + ray_obj.direction_z]
	fistp [dword ecx]
	call print_int, [dword ecx]
	
	add eax, RAY_CONTROL_OFFSET
	call print_byte_list, 1, eax
	
	;call print_vec3, eax
	;add eax, RAY_DIR_OFFSET
	;call print_vec3, eax
	
	
	call print_endl
	add esp, 4
	ret
ENDP print_ray

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

PROC print_vec3_int
	ARG @@vec_ptr:dword
	uses eax
	
	mov eax, [@@vec_ptr]
	
	call print_int, [dword eax + vec3.x]
	call print_int, [dword eax + vec3.y]
	call print_int, [dword eax + vec3.z]
	
	call print_endl
	ret
ENDP print_vec3_int

;--
; This function automatically updates the position of the ray to the intersection &
;   changes the direction to the ray
;--
PROC intersect
@@LOCAL_STACK_SIZE EQU (4*5)  + VEC3_SIZE*1 + SPHERE_SIZE
	; "4 +", ik wil dat esp wijst naar de volgende cel.
	; 4 floats a,b,c, discriminantcdv
	; one vec3: oc
	
	
	; Based on:
	; http://viclw17.github.io/2018/07/16/raytracing-ray-sphere-intersection/
	; float info: http://www.ray.masmcode.com/tutorial/fpuchap7.htm#ftst
	;TODO: loop over all spheres
	ARG @@ray_ptr:dword
	uses eax, ebx, ecx, edi
	
	

	mov ebx, [@@ray_ptr]; Curses this depends on the current state of the ebp
	;call print_ray, eax
	
	push ebp
	
	mov ebp, esp
	mov ecx, @@LOCAL_STACK_SIZE
	sub esp, ecx


	;----------
	; Zero initialize
	;call print_int, ecx
	xor eax, eax
	mov edi, esp
rep stosb
    ;mov ecx, ebp
	;sub edi, 35
	;call print_byte_list, 35, edi
	;--------------
	
	mov eax, ebx; =[@@ray_ptr]
	mov ebx, ebp
	sub ebx, 4*5 + VEC3_SIZE*1 + SPHERE_SIZE; point to the Sphere
	mov ecx, ebp
	sub ecx, 4*5 + VEC3_SIZE*1; point to the vector
	
	;---
	; Initialize sphere
	;---
	fldz
	fst  [dword ebx + sphere_obj.origin_x]
	fstp  [dword ebx + sphere_obj.origin_y]
	fldpi
	fstp [dword ebx + sphere_obj.origin_z]
	fld1
	fldpi
	fdivp
	fstp [dword ebx + sphere_obj.radius]
	

	
	;------------------------
	; vec3 oc = r.origin() - center;
	call vec3_sub_res, eax, ebx, ecx
	
	;call print_vec3, eax
	;call print_vec3, ebx
	;call print_vec3, ecx
	
	;call print_byte_list, 35, edi
	
	;------------------------
	;  float a = dot(r.direction(), r.direction());
	add eax, RAY_DIR_OFFSET

	mov ebx, ebp
	sub ebx, 4
	call vec3_dot, eax, eax, ebx
	
	;sub esp, 4
	;fld [dword ebx]
	;fist [dword esp]
	;call print_int, [dword esp]
	;add esp, 4
	
	;------------------------
	; float b = 2.0 * dot(oc, r.direction());
	mov ebx, ebp
	sub ebx, 4*2
	;call print_vec3, ecx
	;call print_vec3, eax
	call vec3_dot, ecx, eax, ebx

	;sub esp, 4
	;fld [dword ebx]
	;fist [dword esp]
	;call print_int, [dword esp]
	;add esp, 4
	
	fld  [dword ebx]
	fld [dword offset nr_two]
	fmul
	fstp [dword ebx]

	
	;sub esp, 4
	;fld [dword ebx]
	;fist [dword esp]
	;call print_int, [dword esp]
	;add esp, 4
	
	;------------------------
	; float c = dot(oc,oc) - radius*radius;
	mov ebx, ebp
	sub ebx, 4*5 + VEC3_SIZE*1 + SPHERE_SIZE; Sphere
	fld [dword ebx + sphere_obj.radius]
	fmul ST(0), ST(0)
	
	mov ebx, ebp
	sub ebx, 4*3
	call vec3_dot, ecx, ecx, ebx; tijdelijk in c opslaan

	;sub esp, 4
	;fld [dword ebx]
	;fistp [dword esp]
	;call print_int, [dword esp]
	;add esp, 4
	
	fld [dword ebx]
	;fsubp ST(0), ST(1)
	fsubp
	fchs
	
	fstp  [dword ebx]; float c
	
	;sub esp, 4
	;fld [dword ebx]
	;fistp [dword esp]
	;call print_int, [dword esp]
	;add esp, 4
	
	;------------------------
	; float discriminant = b*b - 4*a*c;
	mov ebx, ebp
	sub ebx, 4*2
	fld [dword ebx]
	fmul ST(0), ST(0)
	
	fld [dword offset nr_four]
	mov ebx, ebp
	sub ebx, 4
	fld [dword ebx]; push a
	mov ebx, ebp
	sub ebx, 4*3
	fld [dword ebx]; push c
	fmulp; a*c
	fmulp; 4*(a*c)
	fsubp ST(1), ST(0); (b*b)-(4*a*c)
	mov ebx, ebp
	sub ebx, 4*4
	fst  [dword ebx]; float discriminant, don't pop
	

	
	
	;-----------------
	; Test de discriminant
	;sub esp, 4
	;fld [dword ebx]
	;fistp [dword esp]
	;call print_int, [dword esp]
	;add esp, 4
	
	mov ebx, eax; ray pointer to ebx
	sub ebx, RAY_DIR_OFFSET
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
	jb   @@neg_discriminant_of_negatieve_afstand
	
	;Dus nu een positieve of nul discreminant
	;mov ah, 09h
	;mov edx, offset msg_pos_discreminant
	;int 21h
	
	fsqrt
	mov ecx, ebp
	sub ecx, 4*2
	fld  [dword ecx]; load b
	faddp
	ftst
	fstsw ax
	fwait
	sahf
	jpe @@error_handler
	jb   @@afstand_positief
	;-----
	fld  [dword ecx]; load b
	fsubp
	ftst
	fstsw ax
	fwait
	sahf
	jpe @@error_handler
	jb   @@afstand_positief
	
	jmp @@neg_discriminant_of_negatieve_afstand
@@afstand_positief:
	mov [ebx + ray_obj.hit], 1
	fchs
	fld [dword offset nr_two]
	mov ebx, ebp
	sub ebx, 4
	fld [dword ebx]
	fmulp
	fdivp st(1), st
	mov ebx, ebp
	sub ebx, 4*5
	fstp [dword ebx]
	
	jmp @@finish
	
@@neg_discriminant_of_negatieve_afstand:
	mov [ebx + ray_obj.hit], 0

	;mov ah, 09h
	;mov edx, offset msg_neg_discreminant
	;int 21h

	jmp @@finish
	
@@error_handler:
	mov ah, 09h
	mov edx, offset msg_comparison_was_indeterminate
	int 21h
	
	
@@finish:
	add esp, @@LOCAL_STACK_SIZE
	pop ebp
	ret
ENDP intersect

PROC ray_trace
@@LOCAL_STACK_SIZE EQU RAY_SIZE + VEC3_SIZE + 4*3
	USES eax, ebx, ecx, edi, esi
	
	push ebp
	mov ebp, esp
	
	sub esp, @@LOCAL_STACK_SIZE;         
	; store one ray
	; store one point
	; ecx of outerloop
	; temporary
	; temporary
	
	
	;----------
	; Zero initialize
	xor eax, eax
	mov edi, esp
rep stosb
	;call print_byte_list, RAY_SIZE + VEC3_SIZE + 4, esp
	;--------
	
	mov ebx, ebp
	sub ebx, RAY_SIZE

	xor esi, esi
	mov esi, 0a0000h


@@begin_height_loop:
	mov [esp+8], ecx
	xor ecx, ecx
@@begin_wirdth_loop:
	fld1
	fstp [dword ebx + ray_obj.direction_z]
	fldz
	fst  [dword ebx + ray_obj.direction_y]
	fstp [dword ebx + ray_obj.direction_x]
	
	
	mov [dword esp], ecx
	mov [dword esp+4], SCRWIDTH
	fld [dword esp]
	fld [dword esp+4]
	fdivp
	fld [dword offset nr_neg_half]
	faddp
	;---
	;Correct for the non square pixels
	;---
	fld [dword offset nr_aspect_ratio]
	fmulp
	fstp  [dword ebx + ray_obj.origin_x]
	
	mov edi, [esp+8]; ecx of outerloop
	mov [dword esp], edi
	mov [dword esp+4], SCRHEIGHT
	fld [dword esp]
	fld [dword esp+4]
	fdivp
	fld [dword offset nr_neg_half]
	faddp
	fst  [dword ebx + ray_obj.origin_y]
	fldz
	fstp [dword ebx + ray_obj.origin_z]
	;mov  [dword ebx + ray_obj.hit], 1
	;call print_ray, ebx
	

	call intersect, ebx
	;call print_ray, ebx
	;--

	xor eax, eax
	mov al, [ebx + ray_obj.hit]
	cmp eax, 0
	jz @@no_hit
	
	;---
	; Get Color
	;---
	;Bit    7  6  5  4  3  2  1  0
	;Data   R  R  R  G  G  G  B  B
	mov [dword esi], 128
	jmp @@after_hit
@@no_hit:
	mov [dword esi], 0
@@after_hit:
	
	
	inc esi
	inc ecx
	cmp ecx, SCRWIDTH
	jnz @@begin_wirdth_loop
	
	
	mov ecx, [esp+8]
	inc ecx
	cmp ecx, SCRHEIGHT
	jnz @@begin_height_loop
	
	add esp, @@LOCAL_STACK_SIZE
	pop ebp
	ret
ENDP ray_trace

DATASEG
	nr_four         dd 4.0
	nr_two          dd 2.0
	nr_neg_half     dd -0.5
	nr_aspect_ratio dd 1.2
	msg_comparison_was_indeterminate db "comparison_was_indeterminat", 13, 10, '$'; 13, 10 == carrige return & \n
	msg_pos_discreminant             db "positieve (or zero) discreminant", 13, 10, '$'; 
	msg_neg_discreminant             db "negatieve discreminant", 13, 10, '$'; 

END
