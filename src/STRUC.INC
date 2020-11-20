

;Size: 3*4 bytes  = 12 bytes
VEC3_SIZE EQU 12
STRUC vec3
	x    dd 0.0
	y    dd 0.0
	z    dd 0.0
ENDS

;Size: 3*4 bytes  = 12 bytes
COLOR_SIZE EQU 12
STRUC color
	r    dd 0.0
	g    dd 0.0
	b    dd 0.0
ENDS


;Size: 3 bytes  = 3 bytes
BYTE_VEC3_SIZE EQU 3
STRUC byte_vec3
	x    db 0
	y    db 0
	z    db 0
ENDS

;Size: 10*4ytes + 2 bytes = 42 bytes
RAY_SIZE           EQU 42
RAY_DIR_OFFSET     EQU 12; 3*4
RAY_COL_OFFSET     EQU 24; 6*4
RAY_CONTROL_OFFSET EQU 40; 10*4
STRUC ray_obj
	origin_x          dd 0.0
	origin_y          dd 0.0
	origin_z          dd 0.0
	direction_x       dd 0.0; NOTE: MUST BE NORMALIZED
	direction_y       dd 0.0
	direction_z       dd 0.0
	color_r           dd 0.0; eenheid: 100 lux
	color_g           dd 0.0
	color_b           dd 0.0
	depth             dd 0.0; WARNING: between the last object and this hit.
	hit               db 0
	count             db 0
ENDS ray_obj


;Size: 9*4ytes + 2 bytes = 38 bytes
SPHERE_SIZE                  EQU 38
SPHERE_COLOR_OFFSET          EQU 16
SPHERE_LAMBERTIAN_MUL_OFFSET EQU 28
SPHERE_DIFFUSE_OFFSET        EQU 32
STRUC sphere_obj
	origin_x        dd 0.0
	origin_y        dd 0.0
	origin_z        dd 0.0
	radius          dd 0.0
	color_r         dd 0.0; in byte procent: 255: 100%, 0: 0% indien het reflectief is,
	color_g         dd 0.0; anders is het 100 lux
	color_b         dd 0.0
	lambertian_mul  dd 0.0;  0.0: perfect normaal; 1.0: perfect lambertian
	diffuseness     dd 0.0;  0.0: spiegel;         1.0: niet-spiegel
	control         db 0;    bit 0: LOW: reflectief, HIGH: lichtbron
	padding         db 0
ENDS sphere_obj


