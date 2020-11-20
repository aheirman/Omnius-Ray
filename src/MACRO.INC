


; uses eax
MACRO FLOAT_TEST label_error, label_pos, label_neg, label_zero
	ftst                ;equivalent met fldz fcomp ST(1)
	                    ;compare the value of ST(0) to +0.0
	fstsw ax            ;copy the Status Word containing the result to AX
	fwait               ;insure the previous instruction is completed
	sahf                ;transfer the condition codes to the CPU's flag register
	jpe label_error ;the comparison was indeterminate
					    ;this condition should be verified first
					    ;then only two of the next three conditional jumps
					    ;should become necessary, in whatever order is preferred,
					    ;the third jump being replaced by code to handle that case
	ja   label_pos   ;when all flags are 0
	jb   label_neg   ;only the C0 bit (CF flag) would be set if no error
	jz   label_zero       ;only the C3 bit (ZF flag) would be set if no error
ENDM FLOAT_TEST

MACRO FLOAT_TEST_stx st_num, label_error, label_pos, label_neg, label_zero
	fcomp st( st_num )
	fstsw ax            ;copy the Status Word containing the result to AX
	fwait               ;insure the previous instruction is completed
	sahf                ;transfer the condition codes to the CPU's flag register
	jpe label_error ;the comparison was indeterminate
					    ;this condition should be verified first
					    ;then only two of the next three conditional jumps
					    ;should become necessary, in whatever order is preferred,
					    ;the third jump being replaced by code to handle that case
	ja   label_pos   ;when all flags are 0
	jb   label_neg   ;only the C0 bit (CF flag) would be set if no error
	jz   label_zero       ;only the C3 bit (ZF flag) would be set if no error
ENDM FLOAT_TEST

;st0 = st(0)^st(1)
MACRO POW
;;SOURCE https://www.madwizard.org/programming/snippets?id=36
    fyl2x; y*log_2 (x); 1 erop
    fld1
    fld st(1); 3 er op
    fprem; Remainder = ST(0) - (Q * ST(1)) , Q = truncating the quotient of ST(0)÷ST(1)
    f2xm1; 2^x -1; 3 er op
    fadd
    fscale; 3 er op
    fxch st(1)
    fstp st
ENDM POW

MACRO FLOAT_TEST_stx_enable st_num, enable_err, enable_pos, enable_neg, enable_zero, label_error, label_pos, label_neg, label_zero
	fcomp st( st_num )
	fstsw ax            ;copy the Status Word containing the result to AX
	fwait               ;insure the previous instruction is completed
	sahf                ;transfer the condition codes to the CPU's flag register
IF enable_err
	jpe label_error ;the comparison was indeterminate
					    ;this condition should be verified first
					    ;then only two of the next three conditional jumps
					    ;should become necessary, in whatever order is preferred,
					    ;the third jump being replaced by code to handle that case
ENDIF
IF enable_pos
	ja   label_pos   ;when all flags are 0
ENDIF
IF enable_neg
	jb   label_neg   ;only the C0 bit (CF flag) would be set if no error
ENDIF
IF enable_zero
	jz   label_zero       ;only the C3 bit (ZF flag) would be set if no error
ENDIF
ENDM FLOAT_TEST

; WARNING DIRTIES EAX
MACRO FLOAT_SKIP_IF_TINY
	fld st(0)
	fabs
	fld [dword offset nr_tiny]
	fcompp
	fstsw ax
	fwait
	sahf

	jpe @@error_handler
	ja  @@finish
ENDM  FLOAT_SKIP_IF_TINY


MACRO load_load_col_col_mul loc1:=<text_string>, loc2:=<text_string>, loc3:=<text_string>
	fld  [&loc1&r]
	fld  [&loc2&r]
	fmulp
	fstp [&loc3&r]
	
	fld  [&loc1&g]
	fld  [&loc2&g]
	fmulp
	fstp [&loc3&g]
	
	fld  [&loc1&b]
	fld  [&loc2&b]
	fmulp
	fstp [&loc3&b]
ENDM load_load_col_col_mul


MACRO load_load_vec3_vec3_mul loc1:=<text_string>, loc2:=<text_string>, loc3:=<text_string>
	fld  [&loc1&_x]
	fld  [&loc2&_x]
	fmulp
	fstp [&loc3&_x]
	
	fld  [&loc1&_y]
	fld  [&loc2&_y]
	fmulp
	fstp [&loc3&_y]
	
	fld  [&loc1&_z]
	fld  [&loc2&_z]
	fmulp
	fstp [&loc3&_z]
ENDM load_load_vec3_vec3_mul

