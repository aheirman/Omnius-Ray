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
INCLUDE "FILE.INC"

;https://dev.to/muiz6/c-how-to-write-a-bitmap-image-from-scratch-1k6m

;Size: 7*4ytes + 2 bytes = 30 bytes
BMP_HEADER_SIZE EQU 14
STRUC bmp_header_obj
	signature_p1 db 'B'
	signature_p2 db 'M'
	file_size    dd 54 + NUM_PIXEL_ROW_BYTES*FILE_HEIGHT
	padding      dd 0 
	pixel_offset dd 54
ENDS bmp_header_obj

BMP_INFO_HEADER_SIZE EQU 40
BMP_INFO_HEADER_WIDTH_OFFSET EQU 4
STRUC bmp_info_header_obj
	size_info_header     dd 40
	width                dd FILE_WIDTH;    Hierdoor beginnen we in de linker bovenhoek
	height               dd -FILE_HEIGHT
	num_color_planes     dw 1
	color_depth          dw 24
	compression          dd 0
	raw_bitmap_data_size dd 0
	horizontal_res       dd 3780; pixels per meter
	vertical_res         dd 3780
	color_table_entries  dd 0
	important_colors     dd 0
ENDS bmp_info_header_obj

CODESEG

PROC create_file
	USES eax, ebx, ecx, edx
	xor cx, cx ; no file attrivutes
	mov edx, offset filename
	mov ah, 3ch
	int 21h
	
	jnc @@no_error ; carry flag is set if error occurs

	mov  ah, 09h
	mov  edx, offset msg_create_error
	int  21h
	
	mov	ah,00h
	int	16h
	call terminate_process
	
@@no_error:
	mov [filehandle], ax
	ret
	ret
ENDP create_file

PROC close_file
	USES eax, ebx, ecx, edx
	mov bx, [filehandle]
	mov ah, 3Eh
	int 21h
	
	jnc @@no_error ; carry flag is set if error occurs

	mov  ah, 09h
	mov  edx, offset msg_close_error
	int  21h
	
	mov	ah,00h
	int	16h
	call terminate_process
	
@@no_error:
	ret
ENDP close_file

PROC create_bmp
	ARG @@WIDTH:dword, @@HEIGHT:dword 
	USES eax, ebx, ecx, edx
	
	
	call create_file
	
	mov bx, [filehandle]
	mov cx, BMP_HEADER_SIZE
	mov edx, offset bmp_header
	mov ah, 40h
	int 21h

	jnc @@no_error_1 ; carry flag is set if error occurs
	mov  ah, 09h
	mov  edx, offset msg_write_error_1
	int  21h
	
	mov	ah,00h
	int	16h
	call terminate_process
@@no_error_1:

	;--
	; Change width & Hieght in bmp_info_header
	;---
	
	mov ecx, [dword @@WIDTH]
	call print_int, ecx
	mov [dword offset image_width], ecx
	mov [dword offset bmp_info_header.width], ecx
	mov ecx, [dword @@HEIGHT]
	neg ecx
	call print_int, ecx
	mov [dword offset bmp_info_header.height], ecx
	
	;--
	; write bmp_info_header
	;---
	mov ecx, BMP_INFO_HEADER_SIZE
	mov edx, offset bmp_info_header
	mov ah, 40h
	int 21h
	
	jnc @@no_error_2 ; carry flag is set if error occurs
	mov  ah, 09h
	mov  edx, offset msg_write_error_2
	int  21h
	
	mov	ah,00h
	int	16h
	call terminate_process
@@no_error_2:
	
	ret
ENDP create_bmp

PROC close_bmp
	call close_file
	ret
ENDP close_bmp

;NOTE: must be a packed array of 24bit (8bit per chanel) pixels
PROC write_row
	ARG @@PIXEL_ARRAY_PTR:dword
	USES eax, ebx, ecx, edx

	mov bx, [filehandle]
	mov ecx, [dword offset image_width]; NOT NUM_PIXEL_ROW_BYTES, it must be less than NUM_PIXEL_ROW_BYTES though
	lea ecx, [ecx + 2*ecx]; ecx = 3*ecx
	mov edx, [@@PIXEL_ARRAY_PTR]
	mov ah, 40h
	int 21h
	
	jnc @@no_error_3 ; carry flag is set if error occurs
	mov  ah, 09h
	mov  edx, offset msg_write_error_3
	int  21h
	
	mov	ah,00h
	int	16h
	call terminate_process

@@no_error_3:
	ret
ENDP write_row

DATASEG
	image_width dd 320
	
	filename           db "IMAGE.BMP", 0
	msg_create_error   db "could not create file", 13, 10, '$'
	msg_close_error    db "could not close file", 13, 10, '$'
	msg_write_error_1  db "could not write header", 13, 10, '$'
	msg_write_error_2  db "could not write into header", 13, 10, '$'
	msg_write_error_3  db "could not write into pixel data", 13, 10, '$'
	bmp_header      bmp_header_obj <>
	bmp_info_header bmp_info_header_obj <>

UDATASEG
	filehandle dw ?
END
