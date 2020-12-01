; -------------------------------------------------------------------
; 80386
; 32-bit x86 assembly language
; TASM
;
; author:       Aron Heirman
; date:         27/10/2020
; program:      Hello World!
; -------------------------------------------------------------------
; Word art: https://patorjk.com/software/taag/#p=display&f=Ogre&t=intersect_sphere

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
INCLUDE "MACRO.INC"
INCLUDE "KEYB.INC"

; compile-time constants (with macros)
VMEMADR   EQU 0A0000h
SCRWIDTH  EQU 320
SCRHEIGHT EQU 200

NUM_SUB_PIXELS          EQU 1;16;1;16;64
NUM_SUB_PIXELS_PER_AXIS EQU 1;1;4;8
MAX_BOUNCES             EQU 5


; -------------------------------------------------------------------
; CODE
; -------------------------------------------------------------------
CODESEG



PROC print_ray
	ARG @@ray_ptr:dword
	uses eax, ebx, ecx
	
	;call print_int, eax
	mov eax, [@@ray_ptr]

	mov ecx, eax
	call print_vec3_x1000, ecx
	
	mov ecx, eax
	add ecx, RAY_DIR_OFFSET
	call print_vec3_x1000, ecx
	
	mov ecx, eax
	add ecx, RAY_COL_OFFSET
	call print_vec3_x1000, ecx
	
	call print_rounded_floatx1000, [eax + ray_obj.depth]
	
	add eax, RAY_CONTROL_OFFSET
	call print_byte_list, 1, eax
	
	call print_endl
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

MACRO is_depth_smaller
	fld [ebx + ray_obj.depth]
	fcomp
	fstsw ax            ;copy the Status Word containing the result to AX
	fwait               ;insure the previous instruction is completed
	sahf                ;transfer the condition codes to the CPU's flag register
	jpe @@error_handler
	jb @@finish
ENDM is_depth_smaller

MACRO is_positive
	ftst
	fstsw ax
	fwait
	sahf
	jpe @@error_handler
	jb @@finish
	jz @@finish
ENDM is_positive

; ebx: ray ptr
; ecx: next_ray ptr
; edx: normal
; edi: temporary
MACRO NEXT_RAY_DIR lambertian_mul_loc:=<text_string>, diffuse_mul_offset:=<text_string>
	;;-------
	;; Bereken de next direction via Lambertian reflectance
	;; pseudo code: Next ray.dir = normal + vec3_in_unit_hemisphere
	;;   OPM het is vec3_in_unit_hemisphere niet vec3_in_unit_sphere
	;;      vec3_in_unit_sphere werd veel foutief gebruikt.
	;;-------
	mov esi, [&lambertian_mul_loc&]
	call vec3_in_unit_hemisphere, edx, esi, edi
	VEC3_LOAD   <edx + vec3.>; normaal
	VEC3_LOAD   <edi + vec3.>
	VEC3_VEC3_ADD; lambertian = normal + hemisphere
	VEC3D_NORMALIZE
	VEC3_STOREP <edi + vec3.>
	
	;;-------
	;; Bereken de next direction via Reflection
	;; pseudo code: Next ray.dir = ray.dir - 2*dot(ray.dir,normal)*normal;
	;;-------
	;; Note: normaal zit bovenaan
	VEC3_LOAD <ebx + ray_obj.direction_>; laod direction of old ray
	VEC3_VEC3_DOT_ST0
	fld [dword offset nr_n2]
	fmulp st(1),st(0)
	fstp st(7)
	VEC3S_ST_MUL <6>
	VEC3_VEC3_ADD
	VEC3D_NORMALIZE
	
	;;---
	;; Neem een gewogen gemiddelde
	;;---
	VEC3_LOAD   <edi + vec3.>; lambertian
	fld [&diffuse_mul_offset&]
	fstp st(7); steekt het in 6
	VEC3_VEC3_ST6_WEIGHTED_AVG
	VEC3_STOREP <ecx + ray_obj.direction_>
