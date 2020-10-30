

;Size: 3*4 bytes  = 12 bytes
VEC3_SIZE EQU 12
STRUC vec3
	x    dd 0.0
	y    dd 0.0
	z    dd 0.0
ENDS

;Size: 6*4ytes + 4 bytes = 28 bytes
RAY_SIZE EQU 28
RAY_DIR_OFFSET EQU 12
RAY_CONTROL_OFFSET EQU 27
STRUC ray_obj
	origin_x    dd 0.0
	origin_y    dd 0.0
	origin_z    dd 0.0
	direction_x dd 0.0; NOTE: MUST BE NORMALIZED
	direction_y dd 0.0
	direction_z dd 0.0
	color_r     db 0
	color_g     db 0
	color_b     db 0
	hit         db 0
ENDS ray_obj

;Size: 4*4ytes + 0 bytes = 16 bytes
SPHERE_SIZE EQU 16
STRUC sphere_obj
	origin_x    dd 0.0
	origin_y    dd 0.0
	origin_z    dd 0.0
	radius      dd 0.0
ENDS sphere_obj