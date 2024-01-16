[bits 16]
[org 0x7c00]
jmp start

; nasm -f bin game.asm -o test.bin
; qemu-system-x86_64 test.bin

;========================================================================
;========================================================================

; BOOT_DRIVE					db 0
video_memory_address		equ 0xA000
grid_address				equ 0x8000
grid_sectors				equ 16

frame_width					equ 320	; value should be divisible by 16
frame_height				equ 200	; grid starts from top left (0,0)

;========================================================================
;========================================================================

start:
	xor eax, eax
	xor esi, esi	; clear 32 bit registers for later lea math just in case
	xor edi, edi
	xor ebx, ebx
	mov es, ax
	mov ds, ax
	mov ss, ax
	mov sp, 0x7c00

	; mov [BOOT_DRIVE], dl

	mov ah, 0x02	; read data to memory
	mov al, grid_sectors;		; no. of sectors
	mov ch, 0;65		; cylinder_count 
	mov cl, 2;37		; sector in head
	mov dh, 0;101		; head_count
	; mov dl, [BOOT_DRIVE]
	; xor bx, bx
	; mov es, bx
	mov bx, grid_address
	int 0x13
	
	mov ah, 0
	mov al, 0x0d
	int 0x10

	push video_memory_address
	pop es				; es will remain as video_memory_address
	xor bx, bx

;========================================================================
game_setup:
; exit on user input
	; mov ah, 1
	; int 0x16
	; jnz _end

	xor di, di
	xor si, si

.loop:
	lea bx, [edi+esi]
	mov ax, [bx+grid_address]
	mov [es:bx], ax
	add di, 2
	cmp di, frame_width / 8
	jb .loop
.next_row:
	xor di, di
	add si, 40						;
	cmp si, frame_height * 40		;* 40 as video memory is 40 bytes in width
	jb .loop

	xor di, di
	xor si, si

	xor bx, bx
	jmp neighbour_checks.top_left_corner
	
game_loop:
	xor bx, bx

	cmp di, frame_width
	je .new_row

.same_row:
	jmp neighbour_checks

.new_row:
	xor di, di
	cmp si, frame_height
	je game_setup
	inc si
	jmp neighbour_checks.left_edge	; as di is 0, can jump straight here

;========================================================================
;========================================================================
;	returns al as the bit in the byte
;	increments bl if al is not zero
get_bit_state:	; called ~8x64K times (a lot)
	mov dx, di
	;	math for finding bit in the byte - could use lookup table
	and di, 0x0007 ; 0000 0000 0000 0111
	mov cx, di	; store remainder
	mov di, dx
	mov ch, 0b10000000	; 
	shr ch, cl			; use remainder to find bit pos in byte

	shr di, 3		; from bit to byte value div 8
;	this is limited to width values divisible by 64 with current system
	lea ax, [esi*4+esi] ; si * 5
	lea ax, [eax*8]		; si * 8
	add di, ax			; di + si * 40

;;	if use this, dx gets corrupted					; REMOVE
	; push dx
	; mov ax, 40;frame_width / 8
	; mul si
	; add di, ax ; calculate offset
	; pop dx

	mov al, [es:di]	; get byte
	mov di, dx

	and al, ch ; 0101 1110 --> 0000 00x0
	or al, al
	jz .zero
	inc bl
.zero:
ret
;========================================================================
_end:
	; mov al, 3
	; mov al, 0x0d
	; int 0x10
	cli
	hlt
;========================================================================
; cx as input
; delay:									; NOT USED
	; mov ah, 0x86
	; xor dx, dx
	; int 0x15
	; ret

; al as input
; print_char:								; NOT USED
	; mov ah, 0x0e
	; int 0x10
	; ret

; load_sector:								; NOT USED
	; mov ah, 0x02	; read data to memory
	; mov al, 18		; no. of sectors
	; mov ch, 0;65		; cylinder_count 
	; mov cl, 2;37		; sector in head
	; mov dh, 0;101		; head_count
	; mov dl, [BOOT_DRIVE]
	; xor bx, bx
	; mov es, bx
	; mov bx, neighbour_checks_address
	; int 0x13
	; ; jc disk_error
; ret
	
; disk_error:								; NOT USED
	; mov al, '1'
	; call print_char
	; jmp $
	
%include "neighbour_checks.asm"
	
times 510-($-$$) db 0
dw 0xAA55

; neighbour_checks_start:
; %include "neighbour_checks.asm"
; times 512*2-($-neighbour_checks_start) db 0; 

grid_start:
%include "grid.asm"
times 512*grid_sectors-($-grid_start) db 0