; Pops st0
MACRO load_load_vec3_vec3_st0_mul_mul loc1:=<text_string>, loc2:=<text_string>, loc3:=<text_string>
	fld  [&loc1&_x]
	fld  [&loc2&_x]
	fmulp
	fmul
	fstp [&loc3&_x]
	
	fld  [&loc1&_y]
	fld  [&loc2&_y]
	fmulp
	fmul
	fstp [&loc3&_y]
	
	fld  [&loc1&_z]
	fld  [&loc2&_z]
	fmulp
	fmulp
	fstp [&loc3&_z]
ENDM load_load_vec3_vec3_st0_mul_mul


; How does the vec layout look in the fp stack?
; st(0): z      meaning: Dest   & left
; st(1): y      meaning: Dest   & left
; st(2): x      meaning: Dest   & left
; st(3): z      meaning: Source & right
; st(4): y      meaning: Source & right
; st(5): x      meaning: Source & right
; st(6): a      meaning: tmp constant

MACRO VEC3_LOAD loc:=<text_string>
	fld  [&loc&x]
	fld  [&loc&y]
	fld  [&loc&z]
ENDM  VEC3_LOAD


MACRO COL_LOAD loc:=<text_string>
	fld  [&loc&r]
	fld  [&loc&g]
	fld  [&loc&b]
ENDM  COL_LOAD

MACRO VEC3_LOAD1
	fld1
	fld1
	fld1
ENDM  VEC3_LOAD1

MACRO VEC3_LOADZ
	fldz
	fldz
	fldz
ENDM  VEC3_LOADZ

;MACRO VEC3_MOV loc:=<text_string>, loc2:=<text_string>
;	fld  [&loc&x]
;	fld  [&loc&y]
;	fld  [&loc&z]
;	
;	fstp  [&loc2&z]
;	fstp  [&loc2&y]
;	fstp  [&loc2&x]
;ENDM  VEC3_MOV

MACRO VEC3_STOREP loc:=<text_string>
	fstp  [&loc&z]
	fstp  [&loc&y]
	fstp  [&loc&x]
ENDM  VEC3_STOREP

MACRO COL_STORE loc:=<text_string>
	fstp  [&loc&b]
	fstp  [&loc&g]
	fstp  [&loc&r]
ENDM  COL_STORE


; Removoves the top 3 floats
MACRO VEC3_KILL
	fstp st(0)
	fstp st(0)
	fstp st(0)
ENDM  VEC3_KILL


;Look at the doc for information about this.
MACRO VEC3_EXCH
	fxch st(3)
	fxch st(1)
	fxch st(4)
	fxch st(2)
	fxch st(5)
	fxch st(2)
	fxch st(1)
ENDM  VEC3_EXCH


MACRO VEC3D_ST_MUL loc:=<text_string>
	fmul st(0), st(&loc&)
	fxch st(1)
	fmul st(0), st(&loc&)
	fxch st(1)
	
	fxch st(2)
	fmul st(0), st(&loc&)
	fxch st(2)
ENDM  VEC3D_VEC3_MUL

MACRO VEC3_OFFSET_ST0_MUL offset:=<text_string>
	fxch st(0 + &offset&)
	fmul st(0), st(&offset&)
	fxch st(0 + &offset&)
	
	fxch st(1 + &offset&)
	fmul st(0), st(1+&offset&)
	fxch st(1 + &offset&)
	
	fxch st(2 + &offset&)
	fmul st(0), st(2+&offset&)
	fxch st(2 + &offset&)
ENDM  VEC3_OFFSET_ST0_MUL

; WARNING: loc may not be 0!
MACRO VEC3_OFFSET_ST_MUL offset:=<text_string>, loc:=<text_string>
	fxch st(0 + &offset&)
	fmul st(0), st(&loc&)
	fxch st(0 + &offset&)
	
	fxch st(1 + &offset&)
	fmul st(0), st(&loc&)
	fxch st(1 + &offset&)
	
	fxch st(2 + &offset&)
	fmul st(0), st(&loc&)
	fxch st(2 + &offset&)
ENDM  VEC3D_VEC3_MUL

MACRO VEC3S_ST_MUL loc:=<text_string>
	VEC3_OFFSET_ST_MUL <3> <&loc&>
ENDM  VEC3S_VEC3_MUL

MACRO VEC3_VEC3_MUL
	fmul st(0), st(3); z*z_old
	fxch st(1)
	fmul st(0), st(4); y*y_old
	fxch st(1)
	
	fxch st(2)
	fmul st(0), st(5); x*x_old
	fxch st(2)
ENDM  VEC3_VEC3_MUL

