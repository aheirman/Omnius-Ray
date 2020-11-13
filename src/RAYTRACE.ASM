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
INCLUDE "VEC.INC"
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

PROC print_sphere
	ARG @@sphere_ptr:dword
	uses eax
	
	mov eax, [@@sphere_ptr]
	
	call print_rounded_float, [dword eax + sphere_obj.origin_x]
	call print_rounded_float, [dword eax + sphere_obj.origin_y]
	call print_rounded_float, [dword eax + sphere_obj.origin_z]
	
	call print_rounded_float, [dword eax + sphere_obj.radius]
	
	call print_rounded_float, [dword eax + sphere_obj.color_r]
	call print_rounded_float, [dword eax + sphere_obj.color_g]
	call print_rounded_float, [dword eax + sphere_obj.color_b]
	
	;TODO: print control
	call print_endl
	call print_endl
	
	ret
ENDP


;--
; This function automatically creates the next_ray IF
;   the next ray has a distance_traveled that is more than
;   the current distance between source and hit.
;
; Thus, if there us no hit, the next_ray will not be updated.
;--
PROC intersect_sphere
@@LOCAL_STACK_SIZE EQU (4*6)  + VEC3_SIZE*1
	; "4 +", ik wil dat esp wijst naar de volgende cel.
	; 5 floats a,b,c, discriminant, de lengte, en de ptr naar de sphere
	; one vec3: oc
	
	; Based on:
	; http://viclw17.github.io/2018/07/16/raytracing-ray-sphere-intersection/
	; float info: http://www.ray.masmcode.com/tutorial/fpuchap7.htm#ftst
	ARG @@sphere_ptr:dword, @@ray_ptr:dword, @@next_ray_ptr:dword
	uses eax, ebx, ecx, edx, edi
	
	

	mov ebx, [@@ray_ptr]; Curses this depends on the current state of the ebp
	;call print_int, ebx
	;call print_endl
	mov edx, [@@sphere_ptr]
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
	;---
	;Store sphere ptr
	;---
	mov ebx, ebp
	sub ebx, 4*6
	mov [ebx], edx; =[@@sphere_ptr]
	;call print_int, ebx
	;call print_int, [ebx]
	;call print_sphere, edx
	;call print_sphere, [ebx]

	mov ecx, ebp
	sub ecx, 4*6 + VEC3_SIZE*1; point to the vector
	

	
	;------------------------
	; vec3 oc = r.origin() - center;
	; eax: origin is het eerste deel van de ray
	; ebx: origin is het eerste deel van de sphere
	call vec3_sub_res, eax, [ebx], ecx
	
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
	call vec3_dot, ecx, eax, ebx
	
	fld  [dword ebx]
	fld [dword offset nr_two]
	fmul
	fstp [dword ebx]
	
	;------------------------
	; float c = dot(oc,oc) - radius*radius;
	mov ebx, ebp
	sub ebx, 4*6
	mov ebx, [ebx]; --> sphere
	fld [dword ebx + sphere_obj.radius]
	fmul ST(0), ST(0)
	
	mov ebx, ebp
	sub ebx, 4*3
	call vec3_dot, ecx, ecx, ebx; tijdelijk in c opslaan
	
	fld [dword ebx]
	;fsubp ST(0), ST(1)
	fsubp
	fchs
	
	fstp  [dword ebx]; float c
	
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
	
	mov ebx, eax; ray dir pointer to ebx; eax is nu vrij
	sub ebx, RAY_DIR_OFFSET; ray pointer to ebx
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
	
	;Als de afstand niet positief is, dan is ze negatief
	jmp @@finish
	
@@afstand_positief:
	mov [byte ebx + ray_obj.hit], 1
	
	;----
	; bereken de afstand
	;----
	fchs
	fld [dword offset nr_two]
	mov ecx, ebp
	sub ecx, 4
	fld [dword ecx]
	fmulp
	fdivp st(1), st
	mov ecx, ebp
	sub ecx, 4*5
	fst [dword ecx]; sla lengte op
	;call print_rounded_float, [dword eax]
	
	;-------
	; Is de nieuwe afstand de kleinste afstand die tot nu toe is gevonden?
	;------
	fld [ebx + ray_obj.depth]
	fcomp
	fstsw ax            ;copy the Status Word containing the result to AX
	fwait               ;insure the previous instruction is completed
	sahf                ;transfer the condition codes to the CPU's flag register
	jpe @@error_handler
	jb @@finish
	
	fstp [ebx + ray_obj.depth]; Update the ray-depth
	
	;----
	; bereken de kleur: gebruikt eax
	;----
	mov eax, ebp
	sub eax, 4*6
	mov eax, [eax]
	;call print_int, eax
	;call print_int, [eax]
	;call print_sphere, eax
	fld  [eax + sphere_obj.color_r]
	fstp [ebx + ray_obj.color_r]
	fld  [eax + sphere_obj.color_g]
	fstp [ebx + ray_obj.color_g]
	fld  [eax + sphere_obj.color_b]
	fstp [ebx + ray_obj.color_b]
	


	jmp @@finish

@@error_handler:
	mov ah, 09h
	mov edx, offset msg_comparison_was_indeterminate
	int 21h

@@neg_discriminant_of_negatieve_afstand:
	; DON'T
	;mov [ebx + ray_obj.hit], 0

	;mov ah, 09h
	;mov edx, offset msg_neg_discreminant
	;int 21h
	
@@finish:
	add esp, @@LOCAL_STACK_SIZE
	pop ebp
	ret