ENDM  NEXT_RAY_DIR

; _       _                          _                 _                   
;(_)_ __ | |_ ___ _ __ ___  ___  ___| |_     ___ _ __ | |__   ___ _ __ ___ 
;| | '_ \| __/ _ \ '__/ __|/ _ \/ __| __|   / __| '_ \| '_ \ / _ \ '__/ _ \
;| | | | | ||  __/ |  \__ \  __/ (__| |_    \__ \ |_) | | | |  __/ | |  __/
;|_|_| |_|\__\___|_|  |___/\___|\___|\__|___|___/ .__/|_| |_|\___|_|  \___|
;                                      |_____|  |_|                        
;
;
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
	FLOAT_SKIP_IF_TINY
	is_depth_smaller
	fstp [ebx + ray_obj.depth]; Update the ray-depth
	;-------------
	;--------------
	; UPDATING RAY
	;-------------
	;-------------
	
	;mov ah, 09h
	;mov edx, offset msg_updating_ray
	;int 21h
	
	
	
	;---
	; Zet de nieuwe origin
	; pseudo code: nieuwe_origin = oude_origin + oude_direction * t;
	;---
	; ebx: ptr naar oude ray
	mov ebp, [esp + @@LOCAL_STACK_SIZE]; Zet ebp terug goed
	mov ecx, [@@next_ray_ptr]
	mov esi, [ebx + ray_obj.depth]; lengte
	
	add ebx, RAY_DIR_OFFSET
	call vec3_mul_float_res, ebx, esi, ecx; sla direction*depth tijdelijk op in new origin
	sub ebx, RAY_DIR_OFFSET
	
	; esi: tijdelijke vec, ebx origin ptr oud --> ecx: origin nieuw
	call vec3_add_res, ebx, ecx, ecx

	
	;-------
	; Bereken de normaal
	; pseudo code: normalize(nieuwe_origin-sphere_center)
	;-------
	lea edi, [@@vec3_tmp];  Dit zal de ongenormaliseerde normaal zijn.
	mov eax, [@@sphere_ptr];          ptr naar sphere, het eerste is de origin
	call vec3_sub_res, ecx, eax, edi; links, rechts, ptr
	;call print_vec3, ecx
	;call print_vec3, eax
	;call print_vec3, edi
	lea edx, [@@vec3_normal]
	call vec3_normalize_dest, edi, edx
	
	NEXT_RAY_DIR <dword eax + SPHERE_LAMBERTIAN_MUL_OFFSET>, <dword eax + SPHERE_DIFFUSE_OFFSET>

	;call print_ray, ecx
	
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
	; NOTE: WE DON'T NEED TO CORRECT FOR THE SQUARE CUBE LAW
	;----
	;      eax: sphere
	mov esi, [dword @@ray_ptr];         esi: oude ray
	;                             ecx: nieuwe ray	
	load_load_col_col_mul <dword eax + sphere_obj.color_>, <dword esi + ray_obj.color_>, <dword ecx + ray_obj.color_>
	

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

