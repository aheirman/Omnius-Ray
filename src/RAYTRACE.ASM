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
INCLUDE "FILE.INC"

; compile-time constants (with macros)
VMEMADR   EQU 0A0000h	; video memory address
SCRWIDTH  EQU 320	; screen witdth
SCRHEIGHT EQU 200	; screen height

NUM_SUB_PIXELS          EQU 4
NUM_SUB_PIXELS_PER_AXIS EQU 2
MAX_BOUNCES             EQU 2
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
@@LOCAL_NUM_DWORD equ 6
@@LOCAL_STACK_SIZE EQU (4* @@LOCAL_NUM_DWORD )  + VEC3_SIZE*1
	; "4 +", ik wil dat esp wijst naar de volgende cel.
	; floats: 5
	;   a,b,c
	;	discriminant, 
	;	de lengte,
	; ptrs: 1
	;   naar de sphere
	; NOTE: de volgende worden van de argument gehouden:
	;	de ptr naar next_ray
	;
	; one vec3: oc
	
	; Based on:
	; http://viclw17.github.io/2018/07/16/raytracing-ray-sphere-intersection/
	; float info: http://www.ray.masmcode.com/tutorial/fpuchap7.htm#ftst
	;             https://home.deec.uc.pt/~jlobo/tc/artofasm/ch14/ch144.htm#HEADING4-118
	ARG @@sphere_ptr:dword, @@ray_ptr:dword, @@next_ray_ptr:dword
	LOCAL @@vec3_normal:vec3, @@vec3_tmp:vec3
	uses eax, ebx, ecx, edx, edi, esi

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
	;call print_sphere, edx
	
	mov ecx, ebp
	sub ecx, 4*@@LOCAL_NUM_DWORD + VEC3_SIZE*1; point to the vector
	

	
	;------------------------
	; vec3 oc = r.origin() - center;
	; eax: origin is het eerste deel van de ray
	; ebx: origin is het eerste deel van de sphere
	call vec3_sub_res, eax, [dword ebx], ecx
	
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
	; bereken de afstand: Passes float through
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
	
	;---
	; Zet de nieuwe origin
	; pseudo code: nieuwe_origin = oude_origin + oude_direction * t;
	;---
	; ebx: ptr naar ray
	mov ebp, [esp + @@LOCAL_STACK_SIZE]; Zet ebp terug goed
	mov ecx, [@@next_ray_ptr]
	
	mov esi, [ebx + ray_obj.depth]; lengte
	add ebx, RAY_DIR_OFFSET
	add ecx, RAY_DIR_OFFSET
	call vec3_mul_float_res, ebx, esi, ecx; ptr1, float --> nieuwe ptr in direction (tijdelijk)
	sub ebx, RAY_DIR_OFFSET
	mov esi, ecx
	sub ecx, RAY_DIR_OFFSET
	; esi: tijdelijke vec, ebx origin ptr oud --> ecx: origin nieuw
	call vec3_add_res, esi, ebx, ecx
	
	;call print_ray, ebx
	;call print_ray, ecx
	
	;-------
	; Bereken de normaal
	; pseudo code: normalize(nieuwe_origin-sphere_center)
	;-------
	lea ebx, [@@vec3_tmp];  Dit zal de ongenormaliseerde normaal zijn.
	mov eax, [@@sphere_ptr];          ptr naar sphere, het eerste is de origin
	call vec3_sub_res, ecx, eax, ebx; links, rechts, ptr
	;call print_vec3, ecx
	;call print_vec3, eax
	;call print_vec3, ebx
	lea edx, [@@vec3_normal]
	call vec3_normalize_dest, ebx, edx
	
	;-------
	; Bereken de next direction via Lambertian reflectance
	; pseudo code: Next ray.dir = normal + vec3_in_unit_sphere
	;-------
	lea ebx, [@@vec3_tmp]
	call vec3_in_unit_sphere, ebx
	;lea esi, [ecx + ray_obj.direction_x]
	;call vec3_add_res, ebx, edx, esi



	;----
	; DEBUG: kleur op basis van normaal
	; pseudo code: 0.5*vec3(N.x()+1, N.y()+1, N.z()+1);
	;----
	;mov eax, ecx
	;add eax, RAY_COL_OFFSET
	;mov esi, [dword offset nr_1]
	;call vec3_add_float_res, edx, esi, ebx
	;mov esi, [dword offset nr_half]
	;call vec3_mul_float_res, ebx, esi, eax

	;----
	; Geef de kleur van objecten
	;----
	;mov eax, [@@sphere_ptr]
	;fld  [dword eax + sphere_obj.color_r]
	;fstp [dword ecx + ray_obj.color_r]
	;fld  [dword eax + sphere_obj.color_g]
	;fstp [dword ecx + ray_obj.color_g]
	;fld  [dword eax + sphere_obj.color_b]
	;fstp [dword ecx + ray_obj.color_b]

	;----
	; bereken de kleur: gebruikt eax
	;----
	mov eax, [dword @@sphere_ptr];      eax: sphere
	mov esi, [dword @@ray_ptr];         esi: oude ray
	;                             ecx: nieuwe ray	
	fld  [dword eax + sphere_obj.color_r]
	fld  [dword esi + ray_obj.color_r]
	fmulp
	fstp [dword ecx + ray_obj.color_r]
	
	fld  [dword eax + sphere_obj.color_g]
	fld  [dword esi + ray_obj.color_g]
	fmulp
	fstp [dword ecx + ray_obj.color_g]
	
	fld  [dword eax + sphere_obj.color_b]
	fld  [dword esi + ray_obj.color_b]
	fmulp
	fstp [dword ecx + ray_obj.color_b]
	


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
	mov ebp, [esp]
	add esp, 4
	
	ret
