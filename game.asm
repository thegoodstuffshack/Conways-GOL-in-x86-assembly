[bits 16]
[org 0x7c00]
jmp start

; nasm -f bin game.asm -o test.bin
; qemu-system-x86_64 test.bin

;========================================================================
;========================================================================

BOOT_DRIVE					db 0
video_memory_address		equ 0xA000
neighbour_checks_address 	equ 0x7e00
grid_address				equ 0x8200
frame_width					equ 320		; cant change (for now)
										; change screen update to fix
frame_height				equ 31

neighbour_count				db 0

;========================================================================
;========================================================================

start:
	xor eax, eax
	xor esi, esi	; clear 32 bit registers for later lea math
	xor edi, edi
	xor ebx, ebx
	mov es, ax
	mov ds, ax
	mov ss, ax
	mov sp, 0x7c00
	
	mov [BOOT_DRIVE], dl

	call load_sector
	call setup_graphics_mode
	
	push video_memory_address
	pop es
	xor bx, bx
	
;========================================================================
game_setup:
;	load grid state from grid.asm	; faster without movsb??
	xor di, di
	mov ds, di
	mov si, grid_address
	mov cx, frame_height * frame_width / 8
	rep movsb	; mov ds:si to es:di , inc di, inc si, repeat cx times
	
	xor di, di
	xor si, si
	
; exit on user input
	mov ah, 1
	int 0x16
	jnz _end
	
;	use states in video memory to determine new states, place in grid
;	need to individually check state for each tile - 64K

;;	GAME CHANGE - code wrap-around borders
;;	ISSUE - adjusting frame size works however grid is incompatible with different values for width
;		  - without losing the configured pattern in the grid
;		  - frame_width cannot be adjusted
;;	LIMITATION	- current code uses video memory as the grid to read from
;				- adding a 'world' outside of it is currently not possible

; Speed increases are relative to previous version, optimizations with effects are in implementation order
;; OPTIMISATION - shorten functions called more often than others
;				- i.e. lengthen less used functions, e.g. keep es set
;				- es -> video_memory_address, bx -> 0
; IMPLEMENTED -> EFFECT = 28% increase in speed
;; OPTIMISATION - use lea for math (along with cleaning code (major part))
;				- also rearranged parts of code to reduce jumping
; IMPLEMENTED -> EFFECT = 55% increase in speed
;; OPTIMISATION - saving memory with functions increases compute time -> integrate functions
;;				- not reusing code will make it faster, bake EVERYTHING
;				- somewhat implemented, havent done get_bit_state yet
;				  as it would be a bit extreme (for now)
; Half IMPLEMENTED -> EFFECT = 61% increase in speed


;; OPTIMISATION - use register for storing neighbour count (really good)
;; OPTIMISATION - replace the rep movs when refreshing screen
;; OPTIMISATION - only check cells in each iteration that either changed or had neighbours that changed
;; OPTIMISATION - conditional checking of neighbours to prevent same byte grab

game_loop:
	cmp di, frame_width
	je .new_row

.same_row:
	mov [neighbour_count], bl	; memory -> 0
	jmp neighbour_checks

.new_row:
	xor di, di
	cmp si, frame_height
	je game_setup
	inc si
	jmp .same_row
	
;========================================================================
;========================================================================
_end:
	mov al, 3
	call change_graphics_mode
	cli
	hlt

setup_graphics_mode:
;	change bios video mode to graphics 320x200 colour
	mov al, 0x0d
	call change_graphics_mode
	
;	set background colour - 16 bit
;	black, blue, green, cyan, red, magenta, orange, l grey, d grey, l blue, l green, l cyan, l red, pink, yellow, white
	mov ah, 0x0b
	mov bh, 0
	mov bl, 0 ; black
	int 0x10
ret

; di, si, dx, bx, cx, ax
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
	lea eax, [esi*4+esi] ; si * 5
	lea ax, [eax*8]		; si * 8
	add di, ax			; di + si * 40
	
;	if use this, dx gets corrupted
;	not limited but is slower (maybe)
	; mov ax, frame_width / 8
	; mul si
	; add di, ax ; calculate offset
	
	mov al, [es:bx+di]	; get byte
	mov di, dx

	and al, ch ; 0101 1110 --> 0000 00x0
	or al, al
	mov al, bl	; al -> 0
	jz .zero
	inc al
.zero:
ret

;========================================================================
;========================================================================
; es as es
; bx as bx
; di as input for x coord
; si as input for y coord
toggle_pixel_state:
	mov dx, di
	;	math for finding bit in the byte - could use lookup table
	and di, 0x0007 ; 0000 0000 0000 0111
	mov cx, di	; store remainder
	mov di, dx
	mov ch, 0b10000000	; 
	shr ch, cl			; use remainder to find bit pos in byte
	
	shr di, 3		; from bit to byte value div 8

;	this is limited to width values divisible by 64 with current system
	lea eax, [esi*4+esi] ; si * (1,2,3,4,5,8,9)
	lea ax, [eax*8]		; si * 8
	add di, ax
	
;	if use this, dx gets corrupted
;	not limited but is slower (maybe)
	; mov ax, frame_width / 8
	; mul si
	; add di, ax ; calculate offset
	
	mov al, [es:bx+di]	; get byte
	xor al, ch
	add di, bx

	stosb	; mov al into address es:di
	
	mov di, dx
	ret

;========================================================================
;========================================================================

; cx as input
delay:
	mov ah, 0x86
	xor dx, dx
	int 0x15
	ret

; al as input
print_char:
	mov ah, 0x0e
	int 0x10
	ret

; al as input
change_graphics_mode:
	mov ah, 0
	int 0x10
	ret

load_sector:
	mov ah, 0x02	; read data to memory
	mov al, 18		; no. of sectors
	mov ch, 0		; cylinder_count 
	mov cl, 2		; sector in head
	mov dh, 0		; head_count
	mov dl, [BOOT_DRIVE]
	xor bx, bx
	mov es, bx
	mov bx, neighbour_checks_address
	int 0x13
	; jc disk_error
ret
	
; disk_error:
	; mov al, '1'
	; call print_char
	; jmp $
	
times 510-($-$$) db 0
dw 0xAA55

neighbour_checks_start:
%include "neighbour_checks.asm"
times 512*2-($-neighbour_checks_start) db 0

grid_start:
%include "grid.asm"
times 512*16-($-grid_start) db 0