PROC intersect_ground
	ARG @@ray_ptr:dword, @@next_ray_ptr:dword
	LOCAL @@NORMAL:vec3, @@VEC_TMP1:vec3
	uses eax, ebx, ecx, edx, edi, esi
	
	
	mov ebx, [@@ray_ptr]
	mov ecx, [@@next_ray_ptr]
	
	
	;Check if the direction is zero, if so, not intersecting

	fld [ebx + ray_obj.direction_y]
	FLOAT_SKIP_IF_TINY
	; direction is no longer tiny
	; calculate distance
	fld [ebx + ray_obj.origin_y]
	
	fdivrp st(1), st; t = origin_y/direction_y
	fchs
	is_positive
	FLOAT_SKIP_IF_TINY
	is_depth_smaller
	; We've hit it & It's the best one we've found
	mov [byte ebx + ray_obj.hit], 1
	
	fst [dword ebx + ray_obj.depth]; Update the ray-depth
	; depth is now guaranteed smaller
	
	lea edx, [@@NORMAL]
	fldz
	fst  [dword edx + vec3.x]
	fstp [dword edx + vec3.z]
	fld1
	fstp [dword edx + vec3.y]
	lea edi, [@@VEC_TMP1]
	
	NEXT_RAY_DIR <dword offset plane + PLANE_LAMBERTIAN_MUL_OFFSET>, <dword offset plane + PLANE_DIFFUSE_OFFSET>

	
	; st = ray_obj.depth
	; nieuwe_origin = oude_origin + oude_direction * t;
	VEC3_LOAD  <dword ebx + ray_obj.origin_>
	VEC3_LOAD  <dword ebx + ray_obj.direction_>
	VEC3D_ST6_MUL_VEC3_ADD
	VEC3_STOREP <dword ecx + ray_obj.origin_>
	
	
	
	fld [dword offset plane + PLANE_REFLECTIVITY_OFFSET]
	COL_LOAD  <dword ebx + ray_obj.color_>
	;VEC3_LOADZ
	;VEC3_LOAD1
	;VEC3_VEC3_MU
	VEC3D_ST_MUL <3>
	COL_STORE <dword ecx + ray_obj.color_>
	
	
	;call print_ray, ebx
	;call print_ray, ecx
	;call print_int, ebx
	;call print_int, ecx
	
@@finish:
	ret

@@error_handler:
	mov ah, 09h
	mov edx, offset msg_comparison_was_indeterminate
	int 21h
	
	call print_rounded_floatx1000, [ebx + ray_obj.origin_y]
	call print_rounded_floatx1000, [ebx + ray_obj.direction_y]
	
	mov	ah,00h
	int	16h
	call terminate_process