ENDP intersect_sphere


PROC intersect_objects
	; De nieuwe ray
	ARG @@ray_ptr:dword
	LOCAL @@RAY_TMP:ray_obj
	uses eax, ebx, ecx, edx
	mov ebx, [dword @@ray_ptr]
	
	mov ecx, [dword offset num_spheres]
	mov eax, offset sphere_datas
@@loop_begin:
	cmp ecx, 0
	je @@finish
	
	;----
	; Zorg ervoor dat de kleur altijd klaar is voor de volgende 
	;----
	fld1
	fst  [dword ebx + ray_obj.color_r]
	fst  [dword ebx + ray_obj.color_g]
	fstp [dword ebx + ray_obj.color_b]
	
	;call print_sphere, eax
	lea edx, [@@RAY_TMP]; ptr naar de nieuwe ray
	call intersect_sphere, eax, ebx, edx; eax: spehre; ebx: ray; edx: next ray
	dec ecx
	add eax, SPHERE_SIZE
	jmp @@loop_begin
@@finish:


	;---
	; Move color of the final ray in the argument ray.
	;---
	mov eax, [dword edx + ray_obj.color_r]
	mov [dword ebx + ray_obj.color_r], eax
	mov eax, [dword edx + ray_obj.color_g]
	mov [dword ebx + ray_obj.color_g], eax
	mov eax, [dword edx + ray_obj.color_b]
	mov [dword ebx + ray_obj.color_b], eax

	ret
ENDP intersect_objects




;----------------------------------------------------------
; ---------------------------- RAYTRACE -------------------
;----------------------------------------------------------

PROC ray_trace
@@LOCAL_STACK_SIZE EQU RAY_SIZE + VEC3_SIZE + 4*3
	LOCAL @@SUBPIXEL_X:dword, @@SUBPIXEL_Y:dword, @@PIXEL_X:dword, @@PIXEL_Y:dword,\
	      @@TMP_VAR:dword, @@TMP_VAR_2:dword, @@TMP_VEC3_1:vec3, @@TMP_VEC3_2:vec3
	USES eax, ebx, ecx, edx, esi, edi
	
	mov [dword @@SUBPIXEL_X], 0
	mov [dword @@SUBPIXEL_Y], 0
	mov [dword @@PIXEL_X], 0
	mov [dword @@PIXEL_Y], 0
	
	mov ebx, esp
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
	
	sub ebx, RAY_SIZE

	xor esi, esi
	mov esi, 0a0000h