ENDP intersect_sphere


PROC intersect_objects
@@LOCAL_STACK_SIZE EQU RAY_SIZE
	; De nieuwe ray
	ARG @@ray_ptr:dword
	uses eax, ebx, ecx, edx, edi
	mov ebx, [@@ray_ptr]
	
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
	
	mov ecx, [dword offset num_spheres]
	mov eax, offset sphere_datas
@@loop_begin:
	cmp ecx, 0
	je @@finish
	
	
	;call print_sphere, eax
	mov edx, esp; ptr naar de nieuwe ray
	call intersect_sphere, eax, ebx, edx
	dec ecx
	add eax, SPHERE_SIZE
	jmp @@loop_begin
@@finish:

	; TODO move new ray into old ray

	add esp, @@LOCAL_STACK_SIZE
	pop ebp
	ret
ENDP intersect_objects




;----------------------------------------------------------
; ---------------------------- RAYTRACE -------------------
;----------------------------------------------------------

PROC ray_trace
@@LOCAL_STACK_SIZE EQU RAY_SIZE + VEC3_SIZE + 4*3
	USES eax, ebx, ecx, edx, edi, esi
	
	push ebp
	mov ebp, esp
	
	mov ecx, @@LOCAL_STACK_SIZE; DO NOT OPTIMIZE AWAY, IT IS ENEDED FOT THE ZERO INITIALIZE
	sub esp, ecx
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

	; Zet de depth to infinity, hierdoor is iedere echte diepte kleiner
	fld1
	fldz
	fdivp
	fstp [dword ebx + ray_obj.depth]
	mov [byte ebx + ray_obj.hit], 0
	
	
	;fldz
	;fst  [dword ebx + ray_obj.direction_y]
	;fstp [dword ebx + ray_obj.]
	
	fldz
	fst  [dword ebx + ray_obj.origin_x]
	fst  [dword ebx + ray_obj.origin_y]
	fstp  [dword ebx + ray_obj.origin_z]
	

	fld1
	fstp [dword ebx + ray_obj.direction_z]
	
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
	fstp  [dword ebx + ray_obj.direction_x]
	; Voor orthonormaal gebruik deze
	;fstp  [dword ebx + ray_obj.origin_x]
	
	mov edi, [esp+8]; ecx of outerloop
	mov [dword esp], edi
	mov [dword esp+4], SCRHEIGHT
	fld [dword esp]
	fld [dword esp+4]
	fdivp
	fld [dword offset nr_neg_half]
	faddp
	; Voor orthonormaal gebruik deze
	;fst  [dword ebx + ray_obj.origin_y]
	fst  [dword ebx + ray_obj.direction_y]

	;call print_ray, ebx
	
	;call print_int, ebx
	call intersect_objects, ebx
	;call print_ray, ebx
	;--

	xor eax, eax
	mov al, [ebx + ray_obj.hit]
	cmp eax, 0
	jz @@no_hit
	
	;---
	; Get Color using: eax, edx
	;---
	;Bit    7  6  5  4  3  2  1  0
	;Data   R  R  R  G  G  G  B  B
	xor eax, eax; Will be used as the packed color
	
	fld [dword offset nr_max_byte_float]
	fld [dword ebx + ray_obj.color_b]
	fld [dword ebx + ray_obj.color_g]
	fld [dword ebx + ray_obj.color_r]
	
	;---
	;red
	;---
	fmul st, st(3)
	fistp [dword esp]
	mov edx, [dword esp]
	;call print_int, edx

	
	cmp edx, 255
	jl @@not_cliping_r
	;call print_endl
	mov edx, 255
@@not_cliping_r:
	and edx, 224; 3 bovenste bits
	;call print_int, edx
	add eax, edx
	;---
	;green
	;---
	fmul st, st(2)
	fistp [dword esp]
	mov edx, [dword esp]
	;call print_int, edx
	cmp edx, 255
	jl @@not_cliping_g
	;call print_endl
	mov edx, 255
@@not_cliping_g:
	and edx, 224
	;call print_int, edx
	shr edx, 3
	add eax, edx
	;---
	; blue
	;---
	fmul st, st(1)
	fistp [dword esp]
	mov edx, [dword esp]
	;call print_int, edx
	cmp edx, 255
	jl @@not_cliping_b
	mov edx, 255
	;call print_endl
@@not_cliping_b:
	and edx, 224
	;call print_int, edx
	shr edx, 6
	add eax, edx
	;--------------------
	; End of color
	;--------------------
	
	
	mov [dword esi], eax
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
	nr_max_byte_float dd 255.0
	nr_four           dd 4.0
	nr_two            dd 2.0
	nr_neg_half       dd -0.5
	nr_aspect_ratio   dd 1.2
	nr_1              dd 1.0
	msg_comparison_was_indeterminate db "Floating point comparison was indeterminate", 13, 10, '$'; 13, 10 == carrige return & \n
	msg_pos_discreminant             db "positieve (or zero) discreminant", 13, 10, '$'; 
	msg_neg_discreminant             db "negatieve discreminant", 13, 10, '$'; 
	
	;---
	; Initialize sphere
	;---
	num_spheres  dd 3
	sphere_datas sphere_obj <-0.2, 0.0, 0.7, 0.1, 1.0, 0.0, 0.0, 1>,\
	                        <0.2,  0.0, 0.7, 0.1, 0.0, 1.0, 0.0, 1>,\
	                        <0.0,  0.0, 0.7, 0.1, 0.0, 0.0, 1.0, 1>

END