ENDP intersect_ground
	
	
;    _       _                          _            _     _           _       
;   (_)_ __ | |_ ___ _ __ ___  ___  ___| |_     ___ | |__ (_) ___  ___| |_ ___ 
;   | | '_ \| __/ _ \ '__/ __|/ _ \/ __| __|   / _ \| '_ \| |/ _ \/ __| __/ __|
;   | | | | | ||  __/ |  \__ \  __/ (__| |_   | (_) | |_) | |  __/ (__| |_\__ \
;   |_|_| |_|\__\___|_|  |___/\___|\___|\__|___\___/|_.__// |\___|\___|\__|___/
;                                         |_____|       |__/                   
;   

PROC intersect_objects
	; De nieuwe ray
	ARG @@ray_ptr:dword
	LOCAL @@RAY_TMP:ray_obj, @@RAY_COUNTER:dword, @@TMP_VEC3_1:vec3, @@TMP_VEC3_2:vec3, @@TMP_VAR:dword, @@TMP_VAR_2:dword
	uses eax, ebx, ecx, edx, esi
	
	mov ebx, [dword @@ray_ptr]
	lea edx, [@@RAY_TMP];       ptr naar de nieuwe ray
	
	;----
	; Zorg ervoor dat de kleur altijd klaar is voor de volgende 
	;----
	fld1
	fst  [dword ebx + ray_obj.color_r]
	fst  [dword ebx + ray_obj.color_g]
	fst  [dword ebx + ray_obj.color_b]
	fst  [dword edx + ray_obj.color_r]
	fst  [dword edx + ray_obj.color_g]
	fstp [dword edx + ray_obj.color_b]	
	
	mov ecx, MAX_BOUNCES
@@ray_loop_begin:
	mov [dword @@RAY_COUNTER], ecx
	
	mov ecx, [dword offset num_spheres]
	mov eax, offset sphere_datas


	;----
	; Zet de depth to infinity, hierdoor is iedere echte diepte kleiner
	;----
	fld1
	fldz
	fdivp
	fstp [dword ebx + ray_obj.depth]
	mov  [byte ebx + ray_obj.hit], 0
	
@@sphere_loop_begin:
	cmp ecx, 0
	je @@sphere_loop_end
	
	;call print_sphere, eax
	;call print_ray, ebx
	;call print_int, ebx
	call intersect_sphere, eax, ebx, edx; eax: sphere
    ;                                     ebx: ray
	;                                     edx: next ray
	;call print_int, 5

	
	
	dec ecx
	add eax, SPHERE_SIZE
	jmp @@sphere_loop_begin
@@sphere_loop_end:

	call intersect_ground, ebx, edx
	;call print_ray, ebx
	;call print_ray, edx
	;call print_int, ebx
	;call print_int, edx
    ;                                     ebx: ray
	;                                     edx: next ray

	;call print_int, 6
	;call print_endl
	;call print_ray, ebx
	;call print_ray, edx
	
	;---
	; Hebben we iets geraakt?
	;    Indien ja: We kunnen verder loopen
	;          nee: We moeten stoppen.
	;                  --> Vemenig vuldig de begin ray met de background kleur.
	;---
	cmp [byte ebx + ray_obj.hit], 0
	jz @@no_object_hit

	;---
	; Move color of the next ray in the old ray.
	;---
	;mov eax, [dword edx + ray_obj.color_r]
	;mov [dword ebx + ray_obj.color_r], eax
	;mov eax, [dword edx + ray_obj.color_g]
	;mov [dword ebx + ray_obj.color_g], eax
	;mov eax, [dword edx + ray_obj.color_b]
	;mov [dword ebx + ray_obj.color_b], eax



	mov esi, ebx; switch rays
	mov ebx, edx
	mov edx, esi
	
	mov ecx, [dword @@RAY_COUNTER]
	loop @@ray_loop_begin
	jmp @@expended_ray_intersect_budget


	;jmp @@end
	;---
	;We zijn in de buitenlucht
	;---
@@no_object_hit:
	;---
	; EDX: the old ray
	;---
	
	;mov ah, 09h
	;mov edx, offset msg_no_object_hit
	;int 21h
	
	mov esi, [@@ray_ptr]
	lea esi, [esi + RAY_COL_OFFSET]
	;---
	; Calculate background color
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
	
	call vec3_add_res, eax, ecx, eax
	
	;---
	; Vermenigvuldig background color
	;---
	mov ecx, ebx
	add ecx, RAY_COL_OFFSET
	call vec3_mul_vec3_res, eax, ecx, esi
	
	;mov eax, [dword offset nr_1]
	;mov [esi + vec3.x],  eax
	;mov [esi + vec3.y],  eax
	;mov [esi + vec3.z],  eax
	
	jmp @@end
	
	
	;---
	; We zitten in een loop vast
	;---
@@expended_ray_intersect_budget:
	;mov ah, 09h
	;mov edx, offset msg_expended_ray_intersect_budget
	;int 21h
	
	mov esi, [@@ray_ptr]
	lea esi, [esi + RAY_COL_OFFSET]
	mov [esi + vec3.x],  0
	mov [esi + vec3.y],  0
	mov [esi + vec3.z],  0

@@end:
	ret
ENDP intersect_objects


; Converts float to byte
; stores the color in the line buffer
; stores trunkated in b-the byte that will be used for 13h screen buffer
; It also does color space correction:
;	https://www.khronos.org/registry/OpenGL/extensions/ARB/ARB_framebuffer_sRGB.txt
; WARNING USES: EAX
MACRO color_to_color loc_in_float_stack, bmp_offset, shr_number, screen_enable
	LOCAL @@collor_correction_finished, @@exponential, @@not_cliping
	;; Color space correction
	;;if (cl < 0.0031308) {
    ;;    cs = 12.92 * cl;
    ;;} else {
    ;;    cs = 1.055 * pow(cl, 0.41666) - 0.055;
    ;;}
	fld [dword offset nr_srgb_1]
	FLOAT_TEST_stx_enable 1, 1,0,1,0, @@error_handler, , @@exponential
	fld [dword offset nr_srgb_2]
	fmulp
	jmp @@collor_correction_finished
@@exponential:
	fld [dword offset nr_srgb_4]
	fxch st(1)
	POW
	fld [dword offset nr_srgb_3]
	fmulp
	fld [dword offset nr_srgb_6]
	fsubp
@@collor_correction_finished:


	;;All the rest
	;; loc_in_float_stackis the location of 255.0 in the float stack
	fmul st, st( loc_in_float_stack )
	fistp [dword esp]
	mov edx, [dword esp]
	;;call print_int, edx
	cmp edx, 255
	jl @@not_cliping
	;;call print_endl
	mov edx, 255
@@not_cliping:
	;; write to file
	mov [byte ecx + bmp_offset], dl
	
IF screen_enable
	;; Anden met 3e bovenste bits
	and edx, 224
	shr edx, shr_number
	add edi, edx
ENDIF

ENDM  color_to_color

;     _ __ __ _ _   _   | |_ _ __ __ _  ___ ___ 
;    | '__/ _` | | | |  | __| '__/ _` |/ __/ _ \
;    | | | (_| | |_| |  | |_| | | (_| | (_|  __/
;    |_|  \__,_|\__, |___\__|_|  \__,_|\___\___|
;               |___/_____|                     
;
; SETTINGS
;   bit 0: HIGH: 1080p
;          LOW:  LOW RES & square pixel correction
;
PROC ray_trace
	ARG @@SETTINGS:dword
	LOCAL @@RAY:ray_obj, @@SUBPIXEL_X:dword, @@SUBPIXEL_Y:dword, @@PIXEL_X:dword, @@PIXEL_Y:dword,\
	      @@TMP_VAR:dword, @@WIDTH:dword, @@HEIGHT:dword
	USES eax, ebx, ecx, edx, esi, edi
	
	mov [dword @@SUBPIXEL_X], 0
	mov [dword @@SUBPIXEL_Y], 0
	mov [dword @@PIXEL_X], 0
	mov [dword @@PIXEL_Y], 0
	lea ebx, [@@RAY]

	xor esi, esi
	mov esi, 0a0000h

	;---
	; Settings
	;---
	mov eax, [dword @@SETTINGS]
	and eax, 1
	cmp eax, 1
	jne  @@low_res
	mov [dword @@WIDTH],  FILE_WIDTH
	mov [dword @@HEIGHT], FILE_HEIGHT
	jmp @@end_res
@@low_res:
	mov [dword @@WIDTH],  SCRWIDTH
	mov [dword @@HEIGHT], SCRHEIGHT
@@end_res:
	call create_bmp, [dword @@WIDTH], [dword @@HEIGHT]





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
	
	;---
	; Do we need to stop?
	;---
	mov     al, [__keyb_rawScanCode]
	cmp     al, 01h
	je      @@finish ; check if ESC is pressed, otherwise keep looping
	
	
	;; Zet de depth to infinity, hierdoor is iedere echte diepte kleiner
	;fld1
	;fldz
	;fdivp
	;fstp [dword ebx + ray_obj.depth]
	;mov [byte ebx + ray_obj.hit], 0
	
	
	;fldz
	;fst  [dword ebx + ray_obj.direction_y]
	;fstp [dword ebx + ray_obj.]
	
	fldz
	;fst  [dword ebx + ray_obj.origin_x]
	;fstp  [dword ebx + ray_obj.origin_z]

	VEC3_LOAD  <dword offset camera_start_origin.>
	VEC3_STOREP <dword ebx + ray_obj.origin_>

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
	
	fild [dword @@WIDTH]
	fdivp
	fld [dword offset nr_neg_half]
	faddp
	
	;---
	;Correct for the non square pixels
	;---
	mov eax, [dword @@SETTINGS]
	and eax, 1
	cmp eax, 1
	je  @@no_square_pixel_correction
	fld [dword offset nr_aspect_ratio]
	fmulp
@@no_square_pixel_correction:
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
	
	
	fild [dword @@HEIGHT]
	fdivp
	fld  [dword offset nr_neg_half]
	faddp
	fchs
	; Voor orthonormaal gebruik deze
	;fst  [dword ebx + ray_obj.origin_y]
	fstp [dword ebx + ray_obj.direction_y]

	;---
	; Zet de kleur multiplier naar 1.0, 1.0, 1.0
	;--- 
	;mov ecx, [dword offset nr_1]
	;mov [dword ebx + ray_obj.color_r], ecx
	;mov [dword ebx + ray_obj.color_g], ecx
	;mov [dword ebx + ray_obj.color_b], ecx

	;----
	; Zorg ervoor dat de kleur altijd klaar is voor de volgende 
	;----
	fld1
	fst  [dword ebx + ray_obj.color_r]
	fst  [dword ebx + ray_obj.color_g]
	fstp [dword ebx + ray_obj.color_b]


	;---
	; Intersect
	;---
	call intersect_objects, ebx
	;call print_ray, ebx
	;--


	

	
	;---
	; Sla kleur op in de pixel samples
	;---
	mov ecx, [dword @@SUBPIXEL_X]
	mov edx, [dword @@SUBPIXEL_Y]
	lea edx, [ecx + edx*NUM_SUB_PIXELS_PER_AXIS]
	;call print_int, edx
	mov eax, VEC3_SIZE
	imul edx;                                      maakt de eax = arrayindex
	mov edi, eax
	add edi, offset pixel_samples

	mov ecx, [dword ebx + ray_obj.color_r]
	mov [edi + vec3.x],  ecx
	mov ecx, [dword ebx + ray_obj.color_g]
	mov [edi + vec3.y],  ecx
	mov ecx, [dword ebx + ray_obj.color_b]
	mov [edi + vec3.z],  ecx


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
	AVERAGE_COLORS <dword offset pixel_samples>, <dword offset nr_sub_pixels>
	
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
	mov edi, offset pixel_samples
	fld [dword offset nr_max_byte_float]
	fld [dword edi + vec3.z]
	fld [dword edi + vec3.y]
	fld [dword edi + vec3.x]
	
	;---
	; color_to_color
	;---
	mov eax, [dword @@SETTINGS]
	and eax, 1
	cmp eax, 1
	je  @@dont_write_to_frame_buffer
	xor edi, edi; Will be used as the packed color
	color_to_color 3, byte_vec3.z, 0, 1;  r
	color_to_color 2, byte_vec3.y, 3, 1;  g
	color_to_color 1, byte_vec3.x, 6, 1;  b
	mov [dword esi], edi; video geheugen adress
	inc esi
	jmp @@after_col_col

@@dont_write_to_frame_buffer:
	color_to_color 3, byte_vec3.z, 0, 0;  r
	color_to_color 2, byte_vec3.y, 3, 0;  g
	color_to_color 1, byte_vec3.x, 6, 0;  b
@@after_col_col:


	;---
	; Pixel loops
	;---
	mov ecx, [dword @@PIXEL_X]
	inc ecx
	cmp ecx, [dword @@WIDTH]
	jnz @@begin_width_loop
	
	call write_row, offset pixel_row
	
	mov ecx, [dword @@PIXEL_Y]
	inc ecx
	;---
	; Minigame?
	;---
	mov eax, [dword @@SETTINGS]
	and eax, 1
	cmp eax, 1
	jne  @@no_minigame
	call print_int, ecx
@@no_minigame:
	cmp ecx, [dword @@HEIGHT]
	jnz @@begin_height_loop
	
@@finish:
	call close_bmp
	ret
	
@@error_handler:
	mov ah, 09h
	mov edx, offset msg_comparison_was_indeterminate
	int 21h

ENDP ray_trace


;                         _        __       
;     _ __ __ _ _   _    (_)_ __  / _| ___  
;    | '__/ _` | | | |   | | '_ \| |_ / _ \ 
;    | | | (_| | |_| |   | | | | |  _| (_) |
;    |_|  \__,_|\__, |___|_|_| |_|_|  \___/ 
;               |___/_____|               
;    
PROC ray_info
	LOCAL @@TMP_RAY:ray_obj, @@PIXEL_X:dword, @@PIXEL_Y:dword
	USES eax, ebx, ecx, edx, esi
	
	mov [dword @@PIXEL_X], 0
	mov [dword @@PIXEL_Y], 0
	lea ebx, [@@TMP_RAY]
	
	fldz
	fst  [dword ebx + ray_obj.origin_x]
	fstp  [dword ebx + ray_obj.origin_z]

	fld1
	fstp  [dword ebx + ray_obj.origin_y]	

	;fld1
	;fstp [dword ebx + ray_obj.direction_z]
	;
	;
	;;---
	;; X-location
	;;---
	;fild [dword @@PIXEL_Y]
	;fstp  [dword ebx + ray_obj.direction_x]
	;; Voor orthonormaal gebruik deze
	;;fstp  [dword ebx + ray_obj.origin_x]
	;
	;;---
	;; Y-location
	;;--- 
	;fild [dword @@PIXEL_Y]
	;fstp [dword ebx + ray_obj.direction_y]

	fld1
	;fchs
	fstp [dword ebx + ray_obj.direction_y]
	fldz
	fst  [dword ebx + ray_obj.direction_x]
	fstp [dword ebx + ray_obj.direction_z]


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
	;call print_ray, ebx
	call intersect_objects, ebx
	;call print_ray, ebx
	
	ret
ENDP ray_info



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
	nr_tiny           dd 0.0001
	nr_n2             dd -2.0
	nr_sub_pixels     dd NUM_SUB_PIXELS.0
	
	;---
	; SRGB COLOR SPACE VALUES
	;---
	nr_srgb_1         dd 0.0031308
	nr_srgb_2         dd 12.92
	nr_srgb_3         dd 1.055
	nr_srgb_4         dd 0.41666
	nr_srgb_6         dd 0.055
	
	msg_comparison_was_indeterminate db "Floating point comparison was indeterminate", 13, 10, '$'; 13, 10 == carrige return & \n
	msg_pos_discreminant             db "positieve (or zero) discreminant", 13, 10, '$'; 
	msg_neg_discreminant             db "negatieve discreminant", 13, 10, '$'; 
	
	msg_expended_ray_intersect_budget db "expended_ray_intersect_budget", 13, 10, '$'
	msg_no_object_hit                 db "no_object_hit", 13, 10, '$'
	msg_updating_ray                  db "updating_ray", 13, 10, '$'
	
	;---
	; Initialize sphere
	;---
	num_spheres  dd 4
	sphere_datas sphere_obj <-0.2, 0.36, 0.7, 0.1, 0.5,  0.2, 0.2,  1.0, 0.1, 1>,\
	                        <0.2,  0.36, 0.7, 0.1, 0.2,  0.5, 0.2,  1.0, 0.1, 1>,\
	                        <0.0,  1.0,  2.0, 1.0, 0.99, 1.0, 0.99, 1.0, 0.1, 1>,\
							<0.0,  0.31, 0.7, 0.1, 0.9,  0.1, 0.9,  1.0, 0.9, 1>

	plane plane_obj <0.7, 1.0, 0.1>
	
	pixel_samples vec3 NUM_SUB_PIXELS DUP(?)
	
	background_colors vec3  <0.877, 0.579, 0.437>, <0.097, 0.118, 0.205>
	;background_colors vec3 <1.0, 1.0, 1.0>, <0.5, 0.7, 1.0>
	;background_colors vec3 <1.0, 1.0, 1.0>, <1.0, 1.0, 1.0>
	;background_colors vec3 <0.0, 0.0, 0.0>, <1.0, 1.0, 1.0>
	
	camera_start_origin vec3 <0.0, 0.5, 0.0>;<0.3, 0.1, -0.3>
UDATASEG
	pixel_row db NUM_PIXEL_ROW_BYTES dup (?)
END