@@begin_height_loop:
	mov [dword @@PIXEL_Y], ecx
	xor ecx, ecx
@@begin_width_loop:
	mov [dword @@PIXEL_X], ecx
	xor ecx, ecx
@@begin_SUBPIXEL_Y_loop:
	mov [dword @@SUBPIXEL_Y], ecx
	xor ecx, ecx
@@begin_SUBPIXEL_X_loop:
	mov [dword @@SUBPIXEL_X], ecx
	xor ecx, ecx
	
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
	

	;---
	; X-location
	;---
	fild [dword @@PIXEL_X]
	fild [dword @@SUBPIXEL_X]
	mov  [dword @@TMP_VAR], NUM_SUB_PIXELS_PER_AXIS
	fild [dword @@TMP_VAR]
	fdivp
	faddp
	
	mov  [dword @@TMP_VAR], SCRWIDTH
	fild [dword @@TMP_VAR]
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
	
	;---
	; Y-location
	;--- 
	fild [dword @@PIXEL_Y]
	fild [dword @@SUBPIXEL_Y]
	mov  [dword @@TMP_VAR], NUM_SUB_PIXELS_PER_AXIS
	fild [dword @@TMP_VAR]
	fdivp
	faddp
	
	
	mov  [dword @@TMP_VAR], SCRHEIGHT
	fild [dword @@TMP_VAR]
	fdivp
	fld  [dword offset nr_neg_half]
	faddp
	; Voor orthonormaal gebruik deze
	;fst  [dword ebx + ray_obj.origin_y]
	fstp [dword ebx + ray_obj.direction_y]

	;---
	; Zet de kleur multiplier naar 1.0, 1.0, 1.0
	;--- 
	mov ecx, [dword offset nr_1]
	mov [dword ebx + ray_obj.color_r], ecx
	mov [dword ebx + ray_obj.color_g], ecx
	mov [dword ebx + ray_obj.color_b], ecx


	;---
	; Intersect
	;---
	call intersect_objects, ebx
	;call print_ray, ebx
	;--


	

	
	;---
	; Sla kleur op
	;---
	mov ecx, [dword @@SUBPIXEL_X]
	mov edx, [dword @@SUBPIXEL_Y]
	lea edx, [ecx + edx*NUM_SUB_PIXELS_PER_AXIS]
	;call print_int, edx
	mov eax, VEC3_SIZE
	imul edx;                                      maakt de eax = arrayindex
	mov edi, eax
	add edi, offset pixel_samples

	;---
	; Check voor een hit
	;    hit:    kleur van de ray
	;    no-hit: background
	;---

	xor eax, eax
	mov al, [byte ebx + ray_obj.hit]
	cmp eax, 0
	jz @@no_hit

	mov ecx, [dword ebx + ray_obj.color_r]
	mov [edi + vec3.x],  ecx
	mov ecx, [dword ebx + ray_obj.color_g]
	mov [edi + vec3.y],  ecx
	mov ecx, [dword ebx + ray_obj.color_b]
	mov [edi + vec3.z],  ecx

	jmp @@post_hit
@@no_hit:

	;---
	; Background color
	;---
	fld [dword ebx + ray_obj.direction_y]; De y-component is nu geschaald van -1 tot 1
	fld1
	faddp
	fld [dword offset nr_background]
	fmulp;                                 De y-component is nu geschaald van 0 tot 1
	fst [dword @@TMP_VAR]
	fld1
	fsubrp st(1), st(0)
	fstp [dword @@TMP_VAR_2]
	lea eax, [@@TMP_VEC3_1]
	lea ecx, [@@TMP_VEC3_2]
	call vec3_mul_float_res, offset background_colors,             [dword @@TMP_VAR],   eax
	call vec3_mul_float_res, offset background_colors + VEC3_SIZE, [dword @@TMP_VAR_2], ecx
	
	call vec3_add_res, eax, ecx, edi
	;mov [edi + vec3.x],  0
	;mov [edi + vec3.y],  0
	;mov [edi + vec3.z],  0
