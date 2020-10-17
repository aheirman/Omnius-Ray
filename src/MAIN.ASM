; -------------------------------------------------------------------
; 80386
; 32-bit x86 assembly language
; TASM
;
; author:       Aron Heirman
; date:         03/10/2020
; program:      Hello World!
; -------------------------------------------------------------------

IDEAL
P386
MODEL FLAT, C

ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

INCLUDE "VEC.INC"

; -------------------------------------------------------------------
; CODE
; -------------------------------------------------------------------



CODESEG

main:
    sti            ; set The Interrupt Flag => enable interrupts
    cld            ; clear The Direction Flag


	mov ah, 09h
	mov edx, offset msg_ugly
	int 21h

	;mov al, 13h
	;mov ah, 0
	;int 10h     ; set graphics video mode.
	
	
	;mov al, 1100b; color
	;mov cx, 10; x
	;mov dx, 20; y
	;mov ah, 0ch
	;int 10h     ; set pixel. 
	
	;push offset arrdata
	;push 25;[offset arrlen]
	;call print_int_list
	;add sp, 2
	call print_int_list, [dword offset arrlen], offset arrdata
	
	mov ah, 09h
	mov edx, offset msg_end
	int 21h
	int 21h
	
	call bubble_sort,  [dword offset arrlen], offset arrdata
	
	mov ah, 09h
	mov edx, offset msg_end
	int 21h
	int 21h
	
	call print_int_list, [dword offset arrlen], offset arrdata
	
	; Terminate process with return code in response to a keystroke.
    mov ax,4C00h
	int     21h


; -------------------------------------------------------------------
; DATA
; -------------------------------------------------------------------
DATASEG
    msg_end         db 13, 10, '$'; 13, 10 == carrige return & \n
	msg_ugly        db "Hello Really ~Ugly~ World!", 13, 10, '$'; 13, 10 == carrige return & \n
	arrlen dd 25
	arrdata dd 814724, 905792, 126987, 913376, 632360, 97541, 278499, 546882, 957507, 964889, 157614, 970593, 957167, 485376, 800281, 141887, 421762, 915736, 792208, 959493, 655741, 35712, 849130, 933994, 678736


; -------------------------------------------------------------------
; STACK
; -------------------------------------------------------------------
STACK 100h; 100 bytes groot

END main