MACRO VEC3_VEC3_MUL_ST6_MUL
	fmul st(0), st(3); z*z_old
	fmul st(0), st(6)
	fxch st(1)
	fmul st(0), st(4); y*y_old
	fmul st(0), st(6)
	fxch st(1)
	
	fxch st(2)
	fmul st(0), st(5); x*x_old
	fmul st(0), st(6); 
	fxch st(2)
ENDM  VEC3_VEC3_MUL_ST6_MUL

MACRO VEC3_VEC3_MUL_ST6_ADD
	fmul st(0), st(3); z*z_old
	fadd st(0), st(6)
	fxch st(1)
	fmul st(0), st(4); y*y_old
	fadd st(0), st(6)
	fxch st(1)
	
	fxch st(2)
	fmul st(0), st(5); x*x_old
	fadd st(0), st(6); 
	fxch st(2)
ENDM  VEC3_VEC3_MUL_ST6_ADD

; VEC3D staat voor VEC3_DEST
MACRO VEC3D_ST6_MUL_VEC3_ADD
	fmul st(0), st(6); x_dest*a
	fadd st(0), st(3); x_dest*a + x
	
	fxch st(1)
	fmul st(0), st(6); y_dest*a
	fadd st(0), st(4); y_dest*a + y
	fxch st(1)
	
	fxch st(2)
	fmul st(0), st(6); z_dest*a
	fadd st(0), st(5); z_dest*a + z
	fxch st(2)
ENDM  VEC3D_ST6_MUL_VEC3_ADD

MACRO VEC3_VEC3_ADD
	fadd st(0), st(3); z*z_old
	fxch st(1)
	fadd st(0), st(4); y*y_old
	fxch st(1)
	;
	fxch st(2)
	fadd st(0), st(5); x*x_old
	fxch st(2)
ENDM  VEC3_VEC3_ADD


; Dirties ST(6) & both vectors
MACRO VEC3_VEC3_ST6_WEIGHTED_AVG
	VEC3D_ST_MUL <6>
	fld1
	fsubrp st(7), st(0)
	VEC3_OFFSET_ST_MUL <3>, <6>
	VEC3_VEC3_ADD
ENDM  VEC3_VEC3_ST6_WEIGHTED_AVG


MACRO VEC3_L2_ST0
	fldz
	fadd st(1)
	fadd st(2)
	fadd st(3)
ENDM  VEC3_L2_ST0

MACRO VEC3P_L2_ST0
	fldz
	faddp st(1)
	faddp st(1)
	faddp st(1)
ENDM  VEC3P_L2_ST0

MACRO VEC3_L2_ST loc:=<text_string>
	fldz
	fadd st(1)
	fadd st(2)
	fadd st(3)
	fst st(&loc&)
ENDM  VEC3_L2_ST loc:=<text_string>

MACRO VEC3P_VEC3_DOT_ST0
	VEC3_VEC3_MUL
	VEC3P_L2_ST0
ENDM  VEC3P_VEC3_DOT_ST0


; Hoe het werkt:
;   st0: multiplactaie zone
;   st1; additie zone
;  ALGO:
;      steek x,y,z in st0
;      mul x,y,z
;      add het met de som, dest st1
;   pop multiplicatie zone
MACRO VEC3_VEC3_DOT_ST0
	fldz
	fldz
	fadd st(0), st(2); equivalent met fxch st(2) fst  st(2) aangezien st(0)=0
	fmul st(0), st(5)
	fadd st(1), st(0)
	
	fxch st(3)
	fst  st(3)
	fmul st(0), st(6)
	fadd st(1), st(0)
	
	fxch st(4)
	fst  st(4)
	fmul st(0), st(7)
	faddp st(1), st(0)
ENDM  VEC3_VEC3_DOT_ST0

; Hoe het werkt:
;   st0: multiplactaie zone
;   st1; additie zone
;  ALGO:
;      steek x,y,z in st0
;      mul x,y,z
;      add het met de som, dest st1
;   pop multiplicatie zone
MACRO VEC3D_DOT_ST0
	fldz
	fldz
	fadd st(0), st(2); equivalent met fxch st(2) fst  st(2) aangezien st(0)=0
	fmul st(0), st(0)
	fadd st(1), st(0)
	
	fxch st(3)
	fst  st(3)
	fmul st(0), st(0)
	fadd st(1), st(0)
	
	fxch st(4)
	fst  st(4)
	fmul st(0), st(0)
	faddp st(1), st(0)
ENDM  VEC3D_DOT_ST0

MACRO VEC3D_NORMALIZE
	VEC3D_DOT_ST0
	fsqrt
	fld1
	fdivrp
	VEC3_OFFSET_ST0_MUL <1>
	fstp st(0)
ENDM  VEC3D_NORMALIZE