@@post_hit:


	;---
	; Subpixel loops
	;---
	mov ecx, [dword @@SUBPIXEL_X]
	inc ecx
	cmp ecx, NUM_SUB_PIXELS_PER_AXIS
	jnz @@begin_SUBPIXEL_X_loop
	
	mov ecx, [dword @@SUBPIXEL_Y]
	inc ecx
	cmp ecx, NUM_SUB_PIXELS_PER_AXIS
	jnz @@begin_SUBPIXEL_Y_loop

	;---
	; Averaged Color
	;---
	mov edi, offset pixel_samples
	call average_4_color_res, edi, edi
	
	;---
	; Prepare to put pixel in pixel row
	;---
	mov eax, [dword @@PIXEL_X]
	mov edx, BYTE_VEC3_SIZE
	imul edx
	add eax, offset pixel_row
	mov ecx, eax
	
	;---
	; Get Color using: eax, edx
	;---
	;Bit    7  6  5  4  3  2  1  0
	;Data   R  R  R  G  G  G  B  B
	xor eax, eax; Will be used as the packed color
	mov edi, offset pixel_samples
	fld [dword offset nr_max_byte_float]
	fld [dword edi + vec3.z]
	fld [dword edi + vec3.y]
	fld [dword edi + vec3.x]
	
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
	mov [byte ecx + byte_vec3.z], dl
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
	mov [byte ecx + byte_vec3.y], dl
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
	mov [byte ecx + byte_vec3.x], dl
	and edx, 224
	;call print_int, edx
	shr edx, 6
	add eax, edx
	;--------------------
	; End of color
	;--------------------	
	mov [dword esi], eax
	


	;---
	; Pixel loops
	;---
	inc esi; video geheugen adress
	mov ecx, [dword @@PIXEL_X]
	inc ecx
	cmp ecx, SCRWIDTH
	jnz @@begin_width_loop
	
	call write_row, offset pixel_row
	
	mov ecx, [dword @@PIXEL_Y]
	inc ecx
	cmp ecx, SCRHEIGHT
	jnz @@begin_height_loop
	
	add esp, @@LOCAL_STACK_SIZE
	ret
ENDP ray_trace

DATASEG
	nr_max_byte_float dd 255.0
	nr_four           dd 4.0
	nr_two            dd 2.0
	nr_neg_half       dd -0.5
	nr_aspect_ratio   dd 1.2
	nr_1              dd 1.0
	nr_half           dd 0.5
	nr_background     dd 0.5
	nr_zero           dd 0.0
	msg_comparison_was_indeterminate db "Floating point comparison was indeterminate", 13, 10, '$'; 13, 10 == carrige return & \n
	msg_pos_discreminant             db "positieve (or zero) discreminant", 13, 10, '$'; 
	msg_neg_discreminant             db "negatieve discreminant", 13, 10, '$'; 
	
	;---
	; Initialize sphere
	;---
	num_spheres  dd 3
	sphere_datas sphere_obj <-0.2, 0.0, 0.7, 0.1, 1.0, 0.0, 0.0, 1>,\
	                        <0.2,  0.0, 0.7, 0.1, 0.0, 1.0, 0.0, 1>,\
	                        <0.0,  0.0, 2.0, 1.0, 0.0, 0.0, 1.0, 1>
	
	pixel_samples vec3 4 DUP()
	
	background_colors vec3 <0.097, 0.118, 0.205>, <0.877, 0.579, 0.437>

UDATASEG
	pixel_row db NUM_PIXEL_ROW_BYTES dup (?)
END
