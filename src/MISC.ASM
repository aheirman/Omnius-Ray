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

; -------------------------------------------------------------------
; CODE
; -------------------------------------------------------------------
CODESEG

PROC print_byte_list
	ARG @@len:dword, @@data:dword
	USES edi, ebx, eax
	
	mov edi, [@@len]
	inc edi
	mov ebx, [@@data]
	
	
@@beg_print_list:
	sub edi, 1
	jz @@end_print_list
	
	mov eax, [ebx]
	and eax, 0FFh
	
	call print_int, eax
	add ebx, 1

	jmp @@beg_print_list
@@end_print_list:

	mov ah, 09h
	mov edx, offset msg_end
	int 21h

	ret
ENDP print_byte_list

PROC print_int_list
	ARG @@len:dword, @@data:dword
	USES edi, ebx, eax
	
	mov edi, [@@len]
	inc edi
	mov ebx, [@@data]
	
	
beg_print_list:
	sub edi, 1
	jz end_print_list
	
	mov eax, [ebx]
	call print_int, eax
	add ebx, 4

	jmp beg_print_list
end_print_list:

	mov ah, 09h
	mov edx, offset msg_end
	int 21h

	ret
ENDP print_int_list


PROC bubble_sort
	ARG @@len:dword, @@data:dword
	USES edi, ebx, eax, ecx

beg_bubble_sort_outer:
	xor ecx, ecx
	mov edi, [@@len]
	mov ebx, [@@data]
	sub ebx, 4
	
beg_bubble_sort:
	sub edi, 1
	jz end_bubble_sort

	add ebx, 4
	
	mov eax, [ebx]
	mov edx, [ebx+4]
	
	;call print_int, eax
	;call print_int, edx
	
	cmp eax, edx
	jg beg_bubble_sort
	
	;call print_int, -1
	mov [ebx],   edx
	mov [ebx+4], eax
	mov ecx, 1; say that we did some work
	
	jmp beg_bubble_sort
end_bubble_sort:
	test ecx, ecx
	jnz beg_bubble_sort_outer

	ret
ENDP bubble_sort

	;-----
	; PRINT
	; prints a var on the stack
	;-----
PROC print_int
	ARG @@var:dword
	uses eax
	mov eax, [@@var]
	call print_int_eax
	ret
ENDP print_int

	;-----
	; PRINT
	; prints eax
	;-----
PROC print_int_eax
	;ARG eax
	USES eax, ebx, edx, esi, edi

	mov esi, eax
	
	mov edi, 10
	
	
	;----
	; Sign
	;----
	and eax, 80000000h
	jnz negative
	
	mov ah, 02h
	mov edx, '+'
	int 21h
	jmp end_negative
negative:
	mov ah, 02h
	mov edx, '-'
	int 21h
	not esi
	add esi, 1
end_negative:
	
beg_calc_char:
	sub edi, 1
	jz end_calc_char

	xor edx, edx
	mov EBX, 10
	mov eax, esi
	div EBX ; divide EDX:EAX by EBX: EAX=EAX/EBX, EDX=EAX%EBX
	
	mov esi, eax
	xor eax, eax

	push edx

	jmp beg_calc_char
end_calc_char:

	mov edi, 10
beg_print_char:
	sub edi, 1
	jz end_print_char
	
	mov ah, 02h
	pop edx
	add edx, '0'
	int 21h
	
	jmp beg_print_char
end_print_char:

	mov ah, 02h
	mov edx, ','
	int 21h

	ret
ENDP print_int_eax


DATASEG
    msg_end         db 13, 10, '$'; 13, 10 == carrige return & \n

END
